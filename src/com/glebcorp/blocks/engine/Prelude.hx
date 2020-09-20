package com.glebcorp.blocks.engine;

import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.utils.Panic.panic;

using com.glebcorp.blocks.utils.NullUtils;

//////////////////////////////////

interface BIterable<T> {
	function iterator(): Iterator<T>;
}

interface BIterator<T> {
	function hasNext(): Bool;

	function next(): T;
}

//////////////////////////////////

class BBoolean extends BWrapper<Bool> {
	public static final TRUE = new BBoolean(true);
	public static final FALSE = new BBoolean(false);
}

class BNumber extends BWrapper<Float> {}

//////////////////////////////////

class BString extends BWrapper<String> implements BIterable<BString> {
	public function iterator()
		return new BStringIterator(data);
}

@:publicFields
class BStringIterator implements BIterator<BString> {
	var index = 0;
	final str: String;

	function new(str: String)
		this.str = str;

	function hasNext()
		return index < str.length;

	function next()
		return new BString(str.charAt(index++));
}

//////////////////////////////////

class BArray extends BWrapper<Array<BValue>> implements BIterable<BValue> {
	public function iterator()
		return data.iterator();

	override public function toString()
		return '[${data.join(", ")}]';
}

//////////////////////////////////

@:publicFields
class BObject extends BWrapper<Map<String, BValue>> {
	function get(prop: String): BValue
		return data[prop].or(panic('Prop $prop is not defined'));

	function set(prop: String, val: BValue)
		data[prop] = val;

	function iterator()
		return new BObjectIterator(data.keyValueIterator());

	override function toString() {
		return '{' + [for (k => v in data.keyValueIterator()) '$k: $v'].join(", ") + '}';
	}
}

@:publicFields
class BObjectIterator implements BIterator<BArray> {
	final kvIterator: KeyValueIterator<String, BValue>;

	public function new(kvIterator: KeyValueIterator<String, BValue>)
		this.kvIterator = kvIterator;

	public function hasNext()
		return kvIterator.hasNext();

	public function next() {
		final pair = kvIterator.next();
		return new BArray([new BString(pair.key), pair.value]);
	}
}

//////////////////////////////////

class BRange extends BValue implements BIterable<BNumber> {
	final start: Int;
	final stop: Int;

	public function new(start: Int, stop: Int) {
		super();
		this.start = start;
		this.stop = stop;
	}

	public function iterator()
		return new BRangeIterator(start, stop);

	override public function toString()
		return '$start..$stop';
}

class BRangeIterator extends BValue implements BIterator<BNumber> {
	final start: Int;
	final stop: Int;
	var index = 0;

	public function new(start: Int, stop: Int) {
		super();
		this.start = start;
		this.stop = stop;
	}

	public function hasNext()
		return index < stop;

	public function next()
		return new BNumber(index++);
}

//////////////////////////////////

typedef BFunctionBody = (args: Array<BValue>) -> BValue;

@:publicFields
class BFunction extends BWrapper<BFunctionBody> {
	function call(args: Array<BValue>): BValue
		return this.data(args);

	override function toString()
		return "function";
}

//////////////////////////////////

class BBreak extends BWrapper<Int> {}
class BContinue extends BWrapper<Int> {}
class BReturn extends BWrapper<BValue> {}

//////////////////////////////////

class BVoid extends BValue {
	public static final VOID = new BVoid();

	override public function toString()
		return "void";
}

//////////////////////////////////

interface ExecState {
	function resume(?value: BValue): BValue;
}

@:publicFields
@:structInit
class PausedExec {
	final execStack: Array<ExecState>;
	final returned: BValue;
	final async: Bool;
}

class BPausedExec extends BWrapper<PausedExec> {
	override public function toString()
		return "pausedExec(" + data.returned + ")";
}

//////////////////////////////////
