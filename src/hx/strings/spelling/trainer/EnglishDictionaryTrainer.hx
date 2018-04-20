/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.trainer;

import hx.strings.spelling.dictionary.TrainableDictionary;

using hx.strings.Strings;

/**
 * A dictionary trainer with English language specific parsing behaviour.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@threadSafe
class EnglishDictionaryTrainer extends AbstractDictionaryTrainer {

    public static var INSTANCE(default, never) = new EnglishDictionaryTrainer();

    inline
    function new() {
    }

    inline
    function isValidWordChar(ch:Char):Bool {
        return ch.isAsciiAlpha();
    }

    function trainWord(dictionary:TrainableDictionary, word:StringBuilder, ignoreUnknownWords:Bool):Int {
        var w = word.toString();
        if (w == "I" || w == "O") { // only accept single char uppercase words 'I' and 'O'
            if (ignoreUnknownWords && !dictionary.exists(w))
                return 0;

            dictionary.train(w);
            return 1;
        }
        w = w.toLowerCase8();

        if (w.length == 1 && w != "a") { // only accept single char lowercase word 'a'
            // ignore
            return 0;
        }
        if (ignoreUnknownWords && !dictionary.exists(w))
            return 0;

        dictionary.train(w);
        return 1;
    }

    override
    public function trainWithString(dictionary:TrainableDictionary, content:String, ignoreUnknownWords:Bool = false):Int {
        if (dictionary == null) throw "[dictionary] must not be null!";

        var count = 0;
        var currentWord = new StringBuilder();
        var chars = content.toChars();
        var len = chars.length;
        for (i in 0...len) {
            var ch = chars[i];
            if (isValidWordChar(ch)) {
                currentWord.addChar(ch);
            } else if (currentWord.length > 0) {
                if (ch == Char.SINGLE_QUOTE) {
                    var chNext:Char = i < len - 1  ? chars[i + 1] : -1;
                    var chNextNext:Char = i < len - 2 ? chars[i + 2] : -1;
                    // handle "don't" / "can't"
                    if (chNext == 116 /*t*/ && !isValidWordChar(chNextNext)) {
                        currentWord.addChar(ch);
                    // handle "we'll"
                    } else if (chNext == 108 /*l*/ && chNextNext == 108 /*l*/) {
                        currentWord.addChar(ch);
                    } else {
                        count += trainWord(dictionary, currentWord, ignoreUnknownWords);
                        currentWord.clear();
                    }
                } else {
                    count += trainWord(dictionary, currentWord, ignoreUnknownWords);
                    currentWord.clear();
                }
            }
        }

        if (currentWord.length > 0) {
            count += trainWord(dictionary, currentWord, ignoreUnknownWords);
        }
        return count;
    }
}
