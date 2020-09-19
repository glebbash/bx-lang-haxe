package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.utils.Panic.panic;

extern class NullUtils {
	public static inline function unwrap<T>(value: Null<T>): T {
		return value == null ? panic("Attempt to unwrap null") : (value: T);
	}

	public static inline function unsafe<T>(value: Null<T>): T {
		return @:nullSafety(Off) (value: T);
	}

	public static inline function or<T>(value: Null<T>, def: T): T {
		return value == null ? def : (value: T);
	}
}
