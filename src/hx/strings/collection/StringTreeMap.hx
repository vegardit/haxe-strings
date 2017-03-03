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

import haxe.ds.BalancedTree;
import hx.strings.Strings;

/**
 * A map with sorted String key.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class StringTreeMap<V> extends BalancedTree<String, V> implements haxe.Constraints.IMap<String,V> {

    var cmp:String -> String -> Int;

    /**
     * @param comparator used for sorting the String keys. Default is the UTF8 supporting Strings#compare() method
     */
    public function new(?comparator:String -> String -> Int) {
        super();
        this.cmp = comparator == null ? Strings.compare : comparator;
    }

    /**
     * <pre><code>
     * >>> function(){var m = new StringTreeMap<Int>(); m.set("1", 1); m.clear(); return m.isEmpty(); }() == true
     * </code></pre>
     */
    public function clear():Void {
        root = null;
    }
    
    /**
     * <pre><code>
     * >>> new StringTreeMap<Int>().clone() != null
     * </code></pre>
     */
    inline
	public function clone():StringTreeMap<V> {
        var clone = new StringTreeMap<V>();
		for (k in this.keys()) {
			clone.set(k, this.get(k));
		}
		return clone;
	}

    /**
     * <pre><code>
     * >>> new StringTreeMap<Int>().isEmpty() == true
     * >>> function(){var m = new StringTreeMap<Int>(); m.set("1", 1); return m.isEmpty(); }() == false
     * </code></pre>
     */
    inline
    public function isEmpty():Bool {
        return StringMaps.isEmpty(this);
    }

    inline
    override
    function compare(s1:String, s2:String):Int {
        return cmp(s1, s2);
    }
    
    /**
     * Copies all key-value pairs from the source map into this map.
     * 
     * @param replace if true existing key-value pairs are replaced otherwise they will be skipped
     * @return the number of copied key-value pairs
     */
    inline
    public function setAll(source:haxe.Constraints.IMap<String,V>, replace:Bool = true):Int {
        return StringMaps.setAll(source, this);
    }
}
