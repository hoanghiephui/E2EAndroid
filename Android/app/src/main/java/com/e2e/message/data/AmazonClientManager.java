package com.e2e.message.data;

import android.content.Context;
import android.util.Log;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.ClientConfiguration;
import com.amazonaws.auth.CognitoCachingCredentialsProvider;
import com.amazonaws.regions.Region;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClient;

import static com.e2e.message.data.Constants.IDENTITY_POOL_ID;

/**
 * Created by hiep on 9/13/16.
 */

public class AmazonClientManager {
    private static final String LOG_TAG = "AmazonClientManager";

    private AmazonDynamoDBClient ddb = null;
    private Context context;
    private static final int CONNECTION_TIMEOUT_MS = 500; // 500ms connection timeout, fail fast
    private static final int OSG_SOCKET_TIMEOUT_MS = 10 * 1000; // 10 sec socket timeout if no data
    private static final int OSG_MAX_CONNECTIONS = 512; // Lots of connections since this is for the whole OSG

    public AmazonClientManager(Context context) {
        this.context = context;
    }

    public AmazonDynamoDBClient ddb() {
        validateCredentials();
        return ddb;
    }

    public boolean hasCredentials() {
        return (!(IDENTITY_POOL_ID.equalsIgnoreCase("us-east-1:1fb9f1c3-fe33-431f-88e8-c01cac2cf832")
                || Constants.HL_USER_TABLE_NAME.equalsIgnoreCase("HL_User")));
    }

    public void validateCredentials() {

        if (ddb == null) {
            initClients();
        }
    }

    private void initClients() {
        ClientConfiguration config = new ClientConfiguration();
        config.setConnectionTimeout(CONNECTION_TIMEOUT_MS); // very short timeout
        config.setSocketTimeout(OSG_SOCKET_TIMEOUT_MS);
        config.setMaxConnections(OSG_MAX_CONNECTIONS);
        CognitoCachingCredentialsProvider credentials = new CognitoCachingCredentialsProvider(
                context,
                IDENTITY_POOL_ID,
                Regions.US_EAST_1);

        ddb = new AmazonDynamoDBClient(credentials);
        ddb.setRegion(Region.getRegion(Regions.US_EAST_1));
        ddb.setTimeOffset(config.getConnectionTimeout());
    }

    public boolean wipeCredentialsOnAuthError(AmazonServiceException ex) {
        Log.e(LOG_TAG, "Error, wipeCredentialsOnAuthError called" + ex);
        if (
            // STS
            // http://docs.amazonwebservices.com/STS/latest/APIReference/CommonErrors.html
                ex.getErrorCode().equals("IncompleteSignature")
                        || ex.getErrorCode().equals("InternalFailure")
                        || ex.getErrorCode().equals("InvalidClientTokenId")
                        || ex.getErrorCode().equals("OptInRequired")
                        || ex.getErrorCode().equals("RequestExpired")
                        || ex.getErrorCode().equals("ServiceUnavailable")

                        // DynamoDB
                        // http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/ErrorHandling.html#APIErrorTypes
                        || ex.getErrorCode().equals("AccessDeniedException")
                        || ex.getErrorCode().equals("IncompleteSignatureException")
                        || ex.getErrorCode().equals(
                        "MissingAuthenticationTokenException")
                        || ex.getErrorCode().equals("ValidationException")
                        || ex.getErrorCode().equals("InternalFailure")
                        || ex.getErrorCode().equals("InternalServerError")) {

            return true;
        }

        return false;
    }


}
