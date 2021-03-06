package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Engine;
import com.glebcorp.blocks.lang.Prelude;
import com.glebcorp.blocks.lang.syntax.ArrayAtom;

@:tink class Call extends PrecAction {
	final array: ArrayAtom = _;

	override function parse(parser: ExprParser, token: Token, expr: Expression): CallExpr {
		return new CallExpr(expr, array.parse(parser, token));
	}
}

@:tink interface CallableExpression extends Expression {
	final args: ArrayExpr;

	function call(ctx: Context, args: Array<BValue>): BValue;

	function eval(ctx: Context): BValue {
		return call(ctx, args.items.map(arg -> arg.eval(ctx)));
	}
}

@:tink class CallExpr implements CallableExpression {
	final fun: Expression = _;
	final args: ArrayExpr = _;

	function call(ctx: Context, args: Array<BValue>) {
		final fun = fun.eval(ctx).as(BFunction);
		final value = fun.call(args);
		return value;
	}

	function toString(s = "", i = "") {
		return '$fun(${args.toString(s, i)})';
	}
}
