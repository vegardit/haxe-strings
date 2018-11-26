/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
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
class OS {

    #if js
    static var isNodeJS    = untyped __js__("(typeof process !== 'undefined') && (typeof process.release !== 'undefined') && (process.release.name === 'node')");
    static var isPhantomJS = untyped __js__("!!(typeof window != 'undefined' && window.callPhantom && window._phantom)");
    #end

    public static var isWindows(default, never):Bool = {
        #if flash
        var os = flash.system.Capabilities.os;
        #elseif js
        var os = isNodeJS ? untyped __js__("process.platform") : isPhantomJS ? untyped __js__("require('system').os.name") : js.Browser.navigator.oscpu;
        #else
        var os = Sys.systemName();
        #end
        ~/win/i.match(os);
    }
}
