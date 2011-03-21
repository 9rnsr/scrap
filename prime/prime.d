// http://d.hatena.ne.jp/faith_and_brave/20110316/1300256258
import std.algorithm, std.range, std.traits;
import std.stdio;


template annotateEscape(alias fun)
{
	static assert(is(typeof({
		static typeof(&fun) save = &fun;
	}())));
}

auto anyRange(E, R)(R r)
{
	auto ar = AnyRange!E();
	ar.opAssign(r);
	return ar;
}
struct AnyRange(E, RangeKind=void)
{
	void function(const(void)*, int, void*) vtable;
	void[] payload;
	
	this(typeof(vtable) vtbl, void[] data)
	{
		vtable = vtbl;
		payload = data;
	}
	
	void opAssign(R)(R r)
	{
	  static if (is(R == AnyRange!E))
	  {
		vtable  = r.vtable;
		static if (is(R == class) || isArray!R)
			payload = r.payload;
		else
			payload = r.payload.dup;
		debug writefln("AnyRange.opAssign shallow copy");
	  }
	  else
	  {
		static void vtableOf(const(void)* p, int fnNum, void* r)
		{
			switch (fnNum)
			{
			case 0:	*(cast(bool*)r) = (cast(R*)p).empty;	break;	// empty
			case 1:	*(cast(E*)r) = (cast(R*)p).front;		break;	// front
			case 2:	(cast(R*)p).popFront;					break;	// popFront
			case 3:	*cast(R*)((cast(AnyRange!E*)r).payload.ptr) = (cast(R*)p).save;	break;	// save
			}
		}
		
		payload.length = R.sizeof;
		payload[] = (cast(void*)&r)[0 .. R.sizeof];
		vtable = &vtableOf;
		debug writefln("AnyRange.opAssign payload.length = %s", payload.length);
	  }
	}
	
	@property bool empty() const{ bool r; vtable(payload.ptr, 0, cast(void*)&r); return r; }
	@property E front() const	{ E    r; vtable(payload.ptr, 1, cast(void*)&r); return r; }
	void popFront()				{ vtable(payload.ptr, 2, null); }
	
	typeof(this) save()
	{
		typeof(this) r;
		vtable(payload.ptr, 3, &r);
		return r;
	}
}

auto iteration(alias fun, R)(R r)
{
	return Iteration!(fun, R)(r);
}
struct Iteration(alias fun, R)
{
	R r;
	
	@property bool empty() const			{ return r.empty; }
	@property ElementType!R front() const	{ return r.front; }
	void popFront()							{ r = fun(r); }
	
}

version(all)
{
void main()
{
	static AnyRange!int sieve(AnyRange!int r)
	{
		auto save_front = r.front;
		
		r.popFront();
		
		bool pred(int e)
		{
			debug writefln("pred = %s %% %s", e, save_front);
			return e % save_front != 0;
		}
		
		mixin annotateEscape!pred;	// ないとpredが正しく動作しない
		return anyRange!int(filter!pred(r));
	}
	
	auto primes = iteration!sieve(anyRange!int(sequence!"n+2"()));
  debug(1)
  {
	foreach (i; 0 .. 5)
	{
		if (primes.empty) break;
		writefln("> %s", primes.front);
		primes.popFront();
	}
  }
  else
	writefln("%s", take(primes, 5));

}
}else{
void main()
{
	int[] sieve(int[] primes, int n)
	{
		foreach (p; primes)
			if (n % p == 0) return primes;
		return primes ~ n;
	}

	writefln("%s", take(reduce!sieve((int[]).init, take(sequence!"n+2"(),100)), 5));

}
}
