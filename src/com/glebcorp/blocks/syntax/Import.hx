package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.engine.Prelude.BVoid.VOID;
import com.glebcorp.blocks.syntax.Identifier;
import com.glebcorp.blocks.syntax.Object;

@:tink class Import implements Atom {
	final object: Object = _;
	final ident: Identifier = _;

	function parse(parser: ExprParser, token: Token) {
		var path = "";
		while (true) {
			final token = parser.expect({type: TokenType.Identifier});
			switch (token.value) {
				case Text(str):
					path += str;
					if (parser.nextIs({value: "::"})) {
						parser.next();
						break;
					}
					parser.expect({value: "."});
					path += ".";
				default:
					parser.unexpectedToken(token);
			}
		}
		if (parser.nextIs({type: TokenType.BlockBrace})) {
			// TODO: check object
			return new ImportExpr(path, object.parse(parser, parser.next()).pairs);
		}
		return new ImportExpr(path, [new KVPair(ident.expect(parser).name, null)]);
	}
}

@:tink class ImportExpr implements Expression {
	final path: String = _;
	final pairs: Array<KVPair> = _;

	function eval(ctx: Context) {
		final importCtx = Core.subContext(ctx);
		importCtx.scope.exports = new Set();

		ctx.core.evalFile(path, importCtx);

		for (pair in pairs) {
			ctx.scope.define(pair.getDef(), importCtx.scope.get(pair.name), true);
		}
		// TODO: handle varargs import
		return VOID;
	}

	function toString(s = "", i = "") {
		return 'import $path::{${pairs.map(p -> p.name).join(", ")}}';
	}
}
