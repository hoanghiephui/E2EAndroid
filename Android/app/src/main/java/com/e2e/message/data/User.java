package com.e2e.message.data;

import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBAttribute;
import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBHashKey;
import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBTable;

/**
 * Created by hiep on 9/14/16.
 */
@DynamoDBTable(tableName = Constants.HL_USER_TABLE_NAME)
public class User {
    private String id;
    private String userName;
    private String fullName;
    private String keyK;
    private String privateKey;
    private String publicKey;

    @DynamoDBHashKey(attributeName = "v_id")
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    @DynamoDBAttribute(attributeName = "v_username")
    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    @DynamoDBAttribute(attributeName = "v_fullname")
    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    @DynamoDBAttribute(attributeName = "v_keyK")
    public String getKeyK() {
        return keyK;
    }

    public void setKeyK(String keyK) {
        this.keyK = keyK;
    }

    @DynamoDBAttribute(attributeName = "v_privateKey")
    public String getPrivateKey() {
        return privateKey;
    }

    public void setPrivateKey(String privateKey) {
        this.privateKey = privateKey;
    }

    @DynamoDBAttribute(attributeName = "v_publicKey")
    public String getPublicKey() {
        return publicKey;
    }

    public void setPublicKey(String publicKey) {
        this.publicKey = publicKey;
    }
}
