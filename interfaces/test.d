module test;

import interfaces : Interface;

import std.stdio;


class A
{
	int draw()				{ return 1; }
	int draw() const		{ return 10; }
	int draw() immutable	{ return 20; }
	int draw(int v)			{ return v*2; }
	int draw(int v, int n)	{ return v*n; }
}
class B
{
	int draw()				{ return 2; };
}
class X
{
	void undef(){}
}
class Y
{
	void draw(double f){}
}


/+unittest
{
	{
		alias Interface!q{
			int draw();
		} Drawable;
		
		Drawable d = new A();
		assert(d.draw() == 1);
		
		d = Drawable(new B());
		assert(d.draw() == 2);
		
		static assert(!__traits(compiles, d = Drawable(new X())));
	}
	{
		alias Interface!q{
			int draw(int v);
		} Drawable;
		
		Drawable d = new A();
		static assert(!__traits(compiles, d.draw()));
		assert(d.draw(8) == 16);
	}
	{
		alias Interface!q{
			int draw(int v, int n);
		} Drawable;
		
		Drawable d = new A();
		assert(d.draw(8, 8) == 64);
		
		static assert(!__traits(compiles, d = Drawable(new Y())));
	}
}+/

import extypecons;
unittest
{
	alias Interface!q{
		int draw();
		int draw() const;
	} Drawable;
	
	Drawable d = new A();
//	assert(d.draw() == 10);
	
	assert( composeDg(d.objptr, d.funtbl.field[0])()  == 1);	// int draw()
	assert( composeDg(d.objptr, d.funtbl.field[1])()  == 10);	// int draw() const
}
/+unittest
{
	static class D
	{
		void* draw()			{ auto dg = &draw; return dg.funcptr; }
		void* draw() const		{ auto dg = &draw; return dg.funcptr; }
		void* draw() immutable	{ auto dg = &draw; return dg.funcptr; }
	}
	auto d = new D();
	auto id = cast(immutable)d;
	auto cd = cast(const)d;
	writefln("_ draw = %08X",  d.draw());
	writefln("c draw = %08X", cd.draw());
	writefln("i draw = %08X", id.draw());
}+/


/+unittest
{
	interface T{
		int draw() const;//{ return 0; }
	}
	typeof(&T.draw) f;
	pragma(msg, typeof(f));
	typeof(&(new T()).draw) g;
	pragma(msg, typeof(g));
	
	const int delegate() h;
	pragma(msg, typeof(h));
	
//	alias  int delegate() const  A;
}+/

void main()
{
}



/+
	template Drawable(T)
	{
		alias Interface!xd!q{
			int draw() const;
		} Drawable;
	}
+/
