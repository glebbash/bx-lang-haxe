package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Prelude;
import com.glebcorp.blocks.lang.Engine;
import com.glebcorp.blocks.lang.syntax.Assign;
import com.glebcorp.blocks.lang.syntax.Call;
import com.glebcorp.blocks.lang.syntax.ArrayAtom;
import com.glebcorp.blocks.utils.Panic.panic;

@:tink class Dot extends PrecAction {
	final ident: Identifier = _;
	final array: ArrayAtom = _;

	override function parse(parser: ExprParser, token: Token, obj: Expression): Expression {
		final name = ident.expect(parser, true).name;
		if (parser.nextIs({type: TokenType.BlockParen})) {
			return new MethodCallExpr(obj, name, array.parse(parser, parser.next()));
		}
		return new PropExpr(obj, name);
	}
}

@:tink class MethodCallExpr implements CallableExpression {
	final obj: Expression = _;
	final method: String = _;
	final args: ArrayExpr = _;

	function call(ctx: Context, args: Array<BValue>) {
		return obj.eval(ctx).invoke(ctx.core.engine, method, args);
	}

	function toString(s = "", i = "") {
		return '${obj.toString(s, i)}.$method(${args.toString(s, i)})';
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
