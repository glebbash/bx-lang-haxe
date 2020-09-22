package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.syntax.ArrayAtom;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.Core;

class Call extends PrecAction {
	override function parse(parser: ExprParser, token: Token, expr: Expression): CallExpr {
		return new CallExpr(expr, ArrayAtom.PARSER.parse(parser, token));
	}
}

@:tink class CallExpr implements Expression {
	final fun: Expression = _;
	final args: ArrayExpr = _;

	function eval(ctx: Context) {
		final fun = fun.eval(ctx).as(BFunction);
		final args = args.items.map(arg -> arg.eval(ctx));
		final value = fun.call(args);
		return value;
	}

	function toString(s = "", i = "") {
		return '$fun(${args.toString(s, i)})';
	}
}
