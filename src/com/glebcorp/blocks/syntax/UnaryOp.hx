package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.Core;

typedef UnaryFun = (x: BValue) -> BValue;

@:tink class UnaryOp implements Atom {
	final symbol: String = _;
	final fun: UnaryFun = _;

	function parse(parser: ExprParser, token: Token): UnaryOpExpr
		return new UnaryOpExpr(symbol, parser.parse(), fun);
}

@:tink class UnaryOpExpr implements Expression {
	final symbol: String = _;
	final expr: Expression = _;
	final fun: UnaryFun = _;

	function eval(ctx: Context) {
		return fun(expr.eval(ctx));
	}

	function toString(s = "", i = "") {
		return symbol + expr.toString(s, i);
	}
}
