module meta_forward;

/**
 */
template Forward(F, string name, string code)
{
private:
	import std.traits, std.typetuple;
	import std.conv;
	import meta_expand;
	
	enum paramName = "a";
	template ForwardImpl(F)
	{
		template PrmSTC2Str(uint stc)
		{
			static if (stc == ParameterStorageClass.NONE)
			{
				enum PrmSTC2Str = "";
			}
			else static if (stc & ParameterStorageClass.SCOPE)
			{
				enum PrmSTC2Str = "scope "
					~ PrmSTC2Str!(stc & ~ParameterStorageClass.SCOPE);
			}
			else static if (stc & ParameterStorageClass.OUT)
			{
				enum PrmSTC2Str = "out "
					~ PrmSTC2Str!(stc & ~ParameterStorageClass.OUT);
			}
			else static if (stc & ParameterStorageClass.REF)
			{
				enum PrmSTC2Str = "ref "
					~ PrmSTC2Str!(stc & ~ParameterStorageClass.REF);
			}
			else static if (stc & ParameterStorageClass.LAZY)
			{
				enum PrmSTC2Str = "lazy "
					~ PrmSTC2Str!(stc & ~ParameterStorageClass.LAZY);
			}
		}
		static string PrmSTCs(int mode)
		{
			alias staticMap!(PrmSTC2Str, ParameterStorageClassTuple!F) pstcs;
			
			string result;
			foreach (i, stc ; pstcs)
			{
				if (i > 0)
					result ~= ", ";
				if (mode == 0)      // Parameter defines
				{
					result ~= pstcs[i]
						~ mixin(expand!q{
							ParameterTypeTuple!F[${to!string(i)}]
						}) ~ paramName ~ to!string(i);
				}
				else if (mode == 1) // Parameter names
				{
					result ~= paramName ~ to!string(i);
				}
			}
			return result;
		}
		
		static string FunSTCs()
		{
			string result;
			static if (is(F == shared))
			{
				result ~= "shared ";
			}
			static if (is(F == const))
			{
				result ~= "const ";
			}
			static if (is(F == immutable))
			{
				result ~= "immutable ";
			}
			return result;
		}
	}
	alias ForwardImpl!F Impl;

public:
	mixin(
		mixin(expand!
		q{
			ReturnType!F ${name}(${Impl.PrmSTCs(0)}) ${Impl.FunSTCs()} {
				alias TypeTuple!(${Impl.PrmSTCs(1)}) args;
				mixin(code);
			}
		})
	);
}


unittest
{
	static class C
	{
		alias int function(scope int, ref double) F;
		
		int value = 10;
		mixin Forward!(F, "f", q{ a1      *= 2; return value*2; });
		mixin Forward!(F, "g", q{ args[1] *= 3; return value*3; });
	}
	
	auto c = new C();
	double v = 1.0;
	assert(c.f(1, v) == 20);  assert(v == 2.0);
	assert(c.g(1, v) == 30);  assert(v == 6.0);
}
unittest
{
	static class C
	{
		int f()             { return 10; }
		int g() const       { return 20; }
		int h() shared      { return 30; }
		int i() shared const{ return 40; }
		int j() immutable   { return 50; }
		
		// for overload set
		mixin Forward!(typeof(f), "a1", q{ return f(); });  alias a1 a;
		mixin Forward!(typeof(g), "a2", q{ return g(); });  alias a2 a;
		mixin Forward!(typeof(h), "a3", q{ return h(); });  alias a3 a;
		mixin Forward!(typeof(i), "a4", q{ return i(); });  alias a4 a;
		mixin Forward!(typeof(j), "a5", q{ return j(); });  alias a5 a;
	}
	auto           c = new C();
	const         cc = new C();
	shared        sc = new shared(C)();
	shared const scc = new shared(const(C))();
	immutable     ic = new immutable(C)();
	assert(  c.a() == 10);
	assert( cc.a() == 20);
	assert( sc.a() == 30);
	assert(scc.a() == 40);
	assert( ic.a() == 50);
	
}
