/**
 * Boost.InterfacesのD言語実装例
 * Written by Kenji Hara(9rnsr)
 * License: public domain
 */
/**
	実装改良点：
		delegate.ptrは同じobjのメンバ関数から取ったものなら常に同じか？
		継承関係(多層、class/interface)に対して変化しないか？
		
		Interfaceという名前
		object.dに同名の構造体がある
	
	
 */
module interfaces;

import std.traits, std.typecons, std.typetuple;
import std.functional;

//import std.stdio, std.string;

version = SharedSupport;
//version = ImmutableSupport;


/// 
struct Interface(string def)
{
protected:	//privateだとなぜか駄目
	static assert(
		__traits(compiles, {
			mixin("interface I { " ~ def ~ "}");
		}),
		"invalid interface definition");
	mixin("interface I { " ~ def ~ "}");

private:
	alias MakeSignatureTbl!(I, 0).result allNames;
	alias MakeSignatureTbl!(I, 1).result allFpSigs;
	alias MakeSignatureTbl!(I, 2).result allDgSigs;
	
	void*		objptr;
	allFpSigs	funtbl;

	static bool startWith(string s, string pattern) pure
	{
		return s.length >= pattern.length && s[0..pattern.length] == pattern;
	}
	template StorageClassCheck(string mangleof)
	{
		static if( startWith(mangleof, "PF") )	enum StorageClassCheck = "";	//(mutable)
		static if( startWith(mangleof, "PxF") )	enum StorageClassCheck = "x";	//const
		static if( startWith(mangleof, "POF") )	enum StorageClassCheck = "O";	//shared
		static if( startWith(mangleof, "POxF") )enum StorageClassCheck = "Ox";	//shared const
		static if( startWith(mangleof, "PyF") )	enum StorageClassCheck = "y";	//immutable
	}
	template Sig2Idx(string stc, string Name, Args...)
	{
		template Impl(int N, string Name, Args...)
		{
			static if( N < allNames.length ){
//				pragma(msg, "   find in Sig2Idx, [", N, "] ", stc, " ", allFpSigs[N], " ", allFpSigs[N].mangleof);
				static if( allNames[N] == Name
						&& is(ParameterTypeTuple!(allFpSigs[N]) == Args)
						&& stc == StorageClassCheck!(allFpSigs[N].mangleof) ){
					enum result = N;
				}else{
					enum result = Impl!(N+1, Name, Args).result;
				}
			}else{
				enum result = -1;
			}
		}
		enum result = Impl!(0, Name, Args).result;
	}

public:
	this(T)(T obj) if( isAllContains!(I, T)() )
	{
		objptr = cast(void*)obj;
		foreach( i, name; allNames ){
//			pragma(msg, "[", i, "] ", name, " : ", allDgSigs[i], " : ", allFpSigs[i]);
			static if( is(allFpSigs[i] U == U*) ){
				static if( is(U == immutable) ){
//					pragma(msg, " -> immutable");
					allDgSigs[i] dg = mixin("&(cast(immutable)obj)." ~ name);
				}else static if( is(U == shared) && is(U == const) ){
//					pragma(msg, " -> shared const");
					allDgSigs[i] dg = mixin("&(cast(shared const)obj)." ~ name);
				}else static if( is(U == shared) ){
//					pragma(msg, " -> shared");
					allDgSigs[i] dg = mixin("&(cast(shared)obj)." ~ name);
				}else static if( is(U == const) ){
//					pragma(msg, " -> const");
					allDgSigs[i] dg = mixin("&(cast(const)obj)." ~ name);
				}else{
					allDgSigs[i] dg = mixin("&(cast(Unqual!T)obj)." ~ name);
				}
			}
			funtbl[i] = dg.funcptr;
		}
	}
	
	private enum dispatch =
	q{
//		pragma(msg, "opDispatch!(", Name, ", ", TypeTuple!(Args), ") ", stc);
		enum i = Sig2Idx!(stc, Name, Args).result;
//		writefln("  %s Sig2Idx = %s", stc, i);
		static if( i >= 0 ){
			return composeDg(cast(void*)objptr, funtbl[i])(args);
		}else static if( __traits(compiles, mixin("I." ~ Name))
					  && __traits(isStaticFunction, mixin("I." ~ Name)) ){
			return mixin("I." ~ Name)(args);
		}else{
			static assert(0, "member '" ~ Name ~ "' not found in " ~ allNames.stringof);
		}
	};
	
	auto opDispatch(string Name, Args...)(Args args)
	{
		enum stc = "";
		mixin(dispatch);
	}
	auto opDispatch(string Name, Args...)(Args args) const
	{
		enum stc = "x";
		mixin(dispatch);
	}
	auto opDispatch(string Name, Args...)(Args args) shared
	{
		enum stc = "O";
		mixin(dispatch);
	}
	auto opDispatch(string Name, Args...)(Args args) shared const
	{
		enum stc = "Ox";
		mixin(dispatch);
	}
	auto opDispatch(string Name, Args...)(Args args) immutable
	{
		enum stc = "y";
		mixin(dispatch);
	}

//	static auto opDispatch(string Name, Args...)(Args args)
//	{
//		enum stc = 's';
//		mixin(dispatch);
//	}
}


unittest
{
	static class A{
		int draw(){ return 10; }
	}
	static class B : A{
		int draw(){ return 20; }
	}
	
	alias Interface!q{
		int draw();
	} Drawable;
	
	auto a = new A();
	auto b = new B();
	
	Drawable d;
	d = Drawable(a);
	assert(d.draw() == 10);
	d = Drawable(b);
	assert(d.draw() == 20);
	d = Drawable(cast(A)b);
	assert(d.draw() == 20);		// dynamic interface resolution
}


unittest
{
	static class A
	{
		int draw(){ return 10; }
	}
	
	alias Interface!q{
		int draw();
		static int f(){ return 20; }
	} S;
	
	S s = new A();
	assert(s.draw() == 10);
	assert(s.f() == 20);
//	assert(S.f() == 20);	// static opDispatch not allowed ?
	static assert(!__traits(compiles, s.g()));
}


unittest
{
	static class A
	{
		int draw()				{ return 10; }
		int draw() const		{ return 20; }
  version(SharedSupport)
  {
		int draw() shared		{ return 30; }	// not supported
		int draw() shared const	{ return 40; }	// not supported
  }
		int draw() immutable	{ return 50; }	// not supported
	}
	
	alias Interface!q{
		int draw();
		int draw() const;
  version(SharedSupport)
  {
		int draw() shared;
		int draw() shared const;
  }
		int draw() immutable;
	} Drawable;
	
	auto a = new A();
	{
		Drawable d = a;
		assert( composeDg(d.objptr, d.funtbl[0])()  == 10);	// int draw()
		assert( composeDg(d.objptr, d.funtbl[1])()  == 20);	// int draw() const
  version(SharedSupport)
  {
		assert( composeDg(d.objptr, d.funtbl[2])()  == 30);	// int draw() shared
		assert( composeDg(d.objptr, d.funtbl[3])()  == 40);	// int draw() shared const
  }
  version(ImmutableSupport)
  {
		assert( composeDg(d.objptr, d.funtbl[4])()  == 50);	// int draw() immutable <- invalid address
  }
	}
	{
		auto           d =           Drawable (a);
		const         cd =           Drawable (a);
		shared        sd =    cast(shared)Drawable(a);	// workaround for unitetest?
		shared const scd =    cast(shared)Drawable(a);	// workaround for unitetest?
		immutable     id = cast(immutable)Drawable(a);	// workaround for unitetest?
		assert(  d.draw() == 10);
		assert( cd.draw() == 20);
  version(SharedSupport)
  {
		assert( sd.draw() == 30);
		assert(scd.draw() == 40);
  }
  version(ImmutableSupport)
  {
		assert( id.draw() == 50);
  }
	}
}


unittest
{
	static class A
	{
		int draw()				{ return 1; }
		int draw() const		{ return 10; }
		int draw(int v)			{ return v*2; }
		int draw(int v, int n)	{ return v*n; }
	}
	static class B
	{
		int draw()				{ return 2; };
	}
	static class X
	{
		void undef(){}
	}
	static class Y
	{
		void draw(double f){}
	}

	{
		static assert(!__traits(compiles, {
			alias Interface!q{
				int x = 0;
			} Drawable;
		}));
	}
	{
		alias Interface!q{
			int draw();
		} Drawable;
		
		Drawable d = new A();
		assert(d.draw() == 1);
		
		d = Drawable(new B());
		assert(d.draw() == 2);
		
		static assert(!__traits(compiles, d = Drawable(new X())));
	}
	{
		alias Interface!q{
			int draw(int v);
		} Drawable;
		
		Drawable d = new A();
		static assert(!__traits(compiles, d.draw()));
		assert(d.draw(8) == 16);
	}
	{
		alias Interface!q{
			int draw(int v, int n);
		} Drawable;
		
		Drawable d = new A();
		assert(d.draw(8, 8) == 64);
		
		static assert(!__traits(compiles, d = Drawable(new Y())));
	}
}


private template MakeSignatureTbl(T, int Mode)
{
	alias TypeTuple!(__traits(allMembers, T)) Names;
	
	template CollectOverloadsImpl(string Name)
	{
		alias TypeTuple!(__traits(getVirtualFunctions, T, Name)) Overloads;
		
		template MakeTuples(int N)
		{
			static if( N < Overloads.length ){	// string type
				static if( Mode == 0 ){
					alias TypeTuple!(
						Name,
						MakeTuples!(N+1).result
					) result;
				}
				static if( Mode == 1 ){			// function-pointer type
					alias TypeTuple!(
						typeof(&Overloads[N]),
						MakeTuples!(N+1).result
					) result;
				}
				static if( Mode == 2 ){			// delegate type
					alias TypeTuple!(
						typeof({
							typeof(&Overloads[N]) fp;
							return toDelegate(fp);
						}()),
						MakeTuples!(N+1).result
					) result;
				}
			}else{
				alias TypeTuple!() result;
			}
		}
		
		alias MakeTuples!(0).result result;
	}
	template CollectOverloads(string Name)
	{
		alias CollectOverloadsImpl!(Name).result CollectOverloads;
	}
	
	alias staticMap!(CollectOverloads, Names) result;
}


private static bool isAllContains(I, T)()
{
	alias MakeSignatureTbl!(I, 0).result allNames;
	alias MakeSignatureTbl!(I, 1).result allFpSigs;
	
	alias MakeSignatureTbl!(T, 0).result tgt_allNames;
	alias MakeSignatureTbl!(T, 1).result tgt_allFpSigs;
	
	bool result = true;
	foreach( i, name; allNames ){
//		pragma(msg, name, ": ", allFpSigs[i]);
		
		bool res = false;
		foreach( j, s; tgt_allNames ){
			if( name == s
			 && is(ParameterTypeTuple!(allFpSigs[i])
			 	== ParameterTypeTuple!(tgt_allFpSigs[j])) ){
				res = true;
				break;
			}
		}
		result = result && res;
		if( !result ) break;
	}
	return result;
}


// modified from std.functional
auto toDelegate(F)(auto ref F fp) if (isCallable!(F)) {

    static if (is(F == delegate))
    {
        return fp;
    }
    else static if (is(typeof(&F.opCall) == delegate)
                || (is(typeof(&F.opCall) V : V*) && is(V == function)))
    {
        return toDelegate(&fp.opCall);
    }
    else
    {
        alias typeof(&(new DelegateFaker!(F)).doIt) DelType;

        static struct DelegateFields {
            union {
                DelType del;
                //pragma(msg, typeof(del));

                struct {
                    void* contextPtr;
                    typeof({
						auto dg = &(new DelegateFaker!(F)).doIt;
						return dg.funcptr;
					}()) funcPtr;
			        	//get delegate type including StorageClass Modifier
                }
            }
        }

        // fp is stored in the returned delegate's context pointer.
        // The returned delegate's function pointer points to
        // DelegateFaker.doIt.
        DelegateFields df;

        df.contextPtr = cast(void*) fp;

        DelegateFaker!(F) dummy;
        auto dummyDel = &(dummy.doIt);
        df.funcPtr = dummyDel.funcptr;

        return df.del;
    }
}


/// 
auto composeDg(T...)(T args)
{
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
unittest
{
	int localfun(int n){ return n*10; }
	
	auto dg = &localfun;
	assert(composeDg(dg.ptr, dg.funcptr)(5) == 50);
}


