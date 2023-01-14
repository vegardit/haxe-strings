/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 */
@:noDoc @:dox(hide)
@:noCompletion
class Types {

   public static inline function isInstanceOf(v:Dynamic, t:Dynamic):Bool {
      return
         #if (haxe_ver < 4.2)
         Std.is(v, t);
         #else
         Std.isOfType(v, t);
         #end
   }

}