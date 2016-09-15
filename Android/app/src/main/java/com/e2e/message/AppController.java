package com.e2e.message;

import android.app.Application;

import com.orhanobut.hawk.Hawk;
import com.prashantsolanki.secureprefmanager.SecurePrefManagerInit;

/**
 * Created by hiep on 9/13/16.
 */

public class AppController extends Application{

    @Override
    public void onCreate() {
        super.onCreate();
        new SecurePrefManagerInit.Initializer(getApplicationContext())
                .useEncryption(true)
                .initialize();
        Hawk.init (getApplicationContext ()).build ();
    }
}
