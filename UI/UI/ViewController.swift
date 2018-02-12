//
//  ViewController.swift
//  UI
//
//  Created by Senior Project on 11/21/17.
//  Copyright © 2017 Senior Project. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var id: UITextField!
    
        override func viewDidLoad() {
            super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func training(_ sender: Any) {
        
        if let ptvc = storyboard?.instantiateViewController(withIdentifier: "ProfileTraining") as? ProfileTrainingViewController {
            
            //sends the data from the text field to the ProfileTrainingViewController
            ptvc.trainid = id.text
            
            // 3: now pushes our current ViewController onto the navigation controller
            navigationController?.pushViewController(ptvc, animated: true)
        }
    }
    
    
    
}

