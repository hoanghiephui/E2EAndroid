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
public typealias HLResultArrayBlock = ([AnyObject]?) -> Void
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

    func save(model: AWSDynamoDBObjectModel, behavior: AWSDynamoDBObjectMapperSaveBehavior, withBlock block: HLErrorBlock) {
        let mapperConfig = AWSDynamoDBObjectMapperConfiguration()
        mapperConfig.saveBehavior = behavior
        self.dynamoMapper.save(model, configuration: mapperConfig).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
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
    
    func fetchLimit(resultClass: AnyClass, limit: Int, block:HLResultArrayBlock) {
        let queryExpression = AWSDynamoDBScanExpression()
        if limit > 0 {
            queryExpression.limit = limit
        }
        self.dynamoMapper.scan(resultClass, expression: queryExpression).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            if task.error == nil {
                let result = task.result as! AWSDynamoDBPaginatedOutput
                if result.items.count > 0 {
                    block(result.items)
                } else {
                    block (nil)
                }
            } else {
                block(nil)
            }
            return nil
        })
    }
    
    func fetchModel(modelClass: AnyClass,  haskKey: String, block:HLResultBlock) {
        self.dynamoMapper.load(modelClass, hashKey: haskKey, rangeKey: nil).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            if task.error == nil && task.result != nil {
                let dyMessage = task.result as! DyMessage
                block(dyMessage)
            } else {
                    block (nil)
            }
            return nil
        })
    }
    
    func createContactDBTable(dyUser: DyUser, withBlock block:HLErrorBlock) {
        
        let hashKeyAttributeDefinition = AWSDynamoDBAttributeDefinition()
        hashKeyAttributeDefinition.attributeName = "_ctId"
        hashKeyAttributeDefinition.attributeType = AWSDynamoDBScalarAttributeType.S
        
        let hashKeySchemaElement = AWSDynamoDBKeySchemaElement()
        hashKeySchemaElement.attributeName = "_ctId"
        hashKeySchemaElement.keyType = AWSDynamoDBKeyType.Hash
        
        let provisionedThroughput = AWSDynamoDBProvisionedThroughput()
        provisionedThroughput.readCapacityUnits = 2
        provisionedThroughput.writeCapacityUnits = 2
        
        let createTableInput = AWSDynamoDBCreateTableInput()
        createTableInput.tableName = "HL_" + dyUser.userId! + "_Contact";
        createTableInput.attributeDefinitions = [hashKeyAttributeDefinition]
        createTableInput.keySchema = [hashKeySchemaElement]
        createTableInput.provisionedThroughput = provisionedThroughput
        
        self.dynamoDB.createTable(createTableInput).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            if let _ = task.result {
                block(nil)
            } else {
                block(task.error)
            }
            return nil
        })
    }
    
    func createMessageDBTable(dyUser: DyUser, withBlock block:HLErrorBlock) {
        
        let hashKeyAttributeDefinition = AWSDynamoDBAttributeDefinition()
        hashKeyAttributeDefinition.attributeName = "_msId"
        hashKeyAttributeDefinition.attributeType = AWSDynamoDBScalarAttributeType.S
        
        let hashKeySchemaElement = AWSDynamoDBKeySchemaElement()
        hashKeySchemaElement.attributeName = "_msId"
        hashKeySchemaElement.keyType = AWSDynamoDBKeyType.Hash
        
        let provisionedThroughput = AWSDynamoDBProvisionedThroughput()
        provisionedThroughput.readCapacityUnits = 2
        provisionedThroughput.writeCapacityUnits = 2
        
        let createTableInput = AWSDynamoDBCreateTableInput()
        createTableInput.tableName = "HL_" + dyUser.userId! + "_Message";
        createTableInput.attributeDefinitions = [hashKeyAttributeDefinition]
        createTableInput.keySchema = [hashKeySchemaElement]
        createTableInput.provisionedThroughput = provisionedThroughput
        
        self.dynamoDB.createTable(createTableInput).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            if let _ = task.result {
                block(nil)
            } else {
                block(task.error)
            }
            return nil
        })
    }
    
    func signUp(username: String, password: String, fullname: String, withBlock block:HLResultBlock) {
        self.existTable(DyUser.dynamoDBTableName(), withBlock: { (error) -> Void in
            if error == nil {
                let dyUser = DyUser(username: username)
                self.fetch(dyUser, attributeNameS: "_id", attributeVauleS: dyUser.userId!, tableName: DyUser.dynamoDBTableName(), withBlock: { (item) in
                    if (item == nil) {
                        if let salt = HLUltils.SaltData {
                            let keyQ = RNCryptor.FormatV3.keyForPassword(password, salt: salt)
                            let randomSalt = HLUltils.generateTagPrefix(8).dataUTF8!
                            let keyK = RNCryptor.FormatV3.keyForPassword(password, salt: randomSalt)
                            let keyEncryptedK = RNCryptor.encryptData(keyK, password: keyQ.base64String!)
                            
                            let keychain = AWSUICKeyChainStore(service: kKeychainDB)
                            keychain.setData(keyQ, forKey: dyUser.userId!)
                            
                            dyUser.keyEncryptedK = keyEncryptedK
                            dyUser.fullname = fullname
                            dyUser.save({ (error) in
                                if (error != nil) {
                                    keychain.removeItemForKey(dyUser.userId!)
                                    block(error)
                                } else {
                                    self.createContactDBTable(dyUser, withBlock: { (error) in
                                        if (error == nil) {
                                            self.createMessageDBTable(dyUser, withBlock: { (error) in
                                                if (error == nil) {
                                                    let config = NSUserDefaults.standardUserDefaults();
                                                    config.setObject(username, forKey: "username")
                                                    DyUser.currentUser?.fetch({ (obj) in
                                                        block(nil)
                                                    })
                                                } else {
                                                    keychain.removeItemForKey(dyUser.userId!)
                                                    block(error)
                                                    self.dynamoMapper.remove(dyUser)
                                                }
                                            })
                                        } else {
                                            keychain.removeItemForKey(dyUser.userId!)
                                            block(error)
                                            self.dynamoMapper.remove(dyUser)
                                        }
                                    })
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
    
    func login(username: String, password: String, withBlock block:HLErrorBlock) {
        self.existTable(DyUser.dynamoDBTableName(), withBlock: { (error) -> Void in
            if error == nil {
                let dyUser = DyUser(username: username)
                self.fetch(dyUser, attributeNameS: "_id", attributeVauleS: dyUser.userId!, tableName: DyUser.dynamoDBTableName(), withBlock: { (item) in
                    if let object = item {
                        let salt = HLUltils.SaltData
                        let keyQ = RNCryptor.FormatV3.keyForPassword(password, salt: salt!)
                        if  let encryptedKeyK = (object.objectForKey("_keyK") as! AWSDynamoDBAttributeValue).B {
                            do {
                                let _ = try RNCryptor.decryptData(encryptedKeyK, password: keyQ.base64String!)
                                let keychain = AWSUICKeyChainStore(service: kKeychainDB)
                                keychain.setData(keyQ, forKey: dyUser.userId!)
                                DyUser.currentUser?.fetch({ (obj) in
                                    block(nil)
                                })
                            } catch {
                                block(NSError(errorMessage: "The password is wrong. Please enter an other"))
                            }
                        } else {
                            block(NSError(errorMessage: "Your username/password is wrong. Please enter an other"))
                        }
                        
                    } else {
                        block(NSError(errorMessage: "The username isn't already exist. Please enter an other"))
                    }
                })
            } else {
                block(error)
            }
        })
    }
}