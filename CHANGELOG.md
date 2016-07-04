# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com/).

## [2.0.0] - 2016-07-02
### Added
- hx.strings.Pattern.Matcher#iterate()
- hx.strings.Strings#getLevenshteinDistance()
- hx.strings.Strings#getFuzzyDistance()
- hx.strings.Strings#getLongestCommonSubstring()
- hx.strings.Strings#isLowerCase()
- hx.strings.Strings#isUpperCase()
- hx.strings.Strings#left()
- hx.strings.Strings#right()
- hx.strings.Strings#removeLeading()
- hx.strings.Strings#removeTrailing()
- hx.strings.Char: CARET, and constants for characters 0-9
- hx.strings.collection.SortedStringSet
- hx.strings.collection.StringSet
- hx.strings.collection.StringTreeMap
- Spell Checker in package hx.strings.spelling
### Changed
- changed license from MIT to Apache License 2.0
- renamed hx.strings.Strings#stripAnsi() to hx.strings.Strings#removeAnsi()
- renamed hx.strings.Strings#stripTags() to hx.strings.Strings#removeTags()
- renamed hx.strings.Strings#ltrim() to hx.strings.Strings#trimLeft()
- renamed hx.strings.Strings#rstrip() to hx.strings.Strings#trimRight()
- renamed hx.strings.Strings#abbreviate() to hx.strings.Strings#ellipsizeRight()
- renamed hx.strings.Strings#PATH_SEPARATOR to hx.strings.Strings#DIRECTORY_SEPARATOR
- slight performance improvement in hx.strings.StringBuilder
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

## 1.0.0 - 2016-06-05
### Added
- Initial release
