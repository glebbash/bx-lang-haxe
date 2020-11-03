package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.syntax.Assign;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;

@:tink class Dot extends PrecAction {
	final ident: Identifier = _;
	final array: ArrayAtom = _;

	override function parse(parser: ExprParser, token: Token, obj: Expression): Expression {
		final name = ident.expect(parser, true).name;
		if (parser.nextIs({type: TokenType.BlockParen})) {
			return new MethodCallExpr(obj, name, array.parse(parser, parser.next()).items);
		}
		return new PropExpr(obj, name);
	}
}

@:tink class MethodCallExpr implements Expression {
	final obj: Expression = _;
	final method: String = _;
	final args: Array<Expression> = _;

	function eval(ctx: Context) {
        final args = args.map(arg -> arg.eval(ctx));
		return obj.eval(ctx).invoke(ctx.core.engine, method, args);
	}

	function toString(s = "", i = "") {
		return '${obj.toString(s, i)}.$method(${args.map(it -> it.toString(s, i)).join(", ")})';
	}
}

@:tink class PropExpr implements AssignableExpr {
	final obj: Expression = _;
	final prop: String = _;

	function eval(ctx: Context) {
		final object = obj.eval(ctx);
		if (!(object is BMap)) {
			panic("Cannot get member of ${object.type}");
		}
		return cast(object, BMap).get(prop);
	}

	function assign(ctx: Context, value: BValue) {
		final object = obj.eval(ctx);
		if (!(object is BMap)) {
			panic("Cannot get member of ${object.type}");
		}
		cast(object, BMap).set(prop, value);
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
		return '${obj.toString(s, i)}.$prop';
	}
}
