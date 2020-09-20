package com.glebcorp.blocks;

import haxe.macro.Expr;
import haxe.Timer;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.engine.Prelude.BFunction.f1;
import com.glebcorp.blocks.engine.Prelude.BFunction.f2;
import com.glebcorp.blocks.engine.Prelude.BFunction.f3;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude.BVoid.VOID;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.utils.Println.println;
import com.glebcorp.blocks.utils.Panic.panic;

using com.glebcorp.blocks.utils.ArrayLast;
using com.glebcorp.blocks.utils.NullUtils;

class Blocks {
	public static final LEXER_CONFIG: LexerConfig = {
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
			"{" => {
				end: "}",
				type: BlockBrace
			},
			"[" => {
				end: "]",
				type: BlockBracket
			},
			"(" => {
				end: ")",
				type: BlockParen
			},
		],
		captureComments: false,
	}

	public final lexer = new Lexer(LEXER_CONFIG);
	public final parser = new BlocksParser();
	public final engine = new Engine();
	public final globalScope = new Scope();
	public final rootPath: String;

	public function new(rootPath: String) {
		this.rootPath = rootPath;

		var Any = engine.addType("Any");
		engine.addType("Boolean", "Any");
		engine.addType("Number", "Any");
		engine.addType("String", "Any");
		var Array = engine.addType("Array", "Any");
		engine.addType("Object", "Any");
		engine.addType("Function", "Any");
		var Generator = engine.addType("Generator", "Function");

		Any.addMethod("also", f2((fun, val) -> {
			fun.as(BFunction).call([val]);
			return val;
		}));
		// Generator.addMethod("next", (gen, ?val: BValue) -> {
		// 	return gen.as(BGenerator).nextValue(val);
		// }).addMethod("hasNext", (gen) -> {
		// 	return bool(!gen.as(BGenerator).ended);
		// });
		Array.addMethod("map", f2((arr, funV) -> {
			final fun = funV.as(BFunction);
			return new BArray(arr.as(BArray).data.map(e -> fun.call([e])));
		})).addMethod("fold", f3((arr, init, funV) -> {
			final fun = funV.as(BFunction);
			return Lambda.fold(arr.as(BArray).data, (acc, val) -> fun.call([acc, val]), init);
		}));
		globalScope.define("print", new BFunction((val) -> {
			println(val.toString());
			return VOID;
		}));
		// globalScope.define("input", new BFunction((fun) -> {
		// 	var cb = fun.as(BFunction);
		// 	process.stdin.once("data", (data) -> {
		// 		cb.call(new BString(data.toString().slice(0, -1)));
		// 	});
		// 	return VOID;
		// }));
		globalScope.define("time", new BFunction(_ -> {
			return new BNumber(Math.floor(Timer.stamp() * 1000));
		}));
		// globalScope.define("exit", new BFunction((val) -> {
		// 	process.exit(val ? .as(BNumber) ? .data);
		// }));
		globalScope.define("require", f1(pathV -> {
			var path = pathV.as(BString).data;
			var importCtx: Context = {
				scope: new Scope(globalScope, new Set()),
				core: this,
			};
			evalFile(path, importCtx);
			final obj = new BObject([]);
			for (key in importCtx.scope.exports.unwrap().keys()) {
				obj.data[key] = importCtx.scope.get(key);
			}
			return obj;
		}), true);
		globalScope.define("type", f1(val -> new BString(val.type)));
		globalScope.define("Parse", new BObject([
			"number" => f1(str -> {
				return new BNumber(Std.parseFloat(str.as(BString).data));
			})
		]));
	}

	public function evalFile(path: String, ?ctx: Context): BValue {
		#if (!sys)
		return panic('Error: This platform does not support file I/O');
		#else
		var filePath = rootPath + "/" + path.split(".").join("/") + ".bx";
		var file = sys.io.File.getContent(filePath);
		return eval(file, ctx);
		#end
	}

	public function eval(source: String, ?ctx: Context): BValue {
		var tokens = lexer.tokenize(source);
		var exprs = parser.parseAll(tokens);
		var context = ctx.or({scope: new Scope(globalScope), core: this});
		return exprs.map(e -> e.eval(context)).last().unwrap();
	}

	public function prettyPrint(source: String): String {
		var tokens = lexer.tokenize(source);
		var exprs = parser.parseAll(tokens);
		return exprs.map(expr -> expr.toString()).join("\n");
	}
}
