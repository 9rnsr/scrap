/*
  getch_msvc.c
  
  getch/getwch replacement for msvc/mingw32
  (to replace enhenced key prefix 0xE0 with 0x00)
  
  Licence: ‚¢‚í‚ä‚é Public Domain ‚Á‚Ä‚±‚Æ‚Å
           (You can use/modify/redistibute it freely BUT NO WARRANTY.)
  
*/

#include "config.h"
#ifdef NYACUS

#include <windows.h>
# ifdef BUILD_FOR_WCHAR
#   include <wchar.h>
# endif
#include <conio.h>
#include <stdio.h>

/* header */
int getch_replacement_for_msvc(void);
int getche_replacement_for_msvc(void);
version(BUILD_FOR_WCHAR){
	int getwch_replacement_for_msvc(void);
	int getwche_replacement_for_msvc(void);
}

enum MY_GETCH_WITH_ECHO          = 1;
enum MY_GETCH_ENAHNCED_PREFIX_E0 = 2;

int getch_replacement_with_flags_for_msvc(int flags);
int getwch_replacement_with_flags_for_msvc(int flags);
/* header end */


//#define ENTER_THREAD_ATOMIC(semaphore)
//#define LEAVE_THREAD_ATOMIC(semaphore)


enum SCAN_ENH        = 0x00010000;
enum SCAN_CODE_MASK  = 0x0000ffff;
enum EXTRA_00        = 0x01000000;
enum EXTRA_E0        = 0x02000000;
enum IN_NUMLOCKED    = 0x04000000;
enum EXTRA_FLAGS_MASK = (EXTRA_00|EXTRA_E0);
enum STRIP_EXTRA_FLAGS = (~(EXTRA_FLAGS_MASK|IN_NUMLOCKED));

struct vkmap {
	int vk;
	int scan;
	int key;
	int key_shift;
	int key_ctrl;
	int key_alt;
	int key_ctrl_alt;
};

private vkmap extra_keymap_msvc[] = {
	/* { vkey, scan, key, key_shift, key_ctrl, key_alt, key_ctrl_alt } */

	/* special case */
	{ VK_BACK, 0x0e, 0x08, 0x08, 0x7f, 0x08, 0x0e|EXTRA_00 }, /* IBM_15 */
	{ VK_TAB, 0x0f, 0x09, 0x09, 0x94|EXTRA_00 , 0x94, 0x0f|EXTRA_00 }, /* IBM_16 */
	{ VK_RETURN, 0x1c, 0x0d, 0x0d, 0x0a, 0x0a, 0x1c|EXTRA_00 }, /* IBM_43 */
	{ VK_RETURN, 0x1c|SCAN_ENH, 0x0d, 0x0d, 0x0a, 0x0a, 0xa6|EXTRA_00 }, /* IBM_108 (numpad) */

	/* enhanced keys */
	{ VK_INSERT, 0x52|SCAN_ENH, 0x52|EXTRA_E0, 0x52|EXTRA_E0, 0x52|EXTRA_E0, 0xa2|EXTRA_00, 0xa2|EXTRA_00 }, /* IBM_75 */
	{ VK_DELETE, 0x53|SCAN_ENH, 0x53|EXTRA_E0, 0x53|EXTRA_E0, 0x93|EXTRA_E0, 0xa3|EXTRA_00, 0xa3|EXTRA_00 }, /* IBM_76 */
	{ VK_LEFT, 0x4b|SCAN_ENH, 0x4b|EXTRA_E0, 0x4b|EXTRA_E0, 0x4b|EXTRA_E0, 0x73|EXTRA_E0, 0x9b|EXTRA_00 }, /* IBM_79 */
	{ VK_HOME, 0x47|SCAN_ENH, 0x47|EXTRA_E0, 0x47|EXTRA_E0, 0x47|EXTRA_E0, 0x77|EXTRA_E0, 0x97|EXTRA_00 }, /* IBM_80 */
	{ VK_END, 0x4f|SCAN_ENH, 0x4f|EXTRA_E0, 0x4f|EXTRA_E0, 0x4f|EXTRA_E0, 0x75|EXTRA_E0, 0x9f|EXTRA_00 }, /* IBM_81 */
	{ VK_UP, 0x48|SCAN_ENH, 0x48|EXTRA_E0, 0x48|EXTRA_E0, 0x48|EXTRA_E0, 0x8d|EXTRA_E0, 0x98|EXTRA_00 }, /* IBM_83 */
	{ VK_DOWN, 0x50|SCAN_ENH, 0x50|EXTRA_E0, 0x50|EXTRA_E0, 0x50|EXTRA_E0, 0x91|EXTRA_E0, 0xa0|EXTRA_00 }, /* IBM_84 */
	{ VK_PRIOR, 0x49|SCAN_ENH, 0x49|EXTRA_E0, 0x49|EXTRA_E0, 0x49|EXTRA_E0, 0x86|EXTRA_E0, 0x99|EXTRA_00 }, /* IBM_85 */
	{ VK_NEXT, 0x51|SCAN_ENH, 0x51|EXTRA_E0, 0x51|EXTRA_E0, 0x51|EXTRA_E0, 0x76|EXTRA_E0, 0xa1|EXTRA_00 }, /* IBM_86 */
	{ VK_RIGHT, 0x4d|SCAN_ENH, 0x4d|EXTRA_E0, 0x4d|EXTRA_E0, 0x4d|EXTRA_E0, 0x74|EXTRA_E0, 0x9d|EXTRA_00 }, /* IBM_89 */

	/* numpad */
	{ VK_HOME, 0x47, 0x47|EXTRA_00, 0x47|EXTRA_00|IN_NUMLOCKED, 0x77|EXTRA_00, 0x00, 0x00 }, /* IBM_91 */
	{ VK_LEFT, 0x4b, 0x4b|EXTRA_00, 0x4b|EXTRA_00|IN_NUMLOCKED, 0x73|EXTRA_00, 0x00, 0x00 }, /* IBM_92 */
	{ VK_END, 0x4f, 0x4f|EXTRA_00, 0x4f|EXTRA_00|IN_NUMLOCKED, 0x75|EXTRA_00, 0x00, 0x00 }, /* IBM_93 */
	{ VK_UP, 0x48, 0x48|EXTRA_00, 0x48|EXTRA_00|IN_NUMLOCKED, 0x8d|EXTRA_00, 0x00, 0x00 }, /* IBM_96 */
	{ VK_CLEAR, 0x4c, 0x00 /* 0x4c|EXTRA_00 */, 0x00 /* 0x4c|EXTRA_00|IN_NUMLOCKED */, 0x00 /* 0x4c|EXTRA_00 */, 0x00, 0x00 }, /* IBM_97 */
	{ VK_DOWN, 0x50, 0x50|EXTRA_00, 0x50|EXTRA_00|IN_NUMLOCKED, 0x91|EXTRA_00, 0x00, 0x00 }, /* IBM_98 */
	{ VK_INSERT, 0x52, 0x52|EXTRA_00, 0x52|EXTRA_00|IN_NUMLOCKED, 0x92|EXTRA_00, 0x00, 0x00 }, /* IBM_99 */
	{ VK_PRIOR, 0x49, 0x49|EXTRA_00, 0x49|EXTRA_00|IN_NUMLOCKED, 0x84|EXTRA_00, 0x00, 0x00 }, /* IBM_101 */
	{ VK_RIGHT, 0x4d, 0x4d|EXTRA_00, 0x4d|EXTRA_00|IN_NUMLOCKED, 0x74|EXTRA_00, 0x00, 0x00 }, /* IBM_102 */
	{ VK_NEXT, 0x51, 0x51|EXTRA_00, 0x51|EXTRA_00|IN_NUMLOCKED, 0x76|EXTRA_00, 0x00, 0x00 }, /* IBM_103 */
	{ VK_DELETE, 0x53, 0x53|EXTRA_00, 0x53|EXTRA_00|IN_NUMLOCKED, 0x93|EXTRA_00, 0x00, 0x00 }, /* IBM_104 */

	/* function keys */
	{ VK_F1, 0x3b, 0x3b|EXTRA_00, 0x54|EXTRA_00, 0x5e|EXTRA_00, 0x68|EXTRA_00, 0x68|EXTRA_00 }, /* IBM_112 */
	{ VK_F2, 0x3c, 0x3c|EXTRA_00, 0x55|EXTRA_00, 0x5f|EXTRA_00, 0x69|EXTRA_00, 0x69|EXTRA_00 }, /* IBM_113 */
	{ VK_F3, 0x3d, 0x3d|EXTRA_00, 0x56|EXTRA_00, 0x60|EXTRA_00, 0x6a|EXTRA_00, 0x6a|EXTRA_00 }, /* IBM_114 */
	{ VK_F4, 0x3e, 0x3e|EXTRA_00, 0x57|EXTRA_00, 0x61|EXTRA_00, 0x6b|EXTRA_00, 0x6b|EXTRA_00 }, /* IBM_115 */
	{ VK_F5, 0x3f, 0x3f|EXTRA_00, 0x58|EXTRA_00, 0x62|EXTRA_00, 0x6c|EXTRA_00, 0x6c|EXTRA_00 }, /* IBM_116 */
	{ VK_F6, 0x40, 0x40|EXTRA_00, 0x59|EXTRA_00, 0x63|EXTRA_00, 0x6d|EXTRA_00, 0x6d|EXTRA_00 }, /* IBM_117 */
	{ VK_F7, 0x41, 0x41|EXTRA_00, 0x5a|EXTRA_00, 0x64|EXTRA_00, 0x6e|EXTRA_00, 0x6e|EXTRA_00 }, /* IBM_118 */
	{ VK_F8, 0x42, 0x42|EXTRA_00, 0x5b|EXTRA_00, 0x65|EXTRA_00, 0x6f|EXTRA_00, 0x6f|EXTRA_00 }, /* IBM_119 */
	{ VK_F9, 0x43, 0x43|EXTRA_00, 0x5c|EXTRA_00, 0x66|EXTRA_00, 0x70|EXTRA_00, 0x70|EXTRA_00 }, /* IBM_120 */
	{ VK_F10, 0x44, 0x44|EXTRA_00, 0x5d|EXTRA_00, 0x67|EXTRA_00, 0x71|EXTRA_00, 0x71|EXTRA_00 }, /* IBM_121 */
	{ VK_F11, 0x57, 0x85|EXTRA_E0, 0x87|EXTRA_E0, 0x89|EXTRA_E0, 0x8b|EXTRA_E0, 0x8b|EXTRA_E0 }, /* IBM_122 */
	{ VK_F12, 0x58, 0x86|EXTRA_E0, 0x88|EXTRA_E0, 0x8a|EXTRA_E0, 0x8c|EXTRA_E0, 0x8c|EXTRA_E0 }, /* IBM_123 */

	/* terminator */
	{ -1 , -1, 0, 0, 0, 0, 0 }
};

private
int lookup_keycode(int vkey, int scan, int shift, int ctrl, int alt, int enhkey)
{
	int ch;
	const(vkmap)* vk;
	
	for(ch=0, vk=&extra_keymap_msvc[0]; vk.vk != -1; ++vk) {
		int match_vkey = vk.vk && vk.vk == vkey;
		int match_scan = vk.scan && vk.scan == (scan & SCAN_CODE_MASK);
		int match_enhstate = (enhkey && (vk.scan & SCAN_ENH)) || !enhkey;
		if ( (match_vkey || match_scan) && match_enhstate) {
			ch = alt ? ctrl ? vk.key_ctrl_alt
			                : vk.key_alt
			         : ctrl ? vk.key_ctrl
			                : shift ? vk.key_shift
			                        : vk.key;
			break;
		}
	}
	return ch;
}


#ifdef BUILD_FOR_WCHAR
	static LONG succ_wkey_value = 0;
	# define succ_key_value  succ_wkey_value
	# define gettch_replacement_with_flags_for_msvc  getwch_replacement_with_flags_for_msvc
#else
	static LONG succ_key_value = 0;
	# define gettch_replacement_with_flags_for_msvc  getch_replacement_with_flags_for_msvc
#endif

int
#ifdef BUILD_FOR_WCHAR
getwch_replacement_with_flags_for_msvc (int flags)
#else
getch_replacement_with_flags_for_msvc (int flags)
#endif
{
	HANDLE hConin;
	DWORD dwPrevMode;
	BOOL bKey;
	int ch;
	
	if (flags & MY_GETCH_WITH_ECHO) {
		ch = gettch_replacement_with_flags_for_msvc(flags & ~MY_GETCH_WITH_ECHO);
		if (ch != -1)
			version(BUILD_FOR_WCHAR)_putwch(ch);
			else					_putch(ch);
		return ch;
	}
	
	ch = InterlockedExchange(&succ_key_value, 0);
	if (ch != 0) return ch;

	//ENTER_THREAD_ATOMIC();
	//scope(exit) LEAVE_THREAD_ATOMIC();

	bKey = FALSE;
	/* check whether stdin is console handle */
	if ((hConin = GetStdHandle(STD_INPUT_HANDLE)) == INVALID_HANDLE_VALUE ||
	  !GetConsoleMode(hConin, &dwPrevMode))
	{
		ch = -1;
		bKey = TRUE;
	}
	
	while(!bKey) {
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
				if (ir.EventType == KEY_EVENT && ir.Event.KeyEvent.bKeyDown)
				break;
			}
		}
		SetConsoleMode(hConin, dwPrevMode);
		if (!b) {
			ch = -1;
			break;
		}
		version(BUILD_FOR_WCHAR){
			ch = ir.Event.KeyEvent.uChar.UnicodeChar;
		}else{
			ch = (unsigned char)(ir.Event.KeyEvent.uChar.AsciiChar);
		}
		vk = (int)(unsigned)(ir.Event.KeyEvent.wVirtualKeyCode);
		ks = ir.Event.KeyEvent.dwControlKeyState;
		if (ch == 0 || vk == VK_RETURN || vk == VK_BACK || vk == VK_TAB) {
			ch = lookup_keycode(vk, 0 /* ir.Event.KeyEvent.wVirtualScanCode */,
									ks & SHIFT_PRESSED,
									ks & (LEFT_CTRL_PRESSED|RIGHT_CTRL_PRESSED),
									ks & (LEFT_ALT_PRESSED|RIGHT_CTRL_PRESSED),
									ks & ENHANCED_KEY);
			if ((ch & IN_NUMLOCKED) && !(ks & NUMLOCK_ON)) {
				ch = 0;
			}
			if (ch & EXTRA_FLAGS_MASK) {
				if ((ch & EXTRA_E0) && (flags & MY_GETCH_ENAHNCED_PREFIX_E0)) {
					succ_key_value = ch & STRIP_EXTRA_FLAGS;
					bKey = TRUE;
					ch = 0xe0;
					break;
				}
				else if ((ch & (EXTRA_E0|EXTRA_00))) {
					succ_key_value = ch & STRIP_EXTRA_FLAGS;
					bKey = TRUE;
					ch = 0x00;
					break;
				}
			}
			ch &= STRIP_EXTRA_FLAGS;
		}
		if (ch != 0) bKey = TRUE;
	}


	return ch;
}


version(BUILD_FOR_WCHAR)
{
	int getwch_replacement_for_msvc(void)
	{
		return getwch_replacement_with_flags_for_msvc(0);
	}
	int getwche_replacement_for_msvc(void)
	{
		return getwch_replacement_with_flags_for_msvc(MY_GETCH_WITH_ECHO);
	}
}
else
{
	int getch_replacement_for_msvc(void)
	{
		return getch_replacement_with_flags_for_msvc(0);
	}
	int getche_replacement_for_msvc(void)
	{
		return getch_replacement_with_flags_for_msvc(MY_GETCH_WITH_ECHO);
	}
}


version(unittest)
{
	void main()
	{
		int k;
		
		for(;;) {
			version(BUILD_FOR_WCHAR)
			{
				k = getwch_replacement_for_msvc();
				printf("0x%x\n", k);
			}
			else
			{
				k = getch_replacement_for_msvc();
				printf("0x%x", k);
				if (k >=20 && k <= 0x7e) printf(" (%c)", k);
				printf("\n");
			}
			if (k == -1 || k == 0x1b) break;
		}
	}
}

#endif /* ifndef OS2EMX */
