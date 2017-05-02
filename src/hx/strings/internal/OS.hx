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

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
class OS {

    #if js
    static var isNodeJS = untyped __js__("(typeof process !== 'undefined') && (process.release.name === 'node')");
    #end
    
    public static var isWindows(default, never):Bool = {
        #if flash
        var os = flash.system.Capabilities.os;
        #elseif js
        var os = isNodeJS ? untyped __js__("process.platform") : js.Browser.navigator.oscpu;
        #else
        var os = Sys.systemName();
        #end
        ~/windows/i.match(os);
    }
}
