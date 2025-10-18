/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.collection;

import hx.strings.internal.Either2;

/**
 * hx.strings.collection.OrderedStringMap backed set implementation that maintains insertion order.
 *
 * <pre><code>
 * >>> new OrderedStringSet(["", "c", "a", "b", "a"]).toArray()  ==  [ "", "c", "a", "b" ]
 * >>> new OrderedStringSet(["", "c", "a", "b", "a"]).toString() == '[ "", "c", "a", "b" ]'
 * </code></pre>
 */
class OrderedStringSet extends StringSet {

   inline
   public function new(?initialItems:Either2<StringSet,Array<String>>)
      super(initialItems);


   override
   function _initMap():Void
      map = new OrderedStringMap<Bool>();
}
