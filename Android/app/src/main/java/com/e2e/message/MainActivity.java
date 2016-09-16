package com.e2e.message;

import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.Toast;

import com.amazonaws.util.DateUtils;
import com.e2e.message.data.Constants;
import com.e2e.message.data.ContactResponse;
import com.e2e.message.data.DynamoDBManager;
import com.e2e.message.ui.activities.BaseActivity;
import com.e2e.message.ui.activities.LoginActivity;
import com.prashantsolanki.secureprefmanager.SecurePrefManager;

import java.util.Date;

import static com.e2e.message.data.Constants.ACTIVE;
import static com.e2e.message.data.DynamoDBManager.insertContact;

public class MainActivity extends BaseActivity {
    private static final String TAG = MainActivity.class.getSimpleName ();
    private RecyclerView recyHome;
    private ContactResponse contactResponse;
    String userID;


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
        Bundle bundle = getIntent ().getExtras ();
        userID = bundle.getString ("id");
    }

    @Override
    protected void bindEventHandlers() {
        String id = DateUtils.formatISO8601Date (new Date ());
        Log.d (TAG, "bindEventHandlers: time: " + id);
        String publicKeyPref = SecurePrefManager.with (this)
                .get (Constants.RSA_PUBLIC_KEY)
                .defaultValue ("unknown")
                .go ();
        contactResponse = new ContactResponse ();
        contactResponse.setV_ctId (id);
        contactResponse.setV_ctUsername (publicKeyPref.getBytes ());
        contactResponse.setV_ctFullname (publicKeyPref.getBytes ());
        contactResponse.setV_ctPublicKey (publicKeyPref.getBytes ());

        new DynamoDBManagerTask ().execute ();

    }

    private class DynamoDBManagerTask extends AsyncTask<Void, Void, DynamoDBManagerTaskResult> {

        @Override
        protected DynamoDBManagerTaskResult doInBackground (Void... voids) {
            String tableName = "HL_" + userID + "_Contact";
            String tableStatus = DynamoDBManager.getTableStatus (MainActivity.this, tableName);

            DynamoDBManagerTaskResult result = new DynamoDBManagerTaskResult ();
            result.setTableStatus (tableStatus);

            if (tableStatus.equalsIgnoreCase (ACTIVE)) {
                boolean done = insertContact (contactResponse, tableName, MainActivity.this);
            }
            return result;
        }

        @Override
        protected void onPostExecute (DynamoDBManagerTaskResult result) {
            if (!result.getTableStatus ().equalsIgnoreCase ("ACTIVE")) {
                Toast.makeText (MainActivity.this,
                        "The test table is not ready yet.\nTable Status: "
                                + result.getTableStatus (), Toast.LENGTH_LONG).show ();

            } else if (result.getTableStatus ().equalsIgnoreCase ("ACTIVE")) {


            }
        }
    }


    private class DynamoDBManagerTaskResult {
        private String tableStatus;

        public String getTableStatus () {
            return tableStatus;
        }

        public void setTableStatus (String tableStatus) {
            this.tableStatus = tableStatus;
        }
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
