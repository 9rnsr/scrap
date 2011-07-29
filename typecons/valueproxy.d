/**
DMD patches
	Issue 620 - Can't use property syntax with a template function
	Issue 5896 - const overload matching is succumb to template parameter one
*/
module valueproxy;


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

	             auto ref opUnary(string op)() { return mixin(op ~ "a"); }
	       const auto ref opUnary(string op)() { return mixin(op ~ "a"); }
	   immutable auto ref opUnary(string op)() { return mixin(op ~ "a"); }
	      shared auto ref opUnary(string op)() { return mixin(op ~ "a"); }
	const shared auto ref opUnary(string op)() { return mixin(op ~ "a"); }

	             auto ref opIndexUnary(string op, I...)(auto ref I i) { return mixin(op ~ "a[i]"); }
	       const auto ref opIndexUnary(string op, I...)(auto ref I i) { return mixin(op ~ "a[i]"); }
	   immutable auto ref opIndexUnary(string op, I...)(auto ref I i) { return mixin(op ~ "a[i]"); }
	      shared auto ref opIndexUnary(string op, I...)(auto ref I i) { return mixin(op ~ "a[i]"); }
	const shared auto ref opIndexUnary(string op, I...)(auto ref I i) { return mixin(op ~ "a[i]"); }

	             auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e) { return mixin(op ~ "a[b..e]"); }
	       const auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e) { return mixin(op ~ "a[b..e]"); }
	   immutable auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e) { return mixin(op ~ "a[b..e]"); }
	      shared auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e) { return mixin(op ~ "a[b..e]"); }
	const shared auto ref opSliceUnary(string op, B, E)(auto ref B b, auto ref E e) { return mixin(op ~ "a[b..e]"); }

	             auto ref opCast(T)() { return cast(T)a; }
	       const auto ref opCast(T)() { return cast(T)a; }
	   immutable auto ref opCast(T)() { return cast(T)a; }
	      shared auto ref opCast(T)() { return cast(T)a; }
	const shared auto ref opCast(T)() { return cast(T)a; }

	             auto ref opBinary(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }
	       const auto ref opBinary(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }
	   immutable auto ref opBinary(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }
	      shared auto ref opBinary(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }
	const shared auto ref opBinary(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }

	             auto ref opBinaryRight(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }
	       const auto ref opBinaryRight(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }
	   immutable auto ref opBinaryRight(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }
	      shared auto ref opBinaryRight(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }
	const shared auto ref opBinaryRight(string op, B)(auto ref B b) { return mixin("a " ~ op ~ " b"); }

	             auto ref opCall(Args...)(auto ref Args args) { return a(args); }
	       const auto ref opCall(Args...)(auto ref Args args) { return a(args); }
	   immutable auto ref opCall(Args...)(auto ref Args args) { return a(args); }
	      shared auto ref opCall(Args...)(auto ref Args args) { return a(args); }
	const shared auto ref opCall(Args...)(auto ref Args args) { return a(args); }

	             auto ref opIndex(I...)(auto ref I i) { return a[i]; }
	       const auto ref opIndex(I...)(auto ref I i) { return a[i]; }
	   immutable auto ref opIndex(I...)(auto ref I i) { return a[i]; }
	      shared auto ref opIndex(I...)(auto ref I i) { return a[i]; }
	const shared auto ref opIndex(I...)(auto ref I i) { return a[i]; }

	             auto ref opSlice()() { return a[]; }
	       const auto ref opSlice()() { return a[]; }
	   immutable auto ref opSlice()() { return a[]; }
	      shared auto ref opSlice()() { return a[]; }
	const shared auto ref opSlice()() { return a[]; }

	             auto ref opSlice(B, E)(auto ref B b, auto ref E e) { return a[b..e]; }
	       const auto ref opSlice(B, E)(auto ref B b, auto ref E e) { return a[b..e]; }
	   immutable auto ref opSlice(B, E)(auto ref B b, auto ref E e) { return a[b..e]; }
	      shared auto ref opSlice(B, E)(auto ref B b, auto ref E e) { return a[b..e]; }
	const shared auto ref opSlice(B, E)(auto ref B b, auto ref E e) { return a[b..e]; }

	             auto ref opAssign(V)(auto ref V v) { return a = v; }
	       const auto ref opAssign(V)(auto ref V v) { return a = v; }
	   immutable auto ref opAssign(V)(auto ref V v) { return a = v; }
	      shared auto ref opAssign(V)(auto ref V v) { return a = v; }
	const shared auto ref opAssign(V)(auto ref V v) { return a = v; }

	             auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i) { return a[i] = v; }
	       const auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i) { return a[i] = v; }
	   immutable auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i) { return a[i] = v; }
	      shared auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i) { return a[i] = v; }
	const shared auto ref opIndexAssign(V, I...)(auto ref V v, auto ref I i) { return a[i] = v; }

	             auto ref opSiliceAssign(V, R...)(auto ref V v) { return a[] = v; }
	       const auto ref opSiliceAssign(V, R...)(auto ref V v) { return a[] = v; }
	   immutable auto ref opSiliceAssign(V, R...)(auto ref V v) { return a[] = v; }
	      shared auto ref opSiliceAssign(V, R...)(auto ref V v) { return a[] = v; }
	const shared auto ref opSiliceAssign(V, R...)(auto ref V v) { return a[] = v; }

	             auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }
	       const auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }
	   immutable auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }
	      shared auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }
	const shared auto ref opSiliceAssign(V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return a[b..e] = v; }

	             auto ref opOpAssign(string op, V)(auto ref V v) { return mixin("a " ~ op~"= v"); }
	       const auto ref opOpAssign(string op, V)(auto ref V v) { return mixin("a " ~ op~"= v"); }
	   immutable auto ref opOpAssign(string op, V)(auto ref V v) { return mixin("a " ~ op~"= v"); }
	      shared auto ref opOpAssign(string op, V)(auto ref V v) { return mixin("a " ~ op~"= v"); }
	const shared auto ref opOpAssign(string op, V)(auto ref V v) { return mixin("a " ~ op~"= v"); }

	             auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i) { return mixin("a[i] " ~ op~"= v"); }
	       const auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i) { return mixin("a[i] " ~ op~"= v"); }
	   immutable auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i) { return mixin("a[i] " ~ op~"= v"); }
	      shared auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i) { return mixin("a[i] " ~ op~"= v"); }
	const shared auto ref opIndexOpAssign(string op, V, I...)(auto ref V v, auto ref I i) { return mixin("a[i] " ~ op~"= v"); }

	             auto ref opSliceOpAssign(string op, V)(auto ref V v) { return mixin("a[] " ~ op~"= v"); }
	       const auto ref opSliceOpAssign(string op, V)(auto ref V v) { return mixin("a[] " ~ op~"= v"); }
	   immutable auto ref opSliceOpAssign(string op, V)(auto ref V v) { return mixin("a[] " ~ op~"= v"); }
	      shared auto ref opSliceOpAssign(string op, V)(auto ref V v) { return mixin("a[] " ~ op~"= v"); }
	const shared auto ref opSliceOpAssign(string op, V)(auto ref V v) { return mixin("a[] " ~ op~"= v"); }

	             auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }
	       const auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }
	   immutable auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }
	      shared auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }
	const shared auto ref opSliceOpAssign(string op, V, B, E)(auto ref V v, auto ref B b, auto ref E e)	{ return mixin("a[b..e] " ~ op~"= v"); }

	template __TempDispatch(string name)
	{
		template dispatch(T...)
		{
			alias dispatch2!T.dispatch dispatch;
		}
		template dispatch2(T...)
		{
			             auto ref dispatch(Args...)(Args args){ return mixin("a."~name~"!T(args)"); }
			       const auto ref dispatch(Args...)(Args args){ return mixin("a."~name~"!T(args)"); }
			   immutable auto ref dispatch(Args...)(Args args){ return mixin("a."~name~"!T(args)"); }
			      shared auto ref dispatch(Args...)(Args args){ return mixin("a."~name~"!T(args)"); }
			const shared auto ref dispatch(Args...)(Args args){ return mixin("a."~name~"!T(args)"); }
		}
	}
	template __PropDispatch(string name)
	{
		@property              auto ref dispatch()()              { return mixin("a."~name       ); }
		@property              auto ref dispatch(V)(auto ref V v) { return mixin("a."~name~" = v"); }

		@property        const auto ref dispatch()()              { return mixin("a."~name       ); }
		@property        const auto ref dispatch(V)(auto ref V v) { return mixin("a."~name~" = v"); }

		@property    immutable auto ref dispatch()()              { return mixin("a."~name       ); }
		@property    immutable auto ref dispatch(V)(auto ref V v) { return mixin("a."~name~" = v"); }

		@property       shared auto ref dispatch()()              { return mixin("a."~name       ); }
		@property       shared auto ref dispatch(V)(auto ref V v) { return mixin("a."~name~" = v"); }

		@property const shared auto ref dispatch()()              { return mixin("a."~name       ); }
		@property const shared auto ref dispatch(V)(auto ref V v) { return mixin("a."~name~" = v"); }
	}
	template __FuncDispatch(string name)
		if (is(typeof(__traits(getMember, a, name)) == function))
	{
		             auto ref dispatch(Args...)(Args args) { return mixin("a."~name~"(args)"); }
		       const auto ref dispatch(Args...)(Args args) { return mixin("a."~name~"(args)"); }
		   immutable auto ref dispatch(Args...)(Args args) { return mixin("a."~name~"(args)"); }
		      shared auto ref dispatch(Args...)(Args args) { return mixin("a."~name~"(args)"); }
		const shared auto ref dispatch(Args...)(Args args) { return mixin("a."~name~"(args)"); }
	}
	template opDispatch(string name)
	{
		static if (is(typeof(__traits(getMember, a, name)) == function))
		{
			//pragma(msg, name, ": function");
			alias __FuncDispatch!name.dispatch opDispatch;
		}
		else static if (__traits(getOverloads, a, name).length)
		{
			//pragma(msg, name, ": function property");
			alias __PropDispatch!name.dispatch opDispatch;
		}
		else static if (is(typeof(mixin("a."~name))))
		{
			//pragma(msg, name, ": raw property");
			alias __PropDispatch!name.dispatch opDispatch;
		}
		else
		{
			//pragma(msg, name, ": template");
			alias __TempDispatch!name.dispatch opDispatch;
		}
	}
}
unittest
{
	static struct S
	{
		int value;
		mixin ValueProxy!value through;

		this(int n){ value = n; }
	}

	S s = S(10);
	++s;
	assert(s.value == 11);

	// bug5896
	//assert(cast(double)s == 11.0);

	assert(s * 2 == 22);
	S s2 = s * 10;
	assert(s2 == 110);
	s2 = s2 - 60;
	assert(s2 == 50);

	// disable implicit conversion from s to int
	static assert(!__traits(compiles, { int x = s; }()));
	int mul10(int n){ return n * 10; }
	static assert(!__traits(compiles, { mul10(s) == 110; }()));
}
unittest
{
	class Foo
	{
		int field;

        @property const int val1(){ return field; }
        @property void val1(int n){ field = n; }

        @property ref int val2(){ return field; }

        const int func(int x, int y){ return x; }

		T tempfunc(T)()
		{
			return T.init;
		}
	}
	class Hoge
	{
	    Foo foo;
	    this(Foo f)
	    {
            foo = f;
	    }
		mixin ValueProxy!foo;
	}

    auto h = new Hoge(new Foo());
    int n;

	// field
	h.field = 1;			// lhs of assign
	n = h.field;			// rhs of assign
	assert(h.field == 1);	// lhs of BinExp
	assert(1 == h.field);	// rhs of BinExp
	assert(n == 1);

	// getter/setter property function
	h.val1 = 4;
	n = h.val1;
	assert(h.val1 == 4);
	assert(4 == h.val1);
	assert(n == 4);

	// ref getter property function
	h.val2 = 8;
	n = h.val2;
	assert(h.val2 == 8);
	assert(8 == h.val2);
	assert(n == 8);

	// member function
	assert(h.func(2,4) == 2);

	// template member function
	assert(h.tempfunc!int() == 0);
}
