package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.syntax.Assign;
import com.glebcorp.blocks.syntax.Call;
import com.glebcorp.blocks.syntax.ArrayAtom;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;

@:tink class DoubleSemi extends PrecAction {
	final ident: Identifier = _;
	final array: ArrayAtom = _;

	override function parse(parser: ExprParser, token: Token, obj: Expression): Expression {
		final name = ident.expect(parser, true).name;
		if (parser.nextIs({type: TokenType.BlockParen})) {
			return new PropCallExpr(obj, name, array.parse(parser, parser.next()));
		}
		return new MethodGetExpr(obj, name);
	}
}

@:tink class PropCallExpr implements CallableExpression {
	final obj: Expression = _;
	final name: String = _;
	final args: ArrayExpr = _;

	function call(ctx: Context, args: Array<BValue>) {
		final object = obj.eval(ctx);
		if (!(object is BMap)) {
			panic("Cannot get member of ${object.type}");
		}
		return cast(object, BMap).get(name).as(BFunction).call(args);
	}

	function toString(s = "", i = "") {
		return '${obj.toString(s, i)}::$name(${args.toString(s, i)})';
	}
}

@:tink class MethodGetExpr implements Expression {
	final obj: Expression = _;
	final method: String = _;

	function eval(ctx: Context) {
		final object = obj.eval(ctx);
		if (!(object is BMap)) {
			panic("Cannot get member of ${object.type}");
		}
		return cast(object, BMap).get(method);
	}

	function toString(s = "", i = "") {
		return '${obj.toString(s, i)}::$method';
	}
}
