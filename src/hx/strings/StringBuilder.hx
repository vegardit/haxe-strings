/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings;

import haxe.io.BytesOutput;
import haxe.io.Output;

using hx.strings.Strings;

/**
 * An UTF-8 and fluent API supporting alternative to <code>StringBuf</code>
 * with additional functions such as <code>clear()</code>, <code>insert()</code>, <code>isEmpty()</code>
 * <br/>
 * This implementation tries to avoid the creation of intermediate String objects as much as possible.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class StringBuilder {

    var sb = new StringBuf();

    #if !(java || cs)
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
     * >>> new StringBuilder("").length                       == 0
     * >>> new StringBuilder("はい").add("は").add("い").length == 4
     * >>> new StringBuilder("ab").insert(0, "cd").insert(2, "はい").insertChar(1, 32).insertChar(4, 32).length == 8
     * </code></pre>
     *
     * @return the length of the string representation of all added items
     */
    public var length(get, null): Int;

    inline
    function get_length():Int {
        #if (java || cs)
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
        #if !(java || cs)
            len += item.length8();
        #end
        return this;
    }

    /**
     * <pre><code>
     * >>> new StringBuilder("").addChar(223).toString()     == "ß"
     * >>> new StringBuilder("hi").addChar(12399).toString() == "hiは"
     * </code></pre>
     *
     * @return <code>this</code> for chained operations
     */
    #if java inline #end
    public function addChar(ch:Char):StringBuilder {
        #if (java || flash || cs || python)
            sb.addChar(ch);
        #else
            if (ch.isAscii()) {
                sb.addChar(ch);
            }
            else
                sb.add(ch.toString());
        #end

        #if !(java || cs)
            len++;
        #end
        return this;
    }

    /**
     * <pre><code>
     * >>> new StringBuilder("hi").addAll([1,2]).toString() == "hi12"
     * >>> new StringBuilder("hi").addAll([1,2]).length     == 4
     * </code></pre>
     * @return <code>this</code> for chained operations
     */
    public function addAll(items:Array<AnyAsString>):StringBuilder {
        for (item in items) {
            sb.add(item);
            #if !(java || cs)
                len += item.length8();
            #end
        }
        return this;
    }

    /**
     * Resets the builders internal buffer
     *
     * <pre><code>
     * >>> new StringBuilder("hi").clear().add(1).toString() == "1"
     * </code></pre>
     *
     * @return <code>this</code> for chained operations
     */
    public function clear():StringBuilder {
        #if java
            untyped __java__("this.sb.b.setLength(0)");
        #elseif cs
            untyped __cs__("this.sb.b.Clear()");
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

        #if !(java || cs)
            len ++;
        #end
        return this;
    }

    /**
     * <pre><code>
     * >>> new StringBuilder("hi").insert(0, "はい").toString() == "はいhi"
     * >>> new StringBuilder("hi").insert(1, "はい").toString() == "hはいi"
     * >>> new StringBuilder("hi").insert(2, "はい").toString() == "hiはい"
     * >>> new StringBuilder("hi").insert(0, "はい").insert(1, "はい").toString() == "ははいいhi"
     * >>> new StringBuilder("hi").insert(0, "ho").insert(1, "はい").toString() == "hはいohi"
     * >>> new StringBuilder("hi").insert(0, "ho").insert(1, "はい").toString() == "hはいohi"
     * >>> new StringBuilder("hi").insert(0, "ho").insert(2, "はい").toString() == "hoはいhi"
     * >>> new StringBuilder("hi").insert(0, "ho").insert(3, "はい").toString() == "hohはいi"
     * >>> new StringBuilder("hi").insert(0, "ho").insert(4, "はい").toString() == "hohiはい"
     * >>> new StringBuilder("hi").insert(3, " ").toString() throws "[pos] must not be greater than this.length"
     * </code></pre>
     *
     * @return <code>this</code> for chained operations
     * @throws exception if pos is out-of range (i.e. < 0 or > this.length)
     */
    public function insert(pos:CharIndex, item:AnyAsString):StringBuilder {
        if (pos < 0) throw "[pos] must not be negative";
        if (pos > this.length) throw "[pos] must not be greater than this.length";

        if (pos == this.length) {
            add(item);
            return this;
        }

        #if java
            untyped __java__("this.sb.b.insert(pos, item)");
        #elseif cs
            untyped __cs__("this.sb.b.Insert(pos, item)");
        #else
            if (pos == 0) {
                if (pre == null) pre = [];
                pre.unshift(item);
                len += item.length8();
                return this;
            }

            // insert the item into the pre[] array if required
            var pre_len = 0;
            if (pre != null) {
                var i = pre.length;
                for(i in 0...pre.length) {
                    var next_pre_len = pre_len + pre[i].length8();
                    if (next_pre_len == pos) {
                        pre.insert(i + 1, item);
                        len += item.length8();
                        return this;
                    }
                    if (next_pre_len > pos) {
                        var preSplitted = pre[i].splitAt(pos - pre_len);
                        pre[i] = preSplitted[0];
                        pre.insert(i + 1, item);
                        pre.insert(i + 2, preSplitted[1]);
                        len += item.length8();
                        return this;
                    }
                    pre_len = next_pre_len;
                }
            }

            if (sb.length == 0) {
                add(item);
                return this;
            }

            var sbSplitted = sb.toString().splitAt(pos - pre_len);
            sb = new StringBuf();
            sb.add(sbSplitted[0]);
            sb.add(item);
            len += item.length8();
            sb.add(sbSplitted[1]);
        #end
        return this;
    }

    /**
     * <pre><code>
     * >>> new StringBuilder("hi").insertChar(0, Char.of("は")).toString() == "はhi"
     * >>> new StringBuilder("hi").insertChar(1, Char.of("は")).toString() == "hはi"
     * >>> new StringBuilder("hi").insertChar(2, Char.of("は")).toString() == "hiは"
     * >>> new StringBuilder("hi").insertChar(0, Char.of("は")).insertChar(1, 32).toString() == "は hi"
     * >>> new StringBuilder("hi").insert(0, "ho").insertChar(1, Char.of("は")).toString() == "hはohi"
     * >>> new StringBuilder("hi").insert(0, "ho").insertChar(1, Char.of("は")).toString() == "hはohi"
     * >>> new StringBuilder("hi").insert(0, "ho").insertChar(2, Char.of("は")).toString() == "hoはhi"
     * >>> new StringBuilder("hi").insert(0, "ho").insertChar(3, Char.of("は")).toString() == "hohはi"
     * >>> new StringBuilder("hi").insert(0, "ho").insertChar(4, Char.of("は")).toString() == "hohiは"
     * >>> new StringBuilder("hi").insertChar(3, 32).toString() throws "[pos] must not be greater than this.length"
     * </code></pre>
     *
     * @return <code>this</code> for chained operations
     * @throws exception if pos is out-of range (i.e. < 0 or > this.length)
     */
    public function insertChar(pos:CharIndex, ch:Char):StringBuilder {
        if (pos < 0) throw "[pos] must not be negative";
        if (pos > this.length) throw "[pos] must not be greater than this.length";

        if (pos == this.length) {
            addChar(ch);
            return this;
        }

        #if java
            untyped __java__("this.sb.b.insert(pos, (char)ch)");
        #elseif cs
            untyped __cs__("this.sb.b.Insert(pos, (System.Char)ch)");
        #else
            if (pos == 0) {
                if (pre == null) pre = [];
                    pre.unshift(ch);
                len++;
                return this;
            }

            // insert the char into the pre[] array if required
            var pre_len = 0;
            if (pre != null) {
                var i = pre.length;
                for(i in 0...pre.length) {
                    var next_pre_len = pre_len + pre[i].length8();
                    if (next_pre_len == pos) {
                        pre.insert(i + 1, ch);
                        len++;
                        return this;
                    }
                    if (next_pre_len > pos) {
                        var preSplitted = pre[i].splitAt(pos - pre_len);
                        pre[i] = preSplitted[0];
                        pre.insert(i + 1, ch);
                        pre.insert(i + 2, preSplitted[1]);
                        len++;
                        return this;
                    }
                    pre_len = next_pre_len;
                }
            }

            if (sb.length == 0) {
                addChar(ch);
                return this;
            }

            var sbSplitted = sb.toString().splitAt(pos - pre_len);
            sb = new StringBuf();
            sb.add(sbSplitted[0]);
            addChar(ch);
            sb.add(sbSplitted[1]);
        #end
        return this;
    }

    /**
     * <pre><code>
     * >>> new StringBuilder("hi").insertAll(0, [1,2]).toString() == "12hi"
     * >>> new StringBuilder("hi").insertAll(1, [1,2]).toString() == "h12i"
     * >>> new StringBuilder("hi").insertAll(2, [1,2]).toString() == "hi12"
     * </code></pre>
     *
     * @return <code>this</code> for chained operations
     */
    public function insertAll(pos:CharIndex, items:Array<AnyAsString>):StringBuilder {
        if (pos < 0) throw "[pos] must not be negative";
        if (pos > this.length) throw "[pos] must not be greater than this.length";

        if (pos == this.length) {
            addAll(items);
            return this;
        }

        #if (java || cs)
            var i = items.length;
            while (i-- > 0) {
                var item = items[i];
                #if java
                    untyped __java__("this.sb.b.insert(pos, item)");
                #else
                    untyped __cs__("this.sb.b.Insert(pos, item)");
                #end
            }
        #else
            if (pos == 0) {
                if (pre == null) pre = [];
                var i = items.length;
                while (i-- > 0) {
                    var item = items[i];
                    pre.unshift(item);
                    len += item.length8();
                }
                return this;
            }

            // insert the items into the pre[] array if required
            var pre_len = 0;
            if (pre != null) {
                var i = pre.length;
                for(i in 0...pre.length) {
                    var next_pre_len = pre_len + pre[i].length8();
                    if (next_pre_len == pos) {
                        var j = items.length;
                        while (j-- > 0) {
                            var item = items[j];
                            pre.insert(i + 1, item);
                            len += item.length8();
                        }
                        return this;
                    }
                    if (next_pre_len > pos) {
                        var preSplitted = pre[i].splitAt(pos - pre_len);
                        pre[i] = preSplitted[0];
                        pre.insert(i + 1, preSplitted[1]);
                        var j = items.length;
                        while (j-- > 0) {
                            var item = items[j];
                            pre.insert(i + 1, item);
                            len += item.length8();
                        }
                        return this;
                    }
                    pre_len = next_pre_len;
                }
            }

            if (sb.length == 0) {
                for(item in items)
                    add(item);
                return this;
            }

            var sbSplitted = sb.toString().splitAt(pos - pre_len);
            sb = new StringBuf();
            sb.add(sbSplitted[0]);
            for (item in items) {
                sb.add(item);
                len += item.length8();
            }
            sb.add(sbSplitted[1]);
        #end
        return this;
    }

    /**
     * <pre><code>
     * >>> ({var sb=new StringBuilder("1"); var out=sb.asOutput(); out.writeByte(Char.TWO); out.writeString("3"); sb; }).toString() == "123"
     * </code></pre>
     *
     * @return a haxe.ui.Output wrapper object around this instance
     */
    public function asOutput():Output {
        return new OutputWrapper(this);
    }

    /**
     * <pre><code>
     * >>> new StringBuilder().toString()     == ""
     * >>> new StringBuilder("").toString()   == ""
     * >>> new StringBuilder(null).toString() == ""
     * >>> new StringBuilder("hi").toString() == "hi"
     * </code></pre>
     *
     * @return a new string object representing the builder's content
     */
    #if java inline #end
    public function toString():String {
        #if (java || cs)
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

private class OutputWrapper extends Output {

    private var sb:StringBuilder;
    private var bo:BytesOutput;

    inline
    public function new(sb:StringBuilder) {
        this.sb = sb;
    }

    override
    public function flush() {
        if (bo != null && bo.length > 0) {
            sb.add(bo.getBytes().toString());
            bo == null;
        }
    }

    override
      public function writeByte(c:Int):Void {
        if (bo == null) bo = new BytesOutput();
        bo.writeByte(c);
    }

    @:dox(hide)
    override
    #if (haxe_ver >= 4.0)
    function writeString(str:String, ?encoding:haxe.io.Encoding) {
    #else
    function writeString(str:String) {
    #end
        flush();
        sb.add(str);
    }
}

