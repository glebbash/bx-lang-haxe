package com.glebcorp.blocks;

import com.glebcorp.blocks.BlocksParser.bool;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude.BFunction.f1;
import com.glebcorp.blocks.engine.Prelude.BFunction.f2;
import com.glebcorp.blocks.engine.Prelude.BFunction.f3;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.utils.Println.println;
import haxe.Timer;

using com.glebcorp.blocks.utils.ArrayUtils;
using com.glebcorp.blocks.utils.NullUtils;

@:tink class Blocks {
	static final LEXER_CONFIG: LexerConfig = {
		singleLineCommentStart: "//",
		multilineCommentStart: "/*",
		multilineCommentEnd: "*/",
		whitespaceRegex: ~/[ \n\t\r]/,
		numberStartRegex: ~/\d/,
		numberRegex: ~/\d/,
		identifierStartRegex: ~/[a-zA-Z_]/,
		identifierRegex: ~/[a-zA-Z_0-9]/,
		operatorRegex: ~/[^ \n\t\r_a-zA-Z0-9\{\}\[\]\(\)'"]/,
		bracketed: [
			"{" => new BracketInfo("}", BlockBrace),
			"[" => new BracketInfo("]", BlockBracket),
			"(" => new BracketInfo(")", BlockParen),
		],
		captureComments: false,
	}

	final lexer = new Lexer(LEXER_CONFIG);
	final parser = new BlocksParser();
	final engine = new Engine();
	final globalScope = new Scope();
	final rootPath: String = _;

	function new() {
		final Any = engine.addType("Any");
		Any.extend("Boolean");
		Any.extend("Number");
		Any.extend("String");
		final Array = Any.extend("Array");
		Any.extend("Object");
		final Function = Any.extend("Function");
		final Generator = Function.extend("Generator");

		Any.addMethod("also", f2((fun, val) -> {
			fun.as(BFunction).call([val]);
			return val;
		}));
		Generator.addMethod("next", new BFunction(args -> {
			if (args.length == 1) {
				return args[0].unsafe().as(BGenerator).nextValue();
			} else if (args.length == 2) {
				return args[0].unsafe().as(BGenerator).nextValue(args[1].unsafe());
			} else {
				panic("Expected 1-2 arguments");
			}
		})).addMethod("hasNext", f1(gen -> {
			return bool(!gen.as(BGenerator).ended);
		}));
		Array.addMethod("map", f2((arr, funV) -> {
			final fun = funV.as(BFunction);
			return new BArray(arr.as(BArray).data.map(e -> fun.call([e])));
		})).addMethod("fold", f3((arr, init, funV) -> {
			final fun = funV.as(BFunction);
			return Lambda.fold(arr.as(BArray).data, (acc, val) -> fun.call([acc, val]), init);
		}));
		globalScope.define("print", f1(val -> {
			println(val.toString());
			return BVoid.VALUE;
		}));
		// globalScope.define("input", new BFunction((fun) -> {
		// 	var cb = fun.as(BFunction);
		// 	process.stdin.once("data", (data) -> {
		// 		cb.call(new BString(data.toString().slice(0, -1)));
		// 	});
		// 	return BVoid.VALUE;
		// }));
		globalScope.define("time", new BFunction(_ -> {
			return new BNumber(Math.floor(Timer.stamp() * 1000));
		}));
		// globalScope.define("exit", new BFunction((val) -> {
		// 	process.exit(val ? .as(BNumber) ? .data);
		// }));
		globalScope.define("require", f1(pathV -> {
			var path = pathV.as(BString).data;
			var importCtx = new Context(new Scope(globalScope, new Set()), this);
			evalFile(path, importCtx);
			final obj = new BObject();
			for (key in importCtx.scope.exports.unwrap().keys()) {
				obj.set(key, importCtx.scope.get(key));
			}
			return obj;
		}), true);
		globalScope.define("type", f1(val -> new BString(val.type)));
		globalScope.define("Parse", new BObject().set("number", f1(str -> {
			return new BNumber(Std.parseFloat(str.as(BString).data));
		})));
	}

	function evalFile(path: String, ?ctx: Context): BValue {
		#if (!sys)
		return panic('Error: This platform does not support file I/O');
		#else
		final filePath = rootPath + "/" + path.split(".").join("/") + ".bx";
		final file = sys.io.File.getContent(filePath);
		return eval(file, ctx);
		#end
	}

	function eval(source: String, ?ctx: Context): BValue {
		final tokens = lexer.tokenize(source);
		trace(tokens);
		final exprs = parser.parseAll(tokens);
		final context = ctx.or(new Context(new Scope(globalScope), this));
		return exprs.map(e -> e.eval(context)).last().unwrap();
	}

	function prettyPrint(source: String): String {
		final tokens = lexer.tokenize(source);
		final exprs = parser.parseAll(tokens);
		return exprs.map(expr -> expr.toString()).join("\n");
	}
}
