package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.Prelude;

using com.glebcorp.blocks.utils.NullUtils;

@:tink class If implements Atom {
	final block: Block = _;

	function parse(parser: ExprParser, token: Token) {
		final cond = parser.parse();
		final ifTrue = block.blockOrExpr(parser);
		if (parser.nextIs({value: "else"})) {
			parser.next();
			final ifFalse = block.blockOrExpr(parser);
			return new IfExpr(cond, ifTrue, ifFalse);
		}
		return new IfExpr(cond, ifTrue, null);
	}
}

@:tink class IfExpr implements Expression {
    final cond: Expression = _;
    final ifTrue: Expression = _;
    final ifFalse: Null<Expression> = _;

    function eval(ctx: Context) {
        if (cond.eval(ctx) == BBoolean.TRUE) {
            return ifTrue.eval(Core.subContext(ctx));
        } else if (ifFalse != null) {
            return ifFalse.eval(Core.subContext(ctx));
        }
        return BVoid.VALUE;
    }

    function toString(s = "", i = "") {
        if (ifFalse == null) {
            return 'if ${cond.toString(s, i)} ${ifTrue.toString(s, i)}';
        }
        return 'if ${cond.toString(s, i)} ${ifTrue.toString(s, i)} else ${ifFalse.unsafe().toString(s, i)}';
    }
}