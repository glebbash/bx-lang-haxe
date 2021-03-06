package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Prelude;
import com.glebcorp.blocks.lang.Engine;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.syntax.Assign;
import com.glebcorp.blocks.utils.Panic.panic;

using Std;
using com.glebcorp.blocks.utils.NullUtils;

@:tink class DefineVar implements Atom {
	final constant: Bool = _;

	function parse(parser: ExprParser, token: Token): Expression {
		final expr = parser.parse();
		if (!expr.isOfType(AssignExpr) || !cast(expr, AssignExpr).assignable.isDefinable()) {
			panic("This expression is not definable");
		}
		return new DefineExpr(cast(expr, AssignExpr), constant);
	}
}

@:tink class DefineExpr implements Expression {
	final expr: AssignExpr = _;
	final constant: Bool = _;

	function eval(ctx: Context) {
		final value = expr.value.eval(ctx);
		return resume(ctx, value);
	}

	function resume(ctx: Context, value: BValue) {
		if (value.is(BPausedExec)) {
			value.as(BPausedExec).data.execStack.unshift(new DefineExecState(ctx, this));
			return value;
		}
		expr.assignable.define(ctx, value, constant);
		return BVoid.VALUE;
	}

	function toString(s = "", i = "") {
		return (constant ? "const " : "let ") + expr.toString(s, i);
	}
}

@:tink class DefineExecState implements ExecState {
	final ctx: Context = _;
	final defineExpr: DefineExpr = _;

	function resume(?value: BValue): BValue {
		return defineExpr.resume(ctx, value.unwrap());
	}
}