/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE.txt file for details.
 */
package hx.strings;

using hx.strings.Strings;

/**
 * Thread safe API for regex pattern matching backed by Haxe's EReg class
 * 
 * TODO implement missing regex operations
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
    var eregMatchAll:EReg;
    var eregMatchFirst:EReg;
    
    var isFirstMatcher = true;
    var matchAllByDefault:Bool;
    
    /**
     * @param pattern regular expression
     * @param options see http://haxe.org/manual/std-regex.html for possible values
     */
    public static function compile(pattern:String, options:String = "") {
        return new Pattern(pattern, options);
    }
    
    function new(pattern:String, options:String) {
        this.pattern = pattern;
        this.options = options;
        this.matchAllByDefault = options.contains("g");
        this.ereg = new EReg(pattern, options);
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
        return new MatcherImpl(pattern, options, ereg, matchAllByDefault, str);
    }
    
    /**
     * Replaces either the first or all matches, depending on if the "g" option was specified when the pattern was compiled.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).replace("a.b.c", ":") == "a:b.c"
     * >>> Pattern.compile("[.]", "g").replace("a.b.c", ":") == "a:b:c"
     * </code></pre>
     */
    public function replace(str:String, replaceWith:String):String {
        return ereg.replace(str, replaceWith);
    }
    
    /**
     * Replaces all matches with <b>replaceWith</b>
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).replaceAll("a.b.c", ":") == "a:b:c"
     * >>> Pattern.compile("[.]", "g").replaceAll("a.b.c", ":") == "a:b:c"
     * </code></pre>
     */
    public function replaceAll(str:String, replaceWith:String):String {
        if (eregMatchAll == null) eregMatchAll = MatcherImpl.cloneEReg(ereg, pattern, "g" + options);
        return eregMatchAll.replace(str, replaceWith);
    }
    
    /**
     * Replaces the first match with <b>replaceWith</b>
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).replaceFirst("a.b.c", ":") == "a:b.c"
     * >>> Pattern.compile("[.]", "g").replaceFirst("a.b.c", ":") == "a:b.c"
     * </code></pre>
     */
    public function replaceFirst(str:String, replaceWith:String):String {
        if (eregMatchFirst == null) eregMatchFirst = MatcherImpl.cloneEReg(ereg, pattern, options.removeAll("g"));
        return eregMatchFirst.replace(str, replaceWith);
    }

    /**
     * Splits either on the first or all matches, depending on if the "g" option was specified when the pattern was compiled.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).split("a.b.c")  == [ "a", "b.c" ]
     * >>> Pattern.compile("[.]", "g").split("a.b.c")  == [ "a", "b", "c" ]
     * </code></pre>
     */
    public function split(str:String):Array<String> {
        return ereg.split(str);
    }
    
    /**
     * Splits the string on all matches.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).splitAll("a.b.c")  == [ "a", "b", "c" ]
     * >>> Pattern.compile("[.]", "g").splitAll("a.b.c")  == [ "a", "b", "c" ]
     * </code></pre>
     */
    public function splitAll(str:String):Array<String> {
        if (eregMatchAll == null) eregMatchAll = MatcherImpl.cloneEReg(ereg, pattern, "g" + options);
        return eregMatchAll.split(str);
    }

    /**
     * Splits the string on the first match.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).splitOnce("a.b.c") == [ "a", "b.c" ]
     * >>> Pattern.compile("[.]", "g").splitOnce("a.b.c") == [ "a", "b.c" ]
     * </code></pre>
     */
    public function splitOnce(str:String):Array<String> {
        if (eregMatchFirst == null) eregMatchFirst = MatcherImpl.cloneEReg(ereg, pattern, options.removeAll("g"));
        return eregMatchFirst.split(str);
    }
}

@notThreadSafe
interface Matcher {

    /**
     * <pre><code>
     * >>> Pattern.compile(".*").matcher("a").matches() == true
     * </code></pre>
     */
    public function matches():Bool;
    
    /**
     * Replaces either the first or all matches, depending on if the "g" option was specified when the pattern was compiled.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).matcher("a.b.c").replace(":") == "a:b.c"
     * >>> Pattern.compile("[.]", "g").matcher("a.b.c").replace(":") == "a:b:c"
     * </code></pre>
     */
    public function replace(replaceWith:String):String;
    
    /**
     * Replaces all matches with <b>replaceWith</b>
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).matcher("a.b.c").replaceAll(":") == "a:b:c"
     * >>> Pattern.compile("[.]", "g").matcher("a.b.c").replaceAll(":") == "a:b:c"
     * </code></pre>
     */
    public function replaceAll(replaceWith:String):String;

    /**
     * Replaces the first match with <b>replaceWith</b>
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).matcher("a.b.c").replaceFirst(":") == "a:b.c"
     * >>> Pattern.compile("[.]", "g").matcher("a.b.c").replaceFirst(":") == "a:b.c"
     * </code></pre>
     */
    public function replaceFirst(replaceWith:String):String;

    /**
     * Splits either on the first or all matches, depending on if the "g" option was specified when the pattern was compiled.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).matcher("a.b.c").split()  == [ "a", "b.c" ]
     * >>> Pattern.compile("[.]", "g").matcher("a.b.c").split()  == [ "a", "b", "c" ]
     * </code></pre>
     */
    public function split():Array<String>;
    
    /**
     * Splits the string on all matches.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).matcher("a.b.c").splitAll()  == [ "a", "b", "c" ]
     * >>> Pattern.compile("[.]", "g").matcher("a.b.c").splitAll()  == [ "a", "b", "c" ]
     * </code></pre>
     */
    public function splitAll():Array<String>;

    /**
     * Splits the string on the first match.
     * 
     * <pre><code>
     * >>> Pattern.compile("[.]"     ).matcher("a.b.c").splitOnce()  == [ "a", "b.c" ]
     * >>> Pattern.compile("[.]", "g").matcher("a.b.c").splitOnce()  == [ "a", "b.c" ]
     * </code></pre>
     */
    public function splitOnce():Array<String>;
}

private class MatcherImpl implements Matcher {
    
    var ereg:EReg;
    var eregMatchFirst:EReg;
    var eregMatchAll:EReg;

    var pattern:String;
    var options:String;
    var matchAllByDefault:Bool;
    
    var str:String;
    
    public function new(pattern:String, options:String, compiled:EReg, matchAllByDefault:Bool, str:String) {
        this.ereg = cloneEReg(compiled, pattern, options);
        if (matchAllByDefault) {
            this.eregMatchFirst = null;
            this.eregMatchAll = ereg;
            this.matchAllByDefault = true;
        } else {
            this.eregMatchFirst = ereg;
            this.eregMatchAll = null;
            this.matchAllByDefault = false;
        }
        this.pattern = pattern;
        this.options = options;
        this.str = str;
    }

    inline
    public function matches():Bool {
        return ereg.match(str);
    }
    
    inline
    public function replace(replaceWith:String):String {
        return ereg.replace(str, replaceWith);
    }
    
    public function replaceAll(replaceWith:String):String {
        if (eregMatchAll == null) eregMatchAll = cloneEReg(ereg, pattern, "g" + options);
        return eregMatchAll.replace(str, replaceWith);
    }
    
    public function replaceFirst(replaceWith:String):String {
        if (eregMatchFirst == null) eregMatchFirst = cloneEReg(ereg, pattern, options.removeAll("g"));
        return eregMatchFirst.replace(str, replaceWith);
    }
    
    inline
    public function split():Array<String> {
        return ereg.split(str);
    }

    public function splitAll():Array<String> {
        if (eregMatchAll == null) eregMatchAll = cloneEReg(ereg, pattern, "g" + options);
        return eregMatchAll.split(str);
    }
    
    public function splitOnce():Array<String> {
        if (eregMatchFirst == null) eregMatchFirst = cloneEReg(ereg, pattern, options.removeAll("g"));
        return eregMatchFirst.split(str);
    }
    
    public static function cloneEReg(from:EReg, pattern:String, options:String) {
        // partially copy internal state if possible to reuse the inner pre-compiled pattern instance
        #if (neko || lua || cpp || hl)
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "r", Reflect.field(from, "r"));
            Reflect.setField(clone, "global", options.indexOf("g") > -1);
        #elseif java
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "pattern", pattern);
            Reflect.setField(clone, "matcher", Reflect.field(from, "matcher"));
            Reflect.setField(clone, "isGlobal", options.indexOf("g") > -1);
        #elseif js
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "r", Reflect.field(from, "r"));
        #elseif php    
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "pattern", pattern);
            Reflect.setField(clone, "options", options);
            Reflect.setField(clone, "global", options.indexOf("g") > -1);
            Reflect.setField(clone, "re", Reflect.field(from, "re"));
        #elseif python
            var clone = Type.createEmptyInstance(EReg);
            Reflect.setField(clone, "pattern", Reflect.field(from, "pattern"));
            Reflect.setField(clone, "global", options.indexOf("g") > -1);
        #else
            // not reusing internal state on c#, flash and untested platforms
            var clone = new EReg(pattern, options);
        #end
        return clone;
    }
}
