//
//  CreateNewIDViewController.swift
//  UI
//
//  Created by Senior Project on 1/31/18.
//  Copyright © 2018 Senior Project. All rights reserved.
//

import UIKit
import Foundation

class CreateNewIDViewController: UIViewController {
    
    @IBOutlet weak var userid: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func receiveid(_ sender: Any) {
        
        userid.text = "This me ID"
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
