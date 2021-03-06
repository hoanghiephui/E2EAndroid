package com.e2e.message.crypto;


import android.content.Context;
import android.util.Base64;

import com.prashantsolanki.secureprefmanager.SecurePrefManager;

import org.spongycastle.jce.provider.BouncyCastleProvider;
import org.spongycastle.pqc.math.ntru.polynomial.Constants;

import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.Signature;
import java.security.SignatureException;
import java.security.spec.MGF1ParameterSpec;
import java.security.spec.PSSParameterSpec;




public class SignatureUtils {

    private static Signature getInstance() {
        try {
            Signature s = Signature.getInstance("SHA256withRSA/PSS", new BouncyCastleProvider());
            PSSParameterSpec spec1 = new PSSParameterSpec("SHA-256", "MGF1", new MGF1ParameterSpec("SHA-256"), 0, 1);
            s.setParameter(spec1);
            return s;
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        } catch (InvalidAlgorithmParameterException e) {
            throw new RuntimeException(e);
        }
    }

    public static String genSignature(Context mContext, String text) {
        try {
            Signature s = getInstance();
            String privateKey = SecurePrefManager.with(mContext)
                    .get(com.e2e.message.data.Constants.RSA_PRIVATE_KEY)
                    .defaultValue("unknown")
                    .go();
            s.initSign(Crypto.getRSAPrivateKeyFromString(privateKey));
            s.update(text.getBytes());
            return RSA.stringify(Base64.encode(s.sign(), Base64.DEFAULT));
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        } catch (SignatureException e) {
            throw new RuntimeException(e);
        } catch (InvalidKeyException e) {
            throw new RuntimeException(e);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public static boolean checkSignature(Context mContext, String signature, String input) {
        try {
            Signature s = getInstance();
            String publicKey = SecurePrefManager.with(mContext)
                    .get(com.e2e.message.data.Constants.RSA_PUBLIC_KEY)
                    .defaultValue("unknown")
                    .go();
            s.initVerify(Crypto.getRSAPublicKeyFromString(publicKey));
            s.update(input.getBytes());
            return s.verify(Base64.decode(signature.getBytes(), Base64.DEFAULT));
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        } catch (SignatureException e) {
            throw new RuntimeException(e);
        } catch (InvalidKeyException e) {
            throw new RuntimeException(e);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}

