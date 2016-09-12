package com.e2e.message.utils;

import java.nio.charset.Charset;
import java.util.Random;

/**
 * Created by hiep on 9/12/16.
 */
public class HLUltils {
    public static final Charset UTF_8 = Charset.forName("UTF-8");

    public static byte[] kSalt = "HL-SALT".getBytes(UTF_8);
    public static byte[] kRSATag = "com.yusuf.e2e".getBytes(UTF_8);

    public static byte[] getkSalt() {
        return kSalt;
    }

    public static byte[] getkRSATag() {
        return kRSATag;
    }

    public static String generateTagPrefix(int length) {
        String letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        StringBuilder sb = new StringBuilder(length);
        Random r = new Random();
        for (int i = 0; i < length; i++) {
            sb.append("%C").append(letters.charAt(r.nextInt(letters.length())));
        }
        return sb.toString();
    }
}
