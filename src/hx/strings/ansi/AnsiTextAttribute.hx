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

/**
 * https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:enum
abstract AnsiTextAttribute(Int) {
    
    /**
     * All colors/text-attributes off
     */
    var RESET = 0;
    
    var INTENSITY_BOLD = 1;
    
    /**
     * Not widely supported.
     */
    var INTENSITY_FAINT = 2;
    
    /**
     * Not widely supported.
     */
    var ITALIC = 3;
    
    var UNDERLINE_SINGLE = 4;
    
    var BLINK_SLOW = 5;
    
    /**
     * Not widely supported.
     */
    var BLINK_FAST = 6;
    
    var NEGATIVE = 7;
    
    /**
     * Not widely supported.
     */
    var HIDDEN = 8;
    
    /**
     * Not widely supported.
     */
    var STRIKETHROUGH = 9;
    
    /**
     * Not widely supported.
     */
    var UNDERLINE_DOUBLE = 21;
    
    var INTENSITY_OFF = 22;

    var ITALIC_OFF = 23;
        
    var UNDERLINE_OFF = 24;
    
    var BLINK_OFF = 25;
    
    var NEGATIVE_OFF = 27;
    
    var HIDDEN_OFF = 28;
    
    var STRIKTHROUGH_OFF = 29;
}
