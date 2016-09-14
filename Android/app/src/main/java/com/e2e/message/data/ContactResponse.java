package com.e2e.message.data;

import com.amazonaws.mobileconnectors.dynamodbv2.dynamodbmapper.DynamoDBTable;

/**
 * Created by hiep on 9/14/16.
 */
@DynamoDBTable(tableName = Constants.HL_USER_TABLE_NAME)
public class ContactResponse{


    private String v_ctId;
    private byte[] v_ctUsername;
    private byte[] v_ctFullname;
    private byte[] v_ctPublicKey;

    public String getV_ctId() {
        return v_ctId;
    }

    public void setV_ctId(String v_ctId) {
        this.v_ctId = v_ctId;
    }

    public byte[] getV_ctUsername() {
        return v_ctUsername;
    }

    public void setV_ctUsername(byte[] v_ctUsername) {
        this.v_ctUsername = v_ctUsername;
    }

    public byte[] getV_ctFullname() {
        return v_ctFullname;
    }

    public void setV_ctFullname(byte[] v_ctFullname) {
        this.v_ctFullname = v_ctFullname;
    }

    public byte[] getV_ctPublicKey() {
        return v_ctPublicKey;
    }

    public void setV_ctPublicKey(byte[] v_ctPublicKey) {
        this.v_ctPublicKey = v_ctPublicKey;
    }
}
