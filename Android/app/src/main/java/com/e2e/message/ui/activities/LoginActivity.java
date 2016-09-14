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
import android.widget.Toast;

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
        new DynamoDBManagerTask().execute(DynamoDBManagerType.USER);
    }

    private class DynamoDBManagerTask extends AsyncTask<DynamoDBManagerType, Void, DynamoDBManagerTaskResult> {



        @Override
        protected DynamoDBManagerTaskResult doInBackground(DynamoDBManagerType... type) {
            String tableStatus = DynamoDBManager.getTableStatus(LoginActivity.this, HL_USER_TABLE_NAME);

            DynamoDBManagerTaskResult result = new DynamoDBManagerTaskResult();
            result.setTableStatus(tableStatus);
            result.setTaskType(type[0]);
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
            } else if (result.getTableStatus().equalsIgnoreCase("ACTIVE") && result.getTaskType() == DynamoDBManagerType.USER) {
                Toast.makeText(LoginActivity.this, "Login successfully!", Toast.LENGTH_SHORT).show();
                if (userInfo != null){
                    //Log.d(TAG, "onPostExecute: " + Base64.encodeToString(userInfo.getKeyK(), Base64.DEFAULT));
                    JNCryptor cryptor = new AES256JNCryptor();
                    byte[] encryptedKeyK = userInfo.getKeyK();
                    if (encryptedKeyK != null) {
                        try {
                            keyQ = new String(cryptor.keyForPassword(edtPassword.getText().toString().toCharArray(), HLUltils.getkSalt()).getEncoded(), UTF_8);


                            byte[] keyDecrypt = cryptor.decryptData(encryptedKeyK, keyQ.toCharArray());
                            byte[] userName = cryptor.decryptData(userInfo.getUserName(), new String(keyDecrypt, UTF_8).toCharArray());
                            byte[] publicKey = cryptor.decryptData(userInfo.getPrivateKey(), new String(keyDecrypt, UTF_8).toCharArray());
                            //String userName =  decrypt(cryptor, userInfo.getUserName(), Base64.encodeToString(keyDecrypt, Base64.DEFAULT));
                            Log.d(TAG, "onPostExecute: keyQ: " + keyQ);
                            Log.d(TAG, "onPostExecute: keyK: " + Base64.encodeToString(encryptedKeyK, Base64.NO_PADDING));
                            Log.d(TAG, "onPostExecute: keyDecrypt: " + Base64.encodeToString(keyDecrypt, Base64.NO_PADDING));
                            Log.d(TAG, "onPostExecute: userName: " + new String(userInfo.getUserName(), UTF_8) + "    " + new String(userName, UTF_8));
                            Log.d(TAG, "onPostExecute: publicKey: " + new String(publicKey, UTF_8));
                        } catch (InvalidHMACException e) {
                            Toast.makeText(LoginActivity.this, "The password is wrong. Please enter an other", Toast.LENGTH_SHORT).show();
                            e.printStackTrace();
                        } catch (CryptorException e) {
                            e.printStackTrace();
                        }
                    }else {
                        Toast.makeText(LoginActivity.this, "Your username/password is wrong. Please enter an other", Toast.LENGTH_SHORT).show();
                    }
                }else {
                    Toast.makeText(LoginActivity.this, "The username isn't already exist. Please enter an other!", Toast.LENGTH_SHORT).show();
                }
                //LoginActivity.this.finish();
            }
        }
    }






    private enum DynamoDBManagerType {
        GET_TABLE_STATUS, CREATE_TABLE, INSERT_USER, USER, CLEAN_UP
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
