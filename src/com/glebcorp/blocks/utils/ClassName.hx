package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.engine.Engine;

using Type;
using com.glebcorp.blocks.utils.ArrayUtils;
using com.glebcorp.blocks.utils.NullUtils;

class ClassName {
	static function getName<T: BValue>(c: Class<T>): String {
		return c.getClassName().split(".").last().unwrap().substr(1);
	}
}
