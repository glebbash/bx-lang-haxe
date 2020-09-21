package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude;

using StringTools;
using Lambda;

@:publicFields
class Format {
    static function format(template: String, args: BArray): String {
        final f = (val: BValue, tmp: String) -> tmp.replace("{}", Std.string(val));
        return args.data.fold(f, template);
    }

    static function formatN<T>(template: String, args: BObject): String {
        for (key => val in args) {
            template = template.replace('{$key}', Std.string(val));
        }
        return template;
    }
}