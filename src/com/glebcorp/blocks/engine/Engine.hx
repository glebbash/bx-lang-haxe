package com.glebcorp.blocks.engine;

import com.glebcorp.blocks.utils.Panic.panic;

using Type;
using com.glebcorp.blocks.utils.ClassName;

class Engine {
	public function new() {}
}

class BValue {
	public final type: String;

	@:nullSafety(Off)
	public function new()
		this.type = this.getClass().getName();

	@:nullSafety(Off)
	public function is<T: BValue>(c: Class<T>): Bool
		return this.getClass() == cast(c);

	@:nullSafety(Off)
	public function as<T: BValue>(c: Class<T>): T
		return is(c) ? cast(this) : panic('Cannot cast $type to ${c.getName()}');

	public function equals(other: BValue): Bool
		return this == other;

	public function toString(): String
		throw "Abstract method";
}

class BWrapper<T> extends BValue {
	public final data: T;

	public function new(data: T) {
		super();
		this.data = data;
	}

	@:nullSafety(Off)
	override public function equals(other: BValue)
		return data == other.as(this.getClass()).data;

	override public function toString()
		return Std.string(data);
}
