package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.Core;


typedef BinaryFun = (a: BValue, b: BValue) -> BValue;

class BinaryOp implements Action {
	public final prec: Float;
	public final fun: BinaryFun;
	public final rightAssoc: Bool;

	public function new(precedence: Float, fun: BinaryFun, rightAssoc = false) {
		this.prec = precedence;
		this.fun = fun;
		this.rightAssoc = rightAssoc;
	}

	public function parse(parser: ExprParser, token: Token, lhs: Expression): BinaryOpExpr {
        var rhs = parser.parse(prec - (rightAssoc ? 1 : 0));
        return switch (token.value) {
            case Text(str): new BinaryOpExpr(str, lhs, rhs, fun);
            default: parser.unexpectedToken(token);
        };
	}

	public function precedence(_)
		return prec;
}

class BinaryOpExpr implements Expression {
    public final oper: String;
    public final lhs: Expression;
    public final rhs: Expression;
    public final fun: BinaryFun;

    public function new(oper: String, lhs: Expression, rhs: Expression, fun: BinaryFun) {
        this.oper = oper;
        this.lhs = lhs;
        this.rhs = rhs;
        this.fun = fun;
    }

    public function eval(ctx: Context)
        return fun(lhs.eval(ctx), rhs.eval(ctx));

    public function toString(s: String = "", i: String = "")
        return '${lhs.toString(s, i)} ${oper} ${rhs.toString(s, i)}';
}
