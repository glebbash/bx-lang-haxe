package com.glebcorp.blocks.engine;

import com.glebcorp.blocks.engine.Engine;

class BString extends BWrapper<String> {}

class BNumber extends BWrapper<Float> {}

class BBoolean extends BWrapper<Bool> {
    public static final TRUE = new BBoolean(true);
    public static final FALSE = new BBoolean(false);
}