package com.e2e.message.utils;

/**
 * Created by hiep on 9/12/16.
 */
public class StringUtil {
    public static boolean isEmptyString(String string) {
        return string == null || string.trim().equals("") || string.trim().length() <= 0;
    }
}
