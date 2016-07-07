/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
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
 * Dictionary holding words and their popularity/frequency.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface Dictionary {
    
    /**
     * @return true if the given word exists
     */
    public function exists(word:String):Bool;

    /**
     * @return the popularity score of the given word or 0 if the word does not exist in the dictionary
     */
    public function popularity(word:String):Int;
    
    /**
     * @return number of words know to this dictionary
     */
    public function size():Int;
    
    /**
     * @return an iterator over all words known by the dictionary, no particular order is guranteed
     */
    public function words():Iterator<String>;
}
