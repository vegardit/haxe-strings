/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:enum
abstract TriState(Null<Bool>) from Null<Bool> to Null<Bool> {
    var TRUE = true;
    var FALSE = false;
    var UNKNOWN = null;
}
