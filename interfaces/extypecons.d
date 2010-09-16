module extypecons;

import std.traits, std.typecons;


/// 
auto decomposeDg(T)(T dg) if( is(T == delegate) )
{
	auto r = tuple(dg.ptr, dg.funcptr);
	return r;
}

/// 
auto composeDg(T...)(T args)
{
	static if( T.length==1 && is(T[0] X == Tuple!(void*, U), U) ){
		auto tup = args[0];
		//alias typeof(tup.field[1]) U;
		
		auto ptr		= tup.field[0];
		auto funcptr	= tup.field[1];
		
	}else static if( T.length==2 && is(T[0] == void*) && isFunctionPointer!(T[1]) ){
		auto ptr		= args[0];
		auto funcptr	= args[1];
		alias T[1] U;
		
	}else{
		static assert(0, T.stringof);
	}
	
	ReturnType!U delegate(ParameterTypeTuple!U) dg;
	dg.ptr		= ptr;
	dg.funcptr	= cast(typeof(dg.funcptr))funcptr;
	return dg;
}

unittest
{
	int dg(int n){
		return n*10;
	}
	
	auto t = decomposeDg(&dg);
	assert(composeDg(t)(2) == 20);
	assert(composeDg(t.field[0], t.field[1])(5) == 50);
}
