/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
