/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
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
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class SortedStringSet extends StringSet {

   var cmp:String -> String -> Int;


   public function new(?initialItems:Array<String>, ?comparator:String -> String -> Int) {
      cmp = comparator;
      super(initialItems);
   }


   inline
   override
   public function clear():Void
      map = new SortedStringMap<Bool>(cmp);
}
