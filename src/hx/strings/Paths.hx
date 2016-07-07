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

import hx.strings.Pattern;
import hx.strings.internal.Either2;
import hx.strings.internal.Either3;

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
    public static var DIRECTORY_SEPARATOR(default, null):String = hx.strings.internal.OS.isWindows() ? DIRECTORY_SEPARATOR_WIN : DIRECTORY_SEPARATOR_NIX;
    
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
    public static var PATH_SEPARATOR(default, null):String = hx.strings.internal.OS.isWindows() ? PATH_SEPARATOR_WIN : PATH_SEPARATOR_NIX;

    private static function _getSeparator(path:Either2<String, Array<String>>, sep:DirectorySeparatorType) {
        return switch(sep) {
            case AUTO:
                var nixSepPos = Strings.POS_NOT_FOUND;
                var winSepPos = Strings.POS_NOT_FOUND;
                
                if (path == null) return DIRECTORY_SEPARATOR_NIX;
                
                switch(path.value) {
                    case a(str):
                        nixSepPos = str.indexOf8(DIRECTORY_SEPARATOR_NIX);
                        winSepPos = str.indexOf8(DIRECTORY_SEPARATOR_WIN);                        
                    case b(arr):
                        for (str in arr) {
                            if(nixSepPos == Strings.POS_NOT_FOUND)
                                nixSepPos = str.indexOf8(DIRECTORY_SEPARATOR_NIX);
                            if(winSepPos == Strings.POS_NOT_FOUND)
                                winSepPos = str.indexOf8(DIRECTORY_SEPARATOR_WIN);
                        }
                }

                if (winSepPos > Strings.POS_NOT_FOUND)
                    return DIRECTORY_SEPARATOR_WIN;

                if (nixSepPos == Strings.POS_NOT_FOUND && winSepPos == Strings.POS_NOT_FOUND) {
                    
                    // test for "C:"
                    return switch(path.value) {
                        case a(str):
                            if (str.length8() == 2 && str.charCodeAt8(0).isAsciiAlpha() && str.charCodeAt8(1) == Char.COLON)
                                DIRECTORY_SEPARATOR_WIN;
                            else
                                DIRECTORY_SEPARATOR_NIX;
                        case b(arr):
                            if(arr.length > 0) {
                                var str = arr[0];
                                if (str.length8() == 2 && str.charCodeAt8(0).isAsciiAlpha() && str.charCodeAt8(1) == Char.COLON)
                                    DIRECTORY_SEPARATOR_WIN;                            
                                else
                                    DIRECTORY_SEPARATOR_NIX;
                            } else
                                DIRECTORY_SEPARATOR_NIX;
                    }

                }

                return DIRECTORY_SEPARATOR_NIX;

            case OS:
                DIRECTORY_SEPARATOR;
                
            case NIX:
                DIRECTORY_SEPARATOR_NIX;
                
            case WIN:
                DIRECTORY_SEPARATOR_WIN;
        }
    }

    /**
     * <pre><code>
     * >>> Paths.addDirectorySeparator("/dir")      == "/dir/"
     * >>> Paths.addDirectorySeparator("C:\\dir")   == "C:\\dir\\"
     * >>> Paths.addDirectorySeparator("dir")       == "dir/"
     * >>> Paths.addDirectorySeparator("C:")        == "C:\\"
     * >>> Paths.addDirectorySeparator("")          == "/"
     * >>> Paths.addDirectorySeparator(null)        == null
     * </code></pre>
     */
    public static function addDirectorySeparator(path:String, sep:DirectorySeparatorType = AUTO):String {
        if (path == null)
            return null;

        var dirSep = _getSeparator(path, sep);

        if (path.isEmpty())
            return dirSep;

        return path + dirSep;
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
            var nixSepPos = path.lastIndexOf8(DIRECTORY_SEPARATOR_NIX);
            var winSepPos = path.lastIndexOf8(DIRECTORY_SEPARATOR_WIN);
            var sepPos = nixSepPos > winSepPos ? nixSepPos : winSepPos;
            if (sepPos == path.length8() - 1) {
                // handle path ending with multiple separators properly, e.g. "dir//"
                path = path.left(path.length8() - 1);
                continue;
            }
            return path.substring8(sepPos + 1);
        }
    }
    
    /**
     * <pre><code>
     * >>> Paths.basenameWithoutExtension("/dir/file.txt")     == "file"
     * >>> Paths.basenameWithoutExtension("C:\\dir\\file.txt") == "file"
     * >>> Paths.basenameWithoutExtension("/dir/")             == "dir"
     * >>> Paths.basenameWithoutExtension("/dir//")            == "dir"
     * >>> Paths.basenameWithoutExtension("/dir/..")           == ".."
     * >>> Paths.basenameWithoutExtension("..")                == ".."
     * >>> Paths.basenameWithoutExtension(".")                 == "."
     * >>> Paths.basenameWithoutExtension("")                  == ""
     * >>> Paths.basenameWithoutExtension(null)                == null
     * </code></pre>
     * 
     * @return the last part of the given path
     */
    public static function basenameWithoutExtension(path:String):String {
        if (path.isEmpty())
            return path;

        var basename = basename(path);
        if (basename == "." || basename == "..") return basename;
        var dotPos = basename.lastIndexOf8(".");
        return dotPos == Strings.POS_NOT_FOUND ? basename : basename.substring8(0, dotPos);
    }
    
    /**
     * <pre><code>
     * >>> Paths.dirname("C:\\Users\\Default\\Desktop\\") == "C:\\Users\\Default"
     * >>> Paths.dirname("../../..") == "../.."
     * >>> Paths.dirname("../..")    == ".."
     * >>> Paths.dirname("../..///") == ".."
     * >>> Paths.dirname("..")       == "."
     * >>> Paths.dirname(".")        == "."
     * >>> Paths.dirname("")         == "."
     * >>> Paths.dirname(null)       == null
     * </code></pre>
     */
    public static function dirname(path:String):String {
        if (path == null)
            return null;

        if (path == "" || path == "." || path == "..")
            return ".";

        while(true) {
            var nixSepPos = path.lastIndexOf8(DIRECTORY_SEPARATOR_NIX);
            var winSepPos = path.lastIndexOf8(DIRECTORY_SEPARATOR_WIN);
            var sepPos = nixSepPos > winSepPos ? nixSepPos : winSepPos;
            if (sepPos == path.length8() - 1) {
                // handle path ending with multiple separators properly, e.g. "dir//"
                path = path.left(path.length8() - 1);
                continue;
            }
            return path.substring8(0, sepPos);
        }
    }
    
    /**
     * <pre><code>
     * >>> Paths.ellipsize("C:\\Users\\Default\\Desktop\\", 15)             == "C:\\...\\Desktop"
     * >>> Paths.ellipsize("C:\\Users\\Default\\Desktop", 15)               == "C:\\...\\Desktop"
     * >>> Paths.ellipsize("C:\\Users\\Default\\Desktop\\..\\..\\John", 15) == "C:\\Users\\John"
     * >>> Paths.ellipsize("C:\\Users\\Default\\Desktop\\", 3)              == "..."
     * >>> Paths.ellipsize("C:\\Users\\Default\\Desktop\\", 7)              == "C:\\..."
     * >>> Paths.ellipsize("C:\\Users\\Default\\Desktop\\", 7, false)       == "..."
     * >>> Paths.ellipsize("C:\\Users\\Default\\Desktop\\", 12, false)      == "...\\Desktop"
     * >>> Paths.ellipsize("\\\\winserver\\documents\\text.doc", 25)        == "\\\\winserver\\...\\text.doc"
     * >>> Paths.ellipsize("", 0) == ""
     * >>> Paths.ellipsize("", 3) == ""
     * >>> Paths.ellipsize(null, 0) == null
     * >>> Paths.ellipsize(null, 3) == null
     * </code></pre>
     * 
     * @throws exception if maxLength < ellipsis.length
     */
    public static function ellipsize(path:String, maxLength:Int, startFromLeft:Bool = true, ellipsis:String = "..."):String {
        if (path.length8() <= maxLength)
            return path;

        var dirSep = _getSeparator(path, AUTO);

        // check if path fits by normalizing it
        path = normalize(path);
        trace(path);
        if (path.length8() <= maxLength)
            return path;
        
        var ellipsisLen = ellipsis.length8();
        if (maxLength < ellipsisLen) throw '[maxLength] must not be smaller than ${ellipsisLen}';

        var processLeftSide = startFromLeft;
        var leftPart = new StringBuilder();
        var leftPartsCount = 0;
        var rightPart = new StringBuilder();
        var rightPartsCount = 0;
        var pathParts = path.split8(dirSep);
        var dirSepLen = dirSep.length8();

        for (i in 0...pathParts.length) {
            var partToAdd = processLeftSide ? pathParts[leftPartsCount] : pathParts[pathParts.length - rightPartsCount - 1];
            if (leftPart.length + rightPart.length + ellipsisLen + partToAdd.length8() + dirSepLen > maxLength) {
                break;
            }
            
            if (processLeftSide) {
                leftPart.add(partToAdd);
                leftPart.add(dirSep);
                leftPartsCount++;
                
                // handle special case of Windows network share \\server\folder
                if ((i == 0 || i == 1) && partToAdd.isEmpty()) 
                    continue;
            } else {
                rightPart.prepend(partToAdd);
                rightPart.prepend(dirSep);
                rightPartsCount++;
            }
            processLeftSide = !processLeftSide;
        }

        return leftPart + ellipsis + rightPart;
    }
    
    /**
     * <pre><code>
     * >>> Paths.extension("file.txt")         == "txt"
     * >>> Paths.extension("file")             == ""
     * >>> Paths.extension("file.tar.gz")      == "gz"
     * >>> Paths.extension("dir.cfg/file.txt") == "txt"
     * >>> Paths.extension(null)               == null
     * </code></pre>
     * 
     * @return dot extension of the given dir/file
     */
    public static function extension(path:String) {
        if (path == null) 
            return null;
            
        var fileName = basename(path);
        var dotPos = fileName.lastIndexOf8(".");
        if (dotPos == Strings.POS_NOT_FOUND)
            return "";
        return fileName.substr8(dotPos + 1);
    }
    
    /**
     * <pre><code>
     * >>> Paths.globToEReg("**"+"/file?.txt").match("aa/bb/file1.txt") == true
     * >>> Paths.globToEReg("*.txt").match("file.txt")       == true
     * >>> Paths.globToEReg("*.txt").match("file.pdf")       == false
     * >>> Paths.globToEReg("*.{pdf,txt}").match("file.txt") == true
     * >>> Paths.globToEReg("*.{pdf,txt}").match("file.pdf") == true
     * >>> Paths.globToEReg("*.{pdf,txt}").match("file.xml") == false
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
     * >>> Paths.globToPattern("**"+"/file?.txt").matcher("aa/bb/file1.txt").matches() == true
     * >>> Paths.globToPattern("*.txt").matcher("file.txt").matches()       == true
     * >>> Paths.globToPattern("*.txt").matcher("file.pdf").matches()       == false
     * >>> Paths.globToPattern("*.{pdf,txt}").matcher("file.txt").matches() == true
     * >>> Paths.globToPattern("*.{pdf,txt}").matcher("file.pdf").matches() == true
     * >>> Paths.globToPattern("*.{pdf,txt}").matcher("file.xml").matches() == false
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
     * >>> Paths.globToRegEx("file")        == "^file$"
     * >>> Paths.globToRegEx("*.txt")       == "^[^\\\\^\\/]*\\.txt$"
     * >>> Paths.globToRegEx("*file*")      == "^[^\\\\^\\/]*file[^\\\\^\\/]*$"
     * >>> Paths.globToRegEx("file?.txt")   == "^file[^\\\\^\\/]\\.txt$"
     * >>> Paths.globToRegEx("")            == ""
     * >>> Paths.globToRegEx(null)          == null
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
     * >>> Paths.isAbsolute("/")                  == true
     * >>> Paths.isAbsolute("C:")                 == true
     * >>> Paths.isAbsolute("\\\\winserver\\dir") == true
     * >>> Paths.isAbsolute("dir/file")           == false
     * >>> Paths.isAbsolute("../dir")             == false
     * >>> Paths.isAbsolute("1:\\")               == false
     * >>> Paths.isAbsolute("")                   == false
     * >>> Paths.isAbsolute(null)                 == false
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
     * >>> Paths.join("dir", "test.txt")              == "dir/test.txt"
     * >>> Paths.join("dir1\\..\\dir2", "dir3")       == "dir2\\dir3"
     * >>> Paths.join("dir1\\..\\dir2", "dir3", NIX)  == "dir2/dir3"
     * >>> Paths.join(["dir1\\dir2", "dir3", "dir4"]) == "dir1\\dir2\\dir3\\dir4"
     * >>> Paths.join(["dir1/dir2", "dir3", "dir4"])  == "dir1/dir2/dir3/dir4"
     * >>> Paths.join([null], null)      == ""
     * >>> Paths.join([""], "")          == ""
     * >>> Paths.join("", "")            == ""
     * >>> Paths.join(null)              == null
     * >>> Paths.join(null, null)        == null
     * >>> Paths.join(null, "")          == ""
     * </code><pre>
     * 
     * @param normalize if set to false no path normalization will be applied
     */
    public static function join(part1:Either2<String, Array<String>>, part2:String = null, sep:DirectorySeparatorType = AUTO, normalize = true):String {
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

        var path = parts.join(_getSeparator(parts, sep));
        
        if (normalize) {
            path = Paths.normalize(path, sep);
        }

        return path;
    }
    
    /**
     * <pre><code>
     * >>> Paths.normalize("C:\\dir1\\..\\dir2\\")              == "C:\\dir2"
     * >>> Paths.normalize("C:\\..\\foo\\")                     == "foo"
     * >>> Paths.normalize("a\\..\\b/c", NIX)                   == "b/c"
     * >>> Paths.normalize("/a/b/../c/")                        == "/a/c"
     * >>> Paths.normalize("//a/b/../c/")                       == "/a/c"
     * >>> Paths.normalize("a/b/../../../")                     == ".."
     * >>> Paths.normalize("\\\\server.local\\a\\b\\..\\c\\")   == "\\\\server.local\\a\\c"
     * >>> Paths.normalize("\\\\\\server.local\\a\\b\\..\\c\\") == "\\\\server.local\\a\\c"
     * >>> Paths.normalize("")                                  == ""
     * >>> Paths.normalize(null)                                == null
     * </code></pre>
     * 
     * @return normalized version of the given path with trailing slashes are removed
     */
    public static function normalize(path:String, sep:DirectorySeparatorType = AUTO):String {
        if (path.isEmpty()) 
            return path;

        var dirSep = _getSeparator(path, sep);
        var parts = path.split8([DIRECTORY_SEPARATOR_NIX, DIRECTORY_SEPARATOR_WIN]);
        var resultParts = new Array<String>();
        for(i in 0...parts.length) {
            var part = parts[i];
            if (part.isEmpty()) {
                if (i == 0) {
                    resultParts.push(dirSep == DIRECTORY_SEPARATOR_WIN ? DIRECTORY_SEPARATOR_WIN : "");
                }
                continue;
            }
            if (part == ".." && resultParts.length > 0) {
                resultParts.pop();
                continue;
            }
            
            resultParts.push(part);
        }

        return resultParts.join(dirSep);
    }
    
}

/**
 * Using abstract enum because of http://stackoverflow.com/questions/31307992/haxe-enum-default-parameters
 */
@:dox(hide)
@:enum
abstract DirectorySeparatorType(Int) {

    /**
     * tries to determine the separator based on the input, uses slash as fallback
     */
    var AUTO = 0;
    
    /**
     * use current operating system separator
     */
    var OS = 1;
    
    /**
     * use Linux/Unix separator (slash)
     */
    var NIX = 2;
    
    /**
     * use Windows separator (back slash)
     */
    var WIN = 3;
    
}
