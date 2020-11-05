package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.syntax.Export;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.syntax.Identifier;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.syntax.Block;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.Core;
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
