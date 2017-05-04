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

import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;

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
            throw "For the PHP7 target a Haxe version newer than 3.4.0 is required because of bugs in the earlier PHP7 target implementation.";
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
    
    macro 
    public static function is(value:Expr, assignableTo:Expr) {
        return 
            switch assignableTo {
                case macro ($i{varName}: $varType):
                    var varTypeName = haxe.macro.ComplexTypeTools.toString(varType);
                    var idxGenerics = varTypeName.indexOf("<", 1);
                    if(idxGenerics > -1)
                        varTypeName = varTypeName.substring(0, idxGenerics); 
                    macro @:mergeBlock {
                        var $varName:$varType = Std.is($value, $i{varTypeName}) ? cast $value : null;
                        $i{varName} != null;
                    }
                default:
                  throw "Unsupported expression. Expecting e.g. '(myvar: MyType)'";
            }
    }
}
