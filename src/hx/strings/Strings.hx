/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings;

import haxe.Int32;
#if neko
import neko.Utf8;
#else
import haxe.Utf8;
#end
import haxe.crypto.Adler32;
import haxe.crypto.Base64;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import hx.strings.Pattern.Matcher;
import hx.strings.Pattern.MatchingOption;
import hx.strings.internal.Either2;
import hx.strings.internal.Either3;
import hx.strings.internal.OS;
import hx.strings.internal.OneOrMany;

using hx.strings.Strings;

/**
 * Utility functions for Strings with UTF-8 support and consistent behavior across platforms.
 *
 * This class can be used as <a href="http://haxe.org/manual/lf-static-extension.html">static extension</a>.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Strings {

   static final REGEX_ANSI_ESC = Pattern.compile(Char.ESC + "\\[[;\\d]*m", MATCH_ALL);
   static final REGEX_HTML_UNESCAPE = Pattern.compile("&(#\\d+|amp|nbsp|apos|lt|gt|quot);", MATCH_ALL);
   static final REGEX_SPLIT_LINES = Pattern.compile("\\r?\\n", MATCH_ALL);

   #if !php
   static final REGEX_REMOVE_XML_TAGS = Pattern.compile("<[!a-zA-Z\\/][^>]*>", MATCH_ALL);
   #end

   public static inline final POS_NOT_FOUND:CharIndex = -1;

   /**
    * Unix line separator (LF)
    */
   public static inline final NEW_LINE_NIX = "\n";

   /**
    * Windows line separator (CR + LF)
    */
   public static inline final NEW_LINE_WIN = "\r\n";

   /**
    * operating system specific line separator
    */
   public static final NEW_LINE = OS.isWindows ? NEW_LINE_WIN : NEW_LINE_NIX;


   inline
   private static function _getNotFoundDefault(str:String, notFoundDefault:StringNotFoundDefault):String {
      return switch(notFoundDefault) {
         case NULL: null;
         case EMPTY: "";
         case INPUT: str;
      }
   }


   /**
    * no bounds checking
    */
   // to prevent "lua53: target/lua/TestRunner.lua:24443: ')' expected near ':'"
   @:allow(hx.strings.CharIterator)
   #if !lua inline #end
   private static function _charCodeAt8Unsafe(str:String, pos:CharIndex):Char {
      #if target.unicode
         return str.charCodeAt(pos);
      #else
         return Utf8.charCodeAt(str, pos);
      #end
   }


   /**
    * no bounds checking
    */
   private static function _splitAsciiWordsUnsafe(str:String) {
      final words = new Array<String>();
      final currentWord = new StringBuilder();

      final chars = str.toChars();

      final len = chars.length;
      final lastIndex = len - 1;
      for (i in 0...len) {
         final ch = chars[i];
         if (ch.isAsciiAlpha()) {
            final chNext = i < lastIndex ? chars[i + 1] : -1;
            currentWord.addChar(ch);
            if (chNext.isDigit()) {
               words.push(currentWord.toString());
               currentWord.clear();
            } else if (ch.isUpperCase()) {
               if (chNext.isUpperCase() && chars.length > i + 2) {
                  if (!chars[i + 2].isUpperCase()) {
                     words.push(currentWord.toString());
                     currentWord.clear();
                  }
               }
            } else { /*if (!ch.isUpperCase()) */
               if (chNext.isUpperCase()) {
                  words.push(currentWord.toString());
                  currentWord.clear();
               }
            }
         } else if (ch.isDigit()) {
            currentWord.addChar(ch);
            final chNext = i < lastIndex ? chars[i + 1] : -1;
            if (!chNext.isDigit()) {
               words.push(currentWord.toString());
               currentWord.clear();
            }
         } else if (currentWord.length > 0) {
            words.push(currentWord.toString());
            currentWord.clear();
         }
      }

      if (currentWord.length > 0)
         words.push(currentWord.toString());
      return words;
   }


   /**
    * Transforms an ANSI escape sequence to HTML markup.
    *
    * There are currently three different render methods available:
    *
    *  1. <b>StyleAttributes (the default):</b> transforms to linear style attribute such as <pre><span style=\"color:yellow\;">content</span></pre>.
    *
    *  2. <b>CssClasses:</b> Uses <b>AnsiState#defaultCssClassesCallback()</b> which converts to CSS classes named such as
    *     <span class="ansi_fg_red ansi_bold"></span>, where "red" is the ANSI color.
    *     The CSS classes used by default are .ansi_fg_<color>, .ansi_bg_<color>, .ansi_bold, .ansi_blink, .ansi_underline.
    *
    *  3. <b>CssClassesCallback(cb):</b> allows full customization via a custom callback AnsiState->String.
    *     The returned string is the CSS class name applied for the given AnsiState.
    *
    * <pre><code>
    * >>> Strings.ansiToHtml(null)                                  == null
    * >>> Strings.ansiToHtml("")                                    == ""
    * >>> Strings.ansiToHtml("dogcat")                              == "dogcat"
    * >>> Strings.ansiToHtml("\x1B[0m\x1B[0m")                      == ""
    * >>> Strings.ansiToHtml("\x1B[33;40mDOG\x1B[40;42mCAT")        == "<span style=\"color:yellow;background-color:black;\">DOG</span><span style=\"color:yellow;background-color:green;\">CAT</span>"
    * >>> Strings.ansiToHtml("\x1B[33;40mDOG\x1B[40;42mCAT\x1B[0m") == "<span style=\"color:yellow;background-color:black;\">DOG</span><span style=\"color:yellow;background-color:green;\">CAT</span>"
    * >>> Strings.ansiToHtml("\x1B[33;40mDOG\x1B[40;42mCAT\x1B[0m", CssClasses) == "<span class=\"ansi_fg_yellow ansi_bg_black\">DOG</span><span class=\"ansi_fg_yellow ansi_bg_green\">CAT</span>"
    * </code></pre>
    */
   public static function ansiToHtml(
      str          :String,
      ?renderMethod:AnsiToHtmlRenderMethod,
      ?initialState:AnsiState
   ):String {

      if (isEmpty(str))
         return str;

      if (renderMethod == null) renderMethod = StyleAttributes;
      final styleOrClassAttribute = switch(renderMethod) {
         case StyleAttributes        : "style";
         case CssClasses             : "class";
         case CssClassesCallback(cb) : "class";
      }

      final sb = new StringBuilder();

      if (initialState != null && initialState.isActive())
         sb.add('<span $styleOrClassAttribute=\"').add(initialState.toCSS(renderMethod)).add("\">");

      var effectiveState = new AnsiState(initialState);
      final strLenMinus1 = str.length8() - 1;
      var i = -1;
      final lookAhead = new StringBuilder();
      while (i < strLenMinus1) {
         i++;
         final ch:Char = str._charCodeAt8Unsafe(i);
         if (ch == Char.ESC && i < strLenMinus1 && str._charCodeAt8Unsafe(i + 1) == 91 /*[*/) { // is beginning of ANSI Escape Sequence?
            lookAhead.clear();
            final currentState = new AnsiState(effectiveState);
            var currentGraphicModeParam = 0;
            var isValidEscapeSequence = false;
            i += 1;
            while (i < strLenMinus1) {
               i++;
               final ch2:Char = str._charCodeAt8Unsafe(i);
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
                     if (currentState.isActive())
                        sb.add('<span $styleOrClassAttribute=\"').add(currentState.toCSS(renderMethod)).add("\">");
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
         } else
            sb.addChar(ch);
      }

      if (effectiveState.isActive())
          sb.add("</span>");

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
         return php.Syntax.code("base64_encode({0})", plain);
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
         return php.Syntax.code("base64_decode({0})", encoded);
      #else
         return Base64.decode(encoded).toString();
      #end
   }


   /**
    * String#charAt() variant with cross-platform UTF-8 support.
    *
    * <pre><code>
    * >>> Strings.charAt8(" dog", 0)     == " "
    * >>> Strings.charAt8(" dog", 1 )    == "d"
    * >>> Strings.charAt8(" ", -1)       == ""
    * >>> Strings.charAt8(" ", -1, "x")  == "x"
    * >>> Strings.charAt8(" ", 0)        == " "
    * >>> Strings.charAt8(" ", 1)        == ""
    * >>> Strings.charAt8(" ", 10)       == ""
    * >>> Strings.charAt8("", 0)         == ""
    * >>> Strings.charAt8("", 0, "x")    == "x"
    * >>> Strings.charAt8(null, 0)       == ""
    * >>> Strings.charAt8(" はい", 1)     == "は"
    * >>> Strings.charAt8(" はい", 2)     == "い"
    * </code></pre>
    *
    * @param pos character position
    */
   public static function charAt8(str:String, pos:CharIndex, resultIfOutOfBound = ""):String {
      if (str.isEmpty() || pos < 0 || pos >= str.length8())
         return resultIfOutOfBound;
      #if target.unicode
         return str.charAt(pos);
      #else
         return Utf8.sub(str, pos, 1);
      #end
   }


   /**
    * String#charCodeAt() variant with cross-platform UTF-8 support.
    *
    * <pre><code>
    * >>> Strings.charCodeAt8(" dog", 0)           == 32
    * >>> Strings.charCodeAt8(" dog", 0).isSpace() == true
    * >>> Strings.charCodeAt8(" dog", 1)           == 100
    * >>> Strings.charCodeAt8(" dog", 1).isSpace() == false
    * >>> Strings.charCodeAt8(" ", -1)           == -1
    * >>> Strings.charCodeAt8(" ", -1, -4)       == -4
    * >>> Strings.charCodeAt8(" ", 0)            == 32
    * >>> Strings.charCodeAt8(" ", 0).isSpace()  == true
    * >>> Strings.charCodeAt8(" ", 1)            == -1
    * >>> Strings.charCodeAt8(" ", 1).isSpace()  == false
    * >>> Strings.charCodeAt8(" ", 10)           == -1
    * >>> Strings.charCodeAt8("", 0)             == -1
    * >>> Strings.charCodeAt8("", 0, -4)         == -4
    * >>> Strings.charCodeAt8(null, 0)           == -1
    * >>> Strings.charCodeAt8(null, 0).isSpace() == false
    * >>> Strings.charCodeAt8(" はい", 1)         == 12399
    * >>> Strings.charCodeAt8(" はい", 2)         == 12356
    * </code></pre>
    *
    * @param pos character position
    */
   inline
   public static function charCodeAt8(str:String, pos:CharIndex, resultIfOutOfBound:Char = -1):Char {
      final strLen = str.length8();
      if (strLen == 0 || pos < 0 || pos >= strLen)
         return resultIfOutOfBound;

      return str._charCodeAt8Unsafe(pos);
   }


   /**
    * Removes trailing and leading whitespace characters.
    * Replaces all whitespace characters with the space character.
    * Only leaves one space character between words.
    *
    * <pre><code>
    * >>> Strings.compact(null) == null
    * >>> Strings.compact("")   == ""
    * >>> Strings.compact(" dog \n \t cat ") == "dog cat"
    * </code></pre>
    */
   public static function compact(str:String):String {
      if (str.isEmpty())
          return str;

      final sb = new StringBuilder();
      var needWhiteSpace = false;
      for (char in str.toChars()) {
         if (char.isWhitespace()) {
            if (!sb.isEmpty())
               needWhiteSpace = true;
            continue;
         } else if (needWhiteSpace) {
            sb.addChar(Char.SPACE);
            needWhiteSpace = false;
         }
         sb.addChar(char);
      }
      return sb.toString();
   }


   /**
    * Tests if <b>searchIn</b> contains <b>searchFor</b> as a substring
    *
    * <pre><code>
    * >>> Strings.contains("dog", "")  == true
    * >>> Strings.contains("dog", "g") == true
    * >>> Strings.contains("dog", "t") == false
    * >>> Strings.contains("", null)   == false
    * >>> Strings.contains("", "")     == true
    * >>> Strings.contains(null, null) == false
    * >>> Strings.contains(null, "")   == false
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
    * Tests if <b>searchIn</b> contains only the allowed characters
    *
    * <pre><code>
    * >>> Strings.containsOnly(null, null)  == true
    * >>> Strings.containsOnly("", null)    == true
    * >>> Strings.containsOnly("a", null)   == false
    * >>> Strings.containsOnly("AA", [65])  == true
    * >>> Strings.containsOnly("Aa", [65])  == false
    * >>> Strings.containsOnly("AA", "A")   == true
    * >>> Strings.containsOnly("Aa", "A")   == false
    * >>> Strings.containsOnly("Aa", "Aa")  == true
    * </code></pre>
    */
   public static function containsOnly(searchIn:String, allowedChars:Either2<String, Array<Char>>):Bool {
      if (searchIn.isEmpty())
         return true;

      if (allowedChars == null)
         return false;

      final allowedCharsArray:Array<Char> = switch (allowedChars.value) {
         case a(str): str.toChars();
         case b(chars): chars;
      }

      for (ch in searchIn.toChars()) {
         if (allowedCharsArray.indexOf(ch) < 0)
            return false;
      }
      return true;
   }


   /**
    * Tests if <b>searchIn</b> contains all of <b>searchFor</b> as a substring
    *
    * <pre><code>
    * >>> Strings.containsAll("dog", ["c", ""])  == false
    * >>> Strings.containsAll("dog", ["c", "g"]) == false
    * >>> Strings.containsAll("dog", ["c", "a"]) == false
    * >>> Strings.containsAll("dog", ["d", "g"]) == true
    * >>> Strings.containsAll("dog", [""])       == true
    * >>> Strings.containsAll("", null)          == false
    * >>> Strings.containsAll("", [""])          == true
    * >>> Strings.containsAll(null, null)        == false
    * >>> Strings.containsAll(null, [""])        == false
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
    * >>> Strings.containsAllIgnoreCase("dog", ["c", ""])  == false
    * >>> Strings.containsAllIgnoreCase("dog", ["c", "G"]) == false
    * >>> Strings.containsAllIgnoreCase("dog", ["c", "a"]) == false
    * >>> Strings.containsAllIgnoreCase("dog", ["d", "G"]) == true
    * >>> Strings.containsAllIgnoreCase("dog", [""])       == true
    * >>> Strings.containsAllIgnoreCase("", null)          == false
    * >>> Strings.containsAllIgnoreCase("", [""])          == true
    * >>> Strings.containsAllIgnoreCase(null, null)        == false
    * >>> Strings.containsAllIgnoreCase(null, [""])        == false
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
    * >>> Strings.containsAny("dog", ["c", ""])  == true
    * >>> Strings.containsAny("dog", ["c", "g"]) == true
    * >>> Strings.containsAny("dog", ["", "g"])  == true
    * >>> Strings.containsAny("dog", ["c", "a"]) == false
    * >>> Strings.containsAny("dog", ["d", "g"]) == true
    * >>> Strings.containsAny("dog", [""])       == true
    * >>> Strings.containsAny("", null)          == false
    * >>> Strings.containsAny("", [""])          == true
    * >>> Strings.containsAny(null, null)        == false
    * >>> Strings.containsAny(null, [""])        == false
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
    * >>> Strings.containsAnyIgnoreCase("dog", ["c", ""])  == true
    * >>> Strings.containsAnyIgnoreCase("dog", ["c", "G"]) == true
    * >>> Strings.containsAnyIgnoreCase("dog", ["c", "a"]) == false
    * >>> Strings.containsAnyIgnoreCase("dog", ["d", "G"]) == true
    * >>> Strings.containsAnyIgnoreCase("dog", [""])       == true
    * >>> Strings.containsAnyIgnoreCase("", null)          == false
    * >>> Strings.containsAnyIgnoreCase("", [""])          == true
    * >>> Strings.containsAnyIgnoreCase(null, null)        == false
    * >>> Strings.containsAnyIgnoreCase(null, [""])        == false
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
    * Checks that <b>searchIn</b> contains none of <b>searchFor</b> as a substring
    *
    * <pre><code>
    * >>> Strings.containsNone("dog", ["c", ""])  == false
    * >>> Strings.containsNone("dog", ["c", "g"]) == false
    * >>> Strings.containsNone("dog", ["c", "a"]) == true
    * >>> Strings.containsNone("dog", ["d", "g"]) == false
    * >>> Strings.containsNone("dog", [""])       == false
    * >>> Strings.containsNone("", null)          == true
    * >>> Strings.containsNone("", [""])          == false
    * >>> Strings.containsNone(null, null)        == true
    * >>> Strings.containsNone(null, [""])        == true
    * >>> Strings.containsNone("はい", ["い"])     == false
    * >>> Strings.containsNone("はは", ["い"])     == true
    * </code></pre>
    */
   inline
   public static function containsNone(searchIn:String, searchFor:Array<String>):Bool
      return !containsAny(searchIn, searchFor);


   /**
    * Checks that <b>searchIn</b> contains none of <b>searchFor</b> as a substring
    *
    * <pre><code>
    * >>> Strings.containsNoneIgnoreCase("dog", ["c", ""])  == false
    * >>> Strings.containsNoneIgnoreCase("dog", ["c", "G"]) == false
    * >>> Strings.containsNoneIgnoreCase("dog", ["c", "a"]) == true
    * >>> Strings.containsNoneIgnoreCase("dog", ["d", "G"]) == false
    * >>> Strings.containsNoneIgnoreCase("dog", [""])       == false
    * >>> Strings.containsNoneIgnoreCase("", null)          == true
    * >>> Strings.containsNoneIgnoreCase("", [""])          == false
    * >>> Strings.containsNoneIgnoreCase(null, null)        == true
    * >>> Strings.containsNoneIgnoreCase(null, [""])        == true
    * >>> Strings.containsNoneIgnoreCase("はい", ["い"])     == false
    * >>> Strings.containsNoneIgnoreCase("はは", ["い"])     == true
    * </code></pre>
    */
   inline
   public static function containsNoneIgnoreCase(searchIn:String, searchFor:Array<String>):Bool
      return !containsAnyIgnoreCase(searchIn, searchFor);


   /**
    * Tests if <b>searchIn</b> contains any whitespaces
    *
    * <pre><code>
    * >>> Strings.containsWhitespaces(" ")        == true
    * >>> Strings.containsWhitespaces("dog cat")  == true
    * >>> Strings.containsWhitespaces("dog\tcat") == true
    * >>> Strings.containsWhitespaces("")         == false
    * >>> Strings.containsWhitespaces(null)       == false
    * >>> Strings.containsWhitespaces("はい")      == false
    * >>> Strings.containsWhitespaces("は い")     == true
    * </code></pre>
    */
   public static function containsWhitespaces(searchIn:String):Bool {
      if (searchIn == null)
         return false;

      for (ch in searchIn.toChars()) {
         if (ch.isWhitespace())
            return true;
      }

      return false;
   }


   /**
    * <pre><code>
    * >>> Strings.countMatches("dogdog", "g")      == 2
    * >>> Strings.countMatches("dogdog", "og", 1)  == 2
    * >>> Strings.countMatches("dogdog", "og", 3)  == 1
    * >>> Strings.countMatches("dogdog", "og", 9)  == 0
    * >>> Strings.countMatches("dogdog", "og", -1) == 2
    * >>> Strings.countMatches("", null)           == 0
    * >>> Strings.countMatches("", "a")            == 0
    * >>> Strings.countMatches(null, null)         == 0
    * >>> Strings.countMatches(null, "")           == 0
    * </code></pre>
    *
    * @return the number of occurrences of <b>searchFor</b> within <b>searchIn</b> starting
    *         from the given character position.
    */
   public static function countMatches(searchIn:String, searchFor:String, startAt:CharIndex = 0):Int {
      if (searchIn.isEmpty() || searchFor.isEmpty() || startAt >= searchIn.length)
         return 0;

      if (startAt < 0)
         startAt = 0;

      var count = 0;
      var foundAt = startAt > -1 ? startAt - 1 : 0;
      while ((foundAt = searchIn.indexOf(searchFor, foundAt + 1)) > -1)
         count++;
      return count;
   }


   /**
    * <pre><code>
    * >>> Strings.countMatchesIgnoreCase("dogdog", "G")      == 2
    * >>> Strings.countMatchesIgnoreCase("dogdog", "OG", 1)  == 2
    * >>> Strings.countMatchesIgnoreCase("dogdog", "OG", 3)  == 1
    * >>> Strings.countMatchesIgnoreCase("dogdog", "OG", 9)  == 0
    * >>> Strings.countMatchesIgnoreCase("dogdog", "OG", -1) == 2
    * >>> Strings.countMatchesIgnoreCase(null, null)         == 0
    * >>> Strings.countMatchesIgnoreCase(null, "")           == 0
    * >>> Strings.countMatchesIgnoreCase("", null)           == 0
    * >>> Strings.countMatchesIgnoreCase("", "a")            == 0
    * </code></pre>
    *
    * @return the number of occurrences of <b>searchFor</b> within <b>searchIn</b> starting
    *         from the given character position ignoring case.
    */
   public static function countMatchesIgnoreCase(searchIn:String, searchFor:String, startAt:CharIndex = 0):Int {
      if (searchIn.isEmpty() || searchFor.isEmpty() || startAt >= searchIn.length)
         return 0;

      if (startAt < 0)
         startAt = 0;

      searchIn = searchIn.toLowerCase();
      searchFor = searchFor.toLowerCase();

      var count = 0;
      var foundAt = startAt > -1 ? startAt - 1 : 0;
      while ((foundAt = searchIn.indexOf(searchFor, foundAt + 1)) > -1)
         count++;
      return count;
   }


   /**
    * <pre><code>
    * >>> Strings.compare("a", "b")      < 0
    * >>> Strings.compare("b", "a")      > 0
    * >>> Strings.compare("a", "A")      > 0
    * >>> Strings.compare("A", "a")      < 0
    * >>> Strings.compare("a", "B")      > 0
    * >>> Strings.compare("", null)      > 0
    * >>> Strings.compare("", "")       == 0
    * >>> Strings.compare(null, null)   == 0
    * >>> Strings.compare(null, "")      < 0
    * >>> Strings.compare("к--", "К--")  > 0
    * >>> Strings.compare("к--", "т--")  < 0
    * >>> Strings.compare("кот", "КОТ")  > 0
    * </core></pre>
    *
    * @return a positive value if `str > other`, negative value if `str < other`, 0 if `str == other`
    */
   public static function compare(str:String, other:String):Int {
      if (str == null)
         return other == null ? 0 : -1;

      if (other == null)
         return str == null ? 0 : 1;

      #if target.unicode
         return str > other ? 1 : (str == other ? 0 : -1);
      #else
         return Utf8.compare(str, other);
      #end
   }


   /**
    * <pre><code>
    * >>> Strings.compareIgnoreCase("a", "b")      < 0
    * >>> Strings.compareIgnoreCase("b", "a")      > 0
    * >>> Strings.compareIgnoreCase("a", "A")     == 0
    * >>> Strings.compareIgnoreCase("A", "a")     == 0
    * >>> Strings.compareIgnoreCase("a", "B")      < 0
    * >>> Strings.compareIgnoreCase("", null)      > 0
    * >>> Strings.compareIgnoreCase("", "")       == 0
    * >>> Strings.compareIgnoreCase(null, null)   == 0
    * >>> Strings.compareIgnoreCase(null, "")      < 0
    * >>> Strings.compareIgnoreCase("к--", "К--") == 0
    * >>> Strings.compareIgnoreCase("к--", "т--")  < 0
    * >>> Strings.compareIgnoreCase("кот", "КОТ") == 0
    * </core></pre>
    *
    * @return a positive value if `str > other`, negative value if `str < other`, 0 if `str == other`
    */
   public static function compareIgnoreCase(str:String, other:String):Int {
      if (str == null)
         return other == null ? 0 : -1;

      if (other == null)
         return str == null ? 0 : 1;

      str = str.toLowerCase8();
      other = other.toLowerCase8();

      #if target.unicode
         return str > other ? 1 : (str == other ? 0 : -1);
      #else
         return Utf8.compare(str, other);
      #end
   }


   /**
    * <pre><code>
    * >>> Strings.diff("abc", "abC").left  == "c"
    * >>> Strings.diff("abc", "abC").right == "C"
    * >>> Strings.diff("ab", "abC").left   == ""
    * >>> Strings.diff("ab", "abC").right  == "C"
    * >>> Strings.diff(null, null).at      == -1
    * >>> Strings.diff(null, "").at        == 0
    * >>> Strings.diff(null, "").left      == null
    * >>> Strings.diff(null, "").right     == ""
    * </code></pre>
    */
   public static function diff(left:String, right:String):StringDiff {
      final diff = new StringDiff();
      diff.at = diffAt(left, right);
      diff.left = left.substr8(diff.at);
      diff.right = right.substr8(diff.at);
      return diff;
   }


   /**
    * <pre><code>
    * >>> Strings.diffAt("cat", "catdog")          == 3
    * >>> Strings.diffAt("cat", "cat")             == -1
    * >>> Strings.diffAt("cat", "")                == 0
    * >>> Strings.diffAt("cat", "dog")             == 0
    * >>> Strings.diffAt("It's green", "It's red") == 5
    * >>> Strings.diffAt("catdog", "cat")          == 3
    * >>> Strings.diffAt(null, null)               == -1
    * >>> Strings.diffAt(null, "")                 == 0
    * >>> Strings.diffAt("", null)                 == 0
    * >>> Strings.diffAt("", "")                   == -1
    * >>> Strings.diffAt("", "cat")                == 0
    * </code></pre>
    *
    * @return the UTF8 character position where the strings begin to differ or -1 if they are equal
    */
   public static function diffAt(str:String, other:String):CharIndex {
      if (str.equals(other))
         return POS_NOT_FOUND;

      final strLen = str.length8();
      final otherLen = other.length8();

      if (strLen == 0 || otherLen == 0)
         return 0;

      final checkLen = strLen > otherLen ? otherLen : strLen;

      for (i in 0...checkLen)
         if (str._charCodeAt8Unsafe(i) != other._charCodeAt8Unsafe(i))
            return i;
      return checkLen;
   }


   /**
    * <pre><code>
    * >>> Strings.ellipsizeLeft("12345678", 5)   == "...78"
    * >>> Strings.ellipsizeLeft("12345", 4)      == "...5"
    * >>> Strings.ellipsizeLeft("1234", 4)       == "1234"
    * >>> Strings.ellipsizeLeft("", 0)           == ""
    * >>> Strings.ellipsizeLeft("", 3)           == ""
    * >>> Strings.ellipsizeLeft(null, 0)         == null
    * >>> Strings.ellipsizeLeft(null, 3)         == null
    * >>> Strings.ellipsizeLeft("はいはいはい", 5)  == "...はい"
    * </code></pre>
    *
    * @throws exception if maxLength < ellipsis.length
    */
   public static function ellipsizeLeft(str:String, maxLength:Int, ellipsis:String = "..."):String {
      if (str.length8() <= maxLength)
         return str;

      final ellipsisLen = ellipsis.length8();
      if (maxLength < ellipsisLen) throw '[maxLength] must not be smaller than ${ellipsisLen}';

      return ellipsis + str.right(maxLength - ellipsisLen);
   }


   /**
    * <pre><code>
    * >>> Strings.ellipsizeMiddle("12345678", 5)   == "1...8"
    * >>> Strings.ellipsizeMiddle("12345", 4)      == "1..."
    * >>> Strings.ellipsizeMiddle("1234", 4)       == "1234"
    * >>> Strings.ellipsizeMiddle("", 0)           == ""
    * >>> Strings.ellipsizeMiddle("", 3)           == ""
    * >>> Strings.ellipsizeMiddle(null, 0)         == null
    * >>> Strings.ellipsizeMiddle(null, 3)         == null
    * >>> Strings.ellipsizeMiddle("はいはいはい", 5)  == "は...い"
    * </code></pre>
    *
    * @throws exception if maxLength < ellipsis.length
    */
   public static function ellipsizeMiddle(str:String, maxLength:Int, ellipsis:String = "..."):String {
      final strLen = str.length8();
      if (strLen <= maxLength)
         return str;

      final ellipsisLen = ellipsis.length8();
      if (maxLength < ellipsisLen) throw '[maxLength] must not be smaller than ${ellipsisLen}';

      final maxStrLen = maxLength - ellipsisLen;
      final leftLen = Math.round(maxStrLen / 2);
      final rightLen = maxStrLen - leftLen;

      return str.left(leftLen) + ellipsis + str.right(rightLen);
   }


   /**
    * <pre><code>
    * >>> Strings.ellipsizeRight("12345678", 5)   == "12..."
    * >>> Strings.ellipsizeRight("12345", 4)      == "1..."
    * >>> Strings.ellipsizeRight("1234", 4)       == "1234"
    * >>> Strings.ellipsizeRight("", 0)           == ""
    * >>> Strings.ellipsizeRight("", 3)           == ""
    * >>> Strings.ellipsizeRight(null, 0)         == null
    * >>> Strings.ellipsizeRight(null, 3)         == null
    * >>> Strings.ellipsizeRight("はいはいはい", 5)  == "はい..."
    * </code></pre>
    *
    * @throws exception if maxLength < ellipsis.length
    */
   public static function ellipsizeRight(str:String, maxLength:Int, ellipsis:String = "..."):String {
      if (str.length8() <= maxLength)
         return str;

      final ellipsisLen = ellipsis.length8();
      if (maxLength < ellipsisLen) throw '[maxLength] must not be smaller than ${ellipsisLen}';

      return str.left(maxLength - ellipsisLen) + ellipsis;
   }


   /**
    * <pre><code>
    * >>> Strings.endsWith("dogcat", "cat") == true
    * >>> Strings.endsWith("dogcat", "dog") == false
    * >>> Strings.endsWith("dogcat", "")    == true
    * >>> Strings.endsWith("dogcat", null)  == false
    * >>> Strings.endsWith("", "")          == true
    * >>> Strings.endsWith(null, "cat")     == false
    * >>> Strings.endsWith("はい", "い")     == true
    * >>> Strings.endsWith("はい", "は")     == false
    * </code></pre>
    */
   public static function endsWith(searchIn:String, searchFor:String):Bool {
      if (searchIn == null || searchFor == null)
         return false;

      #if cpp
         // TODO StringTools.endsWith doesn't work with UTF8 chars on Haxe4+CPP
         final searchInLen = searchIn.length;
         final searchForLen = searchFor.length;
         return searchInLen >= searchForLen && searchIn.indexOf(searchFor, searchInLen - searchForLen) > POS_NOT_FOUND;
      #end
      return StringTools.endsWith(searchIn, searchFor);
   }


   /**
    * <pre><code>
    * >>> Strings.endsWithAny(null, ["cat"])            == false
    * >>> Strings.endsWithAny("", [""])                 == true
    * >>> Strings.endsWithAny("dogcat", null)           == false
    * >>> Strings.endsWithAny("dogcat", [null])         == false
    * >>> Strings.endsWithAny("dogcat", [""])           == true
    * >>> Strings.endsWithAny("dogcat", ["cat"])        == true
    * >>> Strings.endsWithAny("dogcat", ["dog", "cat"]) == true
    * >>> Strings.endsWithAny("dogcat", ["dog"])        == false
    * >>> Strings.endsWithAny("はい", ["は", "い"])       == true
    * >>> Strings.endsWithAny("はい", ["は"])            == false
    * </code></pre>
    */
   public static function endsWithAny(searchIn:String, searchFor:Array<String>):Bool {
      if (searchIn == null || searchFor == null)
         return false;

      for (candidate in searchFor)
         if (candidate != null && endsWith(searchIn, candidate))
            return true;
      return false;
   }


   /**
    * <pre><code>
    * >>> Strings.endsWithAnyIgnoreCase(null, ["cat"])            == false
    * >>> Strings.endsWithAnyIgnoreCase("", [""])                 == true
    * >>> Strings.endsWithAnyIgnoreCase("dogcat", null)           == false
    * >>> Strings.endsWithAnyIgnoreCase("dogcat", [null])         == false
    * >>> Strings.endsWithAnyIgnoreCase("dogcat", [""])           == true
    * >>> Strings.endsWithAnyIgnoreCase("dogcat", ["CAT"])        == true
    * >>> Strings.endsWithAnyIgnoreCase("dogcat", ["DOG", "CAT"]) == true
    * >>> Strings.endsWithAnyIgnoreCase("dogcat", ["DOG"])        == false
    * >>> Strings.endsWithAnyIgnoreCase("はい", ["は", "い"])       == true
    * >>> Strings.endsWithAnyIgnoreCase("はい", ["は"])            == false
    * </code></pre>
    */
   public static function endsWithAnyIgnoreCase(searchIn:String, searchFor:Array<String>):Bool {
      if (searchIn == null || searchFor == null)
         return false;

      searchIn = searchIn.toLowerCase8();
      for (candidate in searchFor)
         if (candidate != null && endsWith(searchIn, candidate.toLowerCase8()))
            return true;
       return false;
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

      return endsWith(searchIn.toLowerCase(), searchFor.toLowerCase());
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
   public static function equals(str:String, other:AnyAsString):Bool
      return str == other;


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
   public static function equalsIgnoreCase(str:String, other:AnyAsString):Bool
       return str.toLowerCase8() == other.toLowerCase8();


   /**
    * <pre><code>
    * >>> Strings.filter(null,       function(s) return s == " ")       == null
    * >>> Strings.filter("",         function(s) return s == " ")       == ""
    * >>> Strings.filter(" b b b",   function(s) return s == " ")       == "   "
    * >>> Strings.filter("はいはい",   function(s) return s == "は")      == "はは"
    * >>> Strings.filter("ab:cd:ab", function(s) return s == "ab", ":") == "ab:ab"
    * </code></pre>
    *
    * @return a string containing only those characters/substrings for which <b>filter</b> returned `true`.
    */
   inline
   public static function filter(str:String, filter:String -> Bool, separator = ""):String {
      if (str.isEmpty())
         return str;

      return str.split8(separator).filter(filter).join(separator);
   }


   /**
    * <pre><code>
    * >>> Strings.filterChars(null,       function(ch) return ch == 32)            == null
    * >>> Strings.filterChars("",         function(ch) return ch == 32)            == ""
    * >>> Strings.filterChars(" b b b",   function(ch) return ch == 32)            == "   "
    * >>> Strings.filterChars("はいはい",   function(ch) return ch == Char.of("は")) == "はは"
    * </code></pre>
    *
    * @return a string containing only those characters for which <b>filter</b> returned `true`.
    */
   inline
   public static function filterChars(str:String, filter:Char -> Bool):String {
      if (str.isEmpty())
         return str;

      return str.toChars().filter(filter).map((ch) -> ch.toString()).join("");
   }


   /**
    * Calculates the Fuzzy distance between the given strings. A higher value indicates a higher similarity.
    *
    * This string matching algorithm is case-insensitive and similar to the algorithms of editors such as
    * Sublime Text, TextMate, and Atom. One point is given for every matched character. Subsequent
    * matches receive two additional points.
    *
    * <pre><code>
    * >>> Strings.getFuzzyDistance(null, null)                 == 0
    * >>> Strings.getFuzzyDistance("", "")                     == 0
    * >>> Strings.getFuzzyDistance("dogcat", "z")              == 0
    * >>> Strings.getFuzzyDistance("dogcat", "d")              == 1
    * >>> Strings.getFuzzyDistance("dogcat", "o")              == 1
    * >>> Strings.getFuzzyDistance("dogcat", "dc")             == 2
    * >>> Strings.getFuzzyDistance("dc", "dogcat")             == 2
    * >>> Strings.getFuzzyDistance("dogcat", "do")             == 4
    * >>> Strings.getFuzzyDistance("Laughing Out Loud", "lol") == 3
    * </code></pre>
    *
    * Based on https://commons.apache.org/proper/commons-lang/javadocs/api-3.4/org/apache/commons/lang3/StringUtils.html#getFuzzyDistance(java.lang.CharSequence,%20java.lang.CharSequence,%20java.util.Locale)
    */
   public static function getFuzzyDistance(left:String, right:String) {
      if (left.isEmpty() || right.isEmpty())
         return 0;

      left = left.toLowerCase8();
      right = right.toLowerCase8();

      final leftChars = left.toChars();
      final rightChars = right.toChars();
      var leftLastMatchAt = -100;
      var rightLastMatchAt = -100;

      var score = 0;

      for (leftIdx in 0...leftChars.length) {
         final leftChar = leftChars[leftIdx];
         for (rightIdx in (rightLastMatchAt > -1 ? rightLastMatchAt + 1 : 0)...rightChars.length) {
            final rightChar = rightChars[rightIdx];
            if (leftChar == rightChar) {
               score++;
               if ((leftLastMatchAt == leftIdx - 1) && (rightLastMatchAt == rightIdx - 1))
                  score += 2;
               leftLastMatchAt = leftIdx;
                rightLastMatchAt = rightIdx;
                break;
            }
         }
      }

       return score;
   }


   /**
    * Calculates the Levenshtein distance between the given strings.
    *
    * This is the number of single character modification (deletion, insertion, or
    * substitution) needed to change one string into another.
    *
    * See https://en.wikipedia.org/wiki/Levenshtein_distance
    *
    * <pre><code>
    * >>> Strings.getLevenshteinDistance(null, null)                 == 0
    * >>> Strings.getLevenshteinDistance("", "")                     == 0
    * >>> Strings.getLevenshteinDistance("dogcat", "z")              == 6
    * >>> Strings.getLevenshteinDistance("dogcat", "d")              == 5
    * >>> Strings.getLevenshteinDistance("dogcat", "o")              == 5
    * >>> Strings.getLevenshteinDistance("dogcat", "dc")             == 4
    * >>> Strings.getLevenshteinDistance("dc", "dogcat")             == 4
    * >>> Strings.getLevenshteinDistance("dogcat", "do")             == 4
    * >>> Strings.getLevenshteinDistance("laughing out loud", "lol") == 14
    * </code></pre>
    *
    * Based on https://commons.apache.org/proper/commons-lang/javadocs/api-3.4/org/apache/commons/lang3/StringUtils.html#getLevenshteinDistance(java.lang.CharSequence,%20java.lang.CharSequence)
    */
   public static function getLevenshteinDistance(left:String, right:String):Int {
      var leftLen = left.length8();
      var rightLen = right.length8();

      if (leftLen == 0) return rightLen;
      if (rightLen == 0) return leftLen;

      if (leftLen > rightLen) {
         // swap the input strings to consume less memory
         final tmp = left;
         left = right;
         right = tmp;
         final tmpLen = leftLen;
         leftLen = rightLen;
         rightLen = tmpLen;
      }

      var prevCosts = new Array<Int>();
      var costs = new Array<Int>();

      for (leftIdx in 0...leftLen + 1) {
         prevCosts.push(leftIdx);
         costs.push(0);
      }

      final leftChars = left.toChars();
      final rightChars = right.toChars();

      final min = (a:Int, b:Int) -> a > b ? b : a;

      for (rightIdx in 1...rightLen + 1) {
         final rightChar = rightChars[rightIdx - 1];
         costs[0] = rightIdx;

         for (leftIdx in 1...leftLen + 1) {
            final leftIdxMinus1 = leftIdx - 1;
            final cost = leftChars[leftIdxMinus1] == rightChar ? 0 : 1;
            costs[leftIdx] = min(min(costs[leftIdxMinus1] + 1, prevCosts[leftIdx] + 1), prevCosts[leftIdxMinus1] + cost);
         }

         final tmp = prevCosts;
         prevCosts = costs;
         costs = tmp;
      }

      return prevCosts[leftLen];
   }


   /**
    * Determines the longest common substring between the given strings.
    *
    * See https://en.wikipedia.org/wiki/Longest_common_substring_problem
    *
    * <pre><code>
    * >>> Strings.getLongestCommonSubstring(null, null)                   == null
    * >>> Strings.getLongestCommonSubstring(null, "")                     == null
    * >>> Strings.getLongestCommonSubstring("", null)                     == null
    * >>> Strings.getLongestCommonSubstring("", "")                       == ""
    * >>> Strings.getLongestCommonSubstring("dog", "")                    == ""
    * >>> Strings.getLongestCommonSubstring("dogcatcow", "cat")           == "cat"
    * >>> Strings.getLongestCommonSubstring("1234123456", "123421234516") == "12345"
    * </code></pre>
    */
   public static function getLongestCommonSubstring(left:String, right:String):String {
      if (left == null || right == null)
         return null;

      final leftLen = left.length8();
      final rightLen = right.length8();

      if (leftLen == 0 || rightLen == 0)
         return "";

      final leftChars = left.toChars();
      final rightChars = right.toChars();

      var leftSubStartAt = 0;
      var leftSubLen = 0;

      for (leftIdx in 0...leftLen) {
         for (rightIdx in 0...rightLen) {
            var currLen = 0;
            while (leftChars[leftIdx + currLen] == rightChars[rightIdx + currLen]) {
               currLen++;
               if (((leftIdx + currLen) >= leftLen) || ((rightIdx + currLen) >= rightLen))
                  break;
            }
            if (currLen > leftSubLen) {
               leftSubLen = currLen;
               leftSubStartAt = leftIdx;
            }
         }
      }
      return left.substr8(leftSubStartAt, leftSubLen);
   }


   /**
    * <pre><code>
    * >>> Strings.hashCode(null)                 == 0
    * >>> Strings.hashCode("")                   == 0
    * >>> Strings.hashCode("dog & cat")          != 0
    * >>> Strings.hashCode("dog & cat", ADLER32) == 0x0E3302D9
    * >>> Strings.hashCode("dog & cat", CRC32B)  == 0x285CEE6C
    * >>> Strings.hashCode("dog & cat", DJB2A)   == 0x439DDCD9
    * >>> Strings.hashCode("dog & cat", JAVA)    == 0x76C244F8
    * >>> Strings.hashCode("dog & cat", SDBM)    == 0x329DB138
    * </code></pre>
    *
    * @return a (by default platform dependent) hashcode for the given string
    */
   public static function hashCode(str:String, ?algo:HashCodeAlgorithm):Int {
      if (str.isEmpty())
          return 0;

      if (algo == null) algo = PLATFORM_SPECIFIC;

      return switch (algo) {
         case ADLER32:
            Adler32.make(str.toBytes());

         case CRC32B:
            Crc32.make(str.toBytes());

         case DJB2A:
            var hc:Int32 = 5381;
            for (ch in str.toChars())
               hc = ((hc << 5) + hc /* hc * 33 */) ^ ch;
            hc;

         case JAVA:
            var hc:Int32 = 0;
            for (ch in str.toChars())
               hc = ((hc << 5) - hc /* hc * 31 */) + ch;
            hc;

         case SDBM:
            var hc:Int32 = 0;
            for (ch in str.toChars())
               hc = ((hc << 6) + (hc << 16) - hc /* 65599 * hc */) + ch;
            hc;

         default: // PLATFORM SPECIFIC
            #if macro
               Crc32.make(str.toBytes());
            #elseif jvm
               (cast(str, java.lang.Object)).hashCode();
            #elseif java
               untyped __java__("str.hashCode()");
            #elseif cs
               untyped __cs__("str.GetHashCode()");
            #elseif python
               untyped hash(str);
            #else
               Crc32.make(str.toBytes());
            #end
      }
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

      return REGEX_HTML_UNESCAPE.matcher(str).map(function(m:Matcher):String {
         final match:String = m.matched();
         return switch (match) {
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
    * >>> Strings.htmlEncode(' "dog" ', true)  == " &quot;dog&quot; "
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

      final sb = new StringBuilder();
      var isFirstSpace = true;
      for (i in 0...str.length8()) {
         final ch:Char = str._charCodeAt8Unsafe(i);
         switch (ch) {
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
               if (ch > 127)
                  sb.add("&#").add(ch.toInt()).add(";");
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
    * >>> Strings.insertAt(null,   0, "dog") == null
    * >>> Strings.insertAt("cat",  0, null)  == "cat"
    * >>> Strings.insertAt("",     0, "dog") == "dog"
    * >>> Strings.insertAt("cat",  0, "dog") == "dogcat"
    * >>> Strings.insertAt("cat",  1, "dog") == "cdogat"
    * >>> Strings.insertAt("cat",  2, "dog") == "cadogt"
    * >>> Strings.insertAt("cat",  3, "dog") == "catdog"
    * >>> Strings.insertAt("cat", -1, "dog") == "cadogt"
    * >>> Strings.insertAt("cat", -2, "dog") == "cdogat"
    * >>> Strings.insertAt("cat", -3, "dog") == "dogcat"
    * >>> Strings.insertAt("cat", -4, "dog") throws "Absolute value of [pos] must be <= str.length"
    * >>> Strings.insertAt("cat",  4, "dog") throws "Absolute value of [pos] must be <= str.length"
    * </code></pre>
    *
    * @throws exception if the absolute value of insertAt is greater than str.length
    */
   public static function insertAt(str:String, pos:CharIndex, insertion:AnyAsString):String {
      if (str == null)
         return null;

      final strLen = str.length8();
      pos = pos < 0 ? strLen + pos : pos;

      if (pos < 0 || pos > strLen)
         throw "Absolute value of [pos] must be <= str.length";

      if (insertion.isEmpty())
         return str;

      return str.substring8(0, pos) + insertion + str.substring8(pos);
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
   public static function ifBlank(str:String, fallback:String):String
      return str.isBlank() ? fallback : str;


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
   public static function ifEmpty(str:String, fallback:String):String
      return str.isEmpty() ? fallback : str;


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
   public static function ifNull(str:String, fallback:String):String
      return str == null ? fallback : str;


   /**
    * <pre><code>
    * >>> Strings.indentLines(null, null)         == null
    * >>> Strings.indentLines(null, "")           == null
    * >>> Strings.indentLines("", null)           == ""
    * >>> Strings.indentLines("dog", null)        == "dog"
    * >>> Strings.indentLines("dog", "")          == "dog"
    * >>> Strings.indentLines("dog", "  ")        == "  dog"
    * >>> Strings.indentLines("dog\ndog", "  ")   == "  dog\n  dog"
    * >>> Strings.indentLines("dog\r\ndog", "  ") == "  dog\n  dog"
    * </code></pre>
    *
    * @param indentWith all lines of the <code>str</code> will be prefixed with this string
    */
   public static function indentLines(str:String, indentWith:String):String {
      if (str == null)
         return null;

      if (str.length == 0 || indentWith.isEmpty())
         return str;

      var isFirstLine = true;
      final sb = new StringBuilder();
      for (line in REGEX_SPLIT_LINES.split(str)) {
         if (isFirstLine)
            isFirstLine = false;
         else
            sb.newLine();
         sb.add(indentWith);
         sb.add(line);
      }
      return sb.toString();
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
   public static function indexOf8(str:String, searchFor:String, startAt:CharIndex = 0):CharIndex {
      if (str == null || searchFor == null)
         return POS_NOT_FOUND;

      final strLen = str.length8();
      final searchForLen = searchFor.length8();

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

      #if target.unicode
         return str.indexOf(searchFor, startAt);
      #else
         final strNeedsUTF8Workaround = str.length != strLen;
         final searchForNeedsUTF8Workaround = searchFor.length != searchForLen;

         // delegate to native lastIndexOf() if either no UTF8 chars are present or the current platform uses UTF8 encoding by default
         if (!strNeedsUTF8Workaround && !searchForNeedsUTF8Workaround)
            return str.indexOf(searchFor, startAt);

         if (searchForNeedsUTF8Workaround && !strNeedsUTF8Workaround)
            // won't find UTF8 chars in non-UTF8 string
            return POS_NOT_FOUND;

         final searchForChars = [ for (i in 0...searchForLen) searchFor._charCodeAt8Unsafe(i) ];

         var searchForPosToCheck = 0;
         for (strPos in startAt...strLen) {
            final strCh = str.charCodeAt8(strPos);
            if (strCh == searchForChars[searchForPosToCheck]) {
               searchForPosToCheck++;
               if (searchForPosToCheck == searchForLen)
                  return strPos - searchForPosToCheck + 1;
            } else
               searchForPosToCheck = 0;
         }
         return POS_NOT_FOUND;
      #end
   }


   /**
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
    *
    * @return `true` if <code>null</code> or empty ("") or only contains whitespace characters
    */
   inline
   public static function isBlank(str:String):Bool
       return str == null ? true : StringTools.trim(str).length == 0;


   /**
    * <pre><code>
    * >>> Strings.isDigits("1")   == true
    * >>> Strings.isDigits("1,1") == false
    * >>> Strings.isDigits("1.1") == false
    * >>> Strings.isDigits("1a")  == false
    * >>> Strings.isDigits("")    == false
    * >>> Strings.isDigits(null)  == false
    * >>> Strings.isDigits("は")  == false
    * </code></pre>
    *
    * @return true if the string only contains digits (0-9).
    */
   #if php inline #end
   public static function isDigits(str:String):Bool {
      #if php
         return php.Syntax.code("ctype_digit({0})", str);
      #else
         if (str.isEmpty())
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
   public static function isEmpty(str:String):Bool
      return str == null || str.length == 0;


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
   public static function isNotBlank(str:String):Bool
      return str != null && StringTools.trim(str).length > 0;


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
   public static function isNotEmpty(str:String):Bool
      return str != null && str.length > 0;


   /**
    * <pre><code>
    * >>> Strings.isLowerCase(null)   == false
    * >>> Strings.isLowerCase("")     == false
    * >>> Strings.isLowerCase("cat")  == true
    * >>> Strings.isLowerCase("CAT")  == false
    * >>> Strings.isLowerCase("cAt")  == false
    * >>> Strings.isLowerCase("cat2") == true
    * </code></pre>
    */
   public static function isLowerCase(str:String):Bool {
      if (str.isEmpty())
         return false;

      return str == str.toLowerCase8();
   }


   /**
    * <pre><code>
    * >>> Strings.isUpperCase(null)   == false
    * >>> Strings.isUpperCase("")     == false
    * >>> Strings.isUpperCase("CAT")  == true
    * >>> Strings.isUpperCase("cat")  == false
    * >>> Strings.isUpperCase("cAt")  == false
    * >>> Strings.isUpperCase("CAT2") == true
    * </code></pre>
    */
   public static function isUpperCase(str:String):Bool {
      if (str.isEmpty())
         return false;

      return str == str.toUpperCase8();
   }


   /**
    * Invokes the callback function separately on each character/substring of the given string.
    */
   public static function iterate(str:String, callback:String -> Void, separator = ""):Void {
      if (str.isEmpty())
         return;

      for (sub in str.split8(separator))
         callback(sub);
   }


   /**
    * Invokes the callback function on each character of the given string.
    */
   public static function iterateChars(str:String, callback:Char -> Void):Void {
      if (str.isEmpty())
         return;

      for (i in 0...str.length8())
           callback(str._charCodeAt8Unsafe(i));
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
   public static function lastIndexOf8(str:String, searchFor:String, ?startAt:CharIndex):CharIndex {
      if (str == null || searchFor == null)
         return POS_NOT_FOUND;

      final strLen = str.length8();
      final searchForLen = searchFor.length8();
      // assign default value
      if (startAt == null)
         startAt = strLen;

      // handling empty substring
      if (searchForLen == 0) {
         if (startAt < 0)
            return 0;
         if (startAt > strLen)
            return strLen;
         return startAt;
      }

      // startAt out-of-bound
      if (startAt < 0)
         return POS_NOT_FOUND;

      else if (startAt >= strLen)
         startAt = strLen - 1;


      #if (java || flash)
         return str.lastIndexOf(searchFor, startAt);
      #else
         final strNeedsUTF8Workaround = str.length != strLen;
         final searchForNeedsUTF8Workaround = searchFor.length != searchForLen;

         #if !(python || cs)
         // delegate to native lastIndexOf() if either no UTF8 chars are present or the current platform uses UTF8 encoding by default
         if (!strNeedsUTF8Workaround && !searchForNeedsUTF8Workaround)
              return str.lastIndexOf(searchFor, startAt);
         #end

         if (searchForNeedsUTF8Workaround && !strNeedsUTF8Workaround)
            // won't find UTF8 chars in non-UTF8 string
            return POS_NOT_FOUND;

         final searchForChars = searchFor.toChars();
         startAt += searchForLen - 1;

         var searchForPosToCheck = searchForLen - 1;
         var strPos:CharIndex = strLen;
         while (strPos-- > 0) {
            if (strPos > startAt) continue;
            final strCh = str._charCodeAt8Unsafe(strPos);

            if (strCh == searchForChars[searchForPosToCheck]) {
               if (searchForPosToCheck == 0)
                  return strPos;
               searchForPosToCheck--;
            } else
               searchForPosToCheck = searchForLen - 1;
         }
         return POS_NOT_FOUND;
      #end
   }


   /**
    * String#length variant with cross-platform UTF-8 support.
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

      #if target.unicode
         return str.length;
      #else
         return Utf8.length(str);
      #end
   }


   /**
    * <pre><code>
    * >>> Strings.left(null, 1)     == null
    * >>> Strings.left("", 0)       == ""
    * >>> Strings.left("", 1)       == ""
    * >>> Strings.left("abc", 0)    == ""
    * >>> Strings.left("abc", 2)    == "ab"
    * >>> Strings.left("abc", 4)    == "abc"
    * >>> Strings.left("abc", -1)   == ""
    * >>> Strings.left("はいはい", 2) == "はい"
    * </code></pre>
    *
    * @return the leftmost <b>len</b> characters of the given string
    */
   inline
   public static function left(str:String, len:Int) {
      if (str.length8() <= len)
         return str;

      return str.substring8(0, len);
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
    * @param canOverflow if `true`, the resulting string's length may exceed <b>targetLength</b> in case <b>padStr</b> contains more than one character.
    */
   public static function lpad(str:String, targetLength:Int, padStr:String = " ", canOverflow:Bool = true):String {
      var strLen = str.length8();
      if (str == null || strLen > targetLength)
         return str;

      if (padStr.isEmpty())
         padStr = " ";

      final sb = [ str ];
      final padLen = padStr.length8();
      while (strLen < targetLength) {
         sb.unshift(padStr);
         strLen += padLen;
      }

      if (canOverflow)
         return sb.join("");

      return sb.join("").right(targetLength);
   }


   /**
    * <pre><code>
    * >>> Strings.map(null,     function(s) return s.equals("a") ? "xy" : s)      == null
    * >>> Strings.map("",       function(s) return s.equals("a") ? "xy" : s)      == []
    * >>> Strings.map("abab",   function(s) return s.equals("a") ? "xy" : s)      == ["xy", "b", "xy", "b"]
    * >>> Strings.map("はいはい", function(s) return s.equals("は") ? "い" : s)      == ["い", "い", "い", "い"]
    * >>> Strings.map("ab:cd",  function(s) return s.equals("ab")? "xy" : s, ":") == ["xy", "cd"]
    * </code></pre>
    *
    * @return a string with each character/substring mapped by <b>mapper</b>.
    */
   inline
   public static function map<T>(str:String, mapper:String -> T, separator = ""):Array<T> {
      if (str == null)
         return null;

      if (separator == null)
         throw "[separator] must not be null";

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
    * Alias for `substringBefore()`.
    */
   inline
   public static function removeAfter(str:String, searchFor:String):String
      return substringBefore(str, searchFor);


   /**
    * Alias for `substringBeforeLast()`.
    */
   inline
   public static function removeAfterLast(str:String, searchFor:String):String
      return substringBeforeLast(str, searchFor);


   /**
    * Alias for `substringBeforeIgnoreCase()`.
    */
   inline
   public static function removeAfterIgnoreCase(str:String, searchFor:String):String
      return substringBeforeIgnoreCase(str, searchFor);


   /**
    * Alias for `substringBeforeLastIgnoreCase()`.
    */
   inline
   public static function removeAfterLastIgnoreCase(str:String, searchFor:String):String
      return substringBeforeLastIgnoreCase(str, searchFor);


   /**
    * Removes a substring at the given position with the given length
    *
    * <pre><code>
    * >>> Strings.removeAt(null, 1, 1)     == null
    * >>> Strings.removeAt("", 1, 1)       == ""
    * >>> Strings.removeAt("dogcat",  3, 3) == "dog"
    * >>> Strings.removeAt("dogcat",  3, 1) == "dogat"
    * >>> Strings.removeAt("dogcat",  3, 0) == "dogcat"
    * >>> Strings.removeAt("dogcat",  4, 2) == "dogc"
    * >>> Strings.removeAt("dogcat",  5, 2) == "dogca"
    * >>> Strings.removeAt("dogcat",  6, 2) == "dogcat"
    * >>> Strings.removeAt("dogcat",  9, 2) == "dogcat"
    * >>> Strings.removeAt("dogcat",  0, 3) == "cat"
    * >>> Strings.removeAt("dogcat", -4, 3) == "dot"
    * >>> Strings.removeAt("dogcat", -9, 1) throws "[pos] must be smaller than -1 * str.length"
    * </code></pre>
    *
    * @throws exception the <b>pos</b> is smaller than `-1 * str.length`
    */
   public static function removeAt(str:String, pos:CharIndex, length:Int):String {
       if (str.isEmpty() || length < 1)
           return str;

       final strLen = str.length8();
       pos = pos < 0 ? strLen + pos : pos;

       if (pos < 0)
           throw "[pos] must be smaller than -1 * str.length";

       if (pos + length >= strLen)
           return str.substring8(0, pos);

       return str.substring8(0, pos) + str.substring8(pos + length);
   }


   /**
    * Alias for <code>substringAfter()</code>.
    */
   inline
   public static function removeBefore(str:String, searchFor:String):String
      return substringAfter(str, searchFor);


   /**
    * Alias for <code>substringAfterLast()</code>.
    */
   inline
   public static function removeBeforeLast(str:String, searchFor:String):String
      return substringAfterLast(str, searchFor);


   /**
    * Alias for <code>substringAfterIgnoreCase()</code>.
    */
   inline
   public static function removeBeforeIgnoreCase(str:String, searchFor:String):String
      return substringAfterIgnoreCase(str, searchFor);


   /**
    * Alias for <code>substringAfterIgnoreCase()</code>.
    */
   inline
   public static function removeBeforeLastIgnoreCase(str:String, searchFor:String):String
      return substringAfterLastIgnoreCase(str, searchFor);


   /**
    * Removes all occurences of <b>searchFor</b> from the given string.
    *
    * <pre><code>
    * >>> Strings.removeAll(null, null)      == null
    * >>> Strings.removeAll(null, "")        == null
    * >>> Strings.removeAll("", null)        == ""
    * >>> Strings.removeAll("", "")          == ""
    * >>> Strings.removeAll("abab", "a")     == "bb"
    * >>> Strings.removeAll("abcabca", "bc") == "aaa"
    * </code></pre>
    */
   inline
   public static function removeAll(searchIn:String, searchFor:String):String
      return replaceAll(searchIn, searchFor, "");


   /**
    * Removes the first occurrence of <b>searchFor</b> in <b>searchIn</b>.
    *
    * <pre><code>
    * >>> Strings.removeFirst(null, "dog")           == null
    * >>> Strings.removeFirst("", "dog")             == ""
    * >>> Strings.removeFirst("a", "")               == "a"
    * >>> Strings.removeFirst("dogCATdogCAT", "dog") == "CATdogCAT"
    * >>> Strings.removeFirst("dogCATdogCAT", null)  == "dogCATdogCAT"
    * >>> Strings.removeFirst("dogCATdogCAT", "")    == "dogCATdogCAT"
    * >>> Strings.removeFirst("はいはい", "は")        == "いはい"
    * </code></pre>
    */
   inline
   public static function removeFirst(searchIn:String, searchFor:String):String
      return replaceFirst(searchIn, searchFor, "");


   /**
    *  Removes the first occurrence of <b>searchFor</b> in <b>searchIn</b> igorning the case.
    *
    * <pre><code>
    * >>> Strings.removeFirstIgnoreCase(null, "dog")           == null
    * >>> Strings.removeFirstIgnoreCase("", "dog")             == ""
    * >>> Strings.removeFirstIgnoreCase("a", "")               == "a"
    * >>> Strings.removeFirstIgnoreCase("dogCATdogCAT", "DOG") == "CATdogCAT"
    * >>> Strings.removeFirstIgnoreCase("dogCATdogCAT", null)  == "dogCATdogCAT"
    * >>> Strings.removeFirstIgnoreCase("dogCATdogCAT", "")    == "dogCATdogCAT"
    * >>> Strings.removeFirstIgnoreCase("はいはい", "は")        == "いはい"
    * </code></pre>
    */
   inline
   public static function removeFirstIgnoreCase(searchIn:String, searchFor:String):String
      return replaceFirstIgnoreCase(searchIn, searchFor, "");


   /**
    * Removes all ANSI escape sequences from the given string.
    *
    * <pre><code>
    * >>> Strings.removeAnsi(null)                         == null
    * >>> Strings.removeAnsi("")                           == ""
    * >>> Strings.removeAnsi("\x1B[1mHello World!\x1B[0m") == "Hello World!"
    * </code></pre>
    */
   public static function removeAnsi(str:String):String {
      if (str.isEmpty())
         return str;

      return REGEX_ANSI_ESC.replace(str, "");
   }


   /**
    * Removes the substring <b>searchFor</b> from the start of the given string.
    *
    * <pre><code>
    * >>> Strings.removeLeading(null, null)   == null
    * >>> Strings.removeLeading(null, "")     == null
    * >>> Strings.removeLeading("", null)     == ""
    * >>> Strings.removeLeading("", "")       == ""
    * >>> Strings.removeLeading("abab", "a")  == "bab"
    * >>> Strings.removeLeading("aba",  "b")  == "aba"
    * >>> Strings.removeLeading("/aba", "/")  == "aba"
    * >>> Strings.removeLeading("//aba", "/") == "aba"
    * >>> Strings.removeLeading("はい", "は")   == "い"
    * >>> Strings.removeLeading("いはい", "は") == "いはい"
    * </code></pre>
    */
   public static function removeLeading(searchIn:String, searchFor:String):String {
      if (searchIn.isEmpty() || searchFor.isEmpty())
         return searchIn;

      while (searchIn.startsWith(searchFor)) {
         searchIn = searchIn.substring(searchFor.length, searchIn.length);
      }
      return searchIn;
   }


   /**
    * Removes all XML tags from the given string.
    *
    * <pre><code>
    * >>> Strings.removeTags(null)                   == null
    * >>> Strings.removeTags("")                     == ""
    * >>> Strings.removeTags("dog")                  == "dog"
    * >>> Strings.removeTags("<b>dog</b>")           == "dog"
    * >>> Strings.removeTags("<!-- cat -->dog")      == "dog"
    * >>> Strings.removeTags("<ol><li>dog</ol>")     == "dog"
    * >>> Strings.removeTags("<b\n>dog\n</b\n>")     == "dog\n"
    * >>> Strings.removeTags("<b>はい</b>")           == "はい"
    * </code></pre>
    */
   inline
   public static function removeTags(xml:String):String {
      if (xml.isEmpty())
         return xml;

      #if php
         return php.Syntax.code("strip_tags({0})", xml);
      #else
         return REGEX_REMOVE_XML_TAGS.replace(xml, "");
      #end
   }


   /**
    * Removes the substring <b>searchFor</b> from the end of the given string.
    *
    * <pre><code>
    * >>> Strings.removeTrailing(null, null)   == null
    * >>> Strings.removeTrailing(null, "")     == null
    * >>> Strings.removeTrailing("", null)     == ""
    * >>> Strings.removeTrailing("", "")       == ""
    * >>> Strings.removeTrailing("abab", "b")  == "aba"
    * >>> Strings.removeTrailing("aba",  "b")  == "aba"
    * >>> Strings.removeTrailing("aba/", "/")  == "aba"
    * >>> Strings.removeTrailing("aba//", "/") == "aba"
    * >>> Strings.removeTrailing("いは", "は")  == "い"
    * >>> Strings.removeTrailing("いはい", "は") == "いはい"
    * </code></pre>
    */
   public static function removeTrailing(searchIn:String, searchFor:String):String {
      if (searchIn.isEmpty() || searchFor.isEmpty())
         return searchIn;

      while (searchIn.endsWith(searchFor)) {
         searchIn = searchIn.substring(0, searchIn.length - searchFor.length);
      }
      return searchIn;
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
    * >>> Strings.replaceAll("d", "", ",")                 == "d"
    * >>> Strings.replaceAll("dogCATdogCAT", "dog", "***") == "***CAT***CAT"
    * >>> Strings.replaceAll("dogCATdog", "dog", null)     == "nullCATnull"
    * >>> Strings.replaceAll("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
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
    * >>> Strings.replaceFirst("d", "", ",")                 == "d"
    * >>> Strings.replaceFirst("dogCATdogCAT", "dog", "***") == "***CATdogCAT"
    * >>> Strings.replaceFirst("dogCATdogCAT", "dog", null)  == "nullCATdogCAT"
    * >>> Strings.replaceFirst("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
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
         if (searchIn.length8() > 1)
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
    * >>> Strings.replaceFirstIgnoreCase("d", "", ",")                 == "d"
    * >>> Strings.replaceFirstIgnoreCase("dogCATdogCAT", "DOG", "***") == "***CATdogCAT"
    * >>> Strings.replaceFirstIgnoreCase("dogCATdogCAT", "DOG", null)  == "nullCATdogCAT"
    * >>> Strings.replaceFirstIgnoreCase("dogCATdogCAT", null, "cat")  == "dogCATdogCAT"
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
         if (searchIn.length8() > 1)
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

      final chars:Array<String> = str.split8("");
      chars.reverse();
      return chars.join("");
   }


   /**
    * <pre><code>
    * >>> Strings.right(null, 1)    == null
    * >>> Strings.right("", 0)      == ""
    * >>> Strings.right("", 1)      == ""
    * >>> Strings.right("abc", 0)   == ""
    * >>> Strings.right("abc", 2)   == "bc"
    * >>> Strings.right("abc", 4)   == "abc"
    * >>> Strings.right("abc", -1)  == ""
    * </code></pre>
    *
    * @return the rightmost <b>len</b> characters of the given string
    */
   public static function right(str:String, len:Int) {
      if (str.isEmpty())
         return str;

      return str.substring8(str.length8() - len);
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
    * @param canOverflow if `true`, the resulting string's length may exceed <b>targetLength</b> in case <b>padStr</b> contains more than one character.
    */
   public static function rpad(str:String, targetLength:Int, padStr:String = " ", canOverflow:Bool = true):String {
      var strLen = str.length8();
      if (str == null || strLen > targetLength)
         return str;

      if (padStr.isEmpty())
         padStr = " ";

      final padLen = padStr.length8();
      final sb = new StringBuilder(str);
      while (strLen < targetLength) {
         sb.add(padStr);
         strLen += padLen;
      }

      if (canOverflow)
         return sb.toString();

      return sb.toString().left(targetLength);
   }


   /**
    * String#split() variant with cross-platform UTF-8 support and consistent behavior.
    *
    * <pre><code>
    * >>> Strings.split8(null, null)          == null
    * >>> Strings.split8(null, "")            == null
    * >>> Strings.split8("", "")              == []
    * >>> Strings.split8("a.b.c", null)       == null
    * >>> Strings.split8("a.b.c", "")         == [ "a", ".", "b", ".", "c" ]
    * >>> Strings.split8("a.b.c", "", 3)      == [ "a", ".", "b.c" ]
    * >>> Strings.split8("a.b.c", "", 9)      == [ "a", ".", "b", ".", "c" ]
    * >>> Strings.split8("a.b.c", ".")        == [ "a", "b", "c" ]
    * >>> Strings.split8("a...c", ".")        == [ "a", "", "", "c" ]
    * >>> Strings.split8("a.b,c", [".", ","]) == [ "a", "b", "c" ]
    * >>> Strings.split8("a.b.c", ".", 2)     == [ "a", "b.c" ]
    * >>> Strings.split8(".a.b.c.", ".")      == [ "", "a", "b", "c", "" ]
    * >>> Strings.split8(".a.b.c.", ".", 3)   == [ "", "a", "b.c." ]
    * >>> Strings.split8(".a.b.c.", ".", 9)   == [ "", "a", "b", "c", "" ]
    * >>> Strings.split8(".a.b.c.", ".", -1)  == [ "", "a", "b", "c", "" ]
    * >>> Strings.split8("はい", "")           == [ "は", "い" ]
    * </code></pre>
    *
    * @param separator one or multiple separators to use for splitting
    * @param maxParts the split limit, the maximum number of elements in the resulting array
    */
   public static function split8(str:String, separator:OneOrMany<String>, maxParts:Int = 0):Array<String> {
      if (str == null || separator == null)
         return null;

      final strLen = str.length8();

      if (strLen == 0)
         return [];

      final separators = separator.filter((s) -> s != null);
      if (separators.length == 0)
         return null;

      #if target.unicode
         if (maxParts <= 0 && separators.length == 1)
            return str.split(separators[0]);
      #end

      inline
      function sub(str:String, pos:Int, len:Int) {
         #if target.unicode
            return str.substr(pos, len);
         #else
            return Utf8.sub(str, pos, len);
         #end
      }

      if (separators.indexOf("") > -1) {
         if (maxParts <= 0)
            return [ for (i in 0...strLen) sub(str, i, 1) ];

         if (maxParts > strLen)
            maxParts = strLen;
         maxParts--;
         final result = [ for (i in 0...maxParts) sub(str, i, 1) ];
         result.push(sub(str, maxParts, strLen - maxParts));
         return result;
      }

      final separatorsLengths = [ for (sep in separators) sep.length8() ];
      var lastFoundAt = 0;
      final result = [];
      var resultCount = 0;
      while (true) {
         var separatorLen:Int = 0;
         var foundAt = POS_NOT_FOUND;
         for (i in 0...separators.length) {
            final sepFoundAt = str.indexOf8(separators[i], lastFoundAt);
            if (sepFoundAt != POS_NOT_FOUND) {
               if (foundAt == POS_NOT_FOUND || sepFoundAt < foundAt) {
                  foundAt = sepFoundAt;
                  separatorLen = separatorsLengths[i];
               }
            }
         }
         resultCount++;
         if (foundAt == POS_NOT_FOUND || resultCount == maxParts) {
            result.push(sub(str, lastFoundAt, strLen - lastFoundAt));
            break;
         }
         result.push(sub(str, lastFoundAt, foundAt - lastFoundAt));
         lastFoundAt = foundAt + separatorLen;
      }
      return result;
   }


   /**
    * >>> Strings.splitAt(null, null)  == null
    * >>> Strings.splitAt(null, 0)     == null
    * >>> Strings.splitAt(null, 1)     == null
    * >>> Strings.splitAt("", null)    == [""]
    * >>> Strings.splitAt("cat",  0) == ["cat"]
    * >>> Strings.splitAt("cat",  1) == ["c", "at"]
    * >>> Strings.splitAt("cat",  2) == ["ca", "t"]
    * >>> Strings.splitAt("cat",  3) == ["cat"]
    * >>> Strings.splitAt("cat",  4) == ["cat"]
    * >>> Strings.splitAt("cat", -1) == ["ca", "t"]
    * >>> Strings.splitAt("cat", -2) == ["c", "at"]
    * >>> Strings.splitAt("cat", -3) == ["cat"]
    * >>> Strings.splitAt("cat", -4) == ["cat"]
    * >>> Strings.splitAt("cat", [2,1]) == ["c", "a", "t"]
    */
   public static function splitAt(str:String, splitPos:OneOrMany<CharIndex>):Array<String> {
      if (str == null)
         return null;

      if (splitPos == null || splitPos.length == 0)
         return [str];

      final strLen = str.length8();
      if (strLen == 0)
         return [str];

      // remove dups, out-of-bound positions and calculate absolute position of negative values
      final pos = new Array<CharIndex>();
      for (p in splitPos) {
         if (p < 0)
            p = strLen + p;
         if (p < 0 || p >= strLen)
            continue;
         if (pos.indexOf(p) > -1)
            continue;
         pos.push(p);
      }

      pos.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);

      final result = new Array<String>();

      var lastPos = 0;
      for (p in pos) {
         final chunk = str.substring8(lastPos, p);
         if (chunk.isNotEmpty())
            result.push(chunk);
         lastPos = p;
      }
      final chunk = str.substring8(lastPos);
      if (chunk.isNotEmpty())
         result.push(chunk);
      return result;
   }


   /**
    * >>> Strings.splitEvery(null,   1) == null
    * >>> Strings.splitEvery("",     1) == [ "" ]
    * >>> Strings.splitEvery("dog",  1) == [ "d", "o", "g" ]
    * >>> Strings.splitEvery("dog",  2) == [ "do", "g" ]
    * >>> Strings.splitEvery("dog",  3) == [ "dog" ]
    * >>> Strings.splitEvery("dog",  4) == [ "dog" ]
    * >>> Strings.splitEvery("dog",  0) throws "[count] must be greater than 0"
    * >>> Strings.splitEvery("dog", -1) throws "[count] must be greater than 0"
    *
    * @throws exception if length < 1
    */
   public static function splitEvery(str:String, count:Int):Array<String> {
      if (str == null)
         return null;

      if (count < 1)
         throw "[count] must be greater than 0";

      final strLen = str.length8();
      if (strLen == 0 || count >= strLen)
         return [str];

      final result = new Array<String>();
      var pos = 0;
      while (true) {
         final chunk = str.substr8(pos, count);
         pos += count;
         if (chunk.isEmpty())
            break;
         result.push(chunk);
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
   inline
   public static function splitLines(str:String):Array<String>
      return str.isEmpty() ? [] : REGEX_SPLIT_LINES.split(str);


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

      if (searchFor.isEmpty() || searchIn == searchFor)
         return true;

      #if cpp
         // TODO StringTools.startsWith doesn't work with UTF8 chars on Haxe4+CPP
         return (searchIn.length >= searchFor.length && searchIn.lastIndexOf(searchFor, 0) == 0);
      #end

      return StringTools.startsWith(searchIn, searchFor);
   }


   /**
    * <pre><code>
    * >>> Strings.startsWithAny(null, ["cat"])            == false
    * >>> Strings.startsWithAny("", [""])                 == true
    * >>> Strings.startsWithAny("dogcat", null)           == false
    * >>> Strings.startsWithAny("dogcat", [null])         == false
    * >>> Strings.startsWithAny("dogcat", [""])           == true
    * >>> Strings.startsWithAny("dogcat", ["dog"])        == true
    * >>> Strings.startsWithAny("dogcat", ["dog", "cat"]) == true
    * >>> Strings.startsWithAny("dogcat", ["cat"])        == false
    * >>> Strings.startsWithAny("はい", ["は", "い"])       == true
    * >>> Strings.startsWithAny("はい", ["い"])            == false
    * </code></pre>
    */
   public static function startsWithAny(searchIn:String, searchFor:Array<String>):Bool {
      if (searchIn == null || searchFor == null)
         return false;

      for (candidate in searchFor)
         if (candidate != null && startsWith(searchIn, candidate))
            return true;
      return false;
   }


   /**
    * <pre><code>
    * >>> Strings.startsWithAnyIgnoreCase(null, ["cat"])            == false
    * >>> Strings.startsWithAnyIgnoreCase("", [""])                 == true
    * >>> Strings.startsWithAnyIgnoreCase("dogcat", null)           == false
    * >>> Strings.startsWithAnyIgnoreCase("dogcat", [null])         == false
    * >>> Strings.startsWithAnyIgnoreCase("dogcat", [""])           == true
    * >>> Strings.startsWithAnyIgnoreCase("dogcat", ["DOG"])        == true
    * >>> Strings.startsWithAnyIgnoreCase("dogcat", ["DOG", "CAT"]) == true
    * >>> Strings.startsWithAnyIgnoreCase("dogcat", ["CAT"])        == false
    * >>> Strings.startsWithAnyIgnoreCase("はい", ["は", "い"])       == true
    * >>> Strings.startsWithAnyIgnoreCase("はい", ["い"])            == false
    * </code></pre>
    */
   public static function startsWithAnyIgnoreCase(searchIn:String, searchFor:Array<String>):Bool {
      if (searchIn == null || searchFor == null)
         return false;

      searchIn = searchIn.toLowerCase8();
      for (candidate in searchFor) {
         if (candidate != null && startsWith(searchIn, candidate.toLowerCase8()))
            return true;
      }
      return false;
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

      return startsWith(searchIn.toLowerCase(), searchFor.toLowerCase());
   }


   /**
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
    *
    * @return <b>len</b> characters of <b>str</b>, starting from <b>startAt</b>.
    */
   public static function substr8(str:String, startAt:CharIndex, ?len:Int):String {
      if (str.isEmpty())
         return str;

      if (len == null)
         len = str.length8();

      if (len <= 0)
         return "";

      if (startAt < 0) {
         startAt += str.length8();
         if (startAt < 0) startAt = 0;
      }

      #if target.unicode
         return str.substr(startAt, len);
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
    *
    * @return the part of <b>str</b> from <b>startAt</b> to but not including <b>endAt</b>.
    */
   public static function substring8(str:String, startAt:CharIndex, ?endAt:CharIndex):String {
      if (str.isEmpty())
         return str;

      if (endAt == null)
         endAt = str.length8();

      #if target.unicode
         return str.substring(startAt, endAt);
      #else
         if (startAt < 0) startAt = 0;
         if (endAt < 0) endAt = 0;
         if (startAt > endAt) {
            final tmp = startAt;
            startAt = endAt;
            endAt = tmp;
         }
         return Utf8.sub(str, startAt, endAt - startAt);
      #end
   }


   /**
    * <pre><code>
    * >>> Strings.substringAfter(null, "dog")           == null
    * >>> Strings.substringAfter("", "dog")             == ""
    * >>> Strings.substringAfter("dogCATdogCAT", "dog") == "CATdogCAT"
    * >>> Strings.substringAfter("dogCATdogCOW", "COW") == ""
    * >>> Strings.substringAfter("dogCATdogCAT", null)  == ""
    * >>> Strings.substringAfter("dogCATdogCAT", "")    == ""
    * >>> Strings.substringAfter("dogCATdogCAT", "cow") == ""
    * >>> Strings.substringAfter("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringAfter("はいはい", "い")        == "はい"
    * </code></pre>
    */
   public static function substringAfter(str:String, searchFor:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (str == "" || searchFor.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      final foundAt = str.indexOf(searchFor);
      if (foundAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      return str.substring(foundAt + searchFor.length);
   }


   /**
    * <pre><code>
    * >>> Strings.substringAfterIgnoreCase(null, "dog")           == null
    * >>> Strings.substringAfterIgnoreCase("", "dog")             == ""
    * >>> Strings.substringAfterIgnoreCase("dogCATdogCAT", "DOG") == "CATdogCAT"
    * >>> Strings.substringAfterIgnoreCase("dogCATdogCOW", "COW") == ""
    * >>> Strings.substringAfterIgnoreCase("dogCATdogCAT", null)  == ""
    * >>> Strings.substringAfterIgnoreCase("dogCATdogCAT", "")    == ""
    * >>> Strings.substringAfterIgnoreCase("dogCATdogCAT", "cow") == ""
    * >>> Strings.substringAfterIgnoreCase("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringAfterIgnoreCase("はいはい", "い")        == "はい"
    * </code></pre>
    */
   public static function substringAfterIgnoreCase(str:String, searchFor:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (str == "" || searchFor.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      searchFor = searchFor.toLowerCase();

      final foundAt = str.toLowerCase().indexOf(searchFor);
      if (foundAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      return str.substring(foundAt + searchFor.length);
   }


   /**
    * <pre><code>
    * >>> Strings.substringBetween(null, null, null)             == null
    * >>> Strings.substringBetween("",   null, null)             == ""
    * >>> Strings.substringBetween("  ", null, null)             == ""
    * >>> Strings.substringBetween("  ", "", null)               == ""
    * >>> Strings.substringBetween("dogCATdogCOW", "dog")        == "CAT"
    * >>> Strings.substringBetween("dogCATdogCOW", "COW")        == ""
    * >>> Strings.substringBetween("dogCATdogCOW", "dog", "COW") == "CATdog"
    * >>> Strings.substringBetween("dogCATdogCAT", null)         == ""
    * >>> Strings.substringBetween("dogCATdogCAT", "")           == ""
    * >>> Strings.substringBetween("dogCATdogCAT", "cow")        == ""
    * >>> Strings.substringBetween("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringBetween("はいはい", "い")               == "は"
    * </code></pre>
    */
   public static function substringBetween(str:String, after:String, ?before:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (before == null) before = after;

      if (str == "" || after.isEmpty() || before.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      final foundAfterAt = str.indexOf(after);
      if (foundAfterAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      final foundBeforeAt = str.indexOf(before, foundAfterAt + after.length);
      if (foundBeforeAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      return str.substring(foundAfterAt + after.length, foundBeforeAt);
   }


   /**
    * <pre><code>
    * >>> Strings.substringBetweenIgnoreCase(null, null, null)             == null
    * >>> Strings.substringBetweenIgnoreCase("",   null, null)             == ""
    * >>> Strings.substringBetweenIgnoreCase("  ", null, null)             == ""
    * >>> Strings.substringBetweenIgnoreCase("  ", "", null)               == ""
    * >>> Strings.substringBetweenIgnoreCase("dogCATdogCOW", "dog")        == "CAT"
    * >>> Strings.substringBetweenIgnoreCase("dogCATdogCOW", "COW")        == ""
    * >>> Strings.substringBetweenIgnoreCase("dogCATdogCOW", "dog", "COW") == "CATdog"
    * >>> Strings.substringBetweenIgnoreCase("dogCATdogCAT", null)         == ""
    * >>> Strings.substringBetweenIgnoreCase("dogCATdogCAT", "")           == ""
    * >>> Strings.substringBetweenIgnoreCase("dogCATdogCAT", "cow")        == ""
    * >>> Strings.substringBetweenIgnoreCase("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringBetweenIgnoreCase("はいはい", "い")               == "は"
    * </code></pre>
    */
   public static function substringBetweenIgnoreCase(str:String, after:String, ?before:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (before == null) before = after;

      if (str == "" || after.isEmpty() || before.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      final strLower = str.toLowerCase8();
      after = after.toLowerCase8();
      before = before.toLowerCase8();

      final foundAfterAt = strLower.indexOf(after);
      if (foundAfterAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      final foundBeforeAt = strLower.indexOf(before, foundAfterAt + after.length);
      if (foundBeforeAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      return str.substring(foundAfterAt + after.length, foundBeforeAt);
   }


   /**
    * <pre><code>
    * >>> Strings.substringAfterLast(null, "dog")           == null
    * >>> Strings.substringAfterLast("", "dog")             == ""
    * >>> Strings.substringAfterLast("dogCATdogCAT", "dog") == "CAT"
    * >>> Strings.substringAfterLast("dogCATdogCAT", "CAT") == ""
    * >>> Strings.substringAfterLast("dogCATdogCAT", null)  == ""
    * >>> Strings.substringAfterLast("dogCATdogCAT", "")    == ""
    * >>> Strings.substringAfterLast("dogCATdogCAT", "cow") == ""
    * >>> Strings.substringAfterLast("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringAfterLast("はいはい", "は")        == "い"
    * </code></pre>
    */
   public static function substringAfterLast(str:String, searchFor:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (str == "" || searchFor.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      final foundAt = str.lastIndexOf(searchFor);
      if (foundAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      return str.substring(foundAt + searchFor.length);
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
    * >>> Strings.substringAfterLastIgnoreCase("dogCATdogCAT", "cow") == ""
    * >>> Strings.substringAfterLastIgnoreCase("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringAfterLastIgnoreCase("はいはい", "は")        == "い"
    * </code></pre>
    */
   public static function substringAfterLastIgnoreCase(str:String, searchFor:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (str == "" || searchFor.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      searchFor = searchFor.toLowerCase();

      final foundAt = str.toLowerCase().lastIndexOf(searchFor);
      if (foundAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      return str.substring(foundAt + searchFor.length);
   }


   /**
    * <pre><code>
    * >>> Strings.substringBefore(null, "dog")           == null
    * >>> Strings.substringBefore("", "dog")             == ""
    * >>> Strings.substringBefore("dogCATdogCAT", "CAT") == "dog"
    * >>> Strings.substringBefore("dogCATdogCAT", "dog") == ""
    * >>> Strings.substringBefore("dogCATdogCAT", null)  == ""
    * >>> Strings.substringBefore("dogCATdogCAT", "")    == ""
    * >>> Strings.substringBefore("dogCATdogCAT", "cow") == ""
    * >>> Strings.substringBefore("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringBefore("はいはい", "い")        == "は"
    * </code></pre>
    */
   public static function substringBefore(str:String, searchFor:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (str == "" || searchFor.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      final foundAt = str.indexOf(searchFor);
      if (foundAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

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
    * >>> Strings.substringBeforeIgnoreCase("dogCATdogCAT", "cow") == ""
    * >>> Strings.substringBeforeIgnoreCase("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringBeforeIgnoreCase("はいはい", "い")        == "は"
    * </code></pre>
    */
   public static function substringBeforeIgnoreCase(str:String, searchFor:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (str == "" || searchFor.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      searchFor = searchFor.toLowerCase();

      final foundAt = str.toLowerCase().indexOf(searchFor);
      if (foundAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      return str.substring(0, foundAt);
   }


   /**
    * <pre><code>
    * >>> Strings.substringBeforeLast(null, "dog")           == null
    * >>> Strings.substringBeforeLast("", "dog")             == ""
    * >>> Strings.substringBeforeLast("cat", "dog")          == ""
    * >>> Strings.substringBeforeLast("dogCATdogCAT", "CAT") == "dogCATdog"
    * >>> Strings.substringBeforeLast("dogCATdogCAT", "dog") == "dogCAT"
    * >>> Strings.substringBeforeLast("fo1CATdogCAT", "fo1") == ""
    * >>> Strings.substringBeforeLast("dogCATdogCAT", null)  == ""
    * >>> Strings.substringBeforeLast("dogCATdogCAT", "")    == ""
    * >>> Strings.substringBeforeLast("dogCATdogCAT", "cow") == ""
    * >>> Strings.substringBeforeLast("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringBeforeLast("はいはい", "い")        == "はいは"
    * </code></pre>
    */
   public static function substringBeforeLast(str:String, searchFor:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (str == "" || searchFor.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      final foundAt = str.lastIndexOf(searchFor);
      if (foundAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

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
    * >>> Strings.substringBeforeLastIgnoreCase("dogCATdogCAT", "cow") == ""
    * >>> Strings.substringBeforeLastIgnoreCase("dogCATdogCAT", "cow", INPUT) == "dogCATdogCAT"
    * >>> Strings.substringBeforeLastIgnoreCase("はいはい", "い")        == "はいは"
    * </code></pre>
    */
   public static function substringBeforeLastIgnoreCase(str:String, searchFor:String, notFoundDefault:StringNotFoundDefault = EMPTY):String {
      if (str == null)
         return null;

      if (str == "" || searchFor.isEmpty())
         return _getNotFoundDefault(str, notFoundDefault);

      searchFor = searchFor.toLowerCase();

      final foundAt = str.toLowerCase().lastIndexOf(searchFor);
      if (foundAt == POS_NOT_FOUND)
         return _getNotFoundDefault(str, notFoundDefault);

      return str.substring(0, foundAt);
   }


   /**
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
    *
    * @return false if value is null, "", "false" or "0". otherwise returns true.
    */
   inline
   public static function toBool(str:String):Bool {
      if (str.isEmpty())
         return false;

      return switch (str.toLowerCase()) {
         case "false", "0", "no": false;
         default: true;
      }
   }


   /**
    * <pre><code>
    * >>> Strings.toBytes(null)                 == null
    * >>> Strings.toBytes("abc").getString(1,2) == "bc"
    * >>> Strings.toBytes("はい").getString(3,3) == "い"
    * </code></pre>
    *
    * @return the strings internal byte array
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
   public static function toChar(charCode:Int):Char
      return Char.of(charCode);


   /**
    * <pre><code>
    * >>> Strings.toCharIterator(null).hasNext()          == false
    * >>> Strings.toCharIterator("").hasNext()            == false
    * >>> Strings.toCharIterator("cat").hasNext()         == true
    * >>> Strings.toCharIterator("cat").next().toString() == 'c'
    * >>> Strings.toCharIterator("はい").next().toString() == 'は'
    * </code></pre>
    */
   inline
   public static function toCharIterator(str:String):CharIterator
      return CharIterator.fromString(str);


   /**
    * <pre><code>
    * >>> Strings.toChars(null)  == null
    * >>> Strings.toChars("")    == []
    * >>> Strings.toChars("  ")  == [ 32, 32 ]
    * >>> Strings.toChars(" は") == [ 32, 12399 ]
    * </code></pre>
    *
    * @return array containing the codes of all characters
    */
   public static function toChars(str:String):Array<Char> {
      if (str == null)
         return null;

      final strLen = str.length8();

      if (strLen == 0)
         return [];

      return [ for (i in 0...strLen) str._charCodeAt8Unsafe(i) ];
   }


   /**
    * <pre><code>
    * >>> Strings.toPattern(null) == null
    * >>> Strings.toPattern(".*").matcher("foo").matches() == true
    * </code></pre>
    *
    * @return an hx.strings.Pattern object using the given string as regular expression pattern.
    */
   inline
   public static function toPattern(str:String, options:Either3<String, MatchingOption, Array<MatchingOption>> = null):Pattern {
      if (str == null)
         return null;
      return Pattern.compile(str, options);
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
      if (str == null)
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
      final result = Std.parseFloat(str);
      if (Math.isNaN(result))
         return ifUnparseable;
      return result;
   }


   /**
    * Static extension for <code>Int</code>.
    *
    * <pre><code>
    * >>> Strings.toHex(1)              == "1"
    * >>> Strings.toHex(10)             == "A"
    * >>> Strings.toHex(100)            == "64"
    * >>> Strings.toHex(100, 4)         == "0064"
    * >>> Strings.toHex(1000, 2)        == "3E8"
    * >>> Strings.toHex(1000, 2, false) == "3e8"
    * >>> Strings.toHex(-1)             == "FFFFFFFF"
    * >>> Strings.toHex(-10)            == "FFFFFFF6"
    * >>> Strings.toHex(-10, 10)        == "00FFFFFFF6"
    * </code></pre>
    *
    * @param minDigits the resulting string is left padded with <code>0</code> until it length equals <code>minDigits</code>
    * @return the hexadecimal representation of <b>num</b>
    */
   public static function toHex(num:Int, minDigits:Int = 0, upperCase:Bool = true):String {
      final hexed = StringTools.hex(num, 0);
      if (!upperCase)
          return hexed.toLowerCase();
      if (hexed.length >= minDigits)
          return hexed;
      return hexed.lpad(minDigits, "0");
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
      final result = Std.parseInt(str);
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
    * >>> Strings.toLowerCase8("ФЫА") == "фыа"
    * >>> Strings.toLowerCase8("ЙЦУ") == "йцу"
    * >>> Strings.toLowerCase8("はい") == "はい"
    * </code></pre>
    */
   public static function toLowerCase8(str:String):String {
      if (str.isEmpty())
         return str;

      #if php
         return php.Syntax.code("mb_strtolower({0}, {1})", str, "UTF-8");
      #elseif target.unicode
         return str.toLowerCase();
      #else
         final sb = new StringBuilder();
         for (i in 0...str.length8())
            sb.addChar(str._charCodeAt8Unsafe(i).toLowerCase());
         return sb.toString();
      #end
   }


   /**
    * Lowercase the first character of the given string.
    * Does not change the case of other characters.
    *
    * <pre><code>
    * >>> Strings.toLowerCaseFirstChar(null)  == null
    * >>> Strings.toLowerCaseFirstChar(""  )  == ""
    * >>> Strings.toLowerCaseFirstChar("0")   == "0"
    * >>> Strings.toLowerCaseFirstChar("DoG") == "doG"
    * >>> Strings.toLowerCaseFirstChar("doG") == "doG"
    * >>> Strings.toLowerCaseFirstChar("Кот") == "кот"
    * </code></pre>
    */
   public static function toLowerCaseFirstChar(str:String):String {
      if (str.isEmpty())
         return str;

      final firstChar = str._charCodeAt8Unsafe(0).toLowerCase();

      if (str.length == 1)
         return firstChar;

      return firstChar + str.substr8(1);
   }


   /**
    * Naming convention for variables in e.g. Java.
    *
    * First character lower case, e.g., "stringBuilder".
    *
    * <b>NOTE:</b> Non-ASCII characters are NOT preserved!
    *
    * <pre><code>
    * >>> Strings.toLowerCamel(null)                 == null
    * >>> Strings.toLowerCamel("")                   == ""
    * >>> Strings.toLowerCamel("dog-cat")            == "dogCat"
    * >>> Strings.toLowerCamel("dog_cat")            == "dogCat"
    * >>> Strings.toLowerCamel("dog cat")            == "dogCat"
    * >>> Strings.toLowerCamel("1dog2cat3")          == "1Dog2Cat3"
    * >>> Strings.toLowerCamel("AnXMLParser")        == "anXMLParser"
    * >>> Strings.toLowerCamel("AnXMLParser", false) == "anXmlParser"
    * >>> Strings.toLowerCamel("はいはい")             == ""
    * </code></pre>
    */
   public static function toLowerCamel(str:String, keepUppercasedWords = true) {
      if (str.isEmpty())
         return str;

      final sb = new StringBuilder();
      if (keepUppercasedWords)
         for (word in _splitAsciiWordsUnsafe(str))
            sb.add(word.toUpperCaseFirstChar());
      else
         for (word in _splitAsciiWordsUnsafe(str))
            sb.add(word.toLowerCase8().toUpperCaseFirstChar());
      return sb.toString().toLowerCaseFirstChar();
   }


   /**
    * Naming convention for e.g. XML tags.
    *
    * Lower case words separated by hyphen, e.g. "string-builder".
    *
    * <b>NOTE:</b> Non-ASCII characters are NOT preserved!
    *
    * <pre><code>
    * >>> Strings.toLowerHyphen(null)          == null
    * >>> Strings.toLowerHyphen("")            == ""
    * >>> Strings.toLowerHyphen("dog-cat")     == "dog-cat"
    * >>> Strings.toLowerHyphen("Dog_cat")     == "dog-cat"
    * >>> Strings.toLowerHyphen("Dog Cat")     == "dog-cat"
    * >>> Strings.toLowerHyphen("1Dog2Cat3")   == "1-dog-2-cat-3"
    * >>> Strings.toLowerHyphen("AnXMLParser") == "an-xml-parser"
    * >>> Strings.toLowerHyphen("はいはい")      == ""
    * </code></pre>
    */
   public static function toLowerHyphen(str:String) {
      if (str.isEmpty())
         return str;

      return _splitAsciiWordsUnsafe(str).map((s) -> s.toLowerCase8()).join("-");
   }


   /**
    * Naming convention for variables in e.g. C/C++.
    *
    * Lower case words separated by underscore, e.g. "string_builder".
    *
    * <b>NOTE:</b> Non-ASCII characters are NOT preserved!
    *
    * <pre><code>
    * >>> Strings.toLowerUnderscore(null)          == null
    * >>> Strings.toLowerUnderscore("")            == ""
    * >>> Strings.toLowerUnderscore("dog-cat")     == "dog_cat"
    * >>> Strings.toLowerUnderscore("Dog_cat")     == "dog_cat"
    * >>> Strings.toLowerUnderscore("Dog Cat")     == "dog_cat"
    * >>> Strings.toLowerUnderscore("1Dog2Cat3")   == "1_dog_2_cat_3"
    * >>> Strings.toLowerUnderscore("AnXMLParser") == "an_xml_parser"
    * >>> Strings.toLowerUnderscore("はいはい")      == ""
    * </code></pre>
    */
   public static function toLowerUnderscore(str:String) {
      if (str.isEmpty())
         return str;

      return _splitAsciiWordsUnsafe(str).map((s) -> s.toLowerCase8()).join("_");
   }

   /**
    * Decamels (=first-char uppercase words separated by space) the given input string.
    *
    * <b>NOTE:</b> Non-ASCII characters are NOT preserved!
    *
    * <pre><code>
    * >>> Strings.toTitle(null)                 == null
    * >>> Strings.toTitle("")                   == ""
    * >>> Strings.toTitle("dog-cat")            == "Dog Cat"
    * >>> Strings.toTitle("dog_Cat")            == "Dog Cat"
    * >>> Strings.toTitle("Dog cat")            == "Dog Cat"
    * >>> Strings.toTitle("1Dog2Cat3")          == "1 Dog 2 Cat 3"
    * >>> Strings.toTitle("anXMLParser")        == "An XML Parser"
    * >>> Strings.toTitle("anXMLParser", false) == "An Xml Parser"
    * >>> Strings.toTitle("はいはい")             == ""
    * </code></pre>
    */
   public static function toTitle(str:String, keepUppercasedWords = true) {
      if (str.isEmpty())
         return str;

      if(keepUppercasedWords)
         return _splitAsciiWordsUnsafe(str)
            .map((s) -> s.toUpperCase8() == s ? s : s.toLowerCase8().toUpperCaseFirstChar())
            .join(" ");

      return _splitAsciiWordsUnsafe(str)
         .map((s) -> s.toLowerCase8().toUpperCaseFirstChar())
         .join(" ");
   }


   /**
    * Naming convention for types in e.g. Java.
    *
    * First character upper case, e.g., "StringBuilder".
    *
    * <pre><code>
    * >>> Strings.toUpperCamel(null)                 == null
    * >>> Strings.toUpperCamel("")                   == ""
    * >>> Strings.toUpperCamel("dog-cat")            == "DogCat"
    * >>> Strings.toUpperCamel("dog_cat")            == "DogCat"
    * >>> Strings.toUpperCamel("dog cat")            == "DogCat"
    * >>> Strings.toUpperCamel("anXMLParser")        == "AnXMLParser"
    * >>> Strings.toUpperCamel("anXMLParser", false) == "AnXmlParser"
    * </code></pre>
    */
   public static function toUpperCamel(str:String, keepUppercasedWords = true) {
      if (str.isEmpty())
         return str;

      final sb = new StringBuilder();
      if (keepUppercasedWords)
         for (word in _splitAsciiWordsUnsafe(str))
            sb.add(word.toUpperCaseFirstChar());
      else
         for (word in _splitAsciiWordsUnsafe(str))
            sb.add(word.toLowerCase8().toUpperCaseFirstChar());
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
    * >>> Strings.toUpperUnderscore("anXMLParser") == "AN_XML_PARSER"
    * </code></pre>
    */
   public static function toUpperUnderscore(str:String) {
      if (str.isEmpty())
          return str;

      return _splitAsciiWordsUnsafe(str).map((s) -> s.toUpperCase8()).join("_");
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
   public static function toString(str:AnyAsString):String
      return str == null ? "null" : str;


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
    * >>> Strings.toUpperCase8("фыа") == "ФЫА"
    * >>> Strings.toUpperCase8("йцу") == "ЙЦУ"
    * >>> Strings.toUpperCase8("はい") == "はい"
    * </code></pre>
    */
   public static function toUpperCase8(str:String):String {
      if (str.isEmpty())
         return str;

      #if php
         return php.Syntax.code("mb_strtoupper({0}, {1})", str, "UTF-8");
      #elseif (java || flash || cs || python)
         return str.toUpperCase();
      #else
         final sb = new StringBuilder();
         for (i in 0...str.length8())
             sb.addChar(str._charCodeAt8Unsafe(i).toUpperCase());
         return sb.toString();
      #end
   }


   /**
    * Uppercase the first character of the given string.
    * Does not change the case of other characters.
    *
    * <pre><code>
    * >>> Strings.toUpperCaseFirstChar(null)  == null
    * >>> Strings.toUpperCaseFirstChar(""  )  == ""
    * >>> Strings.toUpperCaseFirstChar("0")   == "0"
    * >>> Strings.toUpperCaseFirstChar("doG") == "DoG"
    * >>> Strings.toUpperCaseFirstChar("DoG") == "DoG"
    * >>> Strings.toUpperCaseFirstChar("кот") == "Кот"
    * </code></pre>
    *
    */
   public static function toUpperCaseFirstChar(str:String):String {
      if (str.isEmpty())
         return str;

      final firstChar = str._charCodeAt8Unsafe(0).toUpperCase();

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
    * >>> Strings.trim("  000123000  ", "0 ") == "123"
    * </code></pre>
    *
    * @param charsToRemove if specified, these characters are removed instead of the default whitespace characters
    */
   public static function trim(str:String, ?charsToRemove:Either2<String, Array<Char>>):String {
      if (str.isEmpty())
         return str;

      if(charsToRemove == null)
         return StringTools.trim(str);

      final removableChars:Array<Char> = switch (charsToRemove.value) {
         case a(str): str.toChars();
         case b(chars): chars;
      }

      return trimLeft(trimRight(str, removableChars), removableChars);
   }


   /**
    * Removes trailing whitespace characters.
    *
    * <pre><code>
    * >>> Strings.trimRight(null)      == null
    * >>> Strings.trimRight("")        == ""
    * >>> Strings.trimRight("   ")     == ""
    * >>> Strings.trimRight("\n\t\r")  == ""
    * >>> Strings.trimRight("  abc  ") == "  abc"
    * >>> Strings.trimRight("  はい  ") == "  はい"
    * >>> Strings.trimRight("  000123000  ", "0 ") == "  000123"
    * >>> Strings.trimRight("1", "0 ")             == "1"
    * >>> Strings.trimRight("0 ", "0 ")            == ""
    * </code></pre>
    *
    * @param charsToRemove if specified, these characters are removed instead of the default whitespace characters
    */
   public static function trimRight(str:String, ?charsToRemove:Either2<String, Array<Char>>):String {
      if (str.isEmpty())
         return str;

      if (charsToRemove == null)
         return StringTools.rtrim(str);

      final removableChars:Array<Char> = switch (charsToRemove.value) {
         case a(str): str.toChars();
         case b(chars): chars;
      }

      if (removableChars.length == 0)
         return str;

      final len = str.length8();
      var i = len - 1;
      while(i > -1 && removableChars.indexOf(str.charAt8(i)) > -1)
         i--;
      if (i < len - 1)
         return str.substring8(0, i + 1);
      return str;
   }


   /**
    * Removes leading whitespace characters of <b>str</b>.
    *
    * <pre><code>
    * >>> Strings.trimLeft(null)      == null
    * >>> Strings.trimLeft("")        == ""
    * >>> Strings.trimLeft("   ")     == ""
    * >>> Strings.trimLeft("\n\t\r")  == ""
    * >>> Strings.trimLeft("  abc  ") == "abc  "
    * >>> Strings.trimLeft("  はい  ") == "はい  "
    * >>> Strings.trimLeft("  000123000  ", "0 ") == "123000  "
    * >>> Strings.trimLeft("1", "0 ")             == "1"
    * >>> Strings.trimLeft("0 ", "0 ")            == ""
    * </code></pre>
    *
    * @param charsToRemove if specified, these characters are removed instead of the default whitespace characters
    */
   public static function trimLeft(str:String, ?charsToRemove:Either2<String, Array<Char>>):String {
      if (str == null)
         return str;

      if (charsToRemove == null)
         return StringTools.ltrim(str);

      final removableChars:Array<Char> = switch (charsToRemove.value) {
         case a(str): str.toChars();
         case b(chars): chars;
      }

      if (removableChars.length == 0)
         return str;

      final len = str.length8();
      var i = 0;
      while(i < len && removableChars.indexOf(str.charAt8(i)) > -1)
         i++;

      if(i > 0)
         return str.substring8(i, len);
      return str;
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
    *
    * @param charsToRemove if specified, these characters are removed instead of the default whitespace characters
    */
   public static function trimLines(str:String, ?charsToRemove:Either2<String, Array<Char>>):String {
      if (str.isEmpty())
         return str;

      return REGEX_SPLIT_LINES.split(str).map((line) -> line.trim(charsToRemove)).join(NEW_LINE_NIX);
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

      final trimmed = str.trim();

      if (trimmed.isEmpty())
         return null;

      return trimmed;
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
      final trimmed = str.trim();

      if (trimmed.isEmpty())
         return "";

      return trimmed;
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
   inline
   public static function truncate(str:String, maxLength:Int):String
      return left(str, maxLength);


   /**
    * <pre><code>
    * >>> Strings.urlDecode(null)                                == null
    * >>> Strings.urlDecode("")                                  == ""
    * >>> Strings.urlDecode("param1%3Ddog%26param2%3Ddog%20cat") == "param1=dog&param2=dog cat"
    * >>> Strings.urlDecode("%E3%81%AF%E3%81%84")                == "はい"
    * </code></pre>
    */
   public static function urlDecode(str:String):String {
      if (str.isEmpty())
         return str;

      #if php
         return php.Syntax.code("rawurldecode({0})", str);
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
    * >>> Strings.urlEncode("dog@cat.com")           == "dog%40cat.com"
    * >>> Strings.urlEncode("dog+cat")               == "dog%2Bcat"
    * </pre></code>
    */
   public static function urlEncode(str:String):String {
      if (str.isEmpty())
         return str;

      #if php
         return php.Syntax.code("rawurlencode({0})", str);
      #else
         return StringTools.urlEncode(str);
       #end
   }


   /**
    * <pre><code>
    * >>> Strings.wrap(null,      2)         == null
    * >>> Strings.wrap("",        2)         == ""
    * >>> Strings.wrap("cat",     0)         == "cat"
    * >>> Strings.wrap("cat",    -1)         == "cat"
    * >>> Strings.wrap("cat",     1)         == "c\na\nt"
    * >>> Strings.wrap("cat",     1, false)  == "cat"
    * >>> Strings.wrap("cat dog", 2)         == "ca\nt \ndo\ng"
    * >>> Strings.wrap("cat dog", 2, false)  == "cat\n dog"
    * </code></pre>
    */
   public static function wrap(str:String, maxLineLength:Int, splitLongWords:Bool = true, newLineSeparator = "\n") {
      if (str.length8() <= maxLineLength || maxLineLength < 1)
         return str;

      final sb = new StringBuilder();
      var wordChars:Array<Char> = [];
      var currLineLength = 0;
      for (ch in str.toChars()) {
         if (ch.isWhitespace()) {
            if (wordChars.length > 0) {
               for (wordCh in wordChars) {
                  if (currLineLength == maxLineLength && splitLongWords) {
                     sb.add(newLineSeparator);
                     currLineLength = 0;
                  }
                  currLineLength++;
                  sb.addChar(wordCh);
               }
               wordChars = [];
            }
            if (currLineLength >= maxLineLength) {
               sb.add(newLineSeparator);
               currLineLength = 0;
            }
            sb.addChar(ch);
            currLineLength++;
         } else
             wordChars.push(ch);
      }
      if (wordChars.length > 0) {
         for (wordCh in wordChars) {
            if (currLineLength == maxLineLength && splitLongWords) {
               sb.add(newLineSeparator);
               currLineLength = 0;
            }
            currLineLength++;
            sb.addChar(wordCh);
         }
      }
      return sb.toString();
   }
}


/**
 * Represents a character position (not byte index) in a String.
 *
 * First character is at index 0.
 */
typedef CharIndex = Int;


/**
 * Represents a character position in a sequence including its line/column coordinates.
 */
class CharPos {

   inline
   public function new(index:CharIndex, line:Int, col:Int) {
      this.index = index;
      this.line = line;
      this.col = col;
   }

   /**
    * Character index in the character sequence.
    * <br>
    * First character is at position 0.
    */
   public var index(default, null):CharIndex;

   /**
    * Line number of the character in the sequence.
    * <br>
    * First line is 1.
    */
   public var line(default, null):Int;

   /**
    * Column number of the character in the sequence.
    * <br>
    * First column is 1.
    */
   public var col(default, null):Int;

   public function toString():String
      return 'CharPos[index=$index, line=$line, col=$col]';
}


/**
 * Return value of hx.strings.Strings#diff(String, String)
 */
class StringDiff {

   inline
   public function new() {
   }

   /**
    * index where the strings start to differ
    */
   public var at:CharIndex;

   /**
    * diff of the left string
    */
   public var left:String;

   /**
    * diff of the right string
    */
   public var right:String;

   public function toString():String
      return 'StringDiff[at=$at, left=$left, right=$right]';
}


/**
 * Specifies the default value to be used if a given substring was not found in a string operation
 */
@:enum
abstract StringNotFoundDefault(Int) {

   /**
    * <code>null</code> shall be returned.
    */
   final NULL = 1;

   /**
    * An empty string shall be returned.
    */
   final EMPTY = 2;

   /**
    * The given input string shall be returned.
    */
   final INPUT = 3;
}


/**
 * https://defuse.ca/checksums.htm
 *
 * http://www.partow.net/programming/hashfunctions/
 * http://programmers.stackexchange.com/questions/49550/which-hashing-algorithm-is-best-for-uniqueness-and-speed
 * https://github.com/rurban/smhasher
 */
enum HashCodeAlgorithm {

   PLATFORM_SPECIFIC;

   ADLER32;

   /**
    * http://stackoverflow.com/questions/10953958/can-crc32-be-used-as-a-hash-function
    */
   CRC32B;

   /**
    * http://www.cse.yorku.ca/~oz/hash.html
    */
   DJB2A;

   /**
    * Java String#hashCode()
    */
   JAVA;

   /**
    * http://www.cse.yorku.ca/~oz/hash.html
    */
   SDBM;
}


enum AnsiToHtmlRenderMethod {
   StyleAttributes;
   CssClasses;
   CssClassesCallback(func:AnsiState->String);
}


@:noDoc @:dox(hide)
class AnsiState {
   public var bgcolor:String;
   public var blink:Bool;
   public var bold:Bool;
   public var fgcolor:String;
   public var underline:Bool;


   inline
   public function new(?copyFrom:AnsiState) {
      if (copyFrom == null)
         reset();
      else
         this.copyFrom(copyFrom);
   }

   inline
   public function isActive():Bool
      return fgcolor != null || bgcolor != null || bold || underline || blink;


   public function reset():Void {
      fgcolor = null;
      bgcolor = null;
      bold = false;
      underline = false;
      blink = false;
   }


   public function copyFrom(other:AnsiState) {
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


   public function toCSS(renderMethod:AnsiToHtmlRenderMethod):String {
      if (isActive()) {
         final sb = new StringBuilder();
         if (renderMethod == null) renderMethod = AnsiToHtmlRenderMethod.StyleAttributes;
         switch (renderMethod) {
            case StyleAttributes:
               if (fgcolor != null)
                  sb.add("color:").add(fgcolor).add(";");
               if (bgcolor != null)
                  sb.add("background-color:").add(bgcolor).add(";");
               if (bold)
                  sb.add("font-weight:bold;");
               if (underline)
                  sb.add("text-decoration:underline;");
               if (blink)
                  sb.add("text-decoration:blink;");

            case CssClasses:
               sb.add(AnsiState.defaultCssClassesCallback(this));

            case CssClassesCallback(func):
               sb.add(func(this));
         }
         return sb.toString();
      }
      return "";
   }


   /**
    * This is the default implementation and an example of a custom callback to transform ANSI states to CSS classes.
    *
    * In the HEAD section of your HTML file, appropriate definitions of the CSS classes are required, e.g.:
    * <code>
    *   <style>
    *     .ansi_bold      { font-weight: bold; }
    *     .ansi_underline { text-decoration: underline; }
    *     .ansi_blink     { text-decoration: blink; }
    *     .ansi_fg_red    { color: red; }
    *     .ansi_bg_red    { background-color: red; }
    *     .ansi_fg_blue   { color: blue; }
    *     .ansi_bg_blue   { background-color: blue; }
    *     // .. and so on
    *   </style>
    * </code>
    */
   public static function defaultCssClassesCallback(state:AnsiState):String {
      final classes:Array<String> = [];
      if (state.fgcolor != null) classes.push("ansi_fg_" + state.fgcolor); // e.g. "ansi_fg_red"
      if (state.bgcolor != null) classes.push("ansi_bg_" + state.bgcolor); // e.g. "ansi_bg_red"
      if (state.bold)            classes.push("ansi_bold");
      if (state.underline)       classes.push("ansi_underline");
      if (state.blink)           classes.push("ansi_blink");
      return classes.join(" "); // return "class1 class2 class3"
   }
}
