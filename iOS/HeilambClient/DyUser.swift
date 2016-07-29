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

struct Static {
    static var instance: DyUser? = nil
}

public class DyUser: AWSDynamoDBObjectModel {
    var v_id : String?
    var v_username: NSData?
    var v_fullname: NSData?
    var v_keyK: NSData?
    var v_privateKey : NSData?
    var v_publicKey : NSData?
    
    var _isDirty : Bool?
    
    var userId : String? {
        get {
            return v_id
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
            let keyQString = keyQ?.stringBase64
            return keyQString
        }
    }
    
    var username : String? {
        get {
            return v_username?.stringUTF8
        }
        set {
            v_username = newValue?.dataUTF8
        }
    }

    var fullname : String? {
        get {
            return v_fullname?.stringUTF8
        }
        set {
            v_fullname = newValue?.dataUTF8
        }
    }
    
    var keyEncryptedK : NSData? {
        get {
            return v_keyK
        }
        set {
            v_keyK = newValue
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
    
    var privateKey : NSData? {
        get {
            return v_privateKey
        }
        set {
            v_privateKey = newValue
        }
    }
    
    var publicKey : NSData? {
        get {
            return v_publicKey
        }
        set {
            v_publicKey = newValue
        }
    }
    
    var onceTagPrefix: String {
        get {
            return "com.heilamb." + v_id!
        }
    }
    
    class var currentUser: DyUser? {
        if (Static.instance == nil) {
            let config = NSUserDefaults.standardUserDefaults()
            if let username = config.objectForKey("username") as? String {
                Static.instance = DyUser(username:username);
            }
        }
        return Static.instance
    }
    
    class func clear() {
        Static.instance = nil
    }
    
    required public override init() {
        super.init()
    }
    
    required public init(username:String) {
        self.v_id = HLUltils.uniqueFromString(username)
        self.v_username = username.dataUTF8
        super.init()
    }
    
    required public override init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: ()) throws {
        try super.init(dictionary: dictionaryValue, error: ())
    }
    
    required public init!(coder: NSCoder!) {
        super.init(coder: coder)
    }
    
    class func hashKeyAttribute() -> String {
        return "v_id"
    }
    
    class func dynamoDBTableName() -> String {
        return "HL_User"
    }
    
    class func ignoreAttributes() -> [String] {
        return ["keyEncryptedK", "keyDecryptedK", "base64KeyQ", "username", "fullname", "_isDirty", "isDirty", "privateKey", "publicKey"]
    }

    func clone() -> DyUser {
        let copy = DyUser()
        copy.v_id = v_id
        copy.v_username = v_username?.copy() as? NSData
        copy.v_fullname = v_fullname?.copy() as? NSData
        copy.v_keyK = v_keyK?.copy() as? NSData
        copy.v_privateKey = v_privateKey?.copy() as? NSData
        copy.v_publicKey = v_publicKey?.copy() as? NSData
        return copy
    }
    
    func copyData(other: DyUser) {
        self.v_id = other.v_id
        self.v_username = other.v_username?.copy() as? NSData
        self.v_fullname = other.v_fullname?.copy() as? NSData
        self.v_keyK = other.v_keyK?.copy() as? NSData
        self.v_privateKey = other.privateKey?.copy() as? NSData
        self.v_publicKey = other.v_publicKey?.copy() as? NSData
    }
    
    func encrypt() -> Bool {
        if let base64KeyQ = self.base64KeyQ {
            do {
                let decryptedKeyK = try RNCryptor.decryptData(self.keyEncryptedK!, password: base64KeyQ)
                if let base64KeyK = decryptedKeyK.stringBase64 {
                    self.v_username = RNCryptor.encryptData(self.v_username!, password: base64KeyK)
                    self.v_fullname = RNCryptor.encryptData(self.v_fullname!, password: base64KeyK)
                    self.v_privateKey = RNCryptor.encryptData(self.v_privateKey!, password: base64KeyK)
                    self.v_publicKey = RNCryptor.encryptData(self.v_publicKey!, password: base64KeyK)
                    self
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
    
    func decrypt() -> Bool {
        if let base64KeyQ = self.base64KeyQ {
            do {
                let decryptedKeyK = try RNCryptor.decryptData(self.keyEncryptedK!, password: base64KeyQ)
                if let base64KeyK = decryptedKeyK.stringBase64 {
                    let dencryptedUN = try RNCryptor.decryptData(self.v_username!, password: base64KeyK)
                    let dencryptedFN = try RNCryptor.decryptData(self.v_fullname!, password: base64KeyK)
                    let dencryptedPR = try RNCryptor.decryptData(self.v_privateKey!, password: base64KeyK)
                    let dencryptedPU = try RNCryptor.decryptData(self.v_publicKey!, password: base64KeyK)
                    self.v_username = dencryptedUN
                    self.v_fullname = dencryptedFN
                    self.v_privateKey = dencryptedPR
                    self.v_publicKey = dencryptedPU
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
        HLDynamoDBManager.shared.fetchModel(DyUser.self, haskKey: self.v_id!, block: { (model) in
            if let dyUser = model as? DyUser {
                if (dyUser.decrypt() == true) {
                    self.copyData(dyUser)
                    block(dyUser)
                } else {
                    block(nil)
                }
            } else {
                block(nil)
            }
        })
    }
}