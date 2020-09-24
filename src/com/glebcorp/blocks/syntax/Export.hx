package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Prelude.BVoid.VOID;
import com.glebcorp.blocks.utils.Panic.panic;

using Std;
using com.glebcorp.blocks.utils.NullUtils;

interface ExportableExpr extends Expression {
	function export(exports: Set<String>): Void;
}

class Export implements Atom {
	function new() {}

	function parse(parser: ExprParser, token: Token): ExportExpr {
		final token = parser.next(false);
		final expr = parser.parse();
		if (!expr.isOfType(ExportableExpr)) {
			parser.unexpectedToken(token);
		}
		return new ExportExpr(cast(expr, ExportableExpr));
	}
}

@:tink class ExportExpr implements Expression {
	final expr: ExportableExpr = _;

	function eval(ctx: Context) {
		if (ctx.scope.exports == null) {
			panic('Cannot export values from here');
		}
		expr.eval(ctx);
		expr.export(ctx.scope.exports.unsafe());
		return VOID;
	}

	function toString(s = "", i = "") {
		return 'export ${expr.toString(s, i)}';
	}
}
