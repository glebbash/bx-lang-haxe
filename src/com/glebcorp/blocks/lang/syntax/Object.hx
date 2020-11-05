package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Engine;
import com.glebcorp.blocks.lang.Prelude;
import com.glebcorp.blocks.lang.syntax.Assign;
import com.glebcorp.blocks.lang.syntax.Identifier;

using Std;
using com.glebcorp.blocks.utils.ArrayUtils;
using com.glebcorp.blocks.utils.NullUtils;

@:tink class KVPair {
	final name: String = _;
	final value: Null<Expression> = _;

	inline function getDef() {
		return value == null ? name : value.unsafe().toString();
	}
}

@:tink class Object implements Atom {
	final identifier: Identifier = _;

	function parse(parser: ExprParser, token: Token): ObjectExpr {
		return switch (token.value) {
			case Tokens(exprs):
				final pairs: Array<KVPair> = [];
				for (expr in exprs) {
					final subParser = parser.subParser(expr);
					while (subParser.tokens.peek() != null) {
						final name = identifier.expect(subParser).name;
						final value: Null<Expression> = if (subParser.nextIs({value: ":"})) {
							subParser.next();
							subParser.parse();
						} else {
							null;
						};
						pairs.push(new KVPair(name, value));
						if (subParser.tokens.peek() != null) {
							subParser.expect({value: ","});
						}
					}
				}
				return new ObjectExpr(pairs);
			default:
				parser.unexpectedToken(token);
		};
	}
}

@:tink class ObjectExpr implements AssignableExpr {
	final pairs: Array<KVPair> = _;

	function isValid() {
		return pairs.every(pair -> pair.value == null || pair.value.isOfType(IdentExpr));
	}

	function isDefinable() {
		return true;
	}

	function eval(ctx: Context) {
		final obj = new BObject();
		for (pair in pairs) {
			obj.set(pair.name, if (pair.value != null) {
				pair.value.unsafe().eval(ctx);
			} else {
				new IdentExpr(pair.name).eval(ctx);
			});
		}
		return obj;
	}

	function define(ctx: Context, value: BValue, constant: Bool) {
		if (value == BVoid.VALUE) {
			for (pair in pairs) {
				ctx.scope.define(pair.getDef(), BVoid.VALUE, constant);
			}
			return;
		}
		final obj = value.as(BObject);
		for (pair in pairs) {
			ctx.scope.define(pair.getDef(), obj.get(pair.name), constant);
		}
	}

	function assign(ctx: Context, value: BValue) {
		final obj = value.as(BObject);
		for (pair in pairs) {
			ctx.scope.set(pair.getDef(), obj.get(pair.name));
		}
	}

	function toString(s = "", i = "") {
		final bodyIndent = s + i;
		return i + "{" + pairs.map(pair -> {
			if (pair.value == null) {
				return pair.name;
			}
			return pair.name + ": " + pair.value.unsafe().toString(s, bodyIndent);
		}).join(",\n") + '\n$i}';
	}
}
