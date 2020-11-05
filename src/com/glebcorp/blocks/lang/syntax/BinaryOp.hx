package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Engine;

typedef BinaryFun = (a: BValue, b: BValue) -> BValue;

@:tink class BinaryOp implements Action {
	final symbol: String = _;
	final prec: Float = _;
	final fun: BinaryFun = _;
	final rightAssoc: Bool = @byDefault false;

	@:nullSafety(Off) function new() {}

	function parse(parser: ExprParser, token: Token, lhs: Expression): BinaryOpExpr {
		final rhs = parser.parse(prec - (rightAssoc ? 1 : 0));
		return new BinaryOpExpr(symbol, lhs, rhs, fun);
	}

	function precedence(_) {
		return prec;
	}
}

@:tink class BinaryOpExpr implements Expression {
	final symbol: String = _;
	final lhs: Expression = _;
	final rhs: Expression = _;
	final fun: BinaryFun = _;

	function eval(ctx: Context) {
		return fun(lhs.eval(ctx), rhs.eval(ctx));
	}

	function toString(s = "", i = "") {
		return '${lhs.toString(s, i)} $symbol ${rhs.toString(s, i)}';
	}
}
