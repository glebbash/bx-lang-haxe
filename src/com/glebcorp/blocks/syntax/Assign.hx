package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.Lexer;

using Std;

interface AssignableExpr extends Expression {
	function isValid(): Bool;

	function isDefinable(): Bool;

	function define(ctx: Context, value: BValue, constant: Bool): Void;

	function assign(ctx: Context, value: BValue): Void;
}

class Assign extends PrecAction {
	override
	function parse(parser: ExprParser, token: Token, assignable: Expression): AssignExpr {
		if (!assignable.isOfType(AssignableExpr) || !cast(assignable, AssignableExpr).isValid()) {
			return parser.unexpectedToken(token);
		}
		// right associative
		final value = parser.parse(prec - 1);
		return new AssignExpr(cast(assignable, AssignableExpr), value);
	}
}

@:tink class AssignExpr implements Expression {
	final assignable: AssignableExpr = _;
	final value: Expression = _;

	function eval(ctx: Context) {
		final value = value.eval(ctx);
		assignable.assign(ctx, value);
		return value;
	}

	function toString(s = "", i = "") {
		return '${assignable.toString(s, i)} = ${value.toString(s, i)}';
	}
}
