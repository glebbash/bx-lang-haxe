package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Prelude;

class Await implements Atom {
    static final AWAIT = new Yield();

    function new() {}

    function parse(parser: ExprParser, token: Token): AwaitExpr {
        return new AwaitExpr(parser.parseToEnd());
    }
}

@:tink class AwaitExpr implements Expression {
    final value: Expression = _;

    function eval(ctx: Context) {
        return new BPausedExec(new PausedExec([], value.eval(ctx), true));
    }

    function toString(s = "", i = "") {
        return 'await ${value.toString(s, i)}';
    }
}