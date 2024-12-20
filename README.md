# haxe-strings - [StringTools](http://api.haxe.org/StringTools.html) on steroids.

[![Build Status](https://github.com/vegardit/haxe-strings/workflows/Build/badge.svg "GitHub Actions")](https://github.com/vegardit/haxe-strings/actions?query=workflow%3A%22Build%22)
[![Release](https://img.shields.io/github/release/vegardit/haxe-strings.svg)](http://lib.haxe.org/p/haxe-strings)
[![License](https://img.shields.io/github/license/vegardit/haxe-strings.svg?label=license)](#license)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.1%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

1. [What is it?](#what-is-it)
1. [The `Strings` utility class](#strings-class)
1. [The `String8` type](#string8-type)
1. [The spell checker](#spell-checker)
1. [The string collection classes](#string-collections)
1. [The `StringBuilder` class](#stringbuilder-class)
1. [The `Ansi` class](#ansi-class)
1. [Random string generation](#random-strings)
1. [Semantic version parsing with the `Version` type](#version-type)
1. [Installation](#installation)
1. [Using the latest code](#latest)
1. [License](#license)


## <a name="what-is-it"></a>What is it?

A [haxelib](http://lib.haxe.org/documentation/using-haxelib/) for consistent cross-platform UTF-8 string manipulation.

All classes are located in the package `hx.strings` or below.

The library has been extensively unit tested (over 1,700 individual test cases) on the targets C++, C#, [Eval](https://haxe.org/blog/eval/), Flash, [HashLink](https://hashlink.haxe.org/),
Java, JavaScript ([Node.js](https://nodejs.org) and PhantomJS), [Neko](https://nekovm.org/), [PHP](https://www.php.net/) 7 and [Python](https://www.python.org/) 3.

**Note:**
* When targeting PHP ensure the [php_mbstring](http://php.net/manual/en/book.mbstring.php) extension is enabled in the `php.ini` file. This extension is required for proper UTF-8 support.

### Haxe compatiblity

|haxe-strings    |Haxe           |
|----------------|---------------|
|1.0.0 to 4.0.0  |3.2.1 or higher|
|5.0.0 to 5.2.4  |3.4.2 or higher|
|6.0.0 or higher |4.0.5 or higher|


## <a name="strings-class"></a>The `Strings` utility class

The [hx.strings.Strings](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/Strings.hx) class provides handy utility methods for string manipulations.

It also contains improved implementations of functions provided by Haxe's [StringTools](http://api.haxe.org/StringTools.html) class.

Methods ending with the letter `8` (e.g. `length8()`, `indexOf8()`, `toLowerCase8()`) are improved versions of similar methods
provided by Haxe's [String](http://api.haxe.org/String.html) class, offering UTF-8 support and consistent behavior across all platforms (including Neko).

The [hx.strings.Strings](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/Strings.hx) class can also be used as a [static extension](http://haxe.org/manual/lf-static-extension.html).


### <a name="strings-examples"></a>Some examples

```haxe
using hx.strings.Strings; // augment all Strings with new functions

class Test {

   static function main() {
      // Strings are extended:
      "".isEmpty();      // returns true
      "   ".isBlank();   // returns true
      "123".isDigits();  // returns true
      "a".repeat(3);     // returns "aaa"
      "abc".reverse();   // returns "cba"

      // Int's are extended too:
      32.toChar().isSpace();       // returns true
      32.toChar().toString();      // returns " "
      32.toChar().isAscii();       // returns true
      6000.toChar().isAscii();     // returns false
      6000.toChar().isUTF8();      // returns true
      74.toHex();                  // returns "4A"

      // all functions are null-safe:
      var nullString:String = null;
      nullString.length8();         // returns 0
      nullString.contains("cat");   // returns false

      // all methods support UTF-8 on all platforms:
      "кот".toUpperCase8();         // returns "КОТ"
      "кот".toUpperCaseFirstChar(); // returns "Кот"
      "はいはい".length8();          // returns 4

      // ANSI escape sequence processing:
      "\x1B[1;33mHello World!\x1B[0m".ansiToHtml();            // returns '<span style="color:yellow;font-weight:bold;">Hello World!</span>'
      "\x1B[1;33mHello World!\x1B[0m".ansiToHtml(CssClasses);  // returns '<span class="ansi_fg_yellow ansi_bold">Hello World!</span>'
      "\x1B[1mHello World!\x1B[0m".removeAnsi();               // returns "Hello World!"

      // It is also possible to fully customize the css class names used using a callback:
      "\x1B[1;33mHello World!\x1B[0m".ansiToHtml(CssClassesCallback(function(st:hx.strings.AnsiState):String {
         var a : Array<String> = [];
         if (st.fgcolor != null) a.push("someprefix_fg_" + st.fgcolor + "_somesuffix");
         if (st.bgcolor != null) a.push("someprefix_bg_" + st.fgcolor);
         if (st.bold)            a.push("someprefix_bold");
         if (st.underline)       a.push("someprefix_underline");
         if (st.blink)           a.push("someprefix_blink");
         return a.join(" ");
       })));  // returns '<span class="ansi_fg_yellow ansi_bold">Hello World!</span>'

      // case formatting:
      "look at me".toUpperCamel();       // returns "LookAtMe"
      "MyCSSClass".toLowerCamel();       // returns "myCSSClass"
      "MyCSSClass".toLowerHyphen();      // returns "my-css-class"
      "MyCSSClass".toLowerUnderscore();  // returns "my_css_class"
      "myCSSClass".toUpperUnderscore();  // returns "MY_CSS_CLASS"

      // ellipsizing strings:
      "The weather is very nice".ellipsizeLeft(20);    // returns "The weather is ve..."
      "The weather is very nice".ellipsizeMiddle(20);  // returns "The weath...ery nice"
      "The weather is very nice".ellipsizeRight(20);   // returns "...ther is very nice"

      // string differences:
      "It's green".diffAt("It's red"); // returns 5
      "It's green".diff("It's red");   // returns { left: 'green', right: 'red', at: 5 }

      // hash codes:
      "Cool String".hashCode();       // generate a platform specific hash code
      "Cool String".hashCode(CRC32);  // generate a hash code using CRC32
      "Cool String".hashCode(JAVA);   // generate a hash code using the Java hash algorithm

      // cleanup:
      "/my/path/".removeLeading("/");       // returns "my/path/"
      "/my/path/".removeTrailing("/");      // returns "/my/path"
      "<i>So</i> <b>nice</b>".removeTags(); // returns "So nice"
   }
}
```

## <a name="string8-type"></a>The `String8` type

The `hx.strings.String8` is an abstract type based on `String`. All exposed methods are UTF-8 compatible and have consistent behavior across platforms.

It can be used as a drop-in replacement for type String.

Example usage:
```haxe
class Test {
   static function main() {
      var str:String = "はいはい";  // create a string with UTF8 chars
      str.length;  // will return different values depending on the default UTF8 support of the target platform

      var str8:String8 = str; // we assign the string to a variable of type String8 - because of the nature of Haxe`s abstract types this will not result in the creation of a new object instance
      str8.length;  // will return the correct character length on all platforms

      str8.ellipsizeLeft(2); // the String8 type automatically has all utility string functions provided by the Strings class.
   }
}
```

The type declaration in the Strings8.hx file is nearly empty because all methods are auto generated based on the static methods provided by the `hx.strings.Strings` class.

## <a name="spell-checker"></a>The spell checker

The package [hx.strings.spelling](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/spelling) contains an extensible spell checker implementation that is based on ideas outlined by Peter Norvig in his article [How to write a Spell Checker](http://www.norvig.com/spell-correct.html).

The [SpellChecker#correctWord()](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/spelling/checker/SpellChecker.hx#L38) method can for example be used to implement a Google-like "did you mean 'xyz'?" feature for a custom search engine.

Now let's do some spell checking...

```haxe
import hx.strings.spelling.checker.*;
import hx.strings.spelling.dictionary.*;
import hx.strings.spelling.trainer.*;

class Test {
   static function main() {
      /*
       * first we use the English spell checker with a pre-trained dictionary
       * that is bundled with the library:
       */
      EnglishSpellChecker.INSTANCE.correctWord("speling");  // returns "spelling"
      EnglishSpellChecker.INSTANCE.correctWord("SPELING");  // returns "spelling"
      EnglishSpellChecker.INSTANCE.correctWord("SPELLING"); // returns "spelling"
      EnglishSpellChecker.INSTANCE.correctWord("spell1ng"); // returns "spelling"
      EnglishSpellChecker.INSTANCE.correctText("sometinG zEems realy vrong!") // returns "something seems really wrong!"
      EnglishSpellChecker.INSTANCE.suggestWords("absance"); // returns [ "absence", "advance", "balance" ]

      /*
       * let's check the pre-trained German spell checker
       */
      GermanSpellChecker.INSTANCE.correctWord("schreibweise");  // returns "Schreibweise"
      GermanSpellChecker.INSTANCE.correctWord("Schreibwiese");  // returns "Schreibweise"
      GermanSpellChecker.INSTANCE.correctWord("SCHREIBWEISE");  // returns "Schreibweise"
      GermanSpellChecker.INSTANCE.correctWord("SCHRIBWEISE");   // returns "Schreibweise"
      GermanSpellChecker.INSTANCE.correctWord("Schre1bweise");  // returns "Schreibweise"
      GermanSpellChecker.INSTANCE.correctText("etwaz kohmische Aepfel ligen vör der Thür"); // returns "etwas komische Äpfel liegen vor der Tür"
      GermanSpellChecker.INSTANCE.suggestWords("Sistem");       // returns[ "System", "Sitte", "Sitten" ]

      /*
       * now we train our own dictionary from scratch
       */
      var myDict = new InMemoryDictionary("English");
      // download some training text with good vocabular
      var trainingText = haxe.Http.requestUrl("http://www.norvig.com/big.txt");
      // populating the dictionary might take a while:
      EnglishDictionaryTrainer.INSTANCE.trainWithString(myDict, trainingText);
      // let's use the trained dictionary with a spell checker
      var mySpellChecker = new EnglishSpellChecker(myDict);
      mySpellChecker.INSTANCE.correctWord("speling");  // returns "spelling"

      // since training a dictionary can be quite time consuming, we save
      // the analyzed words and their popularity/frequency to a file
      myDict.exportWordsToFile("myDict.txt");

      // the word list can later be loaded using
      myDict.loadWordsFromFile("myDict.txt");
   }
}
```


## <a name="string-collections"></a>The string collection classes

The package [hx.strings.collection](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/collection) contains some useful collection classes for strings.

1. [StringSet](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/collection/StringSet.hx) is a collection of unique strings. Each string is guaranteed to only exists once within the collection.
   ```haxe
   var set = new hx.strings.collection.StringSet();
   set.add("a");
   set.add("a");
   set.add("b");
   set.add("b");
   // at this point the set only contains two elements: one 'a' and one 'b'
   ```

2. [SortedStringSet](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/collection/SortedStringSet.hx) is a sorted collection of unique strings. A custom comparator can be provided for using different sorting algorithm.

3. [SortedStringMap](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/collection/SortedStringMap.hx) is a map that is sorted by there keys (which are of type [String](http://api.haxe.org/String.html)).


## <a name="stringbuilder-class"></a>The `StringBuilder` class

The [hx.strings.StringBuilder](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/StringBuilder.hx) class is an alternative to the built-in [StringBuf](http://api.haxe.org/StringBuf.html).
It provides an fluent API, cross-platform UTF-8 support and the ability to insert Strings at arbitrary positions.

```haxe
import hx.strings.StringBuilder;

class Test {
   static function main() {
      // create a new instance with initial content
      var sb = new StringBuilder("def");

      // insert / add some strings via fluent API calls
      sb.insert(0, "abc")
         .newLine()   // appends "\n"
         .add("ghi")
         .addChar(106);

      sb.toString();  // returns "abcdef\nghij\n"

      sb.clear();     // reset the internal state

      sb.addAll(["a", 1, true, null]);

      sb.toString();  // returns "a1truenull"
   }
}
```


## <a name="ansi-class"></a>The `Ansi` class

The [hx.strings.ansi.Ansi](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/ansi/Ansi.hx) class provides functionalities to write [ANSI escape sequences](https://en.wikipedia.org/wiki/ANSI_escape_code) in a type-safe manner.

```haxe
import hx.strings.ansi.Ansi;

class Test {
   static function main() {
      var stdout = Sys.stdout();

      stdout.writeString(Ansi.fg(RED));           // set the text foreground color to red
      stdout.writeString(Ansi.bg(WHITE));         // set the text background color to white
      stdout.writeString(Ansi.attr(BOLD));        // make the text bold
      stdout.writeString(Ansi.attr(RESET));       // reset all color or text attributes
      stdout.writeString(Ansi.clearScreen());     // clears the screen
      stdout.writeString(Ansi.cursor(MoveUp(2))); // moves the cursor 2 lines up

      // now let's work with the fluent API:
      var writer = Ansi.writer(stdout); // supports StringBuf, haxe.io.Ouput and hx.strings.StringBuilder
      writer
         .clearScreen()
         .cursor(GoToPos(10,10))
         .fg(GREEN).bg(BLACK).attr(ITALIC).write("How are you?").attr(RESET)
         .cursor(MoveUp(2))
         .fg(RED).bg(WHITE).attr(UNDERLINE).write("Hello World!").attr(UNDERLINE_OFF)
         .flush();
   }
}
```

## <a name="random-strings"></a>Random string generation

The `hx.strings.RandomStrings` class contains methods to generate different types of random strings,
e.g. UUIDs or alpha-numeric sequences.

```haxe
import hx.strings.RandomStrings;
using hx.strings.Strings;

class Test {
   static function main() {
      RandomStrings.randomUUIDv4(); // generates a UUID according to RFC 4122 UUID Version 4, e.g. "f3cdf7a7-a179-464b-ae98-83f6659ae33f"
      RandomStrings.randomDigits(4); // generates a 4-char numeric strings, e.g. "4832"
      RandomStrings.randomAsciiAlphaNumeric(8); // generates a 8-char ascii alph numeric strings, e.g. "aZvDF34L"
      RandomStrings.randomSubstring("abcdefghijlkmn", 4); // returns a random 4-char substring of the given string, e.g. "defg"
   }
}
````

## <a name="version-type"></a>Semantic version parsing with the `Version` type

The [hx.strings.Version](https://github.com/vegardit/haxe-strings/blob/main/src/hx/strings/Version.hx) type provides functionalities for parsing of and working with version strings following the [SemVer 2.0 Specification](https://semver.org).

```haxe
import hx.strings.Version;

class Test {
   static function main() {

      var ver:Version;

      ver = new Version(11, 2, 4);
      ver.major;                  // returns 11
      ver.minor;                  // returns 2
      ver.patch;                  // returns 4
      ver.toString();             // returns '11.2.4'
      ver.nextPatch().toString(); // returns '11.2.5'
      ver.nextMinor().toString(); // returns '11.3.0'
      ver.nextMajor().toString(); // returns '12.0.0'

      ver = Version.of("11.2.4-alpha.2+exp.sha.141d2f7");
      ver.major;            // returns 11
      ver.minor;            // returns 2
      ver.patch;            // returns 4
      ver.isPreRelease;     // returns true
      ver.preRelease;       // returns 'alpha.2'
      ver.buildMetadata;    // returns 'exp.sha.141d2f7'
      ver.hasBuildMetadata; // returns true
      ver.nextPreRelease().toString(); // returns "11.2.4-alpha.3"

      var v1_0_0:Version = "1.0.0";
      var v1_0_1:Version = "1.0.1";

      v1_0_0 < v1_0_1;       // returns true
      v1_0_1 >= v1_0_0;      // returns true

      v1_0_1.isGreaterThan(v1_0_0); // returns true
      v1_0_1.isLessThan(Version.of("1.0.0"); // returns false

      Version.isValid("foobar"); // returns false
   }
}
```


## <a name="installation"></a>Installation

1. install the library via haxelib using the command:
   ```
   haxelib install haxe-strings
   ```

2. use in your Haxe project

   * for [OpenFL](http://www.openfl.org/)/[Lime](https://github.com/openfl/lime) projects add `<haxelib name="haxe-strings" />` to your [project.xml](http://www.openfl.org/documentation/projects/project-files/xml-format/)
   * for free-style projects add `-lib haxe-strings`  to `your *.hxml` file or as command line option when running the [Haxe compiler](http://haxe.org/manual/compiler-usage.html)


## <a name="latest"></a>Using the latest code

### Using `haxelib git`

```
haxelib git haxe-strings https://github.com/vegardit/haxe-strings main D:\haxe-projects\haxe-strings
```

###  Using Git

1. check-out the main branch
    ```
    git clone https://github.com/vegardit/haxe-strings --branch main --single-branch D:\haxe-projects\haxe-strings --depth=1
    ```

2. register the development release with haxe
    ```
    haxelib dev haxe-strings D:\haxe-projects\haxe-strings
    ```


## <a name="license"></a>License

All files are released under the [Apache License 2.0](LICENSE.txt).

Individual files contain the following tag instead of the full license text:
```
SPDX-License-Identifier: Apache-2.0
```

This enables machine processing of license information based on the SPDX License Identifiers that are available here: https://spdx.org/licenses/.
