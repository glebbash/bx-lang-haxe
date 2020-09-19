package com.glebcorp.blocks.utils;

extern class MaxFloat {
    public static inline function maxFloat():Float {
        #if flash
        return untyped __global__['Number'].MAX_VALUE;
        #elseif js
        return js.Syntax.code('Number.MAX_VALUE');
        #elseif cs
        return untyped __cs__('double.MaxValue');
        #elseif java
        return untyped __java__('Double.MAX_VALUE');
        #elseif cpp
        return 1.79769313486232e+308;
        #elseif hl
        return 3.4028234664e+38;
        #elseif python
        return Sys.float_info.max;
        #else
        return 1.79e+308;
        #end
    }
}