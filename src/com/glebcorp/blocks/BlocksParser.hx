package com.glebcorp.blocks;

import com.glebcorp.blocks.engine.Prelude.BNumber;
import com.glebcorp.blocks.utils.RelativePrecedence;
import com.glebcorp.blocks.syntax.BinaryOp;
import com.glebcorp.blocks.Core.Atom;
import com.glebcorp.blocks.Core.Expression;
import com.glebcorp.blocks.syntax.Identifier.IDENT;
import com.glebcorp.blocks.syntax.Literal.LITERAL;
import com.glebcorp.blocks.utils.Panic.panic;

class BlocksParser extends Parser<Expression> {
	public static final ADD: BinaryFun = function(a, b) return new BNumber(a.as(BNumber).data + b.as(BNumber).data);

	public function new() {
		super([], []);
		var prec = RelativePrecedence.precedence();
		addMacro("<IDENT>", IDENT);
		addMacro("<STRING>", LITERAL);
		addMacro("<NUMBER>", LITERAL);

		binaryOp(prec("+").moreThan("MIN"), ADD);
	}

	function binaryOp(np: NamedPrec, fun: BinaryFun, rightAssoc = false) {
		if (postfix.exists(np.name)) {
			panic('Cannot redefine binary op \'${np.name}\'');
		}
		postfix[np.name] = new BinaryOp(np.prec, fun, rightAssoc);
	}

	function addMacro(value: String, atom: Atom) {
		if (prefix.exists(value)) {
			panic('Cannot redefine macro \'$value\'');
		}
		prefix[value] = atom;
	}
}
