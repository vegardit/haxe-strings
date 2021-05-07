/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
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

   public static final INSTANCE = new EnglishDictionary();


   public function new() {
      super();

      Macros.addResource("hx/strings/spelling/dictionary/EnglishDictionary.txt", "EnglishDictionary");

      // not using loadWordsFromResource for full DCE support
      loadWordsFromInput(new BytesInput(Resource.getBytes("EnglishDictionary")));
   }


   override
   public function toString()
      return 'EnglishDictionary[words=$dictSize]';
}
