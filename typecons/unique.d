/**
TODO:
	assumeUiqueによるuniqueness付加
Related:
	@mono_shoo	http://ideone.com/gH9AX
*/
module unique;

import std.algorithm : move;
//import std.conv : emplace;
import std.traits;
//import std.exception : assumeUnique;	//?

import valueproxy;

debug = Uniq;

// DMD patches
version = bug5896;	// Issue 5896 - const overload matching is succumb to template parameter one
version = bug4424;	// Issue 4424 - Copy constructor and templated opAssign cannot coexist	-> apply workaround
version = bug5889;	// Issue 5889 - Struct literal,construction should be rvalue
version = bugXXXX;	// Unknown issue

// for debug print
bool isInitialState(T)(ref T obj)
{
	static if (is(T == class) || is(T == interface) || isDynamicArray!T || isPointer!T)
		return obj is null;
	else
	{
		auto payload = (cast(ubyte*)&obj)[0 .. T.sizeof];
		auto obj_init = cast(ubyte[])typeid(T).init;
		if (obj_init.ptr)
			return payload[] != obj_init[];
		else
			return payload[] != (ubyte[T.sizeof]).init;
	}
}


template isClass(T)
{
	enum isClass = is(T == class);
}

template isInterface(T)
{
	enum isClass = is(T == interface);
}

template isReferenceType(T)
{
    enum isReferenceType = (isClass!T ||
                            isInterface!T ||
                            isPointer!T ||
                            isDynamicArray!T ||
                            isAssosiativeArray!T);
}


/**
Unique type
SeeAlso:
	Concurrent Clean
	http://sky.zero.ad.jp/~zaa54437/programming/clean/CleanBook/part1/Chap4.html#sc11

has ownership

Construction:
	Constructors receive only constrution arguments or
	rvalue T or Unique.

Example
----
Unique!T u;
assert(u == T.init);

Unique!T u = Unique!T(...);	// In-place construction
u = T(...);					// Replace unique object. Old object is destroyed.
u = T.init;					// Destroy unique object

//T t;
//Unique!T u = t;			// Initialize with lvalue is rejected
//u = t;					// Assignment with lvalue is rejected

Unique!T u = T(...);		// Move construction
//T t = u;					// implicit conversion from Unique!T to T is disabled
T t = u.extract;			// Release unique object
----
*/
struct Unique(T)
{
	template isStorableT(X...)
	{
		static if (X.length != 1 || is(X[0] _ == Unique!U, U))
			enum isStorableT = false;
		else
			enum isStorableT = 
				((is(T == class) || is(T == interface)) && is(X[0] : T)) ||
				is(X[0] == T);
	}
	template isStorableU(X...)
	{
		static if (is(X[0] _ == Unique!U, U))
			enum isStorableU = isStorableT!U;
		else
			enum isStorableU = false;
	}
	
private:
	// Do not use union in order to initialize __object with T.init.
	T __object;	// initialized with T.init by default-construction
	@property ref ubyte[T.sizeof] __payload(){ return *(cast(ubyte[T.sizeof]*)&__object); }

public:
	/// In-place construction with args which constructor argumens of T
	this(A...)(auto ref A args) if (!isStorableT!A && !isStorableU!A)
	{
		static if (isClass!T)	// emplaceはclassに対して値semanticsで動くので
			__object = new T(args);
		else
			emplace!T(cast(void[])__payload[], args);
		debug(Uniq) writefln("Unique.this%s", (typeof(args)).stringof);
	}
	/// Move construction with rvalue T
	this(A...)(auto ref A args) if (isStorableT!A)
	{
		static assert(!__traits(isRef, args[0]));

		static if (is(A[0] _ == U, U : T) && is(U == T))
			move(args[0], __object);
		else
			__object = args[0];
		debug(Uniq) writefln("Unique.this(%s)", T.stringof);
	}
	/// Move construction with rvalue T
	this(A...)(auto ref A args) if (isStorableU!A)
	{
		static assert(!__traits(isRef, args[0]));

		static if (is(A[0] _ == Unique!U, U : T) && is(U == T))
			move(args[0].__object, __object);
		else
			__object = args[0].__object;
		debug(Uniq) writefln("Unique.this(Unique!(%s%s))", U.stringof, (is(U == T) ? "" : " : "~T.stringof));
	}

	// for debug print
	debug(Uniq) ~this()
	{
		// for debug
		if (isInitialState(__object))
			writefln("Unique.~this()");
	}

	/// Disable copy construction
	@disable this(this) {}

  version (bug4424)
  {
    // @@@BUG4424@@@ workaround
    private mixin template _workaround4424()
    {
        @disable void opAssign(typeof(this));
    }
    mixin _workaround4424;
  }

	/// Assignment with rvalue of U : T
	void opAssign(U : T)(auto ref U u)
	{
		static assert(!__traits(isRef, u));

		debug(Uniq) writefln("Unique.opAssign(T): u.val = %s, this.val = %s", u.val, this.val);
		static if (is(U == T))
			move(u, __object);
		else
			__object = u;
	}

	/// Assignment with rvalue of Unique!(U : T)
	void opAssign(U : T)(auto ref Unique!U u)
	{
		static assert(!__traits(isRef, u));

		debug(Uniq) writefln("Unique.opAssign(U): u.val = %s, this.val = %s", u.val, this.val);
		static if (is(U == T))
			move(u, this);
		else
			__object = u.__object;
	}

	// Extract value and release uniqueness
	T extract()
	{
		return move(__object);
	}

	// Nothing is required for move operations

	// Hack for std.algorithm.swap
	@disable template proxySwap(T){}

	mixin ValueProxy!__object;	// Relay any operations to __object, and
								// blocking implicit conversion from Unique!T to T
}


/+
// todo
Unique!T assumeUnique(T t) if (is(Unqual!T == T) || is(T == const))
{
	return Unique!T(t);
}
T assumeUnique(T t) if (is(T == immutable))
{
	return Unique!T(t);
}+/


import std.exception, std.conv : ConvException;

// emplace
/**
Given a raw memory area $(D chunk), constructs an object of non-$(D
class) type $(D T) at that address. The constructor is passed the
arguments $(D Args). The $(D chunk) must be as least as large as $(D
T) needs and should have an alignment multiple of $(D T)'s alignment.

This function can be $(D @trusted) if the corresponding constructor of
$(D T) is $(D @safe).

Returns: A pointer to the newly constructed object.
 */
T* emplace(T, Args...)(void[] chunk, Args args) if (!is(T == class))
{
    enforce(chunk.length >= T.sizeof,
            new ConvException("emplace: target size too small"));
    auto a = cast(size_t) chunk.ptr;
    version (OSX)       // for some reason, breaks on other platforms
        enforce(a % T.alignof == 0, new ConvException("misalignment"));
    auto result = cast(typeof(return)) chunk.ptr;

    void initialize()
    {
		auto init = cast(ubyte[])typeid(T).init;
		if (init.ptr)
			(cast(ubyte[])chunk)[] = init[];
		else
			(cast(ubyte[])chunk)[] = 0;
    //  static T i;
    //  memcpy(chunk.ptr, &i, T.sizeof);
    }

    static if (Args.length == 0)
    {
        // Just initialize the thing
        initialize();
    }
    else static if (is(T == struct))
    {
        static if (is(typeof(result.__ctor(args))))
        {
            // T defines a genuine constructor accepting args
            // Go the classic route: write .init first, then call ctor
            initialize();
            result.__ctor(args);
        }
        else static if (is(typeof(T(args))))
        {
            // Struct without constructor that has one matching field for
            // each argument
            initialize();
            *result = T(args);
        }
        else static if (Args.length == 1 && is(Args[0] : T))
        {
            initialize();
            *result = args[0];
        }
    }
    else static if (Args.length == 1 && is(Args[0] : T))
    {
        // Primitive type. Assignment is fine for initialization.
        *result = args[0];
    }
    else
    {
        static assert(false, "Don't know how to initialize an object of type "
                ~ T.stringof ~ " with arguments " ~ Args.stringof);
    }
    return result;
}


import std.stdio;
import std.algorithm;

struct S
{
	int val;

	this(int n)	{ debug(Uniq) writefln("S.this(%s)", n); val = n; }
	this(this)	{ debug(Uniq) writefln("S.this(this)"); }
	~this()		{
	  debug(Uniq)
		if (isInitialState(this))
			writefln("S.~this() val = %s", val); }
}

void main()
{
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Unique!S us;
		assert(us == S.init);
	}
	static assert(!__traits(compiles,
	{
		S s = S(99);
		Unique!S us = s;
	}));
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us = Unique!S(10);
		assert(us.val == 10);
		Unique!S f(){ return Unique!S(20); }
		us = f();
		assert(us.val == 20);
		version (bug5889) us = move(S(30));
		else              us = S(30);
		assert(us.val == 30);
	}
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		version (bug5889) Unique!S us = move(S(10));
		else              Unique!S us = S(10);
		assert(us.val == 10);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Unique!S us1 = Unique!S(10);
		assert(us1.val == 10);
		Unique!S us2;
		move(us1, us2);
		assert(us2.val == 10);
	}
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us1 = Unique!S(10);
		auto us2 = Unique!S(20);
		assert(us1.val == 10);
		assert(us2.val == 20);
	  version (bugXXXX) {} else
	  {
		swap(us1, us2);
		assert(us1.val == 20);
		assert(us2.val == 10);
	  }
	}
	static assert(!__traits(compiles,
	{
		auto us = Unique!S(10);
		S s = us;
	}));
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us = Unique!S(10);
		S s = us.extract;
	}

	static class Foo
	{
		int val;
		this(int n){ val = n; }
		this(Foo* foo, int n){ *foo = this; val = n; }	// for internal test
		int opCast(T : int)(){ return val; }
	}
	static class Bar : Foo
	{
		this(int n){ super(n); }
	}

	version (bug5896) {} else
	{
		Foo foo;
		auto us = Unique!Foo(&foo, 10);
		Foo foo2 = cast(Foo)us;		// can unsafe extract with explicit cast.
		assert(foo2 is foo);
	}
	version (bug5896) {} else
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Foo foo;
		auto us = Unique!Foo(&foo, 10);
		assert(us.__object is foo);	// internal test
		int val = cast(int)us;
		assert(val == 10);
	}

	// init / assign test
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		// Unique!Foo <- Foo (init)
		Unique!Foo us = new Foo(10);
		assert(us.val == 10);
		// Unique!Foo <- Foo (assign)
		us = new Foo(20);
		assert(us.val == 20);
	}
	version (bug5889) {} else
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		// Unique!Foo <- Unique!Foo (init)
		Unique!Foo us = Unique!Foo(Unique!Foo(10));
		assert(us.val == 10);
		// Unique!Foo <- Unique!Foo (assign)
		us = Unique!Foo(20);
		assert(us.val == 20);
	}

	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		// Unique!Foo <- Bar (init)
		Unique!Foo us = new Bar(10);
		assert(us.val == 10);
		// Unique!Foo <- Bar (assign)
		us = new Bar(20);
		assert(us.val == 20);
	}
	version (bug5889) {} else
	{	debug(Uniq) writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		// Unique!Foo <- Unique!Bar (init)
		Unique!Foo us = Unique!Bar(10);
		assert(us.val == 10);
		// Unique!Foo <- Unique!Bar (assign)
		us = Unique!Bar(20);
		assert(us.val == 20);
	}
}