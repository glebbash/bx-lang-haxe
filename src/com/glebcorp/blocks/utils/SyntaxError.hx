package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.Lexer.Position;

@:tink class SyntaxError {
	final message: String = _;
	final position: Position = _;

	function toString() {
		return 'Syntax error $message\n\tat $position';
	}

	static extern inline function syntaxError(message: String, position: Position): Any {
		throw new SyntaxError(message, position);
	}
}
