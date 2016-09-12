package com.e2e.message.ui.activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import com.e2e.message.R;
import com.e2e.message.utils.StringUtil;

/**
 * Created by hiep on 9/12/16.
 */
public class LoginActivity extends BaseActivity implements View.OnClickListener {
    private EditText edtUserName, edtPassword;
    private Button btnConnect;

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
}
