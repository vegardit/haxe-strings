/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

import haxe.CallStack;

class Exception {

   static inline final INDENT = #if java "\t" #else "  " #end;

   inline
   public static function capture(ex:Dynamic) {
      return new Exception(ex);
   }


   public final cause:Dynamic;
   public final causeStackTrace:Array<StackItem>;


   function new(cause:Dynamic) {
      this.cause = cause;
      this.causeStackTrace = CallStack.exceptionStack();
   }


   #if (!python) inline #end
   public function rethrow() {
      #if neko
         neko.Lib.rethrow(cause);  // Neko has proper support
      #elseif python
         //python.Syntax.pythonCode("raise"); // rethrows the last but not necessarily the captured exception
         python.Syntax.code('raise Exception(self.toString()) from None');
      #else
         // cpp.Lib.rethrow(cause);  // swallows stacktrace
         // cs.Lib.rethrow(this);    // throw/rethrow swallows complete stacktrace
         // js.Lib.rethrow();        // rethrows the last but not necessarily the captured exception
         // php.Lib.rethrow(cause);  // swallows stacktrace
         throw this.toString();
      #end
   }


   #if python @:keep #end
   public function toString():String {
      final sb = new StringBuf();
      sb.add("rethrown exception:\n");
      sb.add(INDENT); sb.add("--------------------\n");
      sb.add(INDENT); sb.add("| Exception : "); sb.add(cause); sb.add("\n");
      #if lua @:nullSafety(Off) #end
      for (item in CallStack.toString(causeStackTrace).split("\n")) {
         if (item == "") continue;
         sb.add(INDENT);
         sb.add(StringTools.replace(item, "Called from", "| at"));
         sb.add("\n");
      }
      sb.add(INDENT); sb.add("--------------------");
      return sb.toString();
   }
}