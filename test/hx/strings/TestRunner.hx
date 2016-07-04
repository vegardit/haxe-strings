/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package hx.strings;

import hx.doctest.DocTestRunner;
import hx.strings.Pattern;
import hx.strings.collection.StringSet;
import hx.strings.spelling.checker.*;
import hx.strings.spelling.dictionary.*;
import hx.strings.spelling.trainer.*;

using hx.strings.Strings;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:build(hx.doctest.DocTestGenerator.generateDocTests("src", ".*\\.hx"))
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
            var p:Pattern = Pattern.compile("DOG", [IGNORE_CASE, MATCH_ALL]);
            var m:Matcher = p.matcher("dogcatdog");

            assertEquals(m.matchedPos(), { pos: 0, len: 3 });
            assertEquals(m.matches(), true);
            assertEquals(m.matched(), "dog");
            assertEquals(m.matched(0), "dog");
            try { m.matched(1);     fail(); } catch (e:Dynamic) {};
            assertEquals(m.map(function(m) return "cat"), "catcatcat");
        }

        {
            var p:Pattern = Pattern.compile("(D(.)G)", [IGNORE_CASE, MATCH_ALL]);
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
            var p:Pattern = Pattern.compile("DOG", [IGNORE_CASE, MATCH_ALL]);
            var m:Matcher = p.matcher("cowcatcow");

            try { m.matchedPos(); fail(); } catch (e:Dynamic) {};
            assertEquals(m.matches(), false);
            try { m.matched();      fail(); } catch (e:Dynamic) { };
            try { m.matchedPos(); fail(); } catch (e:Dynamic) { };
            try { m.matched(0);     fail(); } catch (e:Dynamic) {};
            assertEquals(m.map(function(m) return "cat"), "cowcatcow");
        }
    
        {
            var p:Pattern = Pattern.compile("DOG", [IGNORE_CASE]);
            var m:Matcher = p.matcher("dogcatdog");

            assertEquals(m.matchedPos(), { pos: 0, len: 3 });
            assertEquals(m.matches(), true);
            assertEquals(m.matched(), "dog");
            assertEquals(m.matched(0), "dog");
            assertEquals(m.map(function(m) return "cat"), "catcatdog");
        }
        
        {
            var p:Pattern = Pattern.compile("DOG", [IGNORE_CASE]);
            var m:Matcher = p.matcher("dogcatdog");
            
            var matches = new Array<String>();
            m.iterate(function(m) matches.push(m.matched()));
            assertEquals(matches, ["dog", "dog"]);
        }
    }
}
