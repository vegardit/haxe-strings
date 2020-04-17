/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
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
   public static function first<T>(items:Array<T>):T
      return (items == null || items.length == 0) ? null : items[0];


   /**
    * <pre><code>
    * >>> Arrays.unique(["1", "1", "2"]) == ["1", "2"]
    * </code></pre>
    */
   public static function unique<T>(items:Array<T>):Array<T> {
      var filtered = new Array<T>();

      for (i in items)
         if (filtered.indexOf(i) == -1) filtered.push(i);
      return filtered;
   }
}
