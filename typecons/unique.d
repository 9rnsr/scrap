/**
Related:
    @mono_shoo  http://ideone.com/gH9AX
*/
module unique;

import std.traits;

debug = Uniq;

version = bug4424;  // Issue 4424 - Copy constructor and templated opAssign cannot coexist  -> apply workaround

// for debug print
debug (Uniq)
bool isInitialState(T)(ref T obj)
{
    static if (is(T == class) || is(T == interface) || isDynamicArray!T || isPointer!T)
        return obj is null;
    else
    {
        auto payload = (cast(ubyte*)&obj)[0 .. T.sizeof];
        auto obj_init = cast(ubyte[])typeid(T).init();
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
Unique!T u;
assert(u == T.init);

Unique!T u = Unique!T(...); // In-place construction
u = T(...);                 // Replace unique object. Old object is destroyed.
u = T.init;                 // Destroy unique object

//T t;
//Unique!T u = t;           // Initialize with lvalue is rejected
//u = t;                    // Assignment with lvalue is rejected

Unique!T u = T(...);        // Move construction
//T t = u;                  // implicit conversion from Unique!T to T is disabled
T t = u.extract;            // Release unique object
----
*/
struct Unique(T)
{
    import std.algorithm : move;
    import std.conv : emplace;
    import std.typecons : Proxy;
    debug (Uniq) import std.stdio;

    template isStorable(X...)
    {
        enum isStorable = isStorableT!X || isStorableU!X;
    }
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
    T __object; // initialized with T.init by default-construction

public:
    /// In-place construction with args which constructor argumens of T
    this(A...)(auto ref A args) if (!isStorable!A)
    {
        // emplace works against class type as value semantics
        static if (is(T == class))
            __object = new T(args);
        else
            emplace(&__object, args);
        debug (Uniq) writefln("Unique.this%s", (typeof(args)).stringof);
    }

    /// Move construction with rvalue T
    @disable this(A)(ref A arg) if (isStorable!A);
    /// ditto
    this(A)(A arg) if (isStorable!A)
    {
        static if (isStorableT!A)
        {
            static if (is(A _ == U, U : T) && is(U == T))
                move(arg, __object);
            else
                __object = arg;
            debug (Uniq) writefln("Unique.this(%s)", T.stringof);
        }
        else static if (isStorableU!A)
        {
            static if (is(A _ == Unique!U, U : T) && is(U == T))
                move(arg.__object, __object);
            else
                __object = arg.__object;
            debug (Uniq) writefln("Unique.this(Unique!(%s%s))", U.stringof, (is(U == T) ? "" : " : "~T.stringof));
        }
        else
            static assert(0);
    }

    /// Disable copy construction
    @disable this(this) {}

    // for debug print
    debug (Uniq) ~this()
    {
        // for debug
        if (isInitialState(__object))
            writefln("Unique.~this()");
    }

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
    @disable void opAssign(U : T)(ref U u);
    /// ditto
    void opAssign(U : T)(U u)
    {
        debug (Uniq) writefln("Unique.opAssign(T): u.val = %s, this.val = %s", u.val, this.val);
        static if (is(U == T))
            move(u, __object);
        else
            __object = u;
    }

    /// Assignment with rvalue of Unique!(U : T)
    @disable void opAssign(U : T)(ref Unique!U u);
    /// ditto
    void opAssign(U : T)(Unique!U u)
    {
        debug (Uniq) writefln("Unique.opAssign(U): u.val = %s, this.val = %s", u.val, this.val);
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

    // Nothing is required for swap operations

    // Forward all operations to __object, except implicit conversion.
    mixin Proxy!__object;
}


/+
//import std.exception : assumeUnique;  //?

// todo
Unique!T assumeUnique(T t) if (is(Unqual!T == T) || is(T == const))
{
    return Unique!T(t);
}
T assumeUnique(T t) if (is(T == immutable))
{
    return Unique!T(t);
}+/


/**************************************/

unittest
{
    import std.algorithm;   // swap, move
    debug (Uniq) import std.stdio;

    static struct S
    {
        int val;

        this(int n) { debug (Uniq) writefln("S.this(%s)", n); val = n; }
        this(this)  { debug (Uniq) writefln("S.this(this)"); }
        ~this()     {
          debug (Uniq)
            if (isInitialState(this))
                writefln("S.~this() val = %s", val); }
    }

    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        Unique!S us;
        assert(us == S.init);
    }
    static assert(!__traits(compiles,
    {
        S s = S(99);
        Unique!S us = s;
    }));
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        auto us = Unique!S(10);
        assert(us.val == 10);
        Unique!S f(){ return Unique!S(20); }
        us = f();
        assert(us.val == 20);
        us = S(30);
        assert(us.val == 30);
    }
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        Unique!S us = S(10);
        assert(us.val == 10);
    }
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        Unique!S us1 = Unique!S(10);
        assert(us1.val == 10);
        Unique!S us2;
        move(us1, us2);
        assert(us2.val == 10);
    }
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
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
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        auto us = Unique!S(10);
        S s = us.extract();
    }

    static class Foo
    {
        int val;
        this(int n){ val = n; }
        this(Foo* foo, int n){ *foo = this; val = n; }  // for internal test
    }
    static class Bar : Foo
    {
        this(int n){ super(n); }
    }

    {
        Foo foo;
        auto us = Unique!Foo(&foo, 10);
        Foo foo2 = cast(Foo)us;     // can unsafe extract with explicit cast.
                                    // ... or forbid this?
        assert(foo2 is foo);
        assert(us.__object is foo); // internal test
    }
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        auto us = Unique!Foo(10);
        assert(us.val == 10);       // member forwarding
    }

    // init / assign test
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        // Unique!Foo <- Foo (init)
        Unique!Foo us = new Foo(10);
        assert(us.val == 10);
        // Unique!Foo <- Foo (assign)
        us = new Foo(20);
        assert(us.val == 20);
    }
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        // Unique!Foo <- Unique!Foo (init)
        Unique!Foo us = Unique!Foo(Unique!Foo(10));
        assert(us.val == 10);
        // Unique!Foo <- Unique!Foo (assign)
        us = Unique!Foo(20);
        assert(us.val == 20);
    }

    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        // Unique!Foo <- Bar (init)
        Unique!Foo us = new Bar(10);
        assert(us.val == 10);
        // Unique!Foo <- Bar (assign)
        us = new Bar(20);
        assert(us.val == 20);
    }
    {   debug (Uniq) { writefln(">>>> ---"); scope(exit) writefln("<<<< ---"); }
        // Unique!Foo <- Unique!Bar (init)
        Unique!Foo us = Unique!Bar(10);
        assert(us.val == 10);
        // Unique!Foo <- Unique!Bar (assign)
        us = Unique!Bar(20);
        assert(us.val == 20);
    }
}
