import std.stdio;
import E = expand;

//alias E.expand     expand;
alias E.expandFormat expandFormat;

version(unittest)
{
	enum op = "+";
	template Temp(string A)
	{
		enum Temp = "expanded_Temp";
	}
}
unittest
{
	static assert(mixin(expandFormat!q{}) == "");
	static assert(mixin(expandFormat!(1, ", ", 2)) == "1, 2");
}
unittest
{

	// var in code
	static assert(mixin(expandFormat!q{a %:{op} b}) == q{a + b});

	// alt-string in code
	static assert(mixin(expandFormat!q{`raw string`}) == q{`raw string`});


	// var in string 
	static assert(mixin(expandFormat!q{"a %:{op} b"}) == q{"a + b"});

	// var in raw-string
	static assert(mixin(expandFormat!q{r"a %:{op} b"}) == q{r"a + b"});

	// var in alt-string
	static assert(mixin(expandFormat!q{`a %:{op} b`}) == q{`a + b`});

	// var in quoted-string 
	static assert(mixin(expandFormat!q{q{a %:{op} b}}) == q{q{a + b}});
	static assert(mixin(expandFormat!q{Temp!q{ x %:{op} y }}) == q{Temp!q{ x + y }});


	// escape sequence test
	static assert(mixin(expandFormat!q{"\a"})   == q{"\a"});
	static assert(mixin(expandFormat!q{"\xA1"}) == q{"\xA1"});
	static assert(mixin(expandFormat!q{"\""})   == q{"\""});


	// var in var
	static assert(!__traits(compiles, mixin(expandFormat!q{%:{ a %:{op} b }}) ));


	static assert(mixin(expandFormat!q{"\0"})          == q{"\0"});
	static assert(mixin(expandFormat!q{"\01"})         == q{"\01"});
	static assert(mixin(expandFormat!q{"\012"})        == q{"\012"});
	static assert(mixin(expandFormat!q{"\u0FFF"})      == q{"\u0FFF"});
	static assert(mixin(expandFormat!q{"\U00000FFF"})  == q{"\U00000FFF"});


	// var in string in var
	static assert(mixin(expandFormat!q{%:{ Temp!" x %:{op} y " }}) == "expanded_Temp");

	// var in raw-string in var
	static assert(mixin(expandFormat!q{%:{ Temp!r" x %:{op} y " }}) == "expanded_Temp");

	// var in alt-string in var
	static assert(mixin(expandFormat!q{%:{ Temp!` x %:{op} y ` }}) == "expanded_Temp");

	// var in quoted-string in var
	static assert(mixin(expandFormat!q{%:{ Temp!q{ x %:{op} y } }}) == "expanded_Temp");


	// non-paren identifier var
	enum string var = "test";
	static assert(mixin(expandFormat!"ex: %:var") == "ex: test");
	enum string var1234 = "test";
	static assert(mixin(expandFormat!"ex: %:var1234") == "ex: test");
	enum string _var = "test";
	static assert(mixin(expandFormat!"ex: %:_var!") == "ex: test!");
}
// sample unittest
unittest
{
	enum int a = 10;
	enum string op = "+";
	static assert(mixin(expandFormat!q{ %:{a*2} %:op 2 }) == q{ 20 + 2 });
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
