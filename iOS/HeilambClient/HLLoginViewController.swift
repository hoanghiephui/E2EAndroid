//
//  HLLoginViewController.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/11/16.
//  Copyright © 2016 YusufX. All rights reserved.
//


import UIKit

class HLLoginViewController: UIViewController, LGChatControllerDelegate {
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usernameTextField.text = DyUser.currentUser?.username
        self.passwordTextField.text = "1111"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func validInputs() -> Bool {
        
        var message : String = "An error happend!"
        var result : Bool = true
        
        if (usernameTextField?.text?.characters.count == 0 ||
            passwordTextField?.text?.characters.count == 0) {
            message = "Missing some field!"
            result = false
        }
        if (result == false) {
            let alert = HLUltils.alertController(message, okTitle: "OK")
            self.presentViewController(alert, animated: true, completion: nil)
        }
        return result
    }
    
    @IBAction func gotoSignUp(sender: AnyObject?) {
        self.performSegueWithIdentifier("login_to_signup", sender: self)
    }
    
    @IBAction func send(sender: AnyObject?) {
        if (self.validInputs()) {
            self.connectButton.enabled = false
            self.activityIndicatorView.startAnimating()
            HLDynamoDBManager.shared.login(self.usernameTextField.text!, password: self.passwordTextField.text!, withBlock: { (error) in
                self.activityIndicatorView.stopAnimating()
                self.connectButton.enabled = true
                if error == nil {
                    if DyUser.currentUser?.privateKey == nil ||  DyUser.currentUser?.publicKey == nil {
                        let alert = HLUltils.alertController("Failure to setup the keys", okTitle: "OK")
                        self.presentViewController(alert, animated: true, completion: nil)
                    } else {
                        self.performSegueWithIdentifier("connect_to_contact", sender: self)
                    }
                } else {
                    let alert = HLUltils.alertController((error?.localizedDescription)!, okTitle: "OK")
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            })
        }
    }
}

