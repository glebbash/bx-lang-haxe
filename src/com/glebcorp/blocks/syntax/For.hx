package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.syntax.Block;
import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.syntax.Assign;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;

using Std;
using com.glebcorp.blocks.utils.NullUtils;

@:tink class For implements Atom {
	final block: Block = _;

	function parse(parser: ExprParser, token: Token): ForExpr {
		final condParser = parser.nextIs({type: TokenType.BlockParen}) ? parser.subParser(Paren.parenExpr(parser, parser.next())) : parser;
		final bindingStartToken = condParser.next(false);
		final binding = condParser.parse();
		if (!binding.isOfType(AssignableExpr)
			|| !cast(binding, AssignableExpr).isDefinable() || !cast(binding, AssignableExpr).isValid()) {
			return condParser.unexpectedToken(bindingStartToken);
		}
		condParser.expect({value: "in"});
		final iterable = condParser.parse();
		final body = block.blockOrExpr(parser);
		return new ForExpr(cast(binding, AssignableExpr), iterable, body);
	}
}

@:tink class ForExpr implements Expression {
	final binding: AssignableExpr = _;
	final iterable: Expression = _;
	final body: Expression = _;

	function eval(ctx: Context) {
		final iterable = iterable.eval(ctx);
		if (!iterable.isOfType(BIterable)) {
			panic('$iterable is no iterable');
        }
		return resume(ctx, cast(iterable, BIterable).iterator());
	}

	function resume(ctx: Context, iterator: BIterator) {
		while (iterator.hasNext()) {
			final val = iterator.next();
			final forCtx = Core.subContext(ctx);
			binding.define(forCtx, val, false);
			final res = body.eval(forCtx);
			if (res.is(BPausedExec)) {
				res.as(BPausedExec).data.execStack.unshift(new ForExecState(ctx, this, iterator));
				return res;
			}
			if (res.is(BBreak)) {
				if (--res.as(BBreak).data != 0) {
					return res;
				}
				return BVoid.VALUE;
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

	function toString(s = "", i = "") {
		return 'for (${binding.toString(s, i)} in ${iterable.toString(s, i)}) ${body.toString(s, i)}';
	}
}

@:tink class ForExecState implements ExecState {
	final ctx: Context = _;
	final forExpr: ForExpr = _;
	final iterator: BIterator = _;

	function resume(?res: BValue) {
		if (res != null) {
			if (res.is(BBreak)) {
				if (--res.as(BBreak).data != 0) {
					return res;
				}
				return BVoid.VALUE;
			}
			if (res.is(BContinue) && --res.as(BContinue).data != 0) {
				return res;
			}
			if (res.is(BReturn)) {
				return res;
			}
		}
		return forExpr.resume(ctx, iterator);
	}
}
