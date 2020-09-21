package com.glebcorp.blocks.engine;

import com.glebcorp.blocks.engine.Engine.BValue;
import com.glebcorp.blocks.utils.Panic.panic;

typedef Set<T> = Map<T, Bool>;

@:publicFields
@:tink class Cell {
	var value: BValue = _;
	final constant: Bool = _;
}

@:publicFields
@:tink class Scope {
	private final data = new Map<String, Cell>();

	private final parent: Null<Scope> = @byDefault null;
	var exports: Null<Set<String>> = @byDefault null;

	@:nullSafety(Off) function new() {}

	function has(name: String): Bool {
		return data.exists(name);
	}

	function getCell(name: String): Cell {
		var val = data[name];
		if (val == null) {
			if (parent == null) {
				return panic('Error: $name is not defined.');
			}
			return parent.getCell(name);
		}
		return val;
	}

	function get(name: String): BValue {
		return getCell(name).value;
	}

	function define(name: String, value: BValue, constant = false) {
		if (has(name)) {
			panic('Error: $name is already defined.');
		}
		data[name] = new Cell(value, constant);
	}

	function set(name: String, value: BValue) {
		getCell(name).value = value;
	}
}
