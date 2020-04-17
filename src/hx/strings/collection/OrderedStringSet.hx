/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.collection;

import haxe.ds.StringMap;

import hx.strings.internal.Either2;

/**
 * hx.strings.collection.OrderedStringMap backed set implementation that maintains insertion order.
 *
 * <pre><code>
 * >>> new OrderedStringSet(["", "c", "a", "b", "a"]).toArray()  ==  [ "", "c", "a", "b" ]
 * >>> new OrderedStringSet(["", "c", "a", "b", "a"]).toString() == '[ "", "c", "a", "b" ]'
 * </code></pre>
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class OrderedStringSet<V> extends StringSet {

   inline
   public function new(?initialItems:Either2<StringSet,Array<String>>)
      super(initialItems);


   inline
   override
   public function _initMap():Void
      map = new OrderedStringMap<Bool>();
}
