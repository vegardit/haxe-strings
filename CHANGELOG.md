# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]


### Fixed
- lua compatibility issues


## [7.0.1] - 2021-08-05

### Fixed
- lua null-safety false positive


## [7.0.0] - 2021-08-04

### Added
- method `Strings#toFloatOrNull`
- method `Strings#toIntOrNull`

### Changed
- enabled null safety
- `Strings#toEReg()` now throws an exception instead of returning null if input string is null
- changed signature of `Strings#toFloat` from `(String, Null<Float>):Null<Float>` to `(String, Float):Float`
- changed signature of `Strings#toInt` from `(String, Null<Int>):Null<Int>` to `(String, Int):Int`


## [6.0.4] - 2021-05-07

### Fixed
- [Issue#10](https://github.com/vegardit/haxe-strings/issues/10) `Warning : Std.is is deprecated. Use Std.isOfType instead.`


## [6.0.3] - 2020-07-18

### Fixed
- [Issue#9](https://github.com/vegardit/haxe-strings/issues/9) `Warning : Using "is" as an identifier is deprecated`


## [6.0.2] - 2020-07-14

### Fixed
- [Issue#8](https://github.com/vegardit/haxe-strings/issues/8) `Warning : __js__ is deprecated, use js.Syntax.code instead`


## [6.0.1] - 2020-04-21

### Fixed
- added workarounds for JVM target bugs
- added workaround for eval target bug


## [6.0.0] - 2020-04-20

### Added
- property `CharIterator#current:Null<Char>`
- method `CharPos#toString()`
- method `StringDiff#toString()`

### Changed
- minimum required Haxe version is now 4.x
- removed support for old PHP5 target
- `StringSet.addAll(null)` now throws an exception

### Fixed
- `CharIterator#prev()` does not throw EOF as expected
- [PR#5](https://github.com/vegardit/haxe-strings/pull/5) `Ansi.cursor(RestorePos)` performs saves position instead of restoring it

### Removed
- deprecated `hx.strings.Paths` module (use [hx.files.Path](https://github.com/vegardit/haxe-files/blob/main/src/hx/files/Path.hx) of the [haxe-files](https://lib.haxe.org/p/haxe-files/) haxelib instead)


## [5.2.4] - 2019-12-10

### Changed
- enable `Pattern.MatchingOption#DOTALL` option for HL, Lua, NodeJS, Python targets
- reduce usage of deprecated `haxe.Utf8` class


## [5.2.3] - 2019-09-20

### Fixed
- fixes for Haxe 4 RC5


## [5.2.2] - 2018-12-17

### Fixed
- Workaround for [Haxe Issue 5336](https://github.com/HaxeFoundation/haxe/issues/5336) "Utf8.compare() for CS treats upper-/lowercase chars differently than other platforms"
- String8 abstract does not work Haxe 4

## [5.2.1] - 2018-11-27

### Fixed
- "ReferenceError: window is not defined" on node.js


## [5.2.0] - 2018-11-27

### Added
- method `Pattern#remove()`
- type `hx.strings.AnyAsString`

### Fixed
- `OS.isWindows` does not work with PhantomJS


## [5.1.0] - 2018-11-10

### Added
- renderMethod parameter to `Strings#ansiToHtml()` (thanks to https://github.com/emugel)

### Fixed
- make Pattern, OrderedStringMap, StringBuilder compatible with Haxe 4 Preview 5


## [5.0.1] - 2018-04-20

### Changed
- replaced license header by "SPDX-License-Identifier: Apache-2.0"
- `StringMap` is now usable in macro mode
- deprecated `hx.strings.Paths`

### Fixed
- `OS.isWindows` does not work with Node.js


## [5.0.0] - 2017-11-05

### Added
- parameter 'interpolationPrefix' to `hx.strings.StringMacros#multiline()`
- property `hx.strings.collection.SortedStringMap#size`

### Changed
- minimum required Haxe version is now 3.4.x
- removed workarounds for Haxe 3.2 and lower
- renamed hx.strings.collection.OrderedStringMap#clone() to #copy() for Haxe 4 compatiblity
- renamed hx.strings.collection.StringMap#clone() to #copy() for Haxe 4 compatiblity
- renamed hx.strings.collection.SortedStringMap#clone() to #copy() for Haxe 4 compatiblity
- use php.Syntax.code instead of "untyped __call__" for Haxe 4 compatiblity

### Fixed
- [flash] workaround for 'Cannot create Vector without knowing runtime type'
- String8.String8Generator is broken


### Removed
- unused 'comparator' constructor parameter from hx.strings.collection.OrderedStringSet


## [4.0.0] - 2017-05-25

### Added
- class hx.strings.CharIterator
- class hx.strings.Strings.CharPos
- class hx.strings.collection.OrderedStringMap
- class hx.strings.collection.OrderedStringSet
- class hx.strings.StringMacros
- function hx.strings.Strings#toCharIterator()
- function hx.strings.collection.StringSet#addAll()
- function hx.strings.collection.StringArray#contains()
- function hx.strings.collection.StringArray#pushAll()
- function hx.strings.StringBuilder#asOutput()
- function hx.strings.Version#isCompatible()
- parameter 'charsToRemove' to hx.strings.Strings#trim...() methods

### Changed
- renamed hx.strings.collection.StringTreeMap to hx.strings.collection.SortedStringMap
- replaced hx.strings.CharPos abstract with hx.strings.Strings.CharIndex typedef
- replaced hx.strings.collection.StringMaps class with hx.strings.collection.StringMap abstract


## [3.0.0] - 2017-03-27

### Added
- function hx.strings.Pattern.Matcher#reset(str)
- function hx.strings.StringBuilder#insert()
- function hx.strings.StringBuilder#insertAll()
- function hx.strings.StringBuilder#insertChar()
- parameter hx.strings.RandomStrings#randomUUIDv4(separator)
- parameter 'notFoundDefault' to hx.strings.Strings#substring...() methods

### Removed
- function hx.strings.StringBuilder#prepend()
- function hx.strings.StringBuilder#prependAll()
- function hx.strings.StringBuilder#prependChar()

### Changed
- StringBuilder now uses C#'s native StringBuilder#clear()/#insert() methods


## [2.5.0] - 2017-03-03

### Added
- type hx.strings.RandomStrings (#randomUUIDV4(), #randomDigits(), ...)
- type hx.strings.String8
- type hx.strings.collection.StringMaps
- function hx.strings.Strings#containsOnly()
- function hx.strings.Strings#compact()
- function hx.strings.Strings#removeAfter()
- function hx.strings.Strings#removeAt()
- function hx.strings.Strings#removeBefore()
- function hx.strings.Strings#removeFirst()
- function hx.strings.Strings#randomSubstring()
- function hx.strings.collection.StringTreeMap#clone()
- function hx.strings.collection.StringTreeMap#setAll()

### Changed
- renamed hx.strings.Strings#insert() to #insertAt()


## [2.4.0] - 2017-02-28

### Added
- type hx.strings.collection.StringArray
- function hx.strings.collection.StringSet#isEmpty()
- function hx.strings.collection.StringTreeMap#isEmpty()


## [2.3.0] - 2017-02-25

### Added
- function hx.strings.Strings#containsWhitespaces()
- function hx.strings.Strings#insert()
- function hx.strings.Strings#splitAt()
- function hx.strings.Strings#splitEvery()
- Support for Node.js


## [2.2.0] - 2017-01-02

### Added
- type hx.strings.Version (Version parsing according SemVer.org 2.0 specification)
- function hx.strings.Char#isAsciiAlphanumeric()
- function hx.strings.Strings#indentLines()


## [2.1.0] - 2016-08-21

### Added
- package hx.strings.ansi: type-safe ANSI escape sequence generation


## [2.0.2] - 2016-07-11

### Fixed
- [hl] interim workaround for "EReg.hx Unsupported escaped char '/'"
- [cpp] interim fix for static initializer issue


## [2.0.1] - 2016-07-09

### Fixed
- "Warning: maybe loop in static generation"


## [2.0.0] - 2016-07-09

### Added
- spell checker in package hx.strings.spelling
- type hx.strings.collection.SortedStringSet
- type hx.strings.collection.StringSet
- type hx.strings.collection.StringTreeMap
- type hx.strings.Paths for path related string manipulations
- function hx.strings.Pattern.Matcher#iterate()
- function hx.strings.Strings#ellipsizeLeft()
- function hx.strings.Strings#ellipsizeMiddle()
- function hx.strings.Strings#getLevenshteinDistance()
- function hx.strings.Strings#getFuzzyDistance()
- function hx.strings.Strings#getLongestCommonSubstring()
- function hx.strings.Strings#isLowerCase()
- function hx.strings.Strings#isUpperCase()
- function hx.strings.Strings#left()
- function hx.strings.Strings#right()
- function hx.strings.Strings#removeLeading()
- function hx.strings.Strings#removeTrailing()
- fields hx.strings.Char#CARET/#EXCLAMATION_MARK/and constants for characters 0-9

### Changed
- changed license from MIT to Apache License 2.0
- hx.strings.Strings#split8() now allows multiple separators
- slight performance improvement in hx.strings.StringBuilder
- renamed hx.strings.Strings#stripAnsi() to hx.strings.Strings#removeAnsi()
- renamed hx.strings.Strings#stripTags() to hx.strings.Strings#removeTags()
- renamed hx.strings.Strings#ltrim() to hx.strings.Strings#trimLeft()
- renamed hx.strings.Strings#rstrip() to hx.strings.Strings#trimRight()
- renamed hx.strings.Strings#abbreviate() to hx.strings.Strings#ellipsizeRight()
- renamed hx.strings.Strings#hex() to hx.strings.Strings#toHex()
- moved hx.strings.Strings#PATH_SEPARATOR to hx.strings.Paths#DIRECTORY_SEPARATOR
- moved hx.strings.Strings#globToEReg() to hx.strings.Paths#globToEReg()
- moved hx.strings.Strings#globToPattern() to hx.strings.Paths#globToPattern()
- moved hx.strings.Strings#globToRegEx() to hx.strings.Paths#globToRegEx()

### Fixed
- hx.strings.Char.toLowerCase() was broken for character I


## [1.2.0] - 2016-06-21

### Added
- function hx.strings.Strings#endsWithAny()
- function hx.strings.Strings#endsWithAnyIgnoreCase()
- function hx.strings.Strings#startsWithAny()
- function hx.strings.Strings#startsWithAnyIgnoreCase()
- function hx.strings.Strings#toTitle()
- parameter 'algorithm' to hx.strings.Strings#hashCode()

### Fixed
- hx.strings.StringBuilder#addChar() with values between 128 and 255 didn't work on all platforms as expected


## [1.1.0] - 2016-06-11

### Added
- type hx.strings.Pattern for threadsafe pattern matching
- function hx.strings.Strings#abbreviate()
- function hx.strings.Strings#globToPattern()
- function hx.strings.Strings#substringBetween()
- function hx.strings.Strings#substringBetweenIgnoreCase()
- function hx.strings.Strings#toBool()
- function hx.strings.Strings#toFloat()
- function hx.strings.Strings#toInt()
- function hx.strings.Strings#toPattern()
- function hx.strings.Strings#wrap()
- function hx.strings.StringBuilder#isEmpty()


## [1.0.0] - 2016-06-05

### Added
- Initial release
