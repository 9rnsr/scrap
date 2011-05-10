version = ExplicitCtor;
class A{ int a = 1; version (ExplicitCtor){ this(int n){ a *= n; } } }
class B{ int b = 2; version (ExplicitCtor){ this(int n){ b *= n; } } }
class C{ int c = 3; version (ExplicitCtor){ this(int n){ c *= n; } } }
class D{ int d = 4; version (ExplicitCtor){ this(int n){ d *= n; } } }
class E{ int e = 5; version (ExplicitCtor){ this(int n){ e *= n; } } }
class F{ int f = 6; version (ExplicitCtor){ this(int n){ f *= n; } } }
class G{ int g = 7; version (ExplicitCtor){ this(int n){ g *= n; } } }

/*
Inheritance tree:
 --> direct inheritance
 ==> alias this inheritance

X --> MultipleInherit ==> @ --> @ --> @ --> A
                          |     |     + ==> B
                          |     |            
                          |     + ==> @ --> C
                          |           + ==> D
                          |                  
                          + === @ --> @ --> E
                                |     + ==> F
                                |
                                + ==> G
*/
class X : MultipleInherit!(A, B, C, D, E, F, G)
{
    this()
    {
        void print_mem(){
            writefln("> [%(%08X %)]", (cast(int*)cast(void*)this)
                [0 .. __traits(classInstanceSize, X)/int.sizeof]);
        }

        //print_mem();
        version (ExplicitCtor)
        {
            _super!A(1);
            _super!B(2);
            _super!C(3);
            _super!D(4);
            _super!E(5);
            _super!F(6);
            _super!G(7);
        }
        else
        {
            // no need for implicit constructors
        }
        //print_mem();
    }
}

import std.stdio;
void main()
{
    auto x = new X();

    version (ExplicitCtor)
    {
        assert(x.a == 1*1);
        assert(x.b == 2*2);
        assert(x.c == 3*3);
        assert(x.d == 4*4);
        assert(x.e == 5*5);
        assert(x.f == 6*6);
        assert(x.g == 7*7);
    }
    else
    {
        assert(x.a == 1);
        assert(x.b == 2);
        assert(x.c == 3);
        assert(x.d == 4);
        assert(x.e == 5);
        assert(x.f == 6);
        assert(x.g == 7);
    }
}


/******** implementations ********/

import std.conv;
import std.traits;

/* Generate base class from class tuple */
class MultipleInherit(C...)
{
    template __MI(C...)
    {
        static if (C.length <= 2)
            alias Pair!(C) __MI;
        else
            alias Pair!(__MI!(C[0 .. $/2+(C.length%2)]), __MI!(C[$/2+(C.length%2) .. $])) __MI;
    }

    // To refuse explicit constructor calls
    Emplace!(__MI!C) __obj;
    alias __obj this;

    this()
    {
        /*
        initialize object memory image
          The typeid(T).init is now cannot calculate on compile time, so
          should set it on run time.
        */
        __obj.__initialize();
    }

    // super class constructors caller
    template _super(T)
    {
        void _super(A...)(A args)
        {
            //auto o = super.__extract!T;
            auto o = __obj.__extract!T;
            emplace!T((cast(void*)o)[0 .. __traits(classInstanceSize, T)], args);
        }
    }
}

// Generate binary inheritance tree
template Pair(A)
{
    alias A Pair;
}
class Pair(__Lhs, __Rhs) : __Lhs
{
    Emplace!__Rhs __rhs;
    alias __rhs this;

    void __initialize()
    {
        // if super is Pair
        static if (__traits(compiles, super.__initialize()))
            super.__initialize();
        __rhs.__initialize();
    }

    this()
    {
        assert(0);  // This constructor is never called

        // For remove compiler error
        static if (is(typeof(super.__ctor)))
        {
            ParameterTypeTuple!(typeof(super.__ctor)) dummy_params;
            super(dummy_params);
        }
    }

    T __extract(T)()
    {
        static if(__traits(compiles, super.__extract!T()))
        {
            return super.__extract!T();
        }
        else static if(__traits(compiles, __rhs.__extract!T()))
        {
            return __rhs.__extract!T();
        }
        else static if (is(T == __Lhs))
        {
            return this;
        }
        else static if (is(T == __Rhs))
        {
            return __rhs;
        }
        else
            static assert(0);
    }
}

// For define in-place class object and refuse explicit constructor call
struct Emplace(C) if (is(C == class))
{
    /*
    If typeid(C).init can calculate on compile time, we can remove 
    __initialize() function, but it may be difficult to implement compiler.
    */
    byte[__traits(classInstanceSize, C)] __payload;
    @property C __obj(){ return cast(C)__payload.ptr; }
    alias __obj this;

    // set pre construction memory image
    void __initialize()
    {
        __payload = typeid(C).init[];
        // if __obj is Pair
        static if (__traits(compiles, __obj.__initialize()))
            __obj.__initialize();
    }
}
