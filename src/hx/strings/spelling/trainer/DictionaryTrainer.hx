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
package hx.strings.spelling.trainer;

import hx.strings.spelling.dictionary.TrainableDictionary;

/**
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
    public function trainWithFile(dictionary:TrainableDictionary, filePath:String, ignoreUnknownWords:Bool = false):Int;
    #end

    /**
     * Populates the <b>dictionary</b> with words found in the given UTF-8 encoded Haxe input stream.
     * 
     * @param ignoreUnknownWords if set to true only words already present in the dictionary are trained
     * 
     * @return count of words found in the resource
     */
    public function trainWithInput(dictionary:TrainableDictionary, input:haxe.io.Input, ignoreUnknownWords:Bool = false, autoClose:Bool = true):Int;
    
    /**
     * Populates the <b>dictionary</b> with words found in the given UTF-8 encoded Haxe resource.
     * 
     * @param ignoreUnknownWords if set to true only words already present in the dictionary are trained
     * 
     * @return count of words found in the resource
     */
    public function trainWithResource(dictionary:TrainableDictionary, resourceName:String, ignoreUnknownWords:Bool = false):Int;
    
    /**
     * Populates the <b>dictionary</b> with words found in the given UTF-8 encoded content
     * 
     * @param ignoreUnknownWords if set to true only words already present in the dictionary are trained
     * 
     * @return count of words found in the string
     */
    public function trainWithString(dictionary:TrainableDictionary, content:String, ignoreUnknownWords:Bool = false):Int;
}
