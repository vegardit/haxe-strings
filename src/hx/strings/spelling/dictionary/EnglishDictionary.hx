/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.dictionary;

import hx.strings.internal.Macros;

/**
 * A pre-trained English in-memory dictionary.
 *
 * Trained using http://www.norvig.com/big.txt, see http://www.norvig.com/spell-correct.html for details.
 */
class EnglishDictionary extends InMemoryDictionary {

   public static final INSTANCE = new EnglishDictionary();


   public function new() {
      super();

      Macros.addResource("hx/strings/spelling/dictionary/EnglishDictionary.txt", "EnglishDictionary");

      // workaround to prevent strange error: AttributeError: type object 'python_Lib' has no attribute 'lineEnd'
      #if python python.Lib; #end

      // not using loadWordsFromResource for full DCE support
      trace('[INFO] Loading words from embedded [EnglishDictionary]...');
      loadWordsFromResource("EnglishDictionary");
   }


   override
   public function toString()
      return 'EnglishDictionary[words=$dictSize]';
}
