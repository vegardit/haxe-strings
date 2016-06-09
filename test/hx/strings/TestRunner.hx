/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE.txt file for details.
 */
package hx.strings;

import hx.doctest.DocTestRunner;

import hx.strings.Pattern;

using hx.strings.Strings; // to use static extensions in doctests

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:build(hx.doctest.DocTestGenerator.generateDocTests("src", ".*"))
@:keep
class TestRunner extends DocTestRunner {
  
	public static function main() {
        var runner = new TestRunner();
        runner.runAndExit();
    }

    function new() {
        super();
    }
    
    public function testPattern():Void {
        
        {
            var p:Pattern = Pattern.compile("DOG", [CASE_INSENSITIVE, MATCH_ALL]);
            var m:Matcher = p.matcher("dogcatdog");

            assertEquals(m.matchedPos(), { pos: 0, len: 3 });
            assertEquals(m.matches(), true);
            assertEquals(m.matched(), "dog");
            assertEquals(m.matched(0), "dog");
            try { m.matched(1);     fail(); } catch (e:Dynamic) {};
            assertEquals(m.map(function(m) return "cat"), "catcatcat");
        }

        {
            var p:Pattern = Pattern.compile("(D(.)G)", [CASE_INSENSITIVE, MATCH_ALL]);
            var m:Matcher = p.matcher("dOgcatdAg");

            assertEquals(m.matchedPos(), { pos: 0, len: 3 });
            assertEquals(m.matches(), true);
            assertEquals(m.matched(), "dOg");
            assertEquals(m.matched(0), "dOg");
            assertEquals(m.matched(1), "dOg");
            assertEquals(m.matched(2), "O");
            try { m.matched(3);     fail(); } catch (e:Dynamic) { };
            var i = 0;
            assertEquals(m.map(function(m) {
                i++;
                if(i==1) assertEquals(m.matchedPos(), { pos: 0, len: 3 });
                if(i==2) assertEquals(m.matchedPos(), { pos: 6, len: 3 });
                return "cat"; }
            ), "catcatcat");
        }

        {
            var p:Pattern = Pattern.compile("DOG", [CASE_INSENSITIVE, MATCH_ALL]);
            var m:Matcher = p.matcher("cowcatcow");

            try { m.matchedPos(); fail(); } catch (e:Dynamic) {};
            assertEquals(m.matches(), false);
            try { m.matched();      fail(); } catch (e:Dynamic) { };
            try { m.matchedPos(); fail(); } catch (e:Dynamic) { };
            try { m.matched(0);     fail(); } catch (e:Dynamic) {};
            assertEquals(m.map(function(m) return "cat"), "cowcatcow");
        }
    
        {
            var p:Pattern = Pattern.compile("DOG", [CASE_INSENSITIVE]);
            var m:Matcher = p.matcher("dogcatdog");

            assertEquals(m.matchedPos(), { pos: 0, len: 3 });
            assertEquals(m.matches(), true);
            assertEquals(m.matched(), "dog");
            assertEquals(m.matched(0), "dog");
            assertEquals(m.map(function(m) return "cat"), "catcatdog");
        }
    }
}
