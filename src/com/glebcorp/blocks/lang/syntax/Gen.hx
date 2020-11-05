package com.glebcorp.blocks.lang.syntax;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lang.Scope;
import com.glebcorp.blocks.lang.Prelude;
import com.glebcorp.blocks.lang.Core;
import com.glebcorp.blocks.lang.syntax.Identifier;
import com.glebcorp.blocks.utils.Panic.panic;

using Std;
using com.glebcorp.blocks.utils.NullUtils;

@:tink class Gen implements Atom {
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
		final fun = new GenFunExpr(params, body);

		return name == null ? fun : new NamedGenFunExpr(name, fun);
	}
}

@:tink class GenFunExpr implements Expression {
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
            return new BGenerator(genCtx, body);
        });
	}

	function toString(s = "", i = "") {
		return 'gen fun(${params.join(", ")}) ${body.toString(s, i)}';
	}
}

@:tink class NamedGenFunExpr implements Expression {
	final name: String = _;
	final fun: GenFunExpr = _;

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
		return 'gen fun $name ${fun.params.join(", ")} ${fun.body.toString(s, i)}';
	}
}