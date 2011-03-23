import std.algorithm : move;
//import std.conv : emplace;
import std.traits;
//import std.exception : assumeUnique;	//?


debug = Uniq;


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
private:
	// Do not use union in order to initialize __object with T.init.
	T __object;	// initialized with T.init by default-construction
	@property ref ubyte[T.sizeof] __payload(){ return *(cast(ubyte[T.sizeof]*)&__object); }

public:
	/// In-place construction with args which constructor argumens of T
	this(A...)(A args)
//	this(A...)(auto ref A args)	// Issue 5771 - Now template constructor and auto ref cannot use together
		if (!is(A[0] == Unique) && !is(A[0] == T))
	{
	  static if (isClass!T)	// emplaceはclassに対して値semanticsで動くので
		__object = new T(args);
	  else
		emplace!T(cast(void[])__payload[], args);
		debug(Uniq) writefln("Unique.this%s", (typeof(args)).stringof);
	}
	/// Move construction with rvalue T
	this(A...)(A args)
//	this(A...)(auto ref A args)	// Issue 5771 - Now template constructor and auto ref cannot use together
		if (A.length == 1 && is(A[0] == T) && !__traits(isRef, args[0]))	// Rvalue check is now always true...
	{
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

	/// Disable copy construction (Need fixing @@@BUG4437@@@ and @@@BUG4499@@@)
	@disable this(this)
	{
		debug(Uniq) writefln("Unique.this(this)");
	}

	/// Disable assignment with lvalue
	@disable void opAssign(ref const(T) u) {}
	/// ditto
	@disable void opAssign(ref const(Unique) u) {}
	
	/// Assignment with rvalue of T
	void opAssign(T u)
	{
		move(u, __object);
		debug(Uniq) writefln("Unique.opAssign(T): u.val = %s, this.val = %s", u.val, this.val);
	}
	
	/// Assignment with rvalue of Unique!T
	void opAssign(Unique u)
	{
		move(u, this);
		debug(Uniq) writefln("Unique.opAssign(U): u.val = %s, this.val = %s", u.val, this.val);
	}
	
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
  else
  {
	// moveに対しては特段の対応は必要ない
	@disable template proxySwap(T){}	// hack for std.algorithm.swap
  }

//	alias __object this;
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


T* emplaceCopy(T)(void[] chunk, ref T obj) if (!is(T == struct))
{
    enforce(chunk.length >= T.sizeof,
            new ConvException("emplace: target size too small"));
	
	chunk[] = (cast(void*)&obj)[0 .. T.sizeof];
	
  static if (hasElaborateCopyConstructor!T)
	typeid(T).postblit(chunk.ptr);
	
	return cast(T*)chunk.ptr;
}


template ValueProxy(alias a)
{
	auto opUnary(string op)()
	{
		return mixin(op ~ "a");
	}
	
	auto opIndexUnary(string op, Args...)(Args args)
	{
		return mixin(op ~ "a[args]");
	}
	
	auto opSliceUnary(string op, B, E)(B b, E e)
	{
		return mixin(op ~ "a[b .. e]");
	}
	auto opSliceUnary(string op)()
	{
		return mixin(op ~ "a[]");
	}
	
	auto opCast(T)()
	{
		return cast(T)a;
	}
	
	auto opBinary(string op, B)(B b)
	{
		return mixin("a " ~ op ~ " b");
	}
	
	auto opEquals(B)(B b)
	{
		return a == b;
	}
	
	auto opCmp(B)(B b)
	{
		static assert(!(__traits(compiles, a.opCmp(b)) && __traits(compiles, a.opCmp(b))));
		
		static if (__traits(compiles, a.opCmp(b)))
			return a.opCmp(b);
		else static if (__traits(compiles, b.opCmp(a)))
			return -b.opCmp(a);
		else
		{
			return a < b ? -1 : a > b ? +1 : 0;
		}
	}
	
	auto opCall(Args...)(Args args)
	{
		return a(args);
	}
	
	auto opAssign(V)(V v)
	{
		return a = v;
	}
	
	auto opSiliceAssign(V)(V v)
	{
		return a[] = v;
	}
	auto opSiliceAssign(V, B, E)(V v, B b, E e)
	{
		return a[b .. e] = v;
	}
	
	auto opOpAssign(string op, V)(V v)
	{
		return mixin("a " ~ op~"= v");
	}
	auto opIndexOpAssign(string op, V, Args...)(V v, Args args)
	{
		return mixin("a[args] " ~ op~"= v");
	}
	auto opSliceOpAssign(string op, V, B, E)(V v, B b, E e)
	{
		return mixin("a[b .. e] " ~ op~"= v");
	}
	auto opSliceOpAssign(string op, V)(V v)
	{
		return mixin("a[] " ~ op~"= v");
	}
	
	auto opIndex(Args...)(Args args)
	{
		return a[args];
	}
	auto opSlice()()
	{
		return a[];
	}
	auto opSlice(B, E)(B b, E e)
	{
		return a[b .. e];
	}
	
	auto opDispatch(string name, Args...)(Args args)
	{
		// name is property?
		static if (is(typeof(__traits(getMember, s, name)) == function))
			return mixin("a." ~ name ~ "(args)");
		else
			static if (args.length == 0)
				return mixin("a." ~ name);
			else
				return mixin("a." ~ name ~ " = args");
	}
}
unittest
{
	static struct S
	{
		int value;
		mixin ValueProxy!value through;
		
		this(int n){ value = n; }
		
		@disable opBinary(string op, B)(B b) if (op == "/"){}
		//alias through.opBinary opBinary;
		auto opBinary(string op, B)(B b) { return through.opBinary!(op, B)(b); }
	}
	
	S s = S(10);
	++s;
	assert(s.value == 11);
	
	assert(cast(double)s == 11.0);
	
	assert(s * 2 == 22);
	static assert(!__traits(compiles, s / 2));
	S s2 = s * 10;
	assert(s2 == 110);
	s2 = s2 - 60;
	assert(s2 == 50);
	
	static assert(!__traits(compiles, { int x = s; }()));
	
	int mul10(int n){ return n * 10; }
	static assert(!__traits(compiles, { mul10(s) == 110; }()));
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
}

void main()
{
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Unique!S us;
		assert(us == S.init);
	}
	// Do not work correctly. See Issue 5771
/+	static assert(!__traits(compiles,
	{
		S s = S(99);
		Unique!S us = s;
	}));+/
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us = Unique!S(10);
		assert(us.val == 10);
		Unique!S f(){ return Unique!S(20); }
		us = f();
		assert(us.val == 20);
		us = S(30);
		assert(us.val == 30);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Unique!S us = S(10);
		assert(us.val == 10);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		Unique!S us1 = Unique!S(10);
		assert(us1.val == 10);
		Unique!S us2;
		move(us1, us2);
		assert(us2.val == 10);
	}
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us1 = Unique!S(10);
		auto us2 = Unique!S(20);
		assert(us1.val == 10);
		assert(us2.val == 20);
		swap(us1, us2);
		assert(us1.val == 20);
		assert(us2.val == 10);
	}
	static assert(!__traits(compiles,
	{
		auto us = Unique!S(10);
		S s = us;
	}));
	{	writefln(">>>> ---"); scope(exit) writefln("<<<< ---");
		auto us = Unique!S(10);
		S s = us.extract;
	}
}
