package com.glebcorp.blocks.utils;

class Slice {
    #if(js)
    public static extern inline function slice(str: String, start: Int, end: Int): String {
        return js.Syntax.code("str.slice(start, end)");
    }
    #else
    public static function slice(str: String, start: Int, end: Int): String {
        if (start < 0) start += str.length;
        if (end < 0) end += str.length;
        return str.substr(start, end);
    }
    #end
}