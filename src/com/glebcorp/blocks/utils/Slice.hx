package com.glebcorp.blocks.utils;

class Slice {
    #if(js)
    public static extern inline function slice(str: String, start: Int, end: Int): String {
        return js.Syntax.code("str.slice(start, end)");
    }
    #else
    public static function slice(str: String, start: Int, end: Int): String {
        if (start < 0) start += str.length - 1;
        if (end < 0) end += str.length - 1;
        return str.substr(start, end);
    }
    #end
}