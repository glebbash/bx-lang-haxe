package com.glebcorp.blocks;

import com.glebcorp.blocks.engine.Engine.BValue;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.Parser;


typedef ExprParser = Parser<Expression>;
typedef Atom<T : Expression> = PrefixParser<Expression, T>;
typedef Action<T : Expression> = PostfixParser<Expression, T>;

@:structInit
class Context {
    public var scope: Scope;
    public var core: Blocks;
}

interface Expression {
    function eval(ctx: Context): BValue;

    function toString(?symbol: String, ?indent: String): String;
}

class Core {
    public static function subContext(ctx: Context) {
        return { scope: new Scope(ctx.scope), core: ctx.core };
    }
}