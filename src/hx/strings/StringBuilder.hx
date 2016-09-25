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
package hx.strings;

import haxe.Utf8;
import hx.strings.internal.AnyAsString;

using hx.strings.Strings;

/**
 * An UTF-8 and fluent API supporting alternative to <code>StringBuf</code>
 * 
 * <pre><code>
 * >>> new StringBuilder().toString()                       == ""
 * >>> new StringBuilder("").toString()                     == ""
 * >>> new StringBuilder(null).toString()                   == ""
 * >>> new StringBuilder("hi").toString()                   == "hi"
 * >>> new StringBuilder("hi").prepend(1).toString()        == "1hi"
 * >>> new StringBuilder("hi").prepend(1).toString()        == "1hi"
 * >>> new StringBuilder("hi").prependAll([1,2]).toString() == "12hi"
 * >>> new StringBuilder("").addChar(223).toString()        == "ß"
 * >>> new StringBuilder("hi").addChar(12399).toString()    == "hiは"
 * >>> new StringBuilder("hi").prependChar(32).toString()   == " hi"
 * </code></pre>
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@notThreadSafe
class StringBuilder {

    var sb = new StringBuf();
    
    #if !java
    var pre:Array<String> = null;
    var len:Int = 0;
    #end

    inline
    public function new(?initialContent:AnyAsString) {
        if (initialContent != null) 
            add(initialContent);
    }
    
    /**
     * <b>Important:</b> Invocation may result in temporary string object generation during invocation
     * on platforms except Java.
     * 
     * <pre><code>
     * >>> new StringBuilder("").length                         == 0
     * >>> new StringBuilder("はい").add("は").add("い").length   == 4
     * </code></pre>
     * 
     * @return the length of the string representation of all added items
     */
    public var length(get, null): Int;

    inline
    function get_length():Int {
        #if java
            return sb.length;
        #else
            return len;
        #end
    }
    
    /**
     * <pre><code>
     * >>> new StringBuilder(null).add(null).toString() == "null"
     * >>> new StringBuilder("hi").add(null).toString() == "hinull"
     * >>> new StringBuilder("hi").add(1).toString()    == "hi1"
     * </code></pre>
     * 
     * @return <code>this</code> for chained operations
     */
    inline
    public function add(item:AnyAsString):StringBuilder {
        sb.add(item);
        #if !java
        len += item.length8();
        #end
        return this;
    }
    
    /**
     * @return <code>this</code> for chained operations
     */
    #if java inline #end
    public function addChar(ch:Char):StringBuilder {       
        #if (java || flash || cs || python)
            sb.addChar(ch);
        #else
            if (ch.isAscii()) {
                sb.addChar(ch);
            } else {
                var ch8 = new Utf8();
                ch8.addChar(ch);
                sb.add(ch8.toString());
            }
        #end
        
        #if !java
        len++;
        #end
        return this;
    }

    /**
     * <pre><code>
     * >>> new StringBuilder("hi").addAll([1,2]).toString()     == "hi12"
     * >>> new StringBuilder("hi").addAll([1,2]).length         == 4
     * </code></pre>
     * @return <code>this</code> for chained operations
     */
    public function addAll(items:Array<AnyAsString>):StringBuilder {
        for (item in items) {
            sb.add(item);    
            #if !java
            len += item.length8();
            #end
        }
        return this;
    }
    
    /**
     * Resets the builders internal buffer
     * 
     * <pre><code>
     * >>> new StringBuilder("hi").clear().add(1).toString()    == "1"
     * </code></pre>
     * 
     * @return <code>this</code> for chained operations
     */
    public function clear():StringBuilder {
        #if java
            untyped __java__("this.sb.b.setLength(0)");
        #else
            pre = null;
            sb = new StringBuf();
            len = 0;
        #end
        return this;
    }
    
    /**
     * <pre><code>
     * >>> new StringBuilder("").isEmpty()    == true
     * >>> new StringBuilder("cat").isEmpty() == false
     * </code></pre>
     * 
     * @return <code>true</code> if no chars/strings have been added to the string builder yet
     */
    inline
    public function isEmpty():Bool {
        return length == 0;
    }
    
    /**
     * adds the "\n" new line character
     * 
     * @return <code>this</code> for chained operations
     */
    inline
    public function newLine():StringBuilder {
        sb.add(Strings.NEW_LINE_NIX);
        
        #if !java
        len ++;
        #end
        return this;
    }
    
    /**
     * @return <code>this</code> for chained operations
     */
    public function prepend(item:AnyAsString):StringBuilder {
        #if java
            untyped __java__("this.sb.b.insert(0, item)");
        #else
            if (pre == null) pre = [];
            pre.unshift(item);
            len += item.length8();
        #end
        return this;
    }

    /**
     * @return <code>this</code> for chained operations
     */
    public function prependChar(ch:Char):StringBuilder {
        #if java
            untyped __java__("this.sb.b.insert(0, (char)ch)");
        #else
            if (pre == null) pre = [];
            pre.unshift(ch);
            len++;
        #end
        return this;
    }
    
    /**
     * @return <code>this</code> for chained operations
     */
    public function prependAll(items:Array<AnyAsString>):StringBuilder {
        #if !java
            if (pre == null) pre = [];
        #end
        var i = items.length;
        while (i-- > 0) {
            var item = items[i];
            #if java
                untyped __java__("this.sb.b.insert(0, item)");
            #else
                pre.unshift(item);
                len += item.length8();
            #end
        }
        
        return this;
    }
    
    /**
     * @return a new string object representing the builder's content
     */
    #if java inline #end
    public function toString():String {
        #if java
            return sb.toString();
        #else
            if (pre == null)
                return sb.toString();
            var str = pre.join("") + sb.toString();
            clear();
            add(str);
            return str;
        #end
    }
}
