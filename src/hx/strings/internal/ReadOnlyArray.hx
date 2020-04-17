/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

/**
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward(concat, filter, iterator, indexOf, join, lastIndexOf, length, toString)
abstract ReadOnlyArray<T>(Array<T>) from Array<T> {

   @:arrayAccess
   inline function get(i:Int):T return this[i];
}
