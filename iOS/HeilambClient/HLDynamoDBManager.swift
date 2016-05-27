//
//  HLDynamoDBManager.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/26/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import AWSDynamoDB
import RNCryptor

let kDynamoDBKey = "kDynamoDBKey"
let kDynamoMapperKey = "kDynamoMapperKey"

public typealias HLErrorBlock = (NSError?) -> Void
public typealias HLResultBlock = (AnyObject?) -> Void
public typealias HLCountBlock = (Int?) -> Void

public class HLDynamoDBManager {
    
    var dynamoDB : AWSDynamoDB
    var dynamoMapper : AWSDynamoDBObjectMapper
    
    class var shared: HLDynamoDBManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: HLDynamoDBManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = HLDynamoDBManager()
        }
        return Static.instance!
    }

    required public init() {
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: AwsRegion, identityPoolId: CognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(region: AwsRegion, credentialsProvider: credentialProvider)
        let mapperConfig = AWSDynamoDBObjectMapperConfiguration()
        
        mapperConfig.saveBehavior = AWSDynamoDBObjectMapperSaveBehavior.Update
        AWSDynamoDB.registerDynamoDBWithConfiguration(configuration, forKey: kDynamoDBKey)
        AWSDynamoDBObjectMapper.registerDynamoDBObjectMapperWithConfiguration(configuration, objectMapperConfiguration: mapperConfig, forKey: kDynamoMapperKey)
        
        self.dynamoDB = AWSDynamoDB(forKey: kDynamoDBKey)
        self.dynamoMapper = AWSDynamoDBObjectMapper(forKey: kDynamoMapperKey)
    }
    
    func existTable(tableName: String, withBlock block:HLErrorBlock ) {
        let describeTableInput = AWSDynamoDBDescribeTableInput()
        describeTableInput.tableName = tableName
        let describeTask = dynamoDB.describeTable(describeTableInput)
        describeTask.continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            block(task.error)
            return nil
        })
    }
    
    func save(model: AWSDynamoDBObjectModel, withBlock block: HLErrorBlock) {        
        self.dynamoMapper.save(model).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            block(task.error)
            return nil;
        })
    }
        
    func fetch(model: AWSDynamoDBObjectModel, attributeNameS: String, attributeVauleS: String, tableName: String , withBlock block:HLResultBlock) {
        let queryInput = AWSDynamoDBQueryInput()
        let queryValue = AWSDynamoDBAttributeValue()
        let condition = AWSDynamoDBCondition()
        
        queryInput.tableName = tableName
        condition.comparisonOperator = AWSDynamoDBComparisonOperator.EQ
        queryValue.S = attributeVauleS
        condition.attributeValueList = [queryValue]
        queryInput.keyConditions = [attributeNameS : condition]
        
        self.dynamoDB.query(queryInput).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            if ((task.error) != nil) {
                block(nil)
            } else {
                if let result = task.result as? AWSDynamoDBQueryOutput where result.items!.count > 0{
                    block(result.items![0])
                } else {
                    block(nil)
                }
            }
            return nil
        })
    }
    
    func signUp(username: String, password: String, fullname: String, withBlock block:HLResultBlock) {
        HLDynamoDBManager.shared.existTable(DyUser.dynamoDBTableName(), withBlock: { (error) -> Void in
            if error == nil {
                let dyUser = DyUser(username: username)
                dyUser.fetch({ (object) in
                    if (object == nil) {
                        if let salt = HLUltils.SaltData {
                            let keyQ = RNCryptor.FormatV3.keyForPassword(password, salt: salt)
                            let randomSalt = HLUltils.generateTagPrefix(8).dataUTF8!
                            let keyK = RNCryptor.FormatV3.keyForPassword(password, salt: randomSalt)
                            let keyEncryptedK = RNCryptor.encryptData(keyK, password: keyQ.base64String!)
                            
                            let keychain = AWSUICKeyChainStore(service: kKeychainDB)
                            keychain.setData(keyQ, forKey: dyUser.userId!)
                            
                            dyUser.keyK = keyEncryptedK
                            dyUser.fullname = fullname
                            dyUser.save({ (error) in
                                if (error != nil) {
                                    keychain.removeItemForKey(dyUser.userId!)
                                    block(error)
                                } else {
                                    let config = NSUserDefaults.standardUserDefaults();
                                    config.setObject(username, forKey: "username")
                                    block(nil)
                                }
                            })
                        } else {
                            block(NSError(errorMessage: "Missing SALT. Please contact to us"))
                        }
                    } else {
                        block(NSError(errorMessage: "The username was already exist. Please enter an other"))
                    }
                })
            } else {
                block(error)
            }
        })
    }
}