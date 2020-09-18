package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.Core;

typedef UnaryFun = (x: BValue) -> BValue;

class UnaryOp implements Atom {
	public final symbol: String;
	public final fun: UnaryFun;

	public function new(symbol: String, fun: UnaryFun) {
		this.symbol = symbol;
		this.fun = fun;
	}

	public function parse(parser: ExprParser, token: Token): UnaryOpExpr
		return new UnaryOpExpr(symbol, parser.parse(), fun);
}

class UnaryOpExpr implements Expression {
	public final oper: String;
	public final expr: Expression;
	public final fun: UnaryFun;

	public function new(oper: String, expr: Expression, fun: UnaryFun) {
		this.oper = oper;
		this.expr = expr;
		this.fun = fun;
	}

	public function eval(ctx: Context)
		return fun(expr.eval(ctx));

	public function toString(s: String = "", i: String = "")
		return oper + expr.toString(s, i);
}
