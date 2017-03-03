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
package hx.strings;

/**
 * Represents a character position (not byte index) in a String.
 * 
 * First character is at position 0.
 * 
 * <pre><code>
 * >>> CharPos.of(32)                  == 32
 * >>> CharPos.of(32) < 255            == true
 * >>> CharPos.of(32) < CharPos.of(50) == true
 * >>> CharPos.of(32) + " "            == "32 "
 * >>> " " + CharPos.of(32)            == " 32"
 * </code></pre>
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
abstract CharPos(Int) from Int to Int {
        
    public static function of(pos:Int):CharPos {
        return pos;
    }
    
    @:op(A + B)
    static function op_plus(ch:CharPos, other:CharPos):CharPos {
        return ch.toInt() + other.toInt();
    }

    @:op(++A)
    static function op_plus1_pre(ch:CharPos):CharPos;
    
    @:op(A++)
    static function op_plus1_post(ch:CharPos):CharPos;

    @:op(--A)
    static function op_minus1_pre(ch:CharPos):CharPos;
    
    @:op(A--)
    static function op_minus1_post(ch:CharPos):CharPos;
    
    @:op(A - B)
    static function op_minus(ch:CharPos, other:CharPos):CharPos;
    
    @:op(A >= B)
    static function op_gt_or_equals(ch:CharPos, other:CharPos):Bool;
    
    @:op(A <= B)
    static function op_lt_or_equals(ch:CharPos, other:CharPos):Bool;
    
    @:op(A == B)
    static function op_equals(ch:CharPos, other:CharPos):Bool;
    
    @:op(A > B)
    static function op_gt(ch:CharPos, other:CharPos):Bool;

    @:op(A < B)
    static function op_lt(ch:CharPos, other:CharPos):Bool;
    
    /**
     * <pre><code>
     * >>> CharPos.of(14)         == 14
     * >>> CharPos.of(14).toInt() == 14
     * </code></pre>
     */
    inline
    public function toInt():Int {
        return this;
    }
    
    /**
     * <pre><code>
     * >>> CharPos.of(14).toString() == "14"
     * </code></pre>
     */
    @:to
    inline
    public function toString():String {
        return Std.string(this);
    }
}
