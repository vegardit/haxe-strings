/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.checker;

import hx.strings.spelling.checker.AbstractSpellChecker;
import hx.strings.spelling.dictionary.Dictionary;
import hx.strings.spelling.dictionary.GermanDictionary;

using hx.strings.Strings;

/**
 * Spell checker implementation with German language specific parsing behaviour.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class GermanSpellChecker extends AbstractSpellChecker {

   /**
    * default instance that uses the pre-trained hx.strings.spelling.dictionary.GermanDictionary
    *
    * <pre><code>
    * >>> GermanSpellChecker.INSTANCE.correctWord("schreibweise")  == "Schreibweise"
    * >>> GermanSpellChecker.INSTANCE.correctWord("Schreibwiese")  == "Schreibweise"
    * >>> GermanSpellChecker.INSTANCE.correctWord("SCHREIBWEISE")  == "Schreibweise"
    * >>> GermanSpellChecker.INSTANCE.correctWord("SCHRIBWEISE")   == "Schreibweise"
    * >>> GermanSpellChecker.INSTANCE.correctWord("Schre1bweise")  == "Schreibweise"
    #if !cpp
    // TODO see https://github.com/HaxeFoundation/haxe/issues/9007
    * >>> GermanSpellChecker.INSTANCE.correctText("etwaz kohmische Aepfel ligen vör der Thür", 3000) == "etwas komische Äpfel liegen vor der Tür"
    #end
    * >>> GermanSpellChecker.INSTANCE.suggestWords("Sistem", 3, 3000) == [ "System", "Sitte", "Sitten" ]
    * </code></pre>
    */
   public static final INSTANCE = new GermanSpellChecker(GermanDictionary.INSTANCE);

   final alphabetUpper:Array<Char>;


   public function new(dictionary:Dictionary) {
      super(dictionary, "abcdefghijklmnopqrstuvwxyzäöüß");

      alphabetUpper = "ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ".toChars();
   }


   function replaceUmlaute(word:String):String {
      // replace oe with ö, ae with ä and ue with ü
      final word = word.replaceAll("oe", "ö")
         .replaceAll("ae", "ä")
         .replaceAll("ue", "ü")
         .replaceAll("OE", "Ö")
         .replaceAll("AE", "Ä")
         .replaceAll("UE", "Ü");

      if (word.startsWith("Oe"))
         return "Ö" + word.substr8(2);

      if (word.startsWith("Ae"))
         return "Ä" + word.substr8(2);

      if (word.startsWith("Ue"))
         return "Ü" + word.substr8(2);

      return word;
   }


   override
   public function correctText(text:String, timeoutMS:Int = 1000):String {
      final result = new StringBuilder();
      final currentWord = new StringBuilder();

      final chars = text.toChars();
      final len = chars.length;
      for (i in 0...len) {
         final ch:Char = chars[i];
         // treat a-z and 0-9 as characters of potential words to capture OCR errors like "me1n" or "M0ntag"
         if (ch.isAsciiAlpha() || ch.isDigit() || ch == "ä" || ch == "ö" || ch == "ü" || ch == "Ä" || ch == "Ö" || ch == "Ü" || ch == "ß") {
            currentWord.addChar(ch);
         } else if (currentWord.length > 0) {
            result.add(correctWord(currentWord.toString(), timeoutMS));
            currentWord.clear();
            result.addChar(ch);
         } else {
            result.addChar(ch);
         }
      }

      if (currentWord.length > 0)
         result.add(correctWord(currentWord.toString(), timeoutMS));

      return result.toString();
   }


   override
   public function correctWord(word:String, timeoutMS:Int = 1000):String {
      if(dict.exists(word))
         return word;

      final wordWithUmlaute = replaceUmlaute(word);
      if(dict.exists(wordWithUmlaute))
         return wordWithUmlaute;

      if (word.isUpperCase()) { // special handling for all uppercase words
         var wordLower = word.toLowerCase8();
         final wordFirstCharUpper = wordLower.toUpperCaseFirstChar();
         final pLower = dict.popularity(wordLower);
         final pCapitalized = dict.popularity(wordFirstCharUpper);
         if (pLower == 0 && pCapitalized == 0)
            return super.correctWord(wordFirstCharUpper, timeoutMS);
         return pCapitalized > pLower ? wordFirstCharUpper : wordLower;
      }

      return super.correctWord(word, timeoutMS);
   }


   override
   public function suggestWords(word:String, max:Int = 3, timeoutMS:Int = 1000):Array<String> {
      if(!dict.exists(word)) {
         final wordWithUmlaute = replaceUmlaute(word);
         if(dict.exists(wordWithUmlaute))
            return super.suggestWords(wordWithUmlaute, max, timeoutMS);
      }
      return super.suggestWords(word, max, timeoutMS);
   }


   override
   function generateEdits(word:String, timeoutAt:Float):Array<String> {
      final edits = super.generateEdits(word, timeoutAt);

      // add 1st char upper case variation
      for (upper in alphabetUpper)
         edits.push(upper + word.substr8(1));

      return edits;
   }
}
