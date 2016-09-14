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
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.KeySpec;

import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

import static com.e2e.message.data.Constants.ACTIVE;
import static com.e2e.message.utils.HLUltils.UTF_8;
import static com.e2e.message.utils.KeyStoreUtils.decrypt;
import static com.e2e.message.utils.KeyStoreUtils.getSecretKey;
import static com.e2e.message.utils.KeyStoreUtils.loadKey;

/**
 * Created by hiep on 9/12/16.
 */
public class SignUpActivity extends BaseActivity implements View.OnClickListener {
    private static final String TAG = SignUpActivity.class.getSimpleName();
    private EditText edtUserName, edtPassword, edtFullName, edtReTypePassword;
    private Button btnSignUp;

    String keyQ;
    private byte[] keyK;
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
                String ss = HLUltils.generateTagPrefix(8);
                Log.d(TAG, "onSignUp: leng salt"+ ss.getBytes(UTF_8).length);
                keyK = cryptor.keyForPassword(edtPassword.getText().toString().toCharArray(), HLUltils.generateTagPrefix(8).getBytes(UTF_8)).getEncoded();
                       // getSecretKey(edtPassword.getText().toString().toCharArray(), HLUltils.generateTagPrefix(8).getBytes()).getEncoded();
                keyQ = Base64.encodeToString(cryptor.keyForPassword(edtPassword.getText().toString().toCharArray(), HLUltils.getkSalt()).getEncoded(), Base64.URL_SAFE);
                        //Base64.encodeToString(getSecretKey(edtPassword.getText().toString().toCharArray(), HLUltils.getkSalt()).getEncoded(), Base64.NO_WRAP);



                byte[] keyEncryptedK = cryptor.encryptData(keyK , keyQ.toCharArray());

                String keyDecrypt = Base64.encodeToString(keyK, Base64.URL_SAFE) ;

                Log.d(TAG, "onSignUp: keyEncrypt " + keyDecrypt);

                //luu keyQ

                File file = File.createTempFile("keyQ", ".key");
                KeyStoreUtils.saveKey(getSecretKey(edtPassword.getText().toString().toCharArray(), HLUltils.getkSalt()), file);


                SecretKey persistedKey = loadKey(file);
                Log.d(TAG, "onSignUp: keyQ :" + keyQ + " keyQ File: " + Base64.encodeToString(persistedKey.getEncoded(), Base64.URL_SAFE));

                //ma hoa user
                user.setId(StringUtil.uniqueFromString(edtUserName.getText().toString()));
                user.setUserName(cryptor.encryptData(edtUserName.getText().toString().getBytes(), keyDecrypt.toCharArray()));
                user.setFullName(cryptor.encryptData(edtFullName.getText().toString().getBytes(), keyDecrypt.toCharArray()));
                user.setKeyK(keyEncryptedK);
                user.setPrivateKey(cryptor.encryptData(privateKeyPref.getBytes(), keyDecrypt.toCharArray()));
                user.setPublicKey(cryptor.encryptData(publicKeyPref.getBytes(), keyDecrypt.toCharArray()));
                new DynamoDBManagerTask().execute(user);

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



    private class DynamoDBManagerTask extends AsyncTask<UserResponse, Void, DynamoDBManagerTaskResult>{




        @Override
        protected DynamoDBManagerTaskResult doInBackground(UserResponse... userResponses) {
            String tableStatus = DynamoDBManager.getTableStatus(SignUpActivity.this, Constants.HL_USER_TABLE_NAME);

            DynamoDBManagerTaskResult result = new DynamoDBManagerTaskResult();
            result.setTableStatus(tableStatus);
            if (tableStatus.equalsIgnoreCase(ACTIVE)) {
                DynamoDBManager.insertUsers(userResponses[0]);
                String tabbleContact = DynamoDBManager.getTableStatus(SignUpActivity.this, "HL_" + userResponses[0].getId() + "_Contact");
                if (!tabbleContact.equalsIgnoreCase("ACTIVE")){
                    DynamoDBManager.createContactDBTable(SignUpActivity.this, userResponses[0]);
                }
                DynamoDBManager.createMessageDBTable(SignUpActivity.this, userResponses[0]);
            }

            return result;
        }

        @Override
        protected void onPostExecute(DynamoDBManagerTaskResult result) {
            if (!result.getTableStatus().equalsIgnoreCase("ACTIVE")) {

                Toast.makeText(
                        SignUpActivity.this,
                        "The test table is not ready yet.\nTable Status: "
                                + result.getTableStatus(), Toast.LENGTH_LONG)
                        .show();
            } else if (result.getTableStatus().equalsIgnoreCase("ACTIVE")) {
                Toast.makeText(SignUpActivity.this,
                        "Users inserted successfully!", Toast.LENGTH_SHORT).show();
                SignUpActivity.this.finish();
            }
        }
    }





    private class DynamoDBManagerTaskResult {

        private String tableStatus;

        public String getTableStatus() {
            return tableStatus;
        }

        public void setTableStatus(String tableStatus) {
            this.tableStatus = tableStatus;
        }
    }
}
