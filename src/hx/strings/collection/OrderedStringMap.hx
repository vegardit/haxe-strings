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
    public function new() {
        this = new OrderedStringMapImpl<V>();
    }

    @:to
    function __toStringMap():StringMap<V> {
        return cast this;
    }

    @:arrayAccess
    @:noCompletion
    @:noDoc @:dox(hide)
    inline
    public function __arrayGet(key:String):Null<V> {
      return this.get(key);
    }

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
    var __map:StringMap<V>;

    public var size(get, never):Int;
    inline
    private function get_size():Int {
        return __keys.length;
    }

    inline
    public function new() {
        clear();
    }

    /**
     * <pre><code>
     * >>> function(){var m = new OrderedStringMap<Int>(); m.set("1", 1); m.clear(); return m.isEmpty(); }() == true
     * </code></pre>
     */
    inline
    public function clear():Void {
        __keys = new Array<String>();
        __map = new StringMap<V>();
    }

    /**
     * <pre><code>
     * >>> new OrderedStringMap<Int>().clone() != null
     * </code></pre>
     */
    inline
    public function clone():OrderedStringMapImpl<V> {
        var clone = new OrderedStringMapImpl<V>();
        for (k in this.keys()) {
            clone.set(k, this.get(k));
        }
        return clone;
    }

    inline
    public function exists(key:String):Bool {
        return __map.exists(key);
    }

    /**
     * <pre><code>
     * >>> function(){var m = new OrderedStringMap<Int>(); m.set("1", 10); return m["1"]; }() == 10
     * </code></pre>
     */
    inline
    public function get(key:String):Null<V> {
        return __map.get(key);
    }

    /**
     * <pre><code>
     * >>> new OrderedStringMap<Int>().isEmpty() == true
     * >>> function(){var m = new OrderedStringMap<Int>(); m.set("1", 1); return m.isEmpty(); }() == false
     * </code></pre>
     */
    inline
    public function isEmpty():Bool {
        return !this.iterator().hasNext();
    }

    inline
    public function iterator():Iterator<V> {
        return new ValueIterator<V>(this);
    }

    inline
    public function keys():Iterator<String> {
        return __keys.iterator();
    }

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
        var isNew = !__map.exists(key);
        __map.set(key, value);
        if (isNew)
            __keys.push(key);
    }

    public function toString() : String {
        var sb = new StringBuilder("{");
        var it = keys();
        for(key in it) {
            sb.add(key).add(" => ").add(get(key));
            if(it.hasNext())
                sb.add(", ");
        }
        sb.add("}");
        return sb.toString();
    }
}

private class ValueIterator<V> {

    var map:OrderedStringMap<V>;
    var pos = -1;

    inline
    public function new(map:OrderedStringMap<V>) {
        this.map = map;
    }

    inline
    public function hasNext():Bool {
        return pos + 1 < map.__keys.length;
    }

    inline
    public function next():V {
        return map.get(map.__keys[++pos]);
    }
}
