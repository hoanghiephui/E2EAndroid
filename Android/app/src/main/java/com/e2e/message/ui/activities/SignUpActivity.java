package com.e2e.message.ui.activities;

import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;

import com.e2e.message.R;
import com.e2e.message.crypto.Crypto;
import com.e2e.message.crypto.RSA;
import com.e2e.message.data.AmazonClientManager;
import com.e2e.message.data.Constants;
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

import javax.crypto.SecretKey;

import static com.e2e.message.data.Constants.ACTIVE;
import static com.e2e.message.utils.HLUltils.UTF_8;
import static com.e2e.message.utils.KeyStoreUtils.loadKey;

/**
 * Created by hiep on 9/12/16.
 */
public class SignUpActivity extends BaseActivity implements View.OnClickListener {
    private static final String TAG = SignUpActivity.class.getSimpleName();
    private EditText edtUserName, edtPassword, edtFullName, edtReTypePassword;
    private Button btnSignUp;
    private ProgressBar progressSign;

    String keyQ;
    private byte[] keyK;
    public static AmazonClientManager clientManager = null;
    private UserResponse user;
    private String userId;

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
        this.progressSign = (ProgressBar) findViewById(R.id.progressSign);
        btnSignUp.setOnClickListener(this);
    }

    @Override
    protected void bindEventHandlers(){


    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.btnSignUp:
                if (StringUtil.isEmptyString(edtUserName.getText().toString()) ||
                        StringUtil.isEmptyString(edtFullName.getText().toString()) ||
                        StringUtil.isEmptyString(edtReTypePassword.getText().toString()) ||
                        StringUtil.isEmptyString(edtPassword.getText().toString())) {
                    Toast.makeText(this, "Username or Full name or Password null", Toast.LENGTH_SHORT).show();
                } else {
                    onSignUp();
                }

                break;
        }
    }

    private void onSignUp() {
        user = new UserResponse();
        userId = StringUtil.uniqueFromString(edtUserName.getText().toString());
        btnSignUp.setEnabled(false);
        progressSign.setVisibility(View.VISIBLE);
        new DynamoDBManagerTask().execute();
    }

    private void enCryptData() {
        //Generate RSA
        SecurePrefManager.with(this).clear();
        final KeyPair keyPair = RSA.generate();
        Crypto.writePrivateKeyToPreferences(this, keyPair);
        Crypto.writePublicKeyToPreferences(this, keyPair);
        String privateKeyPref = SecurePrefManager.with(this)
                .get(Constants.RSA_PRIVATE_KEY)
                .defaultValue("unknown")
                .go();

        String publicKeyPref = SecurePrefManager.with(this)
                .get(Constants.RSA_PUBLIC_KEY)
                .defaultValue("unknown")
                .go();

        Log.d(TAG, "onSignUp: public key: " + Crypto.stripPublicKeyHeaders(publicKeyPref) + " privateKey: " + Crypto.stripPublicKeyHeaders(privateKeyPref));

        JNCryptor cryptor = new AES256JNCryptor();

        try {
            keyK = cryptor.keyForPassword(edtPassword.getText().toString().toCharArray(), HLUltils.generateTagPrefix(8).getBytes(UTF_8)).getEncoded();

            keyQ = new String(cryptor.keyForPassword(edtPassword.getText().toString().toCharArray(), HLUltils.getkSalt()).getEncoded(), UTF_8);


            byte[] keyEncryptedK = cryptor.encryptData(keyK, keyQ.toCharArray());

            String keyKBase64 = new String(this.keyK, UTF_8);


            //luu keyQ

            File file = File.createTempFile("keyQ", ".key");
            KeyStoreUtils.saveKey(cryptor.keyForPassword(edtPassword.getText().toString().toCharArray(), HLUltils.getkSalt()), file);


            SecretKey persistedKey = loadKey(file);
            Log.d(TAG, "onSignUp: keyK " + keyKBase64);
            Log.d(TAG, "onSignUp: keyQ :" + keyQ);
            Log.d(TAG, "onSignUp: keyQ File: " + new String(persistedKey.getEncoded(), UTF_8));
            Log.d(TAG, "onSignUp: keyEnCry :" + Base64.encodeToString(keyEncryptedK, Base64.NO_PADDING));
            //ma hoa user
            user.setId(userId);
            user.setUserName(cryptor.encryptData(edtUserName.getText().toString().getBytes(UTF_8), keyKBase64.toCharArray()));
            user.setFullName(cryptor.encryptData(edtFullName.getText().toString().getBytes(UTF_8), keyKBase64.toCharArray()));
            user.setKeyK(keyEncryptedK);
            user.setPrivateKey(cryptor.encryptData(privateKeyPref.getBytes(UTF_8), keyKBase64.toCharArray()));
            user.setPublicKey(cryptor.encryptData(publicKeyPref.getBytes(UTF_8), keyKBase64.toCharArray()));

            Log.d(TAG, "onSignUp: userName: " + new String(cryptor.encryptData(edtUserName.getText().toString().getBytes(UTF_8), keyKBase64.toCharArray()), UTF_8));
            byte[] userName = cryptor.decryptData(user.getUserName(), keyKBase64.toCharArray());
            Log.d(TAG, "onSignUp: userUn: " + new String(userName, UTF_8));
        } catch (CryptorException e) {
            // Something went wrong
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (DecoderException e) {
            e.printStackTrace();
        }
    }


    private class DynamoDBManagerTask extends AsyncTask<Void, Boolean, DynamoDBManagerTaskResult> {


        @Override
        protected DynamoDBManagerTaskResult doInBackground(Void... voids) {
            String tableStatus = DynamoDBManager.getTableStatus(SignUpActivity.this, Constants.HL_USER_TABLE_NAME);

            DynamoDBManagerTaskResult result = new DynamoDBManagerTaskResult();

            if (tableStatus.equalsIgnoreCase(ACTIVE)) {
                if (DynamoDBManager.getUserById(SignUpActivity.this, userId) == null) {
                    enCryptData();
                    if (user != null) {
                        DynamoDBManager.insertUsers(user);
                        String tabbleContact = DynamoDBManager.getTableStatus(SignUpActivity.this, "HL_" + user.getId() + "_Contact");
                        if (!tabbleContact.equalsIgnoreCase("ACTIVE")) {
                            DynamoDBManager.createContactDBTable(SignUpActivity.this, user);
                        }
                        DynamoDBManager.createMessageDBTable(SignUpActivity.this, userId);
                    }

                } else {
                    result.setUserStatus(true);
                }

            }

            return result;
        }


        @Override
        protected void onPostExecute(DynamoDBManagerTaskResult result) {
            if (result.isUserStatus()) {
                Toast.makeText(SignUpActivity.this,
                        "The username was already exist. Please enter an other", Toast.LENGTH_LONG).show();
                edtUserName.setCursorVisible(true);
                edtUserName.setFocusable(true);
                btnSignUp.setEnabled(true);
                progressSign.setVisibility(View.GONE);
            } else if (!result.isUserStatus()) {
                Toast.makeText(SignUpActivity.this,
                        "Users inserted successfully!", Toast.LENGTH_SHORT).show();
                SignUpActivity.this.finish();
            }
        }
    }





    private class DynamoDBManagerTaskResult {

        private boolean userStatus;

        public boolean isUserStatus() {
            return userStatus;
        }

        public void setUserStatus(boolean userStatus) {
            this.userStatus = userStatus;
        }
    }
}
