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

import std.traits, std.typecons;
import extraits, extypecons;


/// 
struct Interface(string def)
{
protected:	//privateだとなぜか駄目
	mixin("interface I { " ~ def ~ "}");

private:
	alias AllMemFunNamesTuple!I allNames;
	alias AllMemFunPtrsTuple!I  allSigs;
	
	void*           objptr;
	Tuple!(allSigs) funtbl;

	template Sig2Idx(string Name, Args...)
	{
		template Impl(int i, string Name, Args...)
		{
			static if( i < allNames.length ){
				static if( allNames[i] == Name
						&& is(ParameterTypeTuple!(allSigs[i]) == Args) ){
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
	
	template Function2Delegate(T) if( isFunctionPointer!T )
	{
		pragma(msg, "Function2Delegate: ", T);
	//	static if( ParameterTypeTuple!T.length >= 1 ){
			// hack: タプル展開後の型に.stringofを適用すると
			//       余計な括弧が付いてくるので除去する
			mixin(
				"alias ReturnType!T delegate(" ~
					ParameterTypeTuple!T.stringof[1..$-1]
				~ ") Function2Delegate;"
			);
	//	}else{
	//		alias ReturnType!T delegate(ParameterTypeTuple!T)
	//			Function2Delegate;
	//	}
	}

public:
	this(T)(T obj) if( isAllContains!(I, T)() ){
		foreach( i, name; allNames ){
			pragma(msg, Function2Delegate!(
					typeof(funtbl.field[i])
				).stringof
				~ " dg = &obj." ~ name ~ ";");
			mixin(
				Function2Delegate!(
					typeof(funtbl.field[i])
				).stringof
				~ " dg = &obj." ~ name ~ ";"
			);
			
			static if( i == 0 ) objptr = dg.ptr;
			funtbl.field[i] = dg.funcptr;
		}
	}
	
	auto opDispatch(string Name, Args...)(Args args)
	{
		enum i = Sig2Idx!(Name, Args).result;
		static assert(i >= 0,
			"member '" ~ Name ~ "' not found in " ~ allNames.stringof);
		return composeDg(objptr, funtbl.field[i])(args);
	}
}


private static bool isAllContains(I, T)()
{
	alias AllMemFunNamesTuple!I allNames;
	alias AllMemFunPtrsTuple!I  allSigs;
	
	alias AllMemFunNamesTuple!T tgt_allNames;
	alias AllMemFunPtrsTuple!T  tgt_allSigs;
	
	bool result = true;
	foreach( i, name; allNames ){
		pragma(msg, name, ": ", allSigs[i]);
		
		bool res = false;
		foreach( j, s; tgt_allNames ){
			if( name == s
			 && is(ParameterTypeTuple!(allSigs[i])
			 	== ParameterTypeTuple!(tgt_allSigs[j])) ){
				res = true;
				break;
			}
		}
		result = result && res;
		if( !result ) break;
	}
	return result;
}
