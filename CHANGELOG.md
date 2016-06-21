# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com/).

## [1.2.0] - 2016-06-21
### Added
- hx.strings.Strings.endsWithAny()
- hx.strings.Strings.endsWithAnyIgnoreCase()
- hx.strings.Strings.startsWithAny()
- hx.strings.Strings.startsWithAnyIgnoreCase()
- hx.strings.Strings.toTitle()
- algorithm parameter to hx.strings.Strings.hashCode()
### Fixed
- hx.strings.StringBuilder.addChar with values between 128 and 255 didn't work on all platforms as expected

## [1.1.0] - 2016-06-11
### Added
- hx.strings.Pattern class for threadsafe pattern matching
- hx.strings.Strings.abbreviate()
- hx.strings.Strings.globToPattern()
- hx.strings.Strings.substringBetween()
- hx.strings.Strings.substringBetweenIgnoreCase()
- hx.strings.Strings.toBool()
- hx.strings.Strings.toFloat()
- hx.strings.Strings.toInt()
- hx.strings.Strings.toPattern()
- hx.strings.Strings.wrap()
- hx.strings.StringBuilder.isEmpty()

## 1.0.0 - 2016-06-05
### Added
- Initial release
