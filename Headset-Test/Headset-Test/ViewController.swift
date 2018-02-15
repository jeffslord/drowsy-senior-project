//
//  ViewController.swift
//  Headset-Test
//
//  Created by Sammy Eang on 2/15/18.
//  Copyright © 2018 Sammy Eang. All rights reserved.
//

import UIKit
import Mindwave

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        @objc mwDevice = [MWMDevice sharedInstance];
        @objc [mwDevice setDelegate:self];
        
        connectDevice()
        
        (void)enableConsoleLog:(BOOL)enabled;

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

