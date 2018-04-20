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
@:forward
abstract OneOrMany<T>(Array<T>) from Array<T> to Array<T> {

    @:from
    inline
    static function fromSingle<T>(value:T):OneOrMany<T> {
        return [value];
    }
}
