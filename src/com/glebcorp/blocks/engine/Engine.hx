package com.glebcorp.blocks.engine;

import haxe.extern.Rest;
import com.glebcorp.blocks.utils.Panic.panic;

using Type;
using com.glebcorp.blocks.utils.ClassName;
using com.glebcorp.blocks.utils.NullUtils;
using com.glebcorp.blocks.utils.ArrayLast;

typedef BMethod = (self: BValue, args: Rest<BValue>) -> BValue;

class Engine {
	public final types: Map<String, BType> = [];

	public function new() {}

	public function getType(name: String)
		return types[name];

	public function expectType(name: String)
		return types[name].or(panic('There is no $name type in this context'));
}

class BType {
	public final name: String;

	final parent: Null<String>;
	final methods: Map<String, Array<BMethod>> = [];
	final engine: Engine;

	public function new(engine: Engine, name: String, ?parent: String) {
		this.engine = engine;
		this.name = name;
		this.parent = parent;
	}

	public function addMethod(name: String, method: BMethod) {
		if (!methods.exists(name)) {
			methods[name] = [method];
		} else {
			methods[name].unsafe().push(method);
		}
		return this;
	}

	public function getMethod(name: String): Null<BMethod> {
		var methods = this.methods[name].or([]);
		var method = methods.last();

		if (method != null)
			return method;

		return parent != null ? engine.expectType(parent.unsafe()).getMethod(name) : null;
	}

	public function expectMethod(name: String)
		return getMethod(name).or(panic('Type ${this.name} has no \'$name\' method'));

	public function toString()
		return name;
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
