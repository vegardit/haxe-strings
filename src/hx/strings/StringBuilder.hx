/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE.txt file for details.
 */
package hx.strings;

import haxe.Utf8;

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
 * >>> new StringBuilder("hi").addChar(12399).toString()    == "hiは"
 * >>> new StringBuilder("hi").prependChar(32).toString()   == " hi"
 * </code></pre>
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@notThreadSafe
class StringBuilder {

	var sb = new StringBuf();
    var len:Int;
    
    #if !java
    var pre:Array<String>;
    #end

	public function new(?initialContent:String) {
        if(initialContent != null) {
            add(initialContent);
            len = initialContent.length;
        } else {
            len = 0;
        }
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
        if (len > -1) 
            return len;
            
        #if java
            return sb.length;
        #elseif (flash || cs || python)
            if (pre == null || pre.length == 0) // no prepends
                return sb.length; // is UTF8 compatible
            toString(); // recalculates len variable
            return len;
        #else
            toString(); // recalculates len variable
            return len;
        #end
	}
	
	/**
     * <pre><code>
     * >>> new StringBuilder(null).add(null).toString()         == "null"
     * >>> new StringBuilder("hi").add(null).toString()         == "hinull"
     * >>> new StringBuilder("hi").add(1).toString()            == "hi1"
     * </code></pre>
     * 
	 * @return <code>this</code> for chained operations
	 */
    inline
	public function add<T>(item:T):StringBuilder {
		sb.add(item);
        
        len = -2147483647; // force full calculation
		return this;
	}
    
    /**
     * @return <code>this</code> for chained operations
     */
    public function addChar(ch:Char):StringBuilder {
        
        #if (java || flash)
            sb.addChar(ch);
        #else
            if (ch > 255) {
                var ch8 = new Utf8();
                ch8.addChar(ch);
                sb.add(ch8.toString());
            } else {
                sb.addChar(ch);
            }
        #end
        
        len++;
        return this;
    }

    /**
     * <pre><code>
     * >>> new StringBuilder("hi").addAll([1,2]).toString()     == "hi12"
     * >>> new StringBuilder("hi").addAll([1,2]).length         == 4
     * </code></pre>
     * @return <code>this</code> for chained operations
     */
	public function addAll<T>(items:Array<T>):StringBuilder {
        for (item in items) {
            sb.add(item);	
        }
        
        len = -2147483647; // force full calculation
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
            sb = new StringBuf();
        #end
        len = 0;
		return this;
	}
    
	/**
     * <pre><code>
     * >>> new StringBuilder("").isEmpty()      == true
     * >>> new StringBuilder("cat").isEmpty()   == false
     * </code></pre>
     * 
     * @return <code>true</code> if no chars/strings have been added to the string builder yet
	 */
    public function isEmpty():Bool {
        return length == 0;
    }
	
	/**
	 * adds the operating system dependent new line character(s)
     * 
     * @return <code>this</code> for chained operations
	 */
    inline
	public function newLine():StringBuilder {
		sb.add(Strings.NEW_LINE);
        
        len += Strings.NEW_LINE.length8();
		return this;
	}
    
	/**
	 * @return <code>this</code> for chained operations
	 */
	public function prepend<T>(item:T):StringBuilder {
        #if java
            untyped __java__("this.sb.b.insert(0, item)");
        #else
            if (pre == null) pre = [];
            pre.unshift(Strings.toString(item));
        #end

        len = -2147483647; // force full calculation
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
        #end
        
        len = -2147483647; // force full calculation
        return this;
    }
    
	/**
	 * @return <code>this</code> for chained operations
	 */
	public function prependAll<T>(items:Array<T>):StringBuilder {
        #if !java
            if (pre == null) pre = [];
        #end
        var i = items.length;
        while (i-- > 0) {
            var item = items[i];
            #if java
                untyped __java__("this.sb.b.insert(0, item)");
            #else
                pre.unshift(Strings.toString(item));
            #end
        }
        
        len = -2147483647; // force full calculation
		return this;
	}
	
    /**
     * @return a new string object representing the builder's content
     */
	public function toString():String {
        var str:String;
        #if java
            str = sb.toString();
        #else
            if (pre == null)
                str = sb.toString();
            else
                str = pre.join("") + sb.toString();
        #end
        
        len = str.length8();
        return str;
	}
}
