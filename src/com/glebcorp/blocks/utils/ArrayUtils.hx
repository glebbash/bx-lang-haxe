package com.glebcorp.blocks.utils;

@:publicFields
class ArrayUtils {
	static extern inline function last<T>(array: Array<T>): Null<T> {
        return array.length == 0 ? null : array[array.length - 1];
    }
    
    static function every<T>(arr: Array<T>, fun: T -> Bool): Bool {
        for (e in arr) {
            if (!fun(e)) {
                return false;
            }
        }
        return true;
    }
}