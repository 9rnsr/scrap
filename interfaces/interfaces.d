/**
 * from Boost.Interfaces
 * Written by Kenji Hara(9rnsr)
 * License: Boost License 1.0
 */
module interfaces;

import std.traits, std.typecons, std.typetuple;
import std.functional;

import meta_forward, meta_expand;


private template AdaptTo(Interface) if( is(Interface == interface) )
{
	private template MakeSignatureTbl(T, int mode)
	{
		alias TypeTuple!(__traits(allMembers, T)) Names;
		
		template CollectOverloadsImpl(string Name)
		{
			alias TypeTuple!(__traits(getVirtualFunctions, T, Name)) Overloads;
			
			template MakeTuples(int N)
			{
				static if( N < Overloads.length )
				{
					static if( mode == 0 )	// identifier names
					{
						alias TypeTuple!(
							Name,
							MakeTuples!(N+1).Result
						) Result;
					}
					static if( mode == 1 )	// function types
					{
						alias TypeTuple!(
							typeof(Overloads[N]),
							MakeTuples!(N+1).Result
						) Result;
					}
				}
				else
				{
					alias TypeTuple!() Result;
				}
			}
			
			alias MakeTuples!(0).Result Result;
		}
		template CollectOverloads(string Name)
		{
			alias CollectOverloadsImpl!(Name).Result CollectOverloads;
		}
		
		alias staticMap!(CollectOverloads, Names) Result;
	}
	alias MakeSignatureTbl!(Interface, 0).Result Names;
	alias MakeSignatureTbl!(Interface, 1).Result FnTypes;
	
	bool isAllContains(T)()
	{
		alias MakeSignatureTbl!(T, 0).Result T_Names;
		alias MakeSignatureTbl!(T, 1).Result T_FnTypes;
		
		bool result = true;
		foreach( i, name; Names )
		{
			
			bool res = false;
			foreach( j, s; T_Names )
			{
				if( name == s && is(FnTypes[i] == T_FnTypes[j]) )
				{
					res = true;
					break;
				}
			}
			result = result && res;
			if( !result ) break;
		}
		return result;
	}
	
	final class Impl(T) : Interface
	{
	private:
		T obj;
		this(T o){ obj = o; }
	
	public:
		template MixinAll(int n)
		{
			static if( n >= Names.length )
			{
				enum result = q{};
			}
			else
			{
				enum result = 
					mixin(expand!q{
						mixin Forward!(
							FnTypes[${n.stringof}],
							Names[${n.stringof}],
							"return obj." ~ Names[${n.stringof}] ~ "(args);"
						);
					})
					~ MixinAll!(n+1).result;
			}
		}
		mixin(MixinAll!(0).result);
	}
}
/// 
Interface adaptTo(Interface, T)(T obj) if( AdaptTo!Interface.isAllContains!T() )
{
	return new AdaptTo!Interface.Impl!T(obj);
}


unittest
{
	static class C
	{
		int draw(){ return 10; }
	}
	interface Drawable
	{
		int draw();
	}
	
	auto c = new C();
	Drawable d = adaptTo!Drawable(c);
	assert(d.draw() == 10);
}


/+unittest
{
	class N
	{
		int draw(){ return 10; }
	}
	interface Drawable
	{
		int draw();
	}
	
	auto n = new N();
	auto d = adaptTo!Drawable(n);
	assert(d.draw() == 10);
}+/


unittest
{
	static class A
	{
		int draw(){ return 10; }
	}
	static class B : A
	{
		int draw(){ return 20; }
	}
	
	interface Drawable
	{
		int draw();
	}
	
	auto a = new A();
	auto b = new B();
	
	Drawable d;
	d = adaptTo!Drawable(a);
	assert(d.draw() == 10);
	d = adaptTo!Drawable(b);
	assert(d.draw() == 20);
	d = adaptTo!Drawable(cast(A)b);
	assert(d.draw() == 20);
}


unittest
{
	static class A
	{
		int draw(){ return 10; }
	}
	
	interface Drawable{
		int draw();
		static int f(){ return 20; }
	}
	
	Drawable d = adaptTo!Drawable(new A());
	assert(d.draw() == 10);
	assert(d.f() == 20);
	assert(Drawable.f() == 20);
}


unittest
{
	static class A
	{
		int draw()				{ return 10; }
		int draw() const		{ return 20; }
		int draw() shared		{ return 30; }
		int draw() shared const { return 40; }
		int draw() immutable	{ return 50; }
	}
	
	interface Drawable
	{
		int draw();
		int draw() const;
		int draw() shared;
		int draw() shared const;
		int draw() immutable;
	}
	
	auto  a = new A();
	auto ia = new immutable(A)();
	{
		auto		   d = adaptTo!Drawable(a);
		const		  cd = adaptTo!Drawable(a);
		shared		  sd = adaptTo!(shared(Drawable))(a);
		shared const scd = adaptTo!(shared(Drawable))(a);
		immutable	  id = adaptTo!(immutable(Drawable))(ia);
		assert(  d.draw() == 10);
		assert( cd.draw() == 20);
		assert( sd.draw() == 30);
		assert(scd.draw() == 40);
		assert( id.draw() == 50);
	}
}


unittest
{
	static class A
	{
		int draw()				{ return 1; }
		int draw() const		{ return 10; }
		int draw(int v) 		{ return v*2; }
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
		interface Drawable1
		{
			int draw();
		}
		
		Drawable1 d = adaptTo!Drawable1(new A());
		assert(d.draw() == 1);
		
		d = adaptTo!Drawable1(new B());
		assert(d.draw() == 2);
		
		static assert(!__traits(compiles, d = adaptTo!Drawable1(new X())));
	}
	{
		interface Drawable2
		{
			int draw(int v);
		}
		
		Drawable2 d = adaptTo!Drawable2(new A());
		static assert(!__traits(compiles, d.draw()));
		assert(d.draw(8) == 16);
	}
	{
		interface Drawable3
		{
			int draw(int v, int n);
		}
		
		Drawable3 d = adaptTo!Drawable3(new A());
		assert(d.draw(8, 8) == 64);
		
		static assert(!__traits(compiles, d = adaptTo!Drawable3(new Y())));
	}
}


