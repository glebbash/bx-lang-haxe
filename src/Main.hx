import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.BlocksParser;
import com.glebcorp.blocks.Blocks;
import com.glebcorp.blocks.utils.Println.println;

class Main {
	static extern inline var TIMES = 10000;

	static function main() {
		evalTest();
	}

	static function evalTest() {
		var blocks = new Blocks("scripts");
		println(blocks.evalFile("tests.tmp"));
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
