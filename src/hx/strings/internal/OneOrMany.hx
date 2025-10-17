/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class is not part of the API. Direct usage is discouraged.
 */
@:noDoc @:dox(hide)
@:noCompletion
@:forward
abstract OneOrMany<T>(Array<T>) from Array<T> to Array<T> {

   @:from
   inline
   static function fromSingle<T>(value:T):OneOrMany<T>
      return [value];
}
