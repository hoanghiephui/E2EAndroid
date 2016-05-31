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
    var _msId : String?
    var _fromUser : NSData?
    var _toUser : NSData?
    var _content : NSData?
    var _createAt : NSData?
    var _status : NSData?
    
    var id : String? {
        get {
            return _msId
        }
        set {
            _msId = newValue
        }
    }
    
    var fromUser: String? {
        get {
            return _fromUser?.stringUTF8
        }
        set {
            _fromUser = newValue?.dataUTF8
        }
    }
    
    var toUser: String? {
        get {
            return _toUser?.stringUTF8
        }
        set {
            _toUser = newValue?.dataUTF8
        }
    }

    var content: String? {
        get {
            return _content?.stringUTF8
        }
        set {
            _content = newValue?.dataUTF8
        }
    }
    
    var createdAt: String? {
        get {
            return _createAt?.stringUTF8
        }
        set {
            _createAt = newValue?.dataUTF8
        }
    }

    var status: DyMessageStatus? {
        get {
            if (_status != nil && _status?.stringUTF8 != nil) {
                let iv:Int = Int((_status!.stringUTF8)!)!
                return DyMessageStatus(rawValue: iv)
            } else {
              return DyMessageStatus.Unknown
            }
        }
        set {
            let sv:String = String(newValue!.rawValue)
            _status = sv.dataUTF8
        }
    }
    
    var createdAtDate: NSDate? {
        get {
            let d = Double((_createAt?.stringUTF8)!)
            return NSDate(timeIntervalSince1970: d!)
        }
    }
    
    required public override init!() {
        super.init()
    }
    
    required public init!(messageId: String!) {
        super.init()
        self._msId = messageId
    }
    
    required public init!(coder: NSCoder!) {
        super.init(coder: coder)
    }
    
    public override init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: ()) throws {
         try super.init(dictionary: dictionaryValue, error: error)
    }
    
    func clone() -> DyMessage {
        let copy = DyMessage(messageId: _msId)
        copy._fromUser = _fromUser?.copy() as? NSData
        copy._toUser = _toUser?.copy() as? NSData
        copy._content = _content?.copy() as? NSData
        copy._status = _status?.copy() as? NSData
        copy._createAt = _createAt?.copy() as? NSData
        return copy
    }
    
    func copyData(other : DyMessage) {
        self._msId = other._msId
        self._fromUser = other._fromUser?.copy() as? NSData
        self._toUser = other._toUser?.copy() as? NSData
        self._content = other._content?.copy() as? NSData
        self._status = other._status?.copy() as? NSData
        self._createAt = other._createAt?.copy() as? NSData
    }
    
    func encrypt() -> Bool {
        if let base64KeyQ = DyUser.currentUser!.base64KeyQ {
            do {
                let decryptedKeyK = try RNCryptor.decryptData(DyUser.currentUser!.keyEncryptedK!, password: base64KeyQ)
                if let base64KeyK = decryptedKeyK.base64String {
                    self._fromUser = RNCryptor.encryptData(self._fromUser!, password: base64KeyK)
                    self._toUser = RNCryptor.encryptData(self._toUser!, password: base64KeyK)
                    self._content = RNCryptor.encryptData(self._content!, password: base64KeyK)
                    self._status = RNCryptor.encryptData(self._status!, password: base64KeyK)
                    self._createAt = RNCryptor.encryptData(self._createAt!, password: base64KeyK)
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
                    let dencryptedFUI = try RNCryptor.decryptData(self._fromUser!, password: base64KeyK)
                    let dencryptedTUI = try RNCryptor.decryptData(self._toUser!, password: base64KeyK)
                    let dencryptedCTE = try RNCryptor.decryptData(self._content!, password: base64KeyK)
                    let dencryptedSTU = try RNCryptor.decryptData(self._status!, password: base64KeyK)
                    let dencryptedCRT = try RNCryptor.decryptData(self._createAt!, password: base64KeyK)
                    self._fromUser = dencryptedFUI
                    self._toUser = dencryptedTUI
                    self._content = dencryptedCTE
                    self._status = dencryptedSTU
                    self._createAt = dencryptedCRT
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
                    if let base64KeyK = decryptedKeyK.base64String {
                        dyMsg.status = status
                        dyMsg._status = RNCryptor.encryptData(dyMsg._status!, password: base64KeyK)
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
        return "_msId"
    }
    
    class func dynamoDBTableName() -> String {
        return "HL_" + (DyUser.currentUser?.userId)! + "_Message"
    }
    
    class func ignoreAttributes() -> [String] {
        return ["id", "fromUser", "toUser", "content", "createdAt", "status"]
    }
}