package com.glebcorp.blocks.utils;

typedef Stream<T> = (?consume: Bool) -> Null<T>;

class Streams {
	static function stream<T>(items: Array<T>): Stream<T> {
		var i = 0;
		return function(consume = true) return i < items.length ? items[consume ? i++ : i] : null;
	}
}
