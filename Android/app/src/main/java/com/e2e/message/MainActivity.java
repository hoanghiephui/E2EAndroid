package com.e2e.message;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.widget.RecyclerView;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;

import com.e2e.message.ui.activities.BaseActivity;
import com.e2e.message.ui.activities.LoginActivity;

public class MainActivity extends BaseActivity {
    private RecyclerView recyHome;


    @Override
    protected int getMainLayout() {
        return R.layout.activity_main;
    }

    @Override
    protected void initToolbar(Bundle savedInstanceState) {

    }

    @Override
    protected void initComponents(Bundle savedInstanceState) {
        this.recyHome = (RecyclerView) findViewById(R.id.recyHome);
    }

    @Override
    protected void bindEventHandlers() {

    }

    @Override
    public boolean onCreateOptionsMenu (Menu menu) {
        MenuInflater inflater = getMenuInflater ();
        inflater.inflate (R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected (MenuItem item) {
        switch (item.getItemId ()) {
            case R.id.menu_logOut:
                startActivity (new Intent (this, LoginActivity.class));
                finish ();
                return true;
            default:
                return super.onOptionsItemSelected (item);
        }

    }
}
