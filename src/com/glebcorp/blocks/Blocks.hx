package com.glebcorp.blocks;

import com.glebcorp.blocks.Lexer.LexerConfig;

class Blocks {
	public static final LEXER_CONFIG: LexerConfig = {
		singleLineCommentStart: "//",
		multilineCommentStart: "/*",
		multilineCommentEnd: "*/",
		whitespaceRegex: ~/[ \n\t\r]/,
		numberStartRegex: ~/\d/,
		numberRegex: ~/\d/,
		identifierStartRegex: ~/[a-zA-Z_]/,
		identifierRegex: ~/[a-zA-Z_0-9]/,
		operatorRegex: ~/[^ \n\t\r_a-zA-Z0-9\{\}\[\]\(\)'"]/,
		bracketed: [
			"{" => {end: "}",type: BlockBrace},
			"[" => {end: "]", type: BlockBracket},
			"(" => {end: ")", type: BlockParen},
		],
		captureComments: false,
	}
}
