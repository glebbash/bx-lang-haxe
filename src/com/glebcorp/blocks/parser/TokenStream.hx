package com.glebcorp.blocks.parser;

interface TokenStream {
	function next(): Null<Token>;

	function peek(lookahead: Int): Null<Token>;
}