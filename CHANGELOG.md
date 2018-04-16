# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com/).

## [Unreleased]

### Changed
- replaced license header by "SPDX-License-Identifier: Apache-2.0"
- StringMap is now usable in Macro mode

## [5.0.0] - 2017-11-05

### Added
- parameter 'interpolationPrefix' to hx.strings.StringMacros#multiline()
- property hx.strings.collection.SortedStringMap#size

### Changed
- minium required haxe Version is now 3.4.0
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
