package com.glebcorp.blocks.syntax;

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

class IdentExpr implements Expression {
	public final name: String;

	public function new(name: String)
		this.name = name;

	public function eval(ctx: Context)
		return ctx.scope.get(name);

	public function toString(?_, ?_)
		return name;
}
