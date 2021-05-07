/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings;

/**
 * <pre><code>
 * >>> (function(){var str:AnyAsString = 1;      return str; })() == "1"
 * >>> (function(){var str:AnyAsString = true;   return str; })() == "true"
 * >>> (function(){var str:AnyAsString = "cat";  return str; })() == "cat"
 * >>> (function(){var str:AnyAsString = [1, 2]; return str; })() == "[1,2]"
 * </code></pre>
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
abstract AnyAsString(String) from String to String {

   @:from
   inline
   static function fromBool(value:Bool):AnyAsString
      return value ? "true" : "false";

   @:from
   inline
   static function fromAny(value:Dynamic):AnyAsString
      return Std.string(value);
}
