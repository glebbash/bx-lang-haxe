package com.glebcorp.blocks.utils;

class ArrayLast {
    public static inline function last<T>(array: Array<T>): T {
        return array[array.length - 1];
    }
}