import std.stdio;
import E = expand;

alias E.expandImpl expandImpl;
alias E.expand     expand;

version(unittest)
{
	enum op = "+";
	template Temp(string A)
	{
		pragma(msg, A);
		enum Temp = "expanded_Temp";
	}
}
unittest
{

	// var in code
	static assert(mixin(expand!q{a ${op} b}) == q{a + b});

	// alt-string in code
	static assert(mixin(expand!q{`raw string`}) == q{`raw string`});


	// var in string 
	static assert(mixin(expand!q{"a ${op} b"}) == q{"a + b"});

	// var in raw-string
	static assert(mixin(expand!q{r"a ${op} b"}) == q{r"a + b"});

	// var in alt-string
	static assert(mixin(expand!q{`a ${op} b`}) == q{`a + b`});

	// var in quoted-string 
	static assert(mixin(expand!q{q{a ${op} b}}) == q{q{a + b}});
	static assert( mixin(expand!q{Temp!q{ x ${op} y }}) == q{Temp!q{ x + y }});


	// escape sequence test
	static assert(mixin(expand!q{"\a"})   == q{"\a"});
	static assert(mixin(expand!q{"\xA1"}) == q{"\xA1"});
	static assert(mixin(expand!q{"\""})   == q{"\""});


	// var in var
	static assert(!__traits(compiles, mixin(expand!q{${ a ${op} b }}) ));


	static assert(mixin(expand!q{"\0"})          == q{"\0"});
	static assert(mixin(expand!q{"\01"})         == q{"\01"});
	static assert(mixin(expand!q{"\012"})        == q{"\012"});
	static assert(mixin(expand!q{"\u0FFF"})      == q{"\u0FFF"});
	static assert(mixin(expand!q{"\U00000FFF"})  == q{"\U00000FFF"});


	// var in string in var
//	writeln(   expandImpl(q{${ Temp!" x ${op} y " }}) );
//	writeln(       expand!q{${ Temp!" x ${op} y " }}  );	// CTFE bug?
//	writeln( mixin(expand!q{${ Temp!" x ${op} y " }}) );
//	writeln( mixin(`` ~  Temp!(" x " ~ op ~ " y ")  ~ ``) );
//	static assert(mixin(expand!q{${ Temp!" x ${op} y " }}) == "expanded_Temp");

	// var in raw-string in var
//	writeln(   expandImpl(q{${ Temp!r" x ${op} y " }}) );
//	writeln(       expand!q{${ Temp!r" x ${op} y " }}  );	// CTFE bug?
//	writeln( mixin(expand!q{${ Temp!r" x ${op} y " }}) );
//	static assert(mixin(expand!q{${ Temp!r" x ${op} y "} }) == "expanded_Temp");

	// var in alt-string in var
//	writeln(   expandImpl(q{${ Temp!` x ${op} y ` }}) );
//	writeln(       expand!q{${ Temp!` x ${op} y ` }}  );	// CTFE bug?
//	writeln( mixin(expand!q{${ Temp!` x ${op} y ` }}) );
//	static assert(mixin(expand!q{${ Temp!` x ${op} y ` }}) == "expanded_Temp");

	// var in quoted-string in var
//	writeln(   expandImpl(q{${ Temp!q{ x ${op} y } }}) );
//	writeln(       expand!q{${ Temp!q{ x ${op} y } }}  );	// CTFE bug?
//	writeln( mixin(expand!q{${ Temp!q{ x ${op} y } }}) );
//	static assert(mixin(expand!q{${ Temp!q{ x ${op} y } }}) == "expanded_Temp");
//	static assert(`` ~  Temp!(q{ x } ~ op ~ q{ y })  ~ `` == "expanded_Temp");


/+
	// --------
		//alias Sequence!("a", "b", "c") ParamNames;
		
		enum inner = expand!q{
	join([staticMap!(
		Instantiate!q{ "a" ~ to!string(a) }.With,
		staticIota!(0, 5))], ", ")
};
pragma(msg, inner);
		static assert(inner == mixin(q{
	join([a0, a1, a2, a3, a4], ", ")
}));

		enum res = expand!q{
alias Sequence!(${
	join([staticMap!(
		Instantiate!q{ "a" ~ to!string(a) }.With,
		staticIota!(0, 5))], ", ")
	}) args;
};
		pragma(msg, res);

		static assert(res == q{`
alias Sequence!(`~
	join([staticMap!(
		Instantiate!q{ "a" ~ to!string(a) }.With,
		staticIota!(0, 5))], ", ")
	~`) args;
`});
	// --------
	enum Attr = "";
	enum name = "func";
	enum decl = mixin(expand!q{
		${Attr}
		ReturnType
		${name}
		(${Join!(Wrap!ParamStrings, ", ")})
		{
			alias Sequence!(${
				Join!(Wrap!(
					staticMap!(
						Instantiate!` "a" ~ to!string(a) `.With,
						staticIota!(0, staticLength!(FTI.Parameters)))), ", ")
				}) args;
			mixin(code);
		}
	});
	pragma(msg, decl);
	
	enum test = mixin(expand!q{ `test ${in} alt-string` });
	static assert(test == q{ `test in alt-string` });
+/
}



version(RunTest) void main()
{
/+
		auto s = test(q{
		${StringOf!(FTI.storageClass)}
		${StringOf!(FTI.attributes)}
		FTI.ReturnType
		${name}
		(${Join!(Wrap!ParamStrings, ", ")})
		{
			alias Sequence!(${
				Join!(Wrap!(
					staticMap!(
						Instantiate!` "a" ~ to!string(a) `.With,
						staticIota!(0, staticLength!(FTI.Parameters)))), ", ")
				}) args;
			mixin(code);
		}
	});
	writeln(s);
+/
}
