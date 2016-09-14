package com.e2e.message.utils;

import android.util.Base64;

import org.cryptonode.jncryptor.AES256JNCryptor;
import org.cryptonode.jncryptor.CryptorException;
import org.cryptonode.jncryptor.JNCryptor;
import org.spongycastle.util.encoders.DecoderException;

import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.KeySpec;

import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;

import static org.apache.commons.codec.binary.Hex.decodeHex;
import static org.apache.commons.codec.binary.Hex.encodeHex;
import static org.apache.commons.io.FileUtils.readFileToByteArray;
import static org.apache.commons.io.FileUtils.writeStringToFile;

/**
 * Created by hiep on 9/13/16.
 */

public class KeyStoreUtils {
    private static final String ALGO = "AES";
    private static final int KEYSZ = 256;// 128 default; 192 and 256 also possible

    public static SecretKey generateKey() throws NoSuchAlgorithmException
    {
        KeyGenerator keyGenerator = KeyGenerator.getInstance(ALGO);
        keyGenerator.init(KEYSZ);
        SecretKey key = keyGenerator.generateKey();
        return key;
    }

    public static void saveKey(SecretKey key, File file) throws IOException
    {
        byte[] encoded = key.getEncoded();
        char[] hex = encodeHex(encoded);
        String data = String.valueOf(hex);
        writeStringToFile(file, data);
    }

    public static SecretKey loadKey(File file) throws IOException, org.apache.commons.codec.DecoderException {
        String data = new String(readFileToByteArray(file));
        char[] hex = data.toCharArray();
        byte[] encoded;
        try
        {
            encoded = decodeHex(hex);
        }
        catch (DecoderException e)
        {
            // TODO Auto-generated catch block
            e.printStackTrace();
            return null;
        }
        SecretKey key = new SecretKeySpec(encoded, ALGO);
        return key;
    }

    public static SecretKey getSecretKey(char[] password, byte[] salt) throws NoSuchAlgorithmException, InvalidKeySpecException {
        SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
        // NOTE: last argument is the key length, and it is 128
        KeySpec spec = new PBEKeySpec(password, salt, 1024, 128);
        SecretKey tmp = factory.generateSecret(spec);
        return new SecretKeySpec(tmp.getEncoded(), "AES");
    }

    public static String decrypt(JNCryptor cryptor, byte[] encryptedData, String password) {
        byte[] decryptData = null;
        try {
            decryptData = cryptor.decryptData(Base64.decode(encryptedData, Base64.DEFAULT), password.toCharArray());
        } catch (CryptorException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        if (decryptData != null){
            return Base64.encodeToString(decryptData, Base64.NO_WRAP);
        }else {
            return "";
        }
    }


}
