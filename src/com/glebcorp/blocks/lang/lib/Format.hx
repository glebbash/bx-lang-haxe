package com.glebcorp.blocks.lang.lib;

import com.glebcorp.blocks.lang.Engine;
import com.glebcorp.blocks.lang.Prelude;

using Lambda;
using StringTools;

class Format {
    static final regex = ~/\{\}/;
    
    static function format(template: String, args: BArray): String {
        final f = (val: BValue, tmp: String) -> regex.replace(tmp, Std.string(val));
        return args.data.fold(f, template);
    }

    static function formatN<T>(template: String, args: BObject): String {
        for (key => val in args) {
            template = template.replace('{$key}', Std.string(val));
        }
        return template;
    }
}