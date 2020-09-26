package com.glebcorp.blocks.utils;

class Slice {
    #if(js)
    static extern inline function slice(str: String, start: Int, end: Int): String {
        return js.Syntax.code("str.slice({0}, {1})", start, end);
    }
    #else
    static function slice(str: String, start: Int, end: Int): String {
        if (start < 0) start += str.length - 1;
        if (end < 0) end += str.length - 1;
        return str.substr(start, end);
    }
    #end
}