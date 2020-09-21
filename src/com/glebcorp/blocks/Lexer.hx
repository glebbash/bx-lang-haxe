package com.glebcorp.blocks;

import com.glebcorp.blocks.utils.SyntaxError.syntaxError;

using com.glebcorp.blocks.utils.NullUtils;
using com.glebcorp.blocks.utils.ArrayUtils;

typedef Tokens = Array<Token>;
typedef CharOrEOF = Null<String>;

@:expose("TokenType")
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

@:expose("TokenValue")
enum TokenValue {
	Text(str: String);
	Tokens(tokens: Array<Tokens>);
}

@:expose("Position")
@:publicFields
@:tink class Position {
	final line: Int = _;
	final column: Int = _;

	function toString() {
		return 'line $line, col: $column';
	}
}

@:expose("Token")
@:publicFields
@:tink class Token {
	final type: TokenType = _;
	final value: TokenValue = _;
	final start: Position = _;
	final end: Position = _;

	function toString() {
		return '$type(value: $value, start: [${start.line}, ${start.column}], end: [${end.line}, ${end.column}])';
	}
}

@:expose("BracketInfo")
@:publicFields
@:tink class BracketInfo {
	final end: String = _;
	final type: TokenType = _;
}

@:expose("LexerConfig")
@:publicFields
@:structInit
class LexerConfig {
	final singleLineCommentStart: Null<String> = null;
	final multilineCommentStart: Null<String> = null;
	final multilineCommentEnd: Null<String> = null;
	final whitespaceRegex: EReg;
	final numberStartRegex: EReg;
	final numberRegex: EReg;
	final identifierStartRegex: EReg;
	final identifierRegex: EReg;
	final operatorRegex: EReg;
	final bracketed: Map<String, BracketInfo>;
	final captureComments: Bool;
}

@:expose("Lexer")
@:tink class Lexer {
	private static inline final EOF = null;

	private final config: LexerConfig = _;
	private var source: String = "";
	private var prevRow: Int = 1;
	private var prevCol: Int = 0;
	private var row: Int = 1;
	private var col: Int = 0;
	private var offset: Int = -1;
	private var char: CharOrEOF = EOF;

	public function tokenize(source: String): Array<Tokens> {
		reset(source);
		final exprs: Array<Tokens> = [];
		while (true) {
			final comments: Tokens = [];
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

	function reset(src: String) {
		source = src;
		prevRow = 1;
		prevCol = 0;
		row = 1;
		col = 0;
		offset = -1;
		char = EOF;
		next(); // read first
	}

	function exprIndented(end: CharOrEOF): Tokens {
		final startRow = row;
		final startCol = col;
		final expr: Tokens = [];
		while (true) {
			skipWhitespace(expr);

			if (char == end)
				break;

			if (row == startRow) {
				expr.push(atom());
			} else if (col > startCol) {
				final last = expr.last().unwrap();
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
				expr.push(token(TokenType.BlockIndent, () -> TokenValue.Tokens([exprIndented(end)])));
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
			return token(TokenType.String, () -> TokenValue.Text(string(char.unsafe())));
		}
		final bracketInfo = config.bracketed[char.unsafe()];
		if (bracketInfo != null) {
			return exprBracketed(bracketInfo);
		}
		if (config.numberStartRegex.match(char.unsafe())) {
			return token(TokenType.Number, () -> TokenValue.Text(sequence(config.numberRegex)));
		}
		if (config.identifierStartRegex.match(char.unsafe())) {
			return token(TokenType.Identifier, () -> TokenValue.Text(sequence(config.identifierRegex)));
		}
		return token(TokenType.Operator, () -> TokenValue.Text(sequence(config.operatorRegex)));
	}

	function exprBracketed(info: BracketInfo): Token {
		return token(info.type, () -> {
			final exprs: Array<Tokens> = [];
			next(); // skip opening bracket
			while (true) {
				final comments: Array<Token> = [];
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
		final multiEnding = ending + ending + ending;
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
		var buff = ending.charAt(0) + char;
		while (true) {
			if (skipSequence(ending)) {
				return processML(buff);
			}
			buff += nextExceptEOF();
		}
	}

	function token(type: TokenType, fun: () -> TokenValue, realStart: Null<Position> = null): Token {
		final start = realStart != null ? realStart : pos();
		return new Token(type, fun(), start, new Position(prevRow, prevCol));
	}

	function skipWhitespace(comments: Tokens) {
		while (true) {
			final start: Position = pos();
			if (config.singleLineCommentStart != null && skipSequence(config.singleLineCommentStart)) {
				if (config.captureComments) {
					comments.push(token(TokenType.Comment, () -> TokenValue.Text(sequence(~/[^\n]/)), start));
				} else {
					sequence(~/[^\n]/);
				}
			}
			if (config.multilineCommentStart != null && skipSequence(config.multilineCommentStart)) {
				if (config.captureComments) {
					comments.push(token(TokenType.Comment, () -> TokenValue.Text(skipMultilineComment()), start));
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
			final nextChar = source.substr(offset, string.length);
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
		final c = next();
		return c == EOF ? panicUnexpected() : c.unsafe();
	}

	function panicUnexpected(): Any {
		return syntaxError(char == EOF ? "Unexpected EOF" : 'Unexpected char \'$char\'', pos());
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
		return new Position(row, col);
	}

	function processML(string: String): String {
		final lines = string.split("\n");
		final lastLine = lines.pop();
		if (lastLine == null) {
			return syntaxError("Invalid multiline string", pos());
		}
		final padLength = lastLine.length - 1;
		return lines.map(l -> l.substr(padLength)).join("\n") + "\n";
	}
}
