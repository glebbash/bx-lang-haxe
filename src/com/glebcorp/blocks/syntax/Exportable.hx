package com.glebcorp.blocks.syntax;

import com.glebcorp.blocks.engine.Scope.Set;

interface Exportable {
    function export(exports: Set<String>): Void;
}