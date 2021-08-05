/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.trainer;

import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.Resource;

import hx.strings.collection.StringMap;
import hx.strings.spelling.dictionary.TrainableDictionary;

using hx.strings.Strings;

/**
 * Partially implemented dictionary trainer class that provides shared functionality to subclasses.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:abstract
@threadSafe
class AbstractDictionaryTrainer implements DictionaryTrainer {

   var vocabular:StringMap<Bool>;

   #if sys
   public function trainWithFile(dictionary:TrainableDictionary, filePath:String, ignoreUnknownWords:Bool = false):Int {
      trace('[INFO] Training with file [$filePath]...');
      return trainWithInput(dictionary, sys.io.File.read(filePath), ignoreUnknownWords);
   }
   #end

   public function trainWithInput(dictionary:TrainableDictionary, input:Input, ignoreUnknownWords:Bool = false, autoClose:Bool = true):Int {
      var lineNo = 0;
      var line = "";
      var count = 0;
      try {
         while (true) {
            lineNo++;
            line = input.readLine();
            count += trainWithString(dictionary, line, ignoreUnknownWords);
         }
      } catch(ex:haxe.io.Eof) {
         // expected --> https://github.com/HaxeFoundation/haxe/issues/5418
         if(autoClose) input.close();
      } catch (e:Dynamic) {
         final ex = Exception.capture(e);
         trace('[ERROR] Exception while reading line #$lineNo. Previous line content was [$line].');
         if (autoClose) input.close();
         ex.rethrow();
      }
      return count;
   }

   public function trainWithResource(dictionary:TrainableDictionary, resourceName:String, ignoreUnknownWords:Bool = false):Int {
      trace('[INFO] Training with resource [$resourceName]...');
      return trainWithInput(dictionary, new BytesInput(Resource.getBytes(resourceName)), ignoreUnknownWords);
   }

   public function trainWithString(dictionary:TrainableDictionary, content:String, ignoreUnknownWords:Bool = false):Int
      throw "Not implemented";
}
