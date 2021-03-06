import com.glebcorp.blocks.lang.Blocks;
import com.glebcorp.blocks.lang.BlocksParser;
import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.utils.Println.println;

class Main {
	static extern inline var TIMES = 10000;

	static function main() {
		evalTest();
	}

	static function evalTest() {
		var blocks = new Blocks("scripts");
		try {
			println(blocks.evalFile("main"));
		} catch (e) {
			println(e);
		}
	}

	static function parserTest() {
		new BlocksParser();
	}

	#if(sys)
	static function lexerBench() {
		var lexer = new Lexer(Blocks.LEXER_CONFIG);
		var file = sys.io.File.getContent("../bx-lang-js/data/tests/generator.bx");
		var was = haxe.Timer.stamp() * 1000;
		for (_ in 1...TIMES) {
			lexer.tokenize(file);
		}
		println((haxe.Timer.stamp() * 1000 - was) / TIMES);
	}
	#end
}
