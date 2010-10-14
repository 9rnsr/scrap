module meta_expand;

import std.conv;
import std.string;
import std.stdio;


private
{
	bool isoctdigit(dchar c){ return '0'<=c && c<='7'; }
	bool ishexdigit(dchar c){ return ('0'<=c && c<='9') || ('A'<=c && c<='F') || ('a'<=c && c<='f'); }

	struct ParseResult
	{
		string result;
		string remain;
		
		bool opCast(T)() if (is(T==bool))
		{
			return result.length > 0;
		}
		
		this(string res, string rem)
		{
			result = res;
			remain = rem;
		}
		this(string rem)
		{
			result = null;
			remain = rem;
		}
	}

	ParseResult parseStr(string code)
	{
		auto remain = chompPrefix(code, `"`);
		if (remain.length < code.length)
		{
			size_t i = code.length - remain.length;
			auto result = code[0 .. i];
			for (; i<code.length; ++i)
			{
				auto pVar = parseVar(code[i..$]);
				if (pVar)
				{
					result ~= "`~"
							~ pVar.result[2..$-1]
							~ "~`";
					i += pVar.result.length;
				}
				
				if (code[i] == '\\')
				{
					result ~= code[i];
					++i;
				}
				else if (code[i] == '\"')
				{
					result ~= code[i];
					return ParseResult(result, code[i+1..$]);
				}
				result ~= code[i];
			}
		}
		return ParseResult(code);
	}

	ParseResult parseAltStr(string code)
	{
		auto remain = chompPrefix(code, "`");
		if (remain.length < code.length)
		{
			foreach (i; 0..remain.length)
			{
				if (remain[i] == '`')
				{
					return ParseResult(code[0..1+i+1], remain[i+1..$]);
				}
			}
		}
		return ParseResult(code);
	}

	ParseResult parseRawStr(string code)
	{
		auto remain = chompPrefix(code, `r"`);
		if (remain.length < code.length)
		{
			foreach (i; 0..remain.length)
			{
				if (remain[i] == '\"')
				{
					return ParseResult(code[0..2+i+1], remain[i+1..$]);
				}
			}
		}
		return ParseResult(code);
	}

	ParseResult parseVar(string code)
	{
		auto remain = chompPrefix(code, `${`);
		if (remain.length < code.length)
		{
			foreach (i; 0..remain.length)
			{
				if (remain[i] == '}')
				{
					return ParseResult(code[0..2+i+1], remain[i+1..$]);
				}
			}
		}
		return ParseResult(code);
	}

	string expandCode(string code)
	{
		auto remain = code;
		auto result = "";
		while (remain.length)
		{
			auto pStr    = parseStr(remain);
			auto pAltStr = parseAltStr(remain);
			auto pRawStr = parseRawStr(remain);
			auto pVar    = parseVar(remain);
			
			if (pStr)
			{
				result ~= pStr.result;
				remain  = pStr.remain;
			}
			else if (pAltStr)
			{
				result ~= "`~\"`\"~`"
						~ pAltStr.result[1..$-1]
						~ "`~\"`\"~`";
				remain  = pAltStr.remain;
			}
			else if( pRawStr )
			{
				result ~= pRawStr.result;
				remain  = pRawStr.remain;
			}
			else if (pVar)
			{
				result ~= "`~"
						~ pVar.result[2..$-1]
						~ "~`";
				remain  = pVar.remain;
			}
			else
			{
				result ~= remain[0];
				remain  = remain[1..$];
			}
		}
		return result;
	}
}
/**
	Expand expression in code string
	----
	enum string op = "+";
	static assert(expand!q{ 1 ${op} 2 } == q{ 1 + 2 });
	----
	
	Using both mixin expression, it is easy making parameterized code-blocks.
	----
	template DeclFunc(string name)
	{
		mixin(expand!q{
			int ${name}(int a){ return a; }
		});
	}
	----
	DeclFunc template generates specified name function.
 */
template expand(string code)
{
	enum expand = "`" ~ expandCode(code) ~ "`";
}


version(unittest)
{
	template ExpandTest(string op, string from)
	{
		enum ExpandTest = mixin(expand!from);
	}
	static assert(ExpandTest!("+", q{a ${op} b})     == q{a + b});
	static assert(ExpandTest!("+", q{`raw string`})  == q{`raw string`});
	static assert(ExpandTest!("+", q{"a ${op} b"})   == q{"a + b"});
	static assert(ExpandTest!("+", q{r"${op}"})      == q{r"${op}"});
	static assert(ExpandTest!("+", q{`${op}`})       == q{`${op}`});
	static assert(ExpandTest!("+", q{"\a"})          == q{"\a"});
	static assert(ExpandTest!("+", q{"\xA1"})        == q{"\xA1"});
	static assert(ExpandTest!("+", q{"\0"})          == q{"\0"});
	static assert(ExpandTest!("+", q{"\01"})         == q{"\01"});
	static assert(ExpandTest!("+", q{"\012"})        == q{"\012"});
	static assert(ExpandTest!("+", q{"\u0FFF"})      == q{"\u0FFF"});
	static assert(ExpandTest!("+", q{"\U00000FFF"})  == q{"\U00000FFF"});

	static assert(ExpandTest!("+", q{"\""})          == q{"\""});

	static assert(ExpandTest!("+", q{${op} ${op}})   == q{+ +});
	static assert(ExpandTest!("+", q{"${op} ${op}"}) == q{"+ +"});
}
