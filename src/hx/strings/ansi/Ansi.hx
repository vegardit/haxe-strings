/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
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
package hx.strings.ansi;

import haxe.io.Output;
import hx.strings.StringBuilder;
import hx.strings.ansi.AnsiColor;
import hx.strings.ansi.AnsiTextAttribute;
import hx.strings.internal.AnyAsString;
import hx.strings.internal.Either3;

/**
 * https://en.wikipedia.org/wiki/ANSI_escape_code
 * http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/c327.html
 * http://ascii-table.com/ansi-escape-sequences.php
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Ansi {

    /**
     * ANSI escape sequence header
     */
    public static inline var ESC = "\x1B[";
    
    /**
     * sets the given text attribute
     */
    inline
    public static function attr(attr:AnsiTextAttribute):String {
        
        return ESC + (attr) + "m";
    }
    
    /**
     * set the text background color
     * 
     * <pre><code>
     * >>> Ansi.bg(RED) == "\x1B[41m"
     * </code></pre>
     */
    inline
    public static function bg(color:AnsiColor):String {
        return ESC + (40 + color) + "m";
    }
    
    /**
     * <pre><code>
     * >>> Ansi.cursor(MoveUp(5)) == "\x1B[5A"
     * >>> Ansi.cursor(GoTo(5,5)) == "\x1B[5;5H"
     * </code></pre>
     */
    inline
    public static function cursor(cmd:AnsiCursor):String {
        return switch(cmd) {
            case GoTo(line, column): Ansi.ESC + line + ";" + column + "H";
            case GoToHome: Ansi.ESC + "H";
            case MoveUp(lines): Ansi.ESC + lines + "A";
            case MoveDown(lines): Ansi.ESC + lines + "B";
            case MoveRight(columns): Ansi.ESC + columns + "C";
            case MoveLeft(columns): Ansi.ESC + columns + "D";
            case SavePosition: Ansi.ESC + "s";
            case RestorePosition: Ansi.ESC + "s";
        }
    }

    /**
     * Clears the screen and moves the cursor to the home position
     */
    inline
    public static function clearScreen():String {
        return ESC + "2J";
    }

    /**
     * Clear all characters from current position to the end of the line including the character at the current position
     */
    inline
    public static function clearLine():String {
        return ESC + "K";
    }

    /**
     * set the text foreground color
     * 
     * <pre><code>
     * >>> Ansi.fg(RED) == "\x1B[31m"
     * </code></pre>
     */
    inline
    public static function fg(color:AnsiColor):String {
        return ESC + (30 +color) + "m";
    }

    /**
     * <pre><code>
     * >>> (switch(1){default:var sb = new StringBuf(); Ansi.writer(sb).fg(GREEN).attr(ITALIC).write("Hello").attr(RESET); sb;}).toString() == "\x1B[32m\x1B[3mHello\x1B[0m"
     * </code></pre>
     */
    inline
    public static function writer(out:Either3<Output, StringBuf, StringBuilder>):AnsiWriter<Dynamic> {
        return AnsiWriter.of(out);
    }
}
