/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class is not part of the API. Direct usage is discouraged.
 */
@:noDoc @:dox(hide)
@:noCompletion
class Arrays {

   /**
    * <pre><code>
    * >>> Arrays.first(["1", "2"]) == "1"
    * >>> Arrays.first([])         == null
    * >>> Arrays.first(null)       == null
    * </code></pre>
    */
   #if !hl
   // see https://github.com/HaxeFoundation/haxe/issues/6071
   inline
   #end
   public static function first<T>(items:Array<T>):Null<T>
      return (items == null || items.length == 0) ? null : items[0];


   /**
    * <pre><code>
    * >>> Arrays.unique(["1", "1", "2"]) == ["1", "2"]
    * </code></pre>
    */
   public static function unique<T>(items:Array<T>):Array<T> {
      final filtered = new Array<T>();

      for (i in items)
         if (filtered.indexOf(i) == -1) filtered.push(i);
      return filtered;
   }
}
