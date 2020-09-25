package com.glebcorp.blocks;

import com.glebcorp.blocks.syntax.Dot;
import com.glebcorp.blocks.syntax.While;
import com.glebcorp.blocks.syntax.If;
import com.glebcorp.blocks.syntax.Element;
import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.engine.Prelude;
import com.glebcorp.blocks.syntax.ArrayAtom;
import com.glebcorp.blocks.syntax.Assign;
import com.glebcorp.blocks.syntax.Await;
import com.glebcorp.blocks.syntax.BinaryOp;
import com.glebcorp.blocks.syntax.Block;
import com.glebcorp.blocks.syntax.Break;
import com.glebcorp.blocks.syntax.Call;
import com.glebcorp.blocks.syntax.Continue;
import com.glebcorp.blocks.syntax.Define;
import com.glebcorp.blocks.syntax.DoAndAssign;
import com.glebcorp.blocks.syntax.DoubleSemi;
import com.glebcorp.blocks.syntax.Export;
import com.glebcorp.blocks.syntax.Fun;
import com.glebcorp.blocks.syntax.Identifier;
import com.glebcorp.blocks.syntax.Import;
import com.glebcorp.blocks.syntax.Indent;
import com.glebcorp.blocks.syntax.Is;
import com.glebcorp.blocks.syntax.Literal;
import com.glebcorp.blocks.syntax.Object;
import com.glebcorp.blocks.syntax.Paren;
import com.glebcorp.blocks.syntax.Return;
import com.glebcorp.blocks.syntax.UnaryOp;
import com.glebcorp.blocks.syntax.Yield;
import com.glebcorp.blocks.utils.Format;
import com.glebcorp.blocks.utils.Panic.panic;
import com.glebcorp.blocks.utils.RelativePrecedence;

using com.glebcorp.blocks.BlocksParser.BValueUtils;
using com.glebcorp.blocks.BlocksParser.ExpectNo;
using com.glebcorp.blocks.utils.NullUtils;

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

		binaryOp(prec("+").moreThan("MIN"), ADD);
		binaryOp(prec("-").sameAs("+"), SUB);
		binaryOp(prec("*").moreThan("+"), MUL);
		binaryOp(prec("/").sameAs("*"), DIV);
		binaryOp(prec("%").sameAs("*"), MOD);
		binaryOp(prec("^").moreThan("*"), POW, true);

		postfix["="] = new Assign(prec("=").lessThan("+").prec);

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

		final ARRAY = new ArrayAtom();
		final IDENTIFIER = new Identifier();
		final LITERAL = new Literal();
		final OBJECT = new Object(IDENTIFIER);
		final BLOCK = new Block();

		postfix["<BLOCK_PAREN>"] = new Call(prec("<CALL>").moreThan("^").prec, ARRAY);
		postfix["<BLOCK_BRACKET>"] = new Element(prec("<ELEM>").sameAs("<CALL>").prec);
		postfix["<BLOCK_INDENT>"] = new Indent();

		postfix["is"] = new Is(prec("is").sameAs("+").prec, IDENTIFIER);

		postfix["."] = new Dot(prec(".").moreThan("^").prec, IDENTIFIER, ARRAY);
		postfix["::"] = new DoubleSemi(prec("::").sameAs(".").prec, IDENTIFIER, ARRAY);

		addMacro("<IDENT>", IDENTIFIER);
		addMacro("<NUMBER>", LITERAL);
		addMacro("<STRING>", LITERAL);
		addMacro("<BLOCK_PAREN>", new Paren());
		addMacro("<BLOCK_BRACKET>", ARRAY);
		addMacro("<BLOCK_BRACE>", OBJECT);

		addMacro("true", new ConstLiteral(BBoolean.TRUE));
		addMacro("false", new ConstLiteral(BBoolean.FALSE));

		addMacro("let", new Define(false));
		addMacro("const", new Define(true));

		addMacro("if", new If(BLOCK));

		addMacro("while", new While(BLOCK));
		// addMacro("for", FOR);
		addMacro("break", new Break());
		addMacro("continue", new Continue());

		addMacro("fun", new Fun(IDENTIFIER, ARRAY, BLOCK));
		addMacro("return", new Return());

		// addMacro("gen", GEN);
		addMacro("yield", new Yield());

		// addMacro("async", ASYNC);
		addMacro("await", new Await());

		addMacro("export", new Export());
		addMacro("import", new Import(OBJECT, IDENTIFIER));
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
