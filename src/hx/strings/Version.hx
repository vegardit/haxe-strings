/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package hx.strings;

using hx.strings.Strings;

/**
 * Instances of this type represent SemVer 2.0 compliant versions.
 * 
 * See http://www.semver.org for terminology and constraints.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@immutable
abstract Version(VersionData) from VersionData to VersionData {

    /*
     * Operator overloading
     */
    @:op(A>B) inline function _gt(other:Version):Bool return compareTo(other) > 0;
    @:op(A<B) inline function _lt(other:Version):Bool return compareTo(other) < 0;
    @:op(A>=B) inline function _gteq(other:Version):Bool return compareTo(other) >= 0;
    @:op(A<=B) inline function _lteq(other:Version):Bool return compareTo(other) <= 0;
    @:op(A==B) inline function _eq(other:Version):Bool return compareTo(other, false) == 0;
    @:op(A!=B) inline function _neq(other:Version):Bool return compareTo(other, false) != 0;

    /**
     * Version of the SemVer.org specification implemented by this class.
     */
    inline
    static var SEM_VER_SPEC = "SemVer 2.0.0";
    
    inline
    static var SEP_IDENTIFIER = ".";
    
    inline
    static var SEP_PRERELEASE = "-";
    
    inline
    static var SEP_METADATA = "+";
    
    inline 
    static var PATTERN_NUMBER_NO_LEADING_ZERO:String = "(0|[1-9]\\d*)";

    inline
    static var PATTERN_METADATA = '[0-9A-Za-z-]+(\\$SEP_IDENTIFIER[0-9A-Za-z-]+)*';
    
    inline
    static var PATTERN_PRERELEASE = "" +
                          '($PATTERN_NUMBER_NO_LEADING_ZERO|[1-9a-zA-Z-][0-9a-zA-Z-]*)' + // first identifier
        '(\\$SEP_IDENTIFIER($PATTERN_NUMBER_NO_LEADING_ZERO|[1-9a-zA-Z-][0-9a-zA-Z-]*))*'; // remaining identifiers

    static var PATTERN_VERSION(default, never) = "" +
        '$PATTERN_NUMBER_NO_LEADING_ZERO\\$SEP_IDENTIFIER' + // MAJOR
        '$PATTERN_NUMBER_NO_LEADING_ZERO\\$SEP_IDENTIFIER' + // MINOR
        '$PATTERN_NUMBER_NO_LEADING_ZERO' + // PATCH
        '(?:\\$SEP_PRERELEASE(' + PATTERN_PRERELEASE.replaceAll("(", "(?:") + "))?" +
        '(?:\\$SEP_METADATA('   + PATTERN_METADATA  .replaceAll("(", "(?:") + "))?";

    static var VALIDATOR_METADATA(default, never)   = Pattern.compile("^" + PATTERN_METADATA + "$");
    static var VALIDATOR_PRERELEASE(default, never) = Pattern.compile("^" + PATTERN_PRERELEASE + "$");
    static var VALIDATOR_VERSION(default, never)    = Pattern.compile("^" + PATTERN_VERSION + "$");
    
    /**
     * Trims and parses the given string and returns a version instance.
     * 
     * <pre><code>
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").major         == 1
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").minor         == 2
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").patch         == 3
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").preRelease    == "alpha.1"
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").buildMetadata == "exp.sha.141d2f7"
     * >>> Version.of("  1.2.3-alpha.1+exp.sha.141d2f7  ").major     == 1
     * >>> Version.of(null)     == null
     * >>> Version.of("1")      throws      '[1] is not a valid SemVer 2.0.0 version string!'
     * >>> Version.of("1.2")    throws    '[1.2] is not a valid SemVer 2.0.0 version string!'
     * >>> Version.of("1.02.3") throws '[1.02.3] is not a valid SemVer 2.0.0 version string!'
     * >>> Version.of("-1")     throws     '[-1] is not a valid SemVer 2.0.0 version string!'
     * </code></pre>
     * 
     * @throws if <b>str</b> is not a valid SemVer.org version string.
     */
    @:from
    public static function of(str:String):Version {
        if(str == null)
            return null;

        var m = VALIDATOR_VERSION.matcher(str.trim());

        if(!m.matches())
            throw '[$str] is not a valid $SEM_VER_SPEC version string!';

        #if (php && haxe_ver < "3.4.0")
            // workaround for "Undefined variable: __hx__spos"
            untyped __php__("$__hx__spos = $GLOBALS['%s']->length;");
        #end
        #if (cs || php)
            var preRelease    = try { m.matched(4); } catch (e:Dynamic) {  null; };
            var buildMetadata = try { m.matched(5); } catch (e:Dynamic) {  null; };
        #else
            var preRelease    = m.matched(4);
            var buildMetadata = m.matched(5);
        #end
        
        return new Version(
            m.matched(1).toInt(),
            m.matched(2).toInt(),
            m.matched(3).toInt(),
            preRelease,
            buildMetadata
        );
    }
    
    /**
     * <pre><code>
     * >>> Version.isValid("1.0.0")       == true
     * >>> Version.isValid("1.0.0-rc")    == true
     * >>> Version.isValid("1.0.0-rc.1")  == true
     * >>> Version.isValid("1.0.0+exp.sha.141d2f7")      == true
     * >>> Version.isValid("1.0.0-rc.1+exp.sha.141d2f7") == true
     * >>> Version.isValid(null)     == false
     * >>> Version.isValid("")       == false
     * >>> Version.isValid("1")      == false
     * >>> Version.isValid("1.1")    == false
     * >>> Version.isValid("1.01.0") == false
     * </pre></code>
     * 
     * @return <code>true</code> if <b>str</b> is a valid SemVer.org version string.
     */
    inline
    public static function isValid(str:String):Bool {
        return str.isBlank() ? false : VALIDATOR_VERSION.matcher(str).matches();
    }
    
    /**
     * <pre><code>
     * >>> Version.isValidPreRelease(null) == true
     * >>> Version.isValidPreRelease("")   == true
     * >>> Version.isValidPreRelease("00") == false
     * >>> Version.isValidPreRelease("alpha")    == true
     * >>> Version.isValidPreRelease("alpha.1")  == true
     * >>> Version.isValidPreRelease("alpha.10") == true
     * >>> Version.isValidPreRelease("alpha.01") == false
     * >>> Version.isValidPreRelease("rc")       == true
     * >>> Version.isValidPreRelease("rc1")      == true
     * </pre></code>
     * 
     * @return <code>true</code> if <b>str</b> complies with the SemVer.org specification for the pre-release part of a version string
     */
    inline
    public static function isValidPreRelease(str:String):Bool {
        return str.isEmpty() ? true : VALIDATOR_PRERELEASE.matcher(str).matches();
    }
    
    /**
     * <pre><code>
     * >>> Version.isValidBuildMetaData(null) == true
     * >>> Version.isValidBuildMetaData("")   == true
     * >>> Version.isValidBuildMetaData("00") == true
     * >>> Version.isValidBuildMetaData("2016-12-12.16-11") == true
     * >>> Version.isValidBuildMetaData("exp.sha.141d2f7") == true
     * >>> Version.isValidBuildMetaData("ab_cd") == false
     * </pre></code>
     *
     * @return <code>true</code> if <b>str</b> complies with the SemVer.org specification for the metadata part of a version string.
     */
    inline
    public static function isValidBuildMetaData(str:String):Bool {
        return str.isEmpty() ? true : VALIDATOR_METADATA.matcher(str).matches();
    }

    /**
     * MUST be non-negative.
     * MUST NOT include leading zeros.
     * 
     * <pre><code>
     * >>> Version.of("1.2.3"                        ).major == 1
     * >>> Version.of("1.2.3-alpha.1"                ).major == 1
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").major == 1
     * >>> Version.of("1.2.3+exp.sha.141d2f7"        ).major == 1
     * </pre><code>
     */
    public var major(get, never):Int;
    inline function get_major() return switch (this) {
        case VersionEnum(maj, min, pat, pre, build): maj;
    }

    
    /**
     * MUST be non-negative.
     * MUST NOT include leading zeros.
     * 
     * <pre><code>
     * >>> Version.of("1.2.3"                        ).minor == 2
     * >>> Version.of("1.2.3-alpha.1"                ).minor == 2
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").minor == 2
     * >>> Version.of("1.2.3+exp.sha.141d2f7"        ).minor == 2
     * </pre><code>
     */
    public var minor(get, never):Int;
    inline function get_minor() return switch (this) {
        case VersionEnum(maj, min, pat, pre, build): min;
    }
    
    /**
     * MUST be non-negative.
     * MUST NOT include leading zeros.
     * 
     * <pre><code>
     * >>> Version.of("1.2.3"                        ).patch == 3
     * >>> Version.of("1.2.3-alpha.1"                ).patch == 3
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").patch == 3
     * >>> Version.of("1.2.3+exp.sha.141d2f7"        ).patch == 3
     * </pre><code>
     */
    public var patch(get, never):Int;
    inline function get_patch() return switch (this) {
        case VersionEnum(maj, min, pat, pre, build): pat;
    }

    /**
     * A series of dot (.) separated identifiers.
     * Identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].
     * Identifiers MUST NOT be empty. 
     * Numeric identifiers MUST NOT include leading zeroes. 
     * 
     * <pre><code>
     * >>> Version.of("1.2.3"                        ).preRelease == null
     * >>> Version.of("1.2.3-alpha.1"                ).preRelease == "alpha.1"
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").preRelease == "alpha.1"
     * >>> Version.of("1.2.3+exp.sha.141d2f7"        ).preRelease == null
     * </pre><code>
     */
    public var preRelease(get, never):String;
    inline function get_preRelease() return switch (this) {
        case VersionEnum(maj, min, pat, pre, build): pre;
    }

    /**
     * <pre><code>
     * >>> Version.of("1.0.0"         ).isPreRelease == false
     * >>> Version.of("1.0.0-rc"      ).isPreRelease == true
     * >>> Version.of("1.0.0-rc.1+001").isPreRelease == true
     * >>> Version.of("1.0.0+001"     ).isPreRelease == false
     * </pre></code>
     */
    public var isPreRelease(get, never):Bool;
    inline function get_isPreRelease() return preRelease != null;
    
    /**
     * A series of dot (.) separated identifiers.
     * Identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-]. 
     * Identifiers MUST NOT be empty.
     * 
     * <pre><code>
     * >>> Version.of("1.2.3"                        ).buildMetadata == null
     * >>> Version.of("1.2.3-alpha.1"                ).buildMetadata == null
     * >>> Version.of("1.2.3-alpha.1+exp.sha.141d2f7").buildMetadata == "exp.sha.141d2f7"
     * >>> Version.of("1.2.3+exp.sha.141d2f7"        ).buildMetadata == "exp.sha.141d2f7"
     * </pre><code>
     */
    public var buildMetadata(get, never):String;
    inline function get_buildMetadata() return switch (this) {
        case VersionEnum(maj, min, pat, pre, build): build;
    }

    /**
     * <pre><code>
     * >>> Version.of("1.0.0").hasBuildMetadata          == false
     * >>> Version.of("1.0.0-rc").hasBuildMetadata       == false
     * >>> Version.of("1.0.0-rc.1+001").hasBuildMetadata == true
     * >>> Version.of("1.0.0+001").hasBuildMetadata      == true
     * </pre></code>
     */
    public var hasBuildMetadata(get, never):Bool;
    inline function get_hasBuildMetadata() return buildMetadata != null;

    /**
     * <pre><code>
     * >>> new Version(1                 ).toString() == "1.0.0"
     * >>> new Version(1,2               ).toString() == "1.2.0"
     * >>> new Version(1,2,3             ).toString() == "1.2.3"
     * >>> new Version(1,2,3, "rc"       ).toString() == "1.2.3-rc"
     * >>> new Version(1,2,3, "rc", "001").toString() == "1.2.3-rc+001"
     * 
     * @param major non-negative integer
     * @param minor non-negative integer
     * @param patch non-negative integer
     * @param preRelease A series of dot (.) separated non-empty identifiers containing only ASCII alphanumerics and hyphen. Numeric identifiers MUST NOT include leading zeroes. 
     * @param buildMetadata A series of dot (.) separated non-empty identifiers containing only ASCII alphanumerics and hyphen.
     * </code></pre>
     */
    public function new(major:Int=0, minor:Int=0, patch:Int=0, preRelease:String=null, buildMetadata:String=null) {
        if (major < 0) throw '[$major] is an invalid $SEM_VER_SPEC major level.';
        if (minor < 0) throw '[$minor] is an invalid $SEM_VER_SPEC minor level.';
        if (patch < 0) throw '[$patch] is an invalid $SEM_VER_SPEC patch level.';
        if (!isValidPreRelease(preRelease)) throw '[$preRelease] is an invalid $SEM_VER_SPEC pre-release string.';
        if (!isValidBuildMetaData(buildMetadata)) throw '[$buildMetadata] is an invalid $SEM_VER_SPEC metadata string.';    
        this = VersionEnum(major, minor, patch, preRelease.isEmpty() ? null : preRelease, buildMetadata.isEmpty() ? null : buildMetadata);
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.0.0"   ).compareTo(null) == 1
     * >>> Version.of("1.0.0"   ).compareTo(Version.of("1.0.0")) == 0
     * >>> Version.of("1.0.1"   ).compareTo(Version.of("1.0.0")) == 10
     * >>> Version.of("1.1.0"   ).compareTo(Version.of("1.0.0")) == 100
     * >>> Version.of("2.0.0"   ).compareTo(Version.of("1.0.0")) == 1000
     * >>> Version.of("1.0.0"   ).compareTo(Version.of("1.0.1")) == -10
     * >>> Version.of("1.0.0"   ).compareTo(Version.of("1.1.0")) == -100
     * >>> Version.of("1.0.0"   ).compareTo(Version.of("2.0.0")) == -1000
     * >>> Version.of("1.0.0-rc").compareTo(Version.of("1.0.0-rc")) == 0
     * >>> Version.of("1.0.0"   ).compareTo(Version.of("1.0.0-rc")) == 1
     * >>> Version.of("1.0.0-rc").compareTo(Version.of("1.0.0"   )) == -1
     * >>> Version.of("1.0.0-rc.2" ).compareTo(Version.of("1.0.0-rc")) == 1
     * >>> Version.of("1.0.0-rc.2" ).compareTo(Version.of("1.0.0-rc.1")) == 1
     * >>> Version.of("1.0.0-rc.20").compareTo(Version.of("1.0.0-rc.3")) == 1
     * >>> Version.of("1.0.0+2" ).compareTo(Version.of("1.0.0+1"))        == 0
     * >>> Version.of("1.0.0+2" ).compareTo(Version.of("1.0.0+1"), false) == 1
     * >>> Version.of("1.0.0+2" ).compareTo(Version.of("1.0.0+1"), false) == 1
     * >>> Version.of("1.0.0+1" ).compareTo(Version.of("1.0.0+2"), false) == -1
     * </pre></code>
     * 
     * @return 0 if both instances represent the same version. A positive value if this version is greater and a negative value if this version is lower.
     */
    public function compareTo(other:Version, ignoreBuildMetadata=true):Int {
        if ((other:VersionData) == this) 
            return 0;
            
        if (other == null) 
            return 1;
        
        if (major > other.major) return 1000;
        if (major < other.major) return -1000;
        if (minor > other.minor) return 100;
        if (minor < other.minor) return -100;
        if (patch > other.patch) return 10;
        if (patch < other.patch) return -10;

        if (isPreRelease) {
            if (!other.isPreRelease)
                return -1;
                
            if (preRelease != other.preRelease) {
                
                // chunk based comparison
                var left = preRelease.split(SEP_IDENTIFIER);
                var right = other.preRelease.split(SEP_IDENTIFIER);
                var count = left.length < right.length ? left.length : right.length;
                for (i in 0...count) {
                    var leftId = left[i];
                    var rightId = right[i];
                    if (leftId == rightId) 
                        continue;
                    if (leftId.isDigits() && rightId.isDigits()) {
                        return leftId.toInt() < rightId.toInt() ? -1 : 1;
                    }
                    return Strings.compare(leftId, rightId);
                }

                if (left.length > count)
                    return 1;

                if (right.length > count)
                    return -1;
            }
        } else if (other.isPreRelease)
            return 1;

        if (!ignoreBuildMetadata)
            return Strings.compare(buildMetadata, other.buildMetadata);

        return 0;
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.0.0").equals(Version.of("1.0.0")) == true
     * >>> Version.of("1.0.0").equals(Version.of("1.0.0")) == true
     * </code></pre>
     */
    public function equals(other:Version, ignoreBuildMetadata=true) {
        return compareTo(other, ignoreBuildMetadata)  == 0;
    }
    
    /**
     * See http://semver.org/#spec-item-8
     * 
     * @return true if the major component of both versions is identical.
     */
    public function isCompatible(other:Version):Bool {
        if (other == null)
            return false;

        return major == other.major;
    }

    /**
     * <pre><code>
     * >>> Version.of("1.0.0").isGreaterThan(Version.of("1.0.0")) == false
     * >>> Version.of("1.0.1").isGreaterThan(Version.of("1.0.0")) == true
     * >>> Version.of("1.1.0").isGreaterThan(Version.of("1.0.0")) == true
     * >>> Version.of("2.0.0").isGreaterThan(Version.of("1.0.0")) == true
     * >>> Version.of("1.0.0").isGreaterThan(Version.of("1.0.1")) == false
     * >>> Version.of("1.0.0").isGreaterThan(Version.of("1.1.0")) == false
     * >>> Version.of("1.0.0").isGreaterThan(Version.of("2.0.0")) == false
     * >>> Version.of("1.0.0-rc").isGreaterThan(Version.of("1.0.0-rc")) == false
     * >>> Version.of("1.0.0"   ).isGreaterThan(Version.of("1.0.0-rc")) == true
     * >>> Version.of("1.0.0-rc").isGreaterThan(Version.of("1.0.0"   )) == false
     * </pre></code>
     */
    inline
    public function isGreaterThan(other:Version, ignoreBuildMetadata=true):Bool {
        return compareTo(other, ignoreBuildMetadata) > 0;
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.0.0").isGreaterThanOrEqualTo(Version.of("1.0.0")) == true
     * >>> Version.of("1.0.1").isGreaterThanOrEqualTo(Version.of("1.0.0")) == true
     * </pre></code>
     */
    inline
    public function isGreaterThanOrEqualTo(other:Version, ignoreBuildMetadata=true):Bool {
        return compareTo(other, ignoreBuildMetadata) >= 0;
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.0.0").isLessThan(Version.of("1.0.0")) == false
     * >>> Version.of("1.0.1").isLessThan(Version.of("1.0.0")) == false
     * >>> Version.of("1.1.0").isLessThan(Version.of("1.0.0")) == false
     * >>> Version.of("2.0.0").isLessThan(Version.of("1.0.0")) == false
     * >>> Version.of("1.0.0").isLessThan(Version.of("1.0.1")) == true
     * >>> Version.of("1.0.0").isLessThan(Version.of("1.1.0")) == true
     * >>> Version.of("1.0.0").isLessThan(Version.of("2.0.0")) == true
     * >>> Version.of("1.0.0-rc").isLessThan(Version.of("1.0.0-rc")) == false
     * >>> Version.of("1.0.0"   ).isLessThan(Version.of("1.0.0-rc")) == false
     * >>> Version.of("1.0.0-rc").isLessThan(Version.of("1.0.0"   )) == true
     * </pre></code>
     */
    inline
    public function isLessThan(other:Version, ignoreBuildMetadata=true):Bool {
        return compareTo(other, ignoreBuildMetadata) < 0;
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.0.0").isLessThanOrEqualTo(Version.of("1.0.0")) == true
     * >>> Version.of("1.0.0").isLessThanOrEqualTo(Version.of("1.0.1")) == true
     * </pre></code>
     */
    inline
    public function isLessThanOrEqualTo(other:Version, ignoreBuildMetadata=true):Bool {
        return compareTo(other, ignoreBuildMetadata) <= 0;
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.2.3"     ).nextMajor().toString() == "2.0.0"
     * >>> Version.of("1.2.3-rc.1").nextMajor().toString() == "2.0.0"
     * </code></pre>
     */
    inline
    public function nextMajor(keepBuildMetadata=false):Version {
        return VersionEnum(major + 1, 0, 0, null, keepBuildMetadata ? buildMetadata : null);
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.2.3"     ).nextMinor().toString() == "1.3.0"
     * >>> Version.of("1.2.3-rc.1").nextMinor().toString() == "1.3.0"
     * </code></pre>
     */
    inline
    public function nextMinor(keepBuildMetadata=false):Version {
        return VersionEnum(major, minor + 1, 0, null, keepBuildMetadata ? buildMetadata : null);
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.2.3"     ).nextPatch().toString() == "1.2.4"
     * >>> Version.of("1.2.3-rc.1").nextPatch().toString() == "1.2.4"
     * </code></pre>
     */
    inline
    public function nextPatch(keepBuildMetadata=false):Version {
        return VersionEnum(major, minor, patch + 1,null, keepBuildMetadata ? buildMetadata : null);
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.2.3-rc"      ).nextPreRelease().toString() == "1.2.3-rc.1"
     * >>> Version.of("1.2.3-rc.1"    ).nextPreRelease().toString() == "1.2.3-rc.2"
     * >>> Version.of("1.2.3-rc.1.foo").nextPreRelease().toString() == "1.2.3-rc.2.foo"
     * >>> Version.of("1.2.3-rc+2016" ).nextPreRelease().toString() == "1.2.3-rc.1"
     * >>> Version.of("1.2.3").nextPreRelease() throws '[1.2.3] is not a pre-release and therefore cannot be auto-incremented.'
     * </code></pre>
     * 
     * @return a new version instance with an incremented pre-release part and the build metadata part being reset
     * @throws Exception if <code>preRelease</code> invalid pre-release was specified.
     */
    public function nextPreRelease(keepBuildMetadata=false):Version {
        if (!isPreRelease) {
            var thisAsVersion:Version = this;
            throw '[$thisAsVersion] is not a pre-release and therefore cannot be auto-incremented.';
        }
        var ids = preRelease.split(".");
        var nextPreRelease = "";
        for (i in -ids.length...0) {
            var id = ids[-(i+1)];
            if (id.isDigits()) {
                ids[-(i+1)] = Strings.toString(id.toInt() + 1);
                nextPreRelease = ids.join(".");
                break;
            }
        }

        return VersionEnum(major, minor, patch, nextPreRelease.isEmpty() ? preRelease + ".1" : nextPreRelease, keepBuildMetadata ? buildMetadata : null);
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.0.0"         ).toString() == "1.0.0"
     * >>> Version.of("1.0.0-rc"      ).toString() == "1.0.0-rc"
     * >>> Version.of("1.0.0-rc.1+001").toString() == "1.0.0-rc.1+001"
     * >>> Version.of("1.0.0+001"     ).toString() == "1.0.0+001"
     * </pre></code>
     */
    @:to
    public function toString():String {
        return
            major + SEP_IDENTIFIER + minor + SEP_IDENTIFIER + patch + 
            (preRelease == null ? "" : SEP_PRERELEASE + preRelease) +
            (buildMetadata == null ? "" : SEP_METADATA + buildMetadata);
    }

    /**
     * <pre><code>
     * >>> Version.of("1.2.3-rc.1+001").withBuildMetadata("002").toString() == "1.2.3-rc.1+002"
     * >>> Version.of("1.2.3-rc.1+001").withBuildMetadata(""   ).toString() == "1.2.3-rc.1"
     * >>> Version.of("1.2.3-rc.1+001").withBuildMetadata(null ).toString() == "1.2.3-rc.1"
     * </code></pre>
     */
    public function withBuildMetadata(buildMetadata:String):Version {
        return switch (this) {
          case VersionEnum(maj, min, pat, pre, build): 
            build == buildMetadata ? this: VersionEnum(maj, min, pat, pre, buildMetadata.isEmpty() ? null : buildMetadata);              
        }
    }
    
    /**
     * <pre><code>
     * >>> Version.of("1.2.3-rc.1+001").withPreRelease("rc.2").toString() == "1.2.3-rc.2+001"
     * >>> Version.of("1.2.3-rc.1+001").withPreRelease(""    ).toString() == "1.2.3+001"
     * >>> Version.of("1.2.3-rc.1+001").withPreRelease(null  ).toString() == "1.2.3+001"
     * </code></pre>
     */
    public function withPreRelease(preRelease:String):Version {
        return switch (this) {
          case VersionEnum(maj, min, pat, pre, build): 
            pre == preRelease ? this : VersionEnum(maj, min, pat, preRelease.isEmpty() ? null : preRelease, build);              
        }
    }
}

@:noDoc @:dox(hide)
@:noCompletion
enum VersionData {
  VersionEnum(major:Int, minor:Int, patch:Int, preRelease:String, buildMetadata:String);
}
