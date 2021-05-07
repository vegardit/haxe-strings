/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.checker;

/**
 * Word frequency/popularity based spell checker inspired by Peter Norvig's article
 * "How to Write a Spelling Corrector" http://www.norvig.com/spell-correct.html
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface SpellChecker {

   /**
    * @param timeoutMS approximate maximum time in milliseconds per word the spell checker can try to find the best correction
    *
    * @return the text with each word replaced by it's best known correction
    */
   function correctText(text:String, timeoutMS:Int = 1000):String;

   /**
    * @param timeoutMS approximate maximum time in milliseconds the spell checker can try to find the best correction
    *
    * @return the best known correction for the given word or the word itself if no correction is available
    */
   function correctWord(word:String, timeoutMS:Int = 1000):String;

   /**
    * @param max maximum number of suggestions to return, may be less
    * @param timeoutMS approximate maximum time in milliseconds the spell checker can try to find the best corrections
    *
    * @return an array of the best known corrections for the given word ordered by popularity. the array may be empty in case no corrections are available
    */
   function suggestWords(word:String, max:Int = 3, timeoutMS:Int = 1000):Array<String>;
}
