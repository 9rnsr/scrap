import std.conv : emplace;

import valueproxy;

Scoped!T scoped(T, A...)(A args)
{
	// return value through hidden pointer.
	static assert((Scoped!T).sizeof > 8, "too small object");
	
	//debug(0)
	//{
		ubyte* hidden;	// for assertion check
		asm{ mov hidden, EAX; }
	//}

	version(none)
	{
		auto s = Scoped!T();	// allocated on hidden[0 .. (Scoped!T).sizeof]
		assert(cast(void*)&s == cast(void*)hidden);
		emplace!T(cast(void[])s.__payload, args);
		return s;	// destructor defined object cannnot RVO through hidden pointer
	}
	else
	{
		auto s = cast(Scoped!T*)hidden;
		emplace!T(cast(void[])s.__payload, args);
		asm{
			pop EDI;
			pop ESI;
			pop EBX;
			leave;
			ret;
		}
	}
}

private extern (C) static void _d_monitordelete(Object h, bool det);

// inner struct cannot return value optimization
struct Scoped(T) if (is(T == class))
{
	ubyte[__traits(classInstanceSize, T)] __payload;
	@property T __object(){ return cast(T)__payload.ptr; }

	@disable this(this)
	{
		writeln("Illegal call to Scoped this(this)");
		assert(false);
	}

	~this()
	{
		static void destroy(T)(T obj)
		{
			static if (is(typeof(obj.__dtor())))
			{
				obj.__dtor();
			}
			static if (!is(T == Object) && is(T Base == super))
			{
				Base b = obj;
				destroy(b);
			}
		}

		destroy(__object);
		if ((cast(void**)__payload.ptr)[1])	// if monitor is not null
		{
			_d_monitordelete(__object, true);
		}
	}

	//alias __object this;
	mixin ValueProxy!__object;	// blocking conversion Scoped!T to T, may need?
}


import std.stdio;
void main()
{
	// Issue 4500 - scoped moves class after calling the constructor
	static class A
	{
		static int cnt;
		
		this()		{ a = this; ++cnt; }
		this(int i)	{ a = this; ++cnt; }
		A a;
		bool check(){ return (this is a); }
		~this(){ --cnt; }
	}

	{
		auto a1 = scoped!A();
		assert(a1.check());
		assert(A.cnt == 1);
		
		auto a2 = scoped!A(1);
		assert(a2.check());
		assert(A.cnt == 2);
	}
	assert(A.cnt == 0);	// destructors called on scope exit
}
