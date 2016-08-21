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
import hx.strings.internal.AnyAsString;
import hx.strings.internal.Either3;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:abstract
class AnsiWriter {

    public static function of(out:Either3<Output, StringBuf, StringBuilder>):AnsiWriter {
        return switch(out.value) {
            case a(output): new OutputAnsiWriter(output);
            case b(strBuf): new StringBufAnsiWriter(strBuf);
            case c(strBuilder): new StringBuilderAnsiWriter(strBuilder);
        };
    }
    
    public function write(str:AnyAsString):AnsiWriter throw "Not implemented";
    
    public function flush():AnsiWriter return this;
    
    /**
     * sets the given text attribute
     */
    public function attr(attr:AnsiTextAttribute) {
        write(Ansi.attr(attr));
        return this;
    }
    
    /**
     * set the text background color
     */
    public function bg(color:AnsiColor) {
        write(Ansi.bg(color));
        return this;
    }

    /**
     * Clears the screen and moves the cursor to the home position
     */
    public function clearScreen() {
        write(Ansi.clearScreen());
        return this;
    }

    /**
     * Clear all characters from current position to the end of the line including the character at the current position
     */
    public function clearLine() {
        return write(Ansi.clearLine());
    }

    public function cursor(cmd:AnsiCursor) {
        return write(Ansi.cursor(cmd));
    }
    
    /**
     * set the text foreground color
     */
    public function fg(color:AnsiColor) {
        return write(Ansi.fg(color));
    }
}

private class OutputAnsiWriter extends AnsiWriter {
    public var out(default, null):Output;  
    public function new(out:Output) this.out = out;
    override function write(str:AnyAsString) { out.writeString(str); return this; }
    override public function flush():AnsiWriter { out.flush(); return this } ;
}

private class StringBufAnsiWriter extends AnsiWriter {
    public var out(default, null):StringBuf;   
    public function new(out:StringBuf) this.out = out;
    override function write(str:AnyAsString) { out.add(str); return this; }
}

private class StringBuilderAnsiWriter extends AnsiWriter {
    public var out(default, null):StringBuilder;
    public function new(out:StringBuilder) this.out = out;
    override function write(str:AnyAsString) { out.add(str); return this; }
}
