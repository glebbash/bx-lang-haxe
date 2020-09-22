package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Prelude;

class Yield implements Atom {
    static final YIELD = new Yield();

    function new() {}

    function parse(parser: ExprParser, token: Token): YieldExpr {
        return new YieldExpr(parser.parseToEnd());
    }
}

@:tink class YieldExpr implements Expression {
    final value: Expression = _;

    function eval(ctx: Context) {
        return new BPausedExec(new PausedExec([], value.eval(ctx), false));
    }

    function toString(s = "", i = "") {
        return 'yield ${value.toString(s, i)}';
    }
}