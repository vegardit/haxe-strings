/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.ansi;

@:enum
abstract AnsiColor(Int) {
   final BLACK = 0;
   final RED = 1;
   final GREEN = 2;
   final YELLOW = 3;
   final BLUE = 4;
   final MAGENTA = 5;
   final CYAN = 6;
   final WHITE = 7;
   final DEFAULT = 9;
}
