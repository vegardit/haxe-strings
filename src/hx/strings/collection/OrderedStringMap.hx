/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.collection;

import hx.strings.StringBuilder;

/**
 * A map with String keys ordered by insertion.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract OrderedStringMap<V>(OrderedStringMapImpl<V>) from OrderedStringMapImpl<V> {

   inline
   public function new()
      this = new OrderedStringMapImpl<V>();


   @:to
   function __toStringMap():StringMap<V>
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
   public function __arrayWrite(key:String, value:V):V {
      this.set(key, value);
      return value;
   }
}


@:noDoc @:dox(hide)
@:noCompletion
class OrderedStringMapImpl<V> implements haxe.Constraints.IMap<String,V> {

   @:allow(hx.strings.collection.ValueIterator)
   var __keys:Array<String>;
   final __map = new StringMap<V>();


   public var size(get, never):Int;
   inline
   private function get_size():Int
      return __keys.length;


   inline
   public function new()
      clear();


   /**
    * <pre><code>
    * >>> ({var m = new OrderedStringMap<Int>(); m.set("1", 1); m.clear(); m; }).isEmpty() == true
    * </code></pre>
    */
   inline
   public function clear():Void {
      __keys = new Array<String>();
      __map.clear();
   }


   /**
    * <pre><code>
    * >>> new OrderedStringMap<Int>().copy() != null
    * </code></pre>
    */
   inline
   public function copy():OrderedStringMapImpl<V> {
      final clone = new OrderedStringMapImpl<V>();
      for (k => v in this)
         clone.set(k, v);
      return clone;
   }


   inline
   public function exists(key:String):Bool
      return __map.exists(key);


   /**
    * <pre><code>
    * >>> ({var m = new OrderedStringMap<Int>(); m.set("1", 10); m["1"]; }) == 10
    * </code></pre>
    */
   inline
   public function get(key:String):Null<V>
      return __map.get(key);


   /**
    * <pre><code>
    * >>> new OrderedStringMap<Int>().isEmpty() == true
    * >>> ({var m = new OrderedStringMap<Int>(); m.set("1", 1); m; }).isEmpty() == false
    * </code></pre>
    */
   inline
   public function isEmpty():Bool
      return !this.iterator().hasNext();


   inline
   public function iterator():Iterator<V>
      return new ValueIterator<V>(this);


   inline
   public function keys():Iterator<String>
      return __keys.iterator();


   inline
   public function keyValueIterator():KeyValueIterator<String, V>
      return new haxe.iterators.MapKeyValueIterator(this);


   public function remove(key:String):Bool {
      if (__map.remove(key)) {
         __keys.remove(key);
         return true;
      }
      return false;
   }


   /**
    * Sets the value for the given key. Does not change the position of the key in case it existed already.
    */
   public function set(key:String, value:V):Void {
      final isNew = !__map.exists(key);
      __map.set(key, value);
      if (isNew)
         __keys.push(key);
   }


   public function toString() : String {
      final sb = new StringBuilder("{");
      var isFirst = true;
      for(key => v in this) {
         if(isFirst)
            isFirst = false;
         else
            sb.add(", ");
         sb.add(key).add(" => ").add(v);
      }
      sb.add("}");
      return sb.toString();
   }
}


private class ValueIterator<V> {

   final map:OrderedStringMap<V>;
   var pos = -1;


   inline
   public function new(map:OrderedStringMap<V>)
      this.map = map;


   inline
   public function hasNext():Bool
      return pos + 1 < map.__keys.length;


   inline
   public function next():V
      return map.get(map.__keys[++pos]);
}
