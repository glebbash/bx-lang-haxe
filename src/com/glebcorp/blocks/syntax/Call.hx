package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.syntax.ArrayAtom;
import com.glebcorp.blocks.syntax.ArrayAtom.ARRAY;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.Core;

class Call extends PrecAction {
	override public function parse(parser: ExprParser, token: Token, expr: Expression): CallExpr {
        return new CallExpr(expr, ARRAY.parse(parser, token));
    }
}

@:publicFields
class CallExpr implements Expression {
    final fun: Expression;
    final args: ArrayExpr;

    function new(fun: Expression, args: ArrayExpr) {
        this.fun = fun;
        this.args = args;
    }

    function eval(ctx: Context) {
        final fun = fun.eval(ctx).as(BFunction);
        final args = args.items.map(arg -> arg.eval(ctx));
        final value = fun.call(args);
        return value;
    }

    function toString(symbol = "", indent = "") {
        return '$fun(${args.toString(symbol, indent)})';
    }
}
