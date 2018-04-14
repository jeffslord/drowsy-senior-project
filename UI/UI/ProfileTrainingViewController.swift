//
//  ProfileTrainingViewController.swift
//  UI
//
//  Created by Sammy Eang on 2/12/18.
//  Copyright © 2018 Senior Project. All rights reserved.
//

import UIKit
import Alamofire
import SwiftySound
import RxBluetoothKit
import RxSwift
import SwiftyTimer

class ProfileTrainingViewController: UIViewController,MWMDelegate {
    
    let manager = CentralManager(queue: .main)
    
    let mwm = MWMDevice.sharedInstance()
    var brainWaveDataLocation: String = ""
    
    var trainid: String?
    private var trainSound: Sound?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let trainUrl = Bundle.main.url(forResource: "Senior Project Training Sounds", withExtension: "aif") {
            trainSound = Sound(url: trainUrl)
        }
        
        mwm?.delegate = self
        
        let stateObservable = manager.observeState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func trainingbegin(_ sender: Any) {
        
        //tells server we are profile training for a certain user id so it knows what to do with data
        /*if let userid = trainid {
            
            let parameters: Parameters = ["id": userid, "activity": "train"]
        
            Alamofire.request("http://127.0.0.1:5000/index", method: .post, parameters: parameters)
        }*/
        
        Sound.play(file: "Senior Project Training Sounds", fileExtension: "aif", numberOfLoops: 0)
        
        Timer.after(20.seconds) {
            
            var time: Int = 0
            
                Timer.every(1.seconds) {
                    
                    //exits loops and stops recording after audio ends
                    time += 1
                    if (time == 112) {
                        return
                    }
                    
                    //creates log every second, aka 512 data points hopefully
                    self.mwm?.scanDevice()
                    self.mwm?.enableLogging(withOptions: 1)
                    self.mwm?.enableConsoleLog(true)
                    self.brainWaveDataLocation = (self.mwm?.enableLogging(withOptions: 1))!
                    
                    //after each second/512 data points, sends text file with that to server and deletes text file
                    Timer.after(1.seconds) {
                        
                        //stops logging for current file
                        self.mwm?.stopScanDevice()
                        self.mwm?.stopLogging()
                        self.mwm?.disconnectDevice()
                        
                        //print("This is the file location:" + self.brainWaveDataLocation)
                        
                        //declares filename
                        var fileName = String(self.brainWaveDataLocation.characters.suffix(27))
                        fileName.removeLast(4)
                        //print("This is the file name:" + fileName)
                        
                        //assigns correct file directory
                        var DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                        
                        //grabbing URL of specific file
                        var fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
                        //print("FilePath: \(fileURL.path)")
                        
                        //uploads file to server
                        Alamofire.upload(fileURL, to: "https://httpbin.org/post").responseJSON { response in
                            debugPrint(response)
                        }
                    
                        //deletes file afterwards
                        do {
                            let fileManager = FileManager.default
                            
                            // Check if file exists
                            if fileManager.fileExists(atPath: self.brainWaveDataLocation) {
                                // Delete file
                                try fileManager.removeItem(atPath: self.brainWaveDataLocation)
                            } else {
                                print("File does not exist")
                            }
                            
                        }
                        catch let error as NSError {
                            print("An error took place: \(error)")
                        }
                        
                    }
                
                }
        }
    }
    
    func deviceFound(_ devName: String!, mfgID: String!, deviceID: String!) {
        print("This is the device ID:" + deviceID)
        mwm?.connect(deviceID)
    }
    
    func didConnect() {
        print("Headset Connected")
    }
    
    func didDisconnect() {
        print("Headset Disconnected")
    }
    
}
