package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude.BArray;
import com.glebcorp.blocks.engine.Prelude.BVoid.VOID;
import com.glebcorp.blocks.syntax.Assign.AssignableExpr;
import com.glebcorp.blocks.syntax.Identifier;
import com.glebcorp.blocks.utils.Panic.panic;

using com.glebcorp.blocks.utils.ArrayUtils;

class ArrayAtom implements Atom {
	static final PARSER = new ArrayAtom();

	private function new() {}

	function parse(parser: ExprParser, token: Token): ArrayExpr {
		return switch (token.value) {
			case Tokens(exprs):
				final items: Array<Expression> = [];
				for (expr in exprs) {
					final subParser = parser.subParser(expr);
					while (subParser.nextToken(false) != null) {
						items.push(subParser.parse());
						if (subParser.nextToken(false) != null) {
							subParser.expect({value: ","});
						}
					}
				}
				return new ArrayExpr(items);
			default: parser.unexpectedToken(token);
		}
	}
}

@:tink class ArrayExpr implements AssignableExpr {
	final items: Array<Expression> = _;

	function isValid() {
		return items.every(item -> Std.isOfType(item, IdentExpr));
	}

	function isDefinable() {
		return true;
	}

	function define(ctx: Context, value: BValue, constant: Bool) {
		if (value == VOID) {
			for (ident in items) {
				ctx.scope.define(cast(ident, IdentExpr).name, VOID, constant);
			}
			return;
		}
		final arr = value.as(BArray).data;
		if (items.length > arr.length) {
			panic('Trying to assign ${arr.length} element(s) to ${items.length} name(s)');
		}
		for (i in 0...items.length) {
			final name = cast(items[i], IdentExpr).name;
			final val = arr[i];
			ctx.scope.define(name, val, constant);
		}
	}

	function assign(ctx: Context, value: BValue) {
		final arr = value.as(BArray).data;
		if (items.length > arr.length) {
			panic('Trying to assign ${arr.length} element(s) to ${items.length} name(s)');
		}
		for (i in 0...items.length) {
			final name = cast(items[i], IdentExpr).name;
			final val = arr[i];
			ctx.scope.set(name, val);
		}
	}

	function eval(ctx: Context) {
		return new BArray(items.map(item -> item.eval(ctx)));
	}

	function toString(symbol = "", indent = "") {
		return indent + "[" + items.map(item -> item.toString(symbol, indent)).join(", ") + "]";
	}
}
