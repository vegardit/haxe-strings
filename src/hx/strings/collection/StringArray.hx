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

import hx.strings.internal.Either2;

/**
 * Abstract of Array<String> with additional functionality.
 * 
 * <pre><code>
 * >>> new StringArray().length == 0
 * >>> function(){var a:StringArray = ["a", "b"]; return a;}().length == 2
 * </code></pre>
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract StringArray(Array<String>) from Array<String> to Array<String> {

    inline
    public function new(?initialItems:Either2<StringSet,Array<String>>) {
        this = [];
        if (initialItems != null)
            pushAll(initialItems);
    }

    /**
     * the first element of the array or null if empty
     *   
     * <pre><code>
     * >>> new StringArray(["a", "b"]).first == "a"
     * </code></pre>
     */
    public var first(get, never): String;
    inline
    function get_first():String {
        return isEmpty() ? null : this[0];
    }

    /**
     * the last element of the array or null if empty
     *   
     * <pre><code>
     * >>> new StringArray(["a", "b"]).last == "b"
     * </code></pre>
     */
    public var last(get, never): String;
    inline
    function get_last():String {
        return isEmpty() ? null : this[this.length - 1];
    }
    
    /**
     * <pre><code>
     * >>> new StringArray(["a", "b"]).contains("b") == true
     * >>> new StringArray(["a", "b"]).contains("c") == false
     * </code></pre>
     */
    public function contains(str:String):Bool {
        return this.indexOf(str) > -1;
    }
    
    /**
     * <pre><code>
     * >>> new StringArray().isEmpty() == true
     * >>> function(){var a:StringArray = ["a", "b"]; return a.isEmpty();}()  == false
     * </code></pre>
     */
    inline
    public function isEmpty():Bool {
        return this.length == 0;
    }
    
    /**   
     * <pre><code>
     * >>> function(){var a:StringArray = ["a", "b"]; a.clear(); return a;}().length == 0
     * </code></pre>
     */
    inline
    public function clear():Void {
        while (this.length > 0)
            this.pop();
    }
    
    public function pushAll(items:Either2<StringSet,Array<String>>):Void {
        if (items == null)
            return;

        switch(items.value) {
            case a(set):
                for (str in set) {
                    this.push(str);
                }
            case b(array): 
                for (str in array) {
                    this.push(str);
                }
        }
    }
    
    /**
     * <pre><code>
     * >>> function(){var a:StringArray = ["b", "a"]; a.sortAscending(); return a;}() == ["a", "b"]
     * </code></pre>
     */
    inline
    public function sortAscending():Void {
        this.sort(Strings.compare);
    }
    
    /**
     * <pre><code>
     * >>> function(){var a:StringArray = ["a", "b"]; a.sortDescending(); return a;}() == ["b", "a"]
     * </code></pre>
     */
    inline
    public function sortDescending():Void {
        this.sort(function(s1:String, s2:String) return -1 * Strings.compare(s1, s2));
    }
}
