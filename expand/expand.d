import std.algorithm : startsWith;
import std.stdio;

/**
	epandは与えられた文字列をCodeとして扱い、
	${...}で囲まれた式を文字列に評価される変数/式として
	展開を行う。
 */
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
	enum expand = expandImpl(code);
//	pragma(msg, "----");
//	pragma(msg, "1: ", code);
//	pragma(msg, "2: ", expand);
}

private @trusted
{
	public string expandImpl(string code)
	{
		auto s = Slice(Kind.CODESTR, code);
		s.parseCode();
		return "`" ~ s.buffer ~ "`";
	}

	bool isoctdigit(dchar c)
	{
		return '0'<=c && c<='7';
	}
	bool ishexdigit(dchar c)
	{
		return ('0'<=c && c<='9') || ('A'<=c && c<='F') || ('a'<=c && c<='f');
	}

	enum Kind
	{
		METACODE=0,
		CODESTR,
		STR_IN_METACODE,
		ALT_IN_METACODE,
		RAW_IN_METACODE,
		QUO_IN_METACODE,
	}

	struct Slice
	{
		version(RunTest) uint level = 0;
		Kind current;
		string buffer;
		size_t eaten;
		
		this(Kind c, string h, string t=null){
			current = c;
			if (t is null)
			{
				buffer = h;
				eaten = 0;
			}
			else
			{
				buffer = h ~ t;
				eaten = h.length;
			}
		}
		
		bool chomp(string s)
		{
			auto res = startsWith(tail, s);
			if (res)
			{
				eaten += s.length;
	version(RunTest) if (!__ctfe) writefln("chomp!%s(%s, %s), [%s] / [%s]", level, s, current, head, tail);
			}
			return res;
		}
		void chomp(size_t n)
		{
			if (eaten + n <= buffer.length)
			{
				eaten += n;
	version(RunTest) if (!__ctfe) writefln("chomp!%s(%s, %s), [%s] / [%s]", level, n, current, head, tail);
			}
		}
		
		@property bool  exist() {return eaten < buffer.length;}
		@property string head() {return buffer[0..eaten];}
		@property string tail() {return buffer[eaten..$];}

		bool parseEsc()
		{
			if (chomp(`\`))
			{
				if (chomp("x"))
					chomp(1), chomp(1);
				else
					chomp(1);
				return true;
			}
			else
				return false;
		}
		bool parseStr()
		{
			if (chomp(`"`))
			{
				auto s = Slice(
					(current == Kind.METACODE ? Kind.STR_IN_METACODE : current),
					tail);
	version(RunTest) if (!__ctfe) s.level = level + 1;
				while (s.exist && !s.chomp(`"`))
				{
					if (s.parseVar()) continue;
					if (s.parseEsc()) continue;
					s.chomp(1);
				}
				this = Slice(
					current,
					(current == Kind.METACODE
						? head[0..$-1] ~ `("` ~ s.head[0..$-1] ~ `")`
						: head[0..$] ~ s.head[0..$]),
					s.tail);
	version(RunTest) if (!__ctfe) level = s.level - 1;
				
				return true;
			}
			else
				return false;
		}
		bool parseAlt()
		{
			if (chomp("`"))
			{
				auto s = Slice(
					(current == Kind.METACODE ? Kind.ALT_IN_METACODE : current),
					tail);
	version(RunTest) if (!__ctfe) s.level = level + 1;
				while (s.exist && !s.chomp("`"))
				{
					if (s.parseVar()) continue;
					s.chomp(1);
				}
	version(RunTest) if (!__ctfe) writefln("set_slice!%s(alt, %s), [%s] / [%s]", s.level, s.current, s.head, s.tail);
				this = Slice(
					current,
					(current == Kind.METACODE
						? head[0..$-1] ~ "(`" ~ s.head[0..$-1] ~ "`)"
						: head[0..$-1] ~ "` ~ \"`\" ~ `" ~ s.head[0..$-1] ~ "` ~ \"`\" ~ `"),
					s.tail);
	version(RunTest) if (!__ctfe) level = s.level - 1;
	version(RunTest) if (!__ctfe) writefln("set_slice!%s(alt, %s), [%s] / [%s]", level, current, head, tail);
				return true;
			}
			else
				return false;
		}
		bool parseRaw()
		{
			if (chomp(`r"`))
			{
				auto s = Slice(
					(current == Kind.METACODE ? Kind.RAW_IN_METACODE : current),
					tail);
	version(RunTest) if (!__ctfe) s.level = level + 1;
				while (s.exist && !s.chomp(`"`))
				{
					if (s.parseVar()) continue;
					s.chomp(1);
				}
				this = Slice(
					current,
					(current == Kind.METACODE
						? head[0..$-2] ~ `(r"` ~ s.head[0..$-1] ~ `")`
						: head[0..$] ~ s.head[0..$]),
					s.tail);
				
	version(RunTest) if (!__ctfe) level = s.level - 1;
				return true;
			}
			else
				return false;
		}
		bool parseQuo()
		{
			// TODO: q{}は正しいDのシンボルを含む、という制限がある。
			// 変数展開の境界が正しいシンボルを作らない場合はどうするか？
			// →(バッククォートをEscapeしながら)AltStringに展開するしかない。
			
			if (chomp(`q{`))
			{
				auto s = Slice(
					(current == Kind.METACODE ? Kind.QUO_IN_METACODE : current),
					tail);
	version(RunTest) if (!__ctfe) s.level = level + 1;
				if (s.parseCode!`}`())
				{
					this = Slice(
						current,
						(current == Kind.METACODE
							? head[0..$-2] ~ `(q{` ~ s.head[0..$-1] ~ `})`
							: head[] ~ s.head),
						s.tail);
				}
	version(RunTest) if (!__ctfe) level = s.level - 1;
				return true;
			}
			else
				return false;
		}
		bool parseBlk()
		{
			if (chomp(`{`))
				return parseCode!`}`();
			else
				return false;
		}
		bool parseVar()
		{
			if (chomp(`${`))
			{
				if (current == Kind.METACODE)
					if (__ctfe)
						assert(0, "Invalid var in raw-code.");
					else
						throw new Exception("Invalid var in raw-code.");
				
				auto s = Slice(
					Kind.METACODE,
					tail);
	version(RunTest) if (!__ctfe) s.level = level + 1;
				s.parseCode!`}`();
	version(RunTest) if (!__ctfe) writefln("set_slice!%s(var, %s), [%s] / [%s]", s.level, s.current, s.head, s.tail);
				
				string open, close;
				switch(current)
				{
				case Kind.CODESTR		:	open = "`" , close = "`";	break;
				case Kind.STR_IN_METACODE:	open = `"` , close = `"`;	break;
				case Kind.ALT_IN_METACODE:	open = "`" , close = "`";	break;
				case Kind.RAW_IN_METACODE:	open = `r"`, close = `"`;	break;
				case Kind.QUO_IN_METACODE:	open = `q{`, close = `}`;	break;
				}
				
				this = Slice(
					current,
					(head[0..$-2] ~ close ~ " ~ " ~ s.head[0..$-1] ~ " ~ " ~ open),
					s.tail);
	version(RunTest) if (!__ctfe) level = s.level - 1;
	version(RunTest) if (!__ctfe) writefln("set_slice!%s(var, %s), [%s] / [%s]", level, current, head, tail);
				return true;
			}
			else
				return false;
		}
		bool parseCode(string end=null)()
		{
			enum endCheck = end ? "!chomp(end)" : "true";
			
			while (exist && mixin(endCheck))
			{
				if (parseStr()) continue;
				if (parseAlt()) continue;
				if (parseRaw()) continue;
				if (parseQuo()) continue;
				if (parseBlk()) continue;
				if (parseVar()) continue;
				chomp(1);
			}
			return true;
		}
	}
}

import expand_utest;
