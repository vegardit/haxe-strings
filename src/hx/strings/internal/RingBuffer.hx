/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 *
 * <pre><code>
 * >>> function(){var b = new RingBuffer<String>(2); b.add("a"); b.add("b"); b.add("c"); return b.toArray(); }() == [ "b", "c" ]
 * </code></pre>
 */
@:forward
abstract RingBuffer<V>(RingBufferImpl<V>) {

    inline
    public function new(size:Int) {
        this = new RingBufferImpl<V>(size);
    }

    @:arrayAccess
    inline
    public function get(index:Int):V {
      return this.get(index);
    }
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
        }
        else {
            bufferEndIdx++;
            length++;
        }
        buffer[bufferEndIdx] = item;
    }

    public function get(index:Int):V {
        if (index < 0 || index > bufferMaxIdx)
            throw '[index] $index is out of bound';

        var realIdx = bufferStartIdx + index;
        if (realIdx > bufferMaxIdx) {
            realIdx -= length;
        }

        return buffer[realIdx];
    }

    public function iterator(): Iterator<V> {
        return new RingBufferIterator<V>(this);
    }

    public function toArray():Array<V> {
        var arr = new Array<V>();
        for (i in this) {
            arr.push(i);
        }
        return arr;
    }
}


@:noDoc @:dox(hide)
@:noCompletion
private class RingBufferIterator<V> {

    var buff:RingBufferImpl<V>;
    var idx = -1;

    inline
    public function new(buff:RingBufferImpl<V>) {
        this.buff = buff;
    }

    inline
    public function hasNext():Bool {
        return idx + 1 < buff.length;
    }

    inline
    public function next():V {
        idx++;
        return buff.get(idx);
    }
}
