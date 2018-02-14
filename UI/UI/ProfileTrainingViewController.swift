//
//  ProfileTrainingViewController.swift
//  UI
//
//  Created by Sammy Eang on 2/12/18.
//  Copyright © 2018 Senior Project. All rights reserved.
//

import UIKit

class ProfileTrainingViewController: UIViewController {
    var trainid: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //mwDevice = [MWMDevice sharedInstance];
        //[mwDevice setDelegate:self];
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func trainingbegin(_ sender: Any) {
        print("test")
        let testurl = URL(string:"https:/jsonplaceholder.typicode.com/posts")
        URLSession.shared.dataTask(with: testurl!){(data, response, error) in
            if error != nil{
                print(error ?? "Error not read")
            }
            let data = data
            print(data ?? "Data not retrieved")
        }
        print("Finished button")
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
