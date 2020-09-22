package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.utils.SyntaxError.syntaxError;

class Paren implements Atom {
    static final PARSER = new Paren();

    function new() {}

	static function parenExpr(parser: ExprParser, token: Token): Tokens {
        return switch(token.value) {
            case Tokens(exprs):
                if (exprs.length != 1) {
                    syntaxError("Multiple expressions in parentheses.", token.start);
                }
                if (exprs[0].length == 0) {
                    parser.unexpectedToken(token);
                }
                return exprs[0];
            default: parser.unexpectedToken(token);
        }
    }
    
    function parse(parser: ExprParser, token: Token): ParenExpr {
        final expr = parenExpr(parser, token);
        return new ParenExpr(parser.subParser(expr).parseToEnd());
    }
}

@:tink class ParenExpr implements Expression {
    final expr: Expression = _;

    function eval(ctx: Context) {
        return expr.eval(ctx);
    }

    function toString(s = "", i = "") {
        return '(${expr.toString(s, i)})';
    }
}
