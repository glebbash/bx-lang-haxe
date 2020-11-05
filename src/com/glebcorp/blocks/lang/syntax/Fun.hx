package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Scope;
import com.glebcorp.blocks.lang.Prelude;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.syntax.Block;
import com.glebcorp.blocks.lang.syntax.Export;
import com.glebcorp.blocks.lang.syntax.Identifier;
import com.glebcorp.blocks.utils.Panic.panic;

using Std;
using com.glebcorp.blocks.utils.NullUtils;

@:tink class Fun implements Atom {
	final ident: Identifier = _;
	final params: ArrayAtom = _;
	final block: Block = _;

	function parse(parser: ExprParser, token: Token): Expression {
		var name: Null<String> = null;
		if (parser.nextIs({complexType: "<IDENT>"})) {
			name = ident.parse(parser, parser.next()).name;
		}
		final paramsToken = parser.expect({type: TokenType.BlockParen});
		final paramsExpr = params.parse(parser, paramsToken);
		final params = paramsExpr.items.map(paramExpr -> {
			if (paramExpr.isOfType(IdentExpr)) {
				return cast(paramExpr, IdentExpr).name;
			}
			parser.unexpectedToken(paramsToken);
		});
		if (name != null && parser.nextIs({ value: "=" })) {
			parser.next();
			final expr = parser.tokens.peek();
  			if (expr == null || Block.isBlock(expr.unsafe())) {
				return parser.unexpectedToken(expr);
			}
		}
		final body = block.blockOrExpr(parser);
		final fun = new FunExpr(params, body);
		return name == null ? fun : new NamedFunExpr(name, fun);
	}
}

@:tink class FunExpr implements Expression {
	final params: Array<String> = _;
	final body: BlockExpr = _;

	function eval(ctx: Context) {
		return new BFunction(args -> {
			final funCtx = Core.subContext(ctx);
			final pLen = params.length;
			final aLen = args.length;
			for (i in 0...pLen) {
				if (i < aLen) {
					funCtx.scope.define(params[i], args[i]);
				}
			}
			final res = body.eval(funCtx);
			if (res.is(BPausedExec)) {
				panic("Attempt to pause normal function");
			}
			return res.is(BReturn) ? res.as(BReturn).data : res;
		});
	}

	function toString(s = "", i = "") {
		return 'fun(${params.join(", ")}) ${body.toString(s, i)}';
	}
}

@:tink class NamedFunExpr implements ExportableExpr {
	final name: String = _;
	final fun: FunExpr = _;

	function eval(ctx: Context) {
		final fun = fun.eval(ctx);
		ctx.scope.define(name, fun);
		return BVoid.VALUE;
	}

	function export(exports: Set<String>) {
		if (exports.unwrap().exists(name)) {
			panic('Cannot re-export \'$name\'');
		}
		exports.unsafe()[name] = true;
	}

	function toString(s = "", i = "") {
		return 'fun $name(${fun.params.join(", ")}) ${fun.body.toString(s, i)}';
	}
}
