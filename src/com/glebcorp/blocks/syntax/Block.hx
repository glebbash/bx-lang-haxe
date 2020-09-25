package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude;

using com.glebcorp.blocks.utils.NullUtils;

class Block implements Atom {
	function new() {}
	
	static function isBlock(token: Token) {
		return switch (token.type) {
			case BlockIndent, BlockBrace: true;
			default: false;
		}
	}

	function blockOrExpr(parser: ExprParser): BlockExpr {
		return isBlock(parser.next(false)) ? expect(parser) : new BlockExpr([parser.parse()]);
	}

	function expect(parser: ExprParser): BlockExpr {
		final token = parser.next();
		return isBlock(token) ? parse(parser, token) : parser.unexpectedToken(token);
	}

	function parse(parser: ExprParser, token: Token): BlockExpr {
		return switch (token.value) {
			case Tokens(exprs):
				return new BlockExpr(exprs.map(e -> parser.subParser(e).parseToEnd()));
			default: parser.unexpectedToken(token);
		}
	}
}

@:tink class BlockExpr implements Expression {
	final body: Array<Expression> = _;

	function eval(ctx: Context) {
		return resume(ctx, 0, BVoid.VALUE);
	}

	function resume(ctx: Context, startLine: Int, res: BValue) {
        for (line in startLine...body.length) {
			res = body[line].eval(ctx);
			if (res.is(BPausedExec)) {
				res.as(BPausedExec).data.execStack.unshift(new BlockExecState(ctx, this, line + 1));
				return res;
			}
			if (res.is(BReturn) || res.is(BBreak) || res.is(BContinue)) {
				return res;
			}
		}
		return res;
	}

	function toString(s = "", i = "") {
		final bodyIndent = body.length > 1 ? i + s : "";
		return '$i{\n${body.map(it -> it.toString(s, bodyIndent)).join("\n")}\n$i}';
	}
}

@:tink class BlockExecState implements ExecState {
	final ctx: Context = _;
	final block: BlockExpr = _;
	final line: Int = _;

	function resume(?value : BValue) {
		return block.resume(ctx, line, value.or(BVoid.VALUE));
	}
}
