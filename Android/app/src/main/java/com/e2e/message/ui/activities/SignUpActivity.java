package com.e2e.message.ui.activities;

import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import com.e2e.message.R;
import com.e2e.message.utils.HLUltils;
import com.e2e.message.utils.StringUtil;

import org.cryptonode.jncryptor.AES256JNCryptor;
import org.cryptonode.jncryptor.CryptorException;
import org.cryptonode.jncryptor.JNCryptor;

import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.KeySpec;

import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

/**
 * Created by hiep on 9/12/16.
 */
public class SignUpActivity extends BaseActivity implements View.OnClickListener {
    private static final String TAG = SignUpActivity.class.getSimpleName();
    private EditText edtUserName, edtPassword, edtFullName, edtReTypePassword;
    private Button btnSignUp;

    String keyQ;
    String keyK;

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
        this.edtUserName = (EditText) findViewById(R.id.edtUserName);
        this.edtPassword = (EditText) findViewById(R.id.edtPassword);
        this.edtFullName = (EditText) findViewById(R.id.edtFullName);
        this.edtReTypePassword = (EditText) findViewById(R.id.edtReTypePassword);
        this.btnSignUp = (Button) findViewById(R.id.btnSignUp);
        btnSignUp.setOnClickListener(this);
    }

    @Override
    protected void bindEventHandlers() {

        JNCryptor cryptor = new AES256JNCryptor();

        String password = "secretsquirrel";
        /*try {
            keyQ =  cryptor.keyForPassword(password.toCharArray(), plaintext).getAlgorithm();
            keyK = cryptor.keyForPassword(password.toCharArray(), plaintext).getAlgorithm();
        } catch (CryptorException e) {
            e.printStackTrace();
        }*/


        try {

            byte[] keyEncryptedK = cryptor.encryptData(HLUltils.getkSalt(),
                    getSecretKey(password.toCharArray(), HLUltils.generateTagPrefix(8).getBytes()),
                    getSecretKey(password.toCharArray(), HLUltils.getkSalt()));
            String str = Base64.encodeToString(keyEncryptedK, Base64.NO_WRAP);
            Log.d(TAG, "bindEventHandlers: " + str);
        } catch (CryptorException e) {
            // Something went wrong
            e.printStackTrace();
        } catch (InvalidKeySpecException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
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
        if (StringUtil.isEmptyString(edtUserName.getText().toString()) ||
                StringUtil.isEmptyString(edtFullName.getText().toString()) ||
                StringUtil.isEmptyString(edtReTypePassword.getText().toString()) ||
                StringUtil.isEmptyString(edtPassword.getText().toString())) {
            Toast.makeText(this, "Username or Full name or Password null", Toast.LENGTH_SHORT).show();
        } else {

        }
    }

    public static SecretKey getSecretKey(char[] password, byte[] salt) throws NoSuchAlgorithmException, InvalidKeySpecException {
        SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
        // NOTE: last argument is the key length, and it is 128
        KeySpec spec = new PBEKeySpec(password, salt, 1024, 128);
        SecretKey tmp = factory.generateSecret(spec);
        SecretKey secret = new SecretKeySpec(tmp.getEncoded(), "AES");
        return (secret);
    }
}
