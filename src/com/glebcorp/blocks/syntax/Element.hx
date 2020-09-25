package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.syntax.Assign;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;

class Element extends PrecAction {
	override function parse(parser: ExprParser, token: Token, expr: Expression): ElementExpr {
		return switch (token.value) {
			case Tokens(exprs):
				final subParser = parser.subParser(exprs[0]);
				return new ElementExpr(expr, subParser.parseToEnd());
			default: parser.unexpectedToken(token);
		}
	}
}

@:tink class ElementExpr implements AssignableExpr {
	final arr: Expression = _;
	final index: Expression = _;

	function eval(ctx: Context) {
		final arr = arr.eval(ctx).as(BArray).data;
		final index = Math.round(index.eval(ctx).as(BNumber).data);
		if (index < 0 || index > arr.length) {
			panic('Index out of bounds: $index, array length is ${arr.length}');
		}
		final value = arr[index];
		return value;
	}

	function assign(ctx: Context, value: BValue) {
		final arr = arr.eval(ctx).as(BArray).data;
		final index = Math.round(index.eval(ctx).as(BNumber).data);
		if (index < 0 || index > arr.length) {
			panic('Index out of bounds: $index, array length is ${arr.length}');
		}
		arr[index] = value;
	}

	function isValid() {
		return true;
	}

	function isDefinable() {
		return false;
    }
    
    function define(_, _, _) {
        panic("Not definable");
    }

	function toString(s = "", i = "") {
		return '${arr.toString(s, i)}[${index.toString(s, i)}]';
	}
}
