package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core.Context;
import com.glebcorp.blocks.Core.ExprParser;
import com.glebcorp.blocks.Core.Expression;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.engine.Engine.BValue;
import com.glebcorp.blocks.engine.Prelude;

using com.glebcorp.blocks.utils.NullUtils;
using com.glebcorp.blocks.utils.Slice;

class Literal implements Atom {
	static final PARSER = new Literal();

	private function new() {}

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
