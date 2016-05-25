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

class HLSignupViewController: UIViewController {
    @IBOutlet weak var usernameTextField : UITextField?
    @IBOutlet weak var passwordTextField: UITextField?
    @IBOutlet weak var repaswwordTextField: UITextField?;
    @IBOutlet weak var fullnameTextField: UITextField?
    
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
            let alert : UIAlertController = UIAlertController(title: "E2E", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(OKAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        return result;
    }
    
    @IBAction func signup() {
        if validInputs() {
            
            let credentialProvider = AWSCognitoCredentialsProvider(regionType: AwsRegion, identityPoolId: CognitoIdentityPoolId)
            let configuration = AWSServiceConfiguration(region: AwsRegion, credentialsProvider: credentialProvider)
            AWSDynamoDB.registerDynamoDBWithConfiguration(configuration, forKey: "dynamoDB")            
            
            let dynamoDB = AWSDynamoDB(forKey: "dynamoDB")
            let describeTableInput = AWSDynamoDBDescribeTableInput()
            describeTableInput.tableName = "HL_User"
            let describeTask = dynamoDB.describeTable(describeTableInput)
            
            describeTask.continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
                if (task.error != nil) {
                    let alert : UIAlertController = UIAlertController(title: "E2E", message: task.error?.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                    let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    alert.addAction(OKAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                return nil
            })
        }
    }
}