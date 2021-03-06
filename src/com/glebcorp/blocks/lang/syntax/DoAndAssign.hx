package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.syntax.Assign;
import com.glebcorp.blocks.lang.syntax.BinaryOp;

@:tink class DoAndAssign implements Action {
	final prec: Float = _;
	final fun: BinaryFun = _;

	function parse(parser: ExprParser, token: Token, assignable: Expression): DoAndAssignExpr {
		if (!Std.isOfType(assignable, AssignableExpr)) {
			return parser.unexpectedToken(token);
		}
		return new DoAndAssignExpr(cast assignable, parser.parse(prec), fun);
	}

	function precedence(_) {
		return prec;
	}
}

@:tink class DoAndAssignExpr implements Expression {
	final assignable: AssignableExpr = _;
	final value: Expression = _;
	final fun: BinaryFun = _;

	function eval(ctx: Context) {
		final value = value.eval(ctx);
		final prev = assignable.eval(ctx);
		final res = fun(prev, value);
		assignable.assign(ctx, res);
		return res;
	}

	function toString(s = "", i = ""): String {
		return '${assignable.toString(s, i)} = $value';
	}
}
