package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.syntax.Identifier;
import com.glebcorp.blocks.syntax.Object;

using com.glebcorp.blocks.utils.Slice;
using com.glebcorp.blocks.utils.TokenText;
using com.glebcorp.blocks.utils.NullUtils;

@:tink class Import implements Atom {
	final object: Object = _;
	final ident: Identifier = _;

	function parse(parser: ExprParser, token: Token) {
		var pairs: Null<Array<KVPair>> = null;
		var moduleName: Null<String> = null;
		if (parser.nextIs({type: TokenType.BlockBrace})) {
			// TODO: check object
			pairs = object.parse(parser, parser.next()).pairs;
		} else {
			moduleName = ident.expect(parser).name;
		}

		parser.expect({ value: "from" });

		final pathToken = parser.expect({ type: TokenType.String });
		final path = parser.text(pathToken).slice(1, -1);

		return pairs == null
			? new FullImportExpr(path, moduleName.unsafe())
			: new ImportExpr(path, pairs);
	}
}

@:tink class FullImportExpr implements Expression {
	final path: String = _;
	final moduleName: String = _;

	function eval(ctx: Context) {
		final importCtx = Core.subContext(ctx);
		importCtx.scope.exports = new Set();

		ctx.core.evalFile(path, importCtx);

		final module = new BObject();
		for (member in importCtx.scope.exports.unsafe().keys()) {
			module.set(member, importCtx.scope.get(member));
		}
		
		ctx.scope.define(moduleName, module);

		return BVoid.VALUE;
	}

	function toString(s = "", i = "") {
		return 'import $moduleName from "$path"';
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

		return BVoid.VALUE;
	}

	function toString(s = "", i = "") {
		return 'import {${pairs.map(p -> p.name).join(", ")}} from "$path"';
	}
}
