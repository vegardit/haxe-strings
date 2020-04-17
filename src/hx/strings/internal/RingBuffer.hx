/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 *
 * <pre><code>
 * >>> ({var b = new RingBuffer<String>(2); b.add("a"); b.add("b"); b.add("c"); b; }).toArray() == [ "b", "c" ]
 * </code></pre>
 */
@:forward
abstract RingBuffer<V>(RingBufferImpl<V>) {

   inline
   public function new(size:Int)
      this = new RingBufferImpl<V>(size);


   @:arrayAccess
   inline
   public function get(index:Int):V
      return this.get(index);
}


@:noDoc @:dox(hide)
@:noCompletion
private class RingBufferImpl<V> {

   #if flash
   // using Array instead of Vector as workaround for https://github.com/HaxeFoundation/haxe/issues/6529
   var buffer:Array<V>;
   #else
   var buffer:haxe.ds.Vector<V>;
   #end
   var bufferStartIdx = 0;
   var bufferEndIdx = -1;
   var bufferMaxIdx:Int;


   public var length(default, null):Int = 0;
   public var size(default, null):Int;


   public function new(size:Int) {
      if (size < 1)
         throw "[size] must be > 0";

      #if flash
      buffer = [];
      #else
      buffer = new haxe.ds.Vector<V>(size);
      #end
      this.size = size;
      bufferMaxIdx = size - 1;
   }


   public function add(item:V) {
      if (length == size) {
         bufferEndIdx = bufferStartIdx;
         bufferStartIdx++;
         if (bufferStartIdx > bufferMaxIdx)
            bufferStartIdx = 0;
      } else {
         bufferEndIdx++;
         length++;
      }
      buffer[bufferEndIdx] = item;
   }


   public function get(index:Int):V {
      if (index < 0 || index > bufferMaxIdx)
         throw '[index] $index is out of bound';

      var realIdx = bufferStartIdx + index;
      if (realIdx > bufferMaxIdx)
         realIdx -= length;
      return buffer[realIdx];
   }


   public function iterator(): Iterator<V>
      return new RingBufferIterator<V>(this);


   public function toArray():Array<V> {
      var arr = new Array<V>();
      for (i in this)
         arr.push(i);
      return arr;
   }
}


@:noDoc @:dox(hide)
@:noCompletion
private class RingBufferIterator<V> {

   var buff:RingBufferImpl<V>;
   var idx = -1;


   inline
   public function new(buff:RingBufferImpl<V>)
      this.buff = buff;


   inline
   public function hasNext():Bool
      return idx + 1 < buff.length;


   inline
   public function next():V {
      idx++;
      return buff.get(idx);
   }
}
