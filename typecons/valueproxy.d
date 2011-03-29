module valueproxy;


// Blocking implicit/explicit value extraction
template ValueProxy(alias a)
{
	auto opUnary(string op)()
	{
		return mixin(op ~ "a");
	}
	
	auto opIndexUnary(string op, Args...)(Args args)
	{
		return mixin(op ~ "a[args]");
	}
	
	auto opSliceUnary(string op, B, E)(B b, E e)
	{
		return mixin(op ~ "a[b .. e]");
	}
	auto opSliceUnary(string op)()
	{
		return mixin(op ~ "a[]");
	}
	
	auto opCast(T)()
	{
		// block extracting value by casting
		static assert(!is(T : typeof(a)), "Cannot extract object with casting.");
		return cast(T)a;
	}
	
	auto opBinary(string op, B)(B b)
	{
		return mixin("a " ~ op ~ " b");
	}
	
	auto opEquals(B)(B b)
	{
		return a == b;
	}
	
	auto opCmp(B)(B b)
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
	
	auto opCall(Args...)(Args args)
	{
		return a(args);
	}
	
	auto opAssign(V)(V v)
	{
		return a = v;
	}
	
	auto opSiliceAssign(V)(V v)
	{
		return a[] = v;
	}
	auto opSiliceAssign(V, B, E)(V v, B b, E e)
	{
		return a[b .. e] = v;
	}
	
	auto opOpAssign(string op, V)(V v)
	{
		return mixin("a " ~ op~"= v");
	}
	auto opIndexOpAssign(string op, V, Args...)(V v, Args args)
	{
		return mixin("a[args] " ~ op~"= v");
	}
	auto opSliceOpAssign(string op, V, B, E)(V v, B b, E e)
	{
		return mixin("a[b .. e] " ~ op~"= v");
	}
	auto opSliceOpAssign(string op, V)(V v)
	{
		return mixin("a[] " ~ op~"= v");
	}
	
	auto opIndex(Args...)(Args args)
	{
		return a[args];
	}
	auto opSlice()()
	{
		return a[];
	}
	auto opSlice(B, E)(B b, E e)
	{
		return a[b .. e];
	}
	
	auto opDispatch(string name, Args...)(Args args)
	{
		// name is property?
		static if (is(typeof(__traits(getMember, s, name)) == function))
			return mixin("a." ~ name ~ "(args)");
		else
			static if (args.length == 0)
				return mixin("a." ~ name);
			else
				return mixin("a." ~ name ~ " = args");
	}
}
unittest
{
	static struct S
	{
		int value;
		mixin ValueProxy!value through;
		
		this(int n){ value = n; }
		
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
	
	static assert(!__traits(compiles, { int x = s; }()));
	
	int mul10(int n){ return n * 10; }
	static assert(!__traits(compiles, { mul10(s) == 110; }()));
}


