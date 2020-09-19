package com.glebcorp.blocks;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.engine.Scope;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.Lexer.LexerConfig;
#if(!sys)
import com.glebcorp.blocks.utils.Panic.panic;
#end

using com.glebcorp.blocks.utils.ArrayLast;

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
	}

	public function evalFile(path: String, ?ctx: Context): BValue {
		#if(!sys)
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
		var context: Context = ctx == null ? {scope: new Scope(globalScope), core: this} : ctx;
		return exprs.map(function(e) return e.eval(context)).last();
	}

	public function prettyPrint(source: String): String {
		var tokens = lexer.tokenize(source);
		var exprs = parser.parseAll(tokens);
		return exprs.map(function(expr) return expr.toString()).join("\n");
	}
}
