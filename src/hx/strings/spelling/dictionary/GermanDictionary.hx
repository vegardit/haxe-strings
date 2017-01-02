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

import haxe.Resource;
import haxe.io.BytesInput;
import hx.strings.internal.Macros;

/**
 * A pre-trained German in-memory dictionary.
 * 
 * Contains most common 30.000 words determined and weighted by analyzing:
 * 1) free German books (https://www.gutenberg.org/browse/languages/de), 
 * 2) German movie subtitles (http://opensubtitles.org), 
 * 3) some German newspaper articles, 
 * 4) the Top 10000 German word list of the University Leipzig (http://wortschatz.uni-leipzig.de/html/wliste.html), and
 * 5) the Free German Dictionary (https://sourceforge.net/projects/germandict/)
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class GermanDictionary extends InMemoryDictionary {
  
    public static var INSTANCE(default, never) = {
        Macros.addResource("hx/strings/spelling/dictionary/GermanDictionary.txt", "GermanDictionary");       
        new GermanDictionary();
    }
    
    public function new() {
        super();

        // not using loadWordsFromResource for full DCE support
        loadWordsFromInput(new BytesInput(Resource.getBytes("GermanDictionary")));
    }

    override
    public function toString() {
        return 'GermanDictionary[words=$dictSize]';
    }
}
