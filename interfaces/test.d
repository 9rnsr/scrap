module test;

import interfaces : Interface;

import std.stdio;


class A
{
	int draw()				{ return 1; }
	int draw() const		{ return 10; }
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


unittest
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
}
unittest
{
	alias Interface!q{
		int draw() const;
	} Drawable;
	
	Drawable d = new A();
	assert(d.draw() == 10);
	
	
}


void main()
{
}
