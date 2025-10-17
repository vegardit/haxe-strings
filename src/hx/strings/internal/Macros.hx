/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

import haxe.macro.*;

/**
 * <b>IMPORTANT:</b> This class is not part of the API. Direct usage is discouraged.
 */
@:noDoc @:dox(hide)
@:noCompletion
class Macros {

   static var __static_init = {
      #if (haxe_ver < 4.2)
         throw 'ERROR: Haxe 4.2.x or higher is required!';
      #end

      #if (php && !php7)
          throw 'ERROR: For PHP the php7 target is required!';
      #end
   };


   macro
   public static function addDefines() {
      final def = Context.getDefines();

      if (def.exists("java") && !def.exists("jvm")) {
         trace("[INFO] Setting compiler define 'java_src'.");
         Compiler.define("java_src");
      }
      return macro {}
   }


   macro
   public static function configureNullSafety() {
      haxe.macro.Compiler.nullSafety("hx.strings", StrictThreaded);
      return macro {}
   }


   /**
    * Embeds the given file as resource.
    *
    * Using <code>addResource("com/example/resources/items.txt", "Items");</code>
    * is the same as specifying the Haxe option <code>-resource com/example/resources/items.txt@Items</code>
    *
    * See http://haxe.org/manual/cr-resources.html for more details about embedding resources.
    */
   macro
   public static function addResource(filePath:String, ?resourceName:String):Expr {
      if (resourceName == null || resourceName.length == 0)
         resourceName = filePath;

      if (!sys.FileSystem.exists(filePath)) {
         for (cp in Context.getClassPath()) {
            final path = cp + filePath;
            if (sys.FileSystem.exists(path)) {
               filePath = path;
               break;
            }
         }
      }
      trace('[INFO] Embedding file [$filePath] as resource with name [$resourceName]...');
      Context.addResource(resourceName, sys.io.File.getBytes(filePath));

      // return a no-op expression
      return macro {};
   }


   /**
    * Implements assignment destructuring, see https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment
    *
    * Usage:
    * <pre><code>
    * Macros.unpack([a,b,c] = ["1", "2", "3"]);
    * trace(a);
    *
    * // or
    * var list = ["1", "2", "3"];
    * Macros.unpack([a,b,c] = list);
    * trace(a);
    *
    * // or
    * Macros.unpack([prefix,value] = str.split(":"));
    * trace(prefix);
    * </code></pre>
    */
   macro
   public static function unpack(e:Expr) {
      final assignments = new Array<Expr>();
      switch(e.expr) {
         case EBinop(OpAssign, varsExpr, valuesExpr):
            final varNames = new Array<String>();
            switch varsExpr {
               case macro $a{varDecls}:
                  for (varDecl in varDecls) {
                     switch(varDecl) {
                        case macro $i{varName}:
                           varNames.push(varName);
                        default:
                           Context.error("Invalid variable name.", varDecl.pos);
                     }
                  }
               default:
                  Context.error("Array of variable names expected.", varsExpr.pos);
            }

            var idx = -1;
            switch (valuesExpr.expr) {
               case ECall(_):
                  assignments.push(macro @:mergeBlock {
                     final __unpack_return_values = $valuesExpr;
                  });
                  for (varName in varNames) {
                     idx++;
                     assignments.push(macro @:mergeBlock {
                        var $varName = __unpack_return_values[$v{idx}];
                     });
                  };

               case EArrayDecl(values):
                  for (varName in varNames) {
                     final value = values[++idx];
                     assignments.push(macro @:mergeBlock {
                        final $varName=${value};
                     });
                  };

               case EConst(CIdent(refName)):
                  for (varName in varNames) {
                     idx++;
                     assignments.push(macro @:mergeBlock {
                        final $varName = $i{refName}[$v{idx}];
                     });
                  };

               default:
                  Context.error("Expected a variable reference, an array or a function call.", valuesExpr.pos);
            }

         default:
             Context.error("Assignment operator = is missing!", e.pos);
      }

      return macro @:mergeBlock $b{assignments};
   }
}
