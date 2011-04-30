/**
DMD patches
	Issue 5856 - overloading on const doesn't work for operator overload
	Issue 5896 - const overload matching is succumb to template parameter one
*/
module valueproxy;


template PropDispatch(alias a, string name, Args...)
{
  static if (Args.length == 0)
  {
	@property              auto ref opDispatch(Args args)	{ return mixin("a." ~ name); }
	@property        const auto ref opDispatch(Args args)	{ return mixin("a." ~ name); }
	@property    immutable auto ref opDispatch(Args args)	{ return mixin("a." ~ name); }
	@property       shared auto ref opDispatch(Args args)	{ return mixin("a." ~ name); }
	@property const shared auto ref opDispatch(Args args)	{ return mixin("a." ~ name); }
  }
  else
  {
	@property              auto ref opDispatch(Args args)	{ return mixin("a."~name~" = args"); }
	@property        const auto ref opDispatch(Args args)	{ return mixin("a."~name~" = args"); }
	@property    immutable auto ref opDispatch(Args args)	{ return mixin("a."~name~" = args"); }
	@property       shared auto ref opDispatch(Args args)	{ return mixin("a."~name~" = args"); }
	@property const shared auto ref opDispatch(Args args)	{ return mixin("a."~name~" = args"); }
  }
}
template FuncDispatch(alias a, string name, Args...)
{
	             auto ref opDispatch(Args args)	{ return mixin("a." ~ name ~ "(args)"); }
	       const auto ref opDispatch(Args args)	{ return mixin("a." ~ name ~ "(args)"); }
	   immutable auto ref opDispatch(Args args)	{ return mixin("a." ~ name ~ "(args)"); }
	      shared auto ref opDispatch(Args args)	{ return mixin("a." ~ name ~ "(args)"); }
	const shared auto ref opDispatch(Args args)	{ return mixin("a." ~ name ~ "(args)"); }
}

// Blocking implicit/explicit value extraction
template ValueProxy(alias a)
{
	// todo
	auto ref opEquals(B)(auto ref B b)
	{
		return a == b;
	}

	// todo
	auto ref opCmp(B)(auto ref B b)
	{
		static assert(!(__traits(compiles, a.opCmp(b)) && __traits(compiles, a.opCmp(b))));
		
		static if (__traits(compiles, a.opCmp(b)))
			return a.opCmp(b);
		else static if (__traits(compiles, b.opCmp(a)))
			return -b.opCmp(a);
		else
		{
			return a < b ? -1 : a > b ? +1 : 0;
		}
	}

	             auto ref opUnary(string op)()										{ return mixin(op ~ "a"); }
	       const auto ref opUnary(string op)()										{ return mixin(op ~ "a"); }
	   immutable auto ref opUnary(string op)()										{ return mixin(op ~ "a"); }
	      shared auto ref opUnary(string op)()										{ return mixin(op ~ "a"); }
	const shared auto ref opUnary(string op)()										{ return mixin(op ~ "a"); }

	             auto ref opIndexUnary(string op, I...)(auto ref I i)				{ return mixin(op ~ "a[i]"); }
	       const auto ref opIndexUnary(string op, I...)(auto ref I i)				{ return mixin(op ~ "a[i]"); }
	   immutable auto ref opIndexUnary(string op, I...)(auto ref I i)				{ return mixin(op ~ "a[i]"); }
	      shared auto ref opIndexUnary(string op, I...)(auto ref I i)				{ return mixin(op ~ "a[i]"); }
	const shared auto ref opIndexUnary(string op, I...)(auto ref I i)				{ return mixin(op ~ "a[i]"); }

	             auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e)	{ return mixin(op ~ "a[b..e]"); }
	       const auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e)	{ return mixin(op ~ "a[b..e]"); }
	   immutable auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e)	{ return mixin(op ~ "a[b..e]"); }
	      shared auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e)	{ return mixin(op ~ "a[b..e]"); }
	const shared auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e)	{ return mixin(op ~ "a[b..e]"); }

	auto ref opCast(T)()             	{ static assert(!is(T : typeof(a)), "Cannot extract object with casting."); return cast(T)a; }
	auto ref opCast(T)()        const	{ static assert(!is(T : typeof(a)), "Cannot extract object with casting."); return cast(T)a; }
	auto ref opCast(T)()    immutable	{ static assert(!is(T : typeof(a)), "Cannot extract object with casting."); return cast(T)a; }
	auto ref opCast(T)()       shared	{ static assert(!is(T : typeof(a)), "Cannot extract object with casting."); return cast(T)a; }
	auto ref opCast(T)() const shared	{ static assert(!is(T : typeof(a)), "Cannot extract object with casting."); return cast(T)a; }

	             auto ref opBinary(string op, B)(auto ref B b)		{ return mixin("a " ~ op ~ " b"); }
	       const auto ref opBinary(string op, B)(auto ref B b)		{ return mixin("a " ~ op ~ " b"); }
	   immutable auto ref opBinary(string op, B)(auto ref B b)		{ return mixin("a " ~ op ~ " b"); }
	      shared auto ref opBinary(string op, B)(auto ref B b)		{ return mixin("a " ~ op ~ " b"); }
	const shared auto ref opBinary(string op, B)(auto ref B b)		{ return mixin("a " ~ op ~ " b"); }

	             auto ref opBinaryRight(string op, B)(auto ref B b)	{ return mixin("a " ~ op ~ " b"); }
	       const auto ref opBinaryRight(string op, B)(auto ref B b)	{ return mixin("a " ~ op ~ " b"); }
	   immutable auto ref opBinaryRight(string op, B)(auto ref B b)	{ return mixin("a " ~ op ~ " b"); }
	      shared auto ref opBinaryRight(string op, B)(auto ref B b)	{ return mixin("a " ~ op ~ " b"); }
	const shared auto ref opBinaryRight(string op, B)(auto ref B b)	{ return mixin("a " ~ op ~ " b"); }

	             auto ref opCall(Args...)(auto ref Args args)		{ return a(args); }
	       const auto ref opCall(Args...)(auto ref Args args)		{ return a(args); }
	   immutable auto ref opCall(Args...)(auto ref Args args)		{ return a(args); }
	      shared auto ref opCall(Args...)(auto ref Args args)		{ return a(args); }
	const shared auto ref opCall(Args...)(auto ref Args args)		{ return a(args); }

	             auto ref opIndex(I...)(auto ref I i)				{ return a[i]; }
	       const auto ref opIndex(I...)(auto ref I i)				{ return a[i]; }
	   immutable auto ref opIndex(I...)(auto ref I i)				{ return a[i]; }
	      shared auto ref opIndex(I...)(auto ref I i)				{ return a[i]; }
	const shared auto ref opIndex(I...)(auto ref I i)				{ return a[i]; }

	             auto ref opSlice()()								{ return a[]; }
	       const auto ref opSlice()()								{ return a[]; }
	   immutable auto ref opSlice()()								{ return a[]; }
	      shared auto ref opSlice()()								{ return a[]; }
	const shared auto ref opSlice()()								{ return a[]; }

	             auto ref opSlice(B, E)(auto ref B b, auto ref E e)	{ return a[b..e]; }
	       const auto ref opSlice(B, E)(auto ref B b, auto ref E e)	{ return a[b..e]; }
	   immutable auto ref opSlice(B, E)(auto ref B b, auto ref E e)	{ return a[b..e]; }
	      shared auto ref opSlice(B, E)(auto ref B b, auto ref E e)	{ return a[b..e]; }
	const shared auto ref opSlice(B, E)(auto ref B b, auto ref E e)	{ return a[b..e]; }

	             auto ref opAssign(V)(auto ref V v)											{ return a = v; }
	       const auto ref opAssign(V)(auto ref V v)											{ return a = v; }
	   immutable auto ref opAssign(V)(auto ref V v)											{ return a = v; }
	      shared auto ref opAssign(V)(auto ref V v)											{ return a = v; }
	const shared auto ref opAssign(V)(auto ref V v)											{ return a = v; }

	             auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i)				{ return a[i] = v; }
	       const auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i)				{ return a[i] = v; }
	   immutable auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i)				{ return a[i] = v; }
	      shared auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i)				{ return a[i] = v; }
	const shared auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i)				{ return a[i] = v; }

	             auto ref opSiliceAssign(V, R...)(auto ref V v)								{ return a[] = v; }
	       const auto ref opSiliceAssign(V, R...)(auto ref V v)								{ return a[] = v; }
	   immutable auto ref opSiliceAssign(V, R...)(auto ref V v)								{ return a[] = v; }
	      shared auto ref opSiliceAssign(V, R...)(auto ref V v)								{ return a[] = v; }
	const shared auto ref opSiliceAssign(V, R...)(auto ref V v)								{ return a[] = v; }

	             auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }
	       const auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }
	   immutable auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }
	      shared auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }
	const shared auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }

	             auto ref opOpAssign(string op, V)(auto ref V v)										{ return mixin("a " ~ op~"= v"); }
	       const auto ref opOpAssign(string op, V)(auto ref V v)										{ return mixin("a " ~ op~"= v"); }
	   immutable auto ref opOpAssign(string op, V)(auto ref V v)										{ return mixin("a " ~ op~"= v"); }
	      shared auto ref opOpAssign(string op, V)(auto ref V v)										{ return mixin("a " ~ op~"= v"); }
	const shared auto ref opOpAssign(string op, V)(auto ref V v)										{ return mixin("a " ~ op~"= v"); }

	             auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i)				{ return mixin("a[i] " ~ op~"= v"); }
	       const auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i)				{ return mixin("a[i] " ~ op~"= v"); }
	   immutable auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i)				{ return mixin("a[i] " ~ op~"= v"); }
	      shared auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i)				{ return mixin("a[i] " ~ op~"= v"); }
	const shared auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i)				{ return mixin("a[i] " ~ op~"= v"); }

	             auto ref opSliceOpAssign(string op, V)(auto ref V v)									{ return mixin("a[] " ~ op~"= v"); }
	       const auto ref opSliceOpAssign(string op, V)(auto ref V v)									{ return mixin("a[] " ~ op~"= v"); }
	   immutable auto ref opSliceOpAssign(string op, V)(auto ref V v)									{ return mixin("a[] " ~ op~"= v"); }
	      shared auto ref opSliceOpAssign(string op, V)(auto ref V v)									{ return mixin("a[] " ~ op~"= v"); }
	const shared auto ref opSliceOpAssign(string op, V)(auto ref V v)									{ return mixin("a[] " ~ op~"= v"); }

	             auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }
	       const auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }
	   immutable auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }
	      shared auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }
	const shared auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }

	template opDispatch(string name, Args...)
	{
		static if (is(typeof(__traits(getMember, s, name)) == function))
			alias .FuncDispatch!(a, name, Args).opDispatch opDispatch;
		else
			alias .PropDispatch!(a, name, Args).opDispatch opDispatch;
	}
}
unittest
{
	static struct S
	{
		int value;
		mixin ValueProxy!value through;

		this(int n){ value = n; }

		// special case - refuse divide operator
		@disable opBinary(string op, B)(B b) if (op == "/"){}
		//alias through.opBinary opBinary;
		auto opBinary(string op, B)(B b) { return through.opBinary!(op, B)(b); }
	}

	S s = S(10);
	++s;
	assert(s.value == 11);

	assert(cast(double)s == 11.0);

	assert(s * 2 == 22);
	static assert(!__traits(compiles, s / 2));
	S s2 = s * 10;
	assert(s2 == 110);
	s2 = s2 - 60;
	assert(s2 == 50);

	// disable implicit conversion from s tor int
	static assert(!__traits(compiles, { int x = s; }()));
	int mul10(int n){ return n * 10; }
	static assert(!__traits(compiles, { mul10(s) == 110; }()));

	// disable explicit conversion from s tor int
	static assert(!__traits(compiles, { int x = cast(int)s; }()));
}
