/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.checker;

import haxe.Timer;
import hx.strings.collection.StringSet;
import hx.strings.spelling.dictionary.Dictionary;
import hx.strings.internal.Arrays;

using hx.strings.Strings;

/**
 * Partially implemented spell checker class that provides shared functionality to subclasses.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:abstract
class AbstractSpellChecker implements SpellChecker {

   final alphabet:Array<Char>;
   final dict:Dictionary;


   /**
    * @param alphabet used by #generateEdits() to generate word variations
    */
   public function new(dictionary:Dictionary, alphabet:String) {
      if (dictionary == null) throw "[dictionary] must not be null!";
      if (alphabet == null) throw "[alphabet] must not be null!";
      this.dict = dictionary;
      this.alphabet = Arrays.unique(alphabet.toChars());
   }


   public function correctText(text:String, timeoutMS:Int = 500):String
      throw "Not implemented";


   public function correctWord(word:String, timeoutMS:Int = 500):String {
      final timeoutAt = haxe.Timer.stamp() + (timeoutMS / 1000);

      if(dict.exists(word))
         return word;

      var candidate:String = null;
      var candidatePopularity:Int = 0;

      var edits = generateEdits(word, timeoutAt);

      for (edit in edits) {
         var editPopularity = dict.popularity(edit);
         if (editPopularity > candidatePopularity) {
            candidate = edit;
            candidatePopularity = editPopularity;
         }
      }
      if (candidate != null)
         return candidate;

      if (timeoutAt < Timer.stamp())
         return word;

      // check for words that are 2 edits away from the given input word
      for (edit in edits) {
         if (timeoutAt < Timer.stamp()) break;

         for (edit2 in generateEdits(edit, timeoutAt)) {
            var edit2Popularity = dict.popularity(edit2);
            if (edit2Popularity > candidatePopularity) {
               candidate = edit2;
               candidatePopularity = edit2Popularity;
            }
         }
      }
      return candidate == null ? word : candidate;
   }


   /**
    * @return the a list of word variations that are 1 character edit away from the given input string
    */
   function generateEdits(word:String, timeoutAt:Float):Array<String> {
      final edits = new Array<String>();
      final wordLen = word.length8();
      for (i in 0...wordLen) {
         // generate a word variation by leaving out 1 of the word's characters
         edits.push(word.substring8(0, i) + word.substring8(i + 1));

         // generate a word variation by switching the order of two characters
         edits.push(word.substring8(0, i) + word.substring8(i + 1, i + 2) + word.substring8(i, i + 1) + word.substring8(i + 2));

         for (char in alphabet) {
            // generate a word variation by replacing one character
            edits.push(word.substring8(0, i) + char + word.substring8(i + 1));

            // generate a word variation by adding one character
            edits.push(word.substring8(0, i) + char + word.substring8(i));
         }

         if (timeoutAt < Timer.stamp()) break;
      }
      return edits;
   }


   public function suggestWords(word:String, max:Int = 3, timeoutMS:Int = 1000):Array<String> {
      final timeoutAt = haxe.Timer.stamp() + (timeoutMS / 1000);
      var candidates = new Array<{word:String, popularity:Int}>();

      final edits = generateEdits(word, timeoutAt);
      for (edit in edits) {
         final editPopularity = dict.popularity(edit);
         if (editPopularity > 0)
            candidates.push({word:edit,popularity:editPopularity});
      }

      candidates.sort(function(a, b) return a.popularity > b.popularity ? -1 : a.popularity == b.popularity ? 0 : 1);
      final result = Arrays.unique([for (candidate in candidates) candidate.word]);

      if (result.length < max) {
         candidates = new Array<{word:String, popularity:Int}>();

         // check for words that are 2 edits away from the given input word
         final edit2s = new StringSet();
         for (edit in edits) {
            for (edit2 in generateEdits(edit, timeoutAt)) {
               // short cut
               if (result.indexOf(edit2) > -1 || edit2s.contains(edit2))
                  continue;
               edit2s.add(edit2);
               final edit2Popularity = dict.popularity(edit2);
               if (edit2Popularity > 0)
                  candidates.push({word:edit2,popularity:edit2Popularity});
            }
         }
         candidates.sort(function(a, b) return a.popularity > b.popularity ? -1 : a.popularity == b.popularity ? 0 : 1);
         for (candidate in candidates) {
            if(result.length < max)
               result.push(candidate.word);
            else
               break;
         }
      }

      return Arrays.unique(result).slice(0, max);
   }
}
