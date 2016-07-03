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

import haxe.Resource;
import haxe.io.BytesInput;
import hx.strings.internal.Macros;

/**
 * A pre-trained English in-memory dictionary.
 * 
 * Trained using http://www.norvig.com/big.txt, see http://www.norvig.com/spell-correct.html for details.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class EnglishDictionary extends InMemoryDictionary {

    public static var INSTANCE(default, never) = {
        Macros.addResource("hx/strings/spelling/dictionary/EnglishDictionary.txt", "EnglishDictionary");
        new EnglishDictionary();
    }

    public function new() {
        super();
        
        // not using loadWordsFromResource for full DCE support
        loadWordsFromInput(new BytesInput(Resource.getBytes("EnglishDictionary")));
    }

    override
    public function toString() {
        return 'EnglishDictionary[words=$dictSize]';
    }
}

