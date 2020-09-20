package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.syntax.Assign;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.syntax.BinaryOp;
import com.glebcorp.blocks.Core.Expression;

@:publicFields
class DoAndAssign implements Action {
	final prec: Float;
	final fun: BinaryFun;

	function new(prec: Float, fun: BinaryFun) {
		this.prec = prec;
		this.fun = fun;
	}

	function parse(parser: ExprParser, token: Token, assignable: Expression): DoAndAssignExpr {
		if (!Std.isOfType(assignable, AssignableExpr)) {
			return parser.unexpectedToken(token);
		}
		return new DoAndAssignExpr(cast assignable, parser.parse(prec), fun);
	}

	function precedence(_)
		return prec;
}

@:publicFields
class DoAndAssignExpr implements Expression {
	final assignable: AssignableExpr;
	final value: Expression;
	final fun: BinaryFun;

	function new(assignable: AssignableExpr, value: Expression, fun: BinaryFun) {
		this.assignable = assignable;
		this.value = value;
		this.fun = fun;
	}

	function eval(ctx: Context) {
		final value = value.eval(ctx);
		final prev = assignable.eval(ctx);
		final res = fun(prev, value);
		assignable.assign(ctx, res);
		return res;
	}

	function toString(symbol = "", indent = ""): String {
		return '${assignable.toString(symbol, indent)} = $value';
	}
}
