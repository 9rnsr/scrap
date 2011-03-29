import std.stdio;

class C
{
	long v = 10;
	long get(){ return v; }
	void set(long n){ v = n; }
}
struct A
{
	private C c;
	this(C _)
	{
		c = _;
		writefln("&_    = %08X", cast(void*)&_);
		writefln("&this = %08X", cast(int)&address_test);
	}
	alias c this;
}

void main()
{
	auto a = A(new C());
	int[10] arr;
	writefln("&a = %08X", cast(int)&a);	//offset?
	pragma(msg, A.tupleof);
}
