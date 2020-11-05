package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Prelude;

using com.glebcorp.blocks.utils.NullUtils;

class Break implements Atom {
	function new() {}

	function parse(parser: ExprParser, token: Token): BreakExpr {
		if (parser.nextIs({type: TokenType.Number})) {
			final token = parser.next();
			return switch (token.value) {
				case Text(str):
					final times = Std.parseInt(str).unwrap();
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

@:tink class BreakExpr implements Expression {
	final times: Int = _;

	function eval(ctx: Context) {
		return new BBreak(times);
	}

	function toString(s = "", i = "") {
		return 'break $times';
	}
}
