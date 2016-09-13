package com.e2e.message.ui.activities;

import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import com.e2e.message.R;
import com.e2e.message.crypto.Crypto;
import com.e2e.message.crypto.RSA;
import com.e2e.message.data.AmazonClientManager;
import com.e2e.message.data.DynamoDBManager;
import com.e2e.message.data.UserResponse;
import com.e2e.message.utils.HLUltils;
import com.e2e.message.utils.KeyStoreUtils;
import com.e2e.message.utils.StringUtil;
import com.prashantsolanki.secureprefmanager.SecurePrefManager;

import org.apache.commons.codec.DecoderException;
import org.cryptonode.jncryptor.AES256JNCryptor;
import org.cryptonode.jncryptor.CryptorException;
import org.cryptonode.jncryptor.JNCryptor;

import java.io.File;
import java.io.IOException;
import java.security.KeyPair;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.KeySpec;

import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

import static com.e2e.message.utils.KeyStoreUtils.loadKey;

/**
 * Created by hiep on 9/12/16.
 */
public class SignUpActivity extends BaseActivity implements View.OnClickListener {
    private static final String TAG = SignUpActivity.class.getSimpleName();
    private EditText edtUserName, edtPassword, edtFullName, edtReTypePassword;
    private Button btnSignUp;

    SecretKey keyQ;
    SecretKey keyK;
    public static AmazonClientManager clientManager = null;

    @Override
    protected int getMainLayout() {
        return R.layout.activity_signup;
    }

    @Override
    protected void initToolbar(Bundle savedInstanceState) {
        getSupportActionBar().setDefaultDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
    }

    @Override
    protected void initComponents(Bundle savedInstanceState) {
        clientManager = new AmazonClientManager(this);
        this.edtUserName = (EditText) findViewById(R.id.edtUserName);
        this.edtPassword = (EditText) findViewById(R.id.edtPassword);
        this.edtFullName = (EditText) findViewById(R.id.edtFullName);
        this.edtReTypePassword = (EditText) findViewById(R.id.edtReTypePassword);
        this.btnSignUp = (Button) findViewById(R.id.btnSignUp);
        btnSignUp.setOnClickListener(this);
    }

    @Override
    protected void bindEventHandlers(){


    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.btnSignUp:
                onSignUp();
                break;
        }
    }

    private void onSignUp() {
        UserResponse user = new UserResponse();
        if (StringUtil.isEmptyString(edtUserName.getText().toString()) ||
                StringUtil.isEmptyString(edtFullName.getText().toString()) ||
                StringUtil.isEmptyString(edtReTypePassword.getText().toString()) ||
                StringUtil.isEmptyString(edtPassword.getText().toString())) {
            Toast.makeText(this, "Username or Full name or Password null", Toast.LENGTH_SHORT).show();
        } else {
            //generate rsa
            SecurePrefManager.with(this).clear();
            final KeyPair keyPair = RSA.generate();
            Crypto.writePrivateKeyToPreferences(this, keyPair);
            Crypto.writePublicKeyToPreferences(this, keyPair);
            String privateKeyPref = SecurePrefManager.with(this)
                    .get(com.e2e.message.data.Constants.RSA_PRIVATE_KEY)
                    .defaultValue("unknown")
                    .go();

            String publicKeyPref = SecurePrefManager.with(this)
                    .get(com.e2e.message.data.Constants.RSA_PUBLIC_KEY)
                    .defaultValue("unknown")
                    .go();

            Log.d(TAG, "onSignUp: public key: " + Crypto.stripPublicKeyHeaders(publicKeyPref) + " privateKey: " + Crypto.stripPublicKeyHeaders(privateKeyPref));

            JNCryptor cryptor = new AES256JNCryptor();

            try {
                keyK = getSecretKey(edtPassword.getText().toString().toCharArray(), HLUltils.generateTagPrefix(8).getBytes());
                keyQ = getSecretKey(edtPassword.getText().toString().toCharArray(), HLUltils.getkSalt());

                byte[] keyEncryptedK = cryptor.encryptData(HLUltils.getkSalt(),
                        keyK, keyQ);
                String decryptedKeyK = Base64.encodeToString(keyEncryptedK, Base64.DEFAULT);
                Log.d(TAG, "onSignUp: " + decryptedKeyK);

                //luu keyQ

                File file = File.createTempFile("keyQ", ".key");
                KeyStoreUtils.saveKey(keyQ, file);


                SecretKey persistedKey = loadKey(file);
                Log.d(TAG, "onSignUp: keyQ :" + Base64.encodeToString(keyQ.getEncoded(), Base64.DEFAULT) + " keyQ File: " + Base64.encodeToString(persistedKey.getEncoded(), Base64.DEFAULT));

                //ma hoa user
                user.setId(StringUtil.uniqueFromString(edtUserName.getText().toString()));
                user.setUserName(cryptor.encryptData(edtUserName.getText().toString().getBytes(), decryptedKeyK.toCharArray()));
                user.setFullName(cryptor.encryptData(edtFullName.getText().toString().getBytes(), decryptedKeyK.toCharArray()));
                user.setKeyK(keyEncryptedK);
                user.setPrivateKey(cryptor.encryptData(privateKeyPref.getBytes(), decryptedKeyK.toCharArray()));
                user.setPublicKey(cryptor.encryptData(publicKeyPref.getBytes(), decryptedKeyK.toCharArray()));
                new DynamoDBManagerTask()
                        .execute(DynamoDBManagerType.INSERT_USER);

            } catch (CryptorException e) {
                // Something went wrong
                e.printStackTrace();
            } catch (InvalidKeySpecException e) {
                e.printStackTrace();
            } catch (NoSuchAlgorithmException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            } catch (DecoderException e) {
                e.printStackTrace();
            }
        }
    }

    public static SecretKey getSecretKey(char[] password, byte[] salt) throws NoSuchAlgorithmException, InvalidKeySpecException {
        SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
        // NOTE: last argument is the key length, and it is 128
        KeySpec spec = new PBEKeySpec(password, salt, 1024, 128);
        SecretKey tmp = factory.generateSecret(spec);
        return new SecretKeySpec(tmp.getEncoded(), "AES");
    }

    private class DynamoDBManagerTask extends
            AsyncTask<DynamoDBManagerType, Void, DynamoDBManagerTaskResult> {

        protected DynamoDBManagerTaskResult doInBackground(
                DynamoDBManagerType... types) {

            String tableStatus = DynamoDBManager.getTableStatus();

            DynamoDBManagerTaskResult result = new DynamoDBManagerTaskResult();
            result.setTableStatus(tableStatus);
            result.setTaskType(types[0]);

            if (types[0] == DynamoDBManagerType.CREATE_TABLE) {
                if (tableStatus.length() == 0) {
                    //DynamoDBManager.createTable();
                }
            } else if (types[0] == DynamoDBManagerType.INSERT_USER) {
                if (tableStatus.equalsIgnoreCase("ACTIVE")) {
                    DynamoDBManager.insertUsers();
                }
            } else if (types[0] == DynamoDBManagerType.LIST_USERS) {
                if (tableStatus.equalsIgnoreCase("ACTIVE")) {
                    //DynamoDBManager.getUserList();
                }
            } else if (types[0] == DynamoDBManagerType.CLEAN_UP) {
                if (tableStatus.equalsIgnoreCase("ACTIVE")) {
                    //DynamoDBManager.cleanUp();
                }
            }

            return result;
        }

        protected void onPostExecute(DynamoDBManagerTaskResult result) {

            if (result.getTaskType() == DynamoDBManagerType.CREATE_TABLE) {

                if (result.getTableStatus().length() != 0) {
                    Toast.makeText(
                            SignUpActivity.this,
                            "The test table already exists.\nTable Status: "
                                    + result.getTableStatus(),
                            Toast.LENGTH_LONG).show();
                }

            } else if (result.getTaskType() == DynamoDBManagerType.LIST_USERS
                    && result.getTableStatus().equalsIgnoreCase("ACTIVE")) {

                /*startActivity(new Intent(UserPreferenceDemoActivity.this,
                        UserListActivity.class));*/

            } else if (!result.getTableStatus().equalsIgnoreCase("ACTIVE")) {

                Toast.makeText(
                        SignUpActivity.this,
                        "The test table is not ready yet.\nTable Status: "
                                + result.getTableStatus(), Toast.LENGTH_LONG)
                        .show();
            } else if (result.getTableStatus().equalsIgnoreCase("ACTIVE")
                    && result.getTaskType() == DynamoDBManagerType.INSERT_USER) {
                Toast.makeText(SignUpActivity.this,
                        "Users inserted successfully!", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private enum DynamoDBManagerType {
        GET_TABLE_STATUS, CREATE_TABLE, INSERT_USER, LIST_USERS, CLEAN_UP
    }

    private class DynamoDBManagerTaskResult {
        private DynamoDBManagerType taskType;
        private String tableStatus;

        public DynamoDBManagerType getTaskType() {
            return taskType;
        }

        public void setTaskType(DynamoDBManagerType taskType) {
            this.taskType = taskType;
        }

        public String getTableStatus() {
            return tableStatus;
        }

        public void setTableStatus(String tableStatus) {
            this.tableStatus = tableStatus;
        }
    }
}
