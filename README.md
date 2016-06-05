# haxe-strings - [StringTools](http://api.haxe.org/StringTools.html) on steroids.

What is it?
-----------

A [haxelib](http://lib.haxe.org/documentation/using-haxelib/) for consistent cross-platform UTF-8 string manipulation. 
It is extensively unit tested with over 900 individual test cases.

The classes are under the package `hx.strings`.

The `Strings` class
-----------------

The [hx.strings.Strings](https://github.com/vegardit/haxe-strings/blob/master/src/haxe/strings/Strings.hx) class provides handy utility methods for string manipulations.

It also contains improved implementations of functions provided by Haxe's [StringTools](http://api.haxe.org/StringTools.html) class.

Methods ending with the letter `8` (e.g. `length8()`, `indexOf8()`, `toLowerCase8()`) are improved versions of similar methods
provided by Haxe's [String](http://api.haxe.org/String.html) class, offering UTF-8 support and consistent behavior across all platforms.

The [hx.strings.Strings](https://github.com/vegardit/haxe-strings/blob/master/src/haxe/strings/Strings.hx) class can also be used as a [static extension](http://haxe.org/manual/lf-static-extension.html).

Some examples
-----------------

```haxe
package com.example;

using hx.strings.Strings; // augment all Strings with new functions

class MyClass {

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
        
        // all functions are null-safe:
        var nullString:String = null;
        nullString.isWhiteSpace();    // returns true
        nullString.length8();         // returns 0
        nullString.contains("cat");   // returns false

	    // all methods support UTF-8 on all platforms:
	    "кот".toUpperCase8();         // returns "КОТ"
	    "кот".toUpperCaseFirstChar(); // returns "Кот"
	    "はいはい".length8();          // returns 4

        // ANSI escape sequence processing:
        "\x1B[1;33mHello World!\x1B[0m".ansiToHtml(); // returns '<span style="color:yellow;font-weight:bold;">Hello World!</span>'
	    "\x1B[1mHello World!\x1B[0m".stripAnsi();     // returns "Hello World!"

	    // use glob pattern matching:
	    "src/**/*.hx".globToEReg().match("src/haxe/strings/Char.hx");            // returns true
	    "assets/**/*.{js,css}".globToEReg().match("assets/theme/dark/dark.css"); // returns true
        
        // case formatting:
        "look at me".toUpperCamel();       // returns "LookAtMe"
        "MyCSSClass".toLowerCamel();       // returns "myCSSClass"
        "MyCSSClass".toLowerHyphen();      // returns "my-css-class"
        "MyCSSClass".toLowerUnderscore();  // returns "my_css_class"
        "myCSSClass".toUpperUnderscore();  // returns "MY_CSS_CLASS"
	}
}
```

Using the latest code
---------------------

1. check-out the trunk
    ```
    haxelib git haxe-strings https://github.com/vegardit/haxe-strings.git src
    ```

    or with Subversion
    ```
    svn checkout https://github.com/vegardit/haxe-strings/trunk D:\haxe-projects\haxe-strings
    ```

2. register the development release with haxe
    ```
    haxelib dev haxe-strings D:\haxe-projects\haxe-strings
    ```

3. use in your Haxe project
  * for [OpenFL](http://www.openfl.org/)/[Lime](https://github.com/openfl/lime) projects add `<haxelib name="haxe-strings" />` to your [project.xml](http://www.openfl.org/documentation/projects/project-files/xml-format/)
  * for free-style projects add `-lib haxe-strings`  to `your *.hxml` file or as command line option when running the [Haxe compiler](http://haxe.org/manual/compiler-usage.html)

License
-------
All files are released under the [MIT license](https://github.com/vegardit/haxe-strings/blob/master/LICENSE.txt).