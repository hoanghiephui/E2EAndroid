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
    var v_ctId : String?
    var v_ctUsername : NSData?
    var v_ctFullname : NSData?
    var v_ctPublicKey : NSData?
    
    var id : String? {
        get {
            return v_ctId
        }
        set {
            v_ctId = newValue
        }
    }
    
    var username : String? {
        get {
            return v_ctUsername?.stringUTF8
        }
        set {
            v_ctUsername = newValue?.dataUTF8
        }
    }

    var fullname : String? {
        get {
            return v_ctFullname?.stringUTF8
        }
        set {
            v_ctFullname = newValue?.dataUTF8
        }
    }
    
    var publicKey : NSData? {
        get {
            return v_ctPublicKey
        }
        set {
            v_ctPublicKey = newValue
        }
    }
    
    func clone() -> DyContact {
        let copy = DyContact()
        copy.v_ctId = v_ctId
        copy.v_ctUsername = v_ctUsername?.copy() as? NSData
        copy.v_ctFullname = v_ctFullname?.copy() as? NSData
        copy.v_ctPublicKey = v_ctPublicKey?.copy() as? NSData
        return copy
    }

    func encrypt() -> Bool {
        if let base64KeyQ = DyUser.currentUser!.base64KeyQ {
            do {
                let decryptedKeyK = try RNCryptor.decryptData(DyUser.currentUser!.keyEncryptedK!, password: base64KeyQ)
                if let base64KeyK = decryptedKeyK.stringBase64 {
                    self.v_ctUsername = RNCryptor.encryptData(self.v_ctUsername!, password: base64KeyK)
                    self.v_ctFullname = RNCryptor.encryptData(self.v_ctFullname!, password: base64KeyK)
                    if let pdk = self.v_ctPublicKey {
                        self.v_ctPublicKey = RNCryptor.encryptData(pdk, password: base64KeyK)
                    }
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
                if let base64KeyK = keyK.stringBase64 {
                    let dencryptedUN = try RNCryptor.decryptData(self.v_ctUsername!, password: base64KeyK)
                    let dencryptedFN = try RNCryptor.decryptData(self.v_ctFullname!, password: base64KeyK)
                    self.v_ctUsername = dencryptedUN
                    self.v_ctFullname = dencryptedFN
                    
                    if let pkd = self.v_ctPublicKey {
                        let dencryptedPK = try? RNCryptor.decryptData(pkd, password: base64KeyK)
                        self.v_ctPublicKey = dencryptedPK
                    }
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
        return "v_ctId"
    }
        
    class func dynamoDBTableName() -> String {
        return "HL_" + (DyUser.currentUser?.userId)! + "_Contact"
    }
    
    class func ignoreAttributes() -> [String] {
        return ["id", "username", "fullname", "publicKey"]
    }
    
}