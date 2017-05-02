/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
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
class AnsiWriter<T> {

    public var out(default, null):T;
    
    public static function of(out:Either3<Output, StringBuf, StringBuilder>):AnsiWriter<Dynamic> {
        return switch(out.value) {
            case a(output): new OutputAnsiWriter(output);
            case b(strBuf): new StringBufAnsiWriter(strBuf);
            case c(strBuilder): new StringBuilderAnsiWriter(strBuilder);
        };
    }
    
    /**
     * flushes any buffered data
     */
    public function flush() return this;
    
    public function write(str:AnyAsString):AnsiWriter<T> throw "Not implemented";
    
    /**
     * sets the given text attribute
     */
    public function attr(attr:AnsiTextAttribute) {
        return write(Ansi.attr(attr));
    }
    
    /**
     * set the text background color
     */
    public function bg(color:AnsiColor) {
        return write(Ansi.bg(color));
    }

    /**
     * Clears the screen and moves the cursor to the home position
     */
    public function clearScreen() {
        return write(Ansi.clearScreen());
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

@:noDoc @:dox(hide)
private class OutputAnsiWriter extends AnsiWriter<Output> {
    public function new(out:Output) this.out = out;
    override public function flush() { out.flush(); return this; } ;
    override public function write(str:AnyAsString) { out.writeString(str); return this; }
}

@:noDoc @:dox(hide)
private class StringBufAnsiWriter extends AnsiWriter<StringBuf> {
    public function new(out:StringBuf) this.out = out;
    override public function write(str:AnyAsString) { out.add(str); return this; }
}

@:noDoc @:dox(hide)
private class StringBuilderAnsiWriter extends AnsiWriter<StringBuilder> {
    public function new(out:StringBuilder) this.out = out;
    override public function write(str:AnyAsString) { out.add(str); return this; }
}
