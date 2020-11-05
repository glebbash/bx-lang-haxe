package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.lexer.Lexer;
import com.glebcorp.blocks.parser.Parser;

class TokenText {
	static function text<T>(parser: Parser<T>, token: Token): String {
		return switch (token.value) {
			case Text(str): str;
			default: parser.unexpectedToken(token);
		};
	}
}
