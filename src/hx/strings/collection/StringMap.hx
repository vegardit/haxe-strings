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

import hx.strings.internal.Macros;

/**
 * Abstract on <code>haxe.Constraints.IMap[String, V]</code>
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract StringMap<V>(haxe.Constraints.IMap<String, V>) from haxe.Constraints.IMap<String, V> to haxe.Constraints.IMap<String, V> {

    inline
    public function new() {
        this = new Map<String,V>();
    }

    @:to
    function __toMap():Map<String,V> {
        return cast this;
    }

    @:arrayAccess
    @:noCompletion
    @:noDoc @:dox(hide)
    inline
    public function __arrayGet(key:String):V {
        return this.get(key);
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
     * <b>IMPORTANT:</b> There is currently no native support for getting the size of a map,
     * therefore this is emulated for now by using an iterator - which impacts performance.
     *
     * <pre><code>
     * >>> new StringMap<Int>().size == 0
     * >>> function(){var m = new StringMap<Int>(); m.set("1", 1); m.set("2", 1); return m.size; }() == 2
     * </code></pre>
     */
    public var size(get, never):Int;
    inline
    function get_size():Int {
        var count = 0;
        var it = this.keys();
        while (it.hasNext()) {
            it.next();
            count++;
        }
        return count;
    }

    /**
     * <pre><code>
     * >>> new StringMap<Int>().clone() != null
     * </code></pre>
     */
    public function clone():StringMap<V> {

        if (Macros.is(this, (m:SortedStringMap<V>))) {
            return m.clone();
        }

        if (Macros.is(this, (m:OrderedStringMap<V>))) {
            return m.clone();
        }

        var clone:StringMap<V> = new StringMap<V>();
        for (k in this.keys()) {
            clone.set(k, this.get(k));
        }
        return clone;
    }

    /**
     * <pre><code>
     * >>> new StringMap<Int>().isEmpty() == true
     * >>> function(){var m = new StringMap<Int>(); m.set("1", 1); return m.isEmpty(); }() == false
     * </code></pre>
     */
    inline
    public function isEmpty():Bool {
        return !this.iterator().hasNext();
    }

    /**
     * Copies all key-value pairs from the source map into this map.
     *
     * <pre><code>
     * >>> new StringMap<Int>().setAll(null) == 0
     * </code></pre>
     *
     * @param replace if true existing key-value pairs are replaced otherwise they will be skipped
     * @return the number of copied key-value pairs
     */
    public function setAll(items:StringMap<V>, replace:Bool = true):Int {
        if (items == null)
            return 0;

        var count = 0;
        if(replace) {
            for (k in items.keys()) {
                this.set(k, items.get(k));
                count++;
            }
        } else {
            for (k in items.keys()) {
                if(!this.exists(k)) {
                    this.set(k, items.get(k));
                    count++;
                }
            }
        }
        return count;
    }

}
