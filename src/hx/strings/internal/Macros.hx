/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

import haxe.macro.*;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
class Macros {

   static var __static_init = {
      #if (haxe_ver <= 4)
         throw 'ERROR: As of haxe-strings 6.0.0, Haxe 4.x or higher is required!';
      #end

      #if (php && !php7)
          throw 'ERROR: As of haxe-strings 6.0.0, for PHP the php7 target is required!';
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
    * Usage:
    * <pre><code>
    * if(Macros.is(obj, (foo:Foo)) {
    *    foo.bar();
    * }
    *
    * // or
    * if(Macros.is(obj, (foo:Foo<Int>)) {
    *    foo.bar();
    * }
    * </code></pre>
    *
    * Also works with abstract types in constrast to <code>Std.is()</code>.
    * Does not yet work with classes with private visiblity.
    *
    * Requires Haxe 3.3 or higher because of https://github.com/HaxeFoundation/haxe/issues/5249
    */
   macro
   public static function is(value:Expr, assignableTo:Expr) {
      return switch assignableTo {
         case macro ($i{targetVarName}:$targetVarComplexType):
            var targetTypeName:String = switch(ComplexTypeTools.toType(targetVarComplexType)) {
               // if we target an abstract, resolve the underlying type because Std.is() does not support abstracts directly
               case TAbstract(abstractTypeRef, params):

                  switch(TypeTools.toComplexType(abstractTypeRef.get().type)) {

                     // in case we have a TPath we build the fully qualified name manually, because TypeTools.toString()
                     // creates a wrong path for sub-types of modules (it ommits the module name)
                     // e.g. generates: hx.strings.collection.SortedStringMapImpl
                     //     instead of: hx.strings.collection.SortedStringMap.SortedStringMapImpl
                     case TPath(p):
                        var path = p.pack;
                        path.push(p.name);
                        if (p.sub != null)
                           path.push(p.sub);
                        path.join(".");
                     default:
                        TypeTools.toString(abstractTypeRef.get().type);
                  }

               default:
                  ComplexTypeTools.toString(targetVarComplexType);
            }

            final idxGenerics = targetTypeName.indexOf("<", 1);
            if(idxGenerics > -1)  targetTypeName = targetTypeName.substring(0, idxGenerics);

            var targetTypeExpr = MacroStringTools.toFieldExpr(targetTypeName.split("."));

            macro @:mergeBlock {
               var $targetVarName:$targetVarComplexType = Std.is($value, ${targetTypeExpr}) ? cast $value : null;
               $i{targetVarName} != null;
            }

         default:
           Context.error('Unsupported expression. Expecting e.g. "(myvar: MyType)"', assignableTo.pos);
      };
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
