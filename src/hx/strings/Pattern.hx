/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings;

import hx.strings.internal.Either3;

using hx.strings.Strings;

/**
 * Thread-safe API for regex pattern matching backed by Haxe's EReg class.
 *
 * UTF8 matching (EReg's 'u' flag) is enabled by default.
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
                        ch == "i" || ch == "m" || ch == "g"
                        #if (cpp || flash || java || neko || php)
                        || ch == "s"
                        #end
                        ;
                });
            case b(opt): Std.string(opt);
            case c(arr): arr.filter(function (m) return m != null /* remove null enties */).join("");
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
     * If <b>MatchingOption.MATCH_ALL</b> was specified, replaces all matches with <b>replaceWith</b>.
     * Otherwise only the first match.
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
     * If <b>MatchingOption.MATCH_ALL</b> was specified, removes all matches.
     * Otherwise only the first match.
     *
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).remove("a.b.c") == "ab.c"
     * >>> Pattern.compile("[.]", "g").remove("a.b.c") == "abc"
     * </code></pre>
     */
    inline
    public function remove(str:String):String {
        return ereg.replace(str, "");
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

/**
 * Performs match operations on a string by interpreting a regular expression pattern.
 *
 * Instances are created via the hx.strings.Pattern#matcher() function.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@notThreadSafe
interface Matcher {

    /**
     * Iterates over all matches and invokes the onMatch function for each match.
     */
    public function iterate(onMatch:Matcher -> Void):Void;

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
     * @throws exception if no capturing group with the given index <b>n</b> exists
     */
    public function matched(n:Int = 0):String;

    /**
     * If no match attempt was made before Matcher#matches() will be excuted implicitly.
     *
     * @return the position of the current match
     *
     * @throws exception if no match was found
     *
     * <pre><code>
     * >>> Pattern.compile("c").matcher("abcde").matchedPos() == { pos: 2, len: 1 }
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
     * Resets the matcher with the given input string
     *
     * <pre><code>
     * >>> Pattern.compile("b").matcher("abcb").reset("abCB").substringAfterMatch()  == "CB"
     * </code></pre>
     *
     * @return self reference
     */
    public function reset(str:String):Matcher;

    /**
     * If no match attempt was made before Matcher#matches() will be excuted implicitly.
     *
     * @return the substring after the current match or "" if no match was found
     *
     * <pre><code>
     * >>> Pattern.compile("b"     ).matcher("abcb").substringAfterMatch() == "cb"
     * >>> Pattern.compile("b", "g").matcher("abcb").substringAfterMatch() == "cb"
     * >>> Pattern.compile("d", "g").matcher("abcb").substringAfterMatch() == ""
     * </code></pre>
     */
    public function substringAfterMatch():String;

    /**
     * If no match attempt was made before Matcher#matches() will be excuted implicitly.
     *
     * @return the substring before the current match or "" if no match was found
     *
     * <pre><code>
     * >>> Pattern.compile("b"     ).matcher("abcb").substringBeforeMatch() == "a"
     * >>> Pattern.compile("b", "g").matcher("abcb").substringBeforeMatch() == "a"
     * >>> Pattern.compile("d", "g").matcher("abcb").substringBeforeMatch() == ""
     * </code></pre>
     */
    public function substringBeforeMatch():String;
}

/**
 * Options for compilation of regular expression patterns.
 *
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

private class MatcherImpl implements Matcher {
    var isMatch:Null<Bool>;
    var ereg:EReg;
    var str:String;

    public function new(ereg:EReg, pattern:String, options:String, str:String) {
        this.ereg = _cloneEReg(ereg, pattern, options);
        reset(str);
    }

    inline
    public function reset(str:String):Matcher {
        this.str = str;
        this.isMatch = null;
        return this;
    }

    public function iterate(onMatch:Matcher -> Void):Void {
        var startAt = 0;
        while(ereg.matchSub(str, startAt)) {
            isMatch = true;
            var matchedPos = ereg.matchedPos();
            onMatch(this);
            startAt = matchedPos.pos + matchedPos.len;

        }
        isMatch = false;
    }

    public function map(mapper:Matcher -> String):String {
        return ereg.map(str, function(ereg) {
            isMatch = true;
            return mapper(this);
        });
    }

    public function matched(n:Int = 0):String {
        if(isMatch == null) matches();
        if(!isMatch) throw "No string matched";

        var result = ereg.matched(n);

        #if (cs || php) // workaround for targets with non-compliant implementation
            if(result == null) throw 'Group $n not found.';
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
        if(isMatch == null) matches();
        if(!isMatch) throw "No string matched";
        return ereg.matchedPos();
    }

    public function substringAfterMatch():String {
        if(isMatch == null) matches();
        if(!isMatch) return "";
        return ereg.matchedRight();
    }

    public function substringBeforeMatch():String {
        if(isMatch == null) matches();
        if(!isMatch) return "";
        return ereg.matchedLeft();
    }

    function _cloneEReg(from:EReg, pattern:String, options:String) {

        // partially copy internal state (if possible) to reuse the inner pre-compiled pattern instance
        // and avoid expensive reparsing of the pattern string
        #if (neko || lua || cpp)
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
            // - targets where cloning results in runtime errors (hl)
            var clone = new EReg(pattern, options);
        #end
        return clone;
    }
}
