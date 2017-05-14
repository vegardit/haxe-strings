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
import haxe.io.Input;
import haxe.io.Output;

import hx.strings.collection.StringMap;

using hx.strings.Strings;

/**
 * Hash map based dictionary.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class InMemoryDictionary implements TrainableDictionary {

    /**
     * key = word, value = popularity score
     */
    var dict:StringMap<Int>;
    var dictSize:Int;

    inline
    public function new() {
        clear();
    }

    public function clear():Void {
        dict = new StringMap<Int>();
        dictSize = 0;
    }

    inline
    public function exists(word:String):Bool {
        return dict.exists(word);
    }

    public function popularity(word:String):Int {
        var p = dict.get(word);
        return p == null ? 0 : p;
    }

    public function train(word:String):Int {
        var p = popularity(word) + 1;
        dict.set(word, p);
        if (p == 1) dictSize++;
        return p;
    }

    public function remove(word:String):Bool {
        if (dict.remove(word)) {
            dictSize--;
            return true;
        }
        return false;
    }

    inline
    public function size():Int {
        return dictSize;
    }

    public function trimTo(n:Int):Int {
        if (dictSize <= n)
            return 0;

        var arr = [ for (word in dict.keys()) { word:word, popularity:dict.get(word) } ];
        arr.sort(function(a, b) return a.popularity > b.popularity ? -1 : a.popularity == b.popularity ? 0 : 1);
        var removables = arr.slice(n);
        for (r in removables)
            remove(r.word);
        return removables.length;
    }

    /**
     * Exports all words and their popularity to the given output stream
     */
    public function exportWordsToOutput(out:Output, autoClose:Bool=true):Void {
        var words = [ for (word in dict.keys()) word ];
        words.sort(Strings.compare);
        for (word in words) {
            out.writeString('$word:${dict[word]}\n');
        }
        if(autoClose)
            out.close();
    }

    #if sys
    /**
     * Exports all words and their popularity to the given file
     */
    inline
    public function exportWordsToFile(filePath:String):Void {
        trace('Exporting words to file [$filePath]...');
        exportWordsToOutput(sys.io.File.write(filePath));
    }

    /**
     * Loads all words and their popularity from the given file
     *
     * @return number of loaded entries
     */
    public function loadWordsFromFile(filePath:String):Int {
        trace('Loading words from file [$filePath]...');
        return loadWordsFromInput(sys.io.File.read(filePath));
    }
    #end

    /**
     * Loads all words and their popularity from the given Haxe resource
     *
     * @return number of loaded entries
     */
    inline
    public function loadWordsFromResource(resourceName:String):Int {
        trace('Loading words from resource [$resourceName]...');
        return loadWordsFromInput(new BytesInput(Resource.getBytes(resourceName)));
    }

    /**
     * Loads all words and their popularity from the given input stream
     *
     * @return number of loaded entries
     */
    public function loadWordsFromInput(input:Input, autoClose:Bool=true):Int {
        var lineNo = 0;
        var line = "";
        var count = 0;
        try {
            while (true) {
                lineNo++;
                line = input.readLine();
                if (!line.contains(":")) {
                    trace('[WARN] Skipping line #$lineNo which misses the colon (:) separator');
                    continue;
                }
                var word = line.substringBeforeLast(":");
                var popularity = line.substringAfterLast(":").toInt(0);
                if (popularity < 1) {
                    trace('[WARN] Skipping line #$lineNo with popularity < 1');
                    continue;
                }
                if (!exists(word)) dictSize++;
                count++;
                dict.set(word, popularity);
            }
        } catch(ex:haxe.io.Eof) {
            // expected --> https://github.com/HaxeFoundation/haxe/issues/5418
        } catch (ex:Dynamic) {
            trace('Exception while reading line #$lineNo. Previous line content was [$line]');
            if (autoClose) input.close();
            #if neko neko.Lib.rethrow #else throw #end (ex);
        }
        if (autoClose) input.close();
        return count;
    }

    public function toString() {
        return 'InMemoryDictionary[words=$dictSize]';
    }

    inline
    public function words():Iterator<String> {
        return dict.keys();
    }
}
