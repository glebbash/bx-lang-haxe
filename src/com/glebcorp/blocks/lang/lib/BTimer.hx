package com.glebcorp.blocks.lang.lib;

import com.glebcorp.blocks.lang.Engine;

class BTimer extends BValue {
    final startTime = haxe.Timer.stamp();

    function passed() {
        return startTime - haxe.Timer.stamp();
    }
}