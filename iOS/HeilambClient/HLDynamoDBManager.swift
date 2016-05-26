//
//  HLDynamoDBManager.swift
//  HeilambClient
//
//  Created by Sinbad Flyce on 5/26/16.
//  Copyright © 2016 YusufX. All rights reserved.
//

import Foundation
import AWSDynamoDB

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
        AWSDynamoDBObjectMapper.registerDynamoDBObjectMapperWithConfiguration(configuration, objectMapperConfiguration: mapperConfig,forKey: kDynamoMapperKey)
        
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
    
    func saveUser(user: DyUser, withBlock block: HLErrorBlock) {
        self.dynamoMapper.save(user).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            block(task.error)
            return nil;
        })
    }
    
    func existUser(user: DyUser, withBlock block:HLCountBlock) {
        let queryInput = AWSDynamoDBQueryInput()
        let queryValue = AWSDynamoDBAttributeValue()
        let condition = AWSDynamoDBCondition()
        queryInput.tableName = DyUser.dynamoDBTableName()
        queryValue.S = user.userId
        condition.comparisonOperator = AWSDynamoDBComparisonOperator.EQ
        condition.attributeValueList = [queryValue]
        queryInput.keyConditions = ["userId" : condition]
        
        self.dynamoDB.query(queryInput).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in
            if ((task.error) != nil) {
                block(0)
            } else {
                if let result = task.result as? AWSDynamoDBQueryOutput {
                    block(result.scannedCount?.integerValue)
                } else {
                    block(0)
                }
            }
            return nil
        })
    }
}