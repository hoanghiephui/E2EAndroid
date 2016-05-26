//
//  HLUltils.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/18/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import Hashids_Swift

public class HLUltils {
    
    public static let kSalt = "HL-SALT"
    
    class func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("[HL] Something went wrong")
            }
        }
        return nil
    }
    
    class func generateTagPrefix(len : Int) -> String! {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0 ... len {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString as String
    }
    
    class func uniqueFromString(stringValue:String!) -> String? {
        let hashids = Hashids(salt: stringValue, minHashLength: 10)
        return hashids.encode(9)
    }
    
    class func alertController(message: String, okTitle: String) -> UIAlertController{
        let alert : UIAlertController = UIAlertController(title: "E2EE", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let OKAction = UIAlertAction(title: okTitle, style: .Default, handler: nil)
        alert.addAction(OKAction)
        return alert
    }
}