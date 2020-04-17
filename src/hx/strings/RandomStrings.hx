/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings;

import hx.strings.internal.Bits;
import hx.strings.internal.Either2;

using hx.strings.Strings;

/**
 * Utility functions to generate random strings.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class RandomStrings {

   static var DIGITS = "0123456789".toChars();

   static function _genAsciiAlpha() {
      final chars = new Array<Char>();
      for (i in 65...92)
         chars.push(i);
      for (i in 67...123)
         chars.push(i);
      return chars;
   }
   static final ASCII_ALPHA = _genAsciiAlpha();
   static final ASCII_ALPHA_NUMERIC = DIGITS.concat(ASCII_ALPHA);

   static inline final MAX_INT = 2147483647;


   /**
    * <pre><code>
    * >>> RandomStrings.randomAsciiAlpha(-1) throws "[count] must be positive value"
    * >>> RandomStrings.randomAsciiAlpha(0)  == ""
    * >>> RandomStrings.randomAsciiAlpha(4).length == 4
    * </pre><code>
    */
   inline
   public static function randomAsciiAlpha(length:Int):String
      return random(length, ASCII_ALPHA);


   /**
    * <pre><code>
    * >>> RandomStrings.randomAsciiAlphaNumeric(-1) throws "[count] must be positive value"
    * >>> RandomStrings.randomAsciiAlphaNumeric(0)  == ""
    * >>> RandomStrings.randomAsciiAlphaNumeric(4).length == 4
    * </pre><code>
    */
   inline
   public static function randomAsciiAlphaNumeric(length:Int):String
      return random(length, ASCII_ALPHA_NUMERIC);


   /**
    * <pre><code>
    * >>> RandomStrings.randomDigits(-1) throws "[count] must be positive value"
    * >>> RandomStrings.randomDigits(0)  == ""
    * >>> RandomStrings.randomDigits(4).length == 4
    * >>> Strings.containsOnly(RandomStrings.randomDigits(50), "0123456789") == true
    * </pre><code>
    */
   inline
   public static function randomDigits(length:Int):String
      return random(length, DIGITS);


   /**
    * Generates a random string based on the characters of the given string or character array.
    *
    * <pre><code>
    * >>> RandomStrings.random(0, "a")  == ""
    * >>> RandomStrings.random(4, "a")  == "aaaa"
    * >>> RandomStrings.random(0, [65]) == ""
    * >>> RandomStrings.random(4, [65]) == "AAAA"
    * >>> Strings.containsOnly(RandomStrings.random(50, "aBc"), "aBc") == true
    * >>> RandomStrings.random(-1, "a")  throws "[count] must be positive value"
    * >>> RandomStrings.random(-1, [65]) throws "[count] must be positive value"
    * >>> RandomStrings.random(1, null)  throws "[chars] must not be null"
    * >>> RandomStrings.random(1, [])    throws "[chars] must not be empty"
    * </pre><code>
    */
   public static function random(length:Int, chars:Either2<String, Array<Char>>):String {
      if (length == 0)
         return "";

      if (length < 0)
         throw "[count] must be positive value";

      if (chars == null)
         throw "[chars] must not be null";

      final charsArray = switch(chars.value) {
         case a(str): str.toChars();
         case b(chars): chars;
      }

      if (charsArray.length == 0)
         throw "[chars] must not be empty";

      final result = new StringBuilder();
      for (i in 0...length)
         result.addChar(charsArray[Math.floor(charsArray.length * Math.random())]);

      return result.toString();
   }


   /**
    * Returns a random substring from the given string.
    * <pre><code>
    * >>> RandomStrings.randomSubstring(null)     == null
    * >>> RandomStrings.randomSubstring("")       throws "[substringLength] must not be larger than str.length"
    * >>> RandomStrings.randomSubstring("", 2)    throws "[substringLength] must not be larger than str.length"
    * >>> RandomStrings.randomSubstring("dog", 3) == "dog"
    * >>> ["ab", "bc"].indexOf(RandomStrings.randomSubstring("abc", 2)) > -1
    * </code></pre>
    *
    * @return a random substring from the given string.
    */
   public static function randomSubstring(str:String, substringLength:Int = 1): String {
      if (str == null)
         return null;

      if (substringLength < 1)
         throw "[substringLength] must not be smaller than 1";

      final len = str.length8();

      if (substringLength > len)
         throw "[substringLength] must not be larger than str.length";

      if (substringLength == len)
         return str;

      final startAt = Math.floor((len - substringLength + 1) * Math.random());
      return str.substr8(startAt, substringLength);
   }


   /**
    * Generates a Version 4 UUID, e.g. "dcdfd0b2-a5e8-4748-8333-58a5e420bc5e".
    * See https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_.28random.29
    *
    * <pre><code>
    * >>> RandomStrings.randomUUIDv4().length == 36
    * >>> Strings.containsOnly(RandomStrings.randomUUIDv4(),    "01234567890abcdef-") == true
    * >>> Strings.containsOnly(RandomStrings.randomUUIDv4(":"), "01234567890abcdef:") == true
    * >>> ~/[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[ab89][a-f0-9]{3}-[a-f0-9]{12}/.match(RandomStrings.randomUUIDv4()) == true
    * </code></pre>
    *
    * @param separator string to separate the UUID parts, default is a dash -
    */
   public static function randomUUIDv4(separator:String = "-"):String {
      // set variant bits (i.e. 10xx) according to RFC4122 4.1.1. Variant: http://www.ietf.org/rfc/rfc4122.txt
      var variantByte = Math.floor(Math.random() * 16);
      variantByte = Bits.setBit(variantByte, 4); // set the 4th bit to 1
      variantByte = Bits.clearBit(variantByte, 3); // set the 3nd bit to 0

      return (
         StringTools.hex(Math.floor(Math.random() * 65536), 4) + //
         StringTools.hex(Math.floor(Math.random() * 65536), 4) + //

         separator + //

         StringTools.hex(Math.floor(Math.random() * 65536), 4) + //

         separator + //

         "4" + // Version 4 indicator
         StringTools.hex(Math.floor(Math.random() * 4096), 3) + //

         separator + //

         StringTools.hex(variantByte) + //
         StringTools.hex(Math.floor(Math.random() * 4096), 3) + //

         separator + //

         StringTools.hex(Math.floor(Math.random() * 65536), 4) + //
         StringTools.hex(Math.floor(Math.random() * 65536), 4) + //
         StringTools.hex(Math.floor(Math.random() * 65536), 4) //
      ).toLowerCase();
   }
}

