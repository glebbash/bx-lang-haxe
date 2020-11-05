package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Prelude;

class Yield implements Atom {
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