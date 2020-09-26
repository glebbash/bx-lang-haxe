package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.syntax.Identifier;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.utils.Panic.panic;

using Std;
using com.glebcorp.blocks.utils.NullUtils;

@:tink class Async implements Atom {
	final ident: Identifier = _;
	final array: ArrayAtom = _;
	final block: Block = _;
    
	function parse(parser: ExprParser, token: Token): Expression {
		parser.expect({value: "fun"});
		final name = parser.nextIs({complexType: "<IDENT>"}) ? ident.parse(parser, parser.next()).name : null;

		final paramsToken = parser.expect({type: TokenType.BlockParen});
		final paramsExpr = array.parse(parser, paramsToken);
		final params = paramsExpr.items.map(paramExpr -> {
			if (paramExpr.isOfType(IdentExpr)) {
				return cast(paramExpr, IdentExpr).name;
			}
			return parser.unexpectedToken(paramsToken);
		});
		final body = block.blockOrExpr(parser);
		final fun = new AsyncFunExpr(params, body);

		return name == null ? fun : new NamedAsyncFunExpr(name, fun);
	}
}

@:tink class AsyncFunExpr implements Expression {
	final params: Array<String> = _;
	final body: Expression = _;

	function eval(ctx: Context) {
		return new BFunction(args -> {
            final genCtx = Core.subContext(ctx);
            final pLen = params.length;
            final aLen = args.length;
            for (i in 0...pLen) {
                if (i < aLen) {
                    genCtx.scope.define(params[i], args[i]);
                }
            }
            return new BAsyncFunction(genCtx, body).wrap();
        });
	}

	function toString(s = "", i = "") {
		return 'async fun(${params.join(", ")}) ${body.toString(s, i)}';
	}
}

@:tink class NamedAsyncFunExpr implements Expression {
	final name: String = _;
	final fun: AsyncFunExpr = _;

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
		return 'async fun $name ${fun.params.join(", ")} ${fun.body.toString(s, i)}';
	}
}