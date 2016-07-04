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

import haxe.io.Path;
import hx.strings.Pattern;
import hx.strings.internal.Either2;
import hx.strings.internal.Either3;
import hx.strings.internal.OS;

using hx.strings.Strings;

/**
 * Local filesystem path related string manipulation operations.
 * 
 * It provides more robust implementations of similar functions provided by haxe.io.Path.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Paths {
    
    /**
     * Unix-flavor directory separator (slash)
     */
    public static inline var DIRECTORY_SEPARATOR_NIX = "/";
    
    /**
     * Windows directory separator (backslash)
     */
    public static inline var DIRECTORY_SEPARATOR_WIN = "\\";

    /**
     * operating system specific directory separator (slash or backslash)
     */
    public static var DIRECTORY_SEPARATOR(default, null):String = OS.isWindows() ? DIRECTORY_SEPARATOR_WIN : DIRECTORY_SEPARATOR_NIX;
    
    /**
     * Unix-flavor path separator (:) used to separate paths in the PATH environment variable
     */
    public static inline var PATH_SEPARATOR_NIX = ":";
    
    /**
     * Windows path separator (;) used to separate paths in the PATH environment variable
     */
    public static inline var PATH_SEPARATOR_WIN = ";";

    /**
     * operating system specific path separator (colon or semicolon) used to separate paths in the PATH environment variable
     */
    public static var PATH_SEPARATOR(default, null):String = OS.isWindows() ? PATH_SEPARATOR_WIN : PATH_SEPARATOR_NIX;

    /**
     * <pre><code>
     * >>> Paths.addTrailingSlash("/dir")      == "/dir/"
     * >>> Paths.addTrailingSlash("C:\\dir")   == "C:\\dir\\"
     * >>> Paths.addTrailingSlash("dir")       == "dir/"
     * >>> Paths.addTrailingSlash("C:")        == "C:\\"
     * >>> Paths.addTrailingSlash("")          == "/"
     * >>> Paths.addTrailingSlash(null)        == null
     * </code></pre>
	 */
    public static function addTrailingSlash(path:String):String {
        if (path == null)
            return null;
            
		if (path.length == 0)
			return DIRECTORY_SEPARATOR_NIX;
            
		var nixSepPos = path.lastIndexOf(DIRECTORY_SEPARATOR_NIX);
		var winSepPos = path.lastIndexOf(DIRECTORY_SEPARATOR_WIN);

        if (nixSepPos == -1 && winSepPos == -1) {
            if (path.charCodeAt8(0).isAsciiAlpha() &&  path.charCodeAt8(1) == Char.COLON)
                return path + DIRECTORY_SEPARATOR_WIN;
            return path + DIRECTORY_SEPARATOR_NIX;
        }
        
		if(nixSepPos < winSepPos) {
			if (winSepPos != path.length - 1)
                return path + DIRECTORY_SEPARATOR_WIN;
            return path;
		}
        
        if (nixSepPos != path.length - 1)
            return path + DIRECTORY_SEPARATOR_NIX;
        return path;
    }
    
    /**
     * <pre><code>
     * >>> Paths.basename("/dir/file.txt")     == "file.txt"
     * >>> Paths.basename("C:\\dir\\file.txt") == "file.txt"
     * >>> Paths.basename("/dir/")             == "dir"
     * >>> Paths.basename("/dir//")            == "dir"
     * >>> Paths.basename("/dir/..")           == ".."
     * >>> Paths.basename("..")                == ".."
     * >>> Paths.basename(".")                 == "."
     * >>> Paths.basename("")                  == ""
     * >>> Paths.basename(null)                == null
     * </code></pre>
     * 
     * @return the last part of the given path
     */
    public static function basename(path:String):String {
        if (path.isEmpty())
            return path;

        while(true) {
            var nixSepPos = path.lastIndexOf(DIRECTORY_SEPARATOR_NIX);
            var winSepPos = path.lastIndexOf(DIRECTORY_SEPARATOR_WIN);
            var sepPos = nixSepPos > winSepPos ? nixSepPos : winSepPos;
            if (sepPos == path.length8() - 1) {
                path = path.left(path.length8() - 1);
                continue;
            }
            return path.substring8(sepPos + 1);
        }
    }
    
    /**
     * <pre><code>
     * > >> Paths.globToEReg("**"+"/file?.txt").match("aa/bb/file1.txt") == true
     * > >> Paths.globToEReg("*.txt").match("file.txt")       == true
     * > >> Paths.globToEReg("*.txt").match("file.pdf")       == false
     * > >> Paths.globToEReg("*.{pdf,txt}").match("file.txt") == true
     * > >> Paths.globToEReg("*.{pdf,txt}").match("file.pdf") == true
     * > >> Paths.globToEReg("*.{pdf,txt}").match("file.xml") == false
     * </code></pre>
     * 
     * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
     * @return a EReg object
     */
    inline
    public static function globToEReg(globPattern:String, regexOptions:String = ""):EReg {
        return globToRegEx(globPattern).toEReg(regexOptions);
    }
    
    /**
     * <pre><code>
     * > >> Paths.globToPattern("**"+"/file?.txt").matcher("aa/bb/file1.txt").matches() == true
     * > >> Paths.globToPattern("*.txt").matcher("file.txt").matches()       == true
     * > >> Paths.globToPattern("*.txt").matcher("file.pdf").matches()       == false
     * > >> Paths.globToPattern("*.{pdf,txt}").matcher("file.txt").matches() == true
     * > >> Paths.globToPattern("*.{pdf,txt}").matcher("file.pdf").matches() == true
     * > >> Paths.globToPattern("*.{pdf,txt}").matcher("file.xml").matches() == false
     * </code></pre>
     * 
     * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
     * @return a hx.strings.Pattern object
     */
    inline
    public static function globToPattern(globPattern:String, options:Either3<String, MatchingOption, Array<MatchingOption>> = null):Pattern {
        return globToRegEx(globPattern).toPattern(options);
    }
    
    /**
     * <pre><code>
     * > >> Paths.globToRegEx("file")        == "^file$"
     * > >> Paths.globToRegEx("*.txt")       == "^[^\\\\^\\/]*\\.txt$"
     * > >> Paths.globToRegEx("*file*")      == "^[^\\\\^\\/]*file[^\\\\^\\/]*$"
     * > >> Paths.globToRegEx("file?.txt")   == "^file[^\\\\^\\/]\\.txt$"
     * > >> Paths.globToRegEx("")            == ""
     * > >> Paths.globToRegEx(null)          == null
     * </code></pre>
     * 
     * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
     */
    public static function globToRegEx(globPattern:String):String {
        if (globPattern.isEmpty())
            return globPattern;

        var sb = new StringBuilder();
        sb.addChar(Char.CARET);
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
     * <pre><code>
     * >>> Paths.isAbsolute("/")                == true
     * >>> Paths.isAbsolute("C:\\")             == true
     * >>> Paths.isAbsolute("\\\\server.local") == true
     * >>> Paths.isAbsolute("dir/file")         == false
     * >>> Paths.isAbsolute("../dir")           == false
     * >>> Paths.isAbsolute("1:\\")             == false
     * >>> Paths.isAbsolute("")                 == false
     * >>> Paths.isAbsolute(null)               == false
     * </code></pre>
     * 
	 * @return true if the given path is a absolute, otherwise false
	 */
	public static function isAbsolute(path:String):Bool {
        if (path.isEmpty()) 
            return false;

        if (path.startsWith("/") || path.startsWith("\\\\"))
            return true;

        if (path.charCodeAt8(0).isAsciiAlpha() && path.charCodeAt8(1) == Char.COLON)
            return true;

		return false;
	}

	/**
     * <pre><code>
     * >>> Paths.normalize("C:\\dir1\\..\\dir2\\") == "C:/dir2"
     * >>> Paths.normalize("C:\\..\\foo\\")        == "foo"
     * >>> Paths.normalize("a/b/../../../")        == ".."
     * >>> Paths.normalize("")                     == ""
     * >>> Paths.normalize(null)                   == null
     * </code></pre>
	 * 
     * @return normalized version of the given path with trailing slashes are removed and separators turned into slashes
	 */
	public static function normalize(path:String):String {
        if (path.isEmpty()) 
            return path;

        path = path.replaceAll(DIRECTORY_SEPARATOR_WIN, DIRECTORY_SEPARATOR_NIX);
        var parts = path.split(DIRECTORY_SEPARATOR_NIX);
        
        var resultParts = new Array<String>();
        for(i in 0...parts.length) {
            var part = parts[i];
            if (part.length == 0) {
                if (i == 0) {
                    resultParts.push("");
                }
                continue;
            }
            if (part == ".." && resultParts.length > 0) {
                resultParts.pop();
                continue;
            }
            
            resultParts.push(part);
        }
        
        return resultParts.join(DIRECTORY_SEPARATOR_NIX);
    }
    
    /**
     * <pre><code>
     * >>> Paths.join("dir", "test.txt")              == "dir/test.txt"
     * >>> Paths.join("dir1\\..\\dir2", "dir3")       == "dir2/dir3"
     * >>> Paths.join(["dir1\\dir2", "dir3", "dir4"]) == "dir1/dir2/dir3/dir4"
     * >>> Paths.join([null], null)      == ""
     * >>> Paths.join([""], "")          == ""
     * >>> Paths.join("", "")            == ""
     * >>> Paths.join(null)              == null
     * >>> Paths.join(null, null)        == null
     * >>> Paths.join(null, "")          == ""
     * </code><pre>
     * 
     * @param useOsSeparator if set to true, the OS specific directory separator will be used slash on *nix and backslash on Windows
     * @param normalize if set to false no path normalization will be applied
     */
    public static function join(part1:Either2<String, Array<String>>, part2:String = null, useOsSeparator = false, normalize = true):String {
        if (part1.value == null && part2 == null)
            return null;

        var parts = part1.value == null ? [] : switch(part1.value) {
            case a(str): str.isEmpty() ? [] : [ str ];
            case b(arr): arr;
        }
        
        if (part2.isNotEmpty()) parts.push(part2);
        
        parts = parts.filter(function(part) return part.isNotEmpty());
        if (parts.length == 0)
            return "";

        var sep = useOsSeparator ? DIRECTORY_SEPARATOR : DIRECTORY_SEPARATOR_NIX;
        var path = parts.join(sep);
        
        if (normalize) {
            path = Paths.normalize(path);
            if (sep == DIRECTORY_SEPARATOR_WIN)
                path = path.replaceAll(DIRECTORY_SEPARATOR_NIX, DIRECTORY_SEPARATOR_WIN);
        } else {
            if (sep == DIRECTORY_SEPARATOR_WIN)
                path = path.replaceAll(DIRECTORY_SEPARATOR_NIX, DIRECTORY_SEPARATOR_WIN);
            else
                path = path.replaceAll(DIRECTORY_SEPARATOR_WIN, DIRECTORY_SEPARATOR_NIX);
        }
            
        return path;
    }
}
