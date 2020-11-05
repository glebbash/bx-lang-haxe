package com.glebcorp.blocks.parser;

@:tink class ArrayTokenStream implements TokenStream {
	final tokens: Array<Token> = _;
	final index = 0;

	function next() {
		return index < items.lenth ? items[i++] : null;
    }
    
    function peek(lookahead: Int): Token {
        final index = index + lookahead;
        return index < items.lenth ? items[i++] : null
    }
}
