//
//  DyContact.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/30/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import AWSDynamoDB
import RNCryptor

public class DyContact: AWSDynamoDBObjectModel {
    var _ctId : String?
    var _ctUsername : NSData?
    var _ctFullname : NSData?
    
    var id : String? {
        get {
            return _ctId
        }
        set {
            _ctId = newValue
        }
    }
    
    var username : String? {
        get {
            return _ctUsername?.stringUTF8
        }
        set {
            _ctUsername = newValue?.dataUTF8
        }
    }

    var fullname : String? {
        get {
            return _ctFullname?.stringUTF8
        }
        set {
            _ctFullname = newValue?.dataUTF8
        }
    }
    
    func clone() -> DyContact {
        let copy = DyContact()
        copy._ctId = _ctId
        copy._ctUsername = _ctUsername?.copy() as? NSData
        copy._ctFullname = _ctFullname?.copy() as? NSData
        return copy
    }

    func encrypt() -> Bool {
        if let base64KeyQ = DyUser.currentUser!.base64KeyQ {
            do {
                let decryptedKeyK = try RNCryptor.decryptData(DyUser.currentUser!.keyEncryptedK!, password: base64KeyQ)
                if let base64KeyK = decryptedKeyK.base64String {
                    self._ctUsername = RNCryptor.encryptData(self._ctUsername!, password: base64KeyK)
                    self._ctFullname = RNCryptor.encryptData(self._ctFullname!, password: base64KeyK)
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
        if let keyK = DyUser.currentUser!.keyDecryptedK {
            do {
                if let base64KeyK = keyK.base64String {
                    let dencryptedUN = try RNCryptor.decryptData(self._ctUsername!, password: base64KeyK)
                    let dencryptedFN = try RNCryptor.decryptData(self._ctFullname!, password: base64KeyK)
                    self._ctUsername = dencryptedUN
                    self._ctFullname = dencryptedFN
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
        copy.encrypt()
        HLDynamoDBManager.shared.save(copy) { (error) in
            block(error)
        }
    }
    
    class func fetchAll(block : HLResultArrayBlock) {
        HLDynamoDBManager.shared.fetchLimit(DyContact.self, limit: 0, block: { (result) in
            if let items = result as? [DyContact]{
                for anItem in items {
                    anItem.dencrypt()
                }
                block(result)
            } else {
                block(nil)
            }
        })
    }
    
    class func hashKeyAttribute() -> String {
        return "_ctId"
    }
        
    class func dynamoDBTableName() -> String {
        return "HL_" + (DyUser.currentUser?.userId)! + "_Contact"
    }
    
    class func ignoreAttributes() -> [String] {
        return ["id", "username", "fullname"]
    }
    
}