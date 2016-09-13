package com.e2e.message.data;

import android.app.Activity;
import android.util.Log;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBMapper;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClient;
import com.amazonaws.services.dynamodbv2.model.AttributeDefinition;
import com.amazonaws.services.dynamodbv2.model.CreateTableRequest;
import com.amazonaws.services.dynamodbv2.model.DescribeTableRequest;
import com.amazonaws.services.dynamodbv2.model.DescribeTableResult;
import com.amazonaws.services.dynamodbv2.model.KeySchemaElement;
import com.amazonaws.services.dynamodbv2.model.KeyType;
import com.amazonaws.services.dynamodbv2.model.ProvisionedThroughput;
import com.amazonaws.services.dynamodbv2.model.ResourceNotFoundException;
import com.amazonaws.services.dynamodbv2.model.ScalarAttributeType;
import com.e2e.message.ui.activities.SignUpActivity;

/**
 * Created by hiep on 9/13/16.
 */

public class DynamoDBManager {
    private static final String TAG = DynamoDBManager.class.getSimpleName();

    public boolean existTable(Activity activity, String tableName){
        AmazonClientManager clientManager = new AmazonClientManager(activity);
        AmazonDynamoDBClient ddbClient = clientManager
                .ddb();
        DynamoDBMapper mapper = new DynamoDBMapper(ddbClient);

        return false;
    }

    public static void createContactDBTable(Activity activity, UserResponse user){
        AmazonClientManager clientManager = new AmazonClientManager(activity);

        String tableName = "HL_" + user.getUserName() + "_Contact";
        AmazonDynamoDBClient ddb = clientManager
                .ddb();

        KeySchemaElement kse = new KeySchemaElement().withAttributeName(
                "v_ctId").withKeyType(KeyType.HASH);
        AttributeDefinition ad = new AttributeDefinition().withAttributeName(
                "v_ctId").withAttributeType(ScalarAttributeType.N);
        ProvisionedThroughput pt = new ProvisionedThroughput()
                .withReadCapacityUnits(10l).withWriteCapacityUnits(5l);

        CreateTableRequest request = new CreateTableRequest()
                .withTableName(tableName)
                .withKeySchema(kse).withAttributeDefinitions(ad)
                .withProvisionedThroughput(pt);

        try {
            Log.d(TAG, "Sending Create table request");
            ddb.createTable(request);
            Log.d(TAG, "Create request response successfully recieved");
        } catch (AmazonServiceException ex) {
            Log.e(TAG, "Error sending create table request", ex);
            clientManager
                    .wipeCredentialsOnAuthError(ex);
        }
    }

    /*
     * Retrieves the table description and returns the table status as a string.
     */
    public static String getTableStatus() {

        try {
            AmazonDynamoDBClient ddb = SignUpActivity.clientManager
                    .ddb();


            DescribeTableRequest request = new DescribeTableRequest()
                    .withTableName(Constants.HL_USER_TABLE_NAME);
            DescribeTableResult result = ddb.describeTable(request);

            String status = result.getTable().getTableStatus();
            return status == null ? "" : status;

        } catch (ResourceNotFoundException e) {
        } catch (AmazonServiceException ex) {
            SignUpActivity.clientManager
                    .wipeCredentialsOnAuthError(ex);
        }

        return "";
    }

    public static void insertUsers() {
        AmazonDynamoDBClient ddb = SignUpActivity.clientManager
                .ddb();
        DynamoDBMapper mapper = new DynamoDBMapper(ddb);

        try {
            UserResponse userResponse = new UserResponse();
            userResponse.getId();
            userResponse.getUserName();
            userResponse.getFullName();
            userResponse.getKeyK();
            userResponse.getPrivateKey();
            userResponse.getPublicKey();

            Log.d(TAG, "Inserting users");
            mapper.save(userResponse);
            Log.d(TAG, "Users inserted");
        } catch (AmazonServiceException ex) {
            Log.e(TAG, "Error inserting users");
            SignUpActivity.clientManager
                    .wipeCredentialsOnAuthError(ex);
        }
    }
}
