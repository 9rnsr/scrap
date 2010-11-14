import std.stdio;
import E = expand;
 
alias E.TypeTuple		TypeTuple;
alias E.text			text;
alias E.expand			expand;
alias E.expandSplit		expandSplit;
alias E.splitVars		splitVars;
alias E.toStringNow		toStringNow;

version(unittest)
{
	enum op = "+";
	template Temp(string A)
	{
		enum Temp = "expanded_Temp";
	}
	template Test(int n)
	{
	}
	template TestType(alias A)
	{
		alias typeof(A) TestType;
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
	static assert(mixin(expand!q{Temp!q{ x ${op} y }}) == q{Temp!q{ x + y }});


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
	static assert(mixin(expand!q{${ Temp!" x ${op} y " }}) == "expanded_Temp");

	// var in raw-string in var
	static assert(mixin(expand!q{${ Temp!r" x ${op} y " }}) == "expanded_Temp");

	// var in alt-string in var
	static assert(mixin(expand!q{${ Temp!` x ${op} y ` }}) == "expanded_Temp");

	// var in quoted-string in var
	static assert(mixin(expand!q{${ Temp!q{ x ${op} y } }}) == "expanded_Temp");


	// non-paren identifier var
	enum string var = "test";
	static assert(mixin(expand!"ex: $var") == "ex: test");
	enum string var1234 = "test";
	static assert(mixin(expand!"ex: $var1234") == "ex: test");
	enum string _var = "test";
	static assert(mixin(expand!"ex: $_var!") == "ex: test!");
	
	// type stringnize
	alias double Double;
	struct S{}
	class C{}
	static assert(mixin(expand!q{enum t = "$int";}) == q{enum t = "int";});
	static assert(mixin(expand!q{enum t = "$Double";}) == q{enum t = "double";});
	static assert(mixin(expand!q{enum t = "new $S()";}) == q{enum t = "new S()";});
	static assert(mixin(expand!q{enum t = "new $C()";}) == q{enum t = "new C()";});
	static assert(mixin(expand!q{enum t = "${TestType!`str`}";}) == q{enum t = "string";});
	static assert(mixin(expand!q{enum t = "${Test!(10)}";}) == q{enum t = "Test!(10)";});	// template name
	
	// parsing comments 
	static assert(mixin(expand!"$var // $var\n$var") == "test // $var\ntest");
	static assert(mixin(expand!"$var /* $var */ $var") == "test /* $var */ test");
	static assert(mixin(expand!"$var q{ /* } */ } $var") == "test q{ /* } */ } test");
	static assert(mixin(expand!"$var /+ $var +/ $var") == "test /+ $var +/ test");
	static assert(mixin(expand!"$var /+$var/+ $var +/ $var+/ $var") == "test /+$var/+ $var +/ $var+/ test");
}
// sample unittest
unittest
{
	enum int a = 10;
	enum string op = "+";
	static assert(mixin(expand!q{ ${a*2} $op 2 }) == q{ 20 + 2 });
	
	writeln(mixin(expandSplit!"I call you $a times."));
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
