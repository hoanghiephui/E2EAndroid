//
//  DyUser.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/26/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import AWSDynamoDB
import RNCryptor

public class DyUser: AWSDynamoDBObjectModel {
    var userId : String?
    var username: String?
    var fullname: String?
    var keyK: String?
    
    required public init(username:String) {
        self.userId = HLUltils.uniqueFromString(username)
        self.username = username
        super.init()
    }
    
    required public init!(coder: NSCoder!) {
        super.init(coder: coder)
    }
    
    class func hashKeyAttribute() -> String {
        return "userId"
    }
    
    class func rangeKeyAttribute() -> String {
        return "username"
    }
    
    class func dynamoDBTableName() -> String {
        return "HL_User"
    }
    
    func encrypt(base64KeyK: String) {
        self.username = RNCryptor.encryptData((self.username?.dataUsingEncoding(NSUTF8StringEncoding)!)!, password: base64KeyK).base64EncodedStringWithOptions([])
        self.fullname = RNCryptor.encryptData((self.fullname?.dataUsingEncoding(NSUTF8StringEncoding)!)!, password: base64KeyK).base64EncodedStringWithOptions([])
    }
}