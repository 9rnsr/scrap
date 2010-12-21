// Written in the D programming language.

/**
 * Demangle D mangled names.
 *
 * Macros:
 *  WIKI = Phobos/StdDemangle
 *
 * Copyright: Copyright Digital Mars 2000 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   $(WEB digitalmars.com, Walter Bright),
 *                        Thomas Kuehne, Frits van Bommel
 */
/*
 *          Copyright Digital Mars 2000 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module demangle;

//debug=demangle;                // uncomment to turn on debugging printf's

private import std.ctype;
private import std.string;
import std.conv;
private import std.utf;
import std.exception;

private import std.typetuple;
private import std.stdio;

private class MangleException : Exception
{
	this()
	{
		super("MangleException");
	}
}

struct Optional(T)
{
private:
	T _payload;
	bool filled = false;

public:
	this(T data)
	{
		_payload = data;
		filled = true;
	}
	
	ref T _get()
	{
		assert(filled);
		return _payload;
	}
	alias _get this;
	
	bool opCast(T:bool)(){ return filled; }
}

/*****************************
 * Demangle D mangled names.
 *
 * If it is not a D mangled name, it returns its argument name.
 * Example:
 *        This program reads standard in and writes it to standard out,
 *        pretty-printing any found D mangled names.
-------------------
import std.stdio;
import std.ctype;
import std.demangle;

int main()
{   char[] buffer;
    bool inword;
    int c;

    while ((c = fgetc(stdin)) != EOF)
    {
        if (inword)
        {
            if (c == '_' || isalnum(c))
                buffer ~= cast(char) c;
            else
            {
                inword = false;
                writef(demangle(buffer), cast(char) c);
            }
        }
        else
        {   if (c == '_' || isalpha(c))
            {   inword = true;
                buffer.length = 0;
                buffer ~= cast(char) c;
            }
            else
                writef(cast(char) c);
        }
    }
    if (inword)
        writef(demangle(buffer));
    return 0;
}
-------------------
 */


struct Demangle
{
	string name;
	size_t ni;

/+	static void error()
	{
		//writefln("error()");
		if (__ctfe)
			assert(0);
		else
			throw new MangleException();
	}+/
	enum error = q{return typeof(return)();};

	static Optional!ubyte ascii2hex(char c)
	{
		if (!isxdigit(c))
			mixin(error);
		return typeof(return)(
			  cast(ubyte)
			  ( (c >= 'a') ? c - 'a' + 10 :
				(c >= 'A') ? c - 'A' + 10 :
							 c - '0'
			  )
			);
	}

	static string reverse(string s)
	{
		char[] r;
		r.length = s.length;
		foreach (i; 0..s.length)
			r[$-1-i] = s[i];
		return r.idup;
	}

	static string formatLong(long n)
	{
		string sign;
		if (n < 0) sign = "-", n = -n;
		
		string s;
		long i = 1;
		do{
			ubyte mod = cast(ubyte)((n / i) % 10);
			s ~= cast(char)(mod + '0');
			n -= i * mod;
			i *= 10;
		}while (n > 0)
		return reverse(s);
	}
	unittest
	{
		static assert(Demangle.formatLong(0)	== "0");
	}
	
	static string formatReal(real r)
	{
		if (r == +0.0L)
			return "0";
	//	else if (r == -0.0L)
	//		return "-0";
		else if (r == +real.infinity)
			return "inf";
		else if (r == -real.infinity)
			return "-inf";
		else if (r !<>= 0)
			return "nan";
		else
		{
			string sign = r < 0 ? "-" : "";
			if (r < 0) r *= -1;
			
			string nstr = formatLong(cast(long)r);
			r -= cast(ulong)r;
			
			string fstr;
			if (r == 0) goto Lend;
			int dig = real.dig - nstr.length;
			if (dig <= 0) goto Lend;
			
			auto nf = cast(ulong)(r * 10.0L^^(dig+1));
			fstr = "." ~ formatLong(cast(long)(nf + (nf % 10 >= 5 ? 10 : 0) / 10));
			auto len = fstr.length;
			while (fstr[len-1] == '0') --len;
			fstr = fstr[0..len];
			
		  Lend:
			return sign ~ nstr ~ fstr;
		}
	}
	unittest
	{
		static assert(Demangle.formatReal(+0.0L)			== "0");
	//	static assert(Demangle.formatReal(-0.0L)			== "-0");
		static assert(Demangle.formatReal(+real.infinity)	== "inf");
		static assert(Demangle.formatReal(-real.infinity)	== "-inf");
		static assert(Demangle.formatReal(real.nan)			== "nan");
		static assert(Demangle.formatReal(1)				== "1");
		static assert(Demangle.formatReal(4.2)				== "4.2");
		static assert(Demangle.formatReal(0.24)				== "0.24");
		static assert(Demangle.formatReal(1024.123)			== "1024.123");
		static assert(Demangle.formatReal(-1.4142)			== "-1.4142");
	}

	static real bytes2real(ubyte[real.sizeof] data)
	{
		enum uint mant_dig = real.mant_dig;
		enum uint expo_dig = real.sizeof*8 - mant_dig - 1;
		static assert(mant_dig == 64);
		static assert(expo_dig == 15);
		enum int  expo_bias = cast(int)0x3FFF;
		enum real mant_bias = 2 ^^ cast(real)(mant_dig-1);
		version(LittleEndian){}else static assert(0);
////	pragma(msg, "expo_bias = ", expo_bias);
////	pragma(msg, "mant_bias = ", mant_bias, ", ^^=", 2 ^^ cast(real)(mant_dig-1));
		
		auto  sign = data[9] & 0x80 ? -1 : 1;
		uint  expo = ((cast(uint)data[9]&0x7F)<<8) + cast(uint)data[8];
		ulong mant = (  (cast(ulong)data[7] << 56)
					  + (cast(ulong)data[6] << 48)
					  + (cast(ulong)data[5] << 40)
					  + (cast(ulong)data[4] << 32)
					  + (cast(ulong)data[3] << 24)
					  + (cast(ulong)data[2] << 16)
					  + (cast(ulong)data[1] <<  8)
					  + (cast(ulong)data[0] <<  0) );
////	writefln("byte2real data = %x", data);
////	writefln("byte2real mant = %x", mant);
////	writefln("byte2real expo = %x", expo);
		if (expo == 0x7FFF)
			if (mant != 0)
				return real.nan;
			else
				return sign * real.infinity;
		else if (expo == 0 && mant == 0)
			return sign * (cast(real)0);
		else
		{
			int  expo_s = cast(int )expo - expo_bias;
			real mant_u = cast(real)mant / mant_bias;
			return sign * mant_u * 2.0L^^expo_s;
		}
	}

	Optional!string getReal()
	{
		ubyte[real.sizeof] data;
		
		if (ni + 10 * 2 > name.length)
			mixin(error);
		for (size_t i = 0; i < 10; i++)
		{
			auto hex1 = ascii2hex(name[ni + i * 2    ]);
			auto hex2 = ascii2hex(name[ni + i * 2 + 1]);
			if (!hex1 || !hex2) mixin(error);
			data[i] = cast(ubyte)((hex1 << 4) + hex2);
		}
		ni += 10 * 2;
		if (__ctfe)
			return typeof(return)(formatReal(bytes2real(data)));
		else
			return typeof(return)(format(*cast(real*)&data[0]));
	}

	Optional!size_t parseNumber()
	{
		//writefln("parseNumber() %d", ni);
		size_t result;

		while (ni < name.length && isdigit(name[ni]))
		{	int i = name[ni] - '0';
			if (result > (size_t.max - i) / 10)
				mixin(error);
			result = result * 10 + i;
			ni++;
		}
		return typeof(return)(result);
	}

	Optional!string parseSymbolName()
	{
		//writefln("parseSymbolName() %d", ni);
		auto iopt = parseNumber();
		if (!iopt) mixin(error);
		size_t i = iopt;	// workaround for CTFE
		if (ni + i > name.length)
			mixin(error);
		string result;
		if (i >= 5 &&
			name[ni] == '_' &&
			name[ni + 1] == '_' &&
			name[ni + 2] == 'T')
		{
			size_t nisave = ni;
			bool err;
			ni += 3;
		//	try
		//	{
				auto t = parseTemplateInstanceName();
				if (!t) mixin(error);
				result = t;
				if (ni != nisave + i)
					err = true;
		//	}
		//	catch (MangleException me)
		//	{
		//		err = true;
		//	}
			ni = nisave;
			if (err)
				goto L1;
			goto L2;
		}
	  L1:
		result = name[ni .. ni + i];
	  L2:
		ni += i;
		return typeof(return)(result);
	}

	Optional!string parseQualifiedName()
	{
		//writefln("parseQualifiedName() %d", ni);
		string result;

		while (ni < name.length && isdigit(name[ni]))
		{
			if (result.length)
				result ~= ".";
			auto s = parseSymbolName();
			if (!s) mixin(error);
			result ~= s;
		}
		return typeof(return)(result);
	}

	Optional!string parseType(string identifier = null)
	{
		//writefln("parseType() %d", ni);
		int isdelegate = 0;
		bool hasthisptr = false; /// For function/delegate types: expects a 'this' pointer as last argument
	  Lagain:
		if (ni >= name.length)
			mixin(error);
		string p;
		switch (name[ni++])
		{
			case 'v':		p = "void";		goto L1;
			case 'b':		p = "bool";		goto L1;
			case 'g':		p = "byte";		goto L1;
			case 'h':		p = "ubyte";	goto L1;
			case 's':		p = "short";	goto L1;
			case 't':		p = "ushort";	goto L1;
			case 'i':		p = "int";		goto L1;
			case 'k':		p = "uint";		goto L1;
			case 'l':		p = "long";		goto L1;
			case 'm':		p = "ulong";	goto L1;
			case 'f':		p = "float";	goto L1;
			case 'd':		p = "double";	goto L1;
			case 'e':		p = "real";		goto L1;
			case 'o':		p = "ifloat";	goto L1;
			case 'p':		p = "idouble";	goto L1;
			case 'j':		p = "ireal";	goto L1;
			case 'q':		p = "cfloat";	goto L1;
			case 'r':		p = "cdouble";	goto L1;
			case 'c':		p = "creal";	goto L1;
			case 'a':		p = "char";		goto L1;
			case 'u':		p = "wchar";	goto L1;
			case 'w':		p = "dchar";	goto L1;

			case 'A':								 // dynamic array
				auto t = parseType();
				if (!t) mixin(error);
				p = t ~ "[]";
				goto L1;

			case 'P':								 // pointer
				auto t = parseType();
				if (!t) mixin(error);
				p = t ~ "*";
				goto L1;

			case 'G':								 // static array
			{	size_t ns = ni;
				auto n = parseNumber();		// workaround for CTFE(auto n == ...)
				if (!n) mixin(error);
				size_t ne = ni;
				auto t = parseType();
				if (!t) mixin(error);
				p = t ~ "[" ~ name[ns .. ne] ~ "]";
				goto L1;
			}

			case 'H':								 // associative array
				auto t = parseType();
				if (!t) mixin(error);
				p = t;
				t = parseType();
				if (!t) mixin(error);
				p = t ~ "[" ~ p ~ "]";
				goto L1;

			case 'D':								 // delegate
				isdelegate = 1;
				goto Lagain;

			case 'M':
				hasthisptr = true;
				goto Lagain;

			case 'y':
				auto t = parseType();
				if (!t) mixin(error);
				p = "immutable(" ~ t ~ ")";
				goto L1;

			case 'x':
				auto t = parseType();
				if (!t) mixin(error);
				p = "const(" ~ t ~ ")";
				goto L1;

			case 'O':
				auto t = parseType();
				if (!t) mixin(error);
				p = "shared(" ~ t ~ ")";
				goto L1;

			case 'F':								 // D function
			case 'U':								 // C function
			case 'W':								 // Windows function
			case 'V':								 // Pascal function
			case 'R':								 // C++ function
			{	char mc = name[ni - 1];
				string args;

				while (1)
				{
					if (ni >= name.length)
						mixin(error);
					char c = name[ni];
					if (c == 'Z')
						break;
					if (c == 'X')
					{
						if (!args.length) mixin(error);
						args ~= " ...";
						break;
					}
					if (args.length)
						args ~= ", ";
					switch (c)
					{
						case 'J':
							args ~= "out ";
							ni++;
							goto default;

						case 'K':
							args ~= "ref ";
							ni++;
							goto default;

						case 'L':
							args ~= "lazy ";
							ni++;
							goto default;

						default:
							auto t = parseType();
							if (!t) mixin(error);
							args ~= t;
							continue;

						case 'Y':
							args ~= "...";
							break;
					}
					break;
				}
				ni++;
				if (!isdelegate && identifier.length)
				{
					switch (mc)
					{
						case 'F': p = null;					break; // D function
						case 'U': p = "extern (C) ";		break; // C function
						case 'W': p = "extern (Windows) ";	break; // Windows function
						case 'V': p = "extern (Pascal) ";	break; // Pascal function
						default:  assert(0);
					}
					auto t = parseType();
					if (!t) mixin(error);
					p ~= t ~ " " ~ identifier ~ "(" ~ args ~ ")";
					return typeof(return)(p);
				}
				auto t = parseType();
				if (!t) mixin(error);
				p = t ~
					(isdelegate ? " delegate(" : " function(") ~
					args ~ ")";
				isdelegate = 0;
				goto L1;
			}

			case 'C':	p = "class ";		goto L2;
			case 'S':	p = "struct ";		goto L2;
			case 'E':	p = "enum ";		goto L2;
			case 'T':	p = "typedef ";		goto L2;

			L2:
				auto t = parseQualifiedName();
				if (!t) mixin(error);
				p ~= t;
				goto L1;

			L1:
				if (isdelegate)
					mixin(error);				// 'D' must be followed by function
				if (identifier.length)
					p ~= " " ~ identifier;
				return typeof(return)(p);

			default:
				size_t i = ni - 1;
				ni = name.length;
				p = name[i .. $];
				goto L1;
		}
	}

	Optional!string parseTemplateInstanceName()
	{
		auto s = parseSymbolName();
		if (!s) mixin(error);
		auto result = s ~ "!(";
		int nargs;

		while (1)
		{	size_t i;

			if (ni >= name.length)
				mixin(error);
			if (nargs && name[ni] != 'Z')
				result ~= ", ";
			nargs++;
			switch (name[ni++])
			{
				case 'T':
					auto t = parseType();
					if (!t) mixin(error);
					result ~= t;
					continue;

				case 'V':
					auto t = parseType();
					if (!t) mixin(error);
					result ~= t ~ " ";
					if (ni >= name.length)
						mixin(error);
					switch (name[ni++])
					{
						case '0': .. case '9':
							i = ni - 1;
							while (ni < name.length && isdigit(name[ni]))
								ni++;
							result ~= name[i .. ni];
							break;

						case 'N':
							i = ni;
							while (ni < name.length && isdigit(name[ni]))
								ni++;
							if (i == ni)
								mixin(error);
							result ~= "-" ~ name[i .. ni];
							break;

						case 'n':
							result ~= "null";
							break;

						case 'e':
							t = getReal();
							if (!t) mixin(error);
							result ~= t;
							break;

						case 'c':
							t = getReal();
							if (!t) mixin(error);
							result ~= t;
							result ~= '+';
							t = getReal();
							if (!t) mixin(error);
							result ~= t;
							result ~= 'i';
							break;

						case 'a':
						case 'w':
						case 'd':
						{	char m = name[ni - 1];
							if (m == 'a')
								m = 'c';
							auto tn = parseNumber();
							if (!tn) mixin(error);
							size_t n = tn;
							if (ni >= name.length || name[ni++] != '_' ||
								ni + n * 2 > name.length)
								mixin(error);
							result ~= '"';
							for (i = 0; i < n; i++)
							{
								auto hex1 = ascii2hex(name[ni + i * 2    ]);
								auto hex2 = ascii2hex(name[ni + i * 2 + 1]);
								if (!hex1 || !hex2) mixin(error);
								result ~= cast(char)((hex1 << 4) + hex2);
							}
							ni += n * 2;
							result ~= '"';
							result ~= m;
							break;
						}

						default:
							mixin(error);
							break;
					}
					continue;

				case 'S':
					auto t = parseSymbolName();
					if (!t) mixin(error);
					result ~= t;
					continue;

				case 'Z':
					break;

				default:
					mixin(error);
			}
			break;
		}
		result ~= ")";
		return typeof(return)(assumeUnique(result));
	}
}

string demangle(string name)
{
	if (name.length >= 3 &&
		name[0] == '_' &&
		name[1] == 'D' &&
		isdigit(name[2]))
	{
		auto dem = Demangle(name, 2);
		
	//	try
	//	{
			string result;
			auto t = dem.parseQualifiedName();
			if (!t) goto Lnot;
			result = t;
			t = dem.parseType(result);
			if (!t) goto Lnot;
			result = t;
			while(dem.ni < dem.name.length){
				t = dem.parseQualifiedName();
				if (!t) goto Lnot;
				result ~= " . " ~ dem.parseType(t);
			}

			if (dem.ni != dem.name.length)
				goto Lnot;
			return result;
	//	}
	//	catch (MangleException e)
	//	{
	//	}
	}

Lnot:
	// Not a recognized D mangled name; so return original
	return name;
}


string demangleType(string name)
{
	auto dem = Demangle(name, 0);
	auto s = dem.parseType();
	if (!s) return name;
	return s;
}

version(unittest)
{
	static const symbols =
	[
		[ "printf", 	 "printf" ],
		[ "_foo",		 "_foo" ],
		[ "_D88",		 "_D88" ],
		[ "_D4test3fooAa", "char[] test.foo"],
		[ "_D8demangle8demangleFAaZAa", "char[] demangle.demangle(char[])" ],
		[ "_D6object6Object8opEqualsFC6ObjectZi", "int object.Object.opEquals(class Object)" ],
		[ "_D4test2dgDFiYd", "double delegate(int, ...) test.dg" ],
		[ "_D4test58__T9factorialVde67666666666666860140VG5aa5_68656c6c6fVPvnZ9factorialf", "float test.factorial!(double 4.2, char[5] \"hello\"c, void* null).factorial" ],
		[ "_D4test101__T9factorialVde67666666666666860140Vrc9a999999999999d9014000000000000000c00040VG5aa5_68656c6c6fVPvnZ9factorialf", "float test.factorial!(double 4.2, cdouble 6.8+3i, char[5] \"hello\"c, void* null).factorial" ],
		[ "_D4test34__T3barVG3uw3_616263VG3wd3_646566Z1xi", "int test.bar!(wchar[3] \"abc\"w, dchar[3] \"def\"d).x" ],
		[ "_D8demangle4testFLC6ObjectLDFLiZiZi", "int demangle.test(lazy class Object, lazy int delegate(lazy int))"],
		[ "_D8demangle4testFAiXi", "int demangle.test(int[] ...)"],
		[ "_D8demangle4testFLAiXi", "int demangle.test(lazy int[] ...)"],
		[ "_D6plugin8generateFiiZAya", "immutable(char)[] plugin.generate(int, int)"],
		[ "_D6plugin8generateFiiZAxa", "const(char)[] plugin.generate(int, int)"],
		[ "_D6plugin8generateFiiZAOa", "shared(char)[] plugin.generate(int, int)"]
	];
	static const baseTypes =
	[
		[ void		.mangleof,	"void"		],
		[ bool		.mangleof,	"bool"		],
		[ byte		.mangleof,	"byte"		],
		[ ubyte		.mangleof,	"ubyte"		],
		[ short		.mangleof,	"short"		],
		[ ushort	.mangleof,	"ushort"	],
		[ int		.mangleof,	"int"		],
		[ uint		.mangleof,	"uint"		],
		[ long		.mangleof,	"long"		],
		[ ulong		.mangleof,	"ulong"		],
	//	[ cent		.mangleof,	"cent"		],
	//	[ ucent		.mangleof,	"ucent"		],
		[ float		.mangleof,	"float"		],
		[ double	.mangleof,	"double"	],
		[ real		.mangleof,	"real"		],
		[ ifloat	.mangleof,	"ifloat"	],
		[ idouble	.mangleof,	"idouble"	],
		[ ireal		.mangleof,	"ireal"		],
		[ cfloat	.mangleof,	"cfloat"	],
		[ cdouble	.mangleof,	"cdouble"	],
		[ creal		.mangleof,	"creal"		],
		[ char		.mangleof,	"char"		],
		[ wchar		.mangleof,	"wchar"		],
		[ dchar		.mangleof,	"dchar"		]
	];
	static const arrayTypes =
	[
		[ (int[])			.mangleof,	"int[]"			],
		[ (int[][])			.mangleof,	"int[][]"		]
	//	[ (int[string])		.mangleof,	"int[string]"	],	object.AssociativeArray!(immutable(char), int).AssociativeArray
		
	];
	static const pointerTypes =
	[
		[ (int*)			.mangleof,	"int*"		],
		[ (int**)			.mangleof,	"int**"		]
	];
	static const modifiers =
	[
		[ (const(int))			.mangleof,	"const(int)"			],
		[ (immutable(int))		.mangleof,	"immutable(int)"		],
		[ (shared(int))			.mangleof,	"shared(int)"			],
		[ (shared(const(int)))	.mangleof,	"shared(const(int))"	],
	];

	class C{}
	struct S{}
	enum E{A}
	static const aggregates =
	[
		[ C	.mangleof,	"class demangle.C"			],
		[ S	.mangleof,	"struct demangle.S"			],
		[ E	.mangleof,	"enum demangle.E"			]
	];

	template staticCheck(alias table, alias dem)
	{
		template staticCheck1(int n)
		{
			static assert(dem(table[n][0]) == table[n][1]);
			enum staticCheck1 = dem(table[n][0]) == table[n][1];
		}
		
		enum result = 
			allSatisfy!(staticMap!(
				staticCheck1,
				staticIota!(0, table.length)));
	}
	bool runtimeCheck(string[2][] table, string function(string) dem)
	{
		foreach (i, name; table)
		{
			string r = dem(name[0]);
			assert(r == name[1],
					"table entry #" ~ to!string(i) ~ ": '" ~ name[0]
					~ "' demangles as '" ~ r ~ "' but is expected to be '"
					~ name[1] ~ "'");
		}
		return true;
	}
}
unittest
{
	debug(demangle) printf("demangle.demangle.unittest\n");

	static assert(staticCheck!(symbols,			demangle).result);

	static assert(staticCheck!(baseTypes,		demangleType).result);
	static assert(staticCheck!(arrayTypes,		demangleType).result);
	static assert(staticCheck!(baseTypes,		demangleType).result);
	static assert(staticCheck!(pointerTypes,	demangleType).result);
	static assert(staticCheck!(modifiers,		demangleType).result);
	static assert(staticCheck!(aggregates,		demangleType).result);

	assert(runtimeCheck(symbols,		&demangle));

	assert(runtimeCheck(baseTypes,		&demangleType));
	assert(runtimeCheck(arrayTypes,		&demangleType));
	assert(runtimeCheck(baseTypes,		&demangleType));
	assert(runtimeCheck(pointerTypes,	&demangleType));
	assert(runtimeCheck(modifiers,		&demangleType));
	assert(runtimeCheck(aggregates,		&demangleType));
}


/**
 *	Demangle type or symbol.
 *	@@BUG@@ Symbol version does not work correctly.
 */
template demangleOf(T)
{
	enum demangleOf = demangleType(T.mangleof);
}
/// ditto
template demangleOf(alias A)
{
	pragma(msg, "demangleOf!alias");
	static if (is(typeof(A)))
		static if (__traits(compiles, { auto v = A; }))
			enum demangleOf = demangle(A.mangleof);
		else
			enum demangleOf = demangleType(A.mangleof);	// A is template
	else static if (is(A))
		enum demangleOf = demangleType(A.mangleof);
}

version(unittest)
{
	int global;
	void f(){}
	template Template(T){void f(){}}
}
unittest
{
//	f();				// instantiation?
//	Template!int.f();	// instantiation

//	static assert(demangleOf!global == "_D8demangle6globali");
//	static assert(demangleOf!f == "_D8demangle1fFZv");
//	static assert(demangleOf!(Template!int) == "__T8TemplateTiZ");	//?
	static assert(demangleOf!int == "int");
}

version(unittest)
{
	void main(){
	}
}
