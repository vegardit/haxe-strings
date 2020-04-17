/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.dictionary;

/**
 * A modifiable/trainable dictionary.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface TrainableDictionary extends Dictionary {

   /**
    * removes all trained words
    */
   function clear():Void;

   /**
    * removes the given word from the dictionary
    *
    * @return true if the word was removed, false if the word didn't exist
    */
   function remove(word:String):Bool;

   /**
    * adds the word to the dictionary or if it exists already increases it's popularity score
    *
    * @return the new popularity score
    */
   function train(word:String):Int;

   /**
    * Only leaves the n-most popular words in the dictionary
    *
    * @return number of removed words
    */
   function trimTo(n:Int):Int;
}
