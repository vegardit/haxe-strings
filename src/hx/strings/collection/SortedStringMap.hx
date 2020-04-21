/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.collection;

import haxe.ds.BalancedTree;

import hx.strings.Strings;

/**
 * A map with sorted String keys.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract SortedStringMap<V>(SortedStringMapImpl<V>) from SortedStringMapImpl<V> {

   inline
   public function new(?comparator:String -> String -> Int)
      this = new SortedStringMapImpl<V>(comparator);


   @:to
   function __toStringMap():StringMap<V>
      return cast this;


   @:arrayAccess
   @:noCompletion
   @:noDoc @:dox(hide)
   public inline function __arrayGet(key:String)
      return this.get(key);


   @:arrayAccess
   @:noCompletion
   @:noDoc @:dox(hide)
   inline
   public function __arrayWrite(key:String, value:V):V {
      this.set(key, value);
      return value;
   }
}


/**
 * <pre><code>
 * >>> ({var m = new SortedStringMap<Int>(); m.set("1", 1); m.clear(); m; }).isEmpty() == true
 * </code></pre>
 */
@:noDoc @:dox(hide)
@:noCompletion
class SortedStringMapImpl<V> extends BalancedTree<String, V> implements haxe.Constraints.IMap<String,V> {

   final cmp:String -> String -> Int;


   /**
    * <b>IMPORTANT:</b> There is currently no native support for getting the size of a map,
    * therefore this is emulated for now by using an iterator - which impacts performance.
    *
    * <pre><code>
    * >>> new SortedStringMap<Int>().size == 0
    * >>> ({var m = new SortedStringMap<Int>(); m.set("1", 1); m.set("2", 1); m; }).size == 2
    * </code></pre>
    */
   public var size(get, never):Int;
   inline
   function get_size():Int {
      var count = 0;
      final it = this.keys();
      while (it.hasNext()) {
         it.next();
         count++;
      }
      return count;
   }


   /**
    * @param comparator used for sorting the String keys. Default is the UTF8 supporting Strings#compare() method
    */
   public function new(?comparator:(String, String) -> Int) {
      super();
      if (comparator == null)
         #if jvm
            // TODO workaround for java.lang.IllegalAccessError: no such method: hx.strings.Strings.compare(String,String)int/invokeStatic
            this.cmp = (s1, s2) -> Strings.compare(s1,s2);
         #else
            this.cmp = Strings.compare;
         #end
      else
      this.cmp = comparator;

   }


   @:arrayAccess
   @:noCompletion
   @:noDoc @:dox(hide)
   inline
   public function __arrayWrite(k:String, v:V):V {
      this.set(k, v);
      return v;
   }


   /**
    * <pre><code>
    * >>> new SortedStringMap<Int>().copy() != null
    * </code></pre>
    */
   override
   public function copy():SortedStringMapImpl<V> {
      final clone = new SortedStringMapImpl<V>();
      for (k => v in this)
         clone.set(k, v);
      return clone;
   }


   inline
   override
   function compare(s1:String, s2:String):Int
      return cmp(s1, s2);


   /**
    * <pre><code>
    * >>> ({var m = new SortedStringMap<Int>(); m.set("1", 10); m["1"]; }) == 10
    * </code></pre>
    */
   @:arrayAccess
   override
   public function get(key:String):Null<V>
       return super.get(key);


   /**
    * <pre><code>
    * >>> new SortedStringMap<Int>().isEmpty() == true
    * >>> ({var m = new SortedStringMap<Int>(); m.set("1", 1); m; }).isEmpty() == false
    * </code></pre>
    */
   inline
   public function isEmpty():Bool
      return !this.iterator().hasNext();


   /**
    * Copies all key-value pairs from the source map into this map.
    *
    * @param replace if true existing key-value pairs are replaced otherwise they will be skipped
    * @return the number of copied key-value pairs
    */
   inline
   public function setAll(source:StringMap<V>, replace:Bool = true):Int {
      final m:StringMap<V> = this;
      return m.setAll(source, replace);
   }
}
