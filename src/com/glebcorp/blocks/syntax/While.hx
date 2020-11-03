package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;

using com.glebcorp.blocks.utils.NullUtils;

@:tink class While implements Atom {
	final block: Block = _;

	function parse(parser: ExprParser, token: Token) {
		final cond = parser.parse();
		final body = block.blockOrExpr(parser);
		return new WhileExpr(cond, body);
	}
}

@:tink class WhileExpr implements Expression {
	final cond: Expression = _;
	final body: Expression = _;

	function eval(ctx: Context) {
		while (cond.eval(ctx) == BBoolean.TRUE) {
			final loopCtx = Core.subContext(ctx);
			final res = body.eval(loopCtx);
			if (res.is(BPausedExec)) {
				res.as(BPausedExec).data.execStack.unshift(new WhileExecState(ctx, this));
				return res;
			}
			if (res.is(BBreak)) {
				if (--res.as(BBreak).data != 0) {
					return res;
				}
				break;
			}
			if (res.is(BContinue) && --res.as(BContinue).data != 0) {
				return res;
			}
			if (res.is(BReturn)) {
				return res;
			}
		}
		return BVoid.VALUE;
	}

	function resume(ctx: Context, res: BValue) {
		if (res.is(BBreak)) {
			if (--res.as(BBreak).data != 0) {
				return res;
			}
			return BVoid.VALUE;
		}
		if (res.is(BContinue) && --res.as(BContinue).data != 0) {
			return res;
		}
		return eval(ctx);
	}

	function toString(s = "", i = "") {
		return 'while $cond $body';
	}
}

@:tink class WhileExecState implements ExecState {
	final ctx: Context = _;
	final whileExpr: WhileExpr = _;

	function resume(?res: BValue) {
		return whileExpr.resume(ctx, res.or(() -> BVoid.VALUE));
	}
}
