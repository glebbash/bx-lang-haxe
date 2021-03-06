package com.glebcorp.blocks.parser;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.lexer.SyntaxError.syntaxError;

using com.glebcorp.blocks.utils.NullUtils;
using com.glebcorp.blocks.utils.TokenText;

interface PrefixParser<E, T: E> {
	function parse(parser: Parser<E>, token: Token): T;
}

interface PostfixParser<E, T: E> {
	function precedence(parser: Parser<E>): Float;

	function parse(parser: Parser<E>, token: Token, expr: E): T;
}

@:structInit
class TokenCondition {
	final type: Null<TokenType> = null;
	final value: Null<String> = null;
	final complexType: Null<String> = null;
}

class Parser<E> {
	private static final START_TOKEN = new Token(TokenType.Comment, TokenValue.Text(""), new Position(1, 1), new Position(1, 1));
	private static final EMPTY_STREAM: ArrayTokenStream = stream([]);

	final prefix: Map<String, PrefixParser<E, E>>;
	final postfix: Map<String, PostfixParser<E, E>>;
	var tokens: ArrayTokenStream = EMPTY_STREAM;

	function new(pre, post, ?tokens) {
		prefix = pre;
		postfix = post;
		this.tokens = tokens == null ? EMPTY_STREAM : tokens;
	}

	static function stream(tokens: Tokens) {
		return new ArrayTokenStream(tokens);
	}

	function subParser(expr: Tokens): Parser<E> {
		return new Parser(prefix, postfix, stream(expr));
	}

	function parseAll(exprs: Array<Tokens>): Array<E> {
		return exprs.map(expr -> {
			tokens = stream(expr);
			return parseToEnd();
		});
	}

	function parse(precedence = 0.0): E {
		var token = next();
		var expr = expectPrefixParser(token).parse(this, token);

		while (precedence < tokenPrecedence()) {
			token = next();
			expr = expectPostfixParser(token).parse(this, token, expr);
		}

		return expr;
	}

	function parseToEnd(precedence = 0.0): E {
		final expr = parse(precedence);
		checkTrailing();
		return expr;
	}

	function checkTrailing() {
		final next = tokens.peek();
		if (next != null) {
			unexpectedToken(next);
		}
	}

	function tokenPrecedence(): Float {
		final token = tokens.peek();
		if (token == null) {
			return 0;
		}

		final parser = getPostfixParser(token);
		if (parser == null) {
			return 0;
		}

		return parser.precedence(this);
	}

	function getPostfixParser(token: Token) {
		return postfix[getTokenType(token)];
	}

	function expectPostfixParser(token: Token): PostfixParser<E, E> {
		final parser = getPostfixParser(token);
		if (parser == null) {
			return syntaxError("Invalid operator: " + token.value, token.start);
		}
		return parser;
	}

	function getPrefixParser(token: Token) {
		return prefix[getTokenType(token)];
	}

	function expectPrefixParser(token: Token): PrefixParser<E, E> {
		final parser = getPrefixParser(token);
		if (parser == null) {
			return syntaxError("Invalid prefix operator: " + token.value, token.start);
		}
		return parser;
	}

	function expect(cond: TokenCondition): Token {
		if (!nextIs(cond)) {
			unexpectedToken(tokens.peek());
		}
		return next();
	}

	function nextIs(cond: TokenCondition): Bool {
		final token = tokens.peek();
		if (token == null) {
			return false;
		}
		if (cond.type != null) {
			return token.type == cond.type;
		}
		if (cond.value != null) {
			return switch (token.value) {
				case TokenValue.Text(val): val == cond.value;
				default: false;
			};
		}
		return getTokenType(token) == cond.complexType.unwrap();
	}

	function next(): Token {
		final token = tokens.next();
		if (token == null) {
			return unexpectedToken(token);
		}
		return token;
	}

	function expectNext(): Token {
		final token = tokens.peek();
		if (token == null) {
			return unexpectedToken(token);
		}
		return token;
	}

	function getTokenType(token: Token): String {
		return switch (token.type) {
			case String: "<STRING>";
			case Number: "<NUMBER>";
			case BlockParen: "<BLOCK_PAREN>";
			case BlockBrace: "<BLOCK_BRACE>";
			case BlockBracket: "<BLOCK_BRACKET>";
			case BlockIndent: "<BLOCK_INDENT>";
			case Operator: this.text(token);
			case Identifier:
				final val = this.text(token);
				if (prefix.exists(val) || postfix.exists(val)) {
					val;
				} else {
					"<IDENT>";
				}
			default: unexpectedToken(token);
		};
	}

	function unexpectedToken(token: Null<Token>): Any {
		if (token == null) {
			var prevToken = tokens.peek(-1);
			if (prevToken == null) {
				return syntaxError("Unexpected end of expression", new Position(-1, -1));
			}
 			return syntaxError("Unexpected end of expression", prevToken.unwrap().end);
		}
		return syntaxError('Unexpected token: \'${getTokenType(token)}\'', token.start);
	}
}
