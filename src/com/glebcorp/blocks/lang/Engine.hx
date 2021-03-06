package com.glebcorp.blocks.lang;

import com.glebcorp.blocks.lang.Prelude;
import com.glebcorp.blocks.utils.Panic.panic;

using com.glebcorp.blocks.utils.ArrayUtils;
using com.glebcorp.blocks.utils.ClassName;
using com.glebcorp.blocks.utils.NullUtils;

interface BMap {
	function set(key: String, val: BValue): BMap;

	function get(key: String): BValue;
}

class Engine {
	final types: Map<String, BType> = [];

	function new() {}

	function addType(name: String, ?parent: String) {
		final type = new BType(this, name, parent);
		types[name] = type;
		return type;
	}

	function getType(name: String) {
		return types[name];
	}

	function expectType(name: String): BType {
		return getType(name).or(() -> panic('There is no $name type in this context'));
	}
}

@:tink class BType extends BValue implements BMap {
	private final engine: Engine = _;
	final name: String = _;
	final parent: Null<String> = _;
	private final methods: Map<String, Array<BFunction>> = [];

	inline function extend(subType: String): BType {
		return engine.addType(subType, name);
	}

	function set(_: String, _: BValue) {
		panic('Cannot redefine class methods');
		return this;
	}

	function get(key: String) {
		return expectMethod(key);
	}

	function addMethod(name: String, method: BFunction) {
		if (!methods.exists(name)) {
			methods[name] = [method];
		} else {
			methods[name].unsafe().push(method);
		}
		return this;
	}

	function getMethod(name: String): Null<BFunction> {
		final method = methods[name].or(() -> []).last();

		if (method != null) {
			return method;
		}

		return parent != null ? engine.expectType(parent.unsafe()).getMethod(name) : null;
	}

	function expectMethod(method: String) {
		return getMethod(method).or(() -> panic('Type $name has no \'$method\' method'));
	}

	override function toString() {
		return name;
	}
}

class BValue {
	final type: String;

	@:nullSafety(Off)
	function new() {
		type = Type.getClass(this).getName();
	}

	function invoke(engine: Engine, methodName: String, args: Array<BValue>): BValue {
		final method = engine.expectType(type).expectMethod(methodName);
		args.insert(0, this);
		return method.call(args);
	}

	@:nullSafety(Off)
	function is<T: BValue>(c: Class<T>): Bool {
		return Type.getClass(this) == cast(c);
	}

	function as<T: BValue>(c: Class<T>): T {
		return is(c) ? cast(this) : panic('Cannot cast $type to ${c.getName()}');
	}

	function equals(other: BValue): Bool {
		return this == other;
	}

	function toString(): String {
		throw "Abstract method";
	}
}

@:tink class BWrapper<T> extends BValue {
	final data: T = _;

	@:nullSafety(Off)
	override function equals(other: BValue) {
		return data == other.as(Type.getClass(this)).data;
	}

	override function toString() {
		return Std.string(data);
	}
}
