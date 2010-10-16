/**
 * from Boost.Interfaces
 * Written by Kenji Hara(9rnsr)
 * License: Boost License 1.0
 */
module interfaces;

import std.traits, std.typecons, std.typetuple;
import std.functional;

import meta;
alias meta.staticMap staticMap;
alias meta.isSame isSame;
alias meta.allSatisfy allSatisfy;


/*private*/ interface Adapted
{
	Object __getOriginal();
}

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
		}
		template isCovariantMatch(alias a)
		{
			enum isCovariantMatch =
							 isSame!(NameOf!(a.Expand[0]), NameOf!(a.Expand[1]))
				 && isCovariantWith!(TypeOf!(a.Expand[0]), TypeOf!(a.Expand[1]));
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
		alias staticMap!(
			Instantiate!CovariantIndexWith.Returns!"Result",
			staticIota!(0, staticLength!Idents)	//workaround @@@BUG4333@@@
		) Result;
	}
	
	template hasRequireMethods(T)
	{
		enum hasRequireMethods = 
			CovariantSignatures!T.Result.length == Idents.length;
	}
	
	class AdaptedImpl(T) : Adapted
	{
		T obj;
		
		this(T obj){ this.obj = obj; }
		
		final Object __getOriginal()
		{
			return obj;
		}
	}
	final class Impl(T) : AdaptedImpl!T, Interfaces
	{
	private:
		alias CovariantSignatures!T.Result CoTypes;
		
		this(T obj){ super(obj); }
	
	public:
		template generateFun(string n)
		{
			enum generateFun = mixin(expand!q{
				mixin DeclareFunction!(
					CoTypes[${n}],	// covariant
					NameOf!(Idents[${n}]),
					"return obj." ~ NameOf!(Idents[${n}]) ~ "(args);"
				);
			});
		}
		mixin mixinAll!(
			staticMap!(
				generateFun,
				staticMap!(StringOf, staticIota!(0,
					staticLength!Idents))));	//workaround @@@BUG4333@@@
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

/// 
T getAdapted(T, I)(I src)
{
	if( auto c = cast(Adapted)src ){
		return cast(T)c.__getOriginal();
	}
	return null;
}

unittest
{
	//class A
	//limitation: can't use nested class
	static class A
	{
		int draw(){ return 10; }
		//Object __getOriginal();
		//limitation : can't contain this name
	}
	static class AA : A
	{
		int draw(){ return 100; }
	}
	static class B
	{
		int draw(){ return 20; }
		int reflesh(){ return 20; }
	}
	static class X
	{
		void undef(){}
	}
	interface Drawable
	{
		int draw();
	}
	interface Refleshable
	{
		int reflesh();
		final int stop(){ return 0; }
		static int refleshAll(){ return 100; }
	}
	
	A a = new A();
	B b = new B();
	Drawable d;
	Refleshable r;
	{
		auto m = adaptTo!Drawable(a);
		d = m;
		assert(d.draw() == 10);
		assert(getAdapted!A(d) is a);
		assert(getAdapted!B(d) is null);
		
		d = adaptTo!Drawable(b);
		assert(d.draw() == 20);
		assert(getAdapted!A(d) is null);
		assert(getAdapted!B(d) is b);
		
		AA aa = new AA();
		d = adaptTo!Drawable(cast(A)aa);
		assert(d.draw() == 100);
		
		static assert(!__traits(compiles,
			d = adaptTo!Drawable(new X())));
		
	}
	{
		auto m = adaptTo!(Drawable, Refleshable)(b);
		d = m;
		r = m;
		assert(m.draw() == 20);
		assert(d.draw() == 20);
		assert(m.reflesh() == 20);
		assert(r.reflesh() == 20);
		
		// call final/static function in interface
		assert(m.stop() == 0);
		assert(m.refleshAll() == 100);
		assert(typeof(m).refleshAll() == 100);
	}
	
}

unittest
{
	static class A
	{
		int draw()              { return 10; }
		int draw(int v)         { return 11; }
		
		int draw() const        { return 20; }
		int draw() shared       { return 30; }
		int draw() shared const { return 40; }
		int draw() immutable    { return 50; }
		
	}
	
	interface Drawable
	{
		int draw();
		int draw() const;
		int draw() shared;
		int draw() shared const;
		int draw() immutable;
	}
	interface Drawable2
	{
		int draw(int v);
	}
	
	auto  a = new A();
	auto ia = new immutable(A)();
	{
		             Drawable   d = adaptTo!Drawable(a);
		const        Drawable  cd = adaptTo!Drawable(a);
		shared       Drawable  sd = adaptTo!Drawable(a);
		shared const Drawable scd = adaptTo!Drawable(a);
		immutable    Drawable  id = adaptTo!Drawable(ia);
		assert(  d.draw() == 10);
		assert( cd.draw() == 20);
		assert( sd.draw() == 30);
		assert(scd.draw() == 40);
		assert( id.draw() == 50);
	}
	{
		Drawable2 d = adaptTo!Drawable2(a);
		static assert(!__traits(compiles, d.draw()));
		assert(d.draw(0) == 11);
	}
}

unittest
{
	interface Drawable
	{
		long draw();
		int reflesh();
	}
	static class A
	{
		int draw(){ return 10; }			// covariant return types
		int reflesh()const{ return 20; }	// covariant storage classes
	}
	
	auto a = new A();
	auto m = adaptTo!Drawable(a);
	Drawable d = m;
	
	static assert(isCovariantWith!(typeof(A.draw), typeof(Drawable.draw)));
	static assert(is(typeof(a.draw()) == int));
	static assert(is(typeof(m.draw()) == int));		//same ReturnType with a
	static assert(is(typeof(d.draw()) == long));

	static assert(isCovariantWith!(typeof(A.reflesh), typeof(Drawable.reflesh)));
	static assert( is(typeof(a.reflesh) == const));
	static assert( is(typeof(m.reflesh) == const));	//same StorageClass with a
	static assert(!is(typeof(d.reflesh) == const));
}
