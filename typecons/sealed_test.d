import std.stdio;
import sealed;

class C
{
    long v = 10;
    long get() const{ return v; }
    void set(long n){ v = n; }
    
    uint ptr() const{ return cast(uint)&this; }
}
class A(C)
{
    C c;
    
    this(C c_)
    {
        c = c_;
        writefln("A.this : &c == %08X, c.v = %s", cast(uint)&c, c.v);
    }
    @property ref Sealed!C getc(string file=__FILE__, uint line=__LINE__)()
    {
    //  writefln("get_c in : %s(%s)", file, line);
    //  scope(exit) writefln("get_c out");
        scope(exit) {}  // if mask this line, occurs Access Violation in line 48. Why?
        
        // here does not run destructor of Sealed struct, is it valid?
        return Sealed!C(c);
    }
    @property ref Sealed!C getc(string file=__FILE__, uint line=__LINE__)() const
    {
    //  writefln("get_c in : %s(%s)", file, line);
    //  scope(exit) writefln("get_c out");
    //  scope(exit) {}  // if mask this line, ...
        
        return Sealed!C(c);
    }
    
    uint c_ptr(){ return cast(uint)&c; }
}

void main(){}
unittest
{
    // A displays sealed mutable C
    auto a = new A!C(new C());
    assert(a.getc.get() == 10);
    a.getc.set(20);
    assert(a.getc.get() == 20);
    
    static assert(is(typeof(a.getc()) == Sealed!C));
    static assert(!__traits(compiles, { C c = a.getc; }));
    
    // problems
    auto sealed_p = &a.getc();      // compile succeeded, should be error.
    // after codes can compile, but may access invalid address
    {
    //  writefln("A.this : &c_ == %08X", cast(uint)a.getc().p);
    //  writefln("A.this : sealed_p == %08X", cast(uint)sealed_p);
    //  assert((*sealed_p).get() == 20);
    //  (*sealed_p).set(100);                   // object.Error: Access Violation
    //  assert((*sealed_p).get() == 100);
    }
}
unittest
{
    // A displays sealed mutable C
    auto a = new const(A!(const(C)))(new const(C)());
    assert(a.getc.get() == 10);
//  a.getc.set(20);
//  assert(a.getc.get() == 20);
    
    static assert(is(typeof(a.getc()) == Sealed!(const(C))));
    static assert(!__traits(compiles, { C c = a.getc; }));
    
    // problems
    auto sealed_p = &a.getc();      // compile succeeded, should be error.
    // after codes can compile, but may access invalid address
    {
    //  writefln("A.this : &c_ == %08X", cast(uint)a.getc().p);
    //  writefln("A.this : sealed_p == %08X", cast(uint)sealed_p);
    //  assert((*sealed_p).get() == 10);        // 
    //  (*sealed_p).set(100);
    //  assert((*sealed_p).get() == 10);        // object.Error: Access Violation
    }
}
version(unittest)
{
    Sealed!C use_A_scope_val()
    {
        auto a = new A!C(new C());
        return a.getc();
    }
    ref Sealed!C use_A_scope_ref()
    {
        auto a = new A!C(new C());
        return a.getc();
    }
}
unittest
{
    static assert(!__traits(compiles, { auto sealed_c = use_A_scope_val(); }));
    static assert(!__traits(compiles, { auto sealed_c = use_A_scope_ref(); }));
}
unittest
{
    auto a = new A!C(new C());
    with (a.getc)
    {
        static assert(!__traits(compiles, { 
            assert(get() == 10);
            set(20);
            assert(get() == 20);
        }));    // cannot compile, it is 
    }
}
unittest
{
    static assert(!__traits(compiles, {
    void f(Sealed!C sc)
    {
    }
    }));
    void g(ref Sealed!C sc)
    {
    }
    auto a = new A!C(new C());
    //f(a.getc());
    g(a.getc());
    
}
unittest
{
    Sealed!C* sealed_p;
    void test()
    {
        void g(ref Sealed!C sc)
        {
            sealed_p = &sc;
        }
        scope c = new C();
        scope a = new A!C(c);
        //f(a.getc());
        g(a.getc());
    }
    //sealed_p.get();   // can compile, break!
}
unittest
{
    auto c1 = new C();
    auto c2 = new C();
    c1.set(10);
    c2.set(20);
    auto a1 = new A!C(c1);
    auto a2 = new A!C(c2);
    assert(a1.getc.get() == 10);
    assert(a2.getc.get() == 20);
//  writefln("a1.getc.p = %08X", a1.getc.p);
//  writefln("a2.getc.p = %08X", a2.getc.p);
//  assert(a1.getc.p == &c1);
//  assert(a2.getc.p == &c2);
    swap(a1.getc(), a2.getc());     // does not work, may compile bug
    assert(a1.getc.get() == 20);
    assert(a2.getc.get() == 10);
}
