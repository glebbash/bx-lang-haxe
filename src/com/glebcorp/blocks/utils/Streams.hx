package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.Lexer.Token;
import com.glebcorp.blocks.Parser.TokenStream;

typedef Stream<T> = (?consume: Bool) -> Null<T>;

class Streams {
	public static function stream<T>(items: Array<T>): Stream<T> {
		var i = 0;
		return function(consume = true) return i < items.length ? items[consume ? i++ : i] : null;
	}
}
