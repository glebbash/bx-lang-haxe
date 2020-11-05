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
import com.glebcorp.blocks.lib.BTimer;
import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.utils.Println.println;

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
		final None = expose(engine.addType("None"));
		final Any = expose(engine.addType("Any"));
		expose(Any.extend("Boolean"));
		expose(Any.extend("Number"));
		final String = expose(Any.extend("String"));
		final Array = expose(Any.extend("Array"));
		expose(Any.extend("Object"));
		final Function = expose(Any.extend("Function"));
		final Generator = expose(Function.extend("Generator"));
		final Timer = expose(Any.extend("Timer"));

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
		String.addMethod("split", f2((str, sep) -> {
			final arr = str.as(BString).data.split(sep.as(BString).data);
			final res = arr.map(s -> cast(new BString(s), BValue));
			return new BArray(res);
		}));
		Array.addMethod("map", f2((arr, funV) -> {
			final fun = funV.as(BFunction);
			return new BArray(arr.as(BArray).data.map(e -> fun.call([e])));
		}))
			.addMethod("fold", f3((arr, init, funV) -> {
				final fun = funV.as(BFunction);
				return Lambda.fold(arr.as(BArray).data, (acc, val) -> fun.call([acc, val]), init);
			}))
			.addMethod("find", f2((arr, funV) -> {
				final fun = funV.as(BFunction);
				final items = arr.as(BArray).data;
				final item = Lambda.find(items, item -> fun.call([item]) == BBoolean.TRUE);
				return if (item == null) {
					BNone.VALUE;
				} else {
					item;
				}
			}))
			.addMethod("join", f2((arr, sep) -> {
				final sepS = sep.as(BString).data;
				final res = arr.as(BArray).data.join(sepS);
				return new BString(res);
			}));
		Timer.addMethod("passed", new BFunction(args -> {
			return new BNumber(cast(args[0], BTimer).passed());
		})).addMethod("start", new BFunction(args -> {
			return new BTimer();
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
		globalScope.define("exit", f1(code -> {
			Sys.exit(Std.int(code.as(BNumber).data));
			return BVoid.VALUE;
		}));
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
		final filePath = '${rootPath}/${path}.bx';
		final file = readFile(filePath);
		return eval(file, ctx);
	}

	private function readFile(path: String): String {
		#if sys
		return sys.io.File.getContent(path);
		#elseif node
		return js.node.Fs.readFileSync(path, "utf-8");
		#else
		return panic('Error: This platform does not support file I/O');
		#end
	}

	function eval(source: String, ?ctx: Context): BValue {
		final tokens = lexer.tokenize(source);
		final exprs = parser.parseAll(tokens);
		final context = ctx.or(() -> new Context(new Scope(globalScope), this));
		return exprs.map(e -> e.eval(context)).last().unwrap();
	}

	function prettyPrint(source: String): String {
		final tokens = lexer.tokenize(source);
		final exprs = parser.parseAll(tokens);
		return exprs.map(expr -> expr.toString()).join("\n");
	}

	private function expose(type: BType): BType {
		globalScope.define(type.name, type, true);
		return type;
	}
}
