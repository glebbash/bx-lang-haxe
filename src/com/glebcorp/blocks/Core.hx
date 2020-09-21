package com.glebcorp.blocks;

import com.glebcorp.blocks.engine.Engine.BValue;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.Parser;
import com.glebcorp.blocks.utils.Panic.panic;

typedef ExprParser = Parser<Expression>;
typedef Atom = PrefixParser<Expression, Expression>;
typedef Action = PostfixParser<Expression, Expression>;

@:publicFields
@:tink class Context {
	final scope: Scope = _;
	final core: Blocks = _;
}

interface Expression {
	function eval(ctx: Context): BValue;

	function toString(?symbol: String, ?indent: String): String;
}

extern class Core {
	public static inline function subContext(ctx: Context): Context {
		return new Context(new Scope(ctx.scope), ctx.core);
	}
}

@:publicFields
@:tink class PrecAction implements PostfixParser<Expression, Expression> {
	final prec: Float = _;

	function parse(_, _, _): Expression {
		panic("Abstract method");
	}

	function precedence(_) {
		return prec;
	}
}