//
//  HLSignupViewController.swift
//  HeilambOSX
//
//  Created by Sinbad Flyce on 7/29/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import Cocoa

class HLSignupViewController: NSViewController {
    @IBOutlet weak var txtUsername: NSTextField!
    @IBOutlet weak var txtFullName: NSTextField!
    @IBOutlet weak var txtPassword: NSSecureTextField!
    @IBOutlet weak var txtConfirmPwd: NSSecureTextField!
    @IBOutlet weak var ctlSpinView: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
#if false
        self.txtFullName.stringValue = "David Saib"
        self.txtUsername.stringValue = "david"
        self.txtPassword.stringValue = "1111"
        self.txtConfirmPwd.stringValue = "1111"
#endif
    }
    
    @IBAction func signup(sender: AnyObject!) {
        if (self.validInputs()) {
            self.ctlSpinView.hidden = false
            self.ctlSpinView.startAnimation(self)
            HLDynamoDBManager.shared.signUp(self.txtUsername.stringValue, password: self.txtPassword.stringValue, fullname: self.txtFullName.stringValue, withBlock: { (error) in
                self.ctlSpinView.stopAnimation(self)
                if let err = error {
                    HLUltils.alertError(err as! NSError)
                } else {                    
                    self.dismissController(self);
                }
            });
        }
    }

    @IBAction func cancel(sender: AnyObject!) {
        self.dismissController(self);
    }
    
    func validInputs() -> Bool {
        
        var message : String = "An error happend!";
        var result : Bool = true;
        
        if (txtUsername.stringValue.characters.count == 0 ||
            txtFullName.stringValue.characters.count == 0 ||
            txtPassword.stringValue.characters.count == 0 ||
            txtConfirmPwd.stringValue.characters.count == 0) {
            message = "Missing some field!"
            result = false;
        }
        
        if (txtPassword.stringValue != txtConfirmPwd.stringValue) {
            message = "Doesn't match the password!"
            result = false;
        }
        
        if (result == false) {
            HLUltils.alert(message: message)
        }
        return result;
    }

}