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
        usernameTextField?.text = "ysflyce"
        fullnameTextField?.text = "Ys Flyce"
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
            HLDynamoDBManager.shared.existTable(DyUser.dynamoDBTableName(), withBlock: { (error) -> Void in
                if (error != nil) {
                    self.indicatorView?.stopAnimating()
                    let alert = HLUltils.alertController((error?.localizedDescription)!, okTitle: "OK")
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    if let password = self.passwordTextField?.text {
                        let dyUser = DyUser(username: (self.usernameTextField?.text!)!)
                        HLDynamoDBManager.shared.existUser(dyUser, withBlock: { (count) in
                            if (count == 0) {
                                if let salt = HLUltils.kSalt.dataUsingEncoding(NSUTF8StringEncoding) {
                                    let keyQ = RNCryptor.FormatV3.keyForPassword(password, salt: salt)
                                    let randomSalt = HLUltils.generateTagPrefix(8).dataUsingEncoding(NSUTF8StringEncoding)!
                                    let keyK = RNCryptor.FormatV3.keyForPassword(password, salt: randomSalt)
                                    let base64KeyQ = keyQ.base64EncodedStringWithOptions([])
                                    let base64KeyK = keyK.base64EncodedStringWithOptions([])
                                    let keyEncryptedK = RNCryptor.encryptData(keyK, password: base64KeyQ)
                                    
                                    dyUser.keyK = keyEncryptedK.base64EncodedStringWithOptions([])
                                    dyUser.fullname = (self.fullnameTextField?.text!)!
                                    dyUser.encrypt(base64KeyK)
                                    HLDynamoDBManager.shared.saveUser(dyUser, withBlock: { (error) in
                                        if (error != nil) {
                                            let alert = HLUltils.alertController((error?.localizedDescription)!, okTitle: "OK")
                                            self.presentViewController(alert, animated: true, completion: nil)
                                            
                                        } else {
                                            let keychain = AWSUICKeyChainStore()
                                            keychain.setData(keyQ, forKey: (self.usernameTextField?.text)!)
                                        }
                                        self.indicatorView?.stopAnimating()
                                    })
                                } else {
                                    self.indicatorView?.stopAnimating()
                                }
                            } else {
                                self.indicatorView?.stopAnimating()
                                let alert = HLUltils.alertController("The username was already exist. Please enter an other", okTitle: "OK")
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                        })
                    }
                }
            })            
        }
    }
}