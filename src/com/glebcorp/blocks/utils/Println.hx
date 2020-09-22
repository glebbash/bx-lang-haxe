package com.glebcorp.blocks.utils;

extern class Println {
    static inline function println(val: Any): Void {
        #if(sys)
        Sys.println(val);
        #elseif(js)
        js.html.Console.log(val);
        #end
    }
}