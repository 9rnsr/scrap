/**
 * from Boost.Interfaces
 * Written by Kenji Hara(9rnsr)
 * License: Boost License 1.0
 */
module interfaces;

import std.traits, std.typecons, std.typetuple;
import std.functional;

import meta_forward, meta_expand;

import meta;
alias meta.staticMap staticMap;
alias meta.isSame isSame;
alias meta.allSatisfy allSatisfy;


private template AdaptTo(Interfaces...)
	if( allSatisfy!(isInterface, Interfaces) )
{
	alias staticUniq!(staticMap!(VirtualFunctionsOf, Interfaces)) Idents;

	template CovariantSignatures(T)
	{
		alias VirtualFunctionsOf!T T_Idents;
		
		template isExactMatch(alias a)
		{
			enum isExactMatch =
					 isSame!(NameOf!(a.Expand[0]), NameOf!(a.Expand[1]))
				  && isSame!(TypeOf!(a.Expand[0]), TypeOf!(a.Expand[1]));
		//	pragma(msg, ". (", NameOf!(a.Expand[0]), " / ", NameOf!(a.Expand[1]),
		//			 ") && (", TypeOf!(a.Expand[0]), " / ", TypeOf!(a.Expand[1]), ") -> ", isExactMatch);
		}
		template isCovariantMatch(alias a)
		{
			enum isCovariantMatch =
							 isSame!(NameOf!(a.Expand[0]), NameOf!(a.Expand[1]))
				 && isCovariantWith!(TypeOf!(a.Expand[0]), TypeOf!(a.Expand[1]));
		//	pragma(msg, ". (", NameOf!(a.Expand[0]), " / ", NameOf!(a.Expand[1]),
		//			 ") && (", TypeOf!(a.Expand[0]), " / ", TypeOf!(a.Expand[1]), ") -> ", isCovariantMatch);
		}
		
		template CovariantIndexWith(size_t i)
		{
			alias staticCartesian!(Wrap!T_Idents, Wrap!(Idents[i])) Cartesian;
			
			enum int j = staticIndexOfIf!(isExactMatch, Cartesian);
			static if( j == -1 )
			{
				enum int k = staticIndexOfIf!(isCovariantMatch, Cartesian);
			}
			else
			{
				enum int k = j;
			}
			
			static if( k == -1 )
			{
				alias Sequence!() Result;
			}
			else
			{
				alias Sequence!(TypeOf!(T_Idents[k])) Result;
			}
		}
		enum Idents_length = Idents.length;		//workaround
		alias staticMap!(
			Instantiate!CovariantIndexWith.Returns!"Result",
			staticIota!(0, Idents_length)
		) Result;
	}
	
	template hasRequireMethods(T)
	{
		enum hasRequireMethods = __traits(compiles, CovariantSignatures!T.Result);
	}
	
	final class Impl(T) : Interfaces
	{
	private:
		alias CovariantSignatures!T.Result CoTypes;
		
		T obj;
		this(T o){ obj = o; }
	
	public:
		template MixinAll(int n)
		{
			static if( n >= Idents.length )
			{
				enum result = q{};
			}
			else
			{
				enum result = 
					mixin(expand!q{
						mixin Forward!(
							CoTypes[${n.stringof}],	// covariant
							NameOf!(Idents[${n.stringof}]),
							"return obj." ~ NameOf!(Idents[${n.stringof}]) ~ "(args);"
						);
					})
					~ MixinAll!(n+1).result;
			}
		}
		mixin(MixinAll!(0).result);
	}
}
/// 
template adaptTo(Interfaces...)
{
	auto adaptTo(T)(T obj) if( AdaptTo!Interfaces.hasRequireMethods!T )
	{
		return new AdaptTo!Interfaces.Impl!T(obj);
	}
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


unittest
{
	static class C
	{
		int draw(){ return 10; }
		int reflesh(){ return 20; }
	}
	interface Drawable
	{
		int draw();
	}
	interface Refleshable
	{
		int reflesh();
	}
	
	auto c = new C();
	auto a = adaptTo!(Drawable, Refleshable)(c);
	Drawable    d = a;
	Refleshable r = a;
	assert(a.draw() == 10);
	assert(d.draw() == 10);
	assert(a.reflesh() == 20);
	assert(r.reflesh() == 20);
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
	
	interface Drawable
	{
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
						Drawable   d = adaptTo!Drawable(a);
		const			Drawable  cd = adaptTo!Drawable(a);
		shared			Drawable  sd = adaptTo!Drawable(a);
		shared const	Drawable scd = adaptTo!Drawable(a);
		immutable		Drawable  id = adaptTo!Drawable(ia);
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


unittest
{
	interface Drawable
	{
		long draw();
	}
	static class C
	{
		int draw(){ return 10; }	// covariant return types
	}
	static assert(isCovariantWith!(typeof(C.draw), typeof(Drawable.draw)));
	
	auto a = adaptTo!Drawable(new C());
	static assert(is(typeof(a.draw()) == int));
	
	Drawable d = a;
	static assert(is(typeof(d.draw()) == long));
}
unittest
{
	interface Drawable
	{
		int draw();
	}
	static class C
	{
		int draw()const{ return 10; }	// covariant storage classes
	}
	static assert(isCovariantWith!(typeof(C.draw), typeof(Drawable.draw)));
	auto a = adaptTo!Drawable(new C());
	static assert(is(typeof(a.draw) == const));
	
	Drawable d = a;
	static assert(!is(typeof(d.draw) == const));
}
