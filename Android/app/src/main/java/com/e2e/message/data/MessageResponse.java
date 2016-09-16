package com.e2e.message.data;

import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBAttribute;
import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBHashKey;
import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBTable;

/**
 * Created by hiep on 9/16/16.
 */

@DynamoDBTable (tableName = "")
public class MessageResponse {
    private String v_id;
    private String v_fromUserId;
    private byte[] v_toUserId;
    private byte[] v_content;
    private byte[] v_createAt;
    private byte[] v_status;

    @DynamoDBHashKey (attributeName = "v_id")
    public String getV_id () {
        return v_id;
    }

    public void setV_id (String v_id) {
        this.v_id = v_id;
    }

    @DynamoDBAttribute (attributeName = "v_fromUserId")
    public String getV_fromUserId () {
        return v_fromUserId;
    }

    public void setV_fromUserId (String v_fromUserId) {
        this.v_fromUserId = v_fromUserId;
    }

    @DynamoDBAttribute (attributeName = "v_toUserId")
    public byte[] getV_toUserId () {
        return v_toUserId;
    }

    public void setV_toUserId (byte[] v_toUserId) {
        this.v_toUserId = v_toUserId;
    }

    @DynamoDBAttribute (attributeName = "v_content")
    public byte[] getV_content () {
        return v_content;
    }

    public void setV_content (byte[] v_content) {
        this.v_content = v_content;
    }

    @DynamoDBAttribute (attributeName = "v_createAt")
    public byte[] getV_createAt () {
        return v_createAt;
    }

    public void setV_createAt (byte[] v_createAt) {
        this.v_createAt = v_createAt;
    }

    @DynamoDBAttribute (attributeName = "v_status")
    public byte[] getV_status () {
        return v_status;
    }

    public void setV_status (byte[] v_status) {
        this.v_status = v_status;
    }
}
