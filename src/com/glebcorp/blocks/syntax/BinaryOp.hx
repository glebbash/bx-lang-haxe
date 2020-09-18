package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.Core;


typedef BinaryFun = (a: BValue, b: BValue) -> BValue;

class BinaryOp implements Action {
    public final symbol: String;
	public final prec: Float;
	public final fun: BinaryFun;
	public final rightAssoc: Bool;

	public function new(symbol: String, precedence: Float, fun: BinaryFun, rightAssoc = false) {
        this.symbol = symbol;
        this.prec = precedence;
		this.fun = fun;
		this.rightAssoc = rightAssoc;
	}

	public function parse(parser: ExprParser, token: Token, lhs: Expression): BinaryOpExpr {
        var rhs = parser.parse(prec - (rightAssoc ? 1 : 0));
        return new BinaryOpExpr(symbol, lhs, rhs, fun);
	}

	public function precedence(_)
		return prec;
}

class BinaryOpExpr implements Expression {
    public final symbol: String;
    public final lhs: Expression;
    public final rhs: Expression;
    public final fun: BinaryFun;

    public function new(symbol: String, lhs: Expression, rhs: Expression, fun: BinaryFun) {
        this.symbol = symbol;
        this.lhs = lhs;
        this.rhs = rhs;
        this.fun = fun;
    }

    public function eval(ctx: Context)
        return fun(lhs.eval(ctx), rhs.eval(ctx));

    public function toString(s: String = "", i: String = "")
        return '${lhs.toString(s, i)} ${symbol} ${rhs.toString(s, i)}';
}
