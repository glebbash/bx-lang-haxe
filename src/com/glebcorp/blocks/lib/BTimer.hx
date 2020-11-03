package com.glebcorp.blocks.lib;

import com.glebcorp.blocks.engine.Engine.BValue;

class BTimer extends BValue {
    final startTime = haxe.Timer.stamp();

    function passed() {
        return startTime - haxe.Timer.stamp();
    }
}