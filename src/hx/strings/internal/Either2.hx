/*
 * Copyright (c) 2016 Vegard IT GmbH, http://vegardit.com
 * 
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE.txt file for details.
 */
package hx.strings.internal;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
abstract Either2<A,B>(_Either2<A,B>) {
	
    inline
	public function new(value:_Either2<A,B>) {
        this = value;
    }
	
	public var value(get,never):_Either2<A,B>;
    inline
    function get_value():_Either2<A,B> {
        return this;
    }

	@:from
    inline
    static function fromA<A,B>(value:A):Either2<A,B> {
        return new Either2(a(value));
    }
    
	@:from
    inline
    static function fromB<A,B>(value:B):Either2<A,B> {
        return new Either2(b(value));
    }
}

private enum _Either2<A, B> {
	a(v:A);
	b(v:B);
}
