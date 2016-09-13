package com.e2e.message.data;

import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBHashKey;
import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBTable;

/**
 * Created by hiep on 9/12/16.
 */
@DynamoDBTable(tableName = Constants.HL_USER_TABLE_NAME)
public class UserResponse {
    private String id;
    private byte[] userName;
    private byte[] fullName;
    private byte[] keyK;
    private byte[] privateKey;
    private byte[] publicKey;


    @DynamoDBHashKey(attributeName = "v_id")
    public String getId() {
        return id;
    }

    @DynamoDBHashKey(attributeName = "v_username")
    public byte[] getUserName() {
        return userName;
    }

    @DynamoDBHashKey(attributeName = "v_fullname")
    public byte[] getFullName() {
        return fullName;
    }

    @DynamoDBHashKey(attributeName = "v_keyK")
    public byte[] getKeyK() {
        return keyK;
    }

    @DynamoDBHashKey(attributeName = "v_privateKey")
    public byte[] getPrivateKey() {
        return privateKey;
    }

    @DynamoDBHashKey(attributeName = "v_publicKey")
    public byte[] getPublicKey() {
        return publicKey;
    }



    public void setId(String id) {
        this.id = id;
    }

    public void setUserName(byte[] userName) {
        this.userName = userName;
    }

    public void setFullName(byte[] fullName) {
        this.fullName = fullName;
    }

    public void setPrivateKey(byte[] privateKey) {
        this.privateKey = privateKey;
    }

    public void setPublicKey(byte[] publicKey) {
        this.publicKey = publicKey;
    }

    public void setKeyK(byte[] keyK) {
        this.keyK = keyK;
    }
}
