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
package hx.strings.internal;

/**
  * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Bits {
    
    /**
     * <pre><code>
     * >>> Bits.clearBit(5, 1) == 4
     * </code></pre>
     */
    inline
    public static function clearBit(num:Int, bitPos:Int):Int {
        return num & ~(1 << (bitPos - 1));
    }
    
    /**
     * <pre><code>
     * >>> Bits.setBit(5, 2) == 7
     * </code></pre>
     */
    inline
    public static function setBit(num:Int, bitPos:Int):Int {
        return num | 1 << (bitPos -1);
    }
    
    /**
     * <pre><code>
     * >>> Bits.toggleBit(5, 1) == 4
     * </code></pre>
     */
    inline
    public static function toggleBit(num:Int, bitPos:Int):Int {
        return num ^ 1 << (bitPos - 1);
    }
    
    /**
     * <pre><code>
     * >>> Bits.getBit(5, 1) == 1
     * >>> Bits.getBit(5, 2) == 0
     * >>> Bits.getBit(5, 3) == 1
     * >>> Bits.getBit(5, 4) == 0
     * </code></pre>
     */
    inline
    public static function getBit(num:Int, bitPos:Int):Int {
        return (num >> (bitPos - 1)) & 1;
    }
}
