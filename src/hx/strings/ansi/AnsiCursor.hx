/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.ansi;

enum AnsiCursor {
   GoToHome;
   GoToPos(line:Int, column:Int);
   MoveUp(lines:Int);
   MoveDown(lines:Int);
   MoveRight(columns:Int);
   MoveLeft(columns:Int);
   SavePos;
   RestorePos;
}
