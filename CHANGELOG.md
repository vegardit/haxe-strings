# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com/).

## [2.4.0] - 2017-02-28

### Added
- hx.strings.collection.StringArray
- hx.strings.collection.StringSet.isEmpty()
- hx.strings.collection.StringTreeMap.isEmpty()


## [2.3.0] - 2017-02-25

### Added
- hx.strings.Strings#containsWhitespaces()
- hx.strings.Strings#insert()
- hx.strings.Strings#splitAt()
- hx.strings.Strings#splitEvery()
- Support for Node.js


## [2.2.0] - 2017-01-02

### Added
- hx.strings.Char#isAsciiAlphanumeric()
- hx.strings.Strings#indentLines()
- hx.strings.Version (Version parsing according SemVer.org 2.0 specification)


## [2.1.0] - 2016-08-21

### Added
- hx.strings.ansi package: type-safe ANSI escape sequence generation


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
- hx.strings.collection.SortedStringSet class
- hx.strings.collection.StringSet class
- hx.strings.collection.StringTreeMap class
- hx.strings.Paths class for path related string manipulations
- hx.strings.Pattern.Matcher#iterate()
- hx.strings.Strings#ellipsizeLeft()
- hx.strings.Strings#ellipsizeMiddle()
- hx.strings.Strings#getLevenshteinDistance()
- hx.strings.Strings#getFuzzyDistance()
- hx.strings.Strings#getLongestCommonSubstring()
- hx.strings.Strings#isLowerCase()
- hx.strings.Strings#isUpperCase()
- hx.strings.Strings#left()
- hx.strings.Strings#right()
- hx.strings.Strings#removeLeading()
- hx.strings.Strings#removeTrailing()
- hx.strings.Char: CARET, EXCLAMATION_MARK, and constants for characters 0-9

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
- hx.strings.Strings#endsWithAny()
- hx.strings.Strings#endsWithAnyIgnoreCase()
- hx.strings.Strings#startsWithAny()
- hx.strings.Strings#startsWithAnyIgnoreCase()
- hx.strings.Strings#toTitle()
- algorithm parameter to hx.strings.Strings#hashCode()

### Fixed
- hx.strings.StringBuilder#addChar() with values between 128 and 255 didn't work on all platforms as expected


## [1.1.0] - 2016-06-11

### Added
- hx.strings.Pattern class for threadsafe pattern matching
- hx.strings.Strings#abbreviate()
- hx.strings.Strings#globToPattern()
- hx.strings.Strings#substringBetween()
- hx.strings.Strings#substringBetweenIgnoreCase()
- hx.strings.Strings#toBool()
- hx.strings.Strings#toFloat()
- hx.strings.Strings#toInt()
- hx.strings.Strings#toPattern()
- hx.strings.Strings#wrap()
- hx.strings.StringBuilder#isEmpty()


## [1.0.0] - 2016-06-05

### Added
- Initial release
