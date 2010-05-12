module zipindex;

import std.algorithm;
import range;
import std.stdio : pp=writefln;

void main(){
	auto msg = ["Hi!", "How are you?", "Nice to meet you."];
	
	foreach( s; msg ){
		pp("x : %s", s);
	}
	foreach( e; zip(counting(), msg) ){
		pp("%s : %s", e.at!0, e.at!1);
	}
}

auto counting(B=size_t, S=size_t)(B begin=0u, S step=1u)
{
	return sequence!("a.field[0] + n * a.field[1]")(begin, step);
}
