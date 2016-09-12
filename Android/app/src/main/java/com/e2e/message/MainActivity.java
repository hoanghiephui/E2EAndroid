package com.e2e.message;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.support.v7.widget.RecyclerView;

import com.e2e.message.ui.activities.BaseActivity;

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
}
