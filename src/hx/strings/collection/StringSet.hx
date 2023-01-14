/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.collection;

import hx.strings.AnyAsString;
import hx.strings.collection.StringMap;
import hx.strings.internal.Either2;


/**
 * haxe.ds.StringMap backed set implementation.
 *
 * Each added string is guaranteed to only be present once in the collection.
 */
class StringSet {

   private static final EMPTY_MAP = new StringMap<Bool>();

   var map:StringMap<Bool> = EMPTY_MAP;


   /**
    * <pre><code>
    * >>> new StringSet().size                     == 0
    * >>> new StringSet(["a", "b", "c", "a"]).size == 3
    * </code></pre>
    */
   public var size(default, null):Int = 0;


   inline
   public function new(?initialItems:Either2<StringSet,Array<String>>) {
      _initMap();

      if (initialItems != null)
         addAll(initialItems);
   }


   function _initMap():Void
      map = new StringMap<Bool>();


   /**
    * <pre><code>
    * >>> new StringSet(["", "a", "b"]).add("")   == false
    * >>> new StringSet(["", "a", "b"]).add("a")  == false
    * >>> new StringSet(["", "a", "b"]).add("c")  == true
    * >>> new StringSet(["", "a", "b"]).add(null) throws "[item] must not be null!"
    * </code></pre>
    * @return true if item was added, false if it was already present
    */
   public function add(item:AnyAsString):Bool {
      if (item == null)
         throw "[item] must not be null!";

      if (contains(item))
         return false;

      map.set(item, true);
      size++;
      return true;
   }


   /**
    * <pre><code>
    * >>> new StringSet(["", "a", "b"]).addAll(["a", "b"]) == 0
    * >>> new StringSet(["", "a", "b"]).addAll(["a", "c"]) == 1
    * >>> new StringSet(["", "a", "b"]).addAll(["c", "d"]) == 2
    * >>> new StringSet(["", "a", "b"]).addAll(null) throws "[items] must not be null!"
    * </code></pre>
    *
    * @return number of added items
    */
   public function addAll(items:Either2<StringSet,Array<String>>):Int {
      if (items == null)
         throw "[items] must not be null!";

      var count = 0;
      switch(items.value) {
         case a(set):
            if (set == null)
               return 0;
            for (str in set) {
               if (str != null && add(str))
                  count++;
            }

         case b(array):
            if (array == null)
               return 0;
            for (str in array) {
               if (str != null && add(str))
                  count++;
            }
      }
      return count;
   }


   /**
    * Empties the set.
    */
   inline
   public function clear():Void
      map.clear();


   /**
    * <pre><code>
    * >>> new StringSet(["", "a", "b"]).contains("")   == true
    * >>> new StringSet(["", "a", "b"]).contains("a")  == true
    * >>> new StringSet(["", "a", "b"]).contains("c")  == false
    * >>> new StringSet(["", "a", "b"]).contains(null) == false
    * </code></pre>
    *
    * @return true if the item is present
    */
   inline
   public function contains(item:Null<String>):Bool
      return item == null ? false : map.exists(item);


   /**
    * <pre><code>
    * >>> new StringSet(          ).isEmpty() == true
    * >>> new StringSet([]        ).isEmpty() == true
    * >>> new StringSet(["a", "b"]).isEmpty() == false
    * </code></pre>
    */
   inline
   public function isEmpty():Bool
      return size == 0;


   /**
    * @return an Iterator over the items. No particular order is guaranteed.
    */
   inline
   public function iterator():Iterator<String>
      return map.keys();


   /**
    * <pre><code>
    * >>> new StringSet(["", "a", "b"]).remove("")   == true
    * >>> new StringSet(["", "a", "b"]).remove("a")  == true
    * >>> new StringSet(["", "a", "b"]).remove("c")  == false
    * >>> new StringSet(["", "a", "b"]).remove(null) == false
    * </code></pre>
    *
    * @return true if the item was removed, false if it was not present
    */
   public function remove(item:Null<String>):Bool {
      if (item == null)
         return false;

      if (map.remove(item)) {
         size--;
         return true;
      }
      return false;
   }


   /**
    * <pre><code>
    * >>> new StringSet([]).toArray()     == [ ]
    * >>> new StringSet([null]).toArray() == [ ]
    * >>> new StringSet([""]).toArray()   == [ "" ]
    * >>> new StringSet(["a"]).toArray()  == [ "a" ]
    * </code></pre>
    */
   public function toArray():StringArray
      return [ for (k in map.keys()) k ];


   /**
    * <pre><code>
    * >>> new StringSet([]).toString()     == "[]"
    * >>> new StringSet([null]).toString() == "[]"
    * >>> new StringSet([""]).toString()   == '[ "" ]'
    * >>> new StringSet(["b"]).toString()  == '[ "b" ]'
    * </code></pre>
    */
   public function toString():String {
      if (size == 0) return "[]";
      return '[ "' + toArray().join('", "') + '" ]';
   }
}
