package com.glebcorp.blocks.utils;

extern class ArrayLast {
    public static inline function last<T>(array: Array<T>): T
        return array[array.length - 1];
}