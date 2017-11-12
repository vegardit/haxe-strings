/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings;

import haxe.macro.*;

/**
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class StringMacros {

    /**
     * Returns the content of the multi-line comment between the methods invocation brackets ( and ).
     * Variables with the notation ${varName} are not interpolated.
     *
     * E.g.
     *
     * <pre><code>
     * var myString = StringMacros.multiline(/*
     * This is a multi-line string wrapped in a comment.
     * Special characters like ' or " don't need to be escaped.
     * Variables ${blabla} are not interpolated.
     * &#42;/
     * </code></pre>
     *
     * @param interpolationPrefix if set, e.g. to "$" Haxe variable interpolation for $var and ${var} be performed
     */
    macro
    public static function multiline(interpolationPrefix:String = "", trimLeft:Bool = true):ExprOf<String> {
        var pos = Context.currentPos();

        var posInfo = Context.getPosInfos(pos);
        var str:String = sys.io.File.getContent(Context.resolvePath(posInfo.file)).substring(posInfo.min, posInfo.max);

        var start = str.indexOf("/*");
        if(start < 0) Context.error("Cannot find multi-line comment start marker '/*'.", pos);

        var end = str.lastIndexOf("*/");
        if(end < 0) Context.error("Cannot find multi-line comment end marker '*/'.", pos);
        if(end < start) Context.error("Multi-line comment end marker most be placed after start marker.", pos);

        var comment = str.substring(start + 2, end);

        comment = Strings.trimRight(comment, "\t ");
        comment = Strings.replaceAll(comment, "\r", "");
        if (comment.length > 0 && comment.charCodeAt(0) == 10)
            comment = comment.substr(1);

        if(trimLeft) {
            var lines:Array<String> = comment.split("\n");
            var indent = 9999;
            for (l in lines) {
                for (i in 0...l.length) {
                    if (l.charCodeAt(i) != 32) {
                        if (i < indent) {
                            indent = i;
                            break;
                        }
                    }
                }
            }
            if (indent > 0) {
                comment = [ for (l in lines) l.substr(indent) ].join("\n");
            }
        }

        if (Strings.isNotEmpty(interpolationPrefix) && Strings.contains(comment, interpolationPrefix)) {
            if (interpolationPrefix != "$") {
                comment = Strings.replaceAll(comment, interpolationPrefix + interpolationPrefix, "THIS_IS_ESCAPED");
                comment = Strings.replaceAll(comment, interpolationPrefix, "THIS_IS_TO_INTERPOLATE");
                comment = Strings.replaceAll(comment, "$", "$$");
                comment = Strings.replaceAll(comment, "THIS_IS_ESCAPED", Strings.replaceAll(interpolationPrefix, "$", "$$"));
                comment = Strings.replaceAll(comment, "THIS_IS_TO_INTERPOLATE", "$");
            }
            return MacroStringTools.formatString(comment, pos);
        }

        return macro @:pos(pos) $v{comment};
    }
}

