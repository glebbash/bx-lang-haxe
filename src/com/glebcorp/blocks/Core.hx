package com.glebcorp.blocks;

import com.glebcorp.blocks.engine.Engine.BValue;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.Parser;

typedef ExprParser = Parser<Expression>;
typedef Atom = PrefixParser<Expression, Expression>;
typedef Action = PostfixParser<Expression, Expression>;

@:publicFields
@:structInit
class Context {
	var scope: Scope;
	var core: Blocks;
}

interface Expression {
	function eval(ctx: Context): BValue;

	function toString(?symbol: String, ?indent: String): String;
}

extern class Core {
	public static inline function subContext(ctx: Context): Context
		return {scope: new Scope(ctx.scope), core: ctx.core};
}
