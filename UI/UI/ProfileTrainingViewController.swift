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
        
        if let trainUrl = Bundle.main.url(forResource: "Begin Testing &Training Instructions", withExtension: "wav") {
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
        
        
        /*if let userid = trainid {
            
            let parameters: Parameters = ["id": userid, "activity": "train"]
        
            Alamofire.request("http://127.0.0.1:5000/index", method: .post, parameters: parameters)
        }*/
        
        Sound.play(file: "Begin Testing &Training Instructions", fileExtension: "wav", numberOfLoops: 0)
        
        mwm?.scanDevice()
        mwm?.enableLogging(withOptions: 1)
        mwm?.enableConsoleLog(true)
        brainWaveDataLocation = (mwm?.enableLogging(withOptions: 1))!
        delay(5) {
            self.mwm?.stopLogging()
            
            print("This is the file location:" + self.brainWaveDataLocation)
            
            var fileName = String(self.brainWaveDataLocation.characters.suffix(27))
            fileName.removeLast(4)
            print("This is the file name:" + fileName)
            
            /*let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")
            print("FilePath: \(fileURL.path)")*/
            
            let fileURL = Bundle.main.url(forResource: "", withExtension: "txt")
            
            /*Alamofire.upload(fileURL!, to: "https://httpbin.org/post").responseJSON { response in
                debugPrint(response)
            }*/
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
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
}
