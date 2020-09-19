package com.glebcorp.blocks.utils;

extern class ArrayLast {
	public static inline function last<T>(array: Array<T>): Null<T>
		return array.length == 0 ? null : array[array.length - 1];
}
