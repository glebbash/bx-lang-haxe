package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.utils.MaxFloat.maxFloat;

using com.glebcorp.blocks.utils.Unwrap;

class NamedPrec {
	public final name: String;
	public final prec: Float;

	public function new(name: String, prec: Float) {
		this.name = name;
		this.prec = prec;
	}
}

class RelativePrecedence {
	public static function precedence() {
		var data: Map<String, Float> = ["MIN" => 0, "MAX" => maxFloat()];
		return function(name: String) return new PrecGen(name, data);
	}
}

class PrecGen {
	public final name: String;
	public final data: Map<String, Float>;

	public function new(name: String, data: Map<String, Float>) {
		this.name = name;
		this.data = data;
	}

	public function between(after: String, before: String): NamedPrec {
		var prec = (data[after].unwrap() + data[before].unwrap()) / 2.0;
		data[name] = prec;
		return new NamedPrec(name, prec);
	}

	public function lessThan(val: String): NamedPrec
		return between("MIN", val);

	public function moreThan(val: String): NamedPrec
		return between(val, "MAX");

	public function sameAs(val: String): NamedPrec
		return between(val, val);
}
