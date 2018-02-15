//
//  ViewController.m
//  EEG Algo SDK
//
//  Created by Donald on 27/4/15.
//  Copyright (c) 2015 NeuroSky. All rights reserved.
//

#import "ViewController.h"

#import "AlgoContext.h"

#define X_RANGE     256

// in simulator, canned data will be used instead.
#if TARGET_IPHONE_SIMULATOR
//#if 1
#include "canned_data.c"
#else
#define IOS_DEVICE
//#include "canned_data.c"
#endif

#ifdef IOS_DEVICE
#import "MWMDevice.h"
#include <sys/time.h>
#endif


/*
 
How to use Algo SDK:

 // getting the Algo SDK instance
 1)NskAlgoSdk *nskAlgo = [NskAlgoSdk sharedInstance];
 
 // setting self as delegate
 2)[nskAlgo setDelegate: self];
 
 // selecting Appreciation, Attention and Meditation algorithms
 3)[nskAlgo setAlgorithmTypes: NskAlgoEegTypeAP|NskAlgoEegTypeAtt|NskAlgoEegTypeMed licenseKey:(char*)"LICENSE_KEY_CHAIN"];
 
 //Start analysing feed-in EEG data with selected EEG algorithm(s)
 4)[nskAlgo startProcess];
 
 //Feed-in realtime (from MWM SDK) or offline (recorded) EEG data to the EEG Algo SDK
 5)[[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypePQ data:poor_signal length:1];
   [[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypeEEG data:eeg_data length:1];
   [[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypeAtt data:attention length:1];
   [[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypeMed data:meditation length:1];
 
 // get Algo result from delegate method;
 6)- (void) stateChanged: (NskAlgoState)state reason:(NskAlgoReason)reason;
   - (void) signalQuality: (NskAlgoSignalQuality)signalQuality;
   .....
 
 //Stop analysing
 7)[[NskAlgoSdk sharedInstance] stopProcess];
 */


typedef NS_ENUM(NSInteger, SegmentIndexType) {
    SegmentAppreciation = 0,
    SegmentMentalEffort,
    SegmentMentalEffort2,
    SegmentFamiliarity,
    SegmentFamiliarity2,
    SegmentEEGBandpower,
    SegmentMax
};

const char *AlgoNames[SegmentMax] = {
    "AP",
    "ME",
    "ME2",
    "F",
    "F2",
    "BP"
};

@interface ViewController () {
    @private
    BOOL bRunning;
    BOOL bPaused;
    
    CPTXYGraph *graph;
    
    NskAlgoEegType algoTypes;
    
    NSTimer *graphTimer;
    
    AlgoContext *algoList[SegmentMax];
    
    BOOL showPickerFlag;
    NSMutableArray *deviceArr;
    NSMutableArray *connectIdArr;
//    NSString *selectedDeviceId;
    NSInteger selectedIndex;
    BOOL bleFlag;
}

@end

@implementation ViewController

NSMutableString *stateStr;
NSMutableString *signalStr;

long long tStart, tEnd;

const ALGO_SETTING defaultAlgoSetting[SegmentMax] = {
/*   xRange          plotMinY    plotMaxY   interval    minInterval maxInterval bcqThreshold                bcqValid    bcqWindow */
    {X_RANGE,        0.0f,       5.0f,      1,          1,          5,          0,                          0,          0},
    {X_RANGE,        -110,       200,       1,          1,          5,          0,                          0,          0},
    {X_RANGE,        0,          0,         30,         30,         300,        0,                          0,          0},
    {X_RANGE,        -110,       200,       1,          1,          5,          0,                          0,          0},
    {X_RANGE,        0,          0,         30,         30,         300,        0,                          0,          0},
    {X_RANGE,        -20,        40,        1,          1,          1,          0,                          0,          0}
};

typedef struct _PLOT_PARAM {
    BOOL plotAvailable;
    char *graphTitle;
    
    char *plotName[5];
} PLOT_PARAM;

PLOT_PARAM defaultPlotParam[SegmentMax] = {
/*    plotAvaliable graphTitle                  plotName */
    { YES,          "Appreciation",             {"AP Index",     nil} },
    { YES,          "Mental Effort",            {"Abs ME",       "Diff ME"} },
    { NO,           nil,                        {nil,            nil} },
    { YES,          "Familiarity",              {"Abs F",        "Diff F"} },
    { NO,           nil,                        {nil,            nil} },
    { YES,          "Bandpower",                {"Delta", "Theta", "Alpha", "Beta", "Gamma"} }
};

- (void) removeAlgoPlot {
    for (int i=0;i<SegmentMax;i++) {
        if (algoList[i].plotAvailable) {
            for (int j=0;j<[algoList[i] getPlotCount];j++) {
                if ([algoList[i] getPlot:j] != nil) {
                    [graph removePlot:[algoList[i] getPlot:j]];
                    [algoList[i] setPlot:nil idx:j];
                }
            }
        }
    }
}

- (void) resetAlgoPlotData {
    for (int i=0;i<SegmentMax;i++) {
        for (int j=0;j<[algoList[i] getPlotCount];j++) {
            if ([algoList[i] getIndex:j] != nil) {
                [[algoList[i] getIndex:j] removeAllObjects];
            }
        }
    }
}

- (void) resetAlgoSettings {
    [self resetAlgoPlotData];
    
    for (int i=0;i<SegmentMax;i++) {
        algoList[i].setting = defaultAlgoSetting[i];
    }
}


- (IBAction)setAlgos:(id)sender {
    algoTypes = 0;
    
    [self removeAlgoPlot];
    [self resetAlgoPlotData];
    [self resetAlgoSettings];
    
    for (int i=0;i<SegmentMax;i++) {
        [_segment setEnabled:NO forSegmentAtIndex:i];
    }
    [_segment setSelected:NO];
    
    [_bcqThresholdTitle setHidden:YES];
    [_bcqThreshold setHidden:YES];
    [_bcqWindowTitle setHidden:YES];
    [_bcqWindow setHidden:YES];
    [_bcqWindowStepper setHidden:YES];
    
    self.myGraph.hostedGraph = nil;
    [graph setHidden:YES];
    [self.textView setText:@""];
    [self.textView setHidden:YES];
    
    [stateStr setString:@""];
    [signalStr setString:@""];
    
    [self.stopButton setEnabled:NO];
    
    [self.attLabel setEnabled:NO];
    [self.attValue setEnabled:NO];
    [self.attLevelIndicator setProgress:0];
    [self.medLabel setEnabled:NO];
    [self.medValue setEnabled:NO];
    [self.medLevelIndicator setProgress:0];
    
    [self.intervalSlider setEnabled:NO];
    [self.configButton setEnabled:NO];
    [self.intervalSlider setValue:1];
    [self.intervalValue setText:@"1"];
    
    if ([_apCheckbox isOn]) {
        algoTypes |= NskAlgoEegTypeAP;
        [_segment setEnabled:YES forSegmentAtIndex:SegmentAppreciation];
    }
    if ([_meCheckbox isOn]) {
        algoTypes |= NskAlgoEegTypeME;
        [_segment setEnabled:YES forSegmentAtIndex:SegmentMentalEffort];
    }
    if ([_me2Checkbox isOn]) {
        algoTypes |= NskAlgoEegTypeME2;
        [_segment setEnabled:YES forSegmentAtIndex:SegmentMentalEffort2];
    }
    if ([_fCheckbox isOn]) {
        algoTypes |= NskAlgoEegTypeF;
        [_segment setEnabled:YES forSegmentAtIndex:SegmentFamiliarity];
    }
    if ([_f2Checkbox isOn]) {
        algoTypes |= NskAlgoEegTypeF2;
        [_segment setEnabled:YES forSegmentAtIndex:SegmentFamiliarity2];
    }
    if ([_attCheckbox isOn]) {
        algoTypes |= NskAlgoEegTypeAtt;
        [self.attLabel setEnabled:YES];
        [self.attValue setEnabled:YES];
    }
    if ([_medCheckbox isOn]) {
        algoTypes |= NskAlgoEegTypeMed;
        [self.medLabel setEnabled:YES];
        [self.medValue setEnabled:YES];
    }
    if ([_bpCheckbox isOn]) {
        algoTypes |= NskAlgoEegTypeBP;
        [_segment setEnabled:YES forSegmentAtIndex:SegmentEEGBandpower];
    }
    if ([_blinkCheckbox isOn]) {
        algoTypes |= NskAlgoEegTypeBlink;
    }
    if (algoTypes == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Please select at least ONE algorithm"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        int ret;
        NskAlgoSdk *handle = [NskAlgoSdk sharedInstance];
        handle.delegate = self;
        
        if ((ret = [[NskAlgoSdk sharedInstance] setAlgorithmTypes:algoTypes licenseKey:(char*)"NeuroSky_Release_To_GeneralFreeLicense_Use_Only_Jul 24 2017"]) != 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[NSString stringWithFormat:@"Fail to init EEG SDK [%d]", ret]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        NSMutableString *version = [NSMutableString stringWithFormat:@"SDK Ver.: %@", [[NskAlgoSdk sharedInstance] getSdkVersion]];
        if (algoTypes & NskAlgoEegTypeAP) {
            [version appendFormat:@"\nAppreciation Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeAP]];
        }
        if (algoTypes & NskAlgoEegTypeME) {
            [version appendFormat:@"\nMental Effort Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeME]];
        }
        if (algoTypes & NskAlgoEegTypeME2) {
            [version appendFormat:@"\nMental Effort 2 Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeME2]];
        }
        if (algoTypes & NskAlgoEegTypeF) {
            [version appendFormat:@"\nFamiliarity Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeF]];
        }
        if (algoTypes & NskAlgoEegTypeF2) {
            [version appendFormat:@"\nFamiliarity 2 Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeF2]];
        }
        if (algoTypes & NskAlgoEegTypeAtt) {
            [version appendFormat:@"\nAttention Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeAtt]];
        }
        if (algoTypes & NskAlgoEegTypeMed) {
            [version appendFormat:@"\nMeditation Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeMed]];
        }
        if (algoTypes & NskAlgoEegTypeBP) {
            [version appendFormat:@"\nEEG Bandpower Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeBP]];
        }
        if (algoTypes & NskAlgoEegTypeBlink) {
            [version appendFormat:@"\nBlink Detection Ver.: %@", [[NskAlgoSdk sharedInstance] getAlgoVersion:NskAlgoEegTypeBlink]];
        }        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:version
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    if (graphTimer == nil) {
        graphTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(reloadGraph) userInfo:nil repeats:YES];
    }
}

- (void)reloadGraph {
    @synchronized(graph) {
        if (graph) {
            CPTColor *fillColor = [CPTColor colorWithComponentRed:1 green:1 blue:1 alpha:1.0];
            graph.plotAreaFrame.plotArea.fill = [CPTFill fillWithColor:fillColor];
            [graph reloadData];
        }
    }
}

- (IBAction)startPausePress:(id)sender {
    if (bPaused) {
        [_bcqThresholdTitle setEnabled:NO];
        [_bcqThreshold setEnabled:NO];
        [_bcqWindowTitle setEnabled:NO];
        [_bcqWindowStepper setEnabled:NO];
        [_bcqWindow setEnabled:NO];
        //Start analysing feed-in EEG data with selected EEG algorithm(s)
        [[NskAlgoSdk sharedInstance] startProcess];
    } else {
        //Pause analysing
        [[NskAlgoSdk sharedInstance] pauseProcess];
    }
}

- (IBAction)stopPress:(id)sender {
    //Stop analysing
    [[NskAlgoSdk sharedInstance] stopProcess];
}

#ifdef IOS_DEVICE
#else
- (IBAction)dataPress:(id)sender {
    [self sendBulkData];
}

- (void) sendBulkData {
    if ([[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypeBulkEEG data:raw_data_yy length:(int32_t)(sizeof(raw_data_yy)/sizeof(raw_data_yy[0]))] == TRUE) {
        [self.dataButton setEnabled:NO];
    }
}
#endif

- (int)convertSegmentToEegType {
    switch (self.segment.selectedSegmentIndex) {
        case SegmentAppreciation:
            return NskAlgoEegTypeAP;
        case SegmentMentalEffort:
            return NskAlgoEegTypeME;
        case SegmentMentalEffort2:
            return NskAlgoEegTypeME2;
        case SegmentFamiliarity:
            return NskAlgoEegTypeF;
        case SegmentFamiliarity2:
            return NskAlgoEegTypeF2;
    }
    return -1;
}

- (IBAction)configPress:(id)sender {
    int interval = 1;
    if ([self convertSegmentToEegType] == -1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please select algorithm from the tab below"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    interval = (int)[self.intervalSlider value];
    [algoList[self.segment.selectedSegmentIndex] setInterval:(int)[self.intervalSlider value]];
    [[NskAlgoSdk sharedInstance] setAlgoIndexOutputInterval:[self convertSegmentToEegType] outputInterval:interval];
}

- (IBAction)sliderValueChanged:(id)sender {
    int interval = (int)[self.intervalSlider value];
    [algoList[self.segment.selectedSegmentIndex] setInterval:(int)interval];
    self.intervalValue.text = [NSString stringWithFormat:@"%d", (int)interval];
}

- (IBAction)segmentChanged:(id)sender {
    UISegmentedControl *control = (UISegmentedControl*)self.segment;
    [self removeAlgoPlot];
    [graph setHidden:YES];
    
    [_configButton setEnabled:YES];
    
    // always hidden BCQ related UI components
    [_bcqThresholdTitle setHidden:YES];
    [_bcqThreshold setHidden:YES];
    [_bcqWindowTitle setHidden:YES];
    [_bcqWindowStepper setHidden:YES];
    [_bcqWindow setHidden:YES];
    
    if (algoList[control.selectedSegmentIndex].plotAvailable) {
        [self.myGraph setHidden:NO];
        [self.textView setHidden:YES];
        graph = [self setupGraph:self.myGraph yMin:algoList[control.selectedSegmentIndex].plotMinY length:algoList[control.selectedSegmentIndex].plotMaxY graphTitle:algoList[control.selectedSegmentIndex].graphTitle];
        
        for (int j=0;j<[algoList[control.selectedSegmentIndex] getPlotCount];j++) {
            if (defaultPlotParam[control.selectedSegmentIndex].plotName[j] != nil) {
                NSString *plotName = [NSString stringWithFormat:@"%s", defaultPlotParam[control.selectedSegmentIndex].plotName[j]];
                CPTPlot *plot = [self addPlotToGraph:graph color:[algoList[control.selectedSegmentIndex] getPlotColor:j] plotTitle:plotName];
                [algoList[control.selectedSegmentIndex] setPlot:plot idx:j];
            }
        }
        
        [self.configButton setEnabled:YES];
        [self.intervalSlider setEnabled:YES];
        [self.intervalSlider setMinimumValue:algoList[control.selectedSegmentIndex].minInterval];
        [self.intervalSlider setMaximumValue:algoList[control.selectedSegmentIndex].maxInterval];
        [self.intervalSlider setValue:algoList[control.selectedSegmentIndex].interval];
        self.intervalValue.text = [NSString stringWithFormat:@"%d", (int)algoList[control.selectedSegmentIndex].interval];
    } else {
        [self.myGraph setHidden:YES];
        [self.textView setHidden:NO];
        
        [self.configButton setEnabled:YES];
        [self.intervalSlider setEnabled:YES];
        [self.intervalSlider setMinimumValue:algoList[control.selectedSegmentIndex].minInterval];
        [self.intervalSlider setMaximumValue:algoList[control.selectedSegmentIndex].maxInterval];
        [self.intervalSlider setValue:algoList[control.selectedSegmentIndex].interval];
        self.intervalValue.text = [NSString stringWithFormat:@"%d", (int)algoList[control.selectedSegmentIndex].interval];
    }
    
    // advance UI settings
    switch (control.selectedSegmentIndex) {
        default:
            break;
    }
}



+ (long long) current_timestamp {
    NSDate *date = [NSDate date];
    return [@(floor([date timeIntervalSince1970] * 1000)) longLongValue];
}



#pragma mark UIPickerView Delegate
// 返回多少列 number Of Components In PickerView
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{

    return 1;
}

// 返回每列的行数  number Of Rows In Component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return deviceArr.count;
}

// 返回pickerView 每行的内容   title For Row
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {

    NSString *deviceInfo = [deviceArr objectAtIndex:row];
//    NSLog(@"deviceInfo = %@",deviceInfo);
    return deviceInfo;
}


// 选中行  did Select Row in Component
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSLog(@"didSelectRow = %ld",row);
    selectedIndex = row;
  
}



- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef IOS_DEVICE
    //Tommy add 2017-08-21 ,support MWM+
    [self showPickerView:NO];
    _scanDeviceBtn.enabled = YES;
    showPickerFlag = NO;
    _devicePicker.delegate = self;
    _devicePicker.dataSource = self;
    deviceArr = [[NSMutableArray alloc] init];
    connectIdArr = [[NSMutableArray alloc] init];
    // we use real mindwave headset on iOS device
    [[MWMDevice sharedInstance] setDelegate:self];
  
    
#else
    // we use canned data for simulator
    [self.dataButton setHidden:NO];
    [self.scanDeviceBtn setEnabled:NO];

#endif
    
    [self.segment removeAllSegments];
    
    for (int i=0;i<SegmentMax;i++) {
        algoList[i] = [[AlgoContext alloc] init];
        algoList[i].plotAvailable = defaultPlotParam[i].plotAvailable;
        [algoList[i] setSetting:defaultAlgoSetting[i]];
        
        if (defaultPlotParam[i].plotAvailable) {
            if (defaultPlotParam[i].graphTitle != nil) {
                algoList[i].graphTitle = [NSString stringWithUTF8String:defaultPlotParam[i].graphTitle];
            }
            for (int j=0;j<[algoList[i] getPlotCount];j++) {
                if (defaultPlotParam[i].plotName[j] != nil) {
                    [algoList[i] setIndex:j];
                    [algoList[i] setPlotName:[NSString stringWithUTF8String:defaultPlotParam[i].plotName[j]] idx:j];
                }
            }
        }
        
        [self.segment insertSegmentWithTitle:[NSString stringWithFormat:@"%s", AlgoNames[i]] atIndex:i animated:NO];
        [self.segment setEnabled:NO forSegmentAtIndex:i];
    }
    bRunning = FALSE;
}

- (CPTXYGraph*)setupGraph: (CPTGraphHostingView*)hostView yMin:(float)yMin length:(float)length graphTitle:(NSString*)graphTitle {
    
    // Create graph from theme
    CPTXYGraph *newGraph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme      = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [newGraph applyTheme:theme];
    
    hostView.hostedGraph = newGraph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)newGraph.defaultPlotSpace;
    NSTimeInterval xLow       = 0.0;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(xLow) length:CPTDecimalFromDouble(X_RANGE+2)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yMin) length:CPTDecimalFromDouble(length)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)newGraph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromDouble(0);
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0);
    x.minorTicksPerInterval       = 0;
    
    CPTXYAxis *y = axisSet.yAxis;
    if (length < 10) {
        y.majorIntervalLength         = CPTDecimalFromDouble(1);
        y.minorTicksPerInterval       = 5;
    } else if (length > 500) {
        y.majorIntervalLength         = CPTDecimalFromDouble(200);
        y.minorTicksPerInterval       = 200;
        y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(X_RANGE/3);
    } else {
        y.majorIntervalLength         = CPTDecimalFromDouble(20);
        y.minorTicksPerInterval       = 2;
    }
    y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(X_RANGE/3);
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    y.majorGridLineStyle = gridLineStyle;
    
    newGraph.title = graphTitle;
    
    return newGraph;
}

- (CPTPlot*) addPlotToGraph: (CPTXYGraph*)gp color:(CPTColor*)color plotTitle:(NSString*)plotTitle {
    // Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 1.5;
    lineStyle.lineColor              = color;
    dataSourceLinePlot.dataLineStyle = lineStyle;
    dataSourceLinePlot.interpolation = CPTScatterPlotInterpolationLinear;
    
    dataSourceLinePlot.dataSource = self;
    
    dataSourceLinePlot.showLabels = YES;
    
    dataSourceLinePlot.title = plotTitle;
    
    [gp addPlot:dataSourceLinePlot];
    
    // Add legend
    gp.legend                 = [CPTLegend legendWithGraph:gp];
    gp.legend.fill            = [CPTFill fillWithColor:[CPTColor greenColor]];
    gp.legend.borderLineStyle = ((CPTXYAxisSet *)gp.axisSet).xAxis.axisLineStyle;
    gp.legend.cornerRadius    = 2.0;
    gp.legend.numberOfRows    = 1;
    gp.legend.numberOfColumns = 5;
    gp.legend.delegate        = self;
    gp.legendAnchor           = CPTRectAnchorBottom;
    gp.legendDisplacement     = CGPointMake( 0.0, 5.0f * CPTFloat(1.25) );
    
    dataSourceLinePlot.delegate = self;
    dataSourceLinePlot.plotSpace.delegate = self;
    
    return dataSourceLinePlot;
}

- (NSString*)GetCurrentTimeStamp
{
    NSDate *now = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm:ss:SSS";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    return [dateFormatter stringFromDate:now];
}

- (NSString *) timeInMiliSeconds
{
    NSDate *date = [NSDate date];
    NSString * timeInMS = [NSString stringWithFormat:@"%lld", [@(floor([date timeIntervalSince1970] * 1000)) longLongValue]];
    return timeInMS;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)labelForDateAtIndex:(NSInteger)index {
    return @"";
}

-(NSString *) NowString{
    
    NSDate *date=[NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    return [dateFormatter stringFromDate:date];
}


#ifdef IOS_DEVICE
static long long current_timestamp() {
    struct timeval te;
    gettimeofday(&te, NULL);
    long long milliseconds = te.tv_sec*1000LL + te.tv_usec/1000; // caculate milliseconds
    return milliseconds;
}

int rawCount = 0;

#pragma mark MWM Delegate

- (void)deviceFound:(NSString *)devName MfgID:(NSString *)mfgID DeviceID:(NSString *)deviceID{
    
    NSLog(@"devName = %@,MfgID = %@,deviceID = %@",devName,mfgID,deviceID);
    if (!showPickerFlag) {
        showPickerFlag = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showPickerView:YES];

        });
    }
    NSString *tmp = [NSString stringWithFormat:@"%@ %@",devName,mfgID];
    [connectIdArr addObject:deviceID];
    [deviceArr addObject:tmp];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_devicePicker reloadAllComponents];
     });
}

- (void)didConnect{
    NSLog(@"didConnect");
}


- (void)didDisconnect{
    NSLog(@"didDisconnect");
}


- (void)eegSample:(int) sample{
    rawCount++;
    //[self addValue:@(data) array:self->eegIndex];
    if (bRunning == FALSE) {
        return;
    }
    {
        int16_t eeg_data[1];
        eeg_data[0] = (int16_t)sample;
        //Feed-in EEG data to the EEG Algo SDK
        [[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypeEEG data:eeg_data length:1];
        //MWM plus case:  BLE sample rate 256;  so double it!
        if (bleFlag) {
            [[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypeEEG data:eeg_data length:1];
        }
    }
    //NSLog(@"%@\n CODE_RAW %d\n",[self NowString],data);
    
}

- (void)eSense:(int)poorSignal Attention:(int)attention Meditation:(int)meditation{

//    NSLog(@"poorSignal = %d,attention = %d,meditation = %d",poorSignal,attention,meditation);
    
    if (bRunning == FALSE) {
        return;
    }
    {
        long long timestamp = current_timestamp();
        static long long ltimestamp = 0;
        printf("PQ,%lld,%lld,%d\n", timestamp%100000, timestamp - ltimestamp, rawCount);
        ltimestamp = timestamp;
        rawCount = 0;
    }
   

    {
        int16_t poor_signal[1];
        poor_signal[0] = (int16_t)poorSignal;
        //Feed-in EEG data to the EEG Algo SDK
        [[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypePQ data:poor_signal length:1];
       
        int16_t attention_input[1];
        attention_input[0] = (int16_t)attention;
        //Feed-in EEG data to the EEG Algo SDK
        [[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypeAtt data:attention_input length:1];
        
        int16_t meditation_input[1];
        meditation_input[0] = (int16_t)meditation;
        //Feed-in EEG data to the EEG Algo SDK
        [[NskAlgoSdk sharedInstance] dataStream:NskAlgoDataTypeMed data:meditation_input length:1];

    }


}

- (void)eegPowerDelta:(int)delta Theta:(int)theta LowAlpha:(int)lowAlpha HighAlpha:(int)highAlpha{}

- (void)eegPowerLowBeta:(int)lowBeta HighBeta:(int)highBeta LowGamma:(int)lowGamma MidGamma:(int)midGamma{}

- (void)eegBlink:(int) blinkValue{}

#endif



#pragma mark
#pragma NSK EEG SDK Delegate
- (void)stateChanged:(NskAlgoState)state reason:(NskAlgoReason)reason {
    if (stateStr == nil) {
        stateStr = [[NSMutableString alloc] init];
    }
    [stateStr setString:@""];
    [stateStr appendString:@"SDK State: "];
    switch (state) {
        case NskAlgoStateCollectingBaselineData:
        {
            bRunning = TRUE;
            bPaused = FALSE;
            [stateStr appendString:@"Collecting baseline"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_startPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
                [_startPauseButton setEnabled:YES];
                [_stopButton setEnabled:YES];
            });
        }
            break;
        case NskAlgoStateAnalysingBulkData:
        {
            bRunning = TRUE;
            bPaused = FALSE;
            [stateStr appendString:@"Analysing Bulk Data"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_startPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
                [_startPauseButton setEnabled:NO];
                [_stopButton setEnabled:YES];
            });
        }
            break;
        case NskAlgoStateInited:
        {
            bRunning = FALSE;
            bPaused = TRUE;
            [stateStr appendString:@"Inited"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_startPauseButton setTitle:@"Start" forState:UIControlStateNormal];
                [_startPauseButton setEnabled:YES];
                [_stopButton setEnabled:NO];
                [_attLevelIndicator setProgress:0.0f];
                [_attValue setText:@""];
                
                [_medLevelIndicator setProgress:0.0f];
                [_medValue setText:@""];
                
                [_intervalSlider setEnabled:YES];
                [_intervalValue setEnabled:YES];
                [_configButton setEnabled:YES];
            });
        }
            break;
        case NskAlgoStatePause:
        {
            bPaused = TRUE;
            [stateStr appendString:@"Pause"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_startPauseButton setTitle:@"Start" forState:UIControlStateNormal];
                [_startPauseButton setEnabled:YES];
                [_stopButton setEnabled:YES];
            });
        }
            break;
        case NskAlgoStateRunning:
        {
            [stateStr appendString:@"Running"];
            bRunning = TRUE;
            bPaused = FALSE;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_startPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
                [_startPauseButton setEnabled:YES];
                [_stopButton setEnabled:YES];
            });
        }
            break;
        case NskAlgoStateStop:
        {
            [stateStr appendString:@"Stop"];
            bRunning = FALSE;
            bPaused = TRUE;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_startPauseButton setTitle:@"Start" forState:UIControlStateNormal];
                [_startPauseButton setEnabled:YES];
                [_stopButton setEnabled:NO];
                [_attLevelIndicator setProgress:0.0f];
                [_attValue setText:@""];
                
                [_medLevelIndicator setProgress:0.0f];
                [_medValue setText:@""];
                
                [_bcqThresholdTitle setEnabled:YES];
                [_bcqThreshold setEnabled:YES];
                [_bcqWindowTitle setEnabled:YES];
                [_bcqWindow setEnabled:YES];
                [_bcqWindowStepper setEnabled:YES];
                
                [self.dataButton setEnabled:YES];
            });
        }
            break;
        case NskAlgoStateUninited:
            [stateStr appendString:@"Uninit"];
            break;
    }
    switch (reason) {
        case NskAlgoReasonBaselineExpired:
            [stateStr appendString:@" | Baseline expired"];
            break;
        case NskAlgoReasonConfigChanged:
            [stateStr appendString:@" | Config changed"];
            break;
        case NskAlgoReasonNoBaseline:
            [stateStr appendString:@" | No Baseline"];
            break;
        case NskAlgoReasonSignalQuality:
            [stateStr appendString:@" | Signal quality"];
            break;
        case NskAlgoReasonUserProfileChanged:
            [stateStr appendString:@" | User profile changed"];
            break;
        case NskAlgoReasonUserTrigger:
            [stateStr appendString:@" | By user"];
            break;
    }
    printf([stateStr UTF8String]);
    printf("\n");
    dispatch_async(dispatch_get_main_queue(), ^{
        //code you want on the main thread.
        self.stateLabel.text = stateStr;
    });
}

- (void) addValue: (NSNumber*)value array:(NSMutableArray*)array {
    @synchronized(graph) {
        if ([array count] >= X_RANGE) {
            [array removeObjectAtIndex:0];
        }
        [array addObject:
         @{ @(CPTScatterPlotFieldX): @([array count]),
            @(CPTScatterPlotFieldY): @([value floatValue]) }
         ];
        
        for (int j=0;j<SegmentMax;j++) {
            if (algoList[j].plotAvailable == YES) {
                for (int i=0;i<[algoList[j] getPlotCount];i++) {
                    NSMutableArray *index = nil;
                    if ([algoList[j] getIndex:i] == array) {
                        index = [algoList[j] getIndex:i];
                        
                        for (int i=0;i<[index count];i++) {
                            NSDictionary *dict = @{ @(CPTScatterPlotFieldX): @(i), @(CPTScatterPlotFieldY): index[i][@(CPTScatterPlotFieldY)] };
                            [index replaceObjectAtIndex:i withObject:dict];
                        }
                    }
                }
            }
        }
    }
}

- (void)signalQuality:(NskAlgoSignalQuality)signalQuality {
    if (signalStr == nil) {
        signalStr = [[NSMutableString alloc] init];
    }
    [signalStr setString:@""];
    [signalStr appendString:@"Signal quailty: "];
    switch (signalQuality) {
        case NskAlgoSignalQualityGood:
            [signalStr appendString:@"Good"];
            break;
        case NskAlgoSignalQualityMedium:
            [signalStr appendString:@"Medium"];
            break;
        case NskAlgoSignalQualityNotDetected:
            [signalStr appendString:@"Not detected"];
            break;
        case NskAlgoSignalQualityPoor:
            [signalStr appendString:@"Poor"];
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        //code you want on the main thread.
        self.signalLabel.text = signalStr;
    });
}

int ap_index = 0;
int me_index = 0;
int me2_index = 0;
int f_index = 0;
int f2_index = 0;

float lMeditation = 0;
float lAttention = 0;
float lAppreciation = 0;
float lMentalEffort_abs = 0, lMentalEffort_diff = 0;

#ifndef IOS_DEVICE
#define SAMPLE_COUNT        600
float ap[SAMPLE_COUNT];
float me[SAMPLE_COUNT];
float f[SAMPLE_COUNT];
float f2[SAMPLE_COUNT];
#endif

int bp_index = 0;

- (void)bpAlgoIndex:(NSNumber *)delta theta:(NSNumber *)theta alpha:(NSNumber *)alpha beta:(NSNumber *)beta gamma:(NSNumber *)gamma {
    NSLog(@"bp[%d] = (delta)%1.6f (theta)%1.6f (alpha)%1.6f (beta)%1.6f (gamma)%1.6f", bp_index, [delta floatValue], [theta floatValue], [alpha floatValue], [beta floatValue], [gamma floatValue]);
    bp_index++;
    
    [self addValue:delta array:[algoList[SegmentEEGBandpower] getIndex:0]];
    [self addValue:theta array:[algoList[SegmentEEGBandpower] getIndex:1]];
    [self addValue:alpha array:[algoList[SegmentEEGBandpower] getIndex:2]];
    [self addValue:beta array:[algoList[SegmentEEGBandpower] getIndex:3]];
    [self addValue:gamma array:[algoList[SegmentEEGBandpower] getIndex:4]];
}

- (void)apAlgoIndex:(NSNumber *)value {
    NSLog(@"ap[%d] = %1.15f", ap_index, [value floatValue]);
    lAppreciation = [value floatValue];
#ifndef IOS_DEVICE
    ap[ap_index] = lAppreciation;
#endif
    ap_index++;
    
    [self addValue:value array:[algoList[SegmentAppreciation] getIndex:0]];
}

- (void)meAlgoIndex:(NSNumber *)abs_me diff_me:(NSNumber *)diff_me max_me:(NSNumber *)max_me min_me:(NSNumber *)min_me {
    
    NSLog(@"me[%d] = ABS:%1.8f DIF:%1.8f [%1.0f:%1.0f]", me_index, [abs_me floatValue], [diff_me floatValue], [min_me floatValue], [max_me floatValue]);
    lMentalEffort_abs = [abs_me floatValue];
    lMentalEffort_diff = [diff_me floatValue];
#ifndef IOS_DEVICE
    me[me_index] = lMentalEffort_abs;
#endif
    me_index++;
    [self addValue:abs_me array:[algoList[SegmentMentalEffort] getIndex:0]];
    [self addValue:diff_me array:[algoList[SegmentMentalEffort] getIndex:1]];
}

- (void) me2AlgoIndex: (NSNumber*)total_me me_rate:(NSNumber*)me_rate changing_rate:(NSNumber*)changing_rate {
    NSLog(@"me2[%d] = (total)%1.6f (rate)%1.6f (chg rate)%1.6f", me2_index, [total_me floatValue], [me_rate floatValue], [changing_rate floatValue]);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"hh:mm:ss"];
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        
        [self.textView setText:[NSString stringWithFormat:@"%@[%@]\n        Total Mental Effort: %1.6f\n        Mental Effort Rate : %1.6f\n        Changing Rate      : %1.6f\n\n", [self.textView text], dateString, [total_me floatValue], [me_rate floatValue], [changing_rate floatValue]]];
        
        NSRange bottom = NSMakeRange(self.textView.text.length -1, 1);
        [self.textView scrollRangeToVisible:bottom];
    });
    
    me2_index++;
}

- (void)fAlgoIndex:(NSNumber *)abs_f diff_f:(NSNumber *)diff_f max_f:(NSNumber *)max_f min_f:(NSNumber *)min_f {
    
        
    NSLog(@"f[%d] = ABS:%1.8f DIF:%1.8f [%1.0f:%1.0f]", f_index, [abs_f floatValue], [diff_f floatValue], [min_f floatValue], [max_f floatValue]);
#ifndef IOS_DEVICE
        f[f_index] = [abs_f floatValue];
#endif
        f_index++;
        [self addValue:abs_f array:[algoList[SegmentFamiliarity] getIndex:0]];
        [self addValue:diff_f array:[algoList[SegmentFamiliarity] getIndex:1]];
}

- (void)f2AlgoIndex:(NSNumber *)progress f_degree:(NSNumber *)f_degree {
    NSLog(@"f2[%d] = %d, %1.15f", f2_index, [progress intValue], [f_degree floatValue]);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"hh:mm:ss"];
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        
        [self.textView setText:[NSString stringWithFormat:@"%@[%@]\n        Progress Level: %1d\n        F Degree      : %1.6f\n\n", [self.textView text], dateString, [progress intValue], [f_degree floatValue]]];
        
        NSRange bottom = NSMakeRange(self.textView.text.length -1, 1);
        [self.textView scrollRangeToVisible:bottom];
    });
    f2_index++;
}

- (void)medAlgoIndex:(NSNumber *)med_index {
    NSLog(@"Meditation: %f", [med_index floatValue]);
    lMeditation = [med_index floatValue];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [_medLevelIndicator setProgress:(lMeditation/100.0f)];
        [_medValue setText:[NSString stringWithFormat:@"%3.0f", lMeditation]];
    });
}

- (void)attAlgoIndex:(NSNumber *)att_index {
    NSLog(@"Attention: %f", [att_index floatValue]);
    lAttention = [att_index floatValue];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [_attLevelIndicator setProgress:(lAttention/100.0f)];
        [_attValue setText:[NSString stringWithFormat:@"%3.0f", lAttention]];
    });
}

BOOL bBlink = NO;
- (void)eyeBlinkDetect:(NSNumber *)strength {
    NSLog(@"Eye blink detected: %d", [strength intValue]);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [_blinkImage setImage:[UIImage imageNamed:@"led-on"]];
        bBlink = YES;
        [NSTimer scheduledTimerWithTimeInterval:0.25f target:self selector:@selector(eyeBlinkAnimate) userInfo:nil repeats:NO];
    });
}

- (void)eyeBlinkAnimate {
    if (bBlink) {
        [_blinkImage setImage:[UIImage imageNamed:@"led-off"]];
        bBlink = NO;
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    for (int i=0;i<SegmentMax;i++) {
        for (int j=0;j<[algoList[i] getPlotCount];j++) {
            CPTPlot *pt = [algoList[i] getPlot:j];
            if (pt == plot) {
                return [[algoList[i] getIndex:j] count];
            }
        }
    }
    return 0;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    for (int i=0;i<SegmentMax;i++) {
        for (int j=0;j<[algoList[i] getPlotCount];j++) {
            CPTPlot *pt = [algoList[i] getPlot:j];
            if (pt == plot) {
                return [algoList[i] getIndex:j][index][@(fieldEnum)];
            }
        }
    }
    return nil;
}

- (BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(UIEvent *)event atPoint:(CGPoint)point {
    return YES;
}

#pragma mark -
#pragma mark Plot Delegate Methods

-(void)plot:(CPTPlot *)plot dataLabelTouchDownAtRecordIndex:(NSUInteger)idx {
    NSLog(@"%lu is touched", (unsigned long)idx);
}


#ifdef IOS_DEVICE

- (IBAction)scanDeviceBtnClick:(id)sender {
    NSLog(@"scanDeviceBtnClick---");
    //call MWM SDK disconect device
    [[MWMDevice sharedInstance] disconnectDevice];

    [self resetDevicePickerData];
    [self showPickerView:NO];
    // call  MWM SDK scanDevice to scan available devices.
    [[MWMDevice sharedInstance] scanDevice];
    
}
- (IBAction)selectBtnClick:(id)sender {
    // stop scan 
    [[MWMDevice sharedInstance] stopScanDevice];
    //connect to the selected device;
    NSString *selectedDeviceId = [connectIdArr objectAtIndex:selectedIndex];
    if ([selectedDeviceId containsString:@":"]) {
        bleFlag = NO;
    }
    else{
        bleFlag = YES;
    }
    NSLog(@"bleFlag = %d",bleFlag);
    
    [[MWMDevice sharedInstance] connectDevice:selectedDeviceId];
    
    [self showPickerView:NO];
}

- (void)showPickerView:(BOOL)showFlag{
    _selectBtn.hidden = !showFlag;
    _devicePicker.hidden = !showFlag;
}

- (void)resetDevicePickerData{
    selectedIndex = 0;
    showPickerFlag = NO;
    [connectIdArr removeAllObjects];
    [deviceArr removeAllObjects];
}

#endif

@end
