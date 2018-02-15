//
//  ViewController.h
//  EEG Algo SDK
//
//  Created by Donald on 27/4/15.
//  Copyright (c) 2015 NeuroSky. All rights reserved.
//

#import <UIKit/UIKit.h>
#if TARGET_IPHONE_SIMULATOR
#else
//#import "TGStreamDelegate.h"
#import "MWMDevice.h"
#endif
#import <AlgoSdk/NskAlgoSdk.h>
#import "CorePlot-CocoaTouch.h"

#if TARGET_IPHONE_SIMULATOR
@interface ViewController : UIViewController <NskAlgoSdkDelegate, CPTPlotDataSource, CPTPlotDelegate, CPTPlotSpaceDelegate>
#else
@interface ViewController : UIViewController <NskAlgoSdkDelegate, MWMDelegate, CPTPlotDataSource, CPTPlotDelegate, CPTPlotSpaceDelegate,UIPickerViewDelegate,UIPickerViewDataSource>
#endif
@property (strong, atomic) IBOutlet UILabel *stateLabel;
@property (strong, atomic) IBOutlet UILabel *signalLabel;
@property (strong, atomic) IBOutlet UISlider *intervalSlider;
@property (strong, atomic) IBOutlet UILabel *intervalValue;
@property (strong, atomic) IBOutlet UIButton *dataButton;
@property (strong, atomic) IBOutlet UIButton *startPauseButton;
@property (strong, atomic) IBOutlet UIButton *stopButton;

@property (strong, atomic) IBOutlet UISegmentedControl *bcqThreshold;
@property (strong, atomic) IBOutlet UILabel *bcqThresholdTitle;
@property (strong, atomic) IBOutlet UIStepper *bcqWindowStepper;
@property (strong, atomic) IBOutlet UILabel *bcqWindow;
@property (strong, atomic) IBOutlet UILabel *bcqWindowTitle;

@property (strong, atomic) IBOutlet UITextView *textView;
@property (strong, atomic) IBOutlet CPTGraphHostingView *myGraph;
@property (strong, atomic) IBOutlet UISegmentedControl *segment;

@property (strong, atomic) IBOutlet UISwitch *apCheckbox;
@property (strong, atomic) IBOutlet UISwitch *meCheckbox;
@property (strong, atomic) IBOutlet UISwitch *me2Checkbox;
@property (strong, atomic) IBOutlet UISwitch *fCheckbox;
@property (strong, atomic) IBOutlet UISwitch *f2Checkbox;
@property (strong, atomic) IBOutlet UISwitch *attCheckbox;
@property (strong, atomic) IBOutlet UISwitch *medCheckbox;
@property (strong, atomic) IBOutlet UISwitch *crCheckbox;
@property (strong, atomic) IBOutlet UISwitch *alCheckbox;
@property (strong, atomic) IBOutlet UISwitch *cpCheckbox;
@property (strong, atomic) IBOutlet UISwitch *etCheckbox;
@property (strong, atomic) IBOutlet UISwitch *yyCheckbox;
@property (strong, atomic) IBOutlet UISwitch *bpCheckbox;
@property (strong, atomic) IBOutlet UISwitch *blinkCheckbox;

@property (strong, atomic) IBOutlet UIButton *setAlgoButton;
@property (strong, atomic) IBOutlet UIProgressView *attLevelIndicator;
@property (strong, atomic) IBOutlet UILabel *attValue;
@property (strong, atomic) IBOutlet UILabel *attLabel;
@property (strong, atomic) IBOutlet UIProgressView *medLevelIndicator;
@property (strong, atomic) IBOutlet UILabel *medValue;
@property (strong, atomic) IBOutlet UILabel *medLabel;

@property (strong, atomic) IBOutlet UIImageView *blinkImage;

@property (strong, atomic) IBOutlet UIButton *configButton;


//scan device realted UI
@property (weak, nonatomic) IBOutlet UIPickerView *devicePicker;
@property (weak, nonatomic) IBOutlet UIButton *selectBtn;
@property (weak, nonatomic) IBOutlet UIButton *scanDeviceBtn;

- (IBAction)segmentChanged:(id)sender;
- (IBAction)startPausePress:(id)sender;
- (IBAction)dataPress:(id)sender;
- (IBAction)configPress:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)setAlgos:(id)sender;
- (IBAction)bcqThresholdChanged:(id)sender;
- (IBAction)bcqWindowChanged:(id)sender;
@end

