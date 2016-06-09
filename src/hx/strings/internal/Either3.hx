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
abstract Either3<A, B, C>(_Either3<A, B, C>) {
	
    inline
	public function new(value:_Either3<A, B, C>) {
        this = value;
    }
	
	public var value(get,never):_Either3<A, B, C>;
    inline
    function get_value():_Either3<A, B, C> {
        return this;
    }

	@:from
    inline
    static function fromA<A,B,C>(value:A):Either3<A, B, C> {
        return new Either3(a(value));
    }
    
	@:from
    inline
    static function fromB<A,B,C>(value:B):Either3<A, B, C> {
        return new Either3(b(value));
    }
    
	@:from
    inline
    static function fromC<A,B,C>(value:C):Either3<A, B, C> {
        return new Either3(c(value));
    }
}

private enum _Either3<A, B, C> {
	a(v:A);
	b(v:B);
    c(v:C);
}
