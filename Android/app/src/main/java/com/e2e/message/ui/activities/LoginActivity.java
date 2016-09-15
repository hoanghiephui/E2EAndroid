package com.e2e.message.ui.activities;

import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Toast;

import com.e2e.message.MainActivity;
import com.e2e.message.R;
import com.e2e.message.data.DynamoDBManager;
import com.e2e.message.data.UserResponse;
import com.e2e.message.utils.HLUltils;
import com.e2e.message.utils.StringUtil;

import org.cryptonode.jncryptor.AES256JNCryptor;
import org.cryptonode.jncryptor.CryptorException;
import org.cryptonode.jncryptor.InvalidHMACException;
import org.cryptonode.jncryptor.JNCryptor;

import static com.e2e.message.data.Constants.ACTIVE;
import static com.e2e.message.data.Constants.HL_USER_TABLE_NAME;
import static com.e2e.message.utils.HLUltils.UTF_8;

/**
 * Created by hiep on 9/12/16.
 */
public class LoginActivity extends BaseActivity implements View.OnClickListener {
    private static final String TAG = LoginActivity.class.getSimpleName();
    private EditText edtUserName, edtPassword;
    private Button btnConnect;
    private ProgressBar progressLogin;
    private String keyQ;
    private String userId;
    private UserResponse userInfo = null;

    @Override
    protected int getMainLayout() {
        return R.layout.activity_login;
    }


    @Override
    protected void initToolbar(Bundle savedInstanceState) {

    }

    @Override
    protected void initComponents(Bundle savedInstanceState) {
        this.edtUserName = (EditText) findViewById(R.id.edtUserName);
        this.edtPassword = (EditText) findViewById(R.id.edtPassword);
        this.btnConnect = (Button) findViewById(R.id.btnConnect);
        this.progressLogin = (ProgressBar) findViewById(R.id.progressLogin);
        btnConnect.setOnClickListener(this);
    }

    @Override
    protected void bindEventHandlers() {


    }


    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.btnConnect:
                onConnect();
                break;
        }
    }

    private void onConnect() {
        if (StringUtil.isEmptyString(edtUserName.getText().toString()) ||
                StringUtil.isEmptyString(edtPassword.getText().toString())) {
            Toast.makeText(LoginActivity.this, "Username or Password null", Toast.LENGTH_SHORT).show();
        } else {
            login();
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.menu_login, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.menu_singup:
                startActivity(new Intent(this, SignUpActivity.class));
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }

    }

    private void login(){
        userId = StringUtil.uniqueFromString(edtUserName.getText().toString());
        new DynamoDBManagerTask().execute();
        progressLogin.setVisibility(View.VISIBLE);
        btnConnect.setEnabled(false);

    }

    private class DynamoDBManagerTask extends AsyncTask<Void, Void, DynamoDBManagerTaskResult> {

        @Override
        protected DynamoDBManagerTaskResult doInBackground(Void... voids) {
            String tableStatus = DynamoDBManager.getTableStatus(LoginActivity.this, HL_USER_TABLE_NAME);

            DynamoDBManagerTaskResult result = new DynamoDBManagerTaskResult();
            result.setTableStatus(tableStatus);

            if (tableStatus.equalsIgnoreCase(ACTIVE)) {
                userInfo = DynamoDBManager.getUserById(LoginActivity.this, userId);
            }
            return result;
        }

        @Override
        protected void onPostExecute(DynamoDBManagerTaskResult result) {
            if (!result.getTableStatus().equalsIgnoreCase("ACTIVE")) {
                Toast.makeText(LoginActivity.this,
                        "The test table is not ready yet.\nTable Status: "
                                + result.getTableStatus(), Toast.LENGTH_LONG).show();
                progressLogin.setVisibility(View.GONE);
                btnConnect.setEnabled(true);
            } else if (result.getTableStatus().equalsIgnoreCase("ACTIVE")) {

                if (userInfo != null){
                    JNCryptor cryptor = new AES256JNCryptor();
                    byte[] encryptedKeyK = userInfo.getKeyK();
                    if (encryptedKeyK != null) {
                        try {
                            //Check if any key exists
                            /*if (Hawk.contains(userId)){
                                keyQ = Hawk.get(userId);
                                Log.d (TAG, "login: getKeyQ: " + keyQ);
                            }*/

                            keyQ = Base64.encodeToString (cryptor.keyForPassword (edtPassword.getText ().toString ().toCharArray (), HLUltils.getkSalt ()).getEncoded (), Base64.NO_WRAP);

                            byte[] keyDecrypt = cryptor.decryptData(encryptedKeyK, keyQ.toCharArray());
                            byte[] userName = cryptor.decryptData (userInfo.getUserName (), Base64.encodeToString (keyDecrypt, Base64.NO_WRAP).toCharArray ());
                            byte[] publicKey = cryptor.decryptData (userInfo.getPrivateKey (), Base64.encodeToString (keyDecrypt, Base64.NO_WRAP).toCharArray ());
                            byte[] privateKey = cryptor.decryptData (userInfo.getPrivateKey (), Base64.encodeToString (keyDecrypt, Base64.NO_WRAP).toCharArray ());
                            byte[] fullName = cryptor.decryptData (userInfo.getFullName (), Base64.encodeToString (keyDecrypt, Base64.NO_WRAP).toCharArray ());

                            Log.d(TAG, "onPostExecute: keyQ: " + keyQ);
                            Log.d (TAG, "onPostExecute: keyK: " + Base64.encodeToString (encryptedKeyK, Base64.NO_WRAP));
                            Log.d (TAG, "onPostExecute: keyDecrypt: " + Base64.encodeToString (keyDecrypt, Base64.NO_WRAP));
                            Log.d(TAG, "onPostExecute: userName: " + new String(userInfo.getUserName(), UTF_8) + "    " + new String(userName, UTF_8));
                            Log.d(TAG, "onPostExecute: publicKey: " + new String(publicKey, UTF_8));

                            startActivity(new Intent(LoginActivity.this, MainActivity.class));
                            LoginActivity.this.finish();
                        } catch (InvalidHMACException e) {
                            progressLogin.setVisibility(View.GONE);
                            btnConnect.setEnabled(true);
                            Toast.makeText(LoginActivity.this, "The password is wrong. Please enter an other", Toast.LENGTH_SHORT).show();
                            e.printStackTrace();
                        } catch (CryptorException e) {
                            e.printStackTrace();
                        }
                    }else {
                        progressLogin.setVisibility(View.GONE);
                        btnConnect.setEnabled(true);
                        Toast.makeText(LoginActivity.this, "Your username/password is wrong. Please enter an other", Toast.LENGTH_SHORT).show();
                    }
                }else {
                    progressLogin.setVisibility(View.GONE);
                    btnConnect.setEnabled(true);
                    Toast.makeText(LoginActivity.this, "The username isn't already exist. Please enter an other!", Toast.LENGTH_SHORT).show();
                }

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
