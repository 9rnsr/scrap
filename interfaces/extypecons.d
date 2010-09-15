module extypecons;

import std.traits;


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
		
		ReturnType!U delegate(ParameterTypeTuple!U) dg;
		dg.ptr		= tup.field[0];
		dg.funcptr	= tup.field[1];
		return dg;
	}else static if( T.length==2 && is(T[0] == void*) && isFunctionPointer!(T[1]) ){
		auto ptr		= args[0];
		auto funcptr	= args[1];
		alias T[1] U;
		
		ReturnType!U delegate(ParameterTypeTuple!U) dg;
		dg.ptr		= ptr;
		dg.funcptr	= funcptr;
		return dg;
	}else{
		static assert(0, T.stringof);
	}
}
