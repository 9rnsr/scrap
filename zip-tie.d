module zipindex;

import std.algorithm;
import std.range;
import std.stdio : pp=writefln;
import tie_;

int i_;
string s_;

void main(){
	auto idx = [1,2,3];//iota(0, 10);
	auto msg = ["Hi!", "How are you?", "Nice to meet you."];
	
	foreach( e; zip(idx, msg) ){
		pp("%s : %s", e.at!0, e.at!1);
	}
	
	Z z;
	foreach( e; z ){
	}
	foreach( i, s; z ){
	}
	
	foreach( i_, s_; z ){	//globalïœêîÇ∆ÇÕï 
		pp("i_=%s, s_=%s", i_, s_);
		pp("i_=%s, s_=%s", .i_, .s_);
	}
	pp("i_=%s, s_=%s", i_, s_);
	
}

import std.typecons;
struct Z{
	int opApply(int delegate(ref int, ref string) dg){
		auto i=0;
		auto s="a";
		dg(i, s);	++i, s~="a";
		dg(i, s);	++i, s~="a";
		dg(i, s);	++i, s~="a";
		return 0;
	}
	int opApply(int delegate(ref Tuple!(int, string)) dg){
		auto i=0;
		auto s="a";
		{ auto t = tuple(i, s);	dg(t); }	++i, s~="a";
		{ auto t = tuple(i, s);	dg(t); }	++i, s~="a";
		{ auto t = tuple(i, s);	dg(t); }	++i, s~="a";
		return 0;
	}
}

