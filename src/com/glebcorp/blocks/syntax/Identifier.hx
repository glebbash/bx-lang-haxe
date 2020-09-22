package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.syntax.Assign;
import com.glebcorp.blocks.syntax.Export;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;

class Identifier implements Atom {
	static final PARSER = new Identifier();

	static function expect(parser: ExprParser, includeSpecial = false) {
		if (includeSpecial) {
			return PARSER.parse(parser, parser.expect({type: TokenType.Identifier}));
		}
		return PARSER.parse(parser, parser.expect({complexType: "<IDENT>"}));
	}

	private function new() {}

	function parse(parser: ExprParser, token: Token): IdentExpr {
		return switch (token.value) {
			case TokenValue.Text(val): new IdentExpr(val);
			default: parser.unexpectedToken(token);
		}
	}
}

@:tink class IdentExpr implements AssignableExpr implements Exportable {
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
