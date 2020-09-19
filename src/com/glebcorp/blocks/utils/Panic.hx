package com.glebcorp.blocks.utils;

extern class Panic {
    public static inline function panic(msg: String): Any
        throw msg;
}