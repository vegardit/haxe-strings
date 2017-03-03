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

using hx.strings.collection.StringMaps;

/**
 * Utility functions for maps with String keys.
 * 
 * This class can be used as <a href="http://haxe.org/manual/lf-static-extension.html">static extension</a>.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class StringMaps {
    
    /**
     * <pre><code>
     * >>> StringMaps.clone(new Map<String, Int>()) != null
     * </code></pre>
     */
	public static function clone<V>(map:haxe.Constraints.IMap<String,V>):haxe.Constraints.IMap<String,V> {
        var clone:haxe.Constraints.IMap<String,V> = Std.is(map, StringTreeMap) ? new StringTreeMap<V>() : new Map<String, V>();
		for (k in map.keys()) {
			clone.set(k, map.get(k));
		}
		return clone;
	}
    
    /**
     * <pre><code>
     * >>> StringMaps.isEmpty(new Map<String, Int>()) == true
     * >>> function(){var m = new Map<String, Int>(); m.set("1", 1); return StringMaps.isEmpty(m); }() == false
     * </code></pre>
     */
    inline
    public static function isEmpty<V>(map:haxe.Constraints.IMap<String,V>):Bool {
        return !map.iterator().hasNext();
    }

    /**
     * Copies all key-value pairs from the source map into this map.
     * 
     * <pre><code>
     * >>> StringMaps.setAll(null, null) == 0
     * >>> StringMaps.setAll(new Map<String, Int>(), null) throws "[target] must not be null"
     * </code></pre>
     * 
     * @param replace if true existing key-value pairs are replaced otherwise they will be skipped
     * @return the number of copied key-value pairs
     */
    public static function setAll<V>(source:haxe.Constraints.IMap<String,V>, target:haxe.Constraints.IMap<String,V>, replace:Bool = true):Int {
        if (source == null)
            return 0;

        if (target == null)
            throw "[target] must not be null";

        var count = 0;
        if(replace) {
            for (k in source.keys()) {
                target.set(k, source.get(k));
                count++;
            }
        } else {
            for (k in source.keys()) {
                if(!target.exists(k)) {
                    target.set(k, source.get(k));
                    count++;
                }
            }
        }
        return count;
    }
}
