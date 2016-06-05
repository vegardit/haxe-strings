/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE.txt file for details.
 */
package hx.strings;

/**
 * Return value of hx.strings.Strings#diff(String, String)
 * 
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class StringDiff {
    
    public function new() {
    }
    
    /**
     * position where the strings start to differ
     */
    public var pos:CharPos;
    
    /**
     * diff of the left string
     */
    public var left:String;
    
    /**
     * diff of the right string
     */
    public var right:String;
}
