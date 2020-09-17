package com.glebcorp.blocks.utils;

class Panic {
    public static function panic(msg: String): Any {
        throw msg;
    }
}