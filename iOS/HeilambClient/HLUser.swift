//
//  HLUser.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/18/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation

public class HLUser {
    public var username : String!
    public var fullname : String!
    
    required public init() {
    }
    
    required public init(dictionary:AnyObject) {
        self.username = dictionary.objectForKey("username") as! String
        self.fullname = dictionary.objectForKey("fullname") as! String
    }
    
    func isNotMe(theUser: HLUser!) -> Bool {
        return self.username != theUser.username
    }
}