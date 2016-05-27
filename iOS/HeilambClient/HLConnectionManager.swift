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
                        }
                    }
                    
                    if let callback = self.onReceivedMessage where messagePackage.type == HLMessageType.TalkingMessage {
                        if let decryptedString = self.localHeimdall.decrypt(messagePackage.content) {
                            messagePackage.content = decryptedString
                        }
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
    
    func sendChatOnUserChannel(theUser: HLUser!, textMessage: String!) -> Bool {
        
        if let publicKeyString = self.publicKeys[theUser.username] {
            let puplicKeyData = NSData(base64EncodedString: publicKeyString, options:NSDataBase64DecodingOptions(rawValue: 0))
            if let partnerHeimdall = Heimdall(publicTag: HLUltils.generateTagPrefix(12), publicKeyData: puplicKeyData) {
                let encryptedText = partnerHeimdall.encrypt(textMessage)
                let messagePackage = HLMessagePackage(chatUser: self.currentUser, content: encryptedText)
                if let jsonObject = messagePackage.jsonObject() {
                    let jsonString = JSON(jsonObject).toString()
                    iotDataManager.publishString(jsonString, onTopic: theUser.username, qoS: .MessageDeliveryAttemptedAtMostOnce)
                    return true
                }
            }
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