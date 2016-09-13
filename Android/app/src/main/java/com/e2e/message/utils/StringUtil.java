package com.e2e.message.utils;

import org.hashids.Hashids;

/**
 * Created by hiep on 9/12/16.
 */
public class StringUtil {
    public static boolean isEmptyString(String string) {
        return string == null || string.trim().equals("") || string.trim().length() <= 0;
    }

    public static String uniqueFromString(String userName){
        Hashids hashids = new Hashids(userName, 10);
        return hashids.encode(9);
    }

    public static boolean isNullOrEmpty(String str) {
        return str == null || str.isEmpty();
    }
}
