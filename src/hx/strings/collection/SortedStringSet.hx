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

/**
 * hx.strings.collection.StringTree backed sorted set implementation.
 * 
 * <pre><code>
 * >>> new SortedStringSet(["", "c", "a", "b", "a"]).toArray()  ==  [ "", "a", "b", "c" ]
 * >>> new SortedStringSet(["", "c", "a", "b", "a"]).toString() == '[ "", "a", "b", "c" ]'
 * </code></pre>
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class SortedStringSet extends StringSet {

    var cmp:String -> String -> Int;
    
    public function new(?initialItems:Array<String>, ?comparator:String -> String -> Int) {
        cmp = comparator;
        super(initialItems);
    }
    
    override
    public function clear():Void {
        map = new StringTreeMap<Bool>(cmp);
    }
}
