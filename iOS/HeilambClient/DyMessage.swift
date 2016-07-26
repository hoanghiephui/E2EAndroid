//
//  DyMessage.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/30/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import AWSDynamoDB
import RNCryptor

public enum DyMessageStatus : Int {
    case Unknown
    case Unsent
    case Sent
    case Deliveried
}

public class DyMessage: AWSDynamoDBObjectModel {
    var v_id : String?
    var v_fromUserId : String?
    var v_toUserId : String?
    var v_content : NSData?
    var v_createAt : NSData?
    var v_status : NSData?
    
    var id : String? {
        get {
            return v_id
        }
        set {
            v_id = newValue
        }
    }
    
    var fromUserId: String? {
        get {
            return v_fromUserId
        }
        set {
            v_fromUserId = newValue
        }
    }
    
    var toUserId: String? {
        get {
            return v_toUserId
        }
        set {
            v_toUserId = newValue
        }
    }

    var content: String? {
        get {
            return v_content?.stringUTF8
        }
        set {
            v_content = newValue?.dataUTF8
        }
    }
    
    var createdAt: String? {
        get {
            return v_createAt?.stringUTF8
        }
    }

    var status: DyMessageStatus? {
        get {
            if (v_status != nil && v_status?.stringUTF8 != nil) {
                let iv:Int = Int((v_status!.stringUTF8)!)!
                return DyMessageStatus(rawValue: iv)
            } else {
              return DyMessageStatus.Unknown
            }
        }
        set {
            let sv:String = String(newValue!.rawValue)
            v_status = sv.dataUTF8
        }
    }
    
    var createdAtDate: NSDate? {
        get {
            let d = NSDate.aws_dateFromString((v_createAt?.stringUTF8)!, format: AWSDateISO8601DateFormat3)
            return d
        }
    }
    
    required public override init!() {
        let awsDateString = NSDate().aws_stringValue(AWSDateISO8601DateFormat3)
        self.v_id = HLUltils.uniqueFromString(awsDateString)
        self.v_createAt = awsDateString.dataUTF8
        
        super.init()
    }
    
    required public init!(messageId: String!) {
        super.init()
        let awsDateString = NSDate().aws_stringValue(AWSDateISO8601DateFormat3)
        self.v_id = messageId
        self.v_createAt = awsDateString.dataUTF8
    }
    
    required public init!(coder: NSCoder!) {
        super.init(coder: coder)
    }
    
    required public convenience init!(messagePackage: HLMessagePackage!, toUserId: String!) {
        self.init()
        self.fromUserId = messagePackage.fromUser.id
        self.toUserId = toUserId
        self.content = messagePackage.content
        self.status = DyMessageStatus.Unknown
    }
    
    public override init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: ()) throws {
         try super.init(dictionary: dictionaryValue, error: error)
    }
    
    func clone() -> DyMessage {
        let copy = DyMessage(messageId: v_id)
        copy.v_fromUserId = v_fromUserId?.copy() as? String
        copy.v_toUserId = v_toUserId?.copy() as? String
        copy.v_content = v_content?.copy() as? NSData
        copy.v_status = v_status?.copy() as? NSData
        copy.v_createAt = v_createAt?.copy() as? NSData
        return copy
    }
    
    func copyData(other : DyMessage) {
        self.v_id = other.v_id
        self.v_fromUserId = other.v_fromUserId?.copy() as? String
        self.v_toUserId = other.v_toUserId?.copy() as? String
        self.v_content = other.v_content?.copy() as? NSData
        self.v_status = other.v_status?.copy() as? NSData
        self.v_createAt = other.v_createAt?.copy() as? NSData
    }
    
    func encrypt() -> Bool {
        if let base64KeyQ = DyUser.currentUser!.base64KeyQ {
            do {
                let decryptedKeyK = try RNCryptor.decryptData(DyUser.currentUser!.keyEncryptedK!, password: base64KeyQ)
                if let base64KeyK = decryptedKeyK.stringBase64 {
                    self.v_content = RNCryptor.encryptData(self.v_content!, password: base64KeyK)
                    self.v_status = RNCryptor.encryptData(self.v_status!, password: base64KeyK)
                    self.v_createAt = RNCryptor.encryptData(self.v_createAt!, password: base64KeyK)
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
                    let dencryptedCTE = try RNCryptor.decryptData(self.v_content!, password: base64KeyK)
                    let dencryptedSTU = try RNCryptor.decryptData(self.v_status!, password: base64KeyK)
                    let dencryptedCRT = try RNCryptor.decryptData(self.v_createAt!, password: base64KeyK)
                    self.v_content = dencryptedCTE
                    self.v_status = dencryptedSTU
                    self.v_createAt = dencryptedCRT
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
    
    func fetchAndUpdate(status: DyMessageStatus, block: HLErrorBlock) {
        HLDynamoDBManager.shared.fetchModel(DyMessage.self, haskKey: self.id!, block: { (item) in
            let dyMsg  = item as! DyMessage
            if let base64KeyQ = DyUser.currentUser!.base64KeyQ {
                do {
                    let decryptedKeyK = try RNCryptor.decryptData(DyUser.currentUser!.keyEncryptedK!, password: base64KeyQ)
                    if let base64KeyK = decryptedKeyK.stringBase64 {
                        dyMsg.status = status
                        dyMsg.v_status = RNCryptor.encryptData(dyMsg.v_status!, password: base64KeyK)
                        self.copyData(dyMsg)
                        HLDynamoDBManager.shared.save(dyMsg, withBlock: { (error) in
                            block(error)
                        })
                    } else {
                        block(NSError(errorMessage: "No exist keyK"))
                    }
                }
                catch {
                    block(NSError(errorMessage: "Cannot decrypt message"))
                }
            } else {
                block(NSError(errorMessage: "No exist keyQ"))
            }
        })
    }
    
    class func fetchAll(block : HLResultArrayBlock) {
        HLDynamoDBManager.shared.fetchLimit(DyMessage.self, limit: 0, block: { (result) in
            if let items = result as? [DyMessage]{
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
        return "v_id"
    }
    
    class func dynamoDBTableName() -> String {
        return "HL_" + (DyUser.currentUser?.userId)! + "_Message"
    }
    
    class func ignoreAttributes() -> [String] {
        return ["id", "fromUserId", "toUserId", "content", "createdAt", "status"]
    }
}