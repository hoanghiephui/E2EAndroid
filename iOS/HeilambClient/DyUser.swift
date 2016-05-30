//
//  DyUser.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/26/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import AWSDynamoDB
import RNCryptor

public typealias HLResultUserBlock = (DyUser?) -> Void

public class DyUser: AWSDynamoDBObjectModel {
    var _id : String?
    var _username: NSData?
    var _fullname: NSData?
    var _keyK: NSData?
    
    var _isDirty : Bool?
    
    var userId : String? {
        get {
            return _id
        }
    }
    
    var isDirty : Bool {
        get {
            return _isDirty != nil ? _isDirty! : true
        }
    }
    
    var base64KeyQ: String? {
        get {
            let keychain = AWSUICKeyChainStore(service: kKeychainDB)
            let keyQ = keychain.dataForKey(self.userId!)
            let keyQString = keyQ?.base64String
            return keyQString
        }
    }
    
    var username : String? {
        get {
            return _username?.stringUTF8
        }
        set {
            _username = newValue?.dataUTF8
        }
    }

    var fullname : String? {
        get {
            return _fullname?.stringUTF8
        }
        set {
            _fullname = newValue?.dataUTF8
        }
    }
    
    var keyEncryptedK : NSData? {
        get {
            return _keyK
        }
        set {
            _keyK = newValue
        }
    }
    
    var keyDecryptedK : NSData? {
        get {
            if let base64KeyQ = self.base64KeyQ {
                do {
                    let decryptedKeyK = try RNCryptor.decryptData(self.keyEncryptedK!, password: base64KeyQ)
                    return decryptedKeyK
                }
                catch {
                    return nil
                }
            }
            return nil
        }
    }
    
    class var currentUser: DyUser? {
        struct Static {
            static var instance: DyUser? = nil
        }
        
        if (Static.instance == nil) {
            let config = NSUserDefaults.standardUserDefaults();
            if let username = config.objectForKey("username") as? String {
                Static.instance = DyUser(username:username);
            }
        }
        return Static.instance
    }
    
    required public override init() {
        super.init()
    }
    
    required public init(username:String) {
        self._id = HLUltils.uniqueFromString(username)
        self._username = username.dataUTF8
        super.init()
    }
    
    required public init!(coder: NSCoder!) {
        super.init(coder: coder)
    }
    
    class func hashKeyAttribute() -> String {
        return "_id"
    }
    
    class func dynamoDBTableName() -> String {
        return "HL_User"
    }
    
    class func ignoreAttributes() -> [String] {
        return ["keyEncryptedK", "keyDecryptedK", "base64KeyQ", "username", "fullname", "_isDirty", "isDirty"]
    }

    func clone() -> DyUser {
        let copy = DyUser()
        copy._id = _id
        copy._username = _username?.copy() as? NSData
        copy._fullname = _fullname?.copy() as? NSData
        copy._keyK = _keyK?.copy() as? NSData
        return copy
    }
    
    func encrypt() -> Bool {
        if let base64KeyQ = self.base64KeyQ {
            do {
                let decryptedKeyK = try RNCryptor.decryptData(self.keyEncryptedK!, password: base64KeyQ)
                if let base64KeyK = decryptedKeyK.base64String {
                    self._username = RNCryptor.encryptData(self._username!, password: base64KeyK)
                    self._fullname = RNCryptor.encryptData(self._fullname!, password: base64KeyK)
                    return true
                } else {
                    return false
                }
            }
            catch {
                return false
            }
        }
        return false
    }
    
    func dencrypt() -> Bool {
        if let base64KeyQ = self.base64KeyQ {
            do {
                let decryptedKeyK = try RNCryptor.decryptData(self.keyEncryptedK!, password: base64KeyQ)
                if let base64KeyK = decryptedKeyK.base64String {
                    let dencryptedFN = try RNCryptor.decryptData(self._username!, password: base64KeyK)
                    let dencryptedUN = try RNCryptor.decryptData(self._fullname!, password: base64KeyK)
                    self._username = dencryptedUN
                    self._fullname = dencryptedFN
                    return true
                } else {
                    return false
                }
                
            } catch {
                return false
            }
        }
        return false
    }
    
    func save(block:HLErrorBlock) {
        let copy = self.clone()
        if (copy.encrypt()) {
            HLDynamoDBManager.shared.save(copy, withBlock: { (error) in
                if (error == nil) {
                    block(nil)
                } else {
                    block(error)
                }
            })
        } else {
            block(NSError(errorMessage: "Cannot encrypt the data"))
        }
    }
    
    func fetch(block:HLResultUserBlock) {
        HLDynamoDBManager.shared.fetch(self, attributeNameS: "_id", attributeVauleS: self.userId!, tableName: DyUser.dynamoDBTableName(), withBlock: { (item) in
            if let user = item {
                let keychain = AWSUICKeyChainStore(service: kKeychainDB)
                let keyQ = keychain.dataForKey(self.userId!)
                
                if  let encryptedK = (user.objectForKey("_keyK") as! AWSDynamoDBAttributeValue).B,
                    let keyQString = keyQ?.base64String,
                    let encryptedUN = ((user.objectForKey("_username") as! AWSDynamoDBAttributeValue).B),
                    let encryptedFN = ((user.objectForKey("_fullname") as! AWSDynamoDBAttributeValue).B) {
                        do {
                            let keyK = try RNCryptor.decryptData(encryptedK, password: keyQString)
                            let base64KeyK = keyK.base64String!
                            let dencryptedFN = try RNCryptor.decryptData(encryptedFN, password: base64KeyK)
                            let dencryptedUN = try RNCryptor.decryptData(encryptedUN, password: base64KeyK)
                            
                            self._keyK = encryptedK
                            self._fullname = dencryptedFN
                            self._username = dencryptedUN
                            self._isDirty = false
                            block(self)
                        } catch {
                            block(self.clone())
                        }
                    }  else {
                    block(self.clone())
                }                
            } else {
                block(nil)
            }
        })
    }
}