/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
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

    public function clear():Void {
        root = null;
    }
    
    inline
    override
    function compare(s1:String, s2:String):Int {
        return cmp(s1, s2);
    }
}
