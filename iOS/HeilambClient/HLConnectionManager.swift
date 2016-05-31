//
//  HLConnectionManager.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/18/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import AWSCore
import AWSIoT
import Heimdall
import RNCryptor

let kHandshakeChannel = "kHandshakeChannel"
let kPrefixHeimdall = "com.sinbadflyce.aws.e2ee.chat"

public class HLConnectionManager {
    let credentialProvider : AWSCognitoCredentialsProvider;
    
    var iotDataManager: AWSIoTDataManager!
    var connected: Bool!
    var publicKeys : [String: String]!
    var localHeimdall : Heimdall!
    
    var currentUser : HLUser!
    public var onReceivedMessage: ((HLMessagePackage?) -> ())?
    public var onHandshakeMessage: ((HLMessagePackage?) -> ())?
    public var onAgreedMessage: ((HLMessagePackage?) -> ())?
    public var onDeliveriedMessage: ((HLMessagePackage?) -> ())?
    
    class var shared: HLConnectionManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: HLConnectionManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = HLConnectionManager()
        }
        return Static.instance!
    }
    
    required public init() {
        credentialProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: CognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: credentialProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
        
        connected = false
        currentUser = nil
        onReceivedMessage = nil
        onHandshakeMessage = nil
        publicKeys = [:]
        
        localHeimdall = Heimdall(tagPrefix: HLUltils.generateTagPrefix(12), keySize: 2048)
    }
    
    public func connectWithUser(user: HLUser!, statusCallback callback: ((Bool) -> Void)!) {
        self.currentUser = user
        let myBundle = NSBundle.mainBundle()
        let myImages = myBundle.pathsForResourcesOfType("p12" as String, inDirectory:nil)
        if (myImages.count > 0) {
            
            if let data = NSData(contentsOfFile:myImages[0]) {
                if AWSIoTManager.importIdentityFromPKCS12Data( data, passPhrase:"", certificateId:myImages[0]) {
                    dispatch_async( dispatch_get_main_queue()) {
                        self.iotDataManager.connectWithClientId( user.username, cleanSession:true, certificateId:myImages[0],statusCallback: { ( status ) in
                            dispatch_async( dispatch_get_main_queue()) {
                                print("[HL] connection status = \(status.rawValue)")
                                switch(status)
                                {
                                case .Connecting:
                                    self.connected = false
                                    break
                                    
                                case .Connected:
                                    self.connected = true
                                    callback(true)
                                    self.finalSuccessConnection()
                                    
                                case .ConnectionRefused:
                                    self.connected = false
                                    callback(false)
                                    break
                                    
                                case .ConnectionError:
                                    self.connected = false
                                    callback(false)
                                    break
                                    
                                case .ProtocolError:
                                    self.connected = false
                                    callback(false)
                                    break
                                    
                                default:
                                    self.connected = false
                                    break
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    // -------- -------- -------- -------- -------- -------- -------- -------- ---------------- -------- -------- --------  //
    // PRIVATE                                                                                                              //
    // -------- -------- -------- -------- -------- -------- -------- -------- ---------------- -------- -------- --------  //
    
    func saveContact(messagePackage : HLMessagePackage)  {
        let dyContact = DyContact()
        dyContact.id = messagePackage.fromUser.id
        dyContact.username = messagePackage.fromUser.username
        dyContact.fullname = messagePackage.fromUser.fullname        
        dyContact.save { (error) in
            if error != nil {
                print(error?.localizedDescription)
            }
        }
    }
    
    func saveMessage(fromUserId: String, toUserId: String, textMessage: String, status: DyMessageStatus, block: (String?) -> Void) {
        let strTime = String(NSDate().timeIntervalSince1970)
        let dyMessage = DyMessage(messageId: HLUltils.uniqueFromString(strTime))
        dyMessage.fromUser = fromUserId
        dyMessage.toUser = toUserId
        dyMessage.content = textMessage
        dyMessage.status = status
        dyMessage.createdAt = strTime
        dyMessage.save({ (error) in
            if error != nil {
                block(nil)
            } else {
                block(dyMessage.id)
            }
        })
    }
    
    func saveMessage(messageId: String, status: DyMessageStatus) {
        let dyMessage = DyMessage(messageId: messageId)
        dyMessage.fetchAndUpdate(status, block: { (error) in
            if error != nil {
                print("[HL] Can't save message")
            }
        })
    }
    
    func resendMessagesOnUser(fromUser: HLUser) {
        DyMessage.fetchAll({ (results) in
            if let messages = results {
                let sortedMsgs = messages.sort({
                    if let m0 = $0 as? DyMessage, let m1 = $1 as? DyMessage {
                        return m0.createdAtDate!.compare(m1.createdAtDate!) == NSComparisonResult.OrderedAscending
                    }
                    return false
                })
                for m in sortedMsgs {
                    let msg = m as! DyMessage
                    if let s = msg.status, let toUser = msg.toUser {
                        if ((s == DyMessageStatus.Unsent || s == DyMessageStatus.Sent) && (toUser == fromUser.id)) {
                            if let publicKeyString = self.publicKeys[fromUser.username] {
                                let puplicKeyData = NSData(base64EncodedString: publicKeyString, options:NSDataBase64DecodingOptions(rawValue: 0))
                                if let partnerHeimdall = Heimdall(publicTag: HLUltils.generateTagPrefix(12), publicKeyData: puplicKeyData) {
                                    let encryptedText = partnerHeimdall.encrypt(msg.content!)
                                    let messagePackage = HLMessagePackage(chatUser: self.currentUser, content: encryptedText, messageId: msg.id)
                                    if let jsonObject = messagePackage.jsonObject() {
                                        let jsonString = JSON(jsonObject).toString()
                                        self.iotDataManager.publishString(jsonString, onTopic: fromUser.username, qoS: .MessageDeliveryAttemptedAtMostOnce)
                                    } else {
                                        print("[HL] Cannot send message (error JSON): fromUser \(self.currentUser.id), toUser:\(fromUser.id)")
                                    }
                                } else {
                                }
                            } else {
                            }
                        }
                    }
                }
            }
        })
    }
    
    func parseStringToHLMessage(stringValue: String!) -> HLMessagePackage? {
        if let dict = HLUltils.convertStringToDictionary(stringValue) {
            return HLMessagePackage(dictionary: dict)
        }
        return nil
    }
    
    func listenIncomingMessagesOnUserChannel() {
        iotDataManager.subscribeToTopic(self.currentUser.username, qoS: .MessageDeliveryAttemptedAtMostOnce, messageCallback: {
            (payload) ->Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                let stringValue = NSString(data: payload, encoding: NSUTF8StringEncoding)! as String
                if let messagePackage = self.parseStringToHLMessage(stringValue) {
                    
                    if let callback = self.onAgreedMessage where messagePackage.type == HLMessageType.AgreePublicKey {
                        if (self.currentUser.isNotMe(messagePackage.fromUser)) {
                            callback(messagePackage)
                            self.publicKeys[messagePackage.fromUser.username] = messagePackage.content
                            self.saveContact(messagePackage)
                            self.resendMessagesOnUser(messagePackage.fromUser)
                        }
                    }
                    
                    if let callback = self.onReceivedMessage where messagePackage.type == HLMessageType.TalkingMessage {
                        if let decryptedString = self.localHeimdall.decrypt(messagePackage.content) {
                            messagePackage.content = decryptedString
                            self.saveMessage(messagePackage.fromUser.id, toUserId: self.currentUser.id,textMessage: decryptedString, status: DyMessageStatus.Deliveried,block: {(error) -> Void in
                            })
                        }
                        self.sendDeliveriedOnUserChannel(messagePackage.fromUser.username, fromUser: self.currentUser, messageId: messagePackage.messageId)
                        callback(messagePackage)
                    }
                    
                    if let callback = self.onDeliveriedMessage where messagePackage.type == HLMessageType.DeliveredMessage {
                        self.saveMessage(messagePackage.messageId, status: DyMessageStatus.Deliveried)
                        callback(messagePackage)
                    }
                }
            }
        })
    }
    
    func listenIncomingMessagesOnHandshakeChannel() {
        iotDataManager.subscribeToTopic(kHandshakeChannel, qoS: .MessageDeliveryAttemptedAtMostOnce, messageCallback: {
            (payload) ->Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                let stringValue = NSString(data: payload, encoding: NSUTF8StringEncoding)! as String
                if let messagePackage = self.parseStringToHLMessage(stringValue), let callback = self.onHandshakeMessage {
                    if (self.currentUser.isNotMe(messagePackage.fromUser)) {
                        callback(messagePackage)
                        self.publicKeys[messagePackage.fromUser.username] = messagePackage.content
                        self.sendAgreePublicKeyOnUserChannel(messagePackage.fromUser)
                        self.saveContact(messagePackage)
                        self.resendMessagesOnUser(messagePackage.fromUser)
                    }
                }
            }
        })
    }
    
    func sendBroadcastPublicKeyOnHandshakeChannel() {
        let publicKeyData = self.localHeimdall.publicKeyDataX509()!
        let publicKeyString = publicKeyData.base64EncodedStringWithOptions([])
        let messagePackage = HLMessagePackage(broadcastUser: self.currentUser, content: publicKeyString)
        
        if let jsonObject = messagePackage.jsonObject() {
            let jsonString = JSON(jsonObject).toString()
            iotDataManager.publishString(jsonString, onTopic: kHandshakeChannel, qoS: .MessageDeliveryAttemptedAtMostOnce)
        }
    }

    func sendAgreePublicKeyOnUserChannel(theUser: HLUser!) {
        let publicKeyData = self.localHeimdall.publicKeyDataX509()!
        let publicKeyString = publicKeyData.base64EncodedStringWithOptions([])
        let messagePackage = HLMessagePackage(agreeUser: self.currentUser, content: publicKeyString)
        
        if let jsonObject = messagePackage.jsonObject() {
            let jsonString = JSON(jsonObject).toString()
            iotDataManager.publishString(jsonString, onTopic: theUser.username, qoS: .MessageDeliveryAttemptedAtMostOnce)
        }
    }
    
    func sendDeliveriedOnUserChannel(userChannel: String, fromUser: HLUser!, messageId: String)  {
        let messagePackage = HLMessagePackage(deliveriedUser: fromUser, messageId: messageId)
        
        if let jsonObject = messagePackage.jsonObject() {
            let jsonString = JSON(jsonObject).toString()
            iotDataManager.publishString(jsonString, onTopic: userChannel, qoS: .MessageDeliveryAttemptedAtMostOnce)
        }
    }
    
    func sendChatOnUserChannel(theUser: HLUser!, textMessage: String!) -> Bool {
        if let publicKeyString = self.publicKeys[theUser.username] {
            let puplicKeyData = NSData(base64EncodedString: publicKeyString, options:NSDataBase64DecodingOptions(rawValue: 0))
            if let partnerHeimdall = Heimdall(publicTag: HLUltils.generateTagPrefix(12), publicKeyData: puplicKeyData) {
                let encryptedText = partnerHeimdall.encrypt(textMessage)
                self.saveMessage(self.currentUser.id, toUserId: theUser.id,textMessage: textMessage, status: DyMessageStatus.Sent, block: {(messageId) -> Void in
                    if messageId != nil {
                        let messagePackage = HLMessagePackage(chatUser: self.currentUser, content: encryptedText, messageId: messageId)
                        if let jsonObject = messagePackage.jsonObject() {
                            let jsonString = JSON(jsonObject).toString()
                            self.iotDataManager.publishString(jsonString, onTopic: theUser.username, qoS: .MessageDeliveryAttemptedAtMostOnce)
                        } else {
                             print("[HL] Cannot send message (error JSON): fromUser \(self.currentUser.id), toUser:\(theUser.id)")
                        }
                    } else {
                        print("[HL] Cannot send message (error messageId): fromUser \(self.currentUser.id), toUser:\(theUser.id)")
                    }
                })
                return true
            } else {
                print("[HL] Cannot send message (error RSA): fromUser \(self.currentUser.id), toUser:\(theUser.id)")
            }
        } else {
            self.saveMessage(self.currentUser.id, toUserId: theUser.id,textMessage: textMessage, status: DyMessageStatus.Unsent, block: {(error) -> Void in
                print("[HL] send offline message: fromUser \(self.currentUser.id), toUser:\(theUser.id)")
            })
        }
        return false
    }
    
    func finalSuccessConnection() {
        self.listenIncomingMessagesOnUserChannel()
        self.listenIncomingMessagesOnHandshakeChannel()
        
        let delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after( delayTime, dispatch_get_main_queue()) {
            self.sendBroadcastPublicKeyOnHandshakeChannel()
        }
    }
}