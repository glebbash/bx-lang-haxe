package com.glebcorp.blocks.engine;

import com.glebcorp.blocks.engine.Engine.BValue;
import com.glebcorp.blocks.utils.Panic.panic;

typedef Set<T> = Map<T, Bool>;

@:structInit
class Cell {
	public var value: BValue;
	public var constant: Bool;
}

class Scope {
	private final data = new Map<String, Cell>();
	private final parent: Null<Scope>;

	public var exports: Null<Set<String>>;

	public function new(?parent: Scope, ?exports: Set<String>) {
		this.parent = parent;
		this.exports = exports;
	}

	public function has(name: String): Bool {
		return data.exists(name);
	}

	public function getCell(name: String): Cell {
		var val = data[name];
		if (val == null) {
			if (this.parent == null) {
				panic('Error: $name is not defined.');
			}
			return parent.getCell(name);
		}
		return val;
	}

	public function get(name: String): BValue {
		return this.getCell(name).value;
	}

	public function define(name: String, value: BValue, constant = false) {
		if (has(name)) {
			panic('Error: $name is already defined.');
        }
        var cell: Cell = {
			value: value,
			constant: constant
		};
		data[name] = cell;
	}

	public function set(name: String, value: BValue) {
		getCell(name).value = value;
	}
}
