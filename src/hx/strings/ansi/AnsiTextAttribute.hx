/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
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
   final RESET = 0;

   final INTENSITY_BOLD = 1;

   /**
    * Not widely supported.
    */
   final INTENSITY_FAINT = 2;

   /**
    * Not widely supported.
    */
   final ITALIC = 3;

   final UNDERLINE_SINGLE = 4;

   final BLINK_SLOW = 5;

   /**
    * Not widely supported.
    */
   final BLINK_FAST = 6;

   final NEGATIVE = 7;

   /**
    * Not widely supported.
    */
   final HIDDEN = 8;

   /**
    * Not widely supported.
    */
   final STRIKETHROUGH = 9;

   /**
    * Not widely supported.
    */
   final UNDERLINE_DOUBLE = 21;

   final INTENSITY_OFF = 22;

   final ITALIC_OFF = 23;

   final UNDERLINE_OFF = 24;

   final BLINK_OFF = 25;

   final NEGATIVE_OFF = 27;

   final HIDDEN_OFF = 28;

   final STRIKTHROUGH_OFF = 29;
}
