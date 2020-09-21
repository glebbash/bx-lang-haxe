package com.glebcorp.blocks;

import com.glebcorp.blocks.syntax.Call;
import com.glebcorp.blocks.syntax.DoAndAssign;
import com.glebcorp.blocks.syntax.UnaryOp;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.utils.RelativePrecedence;
import com.glebcorp.blocks.syntax.BinaryOp;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.utils.Format;
import com.glebcorp.blocks.syntax.Identifier.IDENT;
import com.glebcorp.blocks.syntax.Literal;
import com.glebcorp.blocks.syntax.Literal.LITERAL;
import com.glebcorp.blocks.syntax.ArrayAtom.ARRAY;
import com.glebcorp.blocks.syntax.Paren.PAREN;
import com.glebcorp.blocks.syntax.Object.OBJECT;
import com.glebcorp.blocks.syntax.Return.RETURN;
import com.glebcorp.blocks.syntax.Break.BREAK;
import com.glebcorp.blocks.syntax.Continue.CONTINUE;
import com.glebcorp.blocks.syntax.Yield.YIELD;
import com.glebcorp.blocks.syntax.Await.AWAIT;
import com.glebcorp.blocks.utils.Panic.panic;

using com.glebcorp.blocks.utils.NullUtils;
using com.glebcorp.blocks.BlocksParser.BValueUtils;
using com.glebcorp.blocks.BlocksParser.ExpectNo;

@:publicFields
extern class BValueUtils {
	static inline function num(val: BValue): Float {
		return val.as(BNumber).data;
	}

	static inline function bool(val: BValue): Bool {
		return val.as(BBoolean).data;
	}
}

extern class ExpectNo {
	static inline function expectNo<T>(map: Map<String, T>, key: String): Void {
		if (map.exists(key)) {
			panic('Cannot redefine \'$key\'');
		}
	}
}

@:publicFields
class BlocksParser extends Parser<Expression> {
	static extern inline function num(val: Float): BNumber {
		return new BNumber(val);
	}

	static extern inline function bool(val: Bool): BBoolean {
		return val ? BBoolean.TRUE : BBoolean.FALSE;
	}

	static function repeat(str: String, times: Int): String {
		final buff = new StringBuf();
		for (_ in 0...times) {
			buff.add(str);
		}
		return buff.toString();
	}

	static final ADD: BinaryFun = (a, b) -> {
		if (a.is(BString)) {
			return new BString(a.as(BString).data + b.toString());
		}
		return num(a.num() + b.num());
	};
	static final SUB: BinaryFun = (a, b) -> num(a.num() - b.num());
	static final MUL: BinaryFun = (a, b) -> {
		if (a.is(BString)) {
			return new BString(repeat(a.as(BString).data, Math.round(b.num())));
		}
		return num(a.num() * b.num());
	};
	static final DIV: BinaryFun = (a, b) -> num(a.num() / b.num());
	static final MOD: BinaryFun = (a, b) -> {
		if (a.is(BString)) {
			final template = a.as(BString).data;
			if (b.is(BObject)) {
				return new BString(Format.formatN(template, b.as(BObject)));
			} else {
				return new BString(Format.format(template, b.as(BArray)));
			}
		}
		return num(a.num() % b.num());
	};
	static final POW: BinaryFun = (a, b) -> num(Math.pow(a.num(), b.num()));

	function new() {
		super([], []);
		var prec = RelativePrecedence.precedence();
		
		addMacro("<IDENT>", IDENT);
		addMacro("<NUMBER>", LITERAL);
		addMacro("<STRING>", LITERAL);
		addMacro("<BLOCK_PAREN>", PAREN);
		addMacro("<BLOCK_BRACKET>", ARRAY);
		addMacro("<BLOCK_BRACE>", OBJECT);

		binaryOp(prec("+").moreThan("MIN"), ADD);
		binaryOp(prec("-").sameAs("+"), SUB);
		binaryOp(prec("*").moreThan("+"), MUL);
		binaryOp(prec("/").sameAs("*"), DIV);
		binaryOp(prec("%").sameAs("*"), MOD);
		binaryOp(prec("^").moreThan("*"), POW, true);

		// postfix["="] = new Assign(prec("=").lessThan("+")[1]);
		prec("=").lessThan("+");

		doAndAssign(prec("+=").sameAs("="), ADD);
		doAndAssign(prec("-=").sameAs("="), SUB);
		doAndAssign(prec("*=").sameAs("="), MUL);
		doAndAssign(prec("/=").sameAs("="), DIV);
		doAndAssign(prec("%=").sameAs("="), MOD);
		doAndAssign(prec("^=").sameAs("="), POW);

		binaryOp(prec("==").lessThan("+"), (a, b) -> bool(a.equals(b)));
		binaryOp(prec("!=").sameAs("=="), (a, b) -> bool(!a.equals(b)));
		binaryOp(prec(">").sameAs("=="), (a, b) -> bool(a.num() > b.num()));
		binaryOp(prec(">=").sameAs("=="), (a, b) -> bool(a.num() >= b.num()));
		binaryOp(prec("<").sameAs("=="), (a, b) -> bool(a.num() < b.num()));
		binaryOp(prec("<=").sameAs("=="), (a, b) -> bool(a.num() <= b.num()));

		binaryOp(prec("and").lessThan("=="), (a, b) -> bool(a.bool() && b.bool()));
		binaryOp(prec("or").sameAs("and"), (a, b) -> bool(a.bool() || b.bool()));

		binaryOp(prec("..").lessThan("+"), (a, b) -> new BRange(Math.round(a.num()), Math.round(b.num())));

		unaryOp("-", x -> num(-x.num()));
		unaryOp("+", x -> x.as(BNumber));
		unaryOp("!", x -> bool(!x.bool()));

		postfix["<BLOCK_PAREN>"] = new Call(prec("<CALL>").moreThan("^").prec);
		// postfix.set("<BLOCK_BRACKET>", element(prec("<ELEM>").sameAs("<CALL>")[1]));
		// postfix.set("<BLOCK_INDENT>", INDENT);

		// postfix.set("is", is(prec("is").sameAs("+")[1]));

		// postfix.set(".", dot(prec(".").moreThan("^")[1]));
		// postfix.set("::", doubleSemi(prec("::").sameAs(".")[1]));

		addMacro("true", new ConstLiteral(BBoolean.TRUE));
		addMacro("false", new ConstLiteral(BBoolean.FALSE));

		// addMacro("let", define(false));
		// addMacro("const", define(true));

		// addMacro("if", IF);

		// addMacro("while", WHILE);
		// addMacro("for", FOR);
		addMacro("break", BREAK);
		addMacro("continue", CONTINUE);

		// addMacro("fun", FUN);
		addMacro("return", RETURN);

		// addMacro("gen", GEN);
		addMacro("yield", YIELD);

		// addMacro("async", ASYNC);
		addMacro("await", AWAIT);

		// addMacro("export", EXPORT);
		// addMacro("import", IMPORT);
	}

	function doAndAssign(np: NamedPrec, fun: BinaryFun) {
		postfix.expectNo(np.name);
		postfix[np.name] = new DoAndAssign(np.prec, fun);
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
