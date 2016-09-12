package com.e2e.message.ui.activities;

import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.MenuItem;

/**
 * Created by hiep on 9/12/16.
 */
public abstract class BaseActivity extends AppCompatActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (!initContentView()) {
            return;
        }

        initToolbar(savedInstanceState);
        initComponents(savedInstanceState);
        bindEventHandlers();
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);


    }

    protected boolean initContentView() {
        setContentView(getMainLayout());
        return true;
    }

    protected abstract int getMainLayout();

    protected abstract void initToolbar(Bundle savedInstanceState);

    protected abstract void initComponents(Bundle savedInstanceState);

    protected abstract void bindEventHandlers();

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                finish();
                break;
        }
        return true;
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        finish();
    }


}
