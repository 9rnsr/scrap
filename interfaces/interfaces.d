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


/*private*/ interface Structural
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
	
	class AdaptedImpl(S) : Structural
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


version(all)
{
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
	if( auto c = cast(Structural)from ){
		return cast(S)c._getSource();
	}
	return null;
}
}
else
{

//	template isMutable(T)
//	{
//		enum isMutable = is(T==Unqual!T);
//	}
//	template isConst(T)
//	{
//		static if (is(T U==const(U)) && is(Unqual!U==U))
//			enum isConst = true;
//		else
//			enum isConst = false;
//	}
//	template isShared(T)
//	{
//		static if (is(T U==shared(U)) && is(Unqual!U==U))
//			enum isShared = true;
//		else
//			enum isShared = false;
//	}
//	template isSharedConst(T)
//	{
//		enum isSharedConst = is(T==const) && is(T==shared);
//	}
//	template isImmutable(T)
//	{
//		enum isImmutable = is(T==immutable);
//	}

/// 
template adaptTo(Targets...)
{
	/// 
	auto adaptTo(S)(S s)
	{
		static if (Targets.length == 1)
		{
			alias Targets[0] T;
			
			static if (is(S : T))
				return cast(T)(s);	//static_cast
			else static if (is(T : S))
				return cast(T)(s);	//dynamic_cast
			else
			{
				// try structual_cast
				
			//	//workaround for is(class : qualified interface) == true
			//	pragma(msg, "T=", T, ", S=", S);
			//	// TODO: this check only T extends structurally from S.
			//	static if (isMutable!S)		static assert(isMutable!T);
			//	static if (isConst!S)		static assert(isMutable!T || isConst!T || isImmutable!T);
			//	static if (isShared!S)		static assert(isShared!T);
			//	static if (isSharedConst!S)	static assert(isShared!T || isSharedConst!T);
			//	static if (isImmutable!S)	static assert(isImmutable!T);
			//	
				if (auto a = cast(Structural)s)
				{
				//	if (auto t = cast(T)a._getSource())	//why not allowed this?
					auto t = cast(T)a._getSource();
					// TODO: runtime check with storage-class contravariance
					// Does built-in dynamic_cast support it?
					// Elsewise, cross-cast idiom breaks const-correctness.
					if (t)
						// ejecting from structural wrapping succeeded
						return cast(T)(t);
				}
				
				static if (is(T == class))
					return cast(T)(null);
				else static if (is(T == interface) &&
								AdaptTo!Targets.hasRequireMethods!S)
					// enclosing into structural wrapping
					return cast(T)(new AdaptTo!Targets.Impl!S(s));
				else
					static assert(0,
						"structual_cast from "~S.stringof~
						" to "~T.stringof~" does not support");
			}
			static assert(is(typeof(return) == T));
		}
		else static if (allSatisfy!(isInterface, Targets) &&
						AdaptTo!Targets.hasRequireMethods!S)
			return new AdaptTo!Targets.Impl!S(s);
		else
			static assert(0,
				S.stringof ~ " does not have structual conformance "
				"to " ~ Targets.stringof ~ ".");
	}
}
alias adaptTo getAdapted;
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
	auto sa = new shared(A)();
	auto ia = new immutable(A)();
	{
		             Drawable   d = adaptTo!(             Drawable )(a);
		const        Drawable  cd = adaptTo!(       const(Drawable))(a);
		shared       Drawable  sd = adaptTo!(shared      (Drawable))(sa);
		shared const Drawable scd = adaptTo!(shared const(Drawable))(sa);
		immutable    Drawable  id = adaptTo!(immutable   (Drawable))(ia);
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
	auto d = adaptTo!Drawable(a);	// supports return-typ/storage-class covariance
	assert(d.draw() == 10);
	assert(d.reflesh() == 20);
/+	static assert(isCovariantWith!(typeof(A.draw), typeof(Drawable.draw)));
	static assert(is(typeof(a.draw()) == int));
	static assert(is(typeof(d.draw()) == long));

	static assert(isCovariantWith!(typeof(A.reflesh), typeof(Drawable.reflesh)));
	static assert( is(typeof(a.reflesh) == const));
	static assert(!is(typeof(d.reflesh) == const));
+/
}
