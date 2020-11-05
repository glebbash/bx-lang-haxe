package com.glebcorp.blocks.parser;

import com.glebcorp.blocks.lexer.Lexer;

interface TokenStream {
	function next(): Null<Token>;

	function peek(lookahead: Int = 1): Null<Token>;
}