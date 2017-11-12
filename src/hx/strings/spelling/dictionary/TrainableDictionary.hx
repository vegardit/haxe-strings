/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
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
    public function clear():Void;

    /**
     * removes the given word from the dictionary
     *
     * @return true if the word was removed, false if the word didn't exist
     */
    public function remove(word:String):Bool;

    /**
     * adds the word to the dictionary or if it exists already increases it's popularity score
     *
     * @return the new popularity score
     */
    public function train(word:String):Int;

    /**
     * Only leaves the n-most popular words in the dictionary
     *
     * @return number of removed words
     */
    public function trimTo(n:Int):Int;
}
