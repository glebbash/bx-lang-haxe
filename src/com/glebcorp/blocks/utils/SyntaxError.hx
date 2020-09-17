package com.glebcorp.blocks.utils;

import com.glebcorp.blocks.Lexer.Position;

class SyntaxError {
    var message: String;
    var position: Position;

    function new(message: String, position: Position) {
        this.message = message;
        this.position = position;
    }

    function toString() {
        return 'Syntax error ${message}\n\tat ${position}';
    }

    public static function syntaxError(message: String, position: Position): Any {
        throw new SyntaxError(message, position);
    }
}