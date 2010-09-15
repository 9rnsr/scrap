module extraits;

import std.traits, std.typetuple;


/+
aliasをパラメータにとっているが、オーバーロードされているdraw個別にインスタンス化されないので不可
private template MemFunPtrsTupleImpl(alias F)
{
	pragma(msg, typeof(F));
	alias typeof(&F) MemFunPtrsTupleImpl;
}

template MemFunPtrsTuple(T, string name)
{
	pragma(msg, "MemFunPtrsTup: len=", MemberFunctionsTuple!(T, name).length);
	alias staticMap!(MemFunPtrsTupleImpl, MemberFunctionsTuple!(T, name)) MemFunPtrsTuple;
}
+/


/// 
template MemFunPtrsTuple(T, string name)
{
	alias MemFunPtrsTupleImpl!(MemberFunctionsTuple!(T, name)).result MemFunPtrsTuple;
}
private template MemFunPtrsTupleImpl(T...)
{
	static if( T.length == 0 ){
		alias TypeTuple!() result;
	}else{
		alias TypeTuple!(typeof(&T[0]), MemFunPtrsTupleImpl!(T[1..$]).result) result;
	}
}

/// 
template AllMemFunPtrsTuple(T)
{
	alias AllMemFunPtrsTupleImpl!(T, __traits(allMembers, T)).result AllMemFunPtrsTuple;
}
private template AllMemFunPtrsTupleImpl(T, Names...)
{
	static if( Names.length == 0 ){
		alias TypeTuple!() result;
	}else{
		static assert(is(typeof(Names[0]) == string));
		alias TypeTuple!(
			MemFunPtrsTuple!(T, Names[0]),
			AllMemFunPtrsTupleImpl!(T, Names[1..$]).result
		) result;
	}
}

/// 
template AllMemFunNamesTuple(T)
{
	alias AllMemFunNamesTupleImpl!(T, __traits(allMembers, T)).result AllMemFunNamesTuple;
}
private template AllMemFunNamesTupleImpl(T, Names...)
{
	template RepeatName(size_t N)
	{
		static if( N == 0 ) alias TypeTuple!() RepeatName;
		else	alias TypeTuple!(Names[0], RepeatName!(N-1)) RepeatName;
	}
	
	static if( Names.length == 0 ){
		alias TypeTuple!() result;
	}else{
		static assert(is(typeof(Names[0]) == string));
		alias TypeTuple!(
			RepeatName!(MemFunPtrsTuple!(T, Names[0]).length),
			AllMemFunNamesTupleImpl!(T, Names[1..$]).result
		) result;
	}
}
/+unittest{
	{
		alias MemberFunctionsTuple!(A, "draw") draws;
		pragma(msg, draws);
		pragma(msg, typeof(&draws[0]));
		pragma(msg, typeof(&draws[1]));
	}
	{
		alias MemFunPtrsTuple!(A, "draw") draws;
		pragma(msg, draws);
		pragma(msg, draws[0]);
		pragma(msg, draws[1]);
	}
	
	pragma(msg, __traits(allMembers, A));
	pragma(msg, __traits(allMembers, I));
	
	pragma(msg, AllMemFunPtrsTuple!A);
	
}+/


