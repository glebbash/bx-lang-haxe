package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.BlocksParser.bool;
import com.glebcorp.blocks.lang.syntax.Identifier;

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
