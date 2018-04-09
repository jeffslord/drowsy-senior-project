//
//  ViewController.swift
//  UI
//
//  Created by Senior Project on 11/21/17.
//  Copyright © 2017 Senior Project. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var id: UITextField!
    
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.hideKeyboardWhenTappedAround()

            self.id.delegate = self
            
    }
    
    @IBAction func training(_ sender: Any) {
        
        if let ptvc = storyboard?.instantiateViewController(withIdentifier: "ProfileTraining") as? ProfileTrainingViewController {
            
            //sends the data from the text field to the ProfileTrainingViewController
            ptvc.trainid = id.text
            
            // 3: now pushes our current ViewController onto the navigation controller
            navigationController?.pushViewController(ptvc, animated: true)
        }
    }
    
    @IBAction func test(_ sender: Any) {
        if let tvc = storyboard?.instantiateViewController(withIdentifier: "Testing") as? TestingViewController {
            
            //sends the data from the text field to the ProfileTrainingViewController
            tvc.trainid = id.text
            
            // 3: now pushes our current ViewController onto the navigation controller
            navigationController?.pushViewController(tvc, animated: true)
        }
    }
    
    @IBAction func run(_ sender: Any) {
        if let rvc = storyboard?.instantiateViewController(withIdentifier: "Tracking") as? RunViewController {
            
            //sends the data from the text field to the ProfileTrainingViewController
            rvc.trainid = id.text
            
            // 3: now pushes our current ViewController onto the navigation controller
            navigationController?.pushViewController(rvc, animated: true)
        }
    }
    
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}

