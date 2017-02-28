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
    public function new() {
        this = [];
    }
    
    /**
     * the first element of the array or null if empty
     *   
     * <pre><code>
     * >>> function(){var a:StringArray = ["a", "b"]; return a.first;}() == "a"
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
     * >>> function(){var a:StringArray = ["a", "b"]; return a.last;}()  == "b"
     * </code></pre>
     */
    public var last(get, never): String;
    inline
    function get_last():String {
        return isEmpty() ? null : this[this.length - 1];
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
    public function clear() {
        while (this.length > 0)
            this.pop();
    }

    /**
     * <pre><code>
     * >>> function(){var a:StringArray = ["b", "a"]; a.sortAscending(); return a;}() == ["a", "b"]
     * </code></pre>
     */
    inline
    public function sortAscending():Void {
        haxe.ds.ArraySort.sort(this, Strings.compare);
    }
    
    /**
     * <pre><code>
     * >>> function(){var a:StringArray = ["a", "b"]; a.sortDescending(); return a;}() == ["b", "a"]
     * </code></pre>
     */
    inline
    public function sortDescending():Void {
        haxe.ds.ArraySort.sort(this, function(s1:String, s2:String) return -1 * Strings.compare(s1, s2));
    }
}
