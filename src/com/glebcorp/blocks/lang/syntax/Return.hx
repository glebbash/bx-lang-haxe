package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Prelude;

class Return implements Atom {
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