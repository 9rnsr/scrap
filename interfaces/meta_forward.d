module meta_forward;

import std.traits;
import std.typetuple;

/// 
template Forward(F, string name, string code)
{
private:
	//import std.typetuple;
	private template staticMap(alias F, T...)	//workaround
	{
		static if (T.length == 0)
		{
			alias TypeTuple!() staticMap;
		}
		else
		{
			alias TypeTuple!(F!(T[0]), staticMap!(F, T[1 .. $])) staticMap;
		}
	}

	import std.traits;
	import std.conv;
	import meta_expand;
	
	enum paramName = "a";
	template ForwardImpl(F)
	{
		template PrmSTC2String(uint stc)
		{
			static if( stc == ParameterStorageClass.NONE )
			{
				enum PrmSTC2String = "";
			}
			else static if( stc & ParameterStorageClass.SCOPE )
			{
				enum PrmSTC2String = "scope " ~ PrmSTC2String!(stc & ~ParameterStorageClass.SCOPE);
			}
			else static if( stc & ParameterStorageClass.OUT )
			{
				enum PrmSTC2String = "out " ~ PrmSTC2String!(stc & ~ParameterStorageClass.OUT);
			}
			else static if( stc & ParameterStorageClass.REF )
			{
				enum PrmSTC2String = "ref " ~ PrmSTC2String!(stc & ~ParameterStorageClass.REF);
			}
			else static if( stc & ParameterStorageClass.LAZY )
			{
				enum PrmSTC2String = "lazy " ~ PrmSTC2String!(stc & ~ParameterStorageClass.LAZY);
			}
		}
		static string ParameterSTCs(int mode)
		{
//			pragma(msg, ParameterStorageClassTuple!F);
			alias staticMap!(PrmSTC2String, ParameterStorageClassTuple!F) PrmSTCs;
//			pragma(msg, ParameterStorageClassTuple!F, " -> [", PrmSTCs, "]");
			
			string result;
			foreach( i, stc ; PrmSTCs )
			{
				if( i > 0 ) result ~= ", ";
				if( mode == 0 )			// Parameter defines
				{
					result ~= PrmSTCs[i] ~ mixin(expand!q{ParameterTypeTuple!F[${to!string(i)}] }) ~ paramName ~ to!string(i);
				}
				else if( mode == 1 )	// Parameter names
				{
					result ~= paramName ~ to!string(i);
				}
			}
			return result;
		}
		
		static string FunctionSTCs()
		{
			string result;
			static if( is(F == shared) )
			{
				result ~= "shared ";
			}
			static if( is(F == const) )
			{
				result ~= "const ";
			}
			static if( is(F == immutable) )
			{
				result ~= "immutable ";
			}
			return result;
		}
	}
	alias ForwardImpl!F Impl;
	
//	pragma(msg, Impl.ParameterSTCs(0));
//	pragma(msg, expand!q{ ReturnType!F ${name}(${Impl.ParameterSTCs(0)}){ mixin(code); } });
//	pragma(msg, mixin(expand!q{ ReturnType!F ${name}(${Impl.ParameterSTCs(0)}){ mixin(code); } }));

public:
//	pragma(msg, "Forward.code : ", code);
	mixin(
		mixin(expand!
		q{
			ReturnType!F ${name}(${Impl.ParameterSTCs(0)}) ${Impl.FunctionSTCs()} {
				alias TypeTuple!(${Impl.ParameterSTCs(1)}) args;
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
	assert(c.f(1, v) == 20);	assert(v == 2.0);
	assert(c.g(1, v) == 30);	assert(v == 6.0);
}


unittest
{
	static class C
	{
		int f()				{ return 10; }
		int g() const		{ return 20; }
		int h() shared		{ return 30; }
		int i() shared const{ return 40; }
		int j() immutable	{ return 50; }
		
		// for overload set
		mixin Forward!(typeof(f), "a1", q{ return f(); });		alias a1 a;
		mixin Forward!(typeof(g), "a2", q{ return g(); });		alias a2 a;
		mixin Forward!(typeof(h), "a3", q{ return h(); });		alias a3 a;
		mixin Forward!(typeof(i), "a4", q{ return i(); });		alias a4 a;
		mixin Forward!(typeof(j), "a5", q{ return j(); });		alias a5 a;
	}
	auto           c = new C();
	const         cc = new C();
	shared        sc = cast(shared)new C();
	shared const scc = cast(shared const)new C();
	immutable     ic = cast(immutable)new C();
	assert(  c.a() == 10);
	assert( cc.a() == 20);
	assert( sc.a() == 30);
	assert(scc.a() == 40);
	assert( ic.a() == 50);
	
}
