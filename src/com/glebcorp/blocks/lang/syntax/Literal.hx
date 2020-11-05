package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Engine;
import com.glebcorp.blocks.lang.Prelude;

using com.glebcorp.blocks.utils.NullUtils;
using com.glebcorp.blocks.utils.Slice;

class Literal implements Atom {
	function new() {}

	function parse(parser: ExprParser, token: Token): LiteralExpr {
		return switch (token.value) {
			case Text(str):
				switch (token.type) {
					case Number: new LiteralExpr(new BNumber(Std.parseInt(str).unwrap()));
					case String: new LiteralExpr(new BString(str.slice(1, -1)));
					default: parser.unexpectedToken(token);
				}
			default: parser.unexpectedToken(token);
		};
	}
}

@:tink class ConstLiteral implements Atom {
	final value: BValue = _;

	function parse(parser: ExprParser, token: Token): LiteralExpr {
		return new LiteralExpr(value);
	}
}

@:tink class LiteralExpr implements Expression {
	final value: BValue = _;

	function eval(ctx: Context) {
		return value;
	}

	function toString(?_, ?_) {
		return value.toString();
	}
}
