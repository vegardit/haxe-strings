/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.collection;

import hx.strings.internal.Either2;

/**
 * Abstract of Array<String> with additional functionality.
 *
 * <pre><code>
 * >>> new StringArray().length == 0
 * >>> ({var a:StringArray = ["a", "b"]; a;}).length == 2
 * </code></pre>
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract StringArray(Array<String>) from Array<String> to Array<String> {

   inline
   public function new(?initialItems:Either2<StringSet,Array<String>>) {
      this = [];
      if (initialItems != null)
         pushAll(initialItems);
   }

   /**
    * the first element of the array or null if empty
    *
    * <pre><code>
    * >>> new StringArray(["a", "b"]).first == "a"
    * </code></pre>
    */
   public var first(get, never):Null<String>;
   inline
   function get_first():Null<String>
      return isEmpty() ? null : this[0];


   /**
    * the last element of the array or null if empty
    *
    * <pre><code>
    * >>> new StringArray(["a", "b"]).last == "b"
    * </code></pre>
    */
   public var last(get, never):Null<String>;
   inline
   function get_last():Null<String>
      return isEmpty() ? null : this[this.length - 1];


   /**
    * <pre><code>
    * >>> new StringArray(["a", "b"]).contains("b") == true
    * >>> new StringArray(["a", "b"]).contains("c") == false
    * </code></pre>
    */
   public function contains(str:String):Bool
        return this.indexOf(str) > -1;


   /**
    * <pre><code>
    * >>> new StringArray().isEmpty() == true
    * >>> ({var a:StringArray = ["a", "b"]; a.isEmpty();})  == false
    * </code></pre>
    */
   inline
   public function isEmpty():Bool
        return this.length == 0;


   /**
    * <pre><code>
    * >>> ({var a:StringArray = ["a", "b"]; a.clear(); a;}).length == 0
    * </code></pre>
    */
   inline
   public function clear():Void {
      while (this.length > 0)
         this.pop();
   }


   public function pushAll(items:Either2<StringSet,Array<String>>):Void {
      if (items == null)
         throw "[items] must not be null!";

      switch(items.value) {
         case a(set):
            for (str in set)
               this.push(str);

         case b(array):
            for (str in array)
               this.push(str);
      }
   }


   /**
    * <pre><code>
    * >>> ({var a:StringArray = ["b", "a"]; a.sortAscending(); a;}) == ["a", "b"]
    * </code></pre>
    */
   inline
   public function sortAscending():Void
      this.sort(Strings.compare);


   /**
    * <pre><code>
    * >>> ({var a:StringArray = ["a", "b"]; a.sortDescending(); a;}) == ["b", "a"]
    * </code></pre>
    */
   inline
   public function sortDescending():Void
      this.sort((s1, s2) -> -1 * Strings.compare(s1, s2));
}
