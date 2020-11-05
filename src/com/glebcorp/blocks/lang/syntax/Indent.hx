package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;

class Indent implements Action {
    function new() {}

    function parse(parser: ExprParser, token: Token, expr: Expression): Expression {
        return switch (token.value) {
            case Tokens(exprs):
                final sub = parser.subParser(Lambda.flatten(exprs));
                while (0 < sub.tokenPrecedence()) {
                    final token = sub.next();
                    expr = sub.expectPostfixParser(token).parse(sub, token, expr);
                }
                sub.checkTrailing();
                return expr;
            default: parser.unexpectedToken(token);
        }
    }

    function precedence(parser: ExprParser): Float {
        final token = parser.next(false);
        return switch (token.value) {
            case Tokens(expr):
                final sub = parser.expectPostfixParser(expr[0][0]);
                return sub.precedence(parser);
            default: parser.unexpectedToken(token);
        }
    }
}