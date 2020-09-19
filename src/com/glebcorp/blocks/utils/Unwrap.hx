package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.utils.Panic.panic;

extern class Unwrap {
	public static inline function unwrap<T>(value: Null<T>): T {
		return value == null ? panic("Attempt to unwrap null") : (value: T);
	}

	public static inline function unsafe<T>(value: Null<T>): T {
		return @:nullSafety(Off) (value: T);
	}
}
