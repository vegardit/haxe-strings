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
package hx.strings;

import haxe.Utf8;
import haxe.io.Eof;
import haxe.io.Input;

import hx.strings.Strings.CharPos;
import hx.strings.internal.AnyAsString;
import hx.strings.internal.Bits;
import hx.strings.internal.TriState;

using hx.strings.Strings;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class CharIterator {

    var index = -1;
    var line = 0;
    var col = 0;
    var currChar = -1;

    /**
     * <pre><code>
     * >>> CharIterator.fromString(null).hasNext()          == false
     * >>> CharIterator.fromString("").hasNext()            == false
     * >>> CharIterator.fromString("cat").hasNext()         == true
     * >>> CharIterator.fromString("cat").next().toString() == 'c'
     * >>> CharIterator.fromString("はい").next().toString() == 'は'
     * </code></pre>
     */
    inline
    public static function fromString(chars:AnyAsString):CharIterator {
        if (chars == null) return NullCharIterator.INSTANCE;
        return new StringCharIterator(chars);
    }

    /**
     * <pre><code>
     * >>> CharIterator.fromArray(null).hasNext()                           == false
     * >>> CharIterator.fromArray(Strings.toChars("")).hasNext()            == false
     * >>> CharIterator.fromArray(Strings.toChars("cat")).hasNext()         == true
     * >>> CharIterator.fromArray(Strings.toChars("cat")).next().toString() == 'c'
     * >>> CharIterator.fromArray(Strings.toChars("はい")).next().toString() == 'は'
     * </code></pre>
     */
    inline
    public static function fromArray(chars:Array<Char>):CharIterator {
        if (chars == null) return NullCharIterator.INSTANCE;
        return new ArrayCharIterator(chars);
    }

    /**
     * <pre><code>
     * >>> CharIterator.fromInput(null).hasNext()          == false
     * >>> CharIterator.fromInput(new haxe.io.StringInput("")).hasNext()            == false
     * >>> CharIterator.fromInput(new haxe.io.StringInput("cat")).hasNext()         == true
     * >>> CharIterator.fromInput(new haxe.io.StringInput("cat")).next().toString() == 'c'
     * >>> CharIterator.fromInput(new haxe.io.StringInput("はい")).next().toString() == 'は'
     * </code></pre>
     *
     * Read characters from an ASCII or Utf8-encoded input.
     */
    inline
    public static function fromInput(chars:Input):CharIterator {
        if (chars == null) return NullCharIterator.INSTANCE;
        return new InputCharIterator(chars);
    }

    /**
     * <pre><code>
     * >>> CharIterator.fromIterator(null).hasNext()                                      == false
     * >>> CharIterator.fromIterator(Strings.toChars("").iterator()).hasNext()            == false
     * >>> CharIterator.fromIterator(Strings.toChars("cat").iterator()).hasNext()         == true
     * >>> CharIterator.fromIterator(Strings.toChars("cat").iterator()).next().toString() == 'c'
     * >>> CharIterator.fromIterator(Strings.toChars("はい").iterator()).next().toString() == 'は'
     * </code></pre>
     */
    inline
    public static function fromIterator(chars:Iterator<Char>):CharIterator {
        if (chars == null) return NullCharIterator.INSTANCE;
        return new IteratorCharIterator(chars);
    }

    public var pos(get, never):CharPos;
    inline function get_pos() return new CharPos(index, line, col);

    public function hasNext():Bool throw "Not implemented";

    /**
     * Returns the next character from the input sequence.
     *
     * @throws haxe.io.Eof if no more characters are available
     */
    @:final
    public function next():Char {
        if (!hasNext())
            throw new Eof();

        if (currChar == Char.LF || currChar < 0) {
            line++;
            col=0;
        }

        index++;
        col++;
        currChar = getChar();
        return currChar;
    }

    /**
     * @return the char at the current position
     */
    function getChar():Char throw "Not implemented" ;
}


@:noDoc @:dox(hide)
private class NullCharIterator extends CharIterator {

    public static var INSTANCE = new NullCharIterator();

    function new() {}

    override
    inline
    public function hasNext():Bool {
        return false;
    }
}

@:noDoc @:dox(hide)
private class ArrayCharIterator extends CharIterator {
    var chars:Array<Char>;
    var charsMaxIndex:Int;

    inline
    public function new(chars:Array<Char>) {
        this.chars = chars;
        charsMaxIndex = chars.length -1;
    }

    override
    inline
    public function hasNext():Bool {
        return index < charsMaxIndex;
    }

    override
    inline
    function getChar(): Char {
        return chars[index];
    }
}

@:noDoc @:dox(hide)
private class IteratorCharIterator extends CharIterator {
    var chars:Iterator<Char>;

    public function new(chars:Iterator<Char>) {
        this.chars = chars;
    }

    override
    inline
    public function hasNext():Bool {
        return chars.hasNext();
    }

    override
    inline
    function getChar(): Char {
        return chars.next();
    }
}

@:noDoc @:dox(hide)
private class InputCharIterator extends CharIterator {
    var byteIndex = 0;
    var input:Input;
    var currCharIndex = -1;
    var nextChar:Char;
    var nextCharAvailable = TriState.UNKNOWN;

    public function new(chars:Input) {
        this.input = chars;
    }

    override
    inline
    public function hasNext():Bool {
        if (nextCharAvailable == UNKNOWN) {
            try {
                nextChar = readUtf8Char();
                nextCharAvailable = TRUE;
            } catch (ex:haxe.io.Eof) {
                nextCharAvailable = FALSE;
            }
        }
        return nextCharAvailable == TRUE;
    }

    override
    inline
    function getChar(): Char {
        if(index != currCharIndex) {
            currCharIndex = index;
            nextCharAvailable = UNKNOWN;
            return nextChar;
        }
        return currChar;
    }

    /**
     * http://www.fileformat.info/info/unicode/utf8.htm
     * @throws exception if an unexpected byte was found
     */
    inline
    function readUtf8Char():Char {
        var byte1 = input.readByte();
        byteIndex++;
        if (byte1 <= 127)
            return byte1;

        /*
         * determine the number of bytes composing this UTF char
         * and clear the control bits from the first byte.
         */
        byte1 = Bits.clearBit(byte1, 8);
        byte1 = Bits.clearBit(byte1, 7);
        var totalBytes = 2;

        var isBit6Set = Bits.getBit(byte1, 6);
        var isBit5Set = false;
        if(isBit6Set) {
            byte1 = Bits.clearBit(byte1, 6);
            totalBytes++;

            isBit5Set = Bits.getBit(byte1, 5);
            if(isBit5Set) {
                byte1 = Bits.clearBit(byte1, 5);
                totalBytes++;

                if (Bits.getBit(byte1, 4))
                    throw "Valid UTF-8 byte expected at position [$byteIndex] but found byte with value [$byte]!";
            }
        }

        var result:Int = (byte1 << 6*(totalBytes-1));

        /*
         * read the second byte
         */
        var byte2 = readUtf8MultiSequenceByte();
        result += (byte2 << 6*(totalBytes-2));

        /*
         * read the third byte
         */
        if(isBit6Set) {
            var byte3 = readUtf8MultiSequenceByte();
            result += (byte3 << 6*(totalBytes-3));

            /*
             * read the fourth byte
             */
            if(isBit5Set) {
                var byte4 = readUtf8MultiSequenceByte();
                result += (byte4 << 6*(totalBytes-4));
            }
        }

        // UTF8-BOM marker http://unicode.org/faq/utf_bom.html#bom4
        if (index == 0 && result == 65279)
            return readUtf8Char();

        return result;
    }

    inline
    function readUtf8MultiSequenceByte():Int {
        var byte = input.readByte();
        byteIndex++;

        if (!Bits.getBit(byte, 8))
            throw "Valid UTF-8 multi-sequence byte expected at position [$byteIndex] but found byte with value [$byte]!";

        if (Bits.getBit(byte, 7))
            throw "Valid UTF-8 multi-sequence byte expected at position [$byteIndex] but found byte with value [$byte]!";

        return Bits.clearBit(byte, 8);
    }
}

@:noDoc @:dox(hide)
private class StringCharIterator extends CharIterator {
    var chars:String;
    var charsMaxIndex:Int;

    public function new(chars:String) {
        this.chars = chars;
        charsMaxIndex = chars.length8() - 1;
    }

    override
    inline
    public function hasNext():Bool {
        return index < charsMaxIndex;
    }

    override
    inline
    function getChar(): Char {
        return Strings._charCodeAt8Unsafe(chars, index);
    }
}
