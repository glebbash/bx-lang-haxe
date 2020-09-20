package com.glebcorp.blocks.engine;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude.BVoid.VOID;
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

//////////////////////////////////

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
	public static inline function f1(fun: BValue->BValue): BFunction {
		return new BFunction(args -> switch args {
			case [x]: fun(x);
			case _: panic("Expected 1 argument");
		});
	}

	public static inline function f2(fun: (BValue, BValue) -> BValue): BFunction {
		return new BFunction(args -> switch args {
			case [a, b]: fun(a, b);
			case _: panic("Expected 2 arguments");
		});
	}

	public static inline function f3(fun: (BValue, BValue, BValue) -> BValue): BFunction {
		return new BFunction(args -> switch args {
			case [a, b, c]: fun(a, b, c);
			case _: panic("Expected 3 arguments");
		});
	}

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
	var returned: BValue;
	final async: Bool;
}

class BPausedExec extends BWrapper<PausedExec> {
	override public function toString()
		return "pausedExec(" + data.returned + ")";
}

//////////////////////////////////

@:publicFields
class BGenerator extends BValue implements BIterable<BValue> implements BIterator<BValue> {
	var pausedExec: PausedExec = {
		execStack: [],
		returned: VOID,
		async: false,
	};
	var ended = false;
	final ctx: Context;
	final body: Expression;

	function new(ctx: Context, body: Expression) {
		super();
		this.ctx = ctx;
		this.body = body;
	}

	function next()
		return nextValue();

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
		pausedExec = {
			execStack: [],
			returned: val.is(BReturn) ? val.as(BReturn).data : val,
			async: false,
		};
	}

	function iterator(): BIterator<BValue> {
		return this;
	}

	override function toString()
		return "generator";
}

@:publicFields
class BAsyncFunction extends BValue {
	var pausedExec: PausedExec = {
		execStack: [],
		returned: VOID,
		async: true,
	};
	var ended = false;
	final ctx: Context;
	final body: Expression;

	function new(ctx: Context, body: Expression) {
		super();
		this.ctx = ctx;
		this.body = body;
	}

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
		pausedExec = {
			execStack: [],
			returned: val.is(BReturn) ? val.as(BReturn).data : val,
			async: true,
		};
	}

	override function toString()
		return "asyncFunction";
}