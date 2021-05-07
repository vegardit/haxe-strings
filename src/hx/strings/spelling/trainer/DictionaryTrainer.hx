/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.trainer;

import hx.strings.spelling.dictionary.TrainableDictionary;

/**
 * A dictionary trainer can train/populate a dictionary by analyzing provided reference texts.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface DictionaryTrainer {

    #if sys
    /**
     * Populates the <b>dictionary</b> with words found in the given UTF-8 encoded file.
     *
     * @param ignoreUnknownWords if set to true only words already present in the dictionary are trained
     *
     * @return count of words found in the file
     */
    function trainWithFile(dictionary:TrainableDictionary, filePath:String, ignoreUnknownWords:Bool = false):Int;
    #end

    /**
     * Populates the <b>dictionary</b> with words found in the given UTF-8 encoded Haxe input stream.
     *
     * @param ignoreUnknownWords if set to true only words already present in the dictionary are trained
     *
     * @return count of words found in the resource
     */
    function trainWithInput(dictionary:TrainableDictionary, input:haxe.io.Input, ignoreUnknownWords:Bool = false, autoClose:Bool = true):Int;

    /**
     * Populates the <b>dictionary</b> with words found in the given UTF-8 encoded Haxe resource.
     *
     * @param ignoreUnknownWords if set to true only words already present in the dictionary are trained
     *
     * @return count of words found in the resource
     */
    function trainWithResource(dictionary:TrainableDictionary, resourceName:String, ignoreUnknownWords:Bool = false):Int;

    /**
     * Populates the <b>dictionary</b> with words found in the given UTF-8 encoded content
     *
     * @param ignoreUnknownWords if set to true only words already present in the dictionary are trained
     *
     * @return count of words found in the string
     */
    function trainWithString(dictionary:TrainableDictionary, content:String, ignoreUnknownWords:Bool = false):Int;
}
