/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
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

