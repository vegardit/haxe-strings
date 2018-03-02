/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.checker;

import hx.strings.spelling.dictionary.Dictionary;
import hx.strings.spelling.dictionary.EnglishDictionary;

using hx.strings.Strings;

/**
 * Spell checker implementation with English language specific parsing behaviour.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class EnglishSpellChecker extends AbstractSpellChecker{

    /**
     * default instance that uses the pre-trained hx.strings.spelling.dictionary.EnglishDictionary
     *
     * <pre><code>
     * >>> EnglishSpellChecker.INSTANCE.correctWord("speling")  == "spelling"
     * >>> EnglishSpellChecker.INSTANCE.correctWord("SPELING")  == "spelling"
     * >>> EnglishSpellChecker.INSTANCE.correctWord("SPELLING") == "spelling"
     * >>> EnglishSpellChecker.INSTANCE.correctWord("spell1ng") == "spelling"
     * >>> EnglishSpellChecker.INSTANCE.correctText("sometinG zEems realy vrong!", 3000) == "something seems really wrong!"
     * >>> EnglishSpellChecker.INSTANCE.suggestWords("absance", 3, 3000) == [ "absence", "advance", "balance" ]
     * </code></pre>
     */
    public static var INSTANCE(default, never) = new EnglishSpellChecker(EnglishDictionary.INSTANCE);

    inline
    public function new(dictionary:Dictionary) {
        super(dictionary, "abcdefghijklmnopqrstuvwxyz");
    }

    override
    public function correctText(text:String, timeoutMS:Int = 1000):String {
        var result = new StringBuilder();
        var currentWord = new StringBuilder();

        var chars = text.toChars();
        var len = chars.length;
        for (i in 0...len) {
            var ch:Char = chars[i];
            // treat a-z and 0-9 as characters of potential words to capture OCR errors like "m1nd" or "m0ther" or "1'll"
            if (ch.isAsciiAlpha() || ch.isDigit()) {
                currentWord.addChar(ch);
            } else if (currentWord.length > 0) {
                if (ch == Char.SINGLE_QUOTE) {
                    var chNext:Char = i < len - 1 ? chars[i + 1] : -1;
                    var chNextNext:Char = i < len - 2 ? chars[i + 2] : -1;
                    // handle "don't" / "can't"
                    if (chNext == 116 /*t*/ && !chNextNext.isAsciiAlpha()) {
                        currentWord.addChar(ch);
                    // handle "we'll"
                    } else if (chNext == 108 /*l*/ && chNextNext == 108 /*l*/) {
                        currentWord.addChar(ch);
                    } else {
                        result.add(correctWord(currentWord.toString(), timeoutMS));
                        currentWord.clear();
                        result.addChar(ch);
                    }
                } else {
                    result.add(correctWord(currentWord.toString(), timeoutMS));
                    currentWord.clear();
                    result.addChar(ch);
                }
            } else {
                result.addChar(ch);
            }
        }

        if (currentWord.length > 0) {
            result.add(correctWord(currentWord.toString(), timeoutMS));
        }
        return result.toString();
    }

    override
    public function correctWord(word:String, timeoutMS:Int = 1000):String {
        if(dict.exists(word))
            return word;

        var wordLower = word.toLowerCase8();
        if (dict.exists(wordLower)) {
            return wordLower;
        }

        var result = super.correctWord(wordLower, timeoutMS);
        return result == wordLower ? word : result;
    }
}
