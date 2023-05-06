/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 */
#if (haxe_ver < 4.3) @:enum #else enum #end
abstract TriState(Null<Bool>) from Null<Bool> to Null<Bool> {
   final TRUE = true;
   final FALSE = false;
   final UNKNOWN = null;
}
