package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.utils.MaxFloat.maxFloat;

using com.glebcorp.blocks.utils.Unwrap;

@:publicFields
class NamedPrec {
	final name: String;
	final prec: Float;

	function new(name: String, prec: Float) {
		this.name = name;
		this.prec = prec;
	}
}

extern class RelativePrecedence {
	public static inline function precedence(): String->PrecGen {
		var data: Map<String, Float> = ["MIN" => 0, "MAX" => maxFloat()];
		return function(name: String) return new PrecGen(name, data);
	}
}

@:publicFields
class PrecGen {
	final name: String;
	final data: Map<String, Float>;

	function new(name: String, data: Map<String, Float>) {
		this.name = name;
		this.data = data;
	}

	function between(after: String, before: String): NamedPrec {
		var prec = (data[after].unwrap() + data[before].unwrap()) / 2.0;
		data[name] = prec;
		return new NamedPrec(name, prec);
	}

	extern inline function lessThan(val: String): NamedPrec
		return between("MIN", val);

	extern inline function moreThan(val: String): NamedPrec
		return between(val, "MAX");

	extern inline function sameAs(val: String): NamedPrec
		return between(val, val);
}
