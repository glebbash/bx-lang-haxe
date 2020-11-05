package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Prelude;
import com.glebcorp.blocks.lang.Engine;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.syntax.Assign;
import com.glebcorp.blocks.utils.Panic.panic;

@:tink class Define implements Atom {
    final defineVar: Atom = _;
    final defineConst: Atom = _;
    final defineFun: Atom = _;

    function parse(parser: ExprParser, token: Token): Expression {
        if (parser.nextIs({ value: "mut" })) {
            return defineVar.parse(parser, parser.next());
        }
        if (parser.nextIs({ complexType: "<IDENT>" })) {
            final params = parser.tokens.peek(2);
            if (params == null) {
                return parser.unexpectedToken(null);
            }
            if (params.type == TokenType.BlockParen) {
                return defineFun.parse(parser, token);
            }
        }
        return defineConst.parse(parser, token);
    }
}