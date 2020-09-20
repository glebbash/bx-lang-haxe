package com.glebcorp.blocks.utils;

using StringTools;

class Format {
    public static function format<T>(template: String, args: Array<T>): String {
        final f = (val: T, tmp: String) -> tmp.replace("{}", Std.string(val));
        return Lambda.fold(args, f, template);
    }

    public static function formatN<T>(template: String, args: Map<String, T>): String {
        for (key => val in args) {
            template = template.replace('{$key}', Std.string(val));
        }
        return template;
    }
}