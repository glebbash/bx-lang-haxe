package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Prelude;

using com.glebcorp.blocks.utils.NullUtils;

class Continue implements Atom {
	function new() {}

	function parse(parser: ExprParser, token: Token): ContinueExpr {
		if (parser.nextIs({type: TokenType.Number})) {
			final token = parser.next();
			return switch (token.value) {
				case Text(str):
					final times = Std.parseInt(str).unwrap();
					if (times < 2) {
						parser.unexpectedToken(token);
					}
					return new ContinueExpr(times);
				default:
					parser.unexpectedToken(token);
			}
		}
		return new ContinueExpr(1);
	}
}

@:tink class ContinueExpr implements Expression {
	final times: Int = _;

	function eval(ctx: Context) {
		return new BContinue(times);
	}

	function toString(s = "", i = "") {
		return 'continue $times';
	}
}
