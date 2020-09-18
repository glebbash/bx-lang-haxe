package com.glebcorp.blocks;

import com.glebcorp.blocks.Lexer.TokenValue;
import com.glebcorp.blocks.Lexer.Tokens;
import com.glebcorp.blocks.utils.Streams.Stream;
import com.glebcorp.blocks.utils.Streams.stream;
import com.glebcorp.blocks.Lexer.TokenType;
import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.utils.SyntaxError.syntaxError;

using com.glebcorp.blocks.utils.Unwrap;

interface PrefixParser<E, T: E> {
	function parse(parser: Parser<E>, token: Token): T;
}

interface PostfixParser<E, T: E> {
	function precedence(parser: Parser<E>): Float;

	function parse(parser: Parser<E>, token: Token, expr: E): T;
}

interface TokenCondition {
	public var type: Null<TokenType>;
	public var value: Null<String>;
	public var complexType: Null<String>;
}

class Parser<E> {
	private static final START_TOKEN: Token = {
		type: TokenType.Comment,
		value: TokenValue.Text(""),
		start: {line: 1, column: 1},
		end: {line: 1, column: 1},
	}
	private static final EMPTY_STREAM: Stream<Token> = stream([]);

	private var prevToken = START_TOKEN;

	public var prefix: Map<String, PrefixParser<E, E>>;
	public var postfix: Map<String, PostfixParser<E, E>>;
	public var nextToken: Stream<Token>;

	public function new(prefix: Map<String, PrefixParser<E, E>>, postfix: Map<String, PostfixParser<E, E>>, ?nextToken: Stream<Token>) {
		this.prefix = prefix;
		this.postfix = postfix;
		this.nextToken = nextToken == null ? EMPTY_STREAM : nextToken;
	}

	function subParser(expr: Tokens): Parser<E> {
		return new Parser(prefix, postfix, stream(expr));
	}

	public function parseAll(exprs: Array<Tokens>): Array<E> {
		return exprs.map(function(expr) {
			nextToken = stream(expr);
			return parseToEnd();
		});
	}

	public function parse(precedence = 0.0): E {
		var token = next();
		var expr = expectPrefixParser(token).parse(this, token);

		while (precedence < tokenPrecedence()) {
			var token = next();
			expr = expectPostfixParser(token).parse(this, token, expr);
		}

		return expr;
	}

	public function parseToEnd(precedence = 0.0): E {
		var expr = parse(precedence);
		checkTrailing();
		return expr;
	}

	function checkTrailing() {
		var next = nextToken(false);
		if (next != null) {
			unexpectedToken(next);
		}
	}

	function tokenPrecedence(): Float {
		var token = nextToken(false);
		if (token == null)
			return 0;

		var parser = getPostfixParser(token);
		if (parser == null)
			return 0;

		return parser.precedence(this);
	}

	function getPostfixParser(token: Token) {
		return postfix[getTokenType(token)];
	}

	function expectPostfixParser(token: Token): PostfixParser<E, E> {
		var parser = getPostfixParser(token);
		if (parser == null) {
			return syntaxError("Invalid prefix operator: " + token.value, token.start);
		}
		return parser;
	}

	function getPrefixParser(token: Token) {
		return prefix[getTokenType(token)];
	}

	function expectPrefixParser(token: Token): PrefixParser<E, E> {
		var parser = getPrefixParser(token);
		if (parser == null) {
			return syntaxError("Invalid operator: " + token.value, token.start);
		}
		return parser;
	}

	function expect(cond: TokenCondition): Token {
		if (!nextIs(cond)) {
			unexpectedToken(nextToken(false));
		}
		return next();
	}

	function nextIs(cond: TokenCondition): Bool {
		var token = nextToken(false);
		if (token == null) {
			return false;
		}
		if (cond.type != null) {
			return token.type == cond.type;
		} else if (cond.value != null) {
			return switch (token.value) {
				case TokenValue.Text(val): val == cond.value;
				default: false;
			};
		} else {
			return getTokenType(token) == cond.complexType.unwrap();
		}
	}

	function next(consume = true): Token {
		var token = nextToken(consume);
		if (token == null) {
			return unexpectedToken(token);
		}
		prevToken = token;
		return token;
	}

	function getTokenType(token: Token): String {
		return switch (token.type) {
			case TokenType.String:
				"<STRING>";
			case TokenType.Number:
				"<NUMBER>";
			case TokenType.BlockParen, TokenType.BlockBrace, TokenType.BlockBracket, TokenType.BlockIndent:
				'<${Std.string(token.type).toUpperCase()}>';
			case TokenType.Operator:
				switch (token.value) {
					case TokenValue.Text(val): val;
					default: unexpectedToken(token);
				}
			case TokenType.Identifier:
				switch (token.value) {
					case TokenValue.Text(val): prefix.exists(val) || postfix.exists(val) ? val : "<IDENT>";
					default: unexpectedToken(token);
				}
			default:
				unexpectedToken(token);
		};
	}

	public function unexpectedToken(token: Null<Token>): Any {
		return token == null ? syntaxError("Unexpected end of expression",
			this.prevToken.end) : syntaxError('Unexpected token: \'${this.getTokenType(token)}\'', token.start);
	}
}
