//
//  HLSignupViewController.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/25/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import UIKit
import AWSDynamoDB
import RNCryptor

class HLSignupViewController: UIViewController {
    @IBOutlet weak var usernameTextField : UITextField?
    @IBOutlet weak var passwordTextField: UITextField?
    @IBOutlet weak var repaswwordTextField: UITextField?;
    @IBOutlet weak var fullnameTextField: UITextField?
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        usernameTextField?.text = "sinbadflyce"
        fullnameTextField?.text = "Sinbad Flyce"
        passwordTextField?.text = "1111"
        repaswwordTextField?.text = "1111"
    }
    
    func validInputs() -> Bool {
        
        var message : String = "An error happend!";
        var result : Bool = true;
        
        if (usernameTextField?.text?.characters.count == 0 ||
            fullnameTextField?.text?.characters.count == 0 ||
            passwordTextField?.text?.characters.count == 0 ||
            repaswwordTextField?.text?.characters.count == 0) {
            message = "Missing some field!"
            result = false;
        }
        
        if (passwordTextField?.text != repaswwordTextField?.text) {
            message = "Doesn't match the password!"
            result = false;
        }
        
        if (result == false) {
            let alert = HLUltils.alertController(message, okTitle: "OK")
            self.presentViewController(alert, animated: true, completion: nil)
        }
        return result;
    }
    
    @IBAction func signup() {
        if validInputs() {
            self.indicatorView?.hidden = false
            self.indicatorView?.startAnimating()
            HLDynamoDBManager.shared.signUp((self.usernameTextField?.text)!, password: (self.passwordTextField?.text)!, fullname: (self.fullnameTextField?.text)!, withBlock: { (error) in
                self.indicatorView?.stopAnimating()
                if let err = error {
                    let alert = HLUltils.alertController((err.localizedDescription)!, okTitle: "OK")
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            });
        }
    }
}