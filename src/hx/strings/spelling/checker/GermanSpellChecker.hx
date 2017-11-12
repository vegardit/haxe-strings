/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.spelling.checker;

import hx.strings.spelling.checker.AbstractSpellChecker;
import hx.strings.spelling.dictionary.Dictionary;
import hx.strings.spelling.dictionary.GermanDictionary;

using hx.strings.Strings;

/**
 * Spell checker implementation with German language specific parsing behaviour.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class GermanSpellChecker extends AbstractSpellChecker{

    /**
     * default instance that uses the pre-trained hx.strings.spelling.dictionary.GermanDictionary
     *
     * <pre><code>
     * >>> GermanSpellChecker.INSTANCE.correctWord("schreibweise")  == "Schreibweise"
     * >>> GermanSpellChecker.INSTANCE.correctWord("Schreibwiese")  == "Schreibweise"
     * >>> GermanSpellChecker.INSTANCE.correctWord("SCHREIBWEISE")  == "Schreibweise"
     * >>> GermanSpellChecker.INSTANCE.correctWord("SCHRIBWEISE")   == "Schreibweise"
     * >>> GermanSpellChecker.INSTANCE.correctWord("Schre1bweise")  == "Schreibweise"
     * >>> GermanSpellChecker.INSTANCE.correctText("etwaz kohmische Aepfel ligen vör der Thür", 3000) == "etwas komische Äpfel liegen vor der Tür"
     * >>> GermanSpellChecker.INSTANCE.suggestWords("Sistem", 3, 3000) == [ "System", "Sitte", "Sitten" ]
     * </code></pre>
     */
    public static var INSTANCE(default, never) = new GermanSpellChecker(GermanDictionary.INSTANCE);

    var alphabetUpper:Array<Char>;

    public function new(dictionary:Dictionary) {
        super(dictionary, "abcdefghijklmnopqrstuvwxyzäöüß");

        alphabetUpper = "ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ".toChars();
    }

    override
    public function correctText(text:String, timeoutMS:Int = 1000):String {
        var result = new StringBuilder();
        var currentWord = new StringBuilder();

        var chars = text.toChars();
        var len = chars.length;
        for (i in 0...len) {
            var ch:Char = chars[i];
            // treat a-z and 0-9 as characters of potential words to capture OCR errors like "me1n" or "M0ntag"
            if (ch.isAsciiAlpha() || ch.isDigit() || ch == "ä" || ch == "ö" || ch == "ü" || ch == "Ä" || ch == "Ö" || ch == "Ü" || ch == "ß") {
                currentWord.addChar(ch);
            } else if (currentWord.length > 0) {
                result.add(correctWord(currentWord.toString(), timeoutMS));
                currentWord.clear();
                result.addChar(ch);
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

        // replace oe with ö, ae with ä and ue with ü
        var wordUmlaute = word.replaceAll("oe", "ö")
            .replaceAll("ae", "ä")
            .replaceAll("ue", "ü")
            .replaceAll("OE", "Ö")
            .replaceAll("AE", "Ä")
            .replaceAll("UE", "Ü");
        if (wordUmlaute.startsWith("Oe"))
            wordUmlaute = "Ö" + wordUmlaute.substr8(2);
        else if (wordUmlaute.startsWith("Ae"))
            wordUmlaute = "Ä" + wordUmlaute.substr8(2);
        else if (wordUmlaute.startsWith("Ue"))
            wordUmlaute = "Ü" + wordUmlaute.substr8(2);

        if(dict.exists(wordUmlaute))
            return wordUmlaute;

        if (word.isUpperCase()) { // special handling for all uppercase words
            var wordLower = word.toLowerCase8();
            var wordFirstCharUpper = wordLower.toUpperCaseFirstChar();
            var pLower = dict.popularity(wordLower);
            var pCapitalized = dict.popularity(wordFirstCharUpper);
            if (pLower == 0 && pCapitalized == 0) {
                return super.correctWord(wordFirstCharUpper, timeoutMS);
            }
            return pCapitalized > pLower ? wordFirstCharUpper : wordLower;
        }

        return super.correctWord(word, timeoutMS);
    }

    override
    function generateEdits(word:String, timeoutAt:Float):Array<String> {
        var edits = super.generateEdits(word, timeoutAt);

        // add 1st char upper case variation
        for (upper in alphabetUpper) {
            edits.push(upper + word.substr8(1));
        }
        return edits;
    }
}
