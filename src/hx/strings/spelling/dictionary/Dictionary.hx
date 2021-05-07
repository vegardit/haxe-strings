/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.dictionary;

/**
 * Dictionary holding words and their popularity/frequency.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface Dictionary {

   /**
    * @return true if the given word exists
    */
   function exists(word:String):Bool;

   /**
    * @return the popularity score of the given word or 0 if the word does not exist in the dictionary
    */
   function popularity(word:String):Int;

   /**
    * @return number of words know to this dictionary
    */
   function size():Int;

   /**
    * @return an iterator over all words known by the dictionary, no particular order is guranteed
    */
   function words():Iterator<String>;
}
