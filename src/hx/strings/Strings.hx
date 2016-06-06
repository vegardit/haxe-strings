/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE.txt file for details.
 */
package hx.strings;

import haxe.Int32;
import haxe.Utf8;
import haxe.crypto.Base64;
import haxe.io.Bytes;

using hx.strings.Strings;

/**
 * Utility functions for Strings with UTF-8 support and consistent behavior accross platforms. 
 * 
 * Can be used as <a href="http://haxe.org/manual/lf-static-extension.html">static extension</a>.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Strings {

    static var REGEX_ANSI_ESC = Pattern.compile(Char.ESC + "\\[[;\\d]*m", "g");
    static var REGEX_HTML_UNESCAPE = new EReg("&(#\\d+|amp|nbsp|apos|lt|gt|quot);", "g");
    static var REGEX_SPLIT_LINES = Pattern.compile("\\r?\\n", "g");
    
    #if !php
    static var REGEX_STRIP_XML_TAGS = Pattern.compile("<[!a-zA-Z\\/][^>]*>", "g");
    #end
    
    static var REGEX_IS_WINDOWS = Pattern.compile("windows", "i");
    
    public static inline var POS_NOT_FOUND:CharPos = -1;

    public static inline var NEW_LINE_NIX = "\n";
    public static inline var NEW_LINE_WIN = "\r\n";

    /**
     * new line character of the current operating system
     */
    public static var NEW_LINE(get, null):String;
    private static function get_NEW_LINE() {
        #if flash
        var os = flash.system.Capabilities.os;
        #elseif hl
        // TODO https://github.com/HaxeFoundation/haxe/issues/5314
        var os = "Windows";
        #elseif js
        var os = js.Browser.navigator.oscpu;
        #else
        var os = Sys.systemName();
        #end
        if (REGEX_IS_WINDOWS.matcher(os).matches()) {
            return NEW_LINE_WIN;
        } else {
            return NEW_LINE_NIX;
        }
    }
    
    public static inline var PATH_SEPARATOR_NIX = "/";
    public static inline var PATH_SEPARATOR_WIN = "\\";

    /**
     * path separator of the current operating system
     */
    public static var PATH_SEPARATOR(get, null):String;
    private static function get_PATH_SEPARATOR() {
        #if flash
        var os = flash.system.Capabilities.os;
        #elseif hl
        // TODO https://github.com/HaxeFoundation/haxe/issues/5314
        var os = "Windows";
        #elseif js
        var os = js.Browser.navigator.oscpu;
        #else
        var os = Sys.systemName();
        #end
        if (REGEX_IS_WINDOWS.matcher(os).matches()) {
            return PATH_SEPARATOR_WIN;
        } else {
            return PATH_SEPARATOR_NIX;
        }
    }
    
    /**
     * no bounds checking
     */
    inline
    private static function _charCodeAt8Unsafe(str:String, pos:CharPos):Char {
        #if (flash || java || cs || python)
            return str.charCodeAt(pos);
        #else
            return Utf8.charCodeAt(str, pos);
        #end
    }
    
    /**
     * no bounds checking
     */
    private static function _splitWordsUnsafe(str:String) {
        var words = new Array<String>();
        var currentWord = new StringBuilder();

        var chars = str.toChars();

        for (i in 0...chars.length) {
            var ch = chars[i];
            switch(ch) {
                case Char.MINUS, Char.UNDERSCORE, Char.SPACE:
                    if (currentWord.length > 0) {
                        words.push(currentWord.toString());
                        currentWord.clear();
                    }
                default:
                    if(ch.isAsciiPrintable()) { // skip non-printable characters
                        currentWord.addChar(ch);
                        if (ch.isUpperCase()) {
                            if (chars[i + 1].isUpperCase() && chars.length > i + 2) {
                                if(!chars[i + 2].isUpperCase()) {
                                    words.push(currentWord.toString());
                                    currentWord.clear();
                                }
                            }
                        } else {
                            if(chars[i + 1].isUpperCase()) {
                                words.push(currentWord.toString());
                                currentWord.clear();
                            }
                        }
                    }
            }
        }
        
        if (currentWord.length > 0) {
            words.push(currentWord.toString());
        }
        return words;
    }

    /**
     * <pre><code>
     * >>> Strings.ansiToHtml(null)                                  == null
     * >>> Strings.ansiToHtml("")                                    == ""
     * >>> Strings.ansiToHtml("dogcat")                              == "dogcat"
     * >>> Strings.ansiToHtml("\x1B[0m\x1B[0m")                      == ""
     * >>> Strings.ansiToHtml("\x1B[33;40mDOG\x1B[40;42mCAT")        == "<span style=\"color:yellow;background-color:black;\">DOG</span><span style=\"color:yellow;background-color:green;\">CAT</span>"
     * >>> Strings.ansiToHtml("\x1B[33;40mDOG\x1B[40;42mCAT\x1B[0m") == "<span style=\"color:yellow;background-color:black;\">DOG</span><span style=\"color:yellow;background-color:green;\">CAT</span>"
     * </code></pre>
     */
    public static function ansiToHtml(str:String, ?initialState:ANSIState):String {
        if (isEmpty(str))
            return str;
        
        var sb = new StringBuilder();
        
        if (initialState != null && initialState.isActive()) {
            sb.add("<span style=\"").add(initialState.toCSS()).add("\">");
        }

        var effectiveState = new ANSIState(initialState);
        var strLen = str.length8();
        var i = -1;
        var lookAhead = new StringBuilder();
        while (i < strLen - 1) {
            i++;
            var ch:Char = str._charCodeAt8Unsafe(i);
            if (ch == Char.ESC && i < strLen - 1 && str._charCodeAt8Unsafe(i + 1) == 91 /*[*/) { // is beginning of ANSI Escape Sequence?
                lookAhead.clear();
                var currentState = new ANSIState(effectiveState);
                var currentGraphicModeParam = 0;
                var isValidEscapeSequence = false;
                i += 1;
                while (i < strLen - 1) {
                    i++;
                    var ch2:Char = str._charCodeAt8Unsafe(i);
                    lookAhead.addChar(ch2);
                    switch (ch2) {
                        case 48: currentGraphicModeParam = currentGraphicModeParam * 10 + 0;
                        case 49: currentGraphicModeParam = currentGraphicModeParam * 10 + 1;
                        case 50: currentGraphicModeParam = currentGraphicModeParam * 10 + 2;
                        case 51: currentGraphicModeParam = currentGraphicModeParam * 10 + 3;
                        case 52: currentGraphicModeParam = currentGraphicModeParam * 10 + 4;
                        case 53: currentGraphicModeParam = currentGraphicModeParam * 10 + 5;
                        case 54: currentGraphicModeParam = currentGraphicModeParam * 10 + 6;
                        case 55: currentGraphicModeParam = currentGraphicModeParam * 10 + 7;
                        case 56: currentGraphicModeParam = currentGraphicModeParam * 10 + 8;
                        case 57: currentGraphicModeParam = currentGraphicModeParam * 10 + 9;
                        case Char.SEMICOLON: // graphic mode separator
                            currentState.setGraphicModeParameter(currentGraphicModeParam);
                            currentGraphicModeParam = 0;
                        case 109: // escape sequence terminator 'm'
                            currentState.setGraphicModeParameter(currentGraphicModeParam);
                            if (effectiveState.isActive())
                                sb.add("</span>");
                            if (currentState.isActive()) {
                                sb.add("<span style=\"").add(currentState.toCSS()).add("\">");
                            }
                            effectiveState = currentState;
                            isValidEscapeSequence = true;
                            break; // break out of the while loop
                        default:
                            // invalid character found
                            break; // break out of the while loop
                    }
                }
                if (!isValidEscapeSequence) {
                    // in case of a missing ESC sequence delimiter, we treat the whole ESC string not as an ANSI escape sequence
                    sb.addChar(Char.ESC).add('[').add(lookAhead);
                }
            } else {
                sb.addChar(ch);
            }
        }

        if (effectiveState.isActive()) {
            sb.add("</span>");
        }
        return sb.toString();
    }
    
    /**
     * <pre><code>
     * >>> Strings.appendIfMissing(null, null)   == null
     * >>> Strings.appendIfMissing(null, "")     == null
     * >>> Strings.appendIfMissing("", "")       == ""
     * >>> Strings.appendIfMissing("", " ")      == " "
     * >>> Strings.appendIfMissing("dog", null)  == "dognull"
     * >>> Strings.appendIfMissing("dog", "/")   == "dog/"
     * >>> Strings.appendIfMissing("dog/", "/")  == "dog/"
     * >>> Strings.appendIfMissing("はい", "はい") == "はい"
     * >>> Strings.appendIfMissing("はい", "は")  == "はいは"
     * </code></pre>
     */
    public static function appendIfMissing(str:String, suffix:String):String {
        if (str == null) 
            return null;

        if (str.length == 0)
            return str + suffix;
        
        if (str.endsWith(suffix))
            return str;
            
        return str + suffix;
    }

    /**
     * <pre><code>
     * >>> Strings.base64Encode(null)  == null
     * >>> Strings.base64Encode("")    == ""
     * >>> Strings.base64Encode("dog") == "ZG9n"
     * >>> Strings.base64Encode("はい") == "44Gv44GE"
     * </code></pre>
     */
    inline
    public static function base64Encode(plain:String):String {
        if (plain == null)
            return null;

        #if php
            return untyped __call__("base64_encode", plain);
        #else
            return Base64.encode(plain.toBytes());
        #end
    }
    
    /**
     * <pre><code>
     * >>> Strings.base64Decode(null)       == null
     * >>> Strings.base64Decode("")         == ""
     * >>> Strings.base64Decode("ZG9n")     == "dog"
     * >>> Strings.base64Decode("44Gv44GE") == "はい"
     * </code></pre>
     */
    inline
    public static function base64Decode(encoded:String):String {
        if (encoded == null)
            return null;

        #if php
            return untyped __call__("base64_decode", encoded);
        #else
            return Base64.decode(encoded).toString();
        #end
    }
    
    /**
     * String#charAt() variant with cross-platform UTF-8 support.
     * 
     * @param pos character position
     * 
     * <pre><code>
     * >>> Strings.charAt8(null, 0)       == ""
     * >>> Strings.charAt8("", 0)         == ""
     * >>> Strings.charAt8("", 0, "x")    == "x"
     * >>> Strings.charAt8(" ", -1)       == ""
     * >>> Strings.charAt8(" ", -1, "x")  == "x"
     * >>> Strings.charAt8(" ", 0)        == " "
     * >>> Strings.charAt8(" ", 1)        == ""
     * >>> Strings.charAt8(" ", 10)       == ""
     * >>> Strings.charAt8(" A", 1 )      == "A"
     * >>> Strings.charAt8(" はい", 1)     == "は"
     * >>> Strings.charAt8(" はい", 2)     == "い"
     * </code></pre>
     */
    public static function charAt8(str:String, pos:CharPos, resultIfOutOfBound = ""):String {
        if (str.isEmpty() || pos < 0 || pos >= str.length8())
            return resultIfOutOfBound;
            
        #if (java || flash || cs || python)
            return str.charAt(pos);
        #else
            return Utf8.sub(str, pos, 1);
        #end
    }
    
    /**
     * String#charCodeAt() variant with cross-platform UTF-8 support.
     * 
     * @param pos character position
     * 
     * <pre><code>
     * >>> Strings.charCodeAt8(null, 0)           == -1
     * >>> Strings.charCodeAt8(null, 0).isSpace() == false
     * >>> Strings.charCodeAt8("", 0)             == -1
     * >>> Strings.charCodeAt8("", 0, -4)         == -4
     * >>> Strings.charCodeAt8(" ", -1)           == -1
     * >>> Strings.charCodeAt8(" ", -1, -4)       == -4
     * >>> Strings.charCodeAt8(" ", 0)            == 32
     * >>> Strings.charCodeAt8(" ", 0).isSpace()  == true
     * >>> Strings.charCodeAt8(" ", 1)            == -1
     * >>> Strings.charCodeAt8(" ", 1).isSpace()  == false
     * >>> Strings.charCodeAt8(" ", 10)           == -1
     * >>> Strings.charCodeAt8(" A", 1)           == 65
     * >>> Strings.charCodeAt8(" はい", 1)         == 12399
     * >>> Strings.charCodeAt8(" はい", 2)         == 12356
     * </code></pre>
     */
    inline
    public static function charCodeAt8(str:String, pos:CharPos, resultIfOutOfBound:Char = -1):Char {
        var strLen = str.length8();
        if (strLen == 0 || pos < 0 || pos >= strLen)
            return resultIfOutOfBound;

        return str._charCodeAt8Unsafe(pos);
    }
    
    /**
     * Tests if <b>searchIn</b> contains <b>searchFor</b> as a substring
     * 
     * <pre><code>
     * >>> Strings.contains(null, null) == false
     * >>> Strings.contains(null, "")   == false
     * >>> Strings.contains("", null)   == false
     * >>> Strings.contains("", "")     == true
     * >>> Strings.contains("dog", "")  == true
     * >>> Strings.contains("dog", "g") == true
     * >>> Strings.contains("dog", "t") == false
     * >>> Strings.contains("はい", "い") == true
     * >>> Strings.contains("はは", "い") == false
     * </code></pre>
     */
    inline
    public static function contains(searchIn:String, searchFor:String):Bool {
        if (searchIn == null || searchFor == null)
            return false;
        
        if (searchFor == "")
            return true;

        return searchIn.indexOf(searchFor) > POS_NOT_FOUND;
    }
    
    /**
     * Tests if <b>searchIn</b> contains all of <b>searchFor</b> as a substring
     * 
     * <pre><code>
     * >>> Strings.containsAll(null, null)        == false
     * >>> Strings.containsAll(null, [""])        == false
     * >>> Strings.containsAll("", null)          == false
     * >>> Strings.containsAll("", [""])          == true
     * >>> Strings.containsAll("dog", [""])       == true
     * >>> Strings.containsAll("dog", ["c", ""])  == false
     * >>> Strings.containsAll("dog", ["c", "g"]) == false
     * >>> Strings.containsAll("dog", ["c", "a"]) == false
     * >>> Strings.containsAll("dog", ["d", "g"]) == true
     * >>> Strings.containsAll("はい", ["い"])     == true
     * >>> Strings.containsAll("はは", ["い"])     == false
     * </code></pre>
     */
    public static function containsAll(searchIn:String, searchFor:Array<String>):Bool {
        if (searchIn == null || searchFor == null)
            return false;
        
        for (candidate in searchFor) {            
            if (!contains(searchIn, candidate))
                return false;
        }
        return true;
    }
    
    /**
     * Tests if <b>searchIn</b> contains all of <b>searchFor</b> as a substring
     * 
     * <pre><code>
     * >>> Strings.containsAllIgnoreCase(null, null)        == false
     * >>> Strings.containsAllIgnoreCase(null, [""])        == false
     * >>> Strings.containsAllIgnoreCase("", null)          == false
     * >>> Strings.containsAllIgnoreCase("", [""])          == true
     * >>> Strings.containsAllIgnoreCase("dog", [""])       == true
     * >>> Strings.containsAllIgnoreCase("dog", ["c", ""])  == false
     * >>> Strings.containsAllIgnoreCase("dog", ["c", "G"]) == false
     * >>> Strings.containsAllIgnoreCase("dog", ["c", "a"]) == false
     * >>> Strings.containsAllIgnoreCase("dog", ["d", "G"]) == true
     * >>> Strings.containsAllIgnoreCase("はい", ["い"])     == true
     * >>> Strings.containsAllIgnoreCase("はは", ["い"])     == false
     * </code></pre>
     */
    public static function containsAllIgnoreCase(searchIn:String, searchFor:Array<String>):Bool {
        if (searchIn == null || searchFor == null)
            return false;
        
        searchIn = searchIn.toLowerCase();
        
        for (candidate in searchFor) {            
            if (!contains(searchIn, candidate.toLowerCase()))
                return false;
        }
        return true;
    }
    
    /**
     * Tests if <b>searchIn</b> contains any of <b>searchFor</b> as a substring
     * 
     * <pre><code>
     * >>> Strings.containsAny(null, null)        == false
     * >>> Strings.containsAny(null, [""])        == false
     * >>> Strings.containsAny("", null)          == false
     * >>> Strings.containsAny("", [""])          == true
     * >>> Strings.containsAny("dog", [""])       == true
     * >>> Strings.containsAny("dog", ["c", ""])  == true
     * >>> Strings.containsAny("dog", ["c", "g"]) == true
     * >>> Strings.containsAny("dog", ["", "g"]) == true
     * >>> Strings.containsAny("dog", ["c", "a"]) == false
     * >>> Strings.containsAny("dog", ["d", "g"]) == true
     * >>> Strings.containsAny("はい", ["い"])     == true
     * >>> Strings.containsAny("はは", ["い"])     == false
     * </code></pre>
     */
    public static function containsAny(searchIn:String, searchFor:Array<String>):Bool {
        if (searchIn == null || searchFor == null)
            return false;
        
        for (candidate in searchFor) {            
            if (contains(searchIn, candidate))
                return true;
        }
        return false;
    }
    
    /**
     * Tests if <b>searchIn</b> contains any of <b>searchFor</b> as a substring
     * 
     * <pre><code>
     * >>> Strings.containsAnyIgnoreCase(null, null)        == false
     * >>> Strings.containsAnyIgnoreCase(null, [""])        == false
     * >>> Strings.containsAnyIgnoreCase("", null)          == false
     * >>> Strings.containsAnyIgnoreCase("", [""])          == true
     * >>> Strings.containsAnyIgnoreCase("dog", [""])       == true
     * >>> Strings.containsAnyIgnoreCase("dog", ["c", ""])  == true
     * >>> Strings.containsAnyIgnoreCase("dog", ["c", "G"]) == true
     * >>> Strings.containsAnyIgnoreCase("dog", ["c", "a"]) == false
     * >>> Strings.containsAnyIgnoreCase("dog", ["d", "G"]) == true
     * >>> Strings.containsAnyIgnoreCase("はい", ["い"])     == true
     * >>> Strings.containsAnyIgnoreCase("はは", ["い"])     == false
     * </code></pre>
     */
    public static function containsAnyIgnoreCase(searchIn:String, searchFor:Array<String>):Bool {
        if (searchIn == null || searchFor == null)
            return false;
        
        searchIn = searchIn.toLowerCase();
        
        for (candidate in searchFor) {            
            if (contains(searchIn, candidate.toLowerCase()))
                return true;
        }
        return false;
    }
    
    /**
     * Tests if <b>searchIn</b> contains all of <b>searchFor</b> as a substring
     * 
     * <pre><code>
     * >>> Strings.containsNone(null, null)        == true
     * >>> Strings.containsNone(null, [""])        == true
     * >>> Strings.containsNone("", null)          == true
     * >>> Strings.containsNone("", [""])          == false
     * >>> Strings.containsNone("dog", [""])       == false
     * >>> Strings.containsNone("dog", ["c", ""])  == false
     * >>> Strings.containsNone("dog", ["c", "g"]) == false
     * >>> Strings.containsNone("dog", ["c", "a"]) == true
     * >>> Strings.containsNone("dog", ["d", "g"]) == false
     * >>> Strings.containsNone("はい", ["い"])     == false
     * >>> Strings.containsNone("はは", ["い"])     == true
     * </code></pre>
     */
    public static function containsNone(searchIn:String, searchFor:Array<String>):Bool {
        if (searchIn == null || searchFor == null)
            return true;
        
        for (candidate in searchFor) {            
            if (contains(searchIn, candidate))
                return false;
        }
        return true;
    }
    
    /**
     * Tests if <b>searchIn</b> contains all of <b>searchFor</b> as a substring
     * 
     * <pre><code>
     * >>> Strings.containsNoneIgnoreCase(null, null)        == true
     * >>> Strings.containsNoneIgnoreCase(null, [""])        == true
     * >>> Strings.containsNoneIgnoreCase("", null)          == true
     * >>> Strings.containsNoneIgnoreCase("", [""])          == false
     * >>> Strings.containsNoneIgnoreCase("dog", [""])       == false
     * >>> Strings.containsNoneIgnoreCase("dog", ["c", ""])  == false
     * >>> Strings.containsNoneIgnoreCase("dog", ["c", "G"]) == false
     * >>> Strings.containsNoneIgnoreCase("dog", ["c", "a"]) == true
     * >>> Strings.containsNoneIgnoreCase("dog", ["d", "G"]) == false
     * >>> Strings.containsNoneIgnoreCase("はい", ["い"])     == false
     * >>> Strings.containsNoneIgnoreCase("はは", ["い"])     == true
     * </code></pre>
     */
    public static function containsNoneIgnoreCase(searchIn:String, searchFor:Array<String>):Bool {
        if (searchIn == null || searchFor == null)
            return true;
        
        searchIn = searchIn.toLowerCase();
        
        for (candidate in searchFor) {            
            if (contains(searchIn, candidate.toLowerCase()))
                return false;
        }
        return true;
    }
    
    /**
     * @return the number of occurrences of <b>searchFor</b> within <b>searchIn</b> starting from the 
     *         given character position.
     * 
     * <pre><code>
     * >>> Strings.countMatches(null, null)         == 0
     * >>> Strings.countMatches(null, "")           == 0
     * >>> Strings.countMatches("", null)           == 0
     * >>> Strings.countMatches("", "a")            == 0
     * >>> Strings.countMatches("dogdog", "g")      == 2
     * >>> Strings.countMatches("dogdog", "og", 1)  == 2
     * >>> Strings.countMatches("dogdog", "og", 3)  == 1
     * >>> Strings.countMatches("dogdog", "og", 9)  == 0
     * >>> Strings.countMatches("dogdog", "og", -1) == 2
     * </code></pre>
     */
    public static function countMatches(searchIn:String, searchFor:String, startAt:CharPos = 0):Int {
        if (searchIn.isEmpty() || searchFor.isEmpty() || startAt >= searchIn.length)
            return 0;
            
        if (startAt < 0) 
            startAt = 0;
        
        var count = 0;
        var foundAt = startAt > -1 ? startAt - 1 : 0;
        while ((foundAt = searchIn.indexOf(searchFor, foundAt + 1)) > -1) {
            count++;
        }
        return count;
    }

    /**
     * @return the number of occurrences of <b>searchFor</b> within <b>searchIn</b> starting from the
     *         given character position ignoring case.
     * 
     * <pre><code>
     * >>> Strings.countMatchesIgnoreCase(null, null)         == 0
     * >>> Strings.countMatchesIgnoreCase(null, "")           == 0
     * >>> Strings.countMatchesIgnoreCase("", null)           == 0
     * >>> Strings.countMatchesIgnoreCase("", "a")            == 0
     * >>> Strings.countMatchesIgnoreCase("dogdog", "G")      == 2
     * >>> Strings.countMatchesIgnoreCase("dogdog", "OG", 1)  == 2
     * >>> Strings.countMatchesIgnoreCase("dogdog", "OG", 3)  == 1
     * >>> Strings.countMatchesIgnoreCase("dogdog", "OG", 9)  == 0
     * >>> Strings.countMatchesIgnoreCase("dogdog", "OG", -1) == 2
     * </code></pre>
     */
    public static function countMatchesIgnoreCase(searchIn:String, searchFor:String, startAt:CharPos = 0):Int {
        if (searchIn.isEmpty() || searchFor.isEmpty() || startAt >= searchIn.length)
            return 0;
            
        if (startAt < 0) 
            startAt = 0;
            
        searchIn = searchIn.toLowerCase();
        searchFor = searchFor.toLowerCase();
        
        var count = 0;
        var foundAt = startAt > -1 ? startAt - 1 : 0;
        while ((foundAt = searchIn.indexOf(searchFor, foundAt + 1)) > -1) {
            count++;
        }
        return count;
    }
    
    /**
     * @return 1 if <code>str > other</code>, -1 if <code>str < other</code>, 0 if <code>str == other</code>
     * 
     * <pre><code>
     * >>> Strings.compare(null, null)   == 0
     * >>> Strings.compare(null, "")     == -1
     * >>> Strings.compare("", null)     == 1
     * >>> Strings.compare("", "")       == 0
     * >>> Strings.compare("a", "b")     == -1
     * >>> Strings.compare("b", "a")     == 1
     * >>> Strings.compare("a", "A")     == 1
     * TODO https://github.com/HaxeFoundation/hxcs/issues/25
     * >>> Strings.compare("A", "a")     == -1
     * >>> Strings.compare("a", "B")     == 1
     * >>> Strings.compare("к--", "К--") == 1
     * >>> Strings.compare("к--", "т--") == -1
     * >>> Strings.compare("кот", "КОТ") == 1
     * </core></pre>
     */
    public static function compare(str:String, other:String):Int {
        if (str == null) 
            return other == null ? 0 : -1;
            
        if (other == null) 
            return str == null ? 0 : 1;

        #if neko
            // TODO https://github.com/HaxeFoundation/haxe/issues/5308
            return str > other ? 1 : (str == other ? 0 : -1);
        #else
            return Utf8.compare(str, other);
        #end
    }
    
    /**
     * @return 1 if <code>str > other</code>, -1 if <code>str < other</code>, 0 if <code>str == other</code>
     * 
     * <pre><code>
     * >>> Strings.compareIgnoreCase(null, null)   == 0
     * >>> Strings.compareIgnoreCase(null, "")     == -1
     * >>> Strings.compareIgnoreCase("", null)     == 1
     * >>> Strings.compareIgnoreCase("", "")       == 0
     * >>> Strings.compareIgnoreCase("a", "b")     == -1
     * >>> Strings.compareIgnoreCase("b", "a")     == 1
     * >>> Strings.compareIgnoreCase("a", "A")     == 0
     * >>> Strings.compareIgnoreCase("A", "a")     == 0
     * >>> Strings.compareIgnoreCase("a", "B")     == -1
     * >>> Strings.compareIgnoreCase("к--", "К--") == 0
     * >>> Strings.compareIgnoreCase("к--", "т--") == -1
     * >>> Strings.compareIgnoreCase("кот", "КОТ") == 0
     * </core></pre>
     */
    public static function compareIgnoreCase(str:String, other:String):Int {
        if (str == null) 
            return other == null ? 0 : -1;
            
        if (other == null) 
            return str == null ? 0 : 1;
            
        str = str.toLowerCase8();
        other = other.toLowerCase8();
        
        #if neko
            // TODO https://github.com/HaxeFoundation/haxe/issues/5308
            return str > other ? 1 : (str == other ? 0 : -1);
        #else
            return Utf8.compare(str, other);
        #end
    }

    /**
     * <pre><code>
     * >>> Strings.diff(null, null).pos     == -1
     * >>> Strings.diff(null, "").pos       == 0
     * >>> Strings.diff(null, "").left      == null
     * >>> Strings.diff(null, "").right     == ""
     * >>> Strings.diff("abc", "abC").left  == "c"
     * >>> Strings.diff("abc", "abC").right == "C"
     * >>> Strings.diff("ab", "abC").left   == ""
     * >>> Strings.diff("ab", "abC").right  == "C"
     * </code></pre>
     */
    public static function diff(left:String, right:String):StringDiff {
        var diff = new StringDiff();
        diff.pos = diffAt(left, right);
        diff.left = left.substr8(diff.pos);
        diff.right = right.substr8(diff.pos);
        return diff;
    }

    /**
     * @return the UTF8 character position where the strings begin to differ or -1 if they are equal
     * 
     * <pre><code>
     * >>> Strings.diffAt(null, null)       == -1
     * >>> Strings.diffAt(null, "")         == 0
     * >>> Strings.diffAt("", null)         == 0
     * >>> Strings.diffAt("", "")           == -1
     * >>> Strings.diffAt("", "cat")        == 0
     * >>> Strings.diffAt("cat", "")        == 0
     * >>> Strings.diffAt("cat", "dog")     == 0
     * >>> Strings.diffAt("cat", "cat")     == -1
     * >>> Strings.diffAt("cat", "catdog")  == 3
     * >>> Strings.diffAt("catdog", "cat")  == 3
     * </code></pre>
     */
    public static function diffAt(str:String, other:String):CharPos {
        if (str.equals(other)) 
            return POS_NOT_FOUND;
            
        var strLen = str.length8();
        var otherLen = other.length8();
        
        if (strLen == 0 || otherLen == 0)
            return 0;
        
        var checkLen = strLen > otherLen ? otherLen : strLen;

        for (i in 0...checkLen) {
            if (str._charCodeAt8Unsafe(i) != other._charCodeAt8Unsafe(i))
                return i;
        }
        return checkLen;
    }
    
    /**
     * <pre><code>
     * >>> Strings.endsWith(null, "cat")     == false
     * >>> Strings.endsWith("", "")          == true
     * >>> Strings.endsWith("dogcat", null)  == false
     * >>> Strings.endsWith("dogcat", "")    == true
     * >>> Strings.endsWith("dogcat", "cat") == true
     * >>> Strings.endsWith("dogcat", "dog") == false
     * >>> Strings.endsWith("はい", "い")     == true
     * >>> Strings.endsWith("はい", "は")     == false
     * </code></pre>
     */
    inline
    public static function endsWith(searchIn:String, searchFor:String):Bool {
        if (searchIn == null || searchFor == null)
            return false;

        return StringTools.endsWith(searchIn, searchFor);
    }
    
    /**
     * <pre><code>
     * >>> Strings.endsWithIgnoreCase(null, "cat")     == false
     * >>> Strings.endsWithIgnoreCase("", "")          == true
     * >>> Strings.endsWithIgnoreCase("dogcat", null)  == false
     * >>> Strings.endsWithIgnoreCase("dogcat", "")    == true
     * >>> Strings.endsWithIgnoreCase("dogcat", "CAT") == true
     * >>> Strings.endsWithIgnoreCase("dogcat", "dog") == false
     * >>> Strings.endsWithIgnoreCase("はい", "い")     == true
     * >>> Strings.endsWithIgnoreCase("はい", "は")     == false
     * </code></pre>
     */
    inline
    public static function endsWithIgnoreCase(searchIn:String, searchFor:String):Bool {
        if (searchIn == null || searchFor == null)
            return false;

        return StringTools.endsWith(searchIn.toLowerCase(), searchFor.toLowerCase());
    }
    
    /**
     * Tests if the string representation of <b>other</b> equals <b>str</b>.
     * 
     * <pre><code>
     * >>> Strings.equals(null, null)   == true
     * >>> Strings.equals(null, "")     == false
     * >>> Strings.equals("", "")       == true
     * >>> Strings.equals("", null)     == false
     * >>> Strings.equals("1", 1)       == true
     * >>> Strings.equals("true", true) == true
     * >>> Strings.equals("dog", "dog") == true
     * >>> Strings.equals("dog", "DOG") == false
     * >>> Strings.equals("い", "い")    == true
     * </code></pre>
     */
    inline
    public static function equals<T>(str:String, other:T):Bool {
        return toString(str) == toString(other);
    }

    /**
     * Tests if the string representation of <b>other</b> equals <b>str</b> ignoring the case.
     * 
     * <pre><code>
     * >>> Strings.equalsIgnoreCase(null, null)   == true
     * >>> Strings.equalsIgnoreCase(null, "")     == false
     * >>> Strings.equalsIgnoreCase("", "")       == true
     * >>> Strings.equalsIgnoreCase("", null)     == false
     * >>> Strings.equalsIgnoreCase("1", 1)       == true
     * >>> Strings.equalsIgnoreCase("true", true) == true
     * >>> Strings.equalsIgnoreCase("dog", "dog") == true
     * >>> Strings.equalsIgnoreCase("dog", "DOG") == true
     * >>> Strings.equalsIgnoreCase("い", "い")    == true
     * </code></pre>
     */
    inline
    public static function equalsIgnoreCase<T>(str:String, other:T):Bool {
        return toString(str).toLowerCase() == toString(other).toLowerCase();
    }
    
    /**
     * @return a string containing only those characters/substrings for which <b>filter</b> returned <code>true</code>.
     * 
     * <pre><code>
     * >>> Strings.filter(null,       function(s) return s == " ")       == null
     * >>> Strings.filter("",         function(s) return s == " ")       == ""
     * >>> Strings.filter(" b b b",   function(s) return s == " ")       == "   "
     * >>> Strings.filter("はいはい",   function(s) return s == "は")      == "はは"
     * >>> Strings.filter("ab:cd:ab", function(s) return s == "ab", ":") == "ab:ab"
     * </code></pre>
     */
    inline
    public static function filter(str:String, filter:String -> Bool, separator = ""):String {
        if (str.isEmpty())
            return str;

        return str.split8(separator).filter(filter).join(separator);
	}
    
    /**
     * @return a string containing only those characters for which <b>filter</b> returned <code>true</code>.
     * 
     * <pre><code>
     * >>> Strings.filterChars(null,       function(ch) return ch == 32)            == null
     * >>> Strings.filterChars("",         function(ch) return ch == 32)            == ""
     * >>> Strings.filterChars(" b b b",   function(ch) return ch == 32)            == "   "
     * >>> Strings.filterChars("はいはい",   function(ch) return ch == Char.of("は")) == "はは"
     * </code></pre>
     */
    inline
    public static function filterChars(str:String, filter:Char -> Bool):String {
        if (str.isEmpty())
            return str;

        return str.toChars().filter(filter).map(function (ch) return ch.toString() ).join("");
	}
    
    /**
     * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
     * 
     * <pre><code>
     * >>> Strings.globToEReg("**"+"/file?.txt").match("aa/bb/file1.txt") == true
     * >>> Strings.globToEReg("*.txt").match("file.txt")       == true
     * >>> Strings.globToEReg("*.txt").match("file.pdf")       == false
     * >>> Strings.globToEReg("*.{pdf,txt}").match("file.txt") == true
     * >>> Strings.globToEReg("*.{pdf,txt}").match("file.pdf") == true
     * >>> Strings.globToEReg("*.{pdf,txt}").match("file.xml") == false
     * </code></pre>
     */
    inline
    public static function globToEReg(globPattern:String):EReg {
        return globPattern.globToRegEx().toEReg();
    }
    
    /**
     * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
     * 
     * <pre><code>
     * >>> Strings.globToRegEx(null)                == null
     * >>> Strings.globToRegEx("")                  == ""
     * >>> Strings.globToRegEx("file")              == "file$"
     * >>> Strings.globToRegEx("*.txt")             == "[^\\\\^\\/]*\\.txt$"
     * >>> Strings.globToRegEx("*file*")            == "[^\\\\^\\/]*file[^\\\\^\\/]*$"
     * >>> Strings.globToRegEx("file?.txt")         == "file[^\\\\^\\/]\\.txt$"
     * >>> Strings.globToRegEx("**"+"/file?.txt").toEReg().match("aa/bb/file1.txt") == true
     * >>> Strings.globToRegEx("*.txt").toEReg().match("file.txt")       == true
     * >>> Strings.globToRegEx("*.txt").toEReg().match("file.pdf")       == false
     * >>> Strings.globToRegEx("*.{pdf,txt}").toEReg().match("file.txt") == true
     * >>> Strings.globToRegEx("*.{pdf,txt}").toEReg().match("file.pdf") == true
     * >>> Strings.globToRegEx("*.{pdf,txt}").toEReg().match("file.xml") == false
     * </code></pre>
     */
    public static function globToRegEx(globPattern:String):String {
        if (globPattern.isEmpty())
            return globPattern;

        var sb = new StringBuilder();
        var chars = globPattern.toChars();
        var chPrev:Char = -1;
        var groupDepth = 0;
        var idx = -1;
        while(idx < chars.length - 1) {
            idx++;
            var ch = chars[idx];

            switch (ch) {
                case Char.BACKSLASH:
                    if (chPrev == Char.BACKSLASH)
                        sb.add("\\\\"); // "\\" => "\\"
                case Char.SLASH:
                     // "/" => "\/"
                    sb.add("\\/");
                case Char.DOLLAR:
                    // "$" => "\$"
                    sb.add("\\$");
                case Char.QUESTION_MARK:
                    if (chPrev == Char.BACKSLASH)
                        sb.add("\\?"); // "\?" => "\?"
                    else
                        sb.add("[^\\\\^\\/]"); // "?" => "[^\\^\/]"
                case Char.DOT:
                    // "." => "\."
                    sb.add("\\.");
                case Char.BRACKET_ROUND_LEFT:
                    // "(" => "\("
                    sb.add("\\(");
                case Char.BRACKET_ROUND_RIGHT:
                    // ")" => "\)"
                    sb.add("\\)");
                case Char.BRACKET_CURLY_LEFT:
                    if (chPrev == Char.BACKSLASH)
                        sb.add("\\{"); // "\{" => "\{"
                    else {
                        groupDepth++;
                        sb.addChar(Char.BRACKET_ROUND_LEFT);
                    }
                case Char.BRACKET_CURLY_RIGHT:
                    if (chPrev == Char.BACKSLASH)
                        sb.add("\\}"); // "\}" => "\}"
                    else {
                        groupDepth--;
                        sb.addChar(Char.BRACKET_ROUND_RIGHT);
                    }
                case Char.COMMA:
                    if (chPrev == Char.BACKSLASH)
                        sb.add("\\,"); // "\," => "\,"
                    else {
                        // "," => "|" if in group or => "," if not in group
                        sb.addChar(groupDepth > 0 ? Char.PIPE : Char.COMMA);
                    }
                case Char.ASTERISK:
                    if (chars[idx + 1] == Char.ASTERISK) { // **
                        if (chars[idx + 2] == Char.SLASH) { // **/
                            if (chars[idx + 3] == Char.ASTERISK) { 
                                // "**/*" => ".*"
                                sb.add(".*");
                                idx += 3;
                            } else {
                                // "**/" => "(.*/)?"
                                sb.add("(.*/)?");
                                idx += 2;
                                ch = Char.SLASH;
                            }
                        } else {
                            sb.add(".*"); // "**" => ".*"
                            idx++;
                        }
                    } else {
                        sb.add("[^\\\\^\\/]*"); // "*" => "[^\\^\/]*"
                    }
                default:
                    if (chPrev == Char.BACKSLASH) {
                        sb.addChar(Char.BACKSLASH);
                    }
                    sb.addChar(ch);
            }

            chPrev = ch;
        }
        sb.addChar(Char.DOLLAR);
        return sb.toString();
    }
    
    /**
     * @return a (platform dependent) hashcode for the given string
     * 
     * <pre><code>
     * >>> Strings.hashCode(null)  == 0
     * >>> Strings.hashCode("")    == 0
     * </code></pre>
     */
    public static function hashCode(str:String):Int {
        if (str.isEmpty())
            return 0;

        #if java
            return untyped __java__("str.hashCode()");
        #elseif cs
            return untyped __cs__("str.GetHashCode()");
        #else
            var hc:Int32 = 0;
            for(i in 0...str.length8()) {
                hc = 31 * hc + str._charCodeAt8Unsafe(i);
            }
            return hc;
        #end
    }
    
    /**
     * @param minDigits the resulting string is left padded with <code>0</code> until it length equals <code>minDigits</code>
     * @return the hexadecimal representation of <b>num</b>
     *
     * <pre><code>
     * >>> Strings.hex(1)       == "1"
     * >>> Strings.hex(10)      == "A"
     * >>> Strings.hex(100)     == "64"
     * >>> Strings.hex(100, 4)  == "0064"
     * >>> Strings.hex(1000, 2) == "3E8"
     * >>> Strings.hex(-1)      == "FFFFFFFF"
     * >>> Strings.hex(-10)     == "FFFFFFF6"
     * >>> Strings.hex(-10, 10) == "00FFFFFFF6"
     * </code></pre>
     */
    inline
    public static function hex(num:Int, minDigits:Int = 0):String {
        var hexed = StringTools.hex(num, 0);        
        return hexed.lpad(minDigits, "0");
    }
    
    /**
     * <pre><code>
     * >>> Strings.htmlDecode(null)                == null
     * >>> Strings.htmlDecode("")                  == ""
     * >>> Strings.htmlDecode(" ")                 == " "
     * >>> Strings.htmlDecode(" 'dog' ")           == " 'dog' "
     * >>> Strings.htmlDecode(' "dog" ')           == ' "dog" '
     * >>> Strings.htmlDecode(" 1 & 2 ")           == " 1 & 2 "
     * >>> Strings.htmlDecode(" 1 > 2 ")           == " 1 > 2 "
     * >>> Strings.htmlDecode(" 1 < 2 ")           == " 1 < 2 "
     * >>> Strings.htmlDecode(" &#039;dog&#039; ") == " 'dog' "
     * >>> Strings.htmlDecode(' &quot;dog&quot; ') == ' "dog" '
     * >>> Strings.htmlDecode(" 1 &amp; 2 ")       == " 1 & 2 "
     * >>> Strings.htmlDecode(" 1 &gt; 2 ")        == " 1 > 2 "
     * >>> Strings.htmlDecode(" 1 &lt; 2 ")        == " 1 < 2 "
     * >>> Strings.htmlDecode("&#12399;&#12356;")  == "はい"
     * </code></pre>
     */
    inline
    public static function htmlDecode(str:String):String {
        if (str.isEmpty())
            return str;

        return REGEX_HTML_UNESCAPE.map(str, function(r:EReg):String {
            var match:String = r.matched(0);
            return switch(match) {
                case "&amp;":  "&";
                case "&apos;": "'";
                case "&gt;":   ">";
                case "&lt;":   "<";
                case "&nbsp;": " ";
                case "&quot;": "\"";
                default:
                   Char.of(Std.parseInt(match.substr8(2, match.length8() - 3))).toString();
            }
        });
    }
    
    /**
     * <pre><code>
     * >>> Strings.htmlEncode(null)             == null
     * >>> Strings.htmlEncode("")               == ""
     * >>> Strings.htmlEncode(" ")              == " "
     * >>> Strings.htmlEncode(" 'dog' ")        == " 'dog' "
     * >>> Strings.htmlEncode(' "dog" ')        == ' "dog" '
     * >>> Strings.htmlEncode(" 'dog' ", true)  == " &#039;dog&#039; "
     * >>> Strings.htmlEncode(' "dog" ', true)  == ' &quot;dog&quot; '
     * >>> Strings.htmlEncode(" 'dog' ", false) == " 'dog' "
     * >>> Strings.htmlEncode(' "dog" ', false) == ' "dog" '
     * >>> Strings.htmlEncode(" 1 & 2 ")        == " 1 &amp; 2 "
     * >>> Strings.htmlEncode(" 1 > 2 ")        == " 1 &gt; 2 "
     * >>> Strings.htmlEncode(" 1 < 2 ")        == " 1 &lt; 2 "
     * >>> Strings.htmlEncode("はい")            == "&#12399;&#12356;"
     * </code></pre>
     */
    public static function htmlEncode(str:String, escapeQuotes:Bool = false):String {
        if (str.isEmpty())
            return str;

        var sb = new StringBuilder();
        var isFirstSpace = true;
        for (i in 0...str.length8()){
            var ch:Int /*fails with Char for some reason*/ = str._charCodeAt8Unsafe(i);
            switch(ch) {
                case Char.SPACE:
                    if (isFirstSpace) {
                        sb.add(" ");
                        isFirstSpace = false;
                    } else 
                        sb.add("&nbsp;");

                case Char.AMPERSAND:
                    sb.add("&amp;");

                case Char.DOUBLE_QUOTE:
                    sb.add(escapeQuotes ? "&quot;": "\"");

                case Char.SINGLE_QUOTE:
                    // http://stackoverflow.com/a/2083770
                    sb.add(escapeQuotes ? "&#039;" : "'");

                case Char.LOWER_THAN:
                    sb.add("&lt;");
                    
                case Char.GREATER_THAN:
                    sb.add("&gt;");

                default:
                    if(ch > 127)
                        sb.add('&#$ch;');
                    else
                        sb.addChar(ch);
            }
            
            if (ch != Char.SPACE)
                isFirstSpace = true;
        }

        return sb.toString();
    }
    
    /**
     * <pre><code>
     * >>> Strings.ifBlank(null, null) == null
     * >>> Strings.ifBlank(null, "")   == ""
     * >>> Strings.ifBlank(null, "a")  == "a"
     * >>> Strings.ifBlank("", null)   == null
     * >>> Strings.ifBlank("", "")     == ""
     * >>> Strings.ifBlank("", "a")    == "a"
     * >>> Strings.ifBlank(" ", null)  == null
     * >>> Strings.ifBlank(" ", "")    == ""
     * >>> Strings.ifBlank(" ", "a")   == "a"
     * >>> Strings.ifBlank("a", null)  == "a"
     * >>> Strings.ifBlank("a", "")    == "a"
     * >>> Strings.ifBlank("a", "b")   == "a"
     * </code></pre>
     */
    inline
    public static function ifBlank(str:String, fallback:String):String {
        return str.isBlank() ? fallback : str;
    }
    
    /**
     * <pre><code>
     * >>> Strings.ifEmpty(null, null) == null
     * >>> Strings.ifEmpty(null, "")   == ""
     * >>> Strings.ifEmpty(null, "a")  == "a"
     * >>> Strings.ifEmpty("", null)   == null
     * >>> Strings.ifEmpty("", "")     == ""
     * >>> Strings.ifEmpty("", "a")    == "a"
     * >>> Strings.ifEmpty(" ", null)  == " "
     * >>> Strings.ifEmpty(" ", "")    == " "
     * >>> Strings.ifEmpty(" ", "a")   == " "
     * >>> Strings.ifEmpty("a", null)  == "a"
     * >>> Strings.ifEmpty("a", "")    == "a"
     * >>> Strings.ifEmpty("a", "b")   == "a"
     * </code></pre>
     */
    inline
    public static function ifEmpty(str:String, fallback:String):String {
        return str.isEmpty() ? fallback : str;
    }
    
    /**
     * <pre><code>
     * >>> Strings.ifNull(null, null) == null
     * >>> Strings.ifNull(null, "")   == ""
     * >>> Strings.ifNull(null, "a")  == "a"
     * >>> Strings.ifNull("", null)   == ""
     * >>> Strings.ifNull("", "")     == ""
     * >>> Strings.ifNull("", "a")    == ""
     * >>> Strings.ifNull("a", null)  == "a"
     * >>> Strings.ifNull("a", "")    == "a"
     * >>> Strings.ifNull("a", "b")   == "a"
     * </code></pre>
     */
    inline
    public static function ifNull(str:String, fallback:String):String {
        return str == null ? fallback : str;
    }
    
    /**
     * String#indexOf() variant with cross-platform UTF-8 support and ECMAScript like behavior.
     * 
     * Solves cross-platform issue https://github.com/HaxeFoundation/haxe/issues/5271
     * 
     * @param startAt Character position within <b>str</b> where the search for <b>searchFor</b> starts. 
     *                If <code>startAt < 0</code> the entire string is searched. 
     *                If <code>startAt >= str.length</code>, the string is not searched and -1 is returned. 
     *                Unless <b>searchFor</b> is an empty string, then str.length is returned.
     *
     * @return the character position of the leftmost occurrence of <b>substr</b> within <b>str</b>.
     * 
     * <pre><code>
     * >>> Strings.indexOf8(null, null)         == -1
     * >>> Strings.indexOf8(null, "")           == -1
     * >>> Strings.indexOf8("", null)           == -1
     * >>> Strings.indexOf8("", "")             == 0
     * >>> Strings.indexOf8("", "", 0)          == 0
     * >>> Strings.indexOf8("", "", 1)          == 0
     * >>> Strings.indexOf8("", "", -1)         == 0
     * >>> Strings.indexOf8("dog", null)        == -1
     * >>> Strings.indexOf8("dog", "")          == 0
     * >>> Strings.indexOf8("dog", "", 0)       == 0
     * >>> Strings.indexOf8("dog", "", 1)       == 1
     * >>> Strings.indexOf8("dog", "", 2)       == 2
     * >>> Strings.indexOf8("dog", "", 3)       == 3
     * >>> Strings.indexOf8("dog", "", 4)       == 3
     * >>> Strings.indexOf8("dog", "", 10)      == 3
     * >>> Strings.indexOf8("dog", "", -1)      == 0
     * >>> Strings.indexOf8("dogdog", "cat")    == -1
     * >>> Strings.indexOf8("dogcat", "cat")    == 3
     * >>> Strings.indexOf8("dogcat", "cat", 0) == 3
     * >>> Strings.indexOf8("dogcat", "cat", 1) == 3
     * >>> Strings.indexOf8("catcat", "cat", 3) == 3
     * >>> Strings.indexOf8("catcat", "cat", 4) == -1
     * >>> Strings.indexOf8("dogcat", "は")     == -1
     * >>> Strings.indexOf8("dogはcat", "は")    == 3
     * >>> Strings.indexOf8("dogいcatは", "は")  == 7
     * >>> Strings.indexOf8("dogはcat", "cat")   == 4
     * >>> Strings.indexOf8("foはoはcat", "cat") == 5
     * >>> Strings.indexOf8("いいはい", "")       == 0
     * >>> Strings.indexOf8("いいはい", "", 5)    == 4
     * >>> Strings.indexOf8("いいはい", "は")      == 2
     * </code></pre>
     */
    public static function indexOf8(str:String, searchFor:String, startAt:CharPos = 0):CharPos {

        // handling null strings
        if (str == null || searchFor == null)
            return POS_NOT_FOUND;

        var strLen = str.length8();
        var searchForLen = searchFor.length8();

        // handling negative startAt
        if (startAt < 0)
            startAt = 0;

        // handling empty substring
        if (searchForLen == 0) {
            if (startAt == 0)
                return 0;
            if (startAt > 0 && startAt < strLen) {
                return startAt;
            }
            return strLen;
        }
        
        // startAt out-of-bound
        if (startAt >= strLen)
            return POS_NOT_FOUND;

        #if (java || flash || cs || python)
            return str.indexOf(searchFor, startAt);
        #elseif php
            var index:Dynamic = untyped __call__("mb_strpos", str, searchFor, startAt, 'UTF-8');
            return index == false ? POS_NOT_FOUND : cast index;
        #else
            var strNeedsUTF8Workaround = str.length != strLen;
            var searchForNeedsUTF8Workaround = searchFor.length != searchForLen;
            
            // delegate to native lastIndexOf() if either no UTF8 chars are present or the current platform uses UTF8 encoding by default
            if (!strNeedsUTF8Workaround && !searchForNeedsUTF8Workaround)
                return str.indexOf(searchFor, startAt);
                
            if (searchForNeedsUTF8Workaround && !strNeedsUTF8Workaround)
                // won't find UTF8 chars in non-UTF8 string
                return POS_NOT_FOUND;

            var searchForChars = [ for (i in 0...searchForLen) searchFor._charCodeAt8Unsafe(i) ];
            
            var searchForPosToCheck = 0;
            for (strPos in startAt...strLen) {
                var strCh = str.charCodeAt8(strPos);
                if (strCh == searchForChars[searchForPosToCheck]) {
                    searchForPosToCheck++;
                    if (searchForPosToCheck == searchForLen)
                        return strPos - searchForPosToCheck + 1;
                } else {
                    searchForPosToCheck = 0;
                }
            }
            return POS_NOT_FOUND;
        #end
    }
    
    /**
     * @return <code>true</code> if <code>null</code> or empty ("") or only contains whitespace characters
     * 
     * <pre><code>
     * >>> Strings.isBlank(null)   == true
     * >>> Strings.isBlank("")     == true
     * >>> Strings.isBlank("a")    == false
     * >>> Strings.isBlank("    ") == true
     * >>> Strings.isBlank("\n")   == true
     * >>> Strings.isBlank("\r")   == true
     * >>> Strings.isBlank("\t")   == true
     * >>> Strings.isBlank("は")   == false
     * </code></pre>
     */
    inline
    public static function isBlank(str:String):Bool {
        return str == null ? true : StringTools.trim(str).length == 0;
    }
        
    /**
     * @return true if the string only contains digits (0-9).
     * 
     * <pre><code>
     * >>> Strings.isDigits(null)  == false
     * >>> Strings.isDigits("")    == false
     * >>> Strings.isDigits("1")   == true
     * >>> Strings.isDigits("1,1") == false
     * >>> Strings.isDigits("1.1") == false
     * >>> Strings.isDigits("1a")  == false
     * >>> Strings.isDigits("は")  == false
     * </code></pre>
     */
    #if php inline #end
    public static function isDigits(str:String):Bool {
        #if php
            return untyped __call__("ctype_digit", str);
        #else
            if(str.isEmpty())
                return false;

            for (i in 0...str.length8())
                if (!str._charCodeAt8Unsafe(i).isDigit())
                    return false;

            return true;
        #end
    }
    
    /**
     * <pre><code>
     * >>> Strings.isEmpty(null)   == true
     * >>> Strings.isEmpty("")     == true
     * >>> Strings.isEmpty("    ") == false
     * >>> Strings.isEmpty("\n")   == false
     * >>> Strings.isEmpty("\r")   == false
     * >>> Strings.isEmpty("\t")   == false
     * >>> Strings.isEmpty("a")    == false
     * >>> Strings.isEmpty("は")   == false
     * </code></pre>
     */
    inline
    public static function isEmpty(str:String):Bool {
        return str == null || str.length == 0;
    }

    /**
     * <pre><code>
     * >>> Strings.isNotBlank(null)   == false
     * >>> Strings.isNotBlank("")     == false
     * >>> Strings.isNotBlank("a")    == true
     * >>> Strings.isNotBlank("    ") == false
     * >>> Strings.isNotBlank("\n")   == false
     * >>> Strings.isNotBlank("\r")   == false
     * >>> Strings.isNotBlank("\t")   == false
     * >>> Strings.isNotBlank("は")   == true
     * </code></pre>
     */
    inline
    public static function isNotBlank(str:String):Bool {
        return str != null && StringTools.trim(str).length > 0;
    }
    
    /**
     * <pre><code>
     * >>> Strings.isNotEmpty(null)   == false
     * >>> Strings.isNotEmpty("")     == false
     * >>> Strings.isNotEmpty("    ") == true
     * >>> Strings.isNotEmpty("\n")   == true
     * >>> Strings.isNotEmpty("\r")   == true
     * >>> Strings.isNotEmpty("\t")   == true
     * >>> Strings.isNotEmpty("a")    == true
     * >>> Strings.isNotEmpty("は")   == true
     * </code></pre>
     */
    inline
    public static function isNotEmpty(str:String):Bool {
        return str != null && str.length > 0;
    }
    
    /**
     * Invokes the callback function separately on each character/substring of the given string.
     */
    public static function iterate(str:String, callback:String -> Void, separator = ""):Void {
        if (str.isEmpty())
            return;

        for (sub in str.split8(separator)) {
            callback(sub);
        }
	}
    
    /**
     * Invokes the callback function on each character of the given string.
     */
    public static function iterateChars(str:String, callback:Char -> Void):Void {
        if (str.isEmpty())
            return;

        for (i in 0...str.length8()) {
            callback(str._charCodeAt8Unsafe(i));
        }
	}

    /**
     * String#lastIndexOf() variant with cross-platform UTF-8 support and ECMAScript like behavior.
     * 
     * @param startAt Character position within <b>str</b> from where the search for <b>searchFor</b> starts in reverse.
     *                The default value is `str.length - 1`, so the whole array is searched.
     *                If `startAt >= str.length`, the whole string is searched. 
     *                If `startAt < 0`, the behavior will be the same as if it would be 0.
     * 
     * @return character position of the leftmost occurrence of <b>searchFor</b> within <b>str</b>.
     * 
     * <pre><code>
     * >>> Strings.lastIndexOf8(null, null)               == -1
     * >>> Strings.lastIndexOf8(null, "")                 == -1
     * >>> Strings.lastIndexOf8("", null)                 == -1
     * >>> Strings.lastIndexOf8("", "")                   == 0
     * >>> Strings.lastIndexOf8("", "", 0)                == 0
     * >>> Strings.lastIndexOf8("", "", 1)                == 0
     * >>> Strings.lastIndexOf8("", "", -1)               == 0
     * >>> Strings.lastIndexOf8("dog", null)              == -1
     * >>> Strings.lastIndexOf8("dog", "")                == 3
     * >>> Strings.lastIndexOf8("dog", "", 0)             == 0
     * >>> Strings.lastIndexOf8("dog", "", 2)             == 2
     * >>> Strings.lastIndexOf8("dog", "", 3)             == 3
     * >>> Strings.lastIndexOf8("dog", "", 4)             == 3
     * >>> Strings.lastIndexOf8("dog", "", -1)            == 0
     * >>> Strings.lastIndexOf8("dogdog", "cat")          == -1
     * >>> Strings.lastIndexOf8("dogcat", "cat")          == 3
     * >>> Strings.lastIndexOf8("dogcat", "cat", 0)       == -1
     * >>> Strings.lastIndexOf8("dogcat", "cat", 1)       == -1
     * >>> Strings.lastIndexOf8("dogcat", "cat", 3)       == 3
     * >>> Strings.lastIndexOf8("dogcat", "cat", 4)       == 3
     * >>> Strings.lastIndexOf8("dogcat", "cat", 10)      == 3
     * >>> Strings.lastIndexOf8("dogcat", "cat", -1)      == -1
     * >>> Strings.lastIndexOf8("dogcatdog", "dog")       == 6
     * >>> Strings.lastIndexOf8("dogdogdog", "dogdog")    == 3
     * >>> Strings.lastIndexOf8("dogdogdog", "dogdog", 2) == 0
     * >>> Strings.lastIndexOf8("dogdogdog", "dogdog", 3) == 3
     * >>> Strings.lastIndexOf8("dogdogdog", "dogdog", 4) == 3
     * >>> Strings.lastIndexOf8("dogdogcag", "dog", 3) == 3
     * >>> Strings.lastIndexOf8("dogdogdogい", "dogdog")  == 3
     * >>> Strings.lastIndexOf8("dogcat", "は")            == -1
     * >>> Strings.lastIndexOf8("dogはcat", "は")          == 3
     * >>> Strings.lastIndexOf8("dogいcatは", "は")        == 7
     * >>> Strings.lastIndexOf8("dogはcat", "cat")        == 4
     * >>> Strings.lastIndexOf8("foはoはcat", "cat")       == 5
     * >>> Strings.lastIndexOf8("いいはい", "は")           == 2
     * </code></pre>
     */
    public static function lastIndexOf8(str:String, searchFor:String, ?startAt:CharPos):CharPos {

        // handling null strings
        if (str == null || searchFor == null)
            return POS_NOT_FOUND;

        var strLen = str.length8();
        var searchForLen = searchFor.length8();
        // assign default value
        if (startAt == null)
            startAt = strLen;

        // handling empty substring
        if (searchForLen == 0) {
            if (startAt < 0)
                return 0;
            if(startAt > strLen)
                return strLen;
            return startAt;
        }

        // startAt out-of-bound
        if (startAt < 0)
            return POS_NOT_FOUND;
            
        else if (startAt >= strLen) {
            startAt = strLen - 1;
        }
            
        #if (java || flash)
            return str.lastIndexOf(searchFor, startAt);
        #else
            var strNeedsUTF8Workaround = str.length != strLen;
            var searchForNeedsUTF8Workaround = searchFor.length != searchForLen;

            #if !(python || cs)
            // delegate to native lastIndexOf() if either no UTF8 chars are present or the current platform uses UTF8 encoding by default
            if (!strNeedsUTF8Workaround && !searchForNeedsUTF8Workaround) {
                return str.lastIndexOf(searchFor, startAt);
            }
            #end
            
            if (searchForNeedsUTF8Workaround && !strNeedsUTF8Workaround)
                // won't find UTF8 chars in non-UTF8 string
                return POS_NOT_FOUND;

            var searchForChars = searchFor.toChars();
            startAt += searchForLen - 1;

            var searchForPosToCheck = searchForLen - 1;
            var strPos:CharPos = strLen;
            while (strPos-- > 0) {
                if (strPos > startAt) continue;
                var strCh = str._charCodeAt8Unsafe(strPos);

                if (strCh == searchForChars[searchForPosToCheck]) {
                    if(searchForPosToCheck == 0)
                        return strPos;
                    searchForPosToCheck--;
                } else {
                    searchForPosToCheck = searchForLen - 1;
                }
            }
            return POS_NOT_FOUND;
        #end
    }
    
    /**
     * String#length() variant with cross-platform UTF-8 support.
     * 
     * <pre><code>
     * >>> Strings.length8(null)     == 0
     * >>> Strings.length8("")       == 0
     * >>> Strings.length8("123")    == 3
     * >>> Strings.length8("はいはい") == 4
     * </code></pre>
     */
    inline
    public static function length8(str:String):Int {
        if (str == null)
            return 0;
      
        #if (flash || java || cs || python)
            return str.length;
        #elseif php
            return untyped __call__("mb_strlen", str, 'UTF-8');
        #else
            return Utf8.length(str);
        #end
    }
    
    /**
     * Left pads <b>str</b> with <b>padStr</b> until <b>targetLength</b> is reached.
     * 
     * <pre><code>
     * >>> Strings.lpad(null, 5, null)        == null
     * >>> Strings.lpad(null, 5, "")          == null
     * >>> Strings.lpad(null, 5, "cd")        == null
     * >>> Strings.lpad("ab", 5, null)        == "   ab"
     * >>> Strings.lpad("ab", 5, "")          == "   ab"
     * >>> Strings.lpad("ab", 5, "cd")        == "cdcdab"
     * >>> Strings.lpad("ab", 5, "cd", true)  == "cdcdab"
     * >>> Strings.lpad("ab", 5, "cd", false) == "dcdab"
     * >>> Strings.lpad("ab", 2, "cd")        == "ab"
     * >>> Strings.lpad("は", 3, " ")          == "  は"
     * >>> Strings.lpad("は", 3, "い")         == "いいは"
     * </code></pre>
     * 
     * @param canOverflow if <code>true</code>, the resulting string's length may exceed <b>targetLength</b> in case <b>padStr</b> contains more than one character.
     */
    public static function lpad(str:String, targetLength:Int, padStr:String = " ", canOverflow:Bool = true):String {
        var strLen = str.length8();
        if (str == null || strLen > targetLength)
            return str;

        if (padStr.isEmpty())
            padStr = " ";

        var sb = [ str ];
        var padLen = padStr.length8();
        while (strLen < targetLength) {
            sb.unshift(padStr);
            strLen += padLen;
        }

        if (canOverflow)
            return sb.join("");

        return sb.join("").substr(strLen - targetLength);
    }
    
    /**
     * Removes leading whitespace characters of <b>str</b>.
     * 
     * <pre><code>
     * >>> Strings.ltrim(null)      == null
     * >>> Strings.ltrim("")        == ""
     * >>> Strings.ltrim("   ")     == ""
     * >>> Strings.ltrim("\n\t\r")  == ""
     * >>> Strings.ltrim("  abc  ") == "abc  "
     * >>> Strings.ltrim("  はい  ") == "はい  "
     * </code></pre>
     */
    inline
    public static function ltrim(str:String):String {
        if (str.isEmpty()) 
            return str;

        return StringTools.ltrim(str);
    }
    
    /**
     * @return a string with each character/substring mapped by <b>mapper</b>.
     * 
     * <pre><code>
     * >>> Strings.map(null,     function(s) return s.equals("a") ? "xy" : s)      == null
     * >>> Strings.map("",       function(s) return s.equals("a") ? "xy" : s)      == []
     * >>> Strings.map("abab",   function(s) return s.equals("a") ? "xy" : s)      == ["xy", "b", "xy", "b"]
     * >>> Strings.map("はいはい", function(s) return s.equals("は") ? "い" : s)      == ["い", "い", "い", "い"]
     * >>> Strings.map("ab:cd",  function(s) return s.equals("ab")? "xy" : s, ":") == ["xy", "cd"]
     * </code></pre>
     */
    inline
    public static function map<T>(str:String, mapper:String -> T, separator = ""):Array<T> {
        if (str == null) 
            return null;

        return str.split8(separator).map(mapper);
	}
    
    /**
     * <pre><code>
     * >>> Strings.prependIfMissing(null, null)   == null
     * >>> Strings.prependIfMissing(null, "")     == null
     * >>> Strings.prependIfMissing("", "")       == ""
     * >>> Strings.prependIfMissing("dog", null)  == "nulldog"
     * >>> Strings.prependIfMissing("dog", "/")   == "/dog"
     * >>> Strings.prependIfMissing("/dog", "/")  == "/dog"
     * >>> Strings.prependIfMissing("はい", "はい") == "はい"
     * >>> Strings.prependIfMissing("いは", "は")   == "はいは"
     * </code></pre>
     */
    public static function prependIfMissing(str:String, suffix:String):String {
        if (str == null) 
            return null;
            
        if (str.length == 0)
            return suffix + str;
        
        if (str.startsWith(suffix))
            return str;
            
        return suffix + str;
    }

    /**
     * Surrounds the string with double quotes and escapses contained double quote characters with backslashes.
     * 
     * <pre><code>
     * >>> Strings.quoteDouble(null)          == null
     * >>> Strings.quoteDouble("")            == '""'
     * >>> Strings.quoteDouble(" ")           == '" "'
     * >>> Strings.quoteDouble("dog")         == '"dog"'
     * >>> Strings.quoteDouble("dog's cat's") == '"dog\'s cat\'s"'
     * >>> Strings.quoteDouble('"dog" "cat"') == "\"\\\"dog\\\" \\\"cat\\\"\""
     * </code></pre>
     */
    public static function quoteDouble(str:String):String {
        if (str == null)
            return str;

        if (str.length == 0)
            return '""';
            
        if (!str.contains('"'))
            return '"' + str + '"';

        return '"' + str.replaceAll('"', '\\"') + '"';
    }

    /**
     * Surrounds the string with single quotes and escapses contained single quote characters with backslashes.
     * 
     * <pre><code>
     * >>> Strings.quoteSingle(null)          == null
     * >>> Strings.quoteSingle("")            == "''"
     * >>> Strings.quoteSingle(" ")           == "' '"
     * >>> Strings.quoteSingle("dog")         == "'dog'"
     * >>> Strings.quoteSingle("dog's cat's") == "'dog\\'s cat\\'s'"
     * >>> Strings.quoteSingle('"dog" "cat"') == "'\"dog\" \"cat\"'"
     * </code></pre>
     */
    public static function quoteSingle(str:String):String {

        if (str == null)
            return str;

        if (str.length == 0)
            return "''";
            
        if (!str.contains("'"))
            return "'" + str + "'";

        return "'" + str.replaceAll("'", "\\'") + "'";
    }
    
    /**
     * Removes all occurences of <b>searchFor</b> from the given string.
     * 
     * <pre><code>
     * >>> Strings.removeAll(null, null)  == null
     * >>> Strings.removeAll(null, "")    == null
     * >>> Strings.removeAll("", null)    == ""
     * >>> Strings.removeAll("", "")      == ""
     * >>> Strings.removeAll("abab", "a") == "bb"
     * </code></pre>
     */
    public static function removeAll(searchIn:String, searchFor:String):String {
        if (searchIn.isEmpty() || searchFor.isEmpty())
            return searchIn;

        return StringTools.replace(searchIn, searchFor, "");
    }
    
    /**
     * <pre><code>
     * >>> Strings.repeat(null, 3)      == null
     * >>> Strings.repeat(null, 3)      == null
     * >>> Strings.repeat("", 0)        == ""
     * >>> Strings.repeat("", 3)        == ""
     * >>> Strings.repeat("a", -1)      == ""
     * >>> Strings.repeat("a", 0)       == ""
     * >>> Strings.repeat("a", 1)       == "a"
     * >>> Strings.repeat("a", 3)       == "aaa"
     * >>> Strings.repeat("a", 3, null) == "aaa"
     * >>> Strings.repeat("a", 3, "")   == "aaa"
     * >>> Strings.repeat("a", 3, ",")  == "a,a,a"
     * >>> Strings.repeat("は", 3, "い") == "はいはいは"
     * </code></pre>
     */
    public static function repeat(str:String, count:Int, separator:String = ""):String {
        if (str == null)
            return null;
            
        if (count < 1)
            return "";
            
        if (count == 1)
            return str;
            
        return [ for(i in 0...count) str ].join(separator);
    }
    
    /**
     * Replaces all occurrences of <b>searchFor</b> in <b>searchIn</b> by <b>replaceWith</b>.
     *
     * <pre><code>
     * >>> Strings.replaceAll(null, "dog", "***")           == null
     * >>> Strings.replaceAll("", "dog", "***")             == ""
     * >>> Strings.replaceAll("dogCATdogCAT", "dog", "***") == "***CAT***CAT"
     * >>> Strings.replaceAll("dogCATdog", "dog", null)     == "nullCATnull"
     * >>> Strings.replaceAll("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
     * >>> Strings.replaceAll("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
     * >>> Strings.replaceAll("d", "", ",")                 == "d"
     * >>> Strings.replaceAll("dogCATdogCAT", "", ",")      == "d,o,g,C,A,T,d,o,g,C,A,T"
     * >>> Strings.replaceAll("はいはい", "は", "い")          == "いいいい"
     * </code></pre>
     */
    public static function replaceAll(searchIn:String, searchFor:String, replaceWith:String):String {
        if (searchIn == null || searchIn.isEmpty() || searchFor == null)
            return searchIn;

        if (replaceWith == null) replaceWith = "null";
        
        return StringTools.replace(searchIn, searchFor, replaceWith);
    }
    
    /**
     * Replaces the first occurrence of <b>searchFor</b> in <b>searchIn</b> by <b>replaceWith</b>.
     *
     * <pre><code>
     * >>> Strings.replaceFirst(null, "dog", "***")           == null
     * >>> Strings.replaceFirst("", "dog", "***")             == ""
     * >>> Strings.replaceFirst("a", "", ",")                 == "a"
     * >>> Strings.replaceFirst("dogCATdogCAT", "dog", "***") == "***CATdogCAT"
     * >>> Strings.replaceFirst("dogCATdogCAT", "dog", null)  == "nullCATdogCAT"
     * >>> Strings.replaceFirst("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
     * >>> Strings.replaceFirst("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
     * >>> Strings.replaceFirst("d", "", ",")                 == "d"
     * >>> Strings.replaceFirst("dogCATdogCAT", "", ",")      == "d,ogCATdogCAT"
     * >>> Strings.replaceFirst("はいはい", "は", "い")          == "いいはい"
     * </code></pre>
     */
    public static function replaceFirst(searchIn:String, searchFor:String, replaceWith:String):String {
        if (searchIn == null || searchIn.isEmpty() || searchFor == null)
            return searchIn;

        if (replaceWith == null) replaceWith = "null";

        var foundAt;
        if (searchFor.length == 0)
            if(searchIn.length8() > 1)
                foundAt = 1;
            else
                return searchIn
        else
            foundAt = searchIn.indexOf8(searchFor);
            
        return searchIn.substr8(0, foundAt) + replaceWith + searchIn.substr8(foundAt + searchFor.length8());
    }

    /**
     * Replaces the first occurrence of <b>searchFor</b> in <b>searchIn</b> by <b>replaceWith</b> igorning the case.
     *
     * <pre><code>
     * >>> Strings.replaceFirstIgnoreCase(null, "dog", "***")           == null
     * >>> Strings.replaceFirstIgnoreCase("", "dog", "***")             == ""
     * >>> Strings.replaceFirstIgnoreCase("a", "", ",")                 == "a"
     * >>> Strings.replaceFirstIgnoreCase("dogCATdogCAT", "DOG", "***") == "***CATdogCAT"
     * >>> Strings.replaceFirstIgnoreCase("dogCATdogCAT", "DOG", null)  == "nullCATdogCAT"
     * >>> Strings.replaceFirstIgnoreCase("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
     * >>> Strings.replaceFirstIgnoreCase("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
     * >>> Strings.replaceFirstIgnoreCase("d", "", ",")                 == "d"
     * >>> Strings.replaceFirstIgnoreCase("dogCATdogCAT", "", ",")      == "d,ogCATdogCAT"
     * >>> Strings.replaceFirstIgnoreCase("はいはい", "は", "い")          == "いいはい"
     * </code></pre>
     */
    public static function replaceFirstIgnoreCase(searchIn:String, searchFor:String, replaceWith:String):String {
        if (searchIn == null || searchIn.isEmpty() || searchFor == null)
            return searchIn;

        if (replaceWith == null) replaceWith = "null";

        searchFor = searchFor.toLowerCase();
        
        var foundAt;
        if (searchFor.length == 0)
            if(searchIn.length8() > 1)
                foundAt = 1;
            else
                return searchIn
        else
            foundAt = searchIn.toLowerCase().indexOf8(searchFor);
            
        return searchIn.substr8(0, foundAt) + replaceWith + searchIn.substr8(foundAt + searchFor.length8());
    }
    
    /**
     * <pre><code>
     * >>> Strings.reverse(null) == null
     * >>> Strings.reverse("")   == ""
     * >>> Strings.reverse("a")   == "a"
     * >>> Strings.reverse("ab")  == "ba"
     * >>> Strings.reverse("いは") == "はい"
     * </code></pre>
     */
    public static function reverse(str:String):String {
        if (str.isEmpty())
            return str;

        var chars:Array<String> = str.split8("");
        chars.reverse();
        return chars.join("");
    }
    
    /**
     * Right pads <b>str</b> with <b>padStr</b> until <b>targetLength</b> is reached.
     * 
     * <pre><code>
     * >>> Strings.rpad(null, 5, null)        == null
     * >>> Strings.rpad(null, 5, "")          == null
     * >>> Strings.rpad(null, 5, "cd")        == null
     * >>> Strings.rpad("ab", 5, null)        == "ab   "
     * >>> Strings.rpad("ab", 5, "")          == "ab   "
     * >>> Strings.rpad("ab", 5, "cd")        == "abcdcd"
     * >>> Strings.rpad("ab", 5, "cd", true)  == "abcdcd"
     * >>> Strings.rpad("ab", 5, "cd", false) == "abcdc"
     * >>> Strings.rpad("ab", 2, "cd")        == "ab"
     * >>> Strings.rpad("は", 3, " ")          == "は  "
     * >>> Strings.rpad("は", 3, "い")         == "はいい"
     * </code></pre>
     * 
     * @param canOverflow if <code>true</code>, the resulting string's length may exceed <b>targetLength</b> in case <b>padStr</b> contains more than one character.
     */
    public static function rpad(str:String, targetLength:Int, padStr:String = " ", canOverflow:Bool = true):String {
        var strLen = str.length8();
        if (str == null || strLen > targetLength)
            return str;

        if (padStr.isEmpty())
            padStr = " ";

        var padLen = padStr.length8();
        var sb = new StringBuilder(str);
        while (strLen < targetLength) {
            sb.add(padStr);
            strLen += padLen;
        }

        if (canOverflow)
            return sb.toString();

        return sb.toString().truncate(targetLength);
    }

    /**
     * Removes trailing whitespace characters.
     * 
     * <pre><code>
     * >>> Strings.rstrip(null)      == null
     * >>> Strings.rstrip("")        == ""
     * >>> Strings.rstrip("   ")     == ""
     * >>> Strings.rstrip("\n\t\r")  == ""
     * >>> Strings.rstrip("  abc  ") == "  abc"
     * >>> Strings.rstrip("  はい  ") == "  はい"
     * </code></pre>
     */
    inline
    public static function rstrip(str:String):String {
        if (str.isEmpty()) 
            return str;

        return StringTools.rtrim(str);
    }

    /**
     * String#split() variant with cross-platform UTF-8 support and consistent behavior.
     * 
     * @param max split limit, the maximum number of elements in the resulting array
     * 
     * <pre><code>
     * >>> Strings.split8(null, null)         == null
     * >>> Strings.split8(null, "")           == null
     * >>> Strings.split8("", "")             == []
     * >>> Strings.split8("a.b.c", null)      == null
     * >>> Strings.split8("a.b.c", "")        == [ "a", ".", "b", ".", "c" ]
     * >>> Strings.split8("a.b.c", "", 3)     == [ "a", ".", "b.c" ]
     * >>> Strings.split8("a.b.c", "", 9)     == [ "a", ".", "b", ".", "c" ]
     * >>> Strings.split8("a.b.c", ".")       == [ "a", "b", "c" ]
     * >>> Strings.split8("a.b.c", ".", 2)    == [ "a", "b.c" ]
     * >>> Strings.split8(".a.b.c.", ".")     == [ "", "a", "b", "c", "" ]
     * >>> Strings.split8(".a.b.c.", ".", 3)  == [ "", "a", "b.c." ]
     * >>> Strings.split8(".a.b.c.", ".", 9)  == [ "", "a", "b", "c", "" ]
     * >>> Strings.split8(".a.b.c.", ".", -1) == [ "", "a", "b", "c", "" ]
     * >>> Strings.split8("はい", "")          == [ "は", "い" ]
     * </code></pre>
     */
    public static function split8(str:String, separator:String, ?max:Int = 0):Array<String> {
        if (str == null || separator == null)
            return null;
            
        var strLen = str.length8();
        
        if (strLen == 0)
            return [];

        #if (flash || java || cs || python)
            if(max <= 0)
                return str.split(separator);
        #end

        if (separator.isEmpty()) {
            if(max <= 0)
                return [ for (i in 0...strLen) Utf8.sub(str, i, 1) ];
            
            if (max > strLen) 
                max = strLen;
            max--;
            var result = [ for (i in 0...max) Utf8.sub(str, i, 1) ];
            result.push(Utf8.sub(str, max, strLen - max));
            return result;
        }
        
        var separatorLen = separator.length8();
        var lastFoundAt = 0;
        var result = [];
        var resultCount = 0;
        while (true) {
            var foundAt = str.indexOf8(separator, lastFoundAt);
            resultCount++;
            if (foundAt == POS_NOT_FOUND || resultCount == max) {
                result.push(Utf8.sub(str, lastFoundAt, strLen - lastFoundAt));
                break;
            }
            result.push(Utf8.sub(str, lastFoundAt, foundAt - lastFoundAt));
            lastFoundAt = foundAt + separatorLen;
        }
        return result;
    }
    
    /**
     * Splits all lines.
     * 
     * <pre><code>
     * >>> Strings.splitLines(null)             == []
     * >>> Strings.splitLines("")               == []
     * >>> Strings.splitLines(" dog ")          == [ " dog " ]
     * >>> Strings.splitLines(" dog \n cat ")   == [ " dog ", " cat " ]
     * >>> Strings.splitLines(" dog \r\n cat ") == [ " dog ", " cat " ]
     * </code></pre>
     */
    public static function splitLines(str:String):Array<String> {
        if (str.isEmpty())
            return [];

        return REGEX_SPLIT_LINES.splitAll(str);
    }

    /**
     * <pre><code>
     * >>> Strings.startsWith(null, "cat")     == false
     * >>> Strings.startsWith("", "")          == true
     * >>> Strings.startsWith("dogcat", null)  == false
     * >>> Strings.startsWith("dogcat", "")    == true
     * >>> Strings.startsWith("dogcat", "dog") == true
     * >>> Strings.startsWith("dogcat", "cat") == false
     * </code></pre>
     */
    public static function startsWith(searchIn:String, searchFor:String):Bool {
        if (searchIn == null || searchFor == null)
            return false;
        
        if (searchFor.isEmpty()) 
            return true;
            
        return StringTools.startsWith(searchIn, searchFor);
    }
    
    /**
     * <pre><code>
     * >>> Strings.startsWithIgnoreCase(null, "cat")     == false
     * >>> Strings.startsWithIgnoreCase("", "")          == true
     * >>> Strings.startsWithIgnoreCase("dogcat", null)  == false
     * >>> Strings.startsWithIgnoreCase("dogcat", "")    == true
     * >>> Strings.startsWithIgnoreCase("dogcat", "DOG") == true
     * >>> Strings.startsWithIgnoreCase("dogcat", "cat") == false
     * </code></pre>
     */
    public static function startsWithIgnoreCase(searchIn:String, searchFor:String):Bool {
        if (searchIn == null || searchFor == null)
            return false;
        
        if (searchFor.isEmpty()) 
            return true;
            
        return StringTools.startsWith(searchIn.toLowerCase(), searchFor.toLowerCase());
    }
    

    /**
     * Removes all ANSI escape sequences from the given string.
     * 
     * <pre><code>
     * >>> Strings.stripAnsi(null)                         == null
     * >>> Strings.stripAnsi("")                           == ""
     * >>> Strings.stripAnsi("\x1B[1mHello World!\x1B[0m") == "Hello World!"
     * </code></pre>
     */
    public static function stripAnsi(str:String):String {
        if (str.isEmpty())
            return str;

        return REGEX_ANSI_ESC.replaceAll(str, "");
    }

    /**
     * Removes all XML tags from the given string.
     * 
     * <pre><code>
     * >>> Strings.stripTags(null)                   == null
     * >>> Strings.stripTags("")                     == ""
     * >>> Strings.stripTags("dog")                  == "dog"
     * >>> Strings.stripTags("<b>dog</b>")           == "dog"
     * >>> Strings.stripTags("<!-- cat -->dog")      == "dog"
     * >>> Strings.stripTags("<ol><li>dog</ol>")     == "dog"
     * >>> Strings.stripTags("<b\n>dog\n</b\n>")     == "dog\n"
     * >>> Strings.stripTags("<b>はい</b>")           == "はい"
     * </code></pre>
     */
    inline
    public static function stripTags(xml:String):String {
        if (xml.isEmpty())
            return xml;

        #if php
            return untyped __call__("strip_tags", xml);
        #else
            return REGEX_STRIP_XML_TAGS.replaceAll(xml, "");
        #end
    }

    /**
     * @return <b>len</b> characters of <b>str</b>, starting from <b>startAt</b>.
     * 
     * <pre><code>
     * >>> Strings.substr8(null, 0)        == null
     * >>> Strings.substr8("", 0)          == ""
     * >>> Strings.substr8("", 10)         == ""
     * >>> Strings.substr8("dog", 0)       == "dog"
     * >>> Strings.substr8("dog", 1)       == "og"
     * >>> Strings.substr8("dog", 0, 0)    == ""
     * >>> Strings.substr8("dog", 0, 2)    == "do"
     * >>> Strings.substr8("dog", 0, -1)   == ""
     * >>> Strings.substr8("dog", -2)      == "og"
     * >>> Strings.substr8("dog", -20)     == "dog"
     * >>> Strings.substr8("dog", 1, 1)    == "o"
     * >>> Strings.substr8("dog", 1, 3)    == "og"
     * >>> Strings.substr8("はいはい", 1)    == "いはい"
     * >>> Strings.substr8("はいはい", 2)    == "はい"
     * >>> Strings.substr8("はいはい", 1, 2) == "いは"
     * </code></pre>
     */
    public static function substr8(str:String, startAt:CharPos, ?len:Int):String {
        if (str.isEmpty())
            return str;

        if (len == null) {
            len = str.length8();
        }
        
        if (len <= 0)
            return "";
        
        if (startAt < 0) {
            startAt += str.length8();
            if (startAt < 0) startAt = 0;
        }
            
        #if (flash || java || cs || python)
            return str.substr(startAt, len);
        #elseif php
            return untyped __call__("mb_substr", str, startAt, len, 'UTF-8');
        #else           
            if (len < 0) {
                if (startAt != 0)
                    return "";
                len = str.length8() - startAt + len;
                if (len <= 0)
                    return "";
            }

            return Utf8.sub(str, startAt, len);
        #end
    }

    /**
     * String#substring() variant with cross-platform UTF-8 support.
     * 
     * @return the part of <b>str</b> from <b>startAt</b> to but not including <b>endAt</b>.
     * 
     * <pre><code>
     * >>> Strings.substring8(null, 0)         == null
     * >>> Strings.substring8("", 0)           == ""
     * >>> Strings.substring8("", 10)          == ""
     * >>> Strings.substring8("dog", 0)        == "dog"
     * >>> Strings.substring8("dog", 1)        == "og"
     * >>> Strings.substring8("dog", 0, 0)     == ""
     * >>> Strings.substring8("dog", 0, 2)     == "do"
     * >>> Strings.substring8("dog", 0, -1)    == ""
     * >>> Strings.substring8("dog", 1, -1)    == "d"
     * >>> Strings.substring8("dog", 0, -10)   == ""
     * >>> Strings.substring8("dog", -2)       == "dog"
     * >>> Strings.substring8("dog", -20)      == "dog"
     * >>> Strings.substring8("dog", 1, 1)     == ""
     * >>> Strings.substring8("dog", 1, 2)     == "o"
     * >>> Strings.substring8("はいはい", 1)     == "いはい"
     * >>> Strings.substring8("はいはい", 2)     == "はい"
     * >>> Strings.substring8("はいはい", 1, 2)  == "い"
     * >>> Strings.substring8("はいはい", 2)     == "はい"
     * </code></pre>
     */
    public static function substring8(str:String, startAt:CharPos, ?endAt:CharPos):String {
        if (str.isEmpty())
            return str;
            
        if (endAt == null)
            endAt = str.length8();

        #if (flash || java || cs || python)
            return str.substring(startAt, endAt);
        #else
            if (startAt < 0) startAt = 0;
            if (endAt < 0) endAt = 0;
            if (startAt > endAt) {
                var tmp = startAt;
                startAt = endAt;
                endAt = tmp;
            }
            #if php
                return untyped __call__("mb_substr", str, startAt, endAt - startAt, 'UTF-8');
            #else
                return Utf8.sub(str, startAt, endAt - startAt);        
            #end
        #end
    }

    /**
     * <pre><code>
     * >>> Strings.substringAfter(null, "dog")           == null
     * >>> Strings.substringAfter("", "dog")             == ""
     * >>> Strings.substringAfter("dogCATdogCAT", "dog") == "CATdogCAT"
     * >>> Strings.substringAfter("dogCATdogBAA", "BAA") == ""
     * >>> Strings.substringAfter("dogCATdogCAT", null)  == ""
     * >>> Strings.substringAfter("dogCATdogCAT", "")    == ""
     * >>> Strings.substringAfter("はいはい", "い")        == "はい"
     * </code></pre>
     */
    public static function substringAfter(str:String, separator:String):String {
        if (str.isEmpty())
            return str;
        
        if (separator.isEmpty()) 
            return "";
        
        var foundAt = str.indexOf(separator);
        if (foundAt == POS_NOT_FOUND) {
            return "";
        }
        return str.substring(foundAt + separator.length);
    }
    
    /**
     * <pre><code>
     * >>> Strings.substringAfterIgnoreCase(null, "dog")           == null
     * >>> Strings.substringAfterIgnoreCase("", "dog")             == ""
     * >>> Strings.substringAfterIgnoreCase("dogCATdogCAT", "DOG") == "CATdogCAT"
     * >>> Strings.substringAfterIgnoreCase("dogCATdogBAA", "BAA") == ""
     * >>> Strings.substringAfterIgnoreCase("dogCATdogCAT", null)  == ""
     * >>> Strings.substringAfterIgnoreCase("dogCATdogCAT", "")    == ""
     * >>> Strings.substringAfterIgnoreCase("はいはい", "い")        == "はい"
     * </code></pre>
     */
    public static function substringAfterIgnoreCase(str:String, separator:String):String {
        if (str.isEmpty())
            return str;
        
        if (separator.isEmpty()) 
            return "";
            
        separator = separator.toLowerCase();
        
        var foundAt = str.toLowerCase().indexOf(separator);
        if (foundAt == POS_NOT_FOUND) {
            return "";
        }
        return str.substring(foundAt + separator.length);
    }
    
    /**
     * <pre><code>
     * >>> Strings.substringAfterLast(null, "dog")           == null
     * >>> Strings.substringAfterLast("", "dog")             == ""
     * >>> Strings.substringAfterLast("dogCATdogCAT", "dog") == "CAT"
     * >>> Strings.substringAfterLast("dogCATdogCAT", "CAT") == ""
     * >>> Strings.substringAfterLast("dogCATdogCAT", null)  == ""
     * >>> Strings.substringAfterLast("dogCATdogCAT", "")    == ""
     * >>> Strings.substringAfterLast("はいはい", "は")        == "い"
     * </code></pre>
     */
    public static function substringAfterLast(str:String, separator:String):String {
        if (str.isEmpty())
            return str;
        
        if (separator.isEmpty()) 
            return "";
            
        var foundAt = str.lastIndexOf(separator);
        if (foundAt == POS_NOT_FOUND) {
            return "";
        }
        return str.substring(foundAt + separator.length);
    }
    
    /**
     * <pre><code>
     * >>> Strings.substringAfterLastIgnoreCase(null, "dog")           == null
     * >>> Strings.substringAfterLastIgnoreCase("", "dog")             == ""
     * >>> Strings.substringAfterLastIgnoreCase("dogCATdogCAT", "dog") == "CAT"
     * >>> Strings.substringAfterLastIgnoreCase("dogCATdogCAT", "DOG") == "CAT"
     * >>> Strings.substringAfterLastIgnoreCase("dogCATdogCAT", "CAT") == ""
     * >>> Strings.substringAfterLastIgnoreCase("dogCATdogCAT", null)  == ""
     * >>> Strings.substringAfterLastIgnoreCase("dogCATdogCAT", "")    == ""
     * >>> Strings.substringAfterLastIgnoreCase("はいはい", "は")        == "い"
     * </code></pre>
     */
    public static function substringAfterLastIgnoreCase(str:String, separator:String):String {
        if (str.isEmpty())
            return str;
        
        if (separator.isEmpty()) 
            return "";
            
        separator = separator.toLowerCase();
            
        var foundAt = str.toLowerCase().lastIndexOf(separator);
        if (foundAt == POS_NOT_FOUND) {
            return "";
        }
        return str.substring(foundAt + separator.length);
    }
    
    /**
     * <pre><code>
     * >>> Strings.substringBefore(null, "dog")           == null
     * >>> Strings.substringBefore("", "dog")             == ""
     * >>> Strings.substringBefore("dogCATdogCAT", "CAT") == "dog"
     * >>> Strings.substringBefore("dogCATdogCAT", "dog") == ""
     * >>> Strings.substringBefore("dogCATdogCAT", null)  == ""
     * >>> Strings.substringBefore("dogCATdogCAT", "")    == ""
     * >>> Strings.substringBefore("はいはい", "い")        == "は"
     * </code></pre>
     */
    public static function substringBefore(str:String, separator:String):String {
        if (str.isEmpty())
            return str;
        
        if (separator.isEmpty()) 
            return "";
            
        var foundAt = str.indexOf(separator);
        if (foundAt == POS_NOT_FOUND) {
            return "";
        }
        return str.substring(0, foundAt);
    }
    
    /**
     * <pre><code>
     * >>> Strings.substringBeforeIgnoreCase(null, "dog")           == null
     * >>> Strings.substringBeforeIgnoreCase("", "dog")             == ""
     * >>> Strings.substringBeforeIgnoreCase("dogCATdogCAT", "CAT") == "dog"
     * >>> Strings.substringBeforeIgnoreCase("dogCATdogCAT", "cat") == "dog"
     * >>> Strings.substringBeforeIgnoreCase("dogCATdogCAT", "dog") == ""
     * >>> Strings.substringBeforeIgnoreCase("dogCATdogCAT", null)  == ""
     * >>> Strings.substringBeforeIgnoreCase("dogCATdogCAT", "")    == ""
     * >>> Strings.substringBeforeIgnoreCase("はいはい", "い")        == "は"
     * </code></pre>
     */
    public static function substringBeforeIgnoreCase(str:String, separator:String):String {
        if (str.isEmpty())
            return str;
        
        if (separator.isEmpty()) 
            return "";
            
        separator = separator.toLowerCase();
            
        var foundAt = str.toLowerCase().indexOf(separator);
        if (foundAt == POS_NOT_FOUND) {
            return "";
        }
        return str.substring(0, foundAt);
    }
    
    /**
     * <pre><code>
     * >>> Strings.substringBeforeLast(null, "dog")           == null
     * >>> Strings.substringBeforeLast("", "dog")             == ""
     * >>> Strings.substringBeforeLast("dogCATdogCAT", "CAT") == "dogCATdog"
     * >>> Strings.substringBeforeLast("dogCATdogCAT", "dog") == "dogCAT"
     * >>> Strings.substringBeforeLast("fo1CATdogCAT", "fo1") == ""
     * >>> Strings.substringBeforeLast("dogCATdogCAT", null)  == ""
     * >>> Strings.substringBeforeLast("dogCATdogCAT", "")    == ""
     * >>> Strings.substringBeforeLast("はいはい", "い")        == "はいは"
     * </code></pre>
     */
    public static function substringBeforeLast(str:String, separator:String):String {
        if (str.isEmpty())
            return str;
        
        if (separator.isEmpty()) 
            return "";
            
        var foundAt = str.lastIndexOf(separator);
        if (foundAt == POS_NOT_FOUND) {
            return "";
        }
        return str.substring(0, foundAt);
    }
        
    /**
     * <pre><code>
     * >>> Strings.substringBeforeLastIgnoreCase(null, "dog")           == null
     * >>> Strings.substringBeforeLastIgnoreCase("", "dog")             == ""
     * >>> Strings.substringBeforeLastIgnoreCase("dogCATdogCAT", "cat") == "dogCATdog"
     * >>> Strings.substringBeforeLastIgnoreCase("dogCATdogCAT", "DOG") == "dogCAT"
     * >>> Strings.substringBeforeLastIgnoreCase("fo1CATdogCAT", "Fo1") == ""
     * >>> Strings.substringBeforeLastIgnoreCase("dogCATdogCAT", null)  == ""
     * >>> Strings.substringBeforeLastIgnoreCase("dogCATdogCAT", "")    == ""
     * >>> Strings.substringBeforeLastIgnoreCase("はいはい", "い")        == "はいは"
     * </code></pre>
     */
    public static function substringBeforeLastIgnoreCase(str:String, separator:String):String {
        if (str.isEmpty())
            return str;
        
        if (separator.isEmpty()) 
            return "";
            
        separator = separator.toLowerCase();
            
        var foundAt = str.toLowerCase().lastIndexOf(separator);
        if (foundAt == POS_NOT_FOUND) {
            return "";
        }
        return str.substring(0, foundAt);
    }
    
    /**
     * @return false if value is null, "", "false" or "0". otherwise returns true.
     * 
     * <pre><code>
     * >>> Strings.toBool(null)    == false
     * >>> Strings.toBool("")      == false
     * >>> Strings.toBool("false") == false
     * >>> Strings.toBool("0")     == false
     * >>> Strings.toBool("true")  == true
     * >>> Strings.toBool("1")     == true
     * >>> Strings.toBool("2")     == true
     * >>> Strings.toBool("dog")   == true
     * </code></pre>
     */
    inline
    public static function toBool(str:String):Bool {
        if (str.isEmpty()) return false;
        
        return switch(str.toLowerCase()) {
            case "false", "0", "no": false;
            default: true;
        }
    }
    
    /**
     * @return the strings internal byte array
     * 
     * <pre><code>
     * >>> Strings.toBytes(null)                 == null
     * >>> Strings.toBytes("abc").getString(1,2) == "bc"
     * >>> Strings.toBytes("はい").getString(3,3) == "い"
     * </code></pre>
     */
    inline
    public static function toBytes(str:String):Bytes {
        // the method is intentionally not called getBytes() as it would result
        // in a name clash when used as static extenion in Java
        if (str == null)
            return null;
            
        return Bytes.ofString(str);
    }
        
    /**
     * Casts the given <code>Int</code> to <code>hx.strings.Char</code>.
     * 
     * Static extension for <code>Int</code>.
     * 
     * <pre><code>
     * >>> 32.toChar().toString() == " "
     * >>> 32.toChar().isSpace()  == true
     * </code></pre>
     */
    inline
    public static function toChar(charCode:Int):Char {
        return Char.of(charCode);
    }
    
    /**
     * @return array containing the codes of all characters
     * 
     * <pre><code>
     * >>> Strings.toChars(null)  == null
     * >>> Strings.toChars("")    == []
     * >>> Strings.toChars("  ")  == [ 32, 32 ]
     * >>> Strings.toChars(" は") == [ 32, 12399 ]
     * </code></pre>
     */
    public static function toChars(str:String):Array<Char> {
        if (str == null)
            return null;
        
        var strLen = str.length8();
        
        if (strLen == 0)
            return [];

        return [ for (i in 0...strLen) str._charCodeAt8Unsafe(i) ];
    }

    /**
     * @return an EReg object using the given string as regular expression pattern.
     * 
     * <pre><code>
     * >>> Strings.toEReg(null) == null
     * >>> Strings.toEReg(".*").match("foo") == true
     * </code></pre>
     */
    inline
    public static function toEReg(str:String, opt:String = ""):EReg {
        if(str == null)
            return null;
        return new EReg(str, opt);
    }
    
    /**
     * <pre><code>
     * >>> Strings.toFloat(null)    == null
     * >>> Strings.toFloat("")      == null
     * >>> Strings.toFloat("", -1)  == -1
     * >>> Strings.toFloat("0")     == 0
     * >>> Strings.toFloat("0", -1) == 0
     * >>> Strings.toFloat("1")     == 1
     * >>> Strings.toFloat("1.9")   == 1.9
     * >>> Strings.toFloat("a")     == null
     * >>> Strings.toFloat("a1")    == null
     * >>> Strings.toFloat("1a")    == 1
     * >>> Strings.toFloat("a", -1) == -1
     * </code></pre>
     */
    inline
    public static function toFloat(str:String, ifUnparseable:Null<Float>=null):Null<Float> {
        var result = Std.parseFloat(str);
        if (Math.isNaN(result))
            return ifUnparseable;
        return result;
    }
    
    /**
     * <pre><code>
     * >>> Strings.toInt(null)    == null
     * >>> Strings.toInt("")      == null
     * >>> Strings.toInt("", -1)  == -1
     * >>> Strings.toInt("0")     == 0
     * >>> Strings.toInt("0", -1) == 0
     * >>> Strings.toInt("1")     == 1
     * >>> Strings.toInt("1.9")   == 1
     * >>> Strings.toInt("a")     == null
     * >>> Strings.toInt("a1")    == null
     * >>> Strings.toInt("1a")    == 1
     * >>> Strings.toInt("a", -1) == -1
     * </code></pre>
     */
    inline
    public static function toInt(str:String, ifUnparseable:Null<Int>=null):Null<Int> {
        var result = Std.parseInt(str);
        if (result == null)
            return ifUnparseable;
        return result;
    }
    
    /**
     * String#toLowerCase() variant with cross-platform UTF-8 support and consistent behavior.
     * 
     * <pre><code>
     * >>> Strings.toLowerCase8(null)  == null
     * >>> Strings.toLowerCase8(""  )  == ""
     * >>> Strings.toLowerCase8("0")   == "0"
     * >>> Strings.toLowerCase8("DoG") == "dog"
     * >>> Strings.toLowerCase8("dog") == "dog"
     * >>> Strings.toLowerCase8("КОТ") == "кот"
     * </code></pre>
     */
    public static function toLowerCase8(str:String):String {
        if (str.isEmpty())
            return str;

        #if php
            return untyped __call__("mb_strtolower", str, 'UTF-8');
        #elseif (java || flash || cs || python)
            return str.toLowerCase();
        #else
            var sb = new StringBuilder();
            for (i in 0...str.length8()) {
                sb.addChar(str._charCodeAt8Unsafe(i).toLowerCase());
            }
            return sb.toString();
        #end
    }
    
    /**
     * Lowercase the first character of the given string.
     * 
     * <pre><code>
     * >>> Strings.toLowerCaseFirstChar(null)  == null
     * >>> Strings.toLowerCaseFirstChar(""  )  == ""
     * >>> Strings.toLowerCaseFirstChar("0")   == "0"
     * >>> Strings.toLowerCaseFirstChar("Dog") == "dog"
     * >>> Strings.toLowerCaseFirstChar("dog") == "dog"
     * >>> Strings.toLowerCaseFirstChar("Кот") == "кот"
     * </code></pre>
     */
    public static function toLowerCaseFirstChar(str:String):String {
        if (str.isEmpty())
            return str;

        var firstChar = str._charCodeAt8Unsafe(0).toLowerCase();
        
        if (str.length == 1)
            return firstChar;

        return firstChar + str.substr8(1);
    }
    
    /**
     * Naming convention for variables in e.g. Java.
     * 
     * First character lower case, e.g., "stringBuilder".
     * 
     * <pre><code>
     * >>> Strings.toLowerCamel(null)          == null
     * >>> Strings.toLowerCamel("")            == ""
     * >>> Strings.toLowerCamel("dog-cat")     == "dogCat"
     * >>> Strings.toLowerCamel("dog_cat")     == "dogCat"
     * >>> Strings.toLowerCamel("dog cat")     == "dogCat"
     * >>> Strings.toLowerCamel("AnXMLParser") == "anXMLParser"
     * </code></pre>
     */
    public static function toLowerCamel(str:String) {
        if (str.isEmpty())
            return str;
        
        var sb = new StringBuilder();
        for (word in _splitWordsUnsafe(str))
            sb.add(word.toUpperCaseFirstChar());
        return sb.toString().toLowerCaseFirstChar();
    }
    
    /**
     * Naming convention for e.g. XML tags.
     * 
     * Lower case words separated by hyphen, e.g. "string-builder".
     * 
     * <pre><code>
     * >>> Strings.toLowerHyphen(null)          == null
     * >>> Strings.toLowerHyphen("")            == ""
     * >>> Strings.toLowerHyphen("dog-cat")     == "dog-cat"
     * >>> Strings.toLowerHyphen("dog_cat")     == "dog-cat"
     * >>> Strings.toLowerHyphen("dog cat")     == "dog-cat"
     * >>> Strings.toLowerHyphen("AnXMLParser") == "an-xml-parser"
     * </code></pre>
     */
    public static function toLowerHyphen(str:String) {
        if (str.isEmpty())
            return str;

        return _splitWordsUnsafe(str).map(function(s) return s.toLowerCase8()).join("-");
    }
    
    /**
     * Naming convention for variables in e.g. C/C++.
     * 
     * Lower case words separated by underscore, e.g. "string_builder".
     * 
     * <pre><code>
     * >>> Strings.toLowerUnderscore(null)          == null
     * >>> Strings.toLowerUnderscore("")            == ""
     * >>> Strings.toLowerUnderscore("dog-cat")     == "dog_cat"
     * >>> Strings.toLowerUnderscore("dog_cat")     == "dog_cat"
     * >>> Strings.toLowerUnderscore("dog cat")     == "dog_cat"
     * >>> Strings.toLowerUnderscore("AnXMLParser") == "an_xml_parser"
     * </code></pre>
     */
    public static function toLowerUnderscore(str:String) {
        if (str.isEmpty())
            return str;

        return _splitWordsUnsafe(str).map(function(s) return s.toLowerCase8()).join("_");
    }
    
    /**
     * Naming convention for types in e.g. Java.
     * 
     * First character upper case, e.g., "StringBuilder".
     * 
     * <pre><code>
     * >>> Strings.toUpperCamel(null)          == null
     * >>> Strings.toUpperCamel("")            == ""
     * >>> Strings.toUpperCamel("dog-cat")     == "DogCat"
     * >>> Strings.toUpperCamel("dog_cat")     == "DogCat"
     * >>> Strings.toUpperCamel("dog cat")     == "DogCat"
     * >>> Strings.toUpperCamel("AnXMLParser") == "AnXMLParser"
     * </code></pre>
     */
    public static function toUpperCamel(str:String) {
        if (str.isEmpty())
            return str;
        
        var sb = new StringBuilder();
        for (word in _splitWordsUnsafe(str))
            sb.add(word.toUpperCaseFirstChar());
        return sb.toString();
    }
    
    /**
     * Naming convention for constants in e.g. Java.
     * 
     * All characters upper case separated by underscore, e.g. "STRING_BUILDER".
     * 
     * <pre><code>
     * >>> Strings.toUpperUnderscore(null)          == null
     * >>> Strings.toUpperUnderscore("")            == ""
     * >>> Strings.toUpperUnderscore("dog-cat")     == "DOG_CAT"
     * >>> Strings.toUpperUnderscore("dog_cat")     == "DOG_CAT"
     * >>> Strings.toUpperUnderscore("dog cat")     == "DOG_CAT"
     * >>> Strings.toUpperUnderscore("AnXMLParser") == "AN_XML_PARSER"
     * </code></pre>
     */
    public static function toUpperUnderscore(str:String) {
        if (str.isEmpty())
            return str;

        return _splitWordsUnsafe(str).map(function(s) return s.toUpperCase8()).join("_");
    }
    
    /**
     * <pre><code>
     * >>> Strings.toString(null)  == "null"
     * >>> Strings.toString("")    == ""
     * >>> Strings.toString("dog") == "dog"
     * >>> Strings.toString(1)     == "1"
     * >>> Strings.toString(true)  == "true"
     * >>> Strings.toString([1,2]) == "[1,2]"
     * </code></pre>
     */
    inline
    public static function toString<T>(str:T):String {
        return Std.string(str);
    }

    /**
     * String#toUpperCase() variant with cross-platform UTF-8 support and consistent behavior.
     * 
     * <pre><code>
     * >>> Strings.toUpperCase8(null)  == null
     * >>> Strings.toUpperCase8(""  )  == ""
     * >>> Strings.toUpperCase8("0")   == "0"
     * >>> Strings.toUpperCase8("dOg") == "DOG"
     * >>> Strings.toUpperCase8("DOG") == "DOG"
     * >>> Strings.toUpperCase8("кот") == "КОТ"
     * </code></pre>
     */
    public static function toUpperCase8(str:String):String {
        if (str.isEmpty())
            return str;

        #if php
            return untyped __call__("mb_strtoupper", str, 'UTF-8');
        #elseif (java || flash || cs || python)
            return str.toUpperCase();
        #else
            var sb = new StringBuilder();
            for (i in 0...str.length8()) {
                sb.addChar(str._charCodeAt8Unsafe(i).toUpperCase());
            }
            return sb.toString();
        #end
    }
    
    /**
     * Uppercase the first character of the given string.
     * 
     * <pre><code>
     * >>> Strings.toUpperCaseFirstChar(null)  == null
     * >>> Strings.toUpperCaseFirstChar(""  )  == ""
     * >>> Strings.toUpperCaseFirstChar("0")   == "0"
     * >>> Strings.toUpperCaseFirstChar("dog") == "Dog"
     * >>> Strings.toUpperCaseFirstChar("Dog") == "Dog"
     * >>> Strings.toUpperCaseFirstChar("кот") == "Кот"
     * </code></pre>
     */
    public static function toUpperCaseFirstChar(str:String):String {
        if (str.isEmpty())
            return str;

        var firstChar = str._charCodeAt8Unsafe(0).toUpperCase();

        if (str.length == 1)
            return firstChar;
        return firstChar + str.substr8(1);
    }
        
    /**
     * Removes leading and trailing whitespace characters.
     * 
     * <pre><code>
     * >>> Strings.trim(null)      == null
     * >>> Strings.trim("")        == ""
     * >>> Strings.trim("   ")     == ""
     * >>> Strings.trim("\n\t\r")  == ""
     * >>> Strings.trim("  abc  ") == "abc"
     * >>> Strings.trim("  はい  ") == "はい"
     * </code></pre>
     */
    inline
    public static function trim(str:String):String {
        if (str == null) 
            return str;

        return StringTools.trim(str);
    }
    
    /**
     * Trims all lines and changes new line character to linux style "\n".
     * 
     * <pre><code>
     * >>> Strings.trimLines(null)             == null
     * >>> Strings.trimLines("")               == ""
     * >>> Strings.trimLines(" dog ")          == "dog"
     * >>> Strings.trimLines(" dog \n cat ")   == "dog\ncat"
     * >>> Strings.trimLines(" dog \r\n cat ") == "dog\ncat"
     * </code></pre>
     */
    public static function trimLines(str:String):String {
        if (str.isEmpty())
            return str;

        return REGEX_SPLIT_LINES.splitAll(str).map(function(line) return line.trim()).join(NEW_LINE_NIX);
    }

    /**
     * <pre><code>
     * >>> Strings.trimToNull(null)      == null
     * >>> Strings.trimToNull("")        == null
     * >>> Strings.trimToNull("   ")     == null
     * >>> Strings.trimToNull("\n\t\r")  == null
     * >>> Strings.trimToNull("  abc  ") == "abc"
     * </code></pre>
     */
    inline
    public static function trimToNull(str:String):String {
        if (str == null)
            return null;
            
        var stripped = str.trim();
        
        if (stripped.isEmpty()) 
            return null;
            
        return stripped;
    }
    
    /**
     * <pre><code>
     * >>> Strings.trimToEmpty(null)      == ""
     * >>> Strings.trimToEmpty("")        == ""
     * >>> Strings.trimToEmpty("   ")     == ""
     * >>> Strings.trimToEmpty("\n\t\r")  == ""
     * >>> Strings.trimToEmpty("  abc  ") == "abc"
     * </code></pre>
     */
    inline
    public static function trimToEmpty(str:String):String {
        var stripped = str.trim();
        
        if (stripped.isEmpty()) 
            return "";

        return stripped;
    }

    /**
     * <pre><code>
     * >>> Strings.truncate(null, 0)      == null
     * >>> Strings.truncate(null, 5)      == null
     * >>> Strings.truncate("", 0)        == ""
     * >>> Strings.truncate("", 5)        == ""
     * >>> Strings.truncate("1234", 2)    == "12"
     * >>> Strings.truncate("1234", -1)   == ""
     * >>> Strings.truncate("はいはい", 2)  == "はい"
     * </code></pre>
     */
    public static function truncate(str:String, maxLength:Int):String {
        if (str.length8() <= maxLength)
            return str;

        return str.substring8(0, maxLength);
    }
    
    /**
     * <pre><code>
     * >>> Strings.urlDecode(null)                                == null
     * >>> Strings.urlDecode("")                                  == ""
     * >>> Strings.urlDecode("param1%3Ddog%26param2%3Ddog%20cat") == "param1=dog&param2=dog cat"
     * >>> Strings.urlDecode("%E3%81%AF%E3%81%84")                == "はい"
     * </code></pre>
     */
    inline
    public static function urlDecode(str:String):String {
        if (str.isEmpty()) 
            return str;

        #if php
            return untyped __call__("rawurldecode", str);
        #else
            return StringTools.urlDecode(str);
        #end
    }
    
    /**
     * <pre><code>
     * >>> Strings.urlEncode(null)                    == null
     * >>> Strings.urlEncode("")                      == ""
     * >>> Strings.urlEncode("param1=dog&param2=cat") == "param1%3Ddog%26param2%3Dcat"
     * >>> Strings.urlEncode("はい")                   == "%E3%81%AF%E3%81%84"
     * </pre></code>
     */
    inline
    public static function urlEncode(str:String):String {
        if (str.isEmpty()) 
            return str;

        #if php
            return untyped __call__("rawurlencode", str);
        #else
            return StringTools.urlEncode(str);
        #end
    }
}

class ANSIState {

    public var bgcolor:String;
    public var blink:Bool;
    public var bold:Bool;
    public var fgcolor:String;
    public var underline:Bool;

    public function new(?copyFrom:ANSIState) {
        if(copyFrom == null)
            reset();
        else
            this.copyFrom(copyFrom);
    }

    public function isActive():Bool {
        return fgcolor != null || bgcolor != null || bold || underline || blink;
    }

    public function reset():Void {
        fgcolor = null;
        bgcolor = null;
        bold = false;
        underline = false;
        blink = false;
    }
    
    public function copyFrom(other:ANSIState) {
        fgcolor = other.fgcolor;
        bgcolor = other.bgcolor;
        bold = other.bold;
        underline = other.underline;
        blink = other.blink;
    }

    public function setGraphicModeParameter(param:Int):Void {
        switch (param) {
            case 0: reset();
            case 1: bold = true;
            case 4: underline = true;
            case 5: blink = true;
            case 30: fgcolor = "black";
            case 31: fgcolor = "red";
            case 32: fgcolor = "green";
            case 33: fgcolor = "yellow";
            case 34: fgcolor = "blue";
            case 35: fgcolor = "magenta";
            case 36: fgcolor = "cyan";
            case 37: fgcolor = "white";
            case 40: bgcolor = "black";
            case 41: bgcolor = "red";
            case 42: bgcolor = "green";
            case 43: bgcolor = "yellow";
            case 44: bgcolor = "blue";
            case 45: bgcolor = "magenta";
            case 46: bgcolor = "cyan";
            case 47: bgcolor = "white";
        }
    }

    public function toCSS():String {
        if (isActive()) {
            var sb = new StringBuilder();
            if (fgcolor != null)
                sb.add("color:").add(fgcolor).add(";");
            if (bgcolor != null)
                sb.add("background-color:").add(bgcolor).add(";");
            if (bold)
                sb.add("font-weight:bold;");
            if (underline)
                sb.add("text-decoration:underline;");
            if (blink)
                sb.add("text-decoration: blink;");
            return sb.toString();
        }
        return "";
    }
}
