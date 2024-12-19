/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings;

import haxe.io.Eof;
import hx.doctest.DocTestRunner;
import hx.strings.Pattern;
import hx.strings.collection.OrderedStringMap;
import hx.strings.collection.SortedStringMap;
import hx.strings.collection.StringMap;
import hx.strings.spelling.checker.*;
import hx.strings.spelling.dictionary.*;
import hx.strings.spelling.trainer.*;

import hx.strings.StringMacros.multiline;

using hx.strings.Strings;

@:build(hx.doctest.DocTestGenerator.generateDocTests())
@:keep // prevent DCEing of manually created testXYZ() methods
class TestRunner extends DocTestRunner {

   public static function main() {
      var runner = new TestRunner();
      runner.runAndExit();
   }

   function new() {
      super();
   }

   public function testMultiline():Void {

      assertEquals(multiline(/*foobar*/), "foobar");

      var value = "foo";
      assertEquals(multiline(      /*${value}*/),                        "${value}");
      assertEquals(multiline("$"  /*${value} $${bar} $$$${bar}*/),       "foo ${bar} $${bar}");
      assertEquals(multiline("$$" /*$${value} ${bar} $$$${bar}*/),       "foo ${bar} $${bar}");
      assertEquals(multiline("@"   /*@{value} ${bar} $${bar} @@{bar}*/), "foo ${bar} $${bar} @{bar}");
      assertEquals(multiline("@@" /*@@{value} ${bar} $${bar} @{bar}*/),  "foo ${bar} $${bar} @{bar}");

      assertEquals(multiline("$" /*
   ${value}
   line2
*/), "foo\nline2");

      assertEquals(multiline("$" /*
   ${value}
   line2

*/), "foo\nline2\n");

      assertEquals(multiline("$", false/*
   ${value}
   line2
*/), "   foo\n   line2");

      assertEquals(multiline("$", false/*
   ${value}
   line2

*/), "   foo\n   line2\n");
    }


   public function testCharIterator_WithPrevBuffer():Void {
      var it = CharIterator.fromString("1234567890", 4);

      assertFalse(it.hasPrev());
      try { it.prev(); fail(); } catch (e:Eof) { };
      assertEquals(it.current, null);
      assertTrue(it.hasNext());

      assertEquals(it.next(), Char.of("1"));
      assertEquals(it.current, Char.of("1"));
      assertEquals(it.pos.col, 1);
      assertEquals(it.pos.index, 0);
      assertEquals(it.pos.line, 1);
      assertFalse(it.hasPrev());
      try { it.prev(); fail(); } catch (e:Eof) { };

      assertEquals(it.next(), Char.of("2"));
      assertEquals(it.current, Char.of("2"));
      assertEquals(it.pos.col, 2);
      assertEquals(it.pos.index, 1);
      assertEquals(it.pos.line, 1);
      assertTrue(it.hasPrev());

      assertEquals(it.prev(), Char.of("1"));
      assertEquals(it.next(), Char.of("2"));
      assertEquals(it.next(), Char.of("3"));
      assertEquals(it.next(), Char.of("4"));
      assertEquals(it.next(), Char.of("5"));
      assertEquals(it.next(), Char.of("6"));
      assertEquals(it.prev(), Char.of("5"));
      assertEquals(it.prev(), Char.of("4"));
      assertEquals(it.prev(), Char.of("3"));
      assertEquals(it.prev(), Char.of("2"));
      assertFalse(it.hasPrev());
      assertEquals(it.next(), Char.of("3"));
      assertEquals(it.next(), Char.of("4"));
      assertEquals(it.next(), Char.of("5"));
      assertEquals(it.next(), Char.of("6"));
      assertEquals(it.next(), Char.of("7"));
      assertEquals(it.next(), Char.of("8"));
      assertEquals(it.prev(), Char.of("7"));
      assertEquals(it.prev(), Char.of("6"));
      assertEquals(it.prev(), Char.of("5"));
      assertEquals(it.prev(), Char.of("4"));
      assertFalse(it.hasPrev());
      assertEquals(it.next(), Char.of("5"));
      assertEquals(it.next(), Char.of("6"));
      assertEquals(it.next(), Char.of("7"));
      assertEquals(it.next(), Char.of("8"));
      assertEquals(it.next(), Char.of("9"));
      assertEquals(it.next(), Char.of("0"));
      assertFalse(it.hasNext());
      try { it.next(); fail(); } catch (e:Eof) { };
      assertEquals(it.current, Char.of("0"));
   }


   public function testCharIterator_WithoutPrevBuffer():Void {
      var it = CharIterator.fromString("1234567890", 0);
      assertFalse(it.hasPrev());
      try { it.prev(); fail(); } catch (e:Eof) { };

      assertTrue(it.hasNext());
      assertEquals(it.next(), Char.of("1"));
      assertFalse(it.hasPrev());
      try { it.prev(); fail(); } catch (e:Eof) { };
   }


   public function testPattern():Void {
      {
         var p:Pattern = Pattern.compile("DOG", [IGNORE_CASE, MATCH_ALL]);
         var m:Matcher = p.matcher("dogcatdog");

         assertEquals(m.matchedPos(), { pos: 0, len: 3 });
         assertEquals(m.matches(), true);
         assertEquals(m.matched(), "dog");
         assertEquals(m.matched(0), "dog");
         try { m.matched(1); fail(); } catch (e:Dynamic) {};
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


   public function testPatternDOTALL():Void {
      {
         var p:Pattern = Pattern.compile(".+");
         var m:Matcher = p.matcher("foo\nbar");
         assertEquals("foo", m.matched(0));
      }

      #if !(cs || (js && !nodejs))
      {
         var p:Pattern = Pattern.compile(".+", [DOTALL]);
         var m:Matcher = p.matcher("foo\nbar");
         assertEquals("foo\nbar", m.matched(0));
      }
      #end
   }


   public function testString8():Void {
      var str:String8 = "test";
      assertTrue(str.endsWith("est"));
      assertTrue(str.startsWith("tes"));
   }


   public function testVersion():Void {
      var v1:Version = "1.1.1";
      var v1_B:Version = "1.1.1";
      var v2:Version = "1.1.2";

      /*
       * Testing operator overloading etc
       */
      assertEquals(v1, v1_B);
      assertTrue(v1 == v1_B);
      assertFalse(v1 != v1_B);
      assertFalse(v1 > v1_B);
      assertFalse(v1 < v1_B);
      assertTrue(v1 <= v1_B);
      assertTrue(v1 >= v1_B);

      assertEquals(v1_B, v1);
      assertTrue(v1_B == v1);
      assertFalse(v1_B != v1);
      assertFalse(v1_B > v1);
      assertFalse(v1_B < v1);
      assertTrue(v1_B <= v1);
      assertTrue(v1_B >= v1);

      assertNotEquals(v1, v2);
      assertFalse(v1 == v2);
      assertTrue(v1 != v2);
      assertFalse(v1 > v2);
      assertTrue(v1 < v2);
      assertTrue(v1 <= v2);
      assertFalse(v1 >= v2);

      assertNotEquals(v2, v1);
      assertFalse(v2 == v1);
      assertTrue(v2 != v1);
      assertTrue(v2 > v1);
      assertFalse(v2 < v1);
      assertFalse(v2 <= v1);
      assertTrue(v2 >= v1);

      /*
       * testing using Version as Map keys
       */
      var map:Map<Version, Bool> = new Map<Version, Bool>();
      map.set(v1, true);

      assertTrue(map.exists(v1));
      assertTrue(map.exists(v1_B));
      assertFalse(map.exists(v2));

      map.set(v1_B, true);

      var mapLen = 0;
      for (key in map.keys())
         mapLen++;
      assertEquals(1, mapLen);
   }


   public function testStringMapCopy() {
      var ssm:StringMap<String> = new SortedStringMap<String>();
      assertTrue(Std.isOfType(ssm, SortedStringMapImpl));
      assertTrue(Std.isOfType(ssm.copy(), SortedStringMapImpl));

      var osm:OrderedStringMap<String> = new OrderedStringMap<String>();
      assertTrue(Std.isOfType(osm, OrderedStringMapImpl));
      assertTrue(Std.isOfType(osm.copy(), OrderedStringMapImpl));
   }
}
