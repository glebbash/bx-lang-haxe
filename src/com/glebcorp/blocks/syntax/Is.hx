package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.syntax.Identifier;
import com.glebcorp.blocks.BlockParser.bool;

@:tink class Is extends PrecAction {
	final ident: Identifier = _;

	override function parse(parser: ExprParser, token: Token, expr: Expression) {
		final type = ident.expect(parser).name;
		return new IsExpr(expr, type);
	}
}

@:tink class IsExpr implements Expression {
	final val: Expression = _;
	final type: String = _;

	function eval(ctx: Context) {
		return bool(val.eval(ctx).type == type);
	}

	function toString(s = "", i = "") {
		return '${val.toString(s, i)} is $type';
	}
}
