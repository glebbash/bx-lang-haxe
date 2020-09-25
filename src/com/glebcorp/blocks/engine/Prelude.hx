package com.glebcorp.blocks.engine;

import com.glebcorp.blocks.Core;
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
	static final TRUE = new BBoolean(true);
	static final FALSE = new BBoolean(false);
}

//////////////////////////////////

class BNumber extends BWrapper<Float> {}

//////////////////////////////////

class BString extends BWrapper<String> implements BIterable<BString> {
	function iterator() {
		return new BStringIterator(data);
	}
}

@:tink class BStringIterator implements BIterator<BString> {
	var index = 0;
	final str: String = _;

	function hasNext() {
		return index < str.length;
	}

	function next() {
		return new BString(str.charAt(index++));
	}
}

//////////////////////////////////

class BArray extends BWrapper<Array<BValue>> implements BIterable<BValue> {
	function iterator() {
		return data.iterator();
	}

	override function toString() {
		return '[${data.join(", ")}]';
	}
}

//////////////////////////////////

class BObject extends BValue {
	private final data: Map<String, BValue> = [];
	private final _keys: Array<String> = [];

	function new() {
		super();
	}

	function get(prop: String): BValue {
		return data[prop].or(panic('Prop $prop is not defined'));
	}

	function set(prop: String, val: BValue) {
		if (!data.exists(prop)) {
			_keys.push(prop);
		}
		data[prop] = val;
		return this;
	}

	function keys() {
		return _keys;
	}

	function keyValueIterator(): KeyValueIterator<String, BValue> {
		return new KVIterator(data, _keys);
	}

	function iterator() {
		return new BObjectIterator(keyValueIterator());
	}

	override function toString() {
		return '{' + [for (k => v in this) '$k: $v'].join(", ") + '}';
	}
}

@:tink class KVIterator<T> {
	final data: Map<String, T> = _;
	final keys: Array<String> = _;
	var index = 0;

	function hasNext() {
		return index < keys.length;
	}

	function next() {
		final key = keys[index++];
		return {key: key, value: data[key].unwrap()};
	}
}

@:tink class BObjectIterator implements BIterator<BArray> {
	final kvIterator: KeyValueIterator<String, BValue> = _;

	function hasNext() {
		return kvIterator.hasNext();
	}

	function next() {
		final pair = kvIterator.next();
		return new BArray([new BString(pair.key), pair.value]);
	}
}

//////////////////////////////////

@:tink class BRange extends BValue implements BIterable<BNumber> {
	final start: Int = _;
	final stop: Int = _;

	function iterator() {
		return new BRangeIterator(start, stop);
	}

	override function toString() {
		return '$start..$stop';
	}
}

@:tink class BRangeIterator extends BValue implements BIterator<BNumber> {
	final start: Int = _;
	final stop: Int = _;
	var index = 0;

	function hasNext() {
		return index < stop;
	}

	function next() {
		return new BNumber(index++);
	}
}

//////////////////////////////////

typedef BFunctionBody = (args: Array<BValue>) -> BValue;

class BFunction extends BWrapper<BFunctionBody> {
	static inline function f1(fun: BValue->BValue): BFunction {
		return new BFunction(args -> switch args {
			case [x]: fun(x);
			case _: panic("Expected 1 argument");
		});
	}

	static inline function f2(fun: (BValue, BValue) -> BValue): BFunction {
		return new BFunction(args -> switch args {
			case [a, b]: fun(a, b);
			case _: panic("Expected 2 arguments");
		});
	}

	static inline function f3(fun: (BValue, BValue, BValue) -> BValue): BFunction {
		return new BFunction(args -> switch args {
			case [a, b, c]: fun(a, b, c);
			case _: panic("Expected 3 arguments");
		});
	}

	function call(args: Array<BValue>): BValue {
		return data(args);
	}

	override function toString() {
		return "function";
	}
}

//////////////////////////////////

@:tink class BWrapperMut<T> extends BValue {
	var data: T = _;

	@:nullSafety(Off)
	override function equals(other: BValue) {
		return data == other.as(Type.getClass(this)).data;
	}

	override function toString() {
		return Std.string(data);
	}
}

class BBreak extends BWrapperMut<Int> {}
class BContinue extends BWrapperMut<Int> {}
class BReturn extends BWrapperMut<BValue> {}

//////////////////////////////////

class BVoid extends BValue {
	static final VALUE = new BVoid();

	override function toString() {
		return "void";
	}
}

//////////////////////////////////

interface ExecState {
	function resume(?value: BValue): BValue;
}

@:tink class PausedExec {
	final execStack: Array<ExecState> = _;
	var returned: BValue = _;
	final async: Bool = _;
}

class BPausedExec extends BWrapper<PausedExec> {
	override function toString() {
		return 'pausedExec(${data.returned})';
	}
}

//////////////////////////////////

@:tink class BGenerator extends BValue implements BIterable<BValue> implements BIterator<BValue> {
	var pausedExec = new PausedExec([], BVoid.VALUE, false);
	var ended = false;
	final ctx: Context = _;
	final body: Expression = _;

	function next() {
		return nextValue();
	}

	function nextValue(?val: BValue): BValue {
		if (ended) {
			return pausedExec.returned;
		}

		// first run
		if (pausedExec.execStack.length == 0) {
			final res = body.eval(ctx);
			if (res.is(BPausedExec)) {
				pauseOn(res.as(BPausedExec));
			} else {
				endOn(res);
			}
			return pausedExec.returned;
		}

		var res = val;
		while (true) {
			res = pausedExec.execStack.pop().unsafe().resume(res);
			if (res.is(BPausedExec)) {
				pauseOn(res.unsafe().as(BPausedExec));
				break;
			}
			if (pausedExec.execStack.length == 0) {
				endOn(res);
				break;
			}
		}
		return pausedExec.returned;
	}

	function hasNext() {
		return !ended;
	}

	function pauseOn(pe: BPausedExec) {
		if (pe.data.async) {
			panic("await outside of async");
		}
		pausedExec.returned = pe.data.returned;
		for (val in pe.data.execStack) {
			pausedExec.execStack.push(val);
		}
	}

	function endOn(val: BValue) {
		ended = true;
		final returned = val.is(BReturn) ? val.as(BReturn).data : val;
		pausedExec = new PausedExec([], returned, false);
	}

	function iterator(): BIterator<BValue> {
		return this;
	}

	override function toString() {
		return "generator";
	}
}

@:tink class BAsyncFunction extends BValue {
	var pausedExec = new PausedExec([], BVoid.VALUE, true);
	var ended = false;
	final ctx: Context = _;
	final body: Expression = _;

	function call(cb: BFunction, ?val: BValue): BValue {
		final ret = nextValue(val);
		if (ended) {
			return cb.call([ret]);
		}
		return ret.as(BFunction).call([BFunction.f1(val -> call(cb, val))]);
	}

	function nextValue(?val: BValue): BValue {
		if (ended) {
			return pausedExec.returned;
		}

		// first run
		if (pausedExec.execStack.length == 0) {
			final res = body.eval(ctx);
			if (res.is(BPausedExec)) {
				pauseOn(res.as(BPausedExec));
			} else {
				endOn(res);
			}
			return pausedExec.returned;
		}

		var res = val;
		while (true) {
			res = pausedExec.execStack.pop().unsafe().resume(res);
			if (res.is(BPausedExec)) {
				pauseOn(res.unsafe().as(BPausedExec));
				break;
			}
			if (pausedExec.execStack.length == 0) {
				endOn(res);
				break;
			}
		}
		return pausedExec.returned;
	}

	function pauseOn(pe: BPausedExec) {
		if (!pe.data.async) {
			panic("yield outside of generator");
		}
		pausedExec.returned = pe.data.returned;
		for (val in pe.data.execStack) {
			pausedExec.execStack.push(val);
		}
	}

	function endOn(val: BValue) {
		ended = true;
		final returned = val.is(BReturn) ? val.as(BReturn).data : val;
		pausedExec = new PausedExec([], returned, true);
	}

	override function toString() {
		return "asyncFunction";
	}
}
