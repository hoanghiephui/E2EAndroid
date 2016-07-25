//
//  ViewController.swift
//  HeilambOSX
//
//  Created by Sinbad Flyce on 6/27/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Cocoa
import AWSCore
import AWSIoT
import AWSDynamoDB
import BluetoothKit

class HLLoginViewController: NSViewController {

    @IBOutlet weak var indicatorView : NSProgressIndicator!;
    @IBOutlet weak var txtUsername: NSTextField!;
    @IBOutlet weak var txtPassword: NSSecureTextField!;
    
    override func viewDidLoad() {
        super.viewDidLoad()

        txtUsername.stringValue = "yusuf"
        txtPassword.stringValue = "1111"
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func onLogin(sender: AnyObject! ) {
        if txtUsername.stringValue.characters.count == 0 || txtPassword.stringValue.characters.count == 0 {
            HLUltils.alert(message: "Please enter username or password.", window: self.view.window)
            return;
        }
        
        self.indicatorView.displayedWhenStopped = false;
        self.indicatorView.hidden = false;
        self.indicatorView.startAnimation(sender);
        HLDynamoDBManager.shared.login(txtUsername.stringValue, password: txtPassword.stringValue) { (error) in
            self.indicatorView.stopAnimation(sender);
            if let err = error {
                HLUltils.alertError(err, window: self.view.window)
            } else {
                self.performSegueWithIdentifier("login_to_split", sender: self)
            }
        };
    }
}

