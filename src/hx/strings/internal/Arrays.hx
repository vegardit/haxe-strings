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
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:dox(hide)
@:noCompletion
class Arrays {
    
    /**
     * <pre><code>
     * >>> Arrays.unique(["1", "1", "2"]) == ["1", "2"]
     * </code></pre>
     */
    public static function unique<T>(items:Array<T>):Array<T> {
        var result = new Array<T>();
        for (i in items) {
            if (result.indexOf(i) == -1)
                result.push(i);
        }
        return result;
    }
    
    inline
    public static function first<T>(items:Array<T>):T {
        return (items == null || items.length == 0) ? null :items[0];
    }
    
    inline
    public static function last<T>(items:Array<T>):T {
        return (items == null || items.length == 0) ? null :items[items.length - 1];
    }
}
