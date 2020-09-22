package com.glebcorp.blocks.utils;

import haxe.Exception;

extern class Panic {
    static inline function panic(msg: String): Any {
        throw new Exception(msg);
    }
}