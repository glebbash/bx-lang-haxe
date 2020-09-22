package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Scope;

interface Exportable {
	function export(exports: Set<String>): Void;
}

class Export {
    
}