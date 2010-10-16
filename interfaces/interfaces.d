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
	Object _getSource();
}

private template AdaptTo(Targets...)
	if( allSatisfy!(isInterface, Targets) )
{
	alias staticUniq!(staticMap!(VirtualFunctionsOf, Targets)) TgtFuns;

	template CovariantSignatures(S)
	{
		alias VirtualFunctionsOf!S SrcFuns;
		
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
		
		template InheritsSrcFnFrom(size_t i)
		{
			alias staticCartesian!(Wrap!SrcFuns, Wrap!(TgtFuns[i])) Cartesian;
			
			enum int j_ = staticIndexOfIf!(isExactMatch, Cartesian);
			static if( j_ == -1 )
				enum int j = staticIndexOfIf!(isCovariantMatch, Cartesian);
			else
				enum int j = j_;
			
			static if( j == -1 )
				alias Sequence!() Result;
			else
				alias Sequence!(SrcFuns[j]) Result;
		}
		alias staticMap!(
			TypeOf,
			staticMap!(
				Instantiate!InheritsSrcFnFrom.Returns!"Result",
				staticIota!(0, staticLength!TgtFuns) //workaround @@@BUG4333@@@
			)
		) Result;
	}
	
	template hasRequireMethods(S)
	{
		enum hasRequireMethods = 
			CovariantSignatures!S.Result.length == TgtFuns.length;
	}
	
	class AdaptedImpl(S) : Adapted
	{
		S source;
		
		this(S s){ source = s; }
		
		final Object _getSource()
		{
			return source;
		}
	}
	final class Impl(S) : AdaptedImpl!S, Targets
	{
	private:
		alias CovariantSignatures!S.Result CoTypes;
		
		this(S s){ super(s); }
	
	public:
		template generateFun(string n)
		{
			enum generateFun = mixin(expand!q{
				mixin DeclareFunction!(
					CoTypes[${n}],	// covariant
					NameOf!(TgtFuns[${n}]),
					"return source." ~ NameOf!(TgtFuns[${n}]) ~ "(args);"
				);
			});
		}
		mixin mixinAll!(
			staticMap!(
				generateFun,
				staticMap!(StringOf, staticIota!(0,
					staticLength!TgtFuns))));	//workaround @@@BUG4333@@@
	}
}
/// 
template adaptTo(Targets...)
{
	/// 
	auto adaptTo(S)(S s)
		if( AdaptTo!Targets.hasRequireMethods!S )
	{
		return new AdaptTo!Targets.Impl!S(s);
	}
}

/// 
S getAdapted(S, I)(I from)
{
	if( auto c = cast(Adapted)from ){
		return cast(S)c._getSource();
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
		//Object _getSource();
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
