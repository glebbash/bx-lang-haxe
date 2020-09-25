package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.engine.Prelude;

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
        if (this.cond.eval(ctx) == BBoolean.TRUE) {
            return this.ifTrue.eval(Core.subContext(ctx));
        } else if (this.ifFalse != null) {
            return this.ifFalse.eval(Core.subContext(ctx));
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