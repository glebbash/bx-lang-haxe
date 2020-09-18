import com.glebcorp.blocks.BlocksParser;
import haxe.Timer;
import sys.io.File;
import com.glebcorp.blocks.Blocks;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.Parser;

class Main {
	static inline var TIMES = 10000;

	static function main() {
		evalTest();
	}

	static function evalTest() {
		var blocks = new Blocks("../bx-lang-js/data");
		Sys.println(blocks.evalFile("tests.simple"));
	}

	static function parserTest() {
		new BlocksParser();
	}

	static function lexerBench() {
		var lexer = new Lexer(Blocks.LEXER_CONFIG);
		var file = File.getContent("../bx-lang-js/data/tests/generator.bx");
		var was = Timer.stamp() * 1000;
		for (_ in 1...TIMES) {
			lexer.tokenize(file);
		}
		Sys.println((Timer.stamp() * 1000 - was) / TIMES);
	}
}
