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

    public static boolean checkPassWordAndConfirmPassword (String password, String confirmPassword) {
        boolean pstatus = false;
        if (confirmPassword != null && password != null) {
            if (password.equals (confirmPassword)) {
                pstatus = true;
            }
        }
        return pstatus;
    }
}
