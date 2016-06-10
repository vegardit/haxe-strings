/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE.txt file for details.
 */
package hx.strings;

import hx.strings.internal.Either3;

using hx.strings.Strings;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@notThreadSafe
interface Matcher {
    
    /**
     * Iterates over all matches and invokes the mapper function for each match.
     * 
     * @return a string with all matches replaced by the mapper
     */
    public function map(mapper:Matcher -> String):String;
    
    /**
     * If no match attempt was made before Matcher#matches() will be excuted implicitly.
     * 
     * @return the substring captured by the n-th group of the current match.
     *         If <b>n</b> is <code>0</code>, then returns the whole string of the current match.
     * 
     * @throws an exception if no capturing group with the given index <b>n</b> exists
     */
    public function matched(n:Int = 0):String;

    /**
     * If no match attempt was made before Matcher#matches() will be excuted implicitly.
     * 
     * @return the position of the current match
     * 
     * @throws an exception if no match was found
     * 
     * <pre><code>
     * >>> Pattern.compile("c").matcher("abcde").matchedPos() == { pos: 2, length: 1 }
     * </code></pre>
     */
    public function matchedPos(): { pos:Int, len:Int };

    /**
     * Attempts to match the string against the pattern.
     * 
     * @return true if at least one match has been found
     *
     * <pre><code>
     * >>> Pattern.compile(".*").matcher("a").matches() == true
     * </code></pre>
     */
    public function matches():Bool;

    /**
     * Attempts to match the given region of the string against the pattern.
     * 
     * @return true if at least one match has been found
     *
     * <pre><code>
     * >>> Pattern.compile("b").matcher("aba").matchesInRegion(0)    == true
     * >>> Pattern.compile("b").matcher("aba").matchesInRegion(0, 1) == false
     * >>> Pattern.compile("b").matcher("aba").matchesInRegion(0, 2) == true
     * >>> Pattern.compile("b").matcher("aba").matchesInRegion(1)    == true
     * >>> Pattern.compile("b").matcher("aba").matchesInRegion(2)    == false
     * </code></pre>
     */
    public function matchesInRegion(pos:Int, len:Int=-1):Bool;
    
    /**
     * If no match attempt was made before Matcher#matches() will be excuted implicitly.
     * 
     * @return the substring after the current match or "" if no match was found
     *
     * <pre><code>
     * >>> Pattern.compile("b"     ).matcher("abab").substringAfterMatch() == "ab"
     * >>> Pattern.compile("b", "g").matcher("abab").substringAfterMatch() == "ab"
     * >>> Pattern.compile("c", "g").matcher("abab").substringAfterMatch() == ""
     * </code></pre>
     */
    public function substringAfterMatch():String;
    
    /**
     * If no match attempt was made before Matcher#matches() will be excuted implicitly.
     * 
     * @return the substring before the current match or "" if no match was found
     *
     * <pre><code>
     * >>> Pattern.compile("b"     ).matcher("abab").substringBeforeMatch() == "a"
     * >>> Pattern.compile("b", "g").matcher("abab").substringBeforeMatch() == "a"
     * >>> Pattern.compile("c", "g").matcher("abab").substringBeforeMatch() == ""
     * </code></pre>
     */
    public function substringBeforeMatch():String;
}

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:enum
abstract MatchingOption(String) {
    
    /**
     * case insensitive matching
     */
    var IGNORE_CASE = "i";
    
    /**
     * multiline matching, in the sense of that <code>^</code> and <code>$</code> represent the beginning and end of a line
     */
    var MULTILINE = "m";

    #if (cpp || flash || java || neko || php)
    /**
     * the dot <code>.</code> will also match new lines
     */
    var DOTALL = "s";
    #end
    
    /**
     * All map, split and replace operations are performed on all matches within the given string
     */
    var MATCH_ALL = "g";
}

/**
 * Thread safe API for regex pattern matching backed by Haxe's EReg class.
 * 
 * UTF8 matching is enabled by default.
 * 
 * @see http://haxe.org/manual/std-regex.html
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@immutable
@threadSafe
class Pattern {
    
    public var pattern(default, null):String;
    public var options(default, null):String;
    var ereg:EReg;
    
    /**
     * @param pattern regular expression
     * @param options matching options
     */
    public static function compile(pattern:String, options:Either3<String, MatchingOption, Array<MatchingOption>> = null):Pattern {
        if(options == null)
            return new Pattern(pattern, "");

        return new Pattern(pattern, switch(options.value) {
            case a(str): str.toLowerCase8().filterChars(function(ch) {
                    // remove unsupported flags
                    return 
                        ch == 'i' || ch == 'm' || ch == 'g'
                        #if (cpp || flash || java || neko || php)
                        || ch == 's'
                        #end
                        ;
                });
            case b(opt): opt.toString();
            case c(arr): arr.join("");
        });
    }
    
    function new(pattern:String, options:String) {
        this.pattern = pattern;
        this.options = options;
        this.ereg = new EReg(pattern, options);
        
        // explicitly enable UTF8
        this.options += "u";
    }

    /**
     * <pre><code>
     * >>> Pattern.compile(".*").matcher("a").matches() == true
     * </code></pre>
     * 
     * @return a matcher (not thread-safe) that works on the given input string
     */
    inline
    public function matcher(str:String):Matcher {
        return new MatcherImpl(ereg, pattern, options, str);
    }

    /**
     * Replaces all matches with <b>replaceWith</b>.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).replace("a.b.c", ":") == "a:b.c"
     * >>> Pattern.compile("[.]", "g").replace("a.b.c", ":") == "a:b:c"
     * </code></pre>
     */
    inline
    public function replace(str:String, replaceWith:String):String {
        return ereg.replace(str, replaceWith);
    }

    /**
     * Uses matches as separator to split the string.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).split("a.b.c") == [ "a", "b.c" ]
     * >>> Pattern.compile("[.]", "g").split("a.b.c") == [ "a", "b", "c" ]
     * </code></pre>
     */
    inline
    public function split(str:String):Array<String> {
        return ereg.split(str);
    }
}

private class MatcherImpl implements Matcher {
    
    var pattern:String;
    var options:String;
    var isMatch:Null<Bool>;
    var ereg:EReg;
    
    var str:String;
    
    public function new(ereg:EReg, pattern:String, options:String, str:String) {
        this.pattern = pattern;
        this.options = options;
        this.ereg = _cloneEReg(ereg, pattern, options);
        this.str = str;
    }
    
    public function map(mapper:Matcher -> String):String {
        return ereg.map(str, function(ereg) {
            isMatch = true;
            return mapper(this);
        });
    }

    public function matched(n:Int = 0):String {
        if (isMatch == null) matches();
        if (isMatch == false) throw "No string matched";
        
        var result = ereg.matched(n);
        #if (cs || php) // workaround for targets with non-compliant implementation
        if (result == null) throw 'Group $n not found.';
        #end
        return result;
    }
    
    inline
    public function matches():Bool {
        return isMatch = ereg.match(str);
    }

    inline
    public function matchesInRegion(pos:Int, len:Int=-1):Bool {
        return isMatch = ereg.matchSub(str, pos, len);
    }
    
    public function matchedPos(): { pos:Int, len:Int } {
        if (isMatch == null) matches();
        if (isMatch == false) throw "No string matched";

        return ereg.matchedPos();
    }
    
    public function substringAfterMatch():String {
        if (isMatch == null) matches();
        if (!isMatch) return "";
        return ereg.matchedRight();
    }
    
    public function substringBeforeMatch():String {
        if (isMatch == null) matches();
        if (!isMatch) return "";
        return ereg.matchedLeft();
    }

    static function _cloneEReg(from:EReg, pattern:String, options:String) {

        // partially copy internal state (if possible) to reuse the inner pre-compiled pattern instance
        // and avoid expensive reparsing of the pattern string
        #if (neko || lua || cpp || hl)
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "r", Reflect.field(from, "r"));
            Reflect.setField(clone, "global", Reflect.field(from, "global"));
        #elseif java
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "pattern", pattern);
            Reflect.setField(clone, "matcher", Reflect.field(from, "matcher"));
            Reflect.setField(clone, "isGlobal", Reflect.field(from, "isGlobal"));
        #elseif cs
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "regex", Reflect.field(from, "regex"));
            Reflect.setField(clone, "isGlobal", Reflect.field(from, "isGlobal"));
        #elseif php
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "pattern", pattern);
            Reflect.setField(clone, "options", Reflect.field(from, "options"));
            Reflect.setField(clone, "global", Reflect.field(from, "global"));
            Reflect.setField(clone, "re", Reflect.field(from, "re"));
        #elseif python
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "pattern", Reflect.field(from, "pattern"));
            Reflect.setField(clone, "global", Reflect.field(from, "global"));
        #else
            // not reusing internal state on 
            // - untested targets
            // - targets where the compiled pattern and matcher not separated internally (js, flash)
            var clone = new EReg(pattern, options);
        #end
        return clone;
    }
}
