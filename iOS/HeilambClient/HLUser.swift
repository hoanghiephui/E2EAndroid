//
//  HLUser.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/18/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation

public class HLUser {
    public var id : String!
    public var username : String!
    public var fullname : String!
    
    class var currentUser: HLUser? {
        struct Static {
            static var instance: HLUser? = nil
        }
        
        if (Static.instance == nil) {
            let config = NSUserDefaults.standardUserDefaults();
            if let username = config.objectForKey("username") {
                Static.instance = HLUser();
                Static.instance?.username = username as! String
            }
        }
        return Static.instance
    }
    
    required public init() {
    }
    
    required public init(dictionary:AnyObject) {
        self.username = dictionary.objectForKey("username") as! String
        self.fullname = dictionary.objectForKey("fullname") as! String
    }
    
    func isNotMe(theUser: HLUser!) -> Bool {
        return self.username != theUser.username
    }
    
    func jsonObject() -> AnyObject? {
        if let jsonObject: [String: AnyObject] = [
                "id": self.id,
                "username": self.username,
                "fullname": self.fullname
            ]
        {
            return jsonObject
        }
    }
    
}

public func != (left: HLUser, right:HLUser) -> Bool {
    return left.username != right.username
}