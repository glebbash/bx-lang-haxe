package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.utils.MaxFloat.maxFloat;

using com.glebcorp.blocks.utils.NullUtils;

@:tink class NamedPrec {
	final name: String = _;
	final prec: Float = _;
}

extern class RelativePrecedence {
	static inline function precedence(): String->PrecGen {
		final data: Map<String, Float> = ["MIN" => 0, "MAX" => maxFloat()];
		return (name: String) -> new PrecGen(name, data);
	}
}

@:tink class PrecGen {
	final name: String = _;
	final data: Map<String, Float> = _;

	function between(after: String, before: String): NamedPrec {
		final prec = (data[after].unwrap() + data[before].unwrap()) / 2.0;
		data[name] = prec;
		return new NamedPrec(name, prec);
	}

	extern inline function lessThan(val: String): NamedPrec {
		return between("MIN", val);
	}

	extern inline function moreThan(val: String): NamedPrec {
		return between(val, "MAX");
	}

	extern inline function sameAs(val: String): NamedPrec {
		return between(val, val);
	}
}
