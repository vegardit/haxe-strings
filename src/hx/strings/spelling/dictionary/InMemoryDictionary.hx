/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.dictionary;

import haxe.Resource;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.io.Output;
import hx.strings.internal.Exception;

import hx.strings.collection.StringMap;

using hx.strings.Strings;

/**
 * Hash map based dictionary.
 */
class InMemoryDictionary implements TrainableDictionary {

   /**
    * key = word, value = popularity score
    */
   final dict = new StringMap<Int>();
   var dictSize = 0;


   inline
   public function new() {
   }


   public function clear():Void {
      dict.clear();
      dictSize = 0;
   }


   inline
   public function exists(word:String):Bool
      return dict.exists(word);


   public function popularity(word:String):Int {
      final p = dict.get(word);
      return p == null ? 0 : p;
   }


   public function train(word:String):Int {
      final p = popularity(word) + 1;
      dict.set(word, p);
      if (p == 1)
         dictSize++;
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
   public function size():Int
      return dictSize;


   public function trimTo(n:Int):Int {
      if (dictSize <= n)
         return 0;

      final arr = [for (word => popularity in dict) {word:word, popularity:popularity}];
      arr.sort((a, b) -> a.popularity > b.popularity ? -1 : a.popularity == b.popularity ? 0 : 1);

      #if python @:nullSafety(Off) #end // TODO
      final removables = arr.slice(n);

      for (r in removables)
         remove(r.word);
      return removables.length;
   }


   /**
    * Exports all words and their popularity to the given output stream
    */
   public function exportWordsToOutput(out:Output, autoClose:Bool=true):Void {
      final words = [for (word in dict.keys()) word];
      words.sort(Strings.compare);

      for (word in words)
         out.writeString('$word:${dict[word]}\n');

      if(autoClose)
         out.close();
   }


   #if sys
   /**
    * Exports all words and their popularity to the given file
    */
   public function exportWordsToFile(filePath:String):Void {
      trace('[INFO] Exporting words to file [$filePath]...');
      exportWordsToOutput(sys.io.File.write(filePath));
   }


   /**
    * Loads all words and their popularity from the given file
    *
    * @return number of loaded entries
    */
   public function loadWordsFromFile(filePath:String):Int {
      trace('[INFO] Loading words from file [$filePath]...');
      return loadWordsFromInput(sys.io.File.read(filePath));
   }
   #end


   /**
    * Loads all words and their popularity from the given Haxe resource
    *
    * @return number of loaded entries
    */
   public function loadWordsFromResource(resourceName:String):Int {
      trace('[INFO] Loading words from resource [$resourceName]...');
      final bytes = Resource.getBytes(resourceName);
      if (bytes == null)
         throw 'Resource [$resourceName] not found!';
      return loadWordsFromInput(new BytesInput(bytes));
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
            final tuple = line.split8(":", 2);
            if (tuple.length < 2) {
               trace('[WARN] Skipping line #$lineNo which misses the colon (:) separator');
               continue;
            }
            final word = tuple[0];
            final popularity = tuple[1].toInt(0);
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
      } catch (e:Dynamic) {
         final ex = Exception.capture(e);
         trace('[ERROR] Exception while reading line #$lineNo. Previous line content was [$line].');
         if (autoClose) input.close();
         ex.rethrow();
      }
      if (autoClose) input.close();
      return count;
   }


   public function toString()
      return 'InMemoryDictionary[words=$dictSize]';


   inline
   public function words():Iterator<String>
      return dict.keys();
}
