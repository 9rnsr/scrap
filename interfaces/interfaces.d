/**
 * Boost.InterfacesのD言語実装例
 * Written by Kenji Hara(9rnsr)
 * License: public domain
 */
/**
	実装改良点：
		objptrとfuncptrを一旦分離し、再結合する方式を取るなら、
		const/immutable/synchronizedなどの修飾も維持する必要がある
		
		delegate.ptrは同じobjのメンバ関数から取ったものなら常に同じか？
		継承関係(多層、class/interface)に対して変化しないか？
		
		Interfaceという名前
		object.dに同名の構造体がある
		
		メンバ関数のリスト
		名前:string、引数型:型タプル、修飾型:std.traitsのfunctionAttributesを利用できる？
		→タプルのタプルでTable構成する？
		
		
		
	
	
 */
module interfaces;

import std.traits, std.typecons, std.typetuple;
import extraits, extypecons;

import std.stdio;
import std.functional;

struct ValueTuple(T...)
{
	alias T result;
}


template MakeSignatureTbl(T, int Mode)
{
	alias TypeTuple!(__traits(allMembers, T)) Names;
	
	template CollectOverloadsImpl(string Name)
	{
		alias TypeTuple!(__traits(getVirtualFunctions, T, Name)) Overloads;
		
		// aliasで渡された時点で void() と void()const の区別が消えてしまう
	//	template MakeTuple(alias Member)
	//	{
	//		pragma(msg, typeof(&Member));
	//		alias TypeTuple!(Name, typeof(&Member)) MakeTuple;
	//	}
	//	alias staticMap!(MakeTuple, Overloads) result;
		template MakeTuples(int i){
			static if( i < Overloads.length ){	// string type
				static if( Mode == 0 ){
					alias TypeTuple!(
						Name,
						MakeTuples!(i+1).result
					) result;
				}
				static if( Mode == 1 ){			// function-pointer type
					alias TypeTuple!(
						typeof(&Overloads[i]),
						MakeTuples!(i+1).result
					) result;
				}
				static if( Mode == 2 ){			// delegate type
					alias TypeTuple!(
						typeof({
							typeof(&Overloads[i]) fp;
							return toDelegate(fp);
						}()),
						MakeTuples!(i+1).result
					) result;
				}
			//	alias TypeTuple!(
			//		ValueTuple!(Name, typeof(&Overloads[i])),
			//		MakeTuples!(i+1).result
			//	) result;
			}else{
				alias TypeTuple!() result;
			}
		}
		
		alias MakeTuples!(0).result result;
	}
	template CollectOverloads(string Name)
	{
		alias CollectOverloadsImpl!(Name).result CollectOverloads;
	}
	
	alias staticMap!(CollectOverloads, Names) result;
}



/// 
struct Interface(string def)
{
protected:	//privateだとなぜか駄目
	mixin("interface I { " ~ def ~ "}");

private:
	alias MakeSignatureTbl!(I, 0).result allNames;
	alias MakeSignatureTbl!(I, 1).result allFpSigs;
	alias MakeSignatureTbl!(I, 2).result allDgSigs;
	
	void*				objptr;
	Tuple!(allFpSigs)	funtbl;

	template Sig2Idx(string Name, Args...)
	{
		template Impl(int i, string Name, Args...)
		{
			static if( i < allNames.length ){
				static if( allNames[i] == Name
						&& is(ParameterTypeTuple!(allFpSigs[i]) == Args) ){
					enum result = i;
				}else{
					enum result = Impl!(i+1, Name, Args).result;
				}
			}else{
				enum result = -1;
			}
		}
		enum result = Impl!(0, Name, Args).result;
	}

public:
	this(T)(T obj) if( isAllContains!(I, T)() ){
		foreach( i, name; allNames ){
			allDgSigs[i] dg = mixin("&obj." ~ name);
			
			static if( i == 0 ) objptr = dg.ptr;
			funtbl.field[i] = dg.funcptr;
			writefln("[%s] : %08X", i, funtbl.field[i]);
		}
	}
	
	auto opDispatch(string Name, Args...)(Args args)
	{
		enum i = Sig2Idx!(Name, Args).result;
		static assert(i >= 0,
			"member '" ~ Name ~ "' not found in " ~ allNames.stringof);
		return composeDg(objptr, funtbl.field[i])(args);
	}
	auto opDispatch(string Name, Args...)(Args args) const
	{
		pragma(msg, "aaa");
	}
}

unittest
{
	static class A
	{
		int draw()				{ return 1; }
		int draw() const		{ return 10; }
	}
	alias Interface!q{
		int draw();
		int draw() const;
	} Drawable;
	
	Drawable d = new A();
	assert( composeDg(d.objptr, d.funtbl.field[0])()  == 1);	// int draw()
	assert( composeDg(d.objptr, d.funtbl.field[1])()  == 10);	// int draw() const
}
version(none) unittest
{
	class A
	{
		int draw()				{ return 1; }
		int draw() const		{ return 10; }
	}
	alias Interface!q{
		int draw();
		int draw() const;
	} Drawable;
	
	Drawable d = new A();
	assert( composeDg(d.objptr, d.funtbl.field[0])()  == 1);	// int draw()
	assert( composeDg(d.objptr, d.funtbl.field[1])()  == 10);	// int draw() const
}

private static bool isAllContains(I, T)()
{
	alias MakeSignatureTbl!(I, 0).result allNames;
	alias MakeSignatureTbl!(I, 1).result allFpSigs;
	
	alias MakeSignatureTbl!(T, 0).result tgt_allNames;
	alias MakeSignatureTbl!(T, 1).result tgt_allFpSigs;
	
	bool result = true;
	foreach( i, name; allNames ){
		pragma(msg, name, ": ", allFpSigs[i]);
		
		bool res = false;
		foreach( j, s; tgt_allNames ){
			if( name == s
			 && is(ParameterTypeTuple!(allFpSigs[i])
			 	== ParameterTypeTuple!(tgt_allFpSigs[j])) ){
				res = true;
				break;
			}
		}
		result = result && res;
		if( !result ) break;
	}
	return result;
}



auto toDelegate(F)(auto ref F fp) if (isCallable!(F)) {

    static if (is(F == delegate))
    {
        return fp;
    }
    else static if (is(typeof(&F.opCall) == delegate)
                || (is(typeof(&F.opCall) V : V*) && is(V == function)))
    {
        return toDelegate(&fp.opCall);
    }
    else
    {
        alias typeof(&(new DelegateFaker!(F)).doIt) DelType;

        static struct DelegateFields {
            union {
                DelType del;
                //pragma(msg, typeof(del));

                struct {
                    void* contextPtr;
                    void* funcPtr;
                }
            }
        }

        // fp is stored in the returned delegate's context pointer.
        // The returned delegate's function pointer points to
        // DelegateFaker.doIt.
        DelegateFields df;

        df.contextPtr = cast(void*) fp;

        DelegateFaker!(F) dummy;
        auto dummyDel = &(dummy.doIt);
        df.funcPtr = cast(void*)dummyDel.funcptr;	//強制キャストを挟むことで、int delegate() const -> void* が可能になる

        return df.del;
    }
}
