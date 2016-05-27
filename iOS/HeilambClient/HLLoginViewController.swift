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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func send(sender: AnyObject?) {
        self.connectButton.enabled = false
        self.activityIndicatorView.startAnimating()
        if (self.usernameTextField.text != nil &&
            self.passwordTextField.text != nil) {
            let currentUser = HLUser()
            currentUser.username = usernameTextField.text
            currentUser.fullname = passwordTextField.text
            HLConnectionManager.shared.connectWithUser(currentUser, statusCallback: { (success) in
                self.activityIndicatorView.stopAnimating()
                self.connectButton.enabled = true
                if (success) {
                    self.performSegueWithIdentifier("connect_to_contact", sender: self)
                } else {
                    let alertController = UIAlertController(title: "Error", message: "Cannot to connect to AWS IoT", preferredStyle: UIAlertControllerStyle.Alert)
                    let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    alertController.addAction(OKAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            })
        }
    }
}

