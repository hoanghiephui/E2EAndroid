package com.e2e.message.crypto;

import android.content.Context;
import android.util.Log;

import com.e2e.message.data.Constants;
import com.e2e.message.utils.StringUtil;
import com.prashantsolanki.secureprefmanager.SecurePrefManager;

import org.spongycastle.util.Arrays;
import org.spongycastle.util.encoders.Base64;
import org.spongycastle.util.io.pem.PemObject;
import org.spongycastle.util.io.pem.PemWriter;

import java.io.IOException;
import java.io.StringWriter;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;



public class Crypto {

    public static void writePublicKeyToPreferences(Context mContext, KeyPair key) {
        StringWriter publicStringWriter = new StringWriter();
        try {
            PemWriter pemWriter = new PemWriter(publicStringWriter);
            pemWriter.writeObject(new PemObject("PUBLIC KEY", key.getPublic().getEncoded()));
            pemWriter.flush();
            pemWriter.close();
            SecurePrefManager.with(mContext)
                    .set(Constants.RSA_PUBLIC_KEY)
                    .value(publicStringWriter.toString())
                    .go();
        } catch (IOException e) {
            Log.e("RSA", e.getMessage());
            e.printStackTrace();
        }
    }

    public static void writePrivateKeyToPreferences(Context mContext, KeyPair keyPair) {
        StringWriter privateStringWriter = new StringWriter();
        try {
            PemWriter pemWriter = new PemWriter(privateStringWriter);
            pemWriter.writeObject(new PemObject("PRIVATE KEY", keyPair.getPrivate().getEncoded()));
            pemWriter.flush();
            pemWriter.close();
            SecurePrefManager.with(mContext)
                    .set(Constants.RSA_PRIVATE_KEY)
                    .value(privateStringWriter.toString())
                    .go();
        } catch (IOException e) {
            Log.e("RSA", e.getMessage());
            e.printStackTrace();
        }
    }

    public static PublicKey getRSAPublicKeyFromString(String publicKeyPEM) throws Exception {
        publicKeyPEM = stripPublicKeyHeaders(publicKeyPEM);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA", "SC");
        byte[] publicKeyBytes = Base64.decode(publicKeyPEM.getBytes("UTF-8"));
        X509EncodedKeySpec x509KeySpec = new X509EncodedKeySpec(publicKeyBytes);
        return keyFactory.generatePublic(x509KeySpec);
    }

    public static PrivateKey getRSAPrivateKeyFromString(String privateKeyPEM) throws Exception {
        privateKeyPEM = stripPrivateKeyHeaders(privateKeyPEM);
        KeyFactory fact = KeyFactory.getInstance("RSA", "SC");
        byte[] clear = Base64.decode(privateKeyPEM);
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(clear);
        PrivateKey priv = fact.generatePrivate(keySpec);
        Arrays.fill(clear, (byte) 0);
        return priv;
    }

    public static String stripPublicKeyHeaders(String key) {
        //strip the headers from the key string
        StringBuilder strippedKey = new StringBuilder();
        String lines[] = key.split("\n");
        for (String line : lines) {
            if (!line.contains("BEGIN PUBLIC KEY") && !line.contains("END PUBLIC KEY") && !StringUtil.isNullOrEmpty(line.trim())) {
                strippedKey.append(line.trim());
            }
        }
        return strippedKey.toString().trim();
    }

    public static String stripPrivateKeyHeaders(String key) {
        StringBuilder strippedKey = new StringBuilder();
        String lines[] = key.split("\n");
        for (String line : lines) {
            if (!line.contains("BEGIN PRIVATE KEY") && !line.contains("END PRIVATE KEY") && !StringUtil.isNullOrEmpty(line.trim())) {
                strippedKey.append(line.trim());
            }
        }
        return strippedKey.toString().trim();
    }

}
