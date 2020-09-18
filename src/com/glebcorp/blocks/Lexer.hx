package com.glebcorp.blocks;

import com.glebcorp.blocks.utils.SyntaxError.syntaxError;

using com.glebcorp.blocks.utils.Unwrap;


typedef Tokens = Array<Token>;
typedef CharOrEOF = Null<String>;

@:expose
enum TokenType {
	String;
	Number;
	Identifier;
	Operator;
	BlockParen;
	BlockBrace;
	BlockBracket;
	BlockIndent;
	Comment;
}

@:expose
enum TokenValue {
	Text(str: String);
	Tokens(tokens: Array<Tokens>);
}

@:expose
@:structInit
class Position {
	public final line: Int;
	public final column: Int;
}

@:expose
@:structInit
class Token {
	public final type: TokenType;
	public final start: Position;
	public final end: Position;
	public final value: TokenValue;

	function toString() {
		return '$type(value: $value, start: [${start.line}, ${start.column}], end: [${start.line}, ${start.column}])';
	}
}

@:expose
@:structInit
class BracketInfo {
	public final end: String;
	public final type: TokenType;
}

@:expose
@:structInit
class LexerConfig {
	public final singleLineCommentStart: Null<String> = null;
	public final multilineCommentStart: Null<String> = null;
	public final multilineCommentEnd: Null<String> = null;
	public final whitespaceRegex: EReg;
	public final numberStartRegex: EReg;
	public final numberRegex: EReg;
	public final identifierStartRegex: EReg;
	public final identifierRegex: EReg;
	public final operatorRegex: EReg;
	public final bracketed: Map<String, BracketInfo>;
	public final captureComments: Bool;
}

@:expose
class Lexer {
	private static inline final EOF = null;

	private var config: LexerConfig;
	private var source: String = "";
	private var prevRow: Int = 1;
	private var prevCol: Int = 0;
	private var row: Int = 1;
	private var col: Int = 0;
	private var offset: Int = -1;
	private var char: CharOrEOF = EOF;

	public function new(config: LexerConfig) {
		this.config = config;
	}

	public function tokenize(source: String): Array<Tokens> {
		reset(source);
		var exprs: Array<Tokens> = [];
		while (true) {
			var comments: Tokens = [];
			skipWhitespace(comments);
			if (comments.length > 0) {
				exprs.push(comments);
			}
			if (char == EOF) {
				break;
			}
			exprs.push(exprIndented(EOF));
		}
		return exprs;
	}

	function reset(source: String) {
		this.source = source;
		prevRow = 1;
		prevCol = 0;
		row = 1;
		col = 0;
		offset = -1;
		char = EOF;
		next(); // read first
	}

	function exprIndented(end: CharOrEOF): Tokens {
		var startRow = row;
		var startCol = col;
		var expr: Tokens = [];
		while (true) {
			skipWhitespace(expr);

			if (char == end)
				break;

			if (row == startRow) {
				expr.push(atom());
			} else if (col > startCol) {
				var last = expr[expr.length - 1];
				if (last.type == TokenType.BlockIndent) {
					switch (last.value) {
						case Tokens(tokens):
							tokens.push(exprIndented(end));
						default:
							panicUnexpected();
					}
					continue;
				}
				if (last.end.line == row) {
					expr.push(atom());
					continue;
				}
				expr.push(token(TokenType.BlockIndent, function() return TokenValue.Tokens([exprIndented(end)])));
			} else {
				break;
			}
		}
		return expr;
	}

	function atom(): Token {
		if (EOF == char || ")" == char || "]" == char || "}" == char) {
			return panicUnexpected();
		}
		if ('"' == char || "'" == char) {
			return token(TokenType.String, function() return TokenValue.Text(string(char.unsafe())));
		}
		var bracketInfo = config.bracketed[char.unsafe()];
		if (bracketInfo != null) {
			return exprBracketed(bracketInfo);
		}
		if (config.numberStartRegex.match(char.unsafe())) {
			return token(TokenType.Number, function() return TokenValue.Text(sequence(config.numberRegex)));
		}
		if (config.identifierStartRegex.match(char.unsafe())) {
			return token(TokenType.Identifier, function() return TokenValue.Text(sequence(config.identifierRegex)));
		}
		return token(TokenType.Operator, function() return TokenValue.Text(sequence(config.operatorRegex)));
	}

	function exprBracketed(info: BracketInfo): Token {
		return token(info.type, function() {
			var exprs: Array<Tokens> = [];
			next(); // skip opening bracket
			while (true) {
				var comments: Array<Token> = [];
				skipWhitespace(comments);
				if (comments.length > 0) {
					exprs.push(comments);
				}
				exprs.push(exprIndented(info.end));

				if (char == info.end) {
					break;
				}
			}
			next(); // skip ending bracket
			return TokenValue.Tokens(exprs);
		});
	}

	function sequence(regex: EReg): String {
		var buff = char.unsafe();
		while (true) {
			next();
			if (char != EOF && regex.match(char.unsafe())) {
				buff += char.unsafe();
			} else {
				break;
			}
		}
		return buff;
	}

	function string(ending: String): String {
		var multiEnding = ending + ending + ending;
		if (skipSequence(multiEnding + "\n")) {
			return multilineString(multiEnding);
		}
		var buff = ending;
		while (true) {
			nextExceptEOF();
			if (char == "\\") {
				nextExceptEOF();
				if (char == "\n") {
					syntaxError("String not closed", pos());
				} else {
					buff += escapeChar(char.unsafe());
					continue;
				}
			} else if (char == "\n") {
				syntaxError("String not closed", pos());
			} else if (char == ending) {
				next();
				buff += ending;
				return buff;
			}
			buff += char.unsafe();
		}
	}

	function multilineString(ending: String): String {
		var buffer = ending.charAt(0) + char;
		while (true) {
			if (skipSequence(ending)) {
				return processML(buffer);
			}
			buffer += nextExceptEOF();
		}
	}

	function token(type: TokenType, fun: () -> TokenValue, realStart: Null<Position> = null): Token {
		var start = realStart != null ? realStart : pos();
		return {
			type: type,
			value: fun(),
			start: start,
			end: {
				line: this.prevRow,
				column: this.prevCol
			},
		};
	}

	function skipWhitespace(comments: Tokens) {
		while (true) {
			var start: Position = pos();
			if (config.singleLineCommentStart != null && skipSequence(config.singleLineCommentStart)) {
				if (config.captureComments) {
					comments.push(token(TokenType.Comment, function() return TokenValue.Text(sequence(~/[^\n]/)), start));
				} else {
					sequence(~/[^\n]/);
				}
			}
			if (config.multilineCommentStart != null && skipSequence(config.multilineCommentStart)) {
				if (config.captureComments) {
					comments.push(token(TokenType.Comment, function() return TokenValue.Text(skipMultilineComment()), start));
				} else {
					skipMultilineComment();
				}
			}
			if (char == EOF || !isWhitespace(char.unsafe())) {
				break;
			}
			next();
		}
	}

	function skipSequence(string: String): Bool {
		if (string.length == 1) {
			if (char == string) {
				next();
				return true;
			}
		} else if (offset + string.length <= source.length) {
			var nextChar = source.substr(offset, string.length);
			if (nextChar == string) {
				for (_ in 0...string.length) {
					next();
				}
				return true;
			}
		}
		return false;
	}

	function skipMultilineComment(): String {
		var buff = "";
		var opened = 1;
		while (true) {
			if (skipSequence(config.multilineCommentStart.unsafe())) {
				opened++;
				buff += config.multilineCommentStart.unsafe();
			}
			if (skipSequence(config.multilineCommentEnd.unsafe())) {
				if (--opened == 0) {
					break;
				}
				buff += config.multilineCommentEnd.unsafe();
			}
			buff += char.unsafe();
			next();
			if (char == EOF) {
				panicUnexpected();
			}
		}
		return buff;
	}

	function isWhitespace(char: String): Bool {
		return config.whitespaceRegex.match(char);
	}

	function next(): CharOrEOF {
		if (offset == source.length - 1) {
			prevRow = row;
			prevCol = col;
			char = EOF;
			return char;
		}
		offset++;
		char = source.charAt(offset);
		prevRow = row;
		prevCol = col;
		if (char == "\n") {
			row++;
			col = 0;
		} else {
			col++;
		}
		return char;
	}

	function nextExceptEOF(): String {
		var c = next();
		return c == EOF ? panicUnexpected() : c.unsafe();
	}

	function panicUnexpected(): Any {
		return syntaxError(char == EOF ? "Unexpected EOF" : 'Unexpected char \'${char}\'', pos());
	}

	function escapeChar(char: String): String {
		return switch (char) {
			case '"', "'": char;
			case "n": "\n";
			case "t": "\t";
			default: syntaxError("Invalid escape sequence", pos());
		}
	}

	function pos(): Position {
		return {line: row, column: col};
	}

	function processML(string: String): String {
		var lines = string.split("\n");
		var lastLine = lines.pop();
		if (lastLine == null) {
			return syntaxError("Invalid multiline string", pos());
		}
		var padLength = lastLine.length - 1;
		return lines.map(function(l) return l.substr(padLength)).join("\n") + "\n";
	}
}
