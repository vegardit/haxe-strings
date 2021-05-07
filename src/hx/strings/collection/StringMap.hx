/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.collection;

import hx.strings.internal.Macros;
import hx.strings.internal.Types;

/**
 * Abstract on <code>haxe.Constraints.IMap[String, V]</code>
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract StringMap<V>(haxe.Constraints.IMap<String, V>) from haxe.Constraints.IMap<String, V> to haxe.Constraints.IMap<String, V> {

   inline
   public function new()
      this = new Map<String,V>();


   @:to
   function __toMap():Map<String,V>
      return cast this;


   @:arrayAccess
   @:noCompletion
   @:noDoc @:dox(hide)
   inline
   public function __arrayGet(key:String):Null<V>
      return this.get(key);


   @:arrayAccess
   @:noCompletion
   @:noDoc @:dox(hide)
   inline
   public function __arrayWrite(k:String, v:V):V {
      this.set(k, v);
      return v;
   }

   /**
    * <b>IMPORTANT:</b> There is currently no native support for getting the size of a map,
    * therefore this is emulated for now by using an iterator - which impacts performance.
    *
    * <pre><code>
    * >>> new StringMap<Int>().size == 0
    * >>> ({var m = new StringMap<Int>(); m.set("1", 1); m.set("2", 1); m;}) == ["1" => 1, "2" => 1]
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
    * <pre><code>
    * >>> new StringMap<Int>().copy() != null
    * </code></pre>
    */
   public function copy():StringMap<V> {
      if (Types.isInstanceOf(this, SortedStringMap.SortedStringMapImpl)) {
         final m:SortedStringMap<V> = cast this;
         return m.copy();
      }

      if (Types.isInstanceOf(this, OrderedStringMap.OrderedStringMapImpl)) {
         final m:OrderedStringMap<V> = cast this;
         return m.copy();
      }

      final clone:StringMap<V> = new StringMap<V>();
      for (k => v in this)
         clone.set(k, v);
      return clone;
   }


   /**
    * <pre><code>
    * >>> new StringMap<Int>().isEmpty() == true
    * >>> ({var m = new StringMap<Int>(); m.set("1", 1); m; }).isEmpty() == false
    * </code></pre>
    */
   inline
   public function isEmpty():Bool
      return !this.iterator().hasNext();


   /**
    * Copies all key-value pairs from the source map into this map.
    *
    * <pre><code>
    * >>> ({var m = new StringMap<Int>(); m.setAll(["1" => 1, "2" => 1]); m;}) == ["1" => 1, "2" => 1]
    * >>> new StringMap<Int>().setAll(null) throws "[items] must not be null!"
    * </code></pre>
    *
    * @param replace if true existing key-value pairs are replaced otherwise they will be skipped
    * @return the number of copied key-value pairs
    */
   public function setAll(items:StringMap<V>, replace:Bool = true):Int {
      if (items == null)
         throw "[items] must not be null!";

      var count = 0;
      if(replace) {
         for (k => v in items) {
            this.set(k, v);
            count++;
         }
      } else {
         for (k => v in items) {
            if(!this.exists(k)) {
               this.set(k, v);
               count++;
            }
         }
      }
      return count;
   }
}
