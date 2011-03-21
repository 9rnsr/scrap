module sealed;
import std.stdio;

@trusted struct Sealed(T)
{
    //private T* p;
    public T* p;
    
    this(ref T t)
    {
        this.p = &t;
        writefln("Sealed.this : &t = %08X, p == %08X", &t, cast(uint)p);
    }
    
    auto opDispatch(string s, T...)(auto ref T args)
    {
        mixin("return (*p)." ~ s ~ "(args);");
    }
    auto opDispatch(string s, T...)(auto ref T args) const
    {
        mixin("return (*p)." ~ s ~ "(args);");
    }
    auto opDispatch(string s, T...)(auto ref T args) shared
    {
        mixin("return (*p)." ~ s ~ "(args);");
    }
    auto opDispatch(string s, T...)(auto ref T args) shared const
    {
        mixin("return (*p)." ~ s ~ "(args);");
    }
    auto opDispatch(string s, T...)(auto ref T args) immutable
    {
        mixin("return (*p)." ~ s ~ "(args);");
    }
    
    
    @disable ~this()
    {
    }
}

import std.algorithm;
void swap(T)(ref Sealed!T a, ref Sealed!T b)
{
    writefln("sealed.swap, a.p = %08X, b.p = %08X", a.p, b.p);
    std.algorithm.swap(*a.p, *b.p);
}