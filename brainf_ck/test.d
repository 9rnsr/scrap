import std.stdio;

void main()
{
	Brainf.ck(
		`+++++++++[>++++++++>+++++++++++>+++++<<<-]>.>++.+++++++..+++.>-.`
		`------------.<++++++++.--------.+++.------.--------.>+.`
	);
}


class Brainf
{
static:
	size_t ptr;
	ubyte[100] buf;

	void ck(string code)
	{
		eval(code);
	}
	void eval(string code)
	{
		void error()
		{
			throw new Exception("syntax error");
		}

		size_t pc = 0;
		while (pc < code.length)
		{
			switch (code[pc])
			{
				case '>':
					++ptr;
					break;
				case '<':
					--ptr;
					break;
				case '+':
					++buf[ptr];
					break;
				case '-':
					--buf[ptr];
					break;
				case '.':
					writef("%s", cast(char)buf[ptr]);
					break;
				case ',':
					ubyte n;
					readf("%c", &n);
					buf[ptr] = n;
					break;
				case '[':
					if (buf[ptr] == 0)
					{
						while(code || code[pc] != ']')
							++pc;
						continue;
					}
					break;
				case ']':
					if (buf[ptr] != 0)
					{
						while(pc > 0 && code[--pc] != '['){}
						if (code[pc] != '[') error();
						continue;
					}
					break;
				default:
					error();
			}
			++pc;
		}
	}
}
