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
package hx.strings.internal;

import haxe.macro.*;
Type
/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
class Macros {

    static var __static_init = {
        #if (php7 && haxe_ver <= "3.4.0")
            throw 'For the PHP7 target a Haxe version newer than 3.4.0 is required because of bugs in the earlier PHP7 target implementation.';
        #end
    };

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
                var path = cp + filePath;
                if (sys.FileSystem.exists(path)) {
                    filePath = path;
                    break;
                }
            }
        }
        trace('Embedding file [$filePath] as resource with name [$resourceName]...');
        Context.addResource(resourceName, sys.io.File.getBytes(filePath));

        // return a no-op expression
        return macro {};
    }

    /**
     * Usage:
     * <pre><code>
     * if(Macros.is(obj, (foo:Foo)) {
     *     foo.bar();
     * }
     *
     * // or
     * if(Macros.is(obj, (foo:Foo<Int>)) {
     *     foo.bar();
     * }
     *
     * </code></pre>
     *
     * Also works with abstract types in constrast to <code>Std.is()</code>.
     * Does not yet work with classes with private visiblity.
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
                                path.join('.');
                            default:
                                TypeTools.toString(abstractTypeRef.get().type);
                        }

                    default:
                        ComplexTypeTools.toString(targetVarComplexType);
                }

                var idxGenerics = targetTypeName.indexOf('<', 1);
                if(idxGenerics > -1)  targetTypeName = targetTypeName.substring(0, idxGenerics);

                var targetTypeExpr = MacroStringTools.toFieldExpr(targetTypeName.split('.'));

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
        var assignments = new Array<Expr>();
        switch(e.expr) {
            case EBinop(OpAssign, varsExpr, valuesExpr):
                var varNames = new Array<String>();
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
                            var __unpack_return_values = $valuesExpr;
                        });
                        for (varName in varNames) {
                            idx++;
                            assignments.push(macro @:mergeBlock {
                                var $varName = __unpack_return_values[$v{idx}];
                            });
                        };

                    case EArrayDecl(values):
                        for (varName in varNames) {
                            var value = values[++idx];
                            assignments.push(macro @:mergeBlock {
                                var $varName=${value};
                            });
                      };

                    case EConst(CIdent(refName)):
                        for (varName in varNames) {
                            idx++;
                            assignments.push(macro @:mergeBlock {
                                var $varName = $i{refName}[$v{idx}];
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
