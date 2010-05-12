module zipindex;

import std.range;	// local version

import std.algorithm;
import std.stdio : pp=writefln;

void main(){
	auto msg = ["Hi!", "How are you?", "Nice to meet you."];
	
	foreach( e; zip(counting(), msg) ){
		pp("%s : %s", e.at!0, e.at!1);
	}
}

auto counting(B=size_t, S=size_t)(B begin=0u, S step=1u)
{
	return sequence!("a.field[0] + n * a.field[1]")(begin, step);
}
