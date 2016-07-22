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
    public static let kRSATag = "com.yusuf.e2e"
    
    class var SaltData : NSData? {
        return HLUltils.kSalt.dataUsingEncoding(NSUTF8StringEncoding);
    }
    
    class var RsaTag : NSData {
        return kRSATag.dataUTF8!
    }
    
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
#if os(iOS)
    class func alertController(message: String, okTitle: String) -> UIAlertController{
        let alert : UIAlertController = UIAlertController(title: "E2EE", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let OKAction = UIAlertAction(title: okTitle, style: .Default, handler: nil)
        alert.addAction(OKAction)
        return alert
    }
#elseif os(OSX)
    class func alert (message message : String, window: NSWindow?  = nil){
        let alert = NSAlert()
        alert.addButtonWithTitle("Ok");
        alert.messageText = "E2E OSX"
        alert.informativeText = message
        if let w = window {
            alert.beginSheetModalForWindow(w, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
    
    class func alert (error error : NSError, window: NSWindow?) {
        self.alert(message: error.localizedDescription, window: window)
    }
    
#endif
    
    class func executeDelay(inSecond: Double, block: () -> Void)  {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(inSecond * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            block()
        }
    }

}


public extension String {
    var dataUTF8 : NSData? {
        get {
            return self.dataUsingEncoding(NSUTF8StringEncoding)
        }
    }
    
    var dataBase64 : NSData? {
        get {
            return NSData(base64EncodedString: self, options:NSDataBase64DecodingOptions(rawValue: 0))
        }
    }
}

public extension NSData {
    var stringUTF8 :  String? {
        get {
            return String(data: self, encoding: NSUTF8StringEncoding)
        }
    }
    
    var stringBase64 : String? {
        get {
            return self.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        }
    }
}

public extension NSError {
    convenience init(errorMessage: String) {
        self.init(domain: "com.heilamb.error", code: -1, userInfo: [NSLocalizedDescriptionKey : errorMessage])
    }
}