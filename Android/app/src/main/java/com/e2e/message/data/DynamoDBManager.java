package com.e2e.message.data;

import android.app.Activity;
import android.util.Log;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBMapper;
import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBMapperConfig;
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

    public static void createContactDBTable (Activity activity, String userId) {
        AmazonClientManager clientManager = new AmazonClientManager(activity);

        String tableName = "HL_" + userId + "_Contact";
        AmazonDynamoDBClient ddb = clientManager
                .ddb();

        KeySchemaElement kse = new KeySchemaElement().withAttributeName(
                "v_ctId").withKeyType(KeyType.HASH);
        AttributeDefinition ad = new AttributeDefinition().withAttributeName(
                "v_ctId").withAttributeType (ScalarAttributeType.S);
        ProvisionedThroughput pt = new ProvisionedThroughput()
                .withReadCapacityUnits (10L).withWriteCapacityUnits (5L);

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

    public static void createMessageDBTable(Activity activity, String userId) {
        AmazonClientManager clientManager = new AmazonClientManager(activity);

        String tableName = "HL_" + userId + "_Message";
        AmazonDynamoDBClient ddb = clientManager
                .ddb();

        KeySchemaElement kse = new KeySchemaElement().withAttributeName(
                "v_id").withKeyType(KeyType.HASH);
        AttributeDefinition ad = new AttributeDefinition().withAttributeName(
                "v_id").withAttributeType (ScalarAttributeType.S);
        ProvisionedThroughput pt = new ProvisionedThroughput()
                .withReadCapacityUnits (10L).withWriteCapacityUnits (5L);

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
    public static String getTableStatus(Activity activity, String tableName) {
        AmazonClientManager clientManager = new AmazonClientManager(activity);
        try {
            AmazonDynamoDBClient ddb = clientManager.ddb();

            DescribeTableRequest request = new DescribeTableRequest()
                    .withTableName(tableName);
            DescribeTableResult result = ddb.describeTable(request);

            String status = result.getTable().getTableStatus();
            return status == null ? "" : status;

        } catch (ResourceNotFoundException e) {

        } catch (AmazonServiceException ex) {
            clientManager.wipeCredentialsOnAuthError(ex);
        }

        return "";
    }

    public static boolean fetchData(Activity activity, String userId) {
        return false;
    }

    public static void insertUsers(UserResponse userResponse) {
        AmazonDynamoDBClient ddb = SignUpActivity.clientManager
                .ddb();
        DynamoDBMapper mapper = new DynamoDBMapper(ddb);

        try {
            Log.d(TAG, "Inserting users");
            mapper.save(userResponse);
            Log.d(TAG, "Users inserted");
        } catch (AmazonServiceException ex) {
            Log.e(TAG, "Error inserting users");
            SignUpActivity.clientManager
                    .wipeCredentialsOnAuthError(ex);
        }
    }

    public static UserResponse getUserById(Activity activity, String userId){
        AmazonClientManager clientManager = new AmazonClientManager(activity);
        AmazonDynamoDBClient ddb = clientManager
                .ddb();
        DynamoDBMapper mapper = new DynamoDBMapper(ddb);

        try {
            return mapper.load(UserResponse.class, userId);

        } catch (AmazonServiceException ex) {
            clientManager.wipeCredentialsOnAuthError(ex);
        }

        return null;
    }

    //insert data the table contact
    public static boolean insertContact (ContactResponse contactResponse, String tableName, Activity activity) {
        AmazonClientManager clientManager = new AmazonClientManager (activity);
        boolean done = false;
        AmazonDynamoDBClient ddb = clientManager
                .ddb ();
        DynamoDBMapper mapper = new DynamoDBMapper (ddb, new DynamoDBMapperConfig.Builder ().withTableNameOverride (DynamoDBMapperConfig.TableNameOverride.withTableNameReplacement (tableName))
                .build ());

        try {
            Log.d (TAG, "Inserting users");
            mapper.save (contactResponse);
            Log.d (TAG, "Users inserted");
            done = true;
        } catch (AmazonServiceException ex) {
            Log.e (TAG, "Error inserting users");
            clientManager
                    .wipeCredentialsOnAuthError (ex);
        }
        return done;
    }
}
