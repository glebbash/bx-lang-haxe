package com.glebcorp.blocks.utils;

class Unwrap {
	public static inline function unwrap<T>(value: Null<T>): T {
		return @:nullSafety(Off) (value: T);
	}
}
