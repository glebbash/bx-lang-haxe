package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;

@:publicFields
class Break implements Atom {
	static final BREAK = new Break();

	function new() {}

	function parse(parser: ExprParser, token: Token): BreakExpr {
		if (parser.nextIs({type: TokenType.Number})) {
			final token = parser.next();
			return switch (token.value) {
				case Text(str):
					final times = Std.parseInt(str);
					if (times < 2) {
						parser.unexpectedToken(token);
					}
					return new BreakExpr(times);
				default:
					parser.unexpectedToken(token);
			}
		}
		return new BreakExpr(1);
	}
}

@:publicFields
@:tink class BreakExpr implements Expression {
	final times: Int = _;

	function eval(ctx: Context) {
		return new BBreak(times);
	}

	function toString(s = "", i = "") {
		return 'break $times';
	}
}
