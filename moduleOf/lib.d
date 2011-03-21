module lib;

template ModuleOf(T)
{
	pragma(msg, T.mangleof);
	pragma(msg, __traits(identifier, T));
//	alias ImportTest!("mod.a") M;
//	alias ImportTest!("mod.undef") M;	// dmd stop
	static if (__traits(compiles, { alias ImportTest!("mod.undef") M; }))
	{
		pragma(msg, "ok");
	}
	else
	{
		pragma(msg, "ng");
	}
}
template ImportTest(string name)
{
	mixin("import " ~ name ~ ";");
}