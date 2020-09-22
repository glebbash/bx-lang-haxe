package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Prelude;

class Return implements Atom {
    static final PARSER = new Yield();

    function new() {}

    function parse(parser: ExprParser, token: Token): ReturnExpr {
        return new ReturnExpr(parser.parseToEnd());
    }
}

@:tink class ReturnExpr implements Expression {
    final value: Expression = _;

    function eval(ctx: Context) {
        return new BReturn(value.eval(ctx));
    }

    function toString(s = "", i = "") {
        return 'return ${value.toString(s, i)}';
    }
}