package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.syntax.Identifier;
import com.glebcorp.blocks.syntax.Assign.AssignableExpr;
import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.engine.Prelude.BVoid.VOID;

using Std;
using com.glebcorp.blocks.utils.ArrayUtils;
using com.glebcorp.blocks.utils.NullUtils;

@:publicFields
@:structInit
class KVPair {
	final name: String;
	final value: Null<Expression>;

	inline function getDef() {
		return value == null ? name : value.unsafe().toString();
	}
}

@:publicFields
class Object implements Atom {
	static final OBJECT = new Object();

	function new() {}

	function parse(parser: ExprParser, token: Token): ObjectExpr {
		return switch (token.value) {
			case Tokens(exprs):
				final pairs: Array<KVPair> = [];
				for (expr in exprs) {
					final subParser = parser.subParser(expr);
					while (subParser.nextToken(false) != null) {
						final name = Identifier.expect(subParser).name;
						final value: Null<Expression> = if (subParser.nextIs({value: ":"})) {
							subParser.next();
							subParser.parse();
						} else {
							null;
						};
						pairs.push({name: name, value: value});
						if (subParser.nextToken(false) != null) {
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

@:publicFields
class ObjectExpr implements AssignableExpr {
	final pairs: Array<KVPair>;

	function new(pairs: Array<KVPair>) {
		this.pairs = pairs;
	}

	function isValid() {
		return pairs.every(pair -> pair.value == null || pair.value.isOfType(IdentExpr));
	}

	function isDefinable() {
		return true;
	}

	function eval(ctx: Context) {
		final data: Map<String, BValue> = [];
		for (pair in pairs) {
			data[pair.name] = if (pair.value != null) {
				pair.value.unsafe().eval(ctx);
			} else {
				new IdentExpr(pair.name).eval(ctx);
			}
		}
		return new BObject(data);
	}

	function define(ctx: Context, value: BValue, constant: Bool) {
		if (value == VOID) {
			for (pair in pairs) {
				ctx.scope.define(pair.getDef(), VOID, constant);
			}
			return;
		}
		final obj = value.as(BObject).data;
		for (pair in pairs) {
			ctx.scope.define(pair.getDef(), obj[pair.name], constant);
		}
	}

	function assign(ctx: Context, value: BValue) {
		final obj = value.as(BObject).data;
		for (pair in pairs) {
			ctx.scope.set(pair.getDef(), obj[pair.name]);
		}
	}

	function toString(symbol = "", indent = "") {
		final bodyIndent = symbol + indent;
		return indent + "{" + pairs.map(pair -> {
			if (pair.value == null) {
				return pair.name;
			}
			return pair.name + ": " + pair.value.unsafe().toString(symbol, bodyIndent);
		}).join(",\n") + '\n$indent}';
	}
}
