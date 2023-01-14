/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.collection;

/**
 * hx.strings.collection.SortedStringMap backed sorted set implementation.
 *
 * <pre><code>
 * >>> new SortedStringSet(["", "c", "a", "b", "a"]).toArray()  ==  [ "", "a", "b", "c" ]
 * >>> new SortedStringSet(["", "c", "a", "b", "a"]).toString() == '[ "", "a", "b", "c" ]'
 * </code></pre>
 */
class SortedStringSet extends StringSet {

   final cmp:Null<String -> String -> Int>;


   public function new(?initialItems:Array<String>, ?comparator:String -> String -> Int) {
      cmp = comparator;

      @:nullSafety(Off) // TODO no idea why null-safety check fails
      super(initialItems);
   }


   override
   function _initMap():Void
      map = new SortedStringMap<Bool>(cmp);
}
