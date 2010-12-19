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
	T _payload;
	bool filled = false;
	
	this(T data)
	{
		_payload = data;
		filled = true;
	}
	
	alias _payload this;
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

	static Optional!ubyte ascii2hex(char c)
	{
		if (!isxdigit(c))
			return typeof(return)();//error();
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
		char[] result;
		result.length = s.length;
		foreach (i; 0..s.length)
			result[$-1-i] = s[i];
		return result.idup;
	}

	static string formatReal(real r)
	{
		if (r == +cast(real)0)
			return "0";
		else if (r == -cast(real)0)
			return "-0";
		else if (r == +real.infinity)
			return "inf";
		else if (r == -real.infinity)
			return "-inf";
		else if (r !<>= 0)
			return "nan";
		else
		{
			string result;
			int sign = 1;
			if (r < 0) sign = -1, r *= -1;
			
			{	ulong n = cast(ulong)r;
				ulong i = 1;
				while (n > 0)
				{
					ubyte mod = cast(ubyte)((n / i) % 10);
					result ~= cast(char)(mod + '0');
					n -= i * mod;
					r -= i * mod;
					i *= 10;
				}
				result = reverse(result);
			}
			
			int dig = result.length;
			if (r > 0 && real.dig > dig)
			{
				dig = real.dig - result.length;
				real lim = 5.L * 10.L^^(-(dig+1));
				
				if (r >= lim)
				{
					result ~= ".";
					real i = 0.1;
					while (r > lim)
					{
						ubyte mod = cast(ubyte)((r / i) % 10);
						result ~= cast(char)(mod + '0');
						r -= i * mod;
						i /= 10;
					}
				}
			}
			return result;
		}
	}

	static real bytes2real(ubyte[real.sizeof] data)
	{
		static real pow2(int signed_n)
		{
			uint n = signed_n < 0 ? -signed_n : signed_n;
			real result = (n&1) ? 2.0L : 1.0L;
			for (uint shift=1; n; ++shift,n>>=1)
				if (n&1)
					result *= 1<<shift;
			if (signed_n < 0)
				result = 1.0L / result;
			return result;
		}
		static assert(pow2(2) == 4);
		static assert(pow2(0) == 1);
		static assert(pow2(-2) == 0.25);
		
		
		enum uint mant_dig = real.mant_dig;
		enum uint expo_dig = real.sizeof*8 - mant_dig - 1;
		static assert(mant_dig == 64);
		static assert(expo_dig == 15);
		enum int  expo_bias = cast(int)0x3FFF;
		//enum real mant_bias = 2 ^^ cast(real)(mant_dig-1);
		enum real mant_bias = pow2(mant_dig-1);
		version(LittleEndian){}else static assert(0);
		
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
	//	writefln("byte2real data = %x", data);
	//	writefln("byte2real mant = %x", mant);
	//	writefln("byte2real expo = %x", expo);
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
	//		writefln("r = %s * %s * 2^%s", sign, mant_u, expo_s);
			//auto r = sign * mant_u * 2^^cast(real)expo_s;
			auto r = sign * mant_u * pow2(expo_s);
	//		writefln("r = %s", r);
			return r;
		}
	}

	Optional!string getReal()
	{
		ubyte[real.sizeof] data;
		
		if (ni + 10 * 2 > name.length)
			return typeof(return)();//error();
		for (size_t i = 0; i < 10; i++)
		{	ubyte b;

			auto hex1 = ascii2hex(name[ni + i * 2    ]);
			auto hex2 = ascii2hex(name[ni + i * 2 + 1]);
			if (!hex1 || !hex2) return typeof(return)();
			b = cast(ubyte)((hex1 << 4) + hex2);
			data[i] = b;
		}
		ni += 10 * 2;
		if (__ctfe)
		{
	//		writefln("data = %s", data);
		//	return typeof(return)(format(bytes2real(data)));
			return typeof(return)(formatReal(bytes2real(data)));
		}
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
				return typeof(return)();//error();
			result = result * 10 + i;
			ni++;
		}
		return typeof(return)(result);
	}

	Optional!string parseSymbolName()
	{
		//writefln("parseSymbolName() %d", ni);
		//size_t i = parseNumber();
		auto i = parseNumber();
		if (!i) return typeof(return)();
		if (ni + i > name.length)
			return typeof(return)();//error();
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
				result = parseTemplateInstanceName();
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
			if (!s) return typeof(return)();
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
			return typeof(return)();//error();
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
				p = parseType() ~ "[]";
				goto L1;

			case 'P':								 // pointer
				p = parseType() ~ "*";
				goto L1;

			case 'G':								 // static array
			{	size_t ns = ni;
				if (!parseNumber()) return typeof(return)();
				size_t ne = ni;
				p = parseType() ~ "[" ~ name[ns .. ne] ~ "]";
				goto L1;
			}

			case 'H':								 // associative array
				p = parseType();
				p = parseType() ~ "[" ~ p ~ "]";
				goto L1;

			case 'D':								 // delegate
				isdelegate = 1;
				goto Lagain;

			case 'M':
				hasthisptr = true;
				goto Lagain;

			case 'y':
				p = "immutable(" ~ parseType() ~ ")";
				goto L1;

			case 'x':
				p = "const(" ~ parseType() ~ ")";
				goto L1;

			case 'O':
				p = "shared(" ~ parseType() ~ ")";
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
						return typeof(return)();//error();
					char c = name[ni];
					if (c == 'Z')
						break;
					if (c == 'X')
					{
						if (!args.length) return typeof(return)();//error();
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
							args ~= parseType();
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
					p ~= parseType() ~ " " ~ identifier ~ "(" ~ args ~ ")";
					return typeof(return)(p);
				}
				p = parseType() ~
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
				p ~= parseQualifiedName();
				goto L1;

			L1:
				if (isdelegate)
					return typeof(return)();//error();				// 'D' must be followed by function
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
		if (!s) return typeof(return)();
		auto result = s ~ "!(";
		int nargs;

		while (1)
		{	size_t i;

			if (ni >= name.length)
				return typeof(return)();//error();
			if (nargs && name[ni] != 'Z')
				result ~= ", ";
			nargs++;
			switch (name[ni++])
			{
				case 'T':
					result ~= parseType();
					continue;

				case 'V':
					result ~= parseType() ~ " ";
					if (ni >= name.length)
						return typeof(return)();//error();
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
								return typeof(return)();//error();
							result ~= "-" ~ name[i .. ni];
							break;

						case 'n':
							result ~= "null";
							break;

						case 'e':
							auto str = getReal();
							if (!str) return typeof(return)();
							result ~= str;
							break;

						case 'c':
							auto str = getReal();
							if (!str) return typeof(return)();
							result ~= str;
							result ~= '+';
							str = getReal();
							if (!str) return typeof(return)();
							result ~= str;
							result ~= 'i';
							break;

						case 'a':
						case 'w':
						case 'd':
						{	char m = name[ni - 1];
							if (m == 'a')
								m = 'c';
							size_t n = parseNumber();
							if (!n) return typeof(return)();
							if (ni >= name.length || name[ni++] != '_' ||
								ni + n * 2 > name.length)
								return typeof(return)();//error();
							result ~= '"';
							for (i = 0; i < n; i++)
							{
								auto hex1 = ascii2hex(name[ni + i * 2    ]);
								auto hex2 = ascii2hex(name[ni + i * 2 + 1]);
								if (!hex1 || !hex2) return typeof(return)();
								result ~= cast(char)((hex1 << 4) + hex2);
							}
							ni += n * 2;
							result ~= '"';
							result ~= m;
							break;
						}

						default:
							return typeof(return)();//error();
							break;
					}
					continue;

				case 'S':
					auto sn = parseSymbolName();
					if (!sn) return typeof(return)();
					result ~= sn;
					continue;

				case 'Z':
					break;

				default:
					return typeof(return)();//error();
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
			auto s = dem.parseQualifiedName();
			if (!s) goto Lnot;
			result = s;
			s = dem.parseType(result);
			if (!s) goto Lnot;
			result = s;
			while(dem.ni < dem.name.length){
				s = dem.parseQualifiedName();
				if (!s) goto Lnot;
				result ~= " . " ~ dem.parseType(s);
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


version(unittest)
{
	static const string[2][] table =
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
}
unittest
{
	debug(demangle) printf("demangle.demangle.unittest\n");


	foreach (i, name; table)
	{
		string r = demangle(name[0]);
		assert(r == name[1],
				"table entry #" ~ to!string(i) ~ ": '" ~ name[0]
				~ "' demangles as '" ~ r ~ "' but is expected to be '"
				~ name[1] ~ "'");

	}
}
template staticCheck(int n)
{
	pragma(msg, "[", n, "] ", table[n][0]);
	pragma(msg, "    ", table[n][1]);
	pragma(msg, "    ", demangle(table[n][0]));
	enum staticCheck = demangle(table[n][0]) == table[n][1];
}
unittest
{
	static assert(allSatisfy!(staticMap!(staticCheck, staticIota!(0, table.length))));
}

version(unittest)
{
	void main(){
		void printReal(real r){
			union Data{
				ubyte[real.sizeof] data;	//caution!! LittleEndian in x86
				real val;
			}
			Data d;
			d.val = r;
			writefln("%2X : %s -> %s", d.data.reverse, r, format(r)); }
		
		printReal(0);
		printReal(+cast(real)0);
		printReal(-cast(real)0);
		printReal(+real.infinity);
		printReal(-real.infinity);
		printReal(real.nan);
		printReal(-real.nan);
		
		void printFormatReal(real r)
		{
			writefln("%s / %s", Demangle.formatReal(r), format(r));
		}
		
		printFormatReal(1);
		printFormatReal(4.2);
		printFormatReal(128);
		printFormatReal(1024.234);
	}
}

