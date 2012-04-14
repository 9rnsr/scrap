import std.algorithm : startsWith;
import std.ascii : isAlpha, isAlphaNum;
import std.traits : isCallable, isSomeString;
import std.typetuple : TypeTuple;
import std.conv : text;

/**
Expand expression in string literal, with mixin expression.
Expression in ${ ... } is implicitly converted to string (requires importing std.conv.to)
If expreesion is single variable, you can omit side braces.
--------------------
enum int a = 10;
enum string op = "+";
static assert(mixin(expand!q{ ${a*2} $op 2 }) == q{ 20 + 2 });
// a*2 is caluclated in this scope, and converted to string.
--------------------

Other example, it is easy making parameterized code-blocks.
--------------------
template DefFunc(string name)
{
  // generates specified name function.
  mixin(
    mixin(expand!q{
      int ${name}(int a){ return a; }
    })
  );
}
--------------------
 */
template expand(string s)
{
    enum expand = "text(" ~ expandSplit!s ~ ")";
}

template expandSplit(string s)
{
    enum expandSplit = "TypeTuple!(" ~ splitVars(s) ~ ")";
}

string splitVars(string code)
{
    auto s = Slice(Kind.CODESTR, code);
    s.parseCode();
    return "`" ~ s.buffer ~ "`";
}

template toStringNow(alias V)
{
    static if (is(typeof(V)))
    {
        static if (__traits(compiles, { auto v = V; }))
            alias V toStringNow;
        else
            enum toStringNow = V.stringof;  // V is template
    }
    else static if (is(V))
    {
        enum toStringNow = V.stringof;
    }
    else
        static assert(0, "undefined error with " ~ V.stringof);
}
template toStringNow(T)
{
    enum toStringNow = T.stringof;
}

private @trusted
{
    enum Kind
    {
        METACODE,
        CODESTR,
        STR_IN_METACODE,
        ALT_IN_METACODE,
        RAW_IN_METACODE,
        QUO_IN_METACODE,
    }

    string match(Pred)(string s, Pred pred)
    {
        static if (isCallable!Pred)
        {
            size_t eaten = 0;
            while (eaten < s.length && pred(s[eaten]))
                ++eaten;
            if (eaten)
                return s[0..eaten];
            return null;
        }
        else static if (isSomeString!Pred)
        {
            if (startsWith(s, pred))
                return s[0 .. pred.length];
            return null;
        }
    }
/+
    // match and eat
    string munch(Pred)(ref string s, Pred pred)
    {
        auto r = chomp(s, pred);
        if (r.length)
            s = s[r.length .. $];
        return r;
    }+/

    struct Slice
    {
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
                eaten += s.length;
            return res;
        }
        void chomp(size_t n)
        {
            if (eaten + n <= buffer.length)
                eaten += n;
        }

        @property bool  exist() {return eaten < buffer.length;}
        @property string head() {return buffer[0..eaten];}
        @property string tail() {return buffer[eaten..$];}

        bool parseEsc()
        {
            if (chomp(`\`))
            {
                if (chomp("x"))
                    chomp(2);
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
                auto save_head = head;  // workaround for ctfe

                auto s = Slice(
                    (current == Kind.METACODE ? Kind.STR_IN_METACODE : current),
                    tail);
                while (s.exist && !s.chomp(`"`))
                {
                    if (s.parseVar()) continue;
                    if (s.parseEsc()) continue;
                    s.chomp(1);
                }
                this = Slice(
                    current,
                    (current == Kind.METACODE
                        ? save_head[0..$-1] ~ `(text("` ~ s.head[0..$-1] ~ `"))`
                        : save_head[0..$] ~ s.head[0..$]),
                    s.tail);

                return true;
            }
            else
                return false;
        }
        bool parseAlt()
        {
            if (chomp("`"))
            {
                auto save_head = head;  // workaround for ctfe

                auto s = Slice(
                    (current == Kind.METACODE ? Kind.ALT_IN_METACODE : current),
                    tail);
                while (s.exist && !s.chomp("`"))
                {
                    if (s.parseVar()) continue;
                    s.chomp(1);
                }
                this = Slice(
                    current,
                    (current == Kind.METACODE
                        ? save_head[0..$-1] ~ "(text(`" ~ s.head[0..$-1] ~ "`))"
                        : save_head[0..$-1] ~ "` ~ \"`\" ~ `" ~ s.head[0..$-1] ~ "` ~ \"`\" ~ `"),
                    s.tail);
                return true;
            }
            else
                return false;
        }
        bool parseRaw()
        {
            if (chomp(`r"`))
            {
                auto save_head = head;  // workaround for ctfe

                auto s = Slice(
                    (current == Kind.METACODE ? Kind.RAW_IN_METACODE : current),
                    tail);
                while (s.exist && !s.chomp(`"`))
                {
                    if (s.parseVar()) continue;
                    s.chomp(1);
                }
                this = Slice(
                    current,
                    (current == Kind.METACODE
                        ? save_head[0..$-2] ~ `(text(r"` ~ s.head[0..$-1] ~ `"))`
                        : save_head[0..$] ~ s.head[0..$]),
                    s.tail);

                return true;
            }
            else
                return false;
        }
        bool parseQuo()
        {
            if (chomp(`q{`))
            {
                auto save_head = head;  // workaround for ctfe

                auto s = Slice(
                    (current == Kind.METACODE ? Kind.QUO_IN_METACODE : current),
                    tail);
                if (s.parseCode!`}`())
                {
                    this = Slice(
                        current,
                        (current == Kind.METACODE
                            ? save_head[0..$-2] ~ `(text(q{` ~ s.head[0..$-1] ~ `}))`
                            : save_head[] ~ s.head),
                        s.tail);
                }
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
        bool parseComment()
        {
            if (chomp(`//`))
            {
                while (exist && !chomp("\n"))
                    chomp(1);
                return true;
            }
            else if (chomp(`/*`))
            {
                while (exist && !chomp(`*/`))
                    chomp(1);
                return true;
            }
            return false;
        }
        bool parseNestedComment()
        {
            if (chomp(`/+`))
            {
                while (exist && !chomp(`+/`))
                {
                    if (parseNestedComment()) continue;
                    chomp(1);
                }
                return true;
            }
            return false;
        }
        private void checkVarNested()
        {
            if (current == Kind.METACODE)
                if (__ctfe)
                    assert(0, "Invalid var in raw-code.");
                else
                    throw new Exception("Invalid var in raw-code.");
        }
        private string encloseVar(string exp)
        {
            string open, close;
            switch(current)
            {
            case Kind.CODESTR       :   open = "`" , close = "`";   break;
            case Kind.STR_IN_METACODE:  open = `"` , close = `"`;   break;
            case Kind.ALT_IN_METACODE:  open = "`" , close = "`";   break;
            case Kind.RAW_IN_METACODE:  open = `r"`, close = `"`;   break;
            case Kind.QUO_IN_METACODE:  open = `q{`, close = `}`;   break;
            default:                    assert(0);
            }
//          return close ~ " ~ .std.conv.to!string(toStringNow!("~exp~")) ~ " ~ open;
            return close ~ ", toStringNow!("~exp~"), " ~ open;
        }
        bool parseVar()
        {
            if (auto r = match(tail, `$`))
            {
                auto t = tail[1..$];

                static bool isIdtHead(dchar c) { return c=='_' || isAlpha(c); }
                static bool isIdtTail(dchar c) { return c=='_' || isAlphaNum(c); }

                if (match(t, `{`))
                {
                    checkVarNested();

                    auto s = Slice(Kind.METACODE, t[1..$]);
                    s.parseCode!`}`();
                    this = Slice(current, head ~ encloseVar(s.head[0..$-1]), s.tail);

                    return true;
                }
                else if (auto r2 = match(t[0..1], &isIdtHead))
                {
                    checkVarNested();

                    auto id = t[0 .. 1 + match(t[1..$], &isIdtTail).length];
                    this = Slice(current, head ~ encloseVar(id), t[id.length .. $]);

                    return true;
                }
                return false;
            }
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
                if (parseComment()) continue;
                if (parseNestedComment()) continue;
                chomp(1);
            }
            return true;
        }
    }
}

version(unittest)
{
    enum op = "+";
    template ExpandTemp(string A)
    {
        enum ExpandTemp = "expanded_Temp";
    }
    template ExpandTest(int n)
    {
    }
    template ExpandType(alias A)
    {
        alias typeof(A) ExpandType;
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
    static assert(mixin(expand!q{ExpandTemp!q{ x ${op} y }}) == q{ExpandTemp!q{ x + y }});


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
    static assert(mixin(expand!q{${ ExpandTemp!" x ${op} y " }}) == "expanded_Temp");

    // var in raw-string in var
    static assert(mixin(expand!q{${ ExpandTemp!r" x ${op} y " }}) == "expanded_Temp");

    // var in alt-string in var
    static assert(mixin(expand!q{${ ExpandTemp!` x ${op} y ` }}) == "expanded_Temp");

    // var in quoted-string in var
    static assert(mixin(expand!q{${ ExpandTemp!q{ x ${op} y } }}) == "expanded_Temp");


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
    static assert(mixin(expand!q{enum t = "${ExpandType!`str`}";}) == q{enum t = "string";});
    static assert(mixin(expand!q{enum t = "${ExpandTest!(10)}";}) == q{enum t = "ExpandTest!(10)";});   // template name
}
// sample unittest
unittest
{
    enum int a = 10;
    enum string op = "+";
    static assert(mixin(expand!q{ ${a*2} $op 2 }) == q{ 20 + 2 });

    assert(text(mixin(expandSplit!"I call you $a times.")) == "I call you 10 times.");
}

version(RunTest) void main(){}
