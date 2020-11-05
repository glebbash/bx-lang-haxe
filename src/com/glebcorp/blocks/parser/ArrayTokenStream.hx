package com.glebcorp.blocks.parser;

import com.glebcorp.blocks.lexer.Lexer;

@:tink class ArrayTokenStream implements TokenStream {
	final tokens: Array<Token> = _;
	var index = -1;

	function next(): Null<Token> {
		return index + 1 < tokens.length ? tokens[++index] : null;
    }
    
    function peek(lookahead: Int = 1): Null<Token> {
        final index = index + lookahead;
        return index >= 0 && index < tokens.length ? tokens[index] : null;
    }
}
