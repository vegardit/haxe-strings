/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.trainer;

import hx.strings.spelling.dictionary.TrainableDictionary;

using hx.strings.Strings;

/**
 * A dictionary trainer with German language specific parsing behaviour.
 */
@threadSafe
class GermanDictionaryTrainer extends AbstractDictionaryTrainer {

   public static var INSTANCE(default, never) = new GermanDictionaryTrainer();

   static var SPECIAL_CHARS = [ Char.of("ä"), Char.of("Ä"), Char.of("ö"), Char.of("Ö"), Char.of("ü"), Char.of("Ü"), Char.of("ß") ];

   function new() {
   }

   inline
   function isValidWordChar(ch:Char)
      return ch.isAsciiAlpha() || SPECIAL_CHARS.indexOf(ch) > -1;


   function trainWord(dictionary:TrainableDictionary, word:StringBuilder, ignoreUnknownWords:Bool):Int {
      final w = word.toString();
      if (w.length == 1 || w.startsWith("ß") || w.isUpperCase() /* ignore all uppercase words */)
         return 0;

      if (ignoreUnknownWords && !dictionary.exists(w))
         return 0;

      dictionary.train(w);
      return 1;
   }


   override
   public function trainWithString(dictionary:TrainableDictionary, content:String, ignoreUnknownWords:Bool = false):Int {
      if (dictionary == null) throw "[dictionary] must not be null!";

      final chars = content.toChars();
      final len = chars.length;
      var count = 0;
      var currentWord = new StringBuilder();
      for (i in 0...len) {
         final ch = chars[i];
         if (isValidWordChar(ch)) {
            currentWord.addChar(ch);
         } else if (currentWord.length > 0) {
            count += trainWord(dictionary, currentWord, ignoreUnknownWords);
            currentWord.clear();
         }
      }

      if (currentWord.length > 0)
         count += trainWord(dictionary, currentWord, ignoreUnknownWords);

      return count;
   }
}
