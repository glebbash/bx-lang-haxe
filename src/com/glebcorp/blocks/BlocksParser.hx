package com.glebcorp.blocks;

import com.glebcorp.blocks.syntax.UnaryOp;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.utils.RelativePrecedence;
import com.glebcorp.blocks.syntax.BinaryOp;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.syntax.Identifier.IDENT;
import com.glebcorp.blocks.syntax.Literal.LITERAL;
import com.glebcorp.blocks.utils.Panic.panic;

using com.glebcorp.blocks.utils.NullUtils;
using com.glebcorp.blocks.BlocksParser.BValueUtils;
using com.glebcorp.blocks.BlocksParser.ExpectNo;

extern class BValueUtils {
	public static inline function num(val: BValue): Float {
		return val.as(BNumber).data;
	}

	public static inline function bool(val: BValue): Bool {
		return val.as(BBoolean).data;
	}
}

extern class ExpectNo {
	public static inline function expectNo<T>(map: Map<String, T>, key: String): Void {
		if (map.exists(key)) {
			panic('Cannot redefine \'${key}\'');
		}
	}
}

class BlocksParser extends Parser<Expression> {
	public static extern inline function num(val: Float): BNumber {
		return new BNumber(val);
	}

	public static extern inline function bool(val: Bool): BBoolean {
		return val ? BBoolean.TRUE : BBoolean.FALSE;
	}

	public static final ADD: BinaryFun = (a, b) -> return num(a.num() + b.num());
	public static final SUB: BinaryFun = (a, b) -> return num(a.num() - b.num());
	public static final MUL: BinaryFun = (a, b) -> return num(a.num() * b.num());
	public static final DIV: BinaryFun = (a, b) -> return num(a.num() / b.num());
	public static final MOD: BinaryFun = (a, b) -> return num(a.num() % b.num());
	public static final POW: BinaryFun = (a, b) -> return num(Math.pow(a.num(), b.num()));

	public function new() {
		super([], []);
		var prec = RelativePrecedence.precedence();
		addMacro("<IDENT>", IDENT);
		addMacro("<NUMBER>", LITERAL);
		addMacro("<STRING>", LITERAL);

		binaryOp(prec("+").moreThan("MIN"), ADD);
		binaryOp(prec("-").sameAs("+"), SUB);
		binaryOp(prec("*").moreThan("+"), MUL);
		binaryOp(prec("/").sameAs("*"), DIV);
		binaryOp(prec("%").sameAs("*"), MOD);
		binaryOp(prec("^").moreThan("*"), POW);
		binaryOp(prec("==").lessThan("+"), (a, b) -> bool(a.equals(b)));
		binaryOp(prec("!=").sameAs("=="), (a, b) -> bool(!a.equals(b)));
		binaryOp(prec(">").sameAs("=="), (a, b) -> bool(a.num() > b.num()));
		binaryOp(prec(">=").sameAs("=="), (a, b) -> bool(a.num() >= b.num()));
		binaryOp(prec("<").sameAs("=="), (a, b) -> bool(a.num() < b.num()));
		binaryOp(prec("<=").sameAs("=="), (a, b) -> bool(a.num() <= b.num()));
		binaryOp(prec("and").lessThan("=="), (a, b) -> bool(a.bool() && b.bool()));
		binaryOp(prec("or").sameAs("and"), (a, b) -> bool(a.bool() || b.bool()));

		unaryOp("-", x -> num(-x.num()));
		unaryOp("+", x -> x.as(BNumber));
		unaryOp("!", x -> bool(!x.bool()));
	}

	function binaryOp(np: NamedPrec, fun: BinaryFun, rightAssoc = false) {
		postfix.expectNo(np.name);
		postfix[np.name] = new BinaryOp(np.name, np.prec, fun, rightAssoc);
	}

	function unaryOp(name: String, fun: UnaryFun) {
		addMacro(name, new UnaryOp(name, fun));
	}

	function addMacro(name: String, atom: Atom) {
		prefix.expectNo(name);
		prefix[name] = atom;
	}
}
