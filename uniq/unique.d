import std.algorithm : move;
//import std.conv : emplace;
import std.traits;
//import std.exception : assumeUnique;	//?


debug = Uniq;

/+template isRef(T)
{
	static if (is(T U == U*))
		enum isRef = true;
	else static if (is(U == class) || is(U == interface))
		enum isRef = true;
	else
		enum isRef = false;
}
template isRef(alias V)
{
//	static if (is(V U))
//		enum isRef = .isRef!U;
//	else 
	static if (__traits(isRef, V))
		enum isRef = true;
	else
		enum isRef = .isRef!(typeof(V));

}+/


bool isInitialState(T)(ref T obj)
{
	static if (is(T == class))
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
Unique!T u0;
assert(u0 == T.init);

Unique!T u1 = Unique!T(...);	// In-place construction
u1 = T(...);					// Replace unique object. Old object is destroyed.
u1 = T.init;					// Destroy unique object

Unique!T u2 = T(...);			// Move construction
T t = u.extract;				// Release unique object

Unique!T u3 = T(...);
T t = u3;						// TODO: Breaking uniqueness?
----
*/
struct Unique(T)
	if (!is(T == interface) && //should
	!is(T == class))	// for test
{
private:
  static if (is(T == class))
	ubyte[__traits(claasInstanceSize, T)] __payload;
  else
  {
	T __object;	// initialized with T.init by default-construction
	@property ref ubyte[T.sizeof] __payload(){ return *(cast(ubyte[T.sizeof]*)&__object); }
  }

public:
	/// In-place construction
	this(A...)(A args)
		if (!is(A[0] == Unique) && !is(A[0] == T))
	{
		emplace!T(cast(void[])__payload[], args);
		debug(Uniq) writefln("Unique.this%s", (typeof(args)).stringof);
	}
	/// Move construction
	this(A...)(A args)
		if (A.length == 1 && is(A[0] == T) && !__traits(isRef, args[0]))
	{
//		emplace!T(cast(void[])__payload);	// default construction
		move(args[0], __object);
		debug(Uniq) writefln("Unique.this(T)");
	}
	
	// for debug print
	debug(Uniq) ~this()
	{
		// for debug
		if (isInitialState(__object))
			debug(Uniq) writefln("Unique.~this()");
	}

	/// Disable copy construction
	/// need fixing @@@BUG4437@@@ and @@@BUG4499@@@
	@disable this(this)
	{
		debug(Uniq) writefln("Unique.this(this)");
	}

	/// Disable assignment with lvalue
	@disable void opAssign(ref const(T) u) {}
	@disable void opAssign(ref const(Unique) u) {}	/// ditto
	
	/// Assignment with rvalue of T
	void opAssign(T u)
	{
		move(u, __object);
		debug(Uniq) writefln("Unique.opAssign(T): u.val = %s, this.val = %s", u.val, this.val);
	}
	
	/// Assignment with rvalue of Unique
	void opAssign(Unique u)
	{
		move(u, this);
		debug(Uniq) writefln("Unique.opAssign(U): u.val = %s, this.val = %s", u.val, this.val);
	}
	
/+	/// MAY NOT NEED?
	bool isEmpty() const
	{
	  static if (is(T == class))
		return false;
	  else
		return true;
	}+/
	
	// Extract value and release uniqueness
	T extract()
	{
		return move(__object);
	}

  version(none)
  {
	// std.algorithm.move/swap でたぶんOK
//	Unique move()	// move元はinitになるのでfilled=falseとなりownershipが移動する
//	void swap()		// ownershipが交換されるので一意性は崩れない
  }

	alias __object this;
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


T* emplaceCopy(T)(void[] chunk, ref T obj) if (!is(T == struct))
{
    enforce(chunk.length >= T.sizeof,
            new ConvException("emplace: target size too small"));
	
	chunk[] = (cast(void*)&obj)[0 .. T.sizeof];
	
  static if (hasElaborateCopyConstructor!T)
	typeid(T).postblit(chunk.ptr);
	
	return cast(T*)chunk.ptr;
}


import std.stdio;
import std.algorithm;

struct S
{
	int val;
	
	this(int n)	{ writefln("S.this(%s)", val = n); }
	this(this)	{ writefln("S.this(this)"); }
	~this()		{
		if (isInitialState(this))
			writefln("S.~this() val = %s", val); }
	
	int get() const { return val; }
}

void main()
{
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Unique!S us;
//		assert(us.release == S.init);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us = Unique!S(10);
		assert(us.get == 10);
		Unique!S f(){ return Unique!S(20); }
		us = f();
		assert(us.get == 20);
		us = S(30);
		assert(us.get == 30);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Unique!S us = S(10);
		assert(us.get == 10);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Unique!S us1 = Unique!S(10);
		assert(us1.get == 10);
		Unique!S us2;
		move(us1, us2);
		assert(us2.get == 10);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us1 = Unique!S(10);
		auto us2 = Unique!S(20);
		assert(us1.get == 10);
		assert(us2.get == 20);
		swap(us1, us2);
		assert(us1.get == 20);
		assert(us2.get == 10);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us = Unique!S(10);
		S s = us;	// TODO: Breaking uniqueness
	}
}


