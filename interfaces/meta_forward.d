module meta_forward;


/// 
template Forward(F, string name, string code)
{
private:
	import std.traits, std.typetuple;
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
		alias staticMap!(PrmSTC2String, ParameterStorageClassTuple!F) PrmSTCs;
//		pragma(msg, ParameterStorageClassTuple!F, " -> ", PrmSTCs);
		
		static string ParametersOf(int mode)
		{
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
	}
	alias ForwardImpl!F Impl;
	
//	pragma(msg, Impl.ParametersOf(0));
//	pragma(msg, expand!q{ ReturnType!F ${name}(${Impl.ParametersOf(0)}){ mixin(code); } });
//	pragma(msg, mixin(expand!q{ ReturnType!F ${name}(${Impl.ParametersOf(0)}){ mixin(code); } }));

public:
	mixin(
		mixin(expand!
		q{
			ReturnType!F ${name}(${Impl.ParametersOf(0)}){
				alias TypeTuple!(${Impl.ParametersOf(1)}) args;
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
