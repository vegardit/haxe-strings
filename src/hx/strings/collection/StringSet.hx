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

import haxe.Constraints.IMap;

import hx.strings.collection.StringMap;
import hx.strings.internal.AnyAsString;
import hx.strings.internal.Either2;

/**
 * haxe.ds.StringMap backed set implementation.
 * 
 * Each added string is guaranteed to only be present once in the collection.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class StringSet {
    var map:StringMap<Bool>;
    
    /**
     * <pre><code>
     * >>> new StringSet().size                     == 0
     * >>> new StringSet(["a", "b", "c", "a"]).size == 3
     * </code></pre>
     */
    public var size(default, null):Int = 0;
    
    inline
    public function new(?initialItems:Either2<StringSet,Array<String>>) {
        clear();
        
        addAll(initialItems);
    }

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
        if (item == null) throw "[item] must not be null!";
        
        if (contains(item))
            return false;
            
        map.set(item, true);
        size++;
        return true;
    }
    
    /**
     * <pre><code>
     * >>> new StringSet(["", "a", "b"]).addAll(null)      == 0
     * >>> new StringSet(["", "a", "b"]).addAll(["a", "b"]) == 0
     * >>> new StringSet(["", "a", "b"]).addAll(["a", "c"]) == 1
     * >>> new StringSet(["", "a", "b"]).addAll(["c", "d"]) == 2
     * </code></pre>
     * 
     * @return number of added items
     */
    public function addAll(items:Either2<StringSet,Array<String>>):Int {
        if (items == null)
            return 0;

        var count = 0;
        switch(items.value) {
            case a(set):
                for (str in set) {
                    if (str != null && add(str)) 
                        count++;
                }
            case b(array): 
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
    public function clear():Void {
        map = new StringMap<Bool>();
    }
    
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
    public function contains(item:String):Bool {
        return item == null ? false : map.exists(item);
    }
    
    /**
     * <pre><code>
     * >>> new StringSet(          ).isEmpty() == true
     * >>> new StringSet([]        ).isEmpty() == true
     * >>> new StringSet(["a", "b"]).isEmpty() == false
     * </code></pre>
     */
    inline
    public function isEmpty():Bool {
        return size == 0;
    }
    
    /**
     * @return an Iterator over the items. No particular order is guaranteed.
     */
    inline
    public function iterator():Iterator<String> {
        return map.keys();
    }
    
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
    public function remove(item:String):Bool {
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
    public function toArray():StringArray {
        return [ for (k in map.keys()) k ];
    }
    
    /**
     * <pre><code>
     * >>> new StringSet([]).toString()     == "[]"
     * >>> new StringSet([null]).toString() == "[]"
     * >>> new StringSet([""]).toString()   == '[ "" ]'
     * >>> new StringSet(["b"]).toString()  == '[ "b" ]'
     * </code></pre>
     */
    public function toString() {
        if (size == 0) return "[]";
        return '[ "' + toArray().join('", "') + '" ]';
    }
}
