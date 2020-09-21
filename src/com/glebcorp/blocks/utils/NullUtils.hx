package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.utils.Panic.panic;

@:publicFields
extern class NullUtils {
	static inline function unwrap<T>(value: Null<T>): T {
		return value == null ? panic("Attempt to unwrap null") : (value: T);
	}

	static inline function unsafe<T>(value: Null<T>): T {
		return @:nullSafety(Off) (value: T);
	}

	static inline function or<T>(value: Null<T>, def: T): T {
		return value == null ? def : (value: T);
	}
}
