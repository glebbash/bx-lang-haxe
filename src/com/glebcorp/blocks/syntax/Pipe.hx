package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.Lexer;
import com.glebcorp.blocks.engine.Engine;
import com.glebcorp.blocks.syntax.ArrayAtom;
import com.glebcorp.blocks.syntax.Call;

@:tink class Pipe extends PrecAction {
	override function parse(parser: ExprParser, token: Token, dataArg: Expression): PipeExpr {
        final callExpr = parser.parse(prec);
        if (Std.is(callExpr, CallableExpression)) {
            return new PipeExpr(dataArg, cast(callExpr, CallableExpression));
        }
        return new PipeExpr(dataArg, new CallExpr(callExpr, new ArrayExpr([])));
	}
}

@:tink class PipeExpr implements Expression {
	final dataArg: Expression = _;
    final callExpr: CallableExpression = _;
    final args: Array<Expression> = [dataArg].concat(callExpr.args.items);

	function eval(ctx: Context): BValue {
        final args = args.map(arg -> arg.eval(ctx));
        return callExpr.call(ctx, args);
    }

	function toString(s = "", i = "") {
		return '${dataArg.toString(s, i)} >> ${callExpr.toString(s, i)}';
	}
}
