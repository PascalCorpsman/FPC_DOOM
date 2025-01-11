Unit doomkey;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, LCLType;

Const

  //
  // DOOM keyboard definition.
  // This is the stuff configured by Setup.Exe.
  // Most key data are simple ascii (uppercased).
  //
//  #define KEY_RIGHTARROW	0xae
//  #define KEY_LEFTARROW	0xac
//  #define KEY_UPARROW	0xad
//  #define KEY_DOWNARROW	0xaf
  KEY_ESCAPE = VK_ESCAPE;
  //  #define KEY_ENTER	13
  //  #define KEY_TAB		9
  //  #define KEY_F1		(0x80+0x3b)
  //  #define KEY_F2		(0x80+0x3c)
  //  #define KEY_F3		(0x80+0x3d)
  //  #define KEY_F4		(0x80+0x3e)
  //  #define KEY_F5		(0x80+0x3f)
  //  #define KEY_F6		(0x80+0x40)
  //  #define KEY_F7		(0x80+0x41)
  //  #define KEY_F8		(0x80+0x42)
  //  #define KEY_F9		(0x80+0x43)
  //  #define KEY_F10		(0x80+0x44)
  //  #define KEY_F11		(0x80+0x57)
  //  #define KEY_F12		(0x80+0x58)
  //
  //  #define KEY_BACKSPACE	0x7f
  KEY_PAUSE = VK_PAUSE;
  //
  //  #define KEY_EQUALS	0x3d
  //  #define KEY_MINUS	0x2d
  //
  //  #define KEY_RSHIFT	(0x80+0x36)
  //  #define KEY_RCTRL	(0x80+0x1d)
  //  #define KEY_RALT	(0x80+0x38)
  //
  //  #define KEY_LALT	KEY_RALT
  //
  //  // new keys:
  //
  KEY_CAPSLOCK = VK_CAPITAL;
  KEY_NUMLOCK = VK_NUMLOCK;
  KEY_SCRLCK = VK_SCROLL; // TODO: Stimmt der ?
  //  #define KEY_PRTSCR      (0x80+0x59)
  //
  //  #define KEY_HOME        (0x80+0x47)
  //  #define KEY_END         (0x80+0x4f)
  KEY_PGUP = VK_PRIOR;
  KEY_PGDN = VK_NEXT;
  //  #define KEY_INS         (0x80+0x52)
  //  #define KEY_DEL         (0x80+0x53)
  //
  //  #define KEYP_0          KEY_INS
  //  #define KEYP_1          KEY_END
  //  #define KEYP_2          KEY_DOWNARROW
  //  #define KEYP_3          KEY_PGDN
  //  #define KEYP_4          KEY_LEFTARROW
  //  #define KEYP_5          (0x80+0x4c)
  //  #define KEYP_6          KEY_RIGHTARROW
  //  #define KEYP_7          KEY_HOME
  //  #define KEYP_8          KEY_UPARROW
  //  #define KEYP_9          KEY_PGUP
  //
  //  #define KEYP_DIVIDE     '/'
  //  #define KEYP_PLUS       '+'
  //  #define KEYP_MINUS      '-'
  //  #define KEYP_MULTIPLY   '*'
  //  #define KEYP_PERIOD     0
  //  #define KEYP_EQUALS     KEY_EQUALS
  //  #define KEYP_ENTER      KEY_ENTER

Implementation

End.

