package com.glebcorp.blocks.utils;

using com.glebcorp.blocks.utils.ArrayLast;
import com.glebcorp.blocks.engine.Engine;

using Type;

class ClassName {
	public static function getName<T: BValue>(c: Class<T>): String {
		return c.getClassName().split(".").last().substr(1);
	}
}
