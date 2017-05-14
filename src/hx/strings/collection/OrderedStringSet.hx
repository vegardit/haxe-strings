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

import haxe.ds.StringMap;

import hx.strings.internal.Either2;

/**
 * hx.strings.collection.OrderedStringMap backed set implementation that maintains insertion order.
 *
 * <pre><code>
 * >>> new OrderedStringSet(["", "c", "a", "b", "a"]).toArray()  ==  [ "", "c", "a", "b" ]
 * >>> new OrderedStringSet(["", "c", "a", "b", "a"]).toString() == '[ "", "c", "a", "b" ]'
 * </code></pre>
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class OrderedStringSet<V> extends StringSet {

    inline
    public function new(?initialItems:Either2<StringSet,Array<String>>, ?comparator:String -> String -> Int) {
        super(initialItems);
    }

    inline
    override
    public function clear():Void {
        map = new OrderedStringMap<Bool>();
    }
}
