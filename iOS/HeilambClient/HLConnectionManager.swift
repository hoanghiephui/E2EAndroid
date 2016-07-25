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
import RNCryptor
import BluetoothKit
import SwCrypt

let kHandshakeChannel = "kHandshakeChannel"
let kPrefixHeimdall = "com.sinbadflyce.aws.e2ee.chat"

public class HLConnectionManager : HLBleShareKeyDelegate {
    let credentialProvider : AWSCognitoCredentialsProvider;
    
    var iotDataManager: AWSIoTDataManager!
    var connected: Bool!
    var publicKeys : [String: String]!
    
    
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
    }
    
    public func connectWithUser(user: HLUser!, statusCallback callback: ((Bool) -> Void)!) {
        self.currentUser = user
        let myBundle = NSBundle.mainBundle()
        let myImages = myBundle.pathsForResourcesOfType("p12" as String, inDirectory:nil)
        if (myImages.count > 0) {
            
            if let data = NSData(contentsOfFile:myImages[0]) {
                if AWSIoTManager.importIdentityFromPKCS12Data( data, passPhrase:"1111", certificateId:"awsiot-identity") {
                    dispatch_async( dispatch_get_main_queue()) {
                        self.iotDataManager.connectWithClientId( user.username, cleanSession:true, certificateId:"awsiot-identity",statusCallback: { ( status ) in
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
        } else {
#if os(OSX)
            HLUltils.alert(message: "You don't have certificates");
#endif
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
        dyContact.publicKey = messagePackage.content!.dataUTF8
        dyContact.save { (error) in
            if error != nil {
                print(error?.localizedDescription)
            }
        }
    }
    
    func saveMessage(fromUserId: String, toUserId: String, textMessage: String, status: DyMessageStatus, block: (String?) -> Void) {
        
        let dyMessage = DyMessage()
        dyMessage.fromUserId = fromUserId
        dyMessage.toUserId = toUserId
        dyMessage.content = textMessage
        dyMessage.status = status
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
                print("[HL] Can't save message. Error: \(error?.localizedDescription)")
            } else {
                print("[HL] Saved message. Id: \(messageId)")
            }
        })
    }
    
    func resendMessagesOnUser(fromUser: HLUser) {
        HLDynamoDBManager.shared.fetchHistoryMessages(fromUser.id) { (models) in
            if let messages = models {
                let sortedMessages = messages.sort({
                    if let m0 = $0 as? DyMessage, let m1 = $1 as? DyMessage {
                        return m0.createdAtDate!.compare(m1.createdAtDate!) == NSComparisonResult.OrderedAscending
                    }
                    return false
                })
                
                for m in sortedMessages {
                    let msg = m as! DyMessage
                    if let s = msg.status, let toUser = msg.toUserId {
                        if ((s == DyMessageStatus.Unsent || s == DyMessageStatus.Sent) && (toUser == fromUser.id)) {
                            if let publicKeyString = self.publicKeys[fromUser.username] {
                                let puplicKeyData = publicKeyString.dataUTF8
                                if let encryptedText = try? CC.RSA.encrypt(msg.content!.dataUTF8!, derKey: puplicKeyData!, tag: HLUltils.RsaTag, padding: CC.RSA.AsymmetricPadding.oaep, digest: CC.DigestAlgorithm.sha1) {                                    
                                    let messagePackage = HLMessagePackage(chatUser: self.currentUser, content: encryptedText.stringUTF8, messageId: msg.id)
                                    if let jsonObject = messagePackage.jsonObject() {
                                        let jsonString = JSON(jsonObject).toString()
                                        self.iotDataManager.publishString(jsonString, onTopic: fromUser.username, qoS: .MessageDeliveryAttemptedAtMostOnce)
                                    } else {
                                        print("[HL] Cannot send message (error JSON): fromUser \(self.currentUser.id), toUser:\(fromUser.id)")
                                    }
                                } else {
                                    print("[HL] Error decrypt message (error decrypt): fromUser \(self.currentUser.id), toUser:\(fromUser.id)")
                                }
                            } else {
                                print("[HL] Not yet share public key (error JSON): fromUser \(self.currentUser.id), toUser:\(fromUser.id)")
                            }
                        }
                    }
                }
            }
        }
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
                    
                    if let callback = self.onReceivedMessage where messagePackage.type == HLMessageType.ReceivedMessage {
                        
                        if let (decryptedData, _) = try? CC.RSA.decrypt(messagePackage.content.dataBase64!, derKey: (DyUser.currentUser?.privateKey)!, tag: HLUltils.RsaTag, padding: CC.RSA.AsymmetricPadding.oaep, digest: CC.DigestAlgorithm.sha1) {
                            let decryptedString = decryptedData.stringUTF8
                            messagePackage.content = decryptedString
                            self.saveMessage(messagePackage.fromUser.id, toUserId: self.currentUser.id,textMessage: decryptedString!, status: DyMessageStatus.Deliveried,block: {(messageId) -> Void in
                                if messageId != nil {
                                    print("[HL] Saved message. Id: \(messageId)")
                                } else {
                                    print("[HL] Can't save message. Error: \(decryptedString)")
                                }
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
        let publicKeyData = DyUser.currentUser?.publicKey
        let publicKeyString = publicKeyData?.stringBase64
        let messagePackage = HLMessagePackage(broadcastUser: self.currentUser, content: publicKeyString)
        
        if let jsonObject = messagePackage.jsonObject() {
            let jsonString = JSON(jsonObject).toString()
            iotDataManager.publishString(jsonString, onTopic: kHandshakeChannel, qoS: .MessageDeliveryAttemptedAtMostOnce)
        }
    }

    func sendAgreePublicKeyOnUserChannel(theUser: HLUser!) {
        let publicKeyData = DyUser.currentUser?.publicKey
        let publicKeyString = publicKeyData?.stringBase64
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
            if let puplicKeyData = publicKeyString.dataBase64 {
                if let encryptedData = try? CC.RSA.encrypt(textMessage.dataUTF8!, derKey: puplicKeyData, tag: HLUltils.RsaTag, padding: CC.RSA.AsymmetricPadding.oaep, digest: CC.DigestAlgorithm.sha1) {
                    self.saveMessage(self.currentUser.id, toUserId: theUser.id,textMessage: textMessage, status: DyMessageStatus.Sent, block: {(messageId) -> Void in
                        if messageId != nil {
                            let encryptedText = encryptedData.stringBase64!
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
                    return false
                }
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
            HLBleShareKey.shared.delegate = self
            HLBleShareKey.shared.start()
        }
    }
    
    public func shareKey(shareKey: HLBleShareKey, canSendDatafromCentral fromCentral: BKCentral, toPeripheral: BKRemotePeripheral) {
        let publicKeyData = DyUser.currentUser?.publicKey
        let publicKeyString = publicKeyData?.stringBase64
        let messagePackage = HLMessagePackage(broadcastUser: self.currentUser, content: publicKeyString)
        
        if let jsonObject = messagePackage.jsonObject() {
            let jsonString = JSON(jsonObject).toString()
            if let packData = jsonString.dataUTF8 {
                fromCentral.sendData(packData, toRemotePeer: toPeripheral, completionHandler: { (data, remotePeer, error) in
                    if error == nil {
                        print("[BLE] sent public key to ble peer");
                    }
                })
            }
        }
    }
    
    public func shareKey(shareKey: HLBleShareKey, didReceivedPublicKey messagePackage: HLMessagePackage) {
        if (self.currentUser.isNotMe(messagePackage.fromUser)) {
            self.publicKeys[messagePackage.fromUser.username] = messagePackage.content
        }
    }
    
    public func shareKey(shareKey: HLBleShareKey, didSendDatafromCentral fromCentral: BKCentral, toPeripheral: BKRemotePeripheral, error: NSError?) {
    }
}