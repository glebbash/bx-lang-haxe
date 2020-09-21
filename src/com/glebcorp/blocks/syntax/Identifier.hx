package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.syntax.Assign;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.engine.Scope.Set;
import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.Lexer.TokenValue;
import com.glebcorp.blocks.Core;

class Identifier implements Atom {
	public static final IDENT = new Identifier();

	function new() {}

	public function parse(parser: ExprParser, token: Token): IdentExpr {
		return switch (token.value) {
			case TokenValue.Text(val): new IdentExpr(val);
			default: parser.unexpectedToken(token);
		}
	}
}

class IdentExpr implements AssignableExpr implements Exportable {
	public final name: String;

	public function new(name: String)
		this.name = name;

	public function eval(ctx: Context)
		return ctx.scope.get(name);

	public function export(exports: Set<String>) {
		if (exports.exists(name)) {
			panic('Cannot re-export \'name\'');
		}
		exports[name] = true;
	}

	public function isDefinable()
		return true;

	public function isValid()
		return true;

	public function define(ctx: Context, value: BValue, constant: Bool) {
		ctx.scope.define(name, value, constant);
	}

	public function assign(ctx: Context, value: BValue) {
		ctx.scope.set(name, value);
	}

	public function toString(?_, ?_)
		return name;
}
