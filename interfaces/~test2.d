/+
template AliasSymbol(alias A)
{
	alias A AliasSymbol;
}

class A{
//	int f()		{ return 10; }
	int f()const{ return 20; }
}
struct S
{
//	void f(T)(T a)
//	{
//		typeof(&T.f) fp = &T.f;
//	}
	template f(T)
	{
		pragma(msg, "in S.fun(T) -> T = ", T, ", ", typeof(&T.f));
//		alias AliasSymbol!(T.f) f;
//		pragma(msg, typeof(f), ", ", typeof(&f));
//		void f(T obj)
//		{
//		//	typeof(&f) fp = &f;
//		}
	}
	void g(T)(T obj)
	{
		alias AliasSymbol!(T.f) f;
		pragma(msg, typeof(f));
//		alias AliasSymbol!(&T.f) pf;
//		pragma(msg, typeof(&f));
		pragma(msg, typeof(&T.f));
	}
}

template h(T, string name)
{
/+	@property
	auto get_funcptr()
	{
		typeof(mixin("&T." ~ name)) fp = mixin("&T." ~ name);
		return fp;
	}+/
	enum typeof(mixin("&T." ~ name)) get_funcptr = mixin("&T." ~ name);
}

unittest
{
//	pragma(msg, typeof(&A.f));
	
	auto s = S();
//	s.f!A.f(new A());
//	s.g(new A());
	enum f = h!(A, "f").get_funcptr;
	pragma(msg, h!(A, "f").get_funcptr);
	writefln("f : %08X", f);
	
	auto a = new A();
	auto dg = composeDg(cast(void*)a, f);
	auto af = &a.f;
	assert(cast(void*)dg.ptr     == cast(void*)af.ptr);
	assert(cast(void*)dg.funcptr == cast(void*)af.funcptr);
	assert(dg() == 20);
	
}

import std.traits, std.typecons, std.typetuple;
/+
	template Drawable(T)
	{
		alias Interface!xd!q{
			int draw() const;
		} Drawable;
	}
+/
auto composeDg(T...)(T args)
{
//	pragma(msg, T[0], " -> ", Unqual!(T[0]));
//	static if( T.length>=2 )pragma(msg, T[1], " -> ", Unqual!(T[1]));
	
	static if( T.length==1 && is(Unqual!(T[0]) X == Tuple!(void*, U), U) ){
		auto tup = args[0];
		//alias typeof(tup.field[1]) U;
		
		auto ptr		= tup.field[0];
		auto funcptr	= tup.field[1];
		
	}else static if( T.length==2 && is(Unqual!(T[0]) == void*) && isFunctionPointer!(Unqual!(T[1])) ){
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
+/
