module test;
import std.stdio;
import std.traits;
import std.typecons;

class A
{
private:
	int val;

public:
	this(int v){ val = v; }
	
	void draw(){
		writefln("A.draw: %s", val);
	}
}

class AA : A
{
public:
	this(int v){ super(v); }
	
	void redraw(){
		writefln("AA.redraw: %s", val);
	}
}

class B
{
private:
	string str;

public:
	this(string s){ str = s; }
	
	void draw(){
		writefln("B.draw: %s", str);
	}
}

class X
{
	void undef(){
	}
}

interface I
{
	void draw();
}


void main(){
/+
	auto dg = (&(new A(1)).draw);
	pragma(msg, typeof(dg.funcptr));
	auto pt = dg.ptr;
	auto fn = dg.funcptr;
	
	writefln("%08x", dg.funcptr);
	
	//fn();
	void delegate() dg2;
	dg2.ptr = pt;
	dg2.funcptr = fn;
	dg2();
+/

	auto aa = new AA(1);
	
//	auto p1 = (&aa.draw).ptr;
//	auto p2 = (&aa.redraw).ptr;
//上2行のコードだとp2にfuncptrが入ってしまう。Code生成がおかしい
//	assert((&aa.draw).ptr == (&aa.redraw).ptr);		//このassertも通らない
	auto _dg1 = (&aa.draw),		p1 = _dg1.ptr;
	auto _dg2 = (&aa.redraw),	p2 = _dg2.ptr;
	assert(p1 == p2);								// これならうまくいく
//	writefln("%08X:%08X", p1, p2);

	{
		auto t = packDg(&aa.draw);
	//	unpackDg(t.field[0], t.field[1])();
		unpackDg(t)();
	}
/+	{
		auto dg = (&aa.redraw);
		pragma(msg, typeof(dg.funcptr));
		auto ptr = dg.ptr;
		auto fun = dg.funcptr;
		
		writefln("%08X:%08X", ptr, fun);
		
		//fn();
		void delegate() dg2;
		dg2.ptr = ptr;
		dg2.funcptr = fun;
		dg2();
	}
	
	{
		static assert(is(typeof(&I.draw) == typeof(&A.draw)));
		auto dg = &aa.draw;
		void* pobj = dg.ptr;
		typeof(&I.draw) func = dg.funcptr;
		
		{
			
		}
	}+/
}


auto packDg(T)(T dg) if( is(T == delegate) )
{
	auto r = tuple(dg.ptr, dg.funcptr);
	writefln("packDg:\t%08X:%08X", r.field[0], r.field[1]);
	return r;
}
auto unpackDg(T...)(T args)
{
	static if( T.length==1 && is(T[0] X == Tuple!(void*, U), U) ){
		auto tup = args[0];
	//	alias typeof(tup.field[1]) U;
		
		ReturnType!U delegate(ParameterTypeTuple!U) dg;
		writefln("unpkDg:\t%08X:%08X", tup.field[0], tup.field[1]);
		dg.ptr		= tup.field[0];
		dg.funcptr	= tup.field[1];
		return dg;
	}else static if( T.length==2 && is(T[0] == void*) && isFunctionPointer!(T[1]) ){
		auto ptr		= args[0];
		auto funcptr	= args[1];
		alias T[1] U;
		
		ReturnType!U delegate(ParameterTypeTuple!U) dg;
		writefln("unpkDg:\t%08X:%08X", ptr, funcptr);
		dg.ptr		= ptr;
		dg.funcptr	= funcptr;
		return dg;
	}else{
		static assert(0, T.stringof);
	}
}

version(none){
void main()
{
/+
	auto a1 = new A(1);
	auto a2 = new A(2);
	auto b1 = new B("test");
	auto b2 = new B("string");
	
	a1.draw();
	a2.draw();
	b1.draw();
	b2.draw();
	
	alias MemberFunctionsTuple!(I, "draw") draw;
	static assert(draw.length == 2);
+/
	interface_test();
}



struct Interface(string def)
{
	mixin("static interface Inner { " ~ def ~ "}");
	
	enum allMembers = [__traits(allMembers, Inner)];
	pragma(msg, "allMembers = ", allMembers);
	
	pragma(msg, typeof(Inner.__vptr));
	
	static bool isAllContains(string[] members){
		auto result = true;
		foreach( name; allMembers ){
			bool res = false;
			foreach( s; members ){
				if( s == name ){
					res = true;
					break;
				}
			}
			if( !(result |= res) ) break;
		}
		return result;
	}
	static bool isContains(string member){
		auto result = true;
		foreach( name; allMembers ){
			if( member == name ) return true;
		}
		return false;
	}
	
//	enum Fun0 = mixin("&Inner." ~ allMembers[0]);
//	mixin("alias " ~ ReturnType!(mixin(Fun0)).stringof ~ " delegate(" ~ ParameterTypeTuple!(mixin(Fun0)).stringof ~  ") TFun0;");
//	pragma(msg, "TFun0 = ", TFun0);
//	typeof(mixin(ReturnType!(mixin(Fun0)).stringof ~ " delegate(" ~ ParameterTypeTuple!(mixin(Fun0)).stringof ~  ")")) entry0;
	
	this(T)(T obj){
		pragma(msg, T);
		static assert(isAllContains([__traits(allMembers, T)]));
		
//		pragma(msg,  typeof(entry0));
//		entry0 = mixin("&obj." ~ allMembers[0]);
	}
	
	pragma(msg, allMembers);
	pragma(msg, __traits(getVirtualFunctions, Inner, "draw"));
	pragma(msg, MemberFunctionsTuple!(Inner, "draw"));
}

void interface_test()
{
	alias Interface!q{
		void draw();
		void draw(int);
	} Drawable;
	
	
	Drawable d = new A(1);
//	alias MemberFunctionsTuple!(Drawable.Inner, "draw") MFT;
//	pragma(msg, MFT.length);
//	pragma(msg, typeof(MFT[0]));
}

}	//version(none)
