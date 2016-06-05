/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE.txt file for details.
 */
package hx.strings;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.PosInfos;
import haxe.Log;
import hx.doctest.DocTestRunner;

using hx.strings.Strings;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:build(hx.doctest.DocTestGenerator.generateDocTests())
class TestRunner extends DocTestRunner {
  
	public static function main() {
        var runner = new TestRunner();
        runner.runAndExit();
    }

    function new() { 
        super();
    }
}
