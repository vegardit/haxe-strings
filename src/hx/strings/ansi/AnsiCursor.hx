/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.strings.ansi;

/**
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
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

