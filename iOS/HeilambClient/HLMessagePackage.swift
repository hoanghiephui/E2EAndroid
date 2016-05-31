//
//  HLMessagePackage.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/18/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation

public let kUnknowMessageId = "kUnknowMessageId"
public let kNothingContent = "kNothingContent"

public enum HLMessageType : Int {    
    case Unknown
    case BroadcastPublicKey
    case AgreePublicKey
    case TalkingMessage
    case DeliveredMessage
}


public class HLMessagePackage {
    public var type : HLMessageType!
    public var fromUser : HLUser!
    public var content : String!
    public var messageId : String!
    
    required public init () {
        
    }
    
    required public init? (dictionary: AnyObject!) {
        if let messageType = HLMessageType(rawValue: (dictionary["messageType"] as? Int)!) {
            self.type = messageType
            self.messageId = dictionary.objectForKey("messageId") as? String
            if let data = dictionary["data"] {
                self.content = data!.objectForKey("content") as! String
                if let fromUser = data!.objectForKey("fromUser") {
                    self.fromUser = HLUser(dictionary: fromUser)
                    return
                }
            }
        }
        return nil
    }
    
    required public init (broadcastUser: HLUser!, content: String!) {
        self.fromUser = broadcastUser
        self.messageId = kUnknowMessageId
        self.type = HLMessageType.BroadcastPublicKey
        self.content = content
    }

    required public init (agreeUser: HLUser!, content: String!) {
        self.fromUser = agreeUser
        self.messageId = kUnknowMessageId
        self.type = HLMessageType.AgreePublicKey
        self.content = content
    }

    required public init (deliveriedUser: HLUser!, messageId: String!) {
        self.fromUser = deliveriedUser
        self.messageId = messageId
        self.type = HLMessageType.DeliveredMessage
        self.content = kNothingContent
    }
    
    required public init (chatUser: HLUser!, content: String!, messageId: String!) {
        self.fromUser = chatUser
        self.messageId = messageId
        self.type = HLMessageType.TalkingMessage
        self.content = content
    }
    
    func jsonObject() -> AnyObject? {
        if let jsonObject: [String: AnyObject] = [
            "messageType": self.type.rawValue,
            "messageId" : self.messageId!,
            "data" : [
                "fromUser": [
                    "id": self.fromUser.id,
                    "username": self.fromUser.username,
                    "fullname": self.fromUser.fullname],
            "content": self.content]
            ]
        {
            return jsonObject
        }
    }
}