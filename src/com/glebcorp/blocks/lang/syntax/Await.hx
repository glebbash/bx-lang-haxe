package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Prelude;

class Await implements Atom {
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