package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Engine;
import com.glebcorp.blocks.lang.Scope;
import com.glebcorp.blocks.lang.syntax.Assign;
import com.glebcorp.blocks.lang.syntax.Export;
import com.glebcorp.blocks.utils.Panic.panic;

class Identifier implements Atom {
	function expect(parser: ExprParser, includeSpecial = false) {
		if (includeSpecial) {
			return parse(parser, parser.expect({type: TokenType.Identifier}));
		}
		return parse(parser, parser.expect({complexType: "<IDENT>"}));
	}

	function new() {}

	function parse(parser: ExprParser, token: Token): IdentExpr {
		return switch (token.value) {
			case TokenValue.Text(val): new IdentExpr(val);
			default: parser.unexpectedToken(token);
		}
	}
}

@:tink class IdentExpr implements AssignableExpr implements ExportableExpr {
	final name: String = _;

	function eval(ctx: Context) {
		return ctx.scope.get(name);
	}

	function export(exports: Set<String>) {
		if (exports.exists(name)) {
			panic('Cannot re-export \'name\'');
		}
		exports[name] = true;
	}

	function isDefinable() {
		return true;
	}

	function isValid() {
		return true;
	}

	function define(ctx: Context, value: BValue, constant: Bool) {
		ctx.scope.define(name, value, constant);
	}

	function assign(ctx: Context, value: BValue) {
		ctx.scope.set(name, value);
	}

	function toString(?_, ?_) {
		return name;
	}
}
