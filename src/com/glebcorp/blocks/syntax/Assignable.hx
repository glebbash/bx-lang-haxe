package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.Core;
import com.glebcorp.blocks.engine.Engine.BValue;

interface Assignable {
    function isValid(): Bool;

    function isDefinable(): Bool;

    function define(ctx: Context, value: BValue, constant: Bool): Void;

    function assign(ctx: Context, value: BValue): Void;
}