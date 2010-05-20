import win32.windows;
import std.stdio;

void main()
{
	int ch;
	
	HANDLE hConin = GetStdHandle(STD_INPUT_HANDLE);
	if( hConin == INVALID_HANDLE_VALUE ){
		writefln("Invalid hConIn");
	}
	
	DWORD dwPrevMode;
	if( !GetConsoleMode(hConin, &dwPrevMode) ){
		writefln("Invalid GetConsoleMode");
	}
	
		DWORD dwRead, ks;
		INPUT_RECORD ir;
		int vk;
		BOOL b;
		
		SetConsoleMode(hConin, 0); /* set raw mode */
		for(;;) {
			version(BUILD_FOR_WCHAR){
				b = ReadConsoleInputW(hConin, &ir, 1, &dwRead);
			}else{
				b = ReadConsoleInputA(hConin, &ir, 1, &dwRead);
			}
			if (b && dwRead > 0) {
				if (ir.EventType == KEY_EVENT && ir.KeyEvent.bKeyDown)
				break;
			}
		}
		SetConsoleMode(hConin, dwPrevMode);
		
		
		version(BUILD_FOR_WCHAR){
			ch = ir.KeyEvent.UnicodeChar;
		}else{
			ch = cast(ubyte)(ir.KeyEvent.AsciiChar);
		}
		vk = cast(int)(ir.KeyEvent.wVirtualKeyCode);
		ks = ir.KeyEvent.dwControlKeyState;
		
		writefln("input = ch:%s(%02X), vk:%02X, ks:%02X", cast(char)ch, ch, vk, ks);
		
}
