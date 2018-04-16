//
//  RunViewController.swift
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

class RunViewController: UIViewController, MWMDelegate {
    
    let manager = CentralManager(queue: .main)
    
    let mwm = MWMDevice.sharedInstance()
    var brainWaveDataLocation: String = ""
    
    var runid: String?
    private var runSound: Sound?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let runUrl = Bundle.main.url(forResource: "Drowsy Alert", withExtension: "m4a") {
            runSound = Sound(url: runUrl)
            
        }

        mwm?.delegate = self
        
        let stateObservable = manager.observeState()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tracking(_ sender: Any) {
        //tells server we are running for a certain user id so it knows what to do with data
        /*if let userid = runid {
            
            let parameters: Parameters = ["id": userid, "activity": "run"]
            
            Alamofire.request("http://127.0.0.1:5000/index", method: .post, parameters: parameters)
        }*/
        
        Timer.every(1.seconds) {
            //starts log
            self.mwm?.scanDevice()
            self.mwm?.enableLogging(withOptions: 1)
            self.mwm?.enableConsoleLog(true)
            self.brainWaveDataLocation = (self.mwm?.enableLogging(withOptions: 1))!
            
            Timer.after(1.seconds) {
                //stops log
                self.mwm?.stopScanDevice()
                self.mwm?.stopLogging()
                self.mwm?.disconnectDevice()
                
                //getting fileName
                var fileName = String(self.brainWaveDataLocation.characters.suffix(27))
                fileName.removeLast(4)
                
                //decalring correct file directory to look in
                var DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                
                //grabbing URL of specific file
                var fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
                //print("FilePath: \(fileURL.path)")
                
                Alamofire.upload(fileURL, to: "https://httpbin.org/post").responseJSON { response in
                    debugPrint(response)
                    
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
                
                //default value for drowsy is 0, aka not drowsy, and declares what parameter to ask of server
                var drowsyStatus: Int = 0
                var drowsyRequest: Parameters = ["drowsyStatus": drowsyStatus]
                    
                //asks server for a value for drowsy or not
                Alamofire.request("https://httpbin.org/get", parameters: drowsyRequest)
                    
                    if drowsyStatus == 1 {
                        
                        Sound.play(file: "Drowsy Alert", fileExtension: "m4a", numberOfLoops: 0)
                        
                        let alert = UIAlertController(title: "Warning", message: "GET OFF THE ROAD SLEEPYHEAD", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                            NSLog("The \"OK\" alert occured.")
                        }))
                        
                        self.present(alert, animated: true, completion: nil)
                        return
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
