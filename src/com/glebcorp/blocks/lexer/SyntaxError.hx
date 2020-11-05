package com.glebcorp.blocks.lexer;

import com.glebcorp.blocks.lexer.Lexer.Position;

@:tink class SyntaxError {
	final message: String = _;
	final position: Position = _;

	function toString() {
		return 'SyntaxError: $message\n    at $position';
	}

	static extern inline function syntaxError(message: String, position: Position): Any {
		throw new SyntaxError(message, position);
	}
}
