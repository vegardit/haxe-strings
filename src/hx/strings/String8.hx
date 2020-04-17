/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings;

using hx.strings.Strings;

#if !macro
/**
 * Implemented as an abstract type over String.
 *
 * All exposed methods are UTF-8 compatible and have consistent behavior across platforms.
 *
 * The methods are auto generated based on the static methods provided by the `hx.strings.Strings` class.
 *
 * Example usage:
 * <pre>
 * var str:String8 = "myString";
 * str.length();  // --> this is not the Haxe internal `length()` method but an implementation that with UTF-8 strings across platforms
 * </pre>
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:build(hx.strings.String8.String8Generator.generateMethods())
abstract String8(String) from String to String {

   /**
    * String#length variant with cross-platform UTF-8 support.
    */
   public var length(get, never):Int;
   inline function get_length():Int
      return Strings.length8(this);
}

#else

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

@:noCompletion
@:dox(hide)
class String8Generator {

   macro
   public static function generateMethods():Array<Field> {
      var contextFields = Context.getBuildFields();
      var contextPos = Context.currentPos();

      var delegateClass:ClassType = switch(Context.getType("hx.strings.Strings")) {
         case TInst(t, _): t.get();
         default: Context.fatalError("hx.strings.Strings isn't a class.", contextPos);
      }

      for (delegateField in delegateClass.statics.get()) {
         if (!delegateField.isPublic)
            continue;

         if (delegateField.name == "length8")
            continue;

         switch(delegateField.type) {
            case TFun(args, ret):
               if (args.length == 0)
                  continue;

               // ignore methods whose first argument doesn't take a string
               switch(args[0].t) {
                  case TInst(t, params):
                     if ("String" != t.toString())
                        continue;
                  case TAbstract(t, params):
                     if ("hx.strings.internal.AnyAsString" != t.toString())
                        continue;
                  default:
               }

               /*
                * generate method args declaration of delegating method
                */
               var delegateTFunc:TFunc = delegateField.expr() == null ? null : switch(delegateField.expr().expr) {
                  case TFunction(func): func;
                  default: Context.fatalError("Should never be reached.", contextPos);
               };
               var generatedArgs = new Array<FunctionArg>();
               var delegateArgs = ["this"];
               for (i in 1...args.length) {
                  var defaultValue = delegateTFunc == null ? null :
                     #if (haxe_ver < 4)
                     // delegateTFunc.args[i].value in Haxe 3 is TConstant
                     switch(delegateTFunc.args[i].value) {
                     #else
                     // delegateTFunc.args[i].value in Haxe 4 Preview 5 is TypedExpr
                     delegateTFunc.args[i].value == null ? null :
                     switch(delegateTFunc.args[i].value.expr) {
                        case TConst(constant):
                           switch(constant) {
                     #end
                              case TBool(val):   Context.makeExpr(val, contextPos);
                              case TString(val): Context.makeExpr(val, contextPos);
                              case TFloat(val):  Context.makeExpr(val, contextPos);
                              case TNull:        Context.makeExpr(null, contextPos);
                              case TInt(val):
                                 switch(delegateTFunc.args[i].v.t) {
                                    case TAbstract(t, params):
                                       if (t.toString() == "hx.strings.StringNotFoundDefault") {
                                          switch(val) {
                                             case 1: macro { StringNotFoundDefault.NULL; };
                                             case 2: macro { StringNotFoundDefault.EMPTY; };
                                             case 3: macro { StringNotFoundDefault.INPUT; };
                                             default: null;
                                          }
                                       } else
                                          Context.makeExpr(val, contextPos);
                                    default:
                                       Context.makeExpr(val, contextPos);
                                 }
                               default: null;
                     #if (haxe_ver >= 4)
                           }
                        default: null;
                     }
                     #else
                     }
                     #end
                  var arg = args[i];
                  generatedArgs.push({
                     name: arg.name,
                     opt: arg.opt,
                     value: defaultValue,
                     type: Context.toComplexType(arg.t)
                  });
                  delegateArgs.push(arg.name);
               }

               /*
                * generate generic type declaration of delegating method
                */
               var generatedGenericParams = new Array<TypeParamDecl>();
               for (param in delegateField.params) {
                  generatedGenericParams.push({name: param.name});
               }

               /*
                * generate full declaration of delegating method
                */
               var delegateName = delegateField.name;
               contextFields.push({
                  name: delegateName.endsWith("8") ? delegateName.substringBeforeLast("8") : delegateName,
                  doc: delegateField.doc,
                  meta: delegateField.meta.get(),
                  access: [APublic, AInline],
                  kind: FFun({
                      args: generatedArgs,
                      params: generatedGenericParams,
                      ret: Context.toComplexType(ret),
                      expr: Context.parseInlineString("return Strings." + delegateName + "(" + delegateArgs.join(",") + ")", contextPos)
                  }),
                  pos: contextPos
               });

               #if debug
               trace('[DEBUG] Generated String8#$delegateName(${delegateArgs.slice(1).join(", ")})');
               #end
            default:
               continue;
         }
      }

      return contextFields;
   }
}
#end

