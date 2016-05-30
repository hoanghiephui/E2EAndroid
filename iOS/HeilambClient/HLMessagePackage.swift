//
//  HLMessagePackage.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/18/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation

public enum HLMessageType : Int {    
    case Unknown
    case BroadcastPublicKey
    case AgreePublicKey
    case TalkingMessage
}


public class HLMessagePackage {
    public var type : HLMessageType!
    public var fromUser : HLUser!
    public var content : String!
    
    required public init () {
        
    }
    
    required public init? (dictionary: AnyObject!) {
        if let messageType = HLMessageType(rawValue: (dictionary["messageType"] as? Int)!) {
            self.type = messageType
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
        self.type = HLMessageType.BroadcastPublicKey
        self.content = content
    }

    required public init (agreeUser: HLUser!, content: String!) {
        self.fromUser = agreeUser
        self.type = HLMessageType.AgreePublicKey
        self.content = content
    }

    required public init (chatUser: HLUser!, content: String!) {
        self.fromUser = chatUser
        self.type = HLMessageType.TalkingMessage
        self.content = content
    }
    
    func jsonObject() -> AnyObject? {
        if let jsonObject: [String: AnyObject] = [
            "messageType": self.type.rawValue,
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