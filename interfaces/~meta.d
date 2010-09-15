import std.traits;

template isDelegatePointer(T...)
    if (T.length == 1)
{
    static if (is(T[0] U) || is(typeof(T[0]) U))
    {
        static if (is(U F : F*) && is(F == delegate))
            enum bool isDelegatePointer = true;
        else
            enum bool isDelegatePointer = false;
    }
    else
        enum bool isDelegatePointer = false;
}

template isDelegate(T...)
    if (T.length == 1)
{
    static if (is(T[0] D) || is(typeof(T[0]) D))
    {
        static if (is(D == delegate))
            enum bool isDelegate = true;
        else
            enum bool isDelegate = false;
    }
    else
        enum bool isDelegate = false;
}


template ToCode(T...)
{
	static assert( T.length >= 1 );
	
	static if( T.length == 1 ){
	
		static if( isDelegate!T ){
			enum ToCode = ToCode!(ReturnType!(T[0])) ~ " delegate(" ~ ToCode!(ParameterTypeTuple!(T[0])) ~ ")";
		} else {
			enum ToCode = T[0].stringof;
		}
	
	}else{
		
		enum ToCode = ToCode!(T[0]) ~ ", " ~ ToCode!(T[1..$]);
		
	}
}


unittest{
	alias int delegate(int) Dg;
	pragma(msg, Dg.stringof);
	pragma(msg, ToCode!Dg);
}

