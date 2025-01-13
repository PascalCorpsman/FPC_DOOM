Unit m_menu;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_event
  ;

//
// MENUS
//
// Called by main loop,
// saves config file and calls I_Quit when user exits.
// Even when the menu is not displayed,
// this can resize the view and change game parameters.
// Does all the real work of the menu interaction.
Function M_Responder(Const ev: Pevent_t): Boolean;

// Called by main loop,
// only used for menu (skull cursor) animation.
Procedure M_Ticker();

// Called by main loop,
// draws the menus directly into the screen buffer.
Procedure M_Drawer();

// Called by D_DoomMain,
// loads the config file.
Procedure M_Init();

// Called by intro code to force menu up upon a keypress,
// does nothing if menu is already up.
Procedure M_StartControlPanel();

//// [crispy] Propagate default difficulty setting change
//void M_SetDefaultDifficulty (void);
//
//extern int detailLevel;
//extern int screenblocks;
//
//extern boolean inhelpscreens;
//extern int showMessages;
//
//// [crispy] Numeric entry
//extern boolean numeric_enter;
//extern int numeric_entry;

Var
  menuactive: Boolean;
  inhelpscreens: boolean;

Implementation

Uses
  doomkey, dstrings, doomstat,
  math,
  sounds,
  d_mode, d_loop, d_englsh,
  g_game,
  hu_stuff,
  i_timer, i_system,
  m_controls,
  s_sound,
  v_video, v_trans,
  w_wad,
  z_zone
  ;

Const
  LINEHEIGHT = 16;
  SKULLXOFF = -32;
  skullName: Array Of String = ('M_SKULL1', 'M_SKULL2');

  e_killthings = 0;
  e_toorough = 1;
  e_hurtme = 2;
  e_violence = 3;
  e_nightmare = 4;

Type

  TIntRoutine = Procedure(choice: int);
  TRoutine = Procedure();

  menuitem_t = Record
    // 0 = no cursor here, 1 = ok, 2 = arrows ok
    // [crispy] 3 = arrows ok, no mouse x
    // [crispy] 4 = arrows ok, enter for numeric entry, no mouse x
    status: short;

    Name: String;

    // choice = menu item #.
    // if status = 2 or 3,
    //   choice=0:leftarrow,1:rightarrow
    // [crispy] if status = 4,
    //   choice=0:leftarrow,1:rightarrow,2:enter
    Routine: TIntRoutine;

    // hotkey in menu
    alphaKey: char;
    //    alttext: String; // [crispy] alternative text for menu items
  End;

  menuitems_t = Array Of menuitem_t;

  Pmenu_t = ^menu_t;

  menu_t = Record
    numitems: short; // # of menu items
    prevMenu: Pmenu_t; // previous menu
    menuitems: menuitems_t; // menu items
    routine: TRoutine; // draw routine
    x: short;
    y: short; // x,y of menu
    lastOn: short; // last item user was on in menu
    // lumps_missing: short; // [crispy] indicate missing menu graphics lumps
  End;

Var
  itemOn: short; // menu item skull is on
  skullAnimCounter: short; // skull animation counter
  whichSkull: short; // which skull to draw

  currentMenu: Pmenu_t;

  endstring: String;

  // 1 = message to be printed
  messageToPrint: int;
  // ...and here is the message string!
  messageString: String;
  messageLastMenuActive: Boolean;
  messageRoutine: TIntRoutine;
  // timed message = no input from user
  messageNeedsInput: Boolean;

  numeric_entry_str: String;
  numeric_entry_index: integer; // Braucht man Wahrscheinlich gar nicht, da FPC ja saubere Strings hat ;)

  MainDef: menu_t; // Wird im Initialiserungsteil definiert
  NewDef: menu_t; // Wird im Initialiserungsteil definiert
  EpiDef: menu_t; // Wird im Initialiserungsteil definiert

  epi: int = 0;
  //  CrispnessMenus: Array Of menu_t; // Wird im Initialiserungsteil definiert
  //  crispness_cur: int = 0;

Procedure M_SetupNextMenu(menudef: Pmenu_t);
Begin
  currentMenu := menudef;
  itemOn := currentMenu^.lastOn;
End;

//
//      Find string height from hu_font chars
//
//      nutzt \n als LineEnding !

Function M_StringHeight(str: String): int;
Var
  h, height: int;
  i: integer;
Begin
  height := hu_font[0]^.height;
  h := height;
  i := 1;
  While i < length(str) - 1 Do Begin
    If (str[i] = '\') And (str[i + 1] = 'n') Then Begin
      h := h + height;
      inc(i);
    End;
    inc(i);
  End;
  result := h;
End;

//
// Find string width from hu_font chars
//
//      nutzt \n als LineEnding !

Function M_StringWidth(str: String): int;
Var
  c, w: int;
  i: integer;
Begin
  w := 0;
  str := UpperCase(str);
  str := StringReplace(str, '\n', '', [rfReplaceAll]);
  i := 1;
  While i <= length(Str) Do Begin
    // [crispy] correctly center colorized strings
    If (str[i] = cr_esc) And (i + 1 <= length(str)) Then Begin
      //	    if (string[i+1] >= '0' && string[i+1] <= '0' + CRMAX - 1)
      If ord(str[i + 1]) In [ord('0')..ord('0') + CRMAX - 1] Then Begin
        inc(i, 2);
        continue;
      End;
    End;
    c := ord(str[i]) - ord(HU_FONTSTART);
    If (c < 0) Or (c >= HU_FONTSIZE) Then Begin
      w := w + 4; // WTF: warum ist das kein Define ?
    End
    Else Begin
      w := w + hu_font[c]^.width;
    End;
    inc(i);
  End;
  result := w;
End;

//
//      Write a string using the hu_font
//
//      nutzt \n als LineEnding !

Procedure M_WriteText(x, y: int; str: String);
Var
  w, cx, cy: int;
  i: integer;
  c: int;
Begin
  cx := x;
  cy := y;
  i := 1;
  While i <= length(str) Do Begin
    If (str[i] = '\') And (i + 1 <= length(str)) And (str[i + 1] = 'n') Then Begin
      cx := x;
      cy := cy + 12; // WTF: eigentlich sollte das doch hu_font[0]^.height sein ??
      inc(i, 2);
      continue;
    End;
    // [crispy] support multi-colored text
    If (str[i] = cr_esc) And (i < length(str)) Then Begin
      If (ord(str[i + 1]) In [ord('0')..ord('0') + CRMAX - 1]) Then Begin
        dp_translation := cr[ord(str[i + 1]) - ord('0')];
        inc(i, 2);
        continue;
      End;
    End;
    c := ord(uppercase(str[i])[1]) - ord(HU_FONTSTART);
    If (c < 0) Or (c >= HU_FONTSIZE) Then Begin
      cx := cx + 4; // WTF: warum ist das kein Define ?
      inc(i);
      continue;
    End;
    w := hu_font[c]^.width;
    If (cx + w > ORIGWIDTH) Then exit; // Wir würden über den Rechten Rand heraus malen
    V_DrawPatchDirect(cx, cy, hu_font[c]);
    cx := cx + w;
    inc(i);
  End;
End;

Procedure M_StartMessage(msg: String; routine: TIntRoutine; input: boolean);
Begin
  messageLastMenuActive := menuactive;
  messageToPrint := 1;
  messageString := msg;
  messageRoutine := routine;
  messageNeedsInput := input;
  menuactive := true;
  // [crispy] entering menus while recording demos pauses the game
  If (demorecording) And (Not paused) Then Begin
    sendpause := true;
  End;
End;

Function M_SelectEndMessage(): String;
Begin
  If (logical_gamemission = doom) Then Begin
    // Doom 1
    result := doom1_endmsg[gametic Mod NUM_QUITMESSAGES];
  End
  Else Begin
    // Doom 2
    result := doom2_endmsg[gametic Mod NUM_QUITMESSAGES];
  End;
End;

Procedure M_DrawEpisode();
Begin
  // [crispy] force status bar refresh
  inhelpscreens := true;

  If (W_CheckNumForName('M_EPISOD') <> -1) Then Begin
    V_DrawPatchDirect(54, 38, W_CacheLumpName('M_EPISOD', PU_CACHE));
  End
  Else Begin
    M_WriteText(54, 38, 'Which Episode?');
    // EpiDef.lumps_missing := 1;
  End;
End;

Procedure M_DrawNewGame();
Begin
  // [crispy] force status bar refresh
  //  inhelpscreens := true;
  V_DrawPatchDirect(96, 14, W_CacheLumpName('M_NEWG', PU_CACHE));
  V_DrawPatchDirect(54, 38, W_CacheLumpName('M_SKILL', PU_CACHE));
End;

Procedure M_DrawMainMenu();
Begin
  // [crispy] force status bar refresh
  //    inhelpscreens = true;
  V_DrawPatchDirect(94, 2, W_CacheLumpName('M_DOOM', PU_CACHE));
End;

Procedure M_NewGame(choice: int);
Begin
  // [crispy] forbid New Game while recording a demo
  If (demorecording) Then Begin
    exit;
  End;

  If (netgame) And (Not demoplayback) Then Begin
    M_StartMessage(NEWGAME, Nil, false);
    exit;
  End;

  // Chex Quest disabled the episode select screen, as did Doom II.

  If (gamemode = commercial) And (true {!crispy->havenerve && !crispy->havemaster}) Or (gameversion = exe_chex) Then Begin // [crispy] NRFTL / The Master Levels
    M_SetupNextMenu(@NewDef);
  End
  Else Begin
    M_SetupNextMenu(@EpiDef);
  End;
End;

Procedure M_QuitResponse(key: int);
Begin
  //    extern int show_endoom;
  // [crispy] allow to confirm by pressing Enter key
  If (key <> key_menu_confirm) And (key <> key_menu_forward) Then exit;
  // [crispy] play quit sound only if the ENDOOM screen is also shown
  //    if (!netgame && show_endoom)
  //    {
  //	if (gamemode == commercial)
  //	    S_StartSound(NULL,quitsounds2[(gametic>>2)&7]);
  //	else
  //	    S_StartSound(NULL,quitsounds[(gametic>>2)&7]);
  //	I_WaitVBL(105);
  //    }
  I_Quit();
End;

Procedure M_Options(choice: int);
Begin
  //  M_SetupNextMenu(&OptionsDef);
End;

//
// Selected from DOOM menu
//

Procedure M_LoadGame(choice: int);
Begin
  // [crispy] allow loading game while multiplayer demo playback
//    if (netgame && !demoplayback)
//    {
//	M_StartMessage(DEH_String(LOADNET),NULL,false);
//	return;
//    }
//
//    M_SetupNextMenu(&LoadDef);
//    M_ReadSaveStrings();
End;

//
// Selected from DOOM menu
//

Procedure M_SaveGame(choice: int);
Begin
  //    if (!usergame)
  //    {
  //	M_StartMessage(DEH_String(SAVEDEAD),NULL,false);
  //	return;
  //    }
  //
  //    if (gamestate != GS_LEVEL)
  //	return;
  //
  //    M_SetupNextMenu(&SaveDef);
  //    M_ReadSaveStrings();
End;

//
// M_ReadThis
//

Procedure M_ReadThis(choice: int);
Begin
  choice := 0;
  //    M_SetupNextMenu(&ReadDef1);
End;

Procedure M_QuitDOOM(choice: int);
Begin
  // [crispy] fast exit if "run" key is held down
  If (speedkeydown()) Then I_Quit();

  endstring := M_SelectEndMessage() + '\n\n' + dosy;

  M_StartMessage(endstring, @M_QuitResponse, true);
End;

Function intToSkill(value: int): skill_t;
Begin
  Case value Of
    e_killthings: result := sk_baby;
    e_toorough: result := sk_easy;
    e_hurtme: result := sk_medium;
    e_violence: result := sk_hard;
    e_nightmare: result := sk_nightmare;
  End;
End;

//
// M_ClearMenus
//

Procedure M_ClearMenus();
Begin
  menuactive := false;

  // [crispy] entering menus while recording demos pauses the game
  If (demorecording) And (paused) Then sendpause := true;

  If (Not netgame) And (usergame) And (paused) Then sendpause := true;
End;

Procedure M_VerifyNightmare(key: int);
Begin
  // [crispy] allow to confirm by pressing Enter key
  If (key <> key_menu_confirm) And (key <> key_menu_forward) Then Begin
    exit;
  End;

  G_DeferedInitNew(intToSkill(e_nightmare), epi + 1, 1);
  M_ClearMenus();
End;

Procedure M_ChooseSkill(choice: int);
Begin
  If (choice = e_nightmare) Then Begin
    M_StartMessage(NIGHTMARE, @M_VerifyNightmare, true);
    exit;
  End;

  G_DeferedInitNew(intToSkill(choice), epi + 1, 1);
  M_ClearMenus();
End;

Procedure M_Episode(choice: int);
Begin
  If (gamemode = shareware) And (choice <> 0) Then Begin
    M_StartMessage(SWSTRING, Nil, false);
    //	M_SetupNextMenu(&ReadDef1);
    exit;
  End;
  epi := choice;
  // [crispy] have Sigil II loaded but not Sigil
  If (epi = 4) And (false { crispy-> haved1e6 && !crispy-> haved1e5}) Then
    epi := 5;
  M_SetupNextMenu(@NewDef);
End;

// These keys evaluate to a "null" key in Vanilla Doom that allows weird
// jumping in the menus. Preserve this behavior for accuracy.

Function IsNullKey(key: int): Boolean;
Begin
  result := (key = KEY_PAUSE) Or (key = KEY_CAPSLOCK)
    Or (key = KEY_SCRLCK) Or (key = KEY_NUMLOCK);
End;

//
// M_Responder
//

Function M_Responder(Const ev: Pevent_t): Boolean;
Const
  mousewait: int = 0;
  //    static  int     mousey = 0;
  //    static  int     lasty = 0;
  //    static  int     mousex = 0;
  //    static  int     lastx = 0;

Var
  ch: char;
  key: int;
  i: int;
  //    boolean mousextobutton = false;
  //    int dir;
Begin
  result := false;
  //    // In testcontrols mode, none of the function keys should do anything
  //    // - the only key is escape to quit.
  //
  //    if (testcontrols)
  //    {
  //        if (ev->type == ev_quit
  //         || (ev->type == ev_keydown
  //          && (ev->data1 == key_menu_activate || ev->data1 == key_menu_quit)))
  //        {
  //            I_Quit();
  //            return true;
  //        }
  //
  //        return false;
  //    }

      // "close" button pressed on window?
  If (ev^._type = ev_quit) Then Begin
    // First click on close button = bring up quit confirm message.
    // Second click on close button = confirm quit

    If (menuactive) And (messageToPrint <> 0) And (messageRoutine = @M_QuitResponse) Then Begin
      M_QuitResponse(key_menu_confirm);
    End
    Else Begin
      S_StartSoundOptional(Nil, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
      M_QuitDOOM(0);
    End;

    result := true;
    exit;
  End;

  // key is the key pressed, ch is the actual character typed

  ch := #0;
  key := -1;

  If (ev^._type = ev_joystick) Then Begin
    // Simulate key presses from joystick events to interact with the menu.

//        if (menuactive)
//        {
//            if (JOY_GET_DPAD(ev->data6) != JOY_DIR_NONE)
//            {
//                dir = JOY_GET_DPAD(ev->data6);
//            }
//            else if (JOY_GET_LSTICK(ev->data6) != JOY_DIR_NONE)
//            {
//                dir = JOY_GET_LSTICK(ev->data6);
//            }
//            else
//            {
//                dir = JOY_GET_RSTICK(ev->data6);
//            }
//
//            if (dir & JOY_DIR_UP)
//            {
//                key = key_menu_up;
//                joywait = I_GetTime() + 5;
//            }
//            else if (dir & JOY_DIR_DOWN)
//            {
//                key = key_menu_down;
//                joywait = I_GetTime() + 5;
//            }
//            if (dir & JOY_DIR_LEFT)
//            {
//                key = key_menu_left;
//                joywait = I_GetTime() + 5;
//            }
//            else if (dir & JOY_DIR_RIGHT)
//            {
//                key = key_menu_right;
//                joywait = I_GetTime() + 5;
//            }
//
//#define JOY_BUTTON_MAPPED(x) ((x) >= 0)
//#define JOY_BUTTON_PRESSED(x) (JOY_BUTTON_MAPPED(x) && (ev->data1 & (1 << (x))) != 0)
//
//            if (JOY_BUTTON_PRESSED(joybfire))
//            {
//                // Simulate a 'Y' keypress when Doom show a Y/N dialog with Fire button.
//                if (messageToPrint && messageNeedsInput)
//                {
//                    key = key_menu_confirm;
//                }
//                // Simulate pressing "Enter" when we are supplying a save slot name
//                else if (saveStringEnter)
//                {
//                    key = KEY_ENTER;
//                }
//                else
//                {
//                    // if selecting a save slot via joypad, set a flag
//                    if (currentMenu == &SaveDef)
//                    {
//                        joypadSave = true;
//                    }
//                    key = key_menu_forward;
//                }
//                joywait = I_GetTime() + 5;
//            }
//            if (JOY_BUTTON_PRESSED(joybuse))
//            {
//                // Simulate a 'N' keypress when Doom show a Y/N dialog with Use button.
//                if (messageToPrint && messageNeedsInput)
//                {
//                    key = key_menu_abort;
//                }
//                // If user was entering a save name, back out
//                else if (saveStringEnter)
//                {
//                    key = KEY_ESCAPE;
//                }
//                else
//                {
//                    key = key_menu_back;
//                }
//                joywait = I_GetTime() + 5;
//            }
//        }
//        if (JOY_BUTTON_PRESSED(joybmenu))
//        {
//            key = key_menu_activate;
//            joywait = I_GetTime() + 5;
//        }
  End
  Else Begin
    If (ev^._type = ev_mouse) And (mousewait < I_GetTime()) And (menuactive) Then Begin
      //	    // [crispy] novert disables controlling the menus with the mouse
      //	    if (!novert)
      //	    {
      //	    mousey += ev->data3;
      //	    }
      //	    if (mousey < lasty-30)
      //	    {
      //		key = key_menu_down;
      //		mousewait = I_GetTime() + 5;
      //		mousey = lasty -= 30;
      //	    }
      //	    else if (mousey > lasty+30)
      //	    {
      //		key = key_menu_up;
      //		mousewait = I_GetTime() + 5;
      //		mousey = lasty += 30;
      //	    }
      //
      //	    mousex += ev->data2;
      //	    if (mousex < lastx-30)
      //	    {
      //		key = key_menu_left;
      //		mousewait = I_GetTime() + 5;
      //		mousex = lastx -= 30;
      //		mousextobutton = true;
      //	    }
      //	    else if (mousex > lastx+30)
      //	    {
      //		key = key_menu_right;
      //		mousewait = I_GetTime() + 5;
      //		mousex = lastx += 30;
      //		mousextobutton = true;
      //	    }
      //
      //	    if (ev->data1&1)
      //	    {
      //		key = key_menu_forward;
      //		mousewait = I_GetTime() + 5;
      //	    }
      //
      //	    if (ev->data1&2)
      //	    {
      //		key = key_menu_back;
      //		mousewait = I_GetTime() + 5;
      //	    }
      //
      //	    // [crispy] scroll menus with mouse wheel
      //	    if (mousebprevweapon >= 0 && ev->data1 & (1 << mousebprevweapon))
      //	    {
      //		key = key_menu_down;
      //		mousewait = I_GetTime() + 1;
      //	    }
      //	    else
      //	    if (mousebnextweapon >= 0 && ev->data1 & (1 << mousebnextweapon))
      //	    {
      //		key = key_menu_up;
      //		mousewait = I_GetTime() + 1;
      //	    }
    End
    Else Begin
      If (ev^._type = ev_keydown) Then Begin
        key := ev^.data1;
        ch := chr(ev^.data2);
        ch := LowerCase(ch);
      End;
    End;
  End;

  If (key = -1) Then Begin
    exit;
  End;
  // Save Game string input
//    if (saveStringEnter)
//    {
//	switch(key)
//	{
//	  case KEY_BACKSPACE:
//	    if (saveCharIndex > 0)
//	    {
//		saveCharIndex--;
//		savegamestrings[saveSlot][saveCharIndex] = 0;
//	    }
//	    break;
//
//          case KEY_ESCAPE:
//            saveStringEnter = 0;
//            I_StopTextInput();
//            M_StringCopy(savegamestrings[saveSlot], saveOldString,
//                         SAVESTRINGSIZE);
//            break;
//
//	  case KEY_ENTER:
//	    saveStringEnter = 0;
//            I_StopTextInput();
//	    if (savegamestrings[saveSlot][0])
//		M_DoSave(saveSlot);
//	    break;
//
//	  default:
//            // Savegame name entry. This is complicated.
//            // Vanilla has a bug where the shift key is ignored when entering
//            // a savegame name. If vanilla_keyboard_mapping is on, we want
//            // to emulate this bug by using ev->data1. But if it's turned off,
//            // it implies the user doesn't care about Vanilla emulation:
//            // instead, use ev->data3 which gives the fully-translated and
//            // modified key input.
//
//            if (ev->type != ev_keydown)
//            {
//                break;
//            }
//            if (vanilla_keyboard_mapping)
//            {
//                ch = ev->data1;
//            }
//            else
//            {
//                ch = ev->data3;
//            }
//
//            ch = toupper(ch);
//
//            if (ch != ' '
//             && (ch - HU_FONTSTART < 0 || ch - HU_FONTSTART >= HU_FONTSIZE))
//            {
//                break;
//            }
//
//	    if (ch >= 32 && ch <= 127 &&
//		saveCharIndex < SAVESTRINGSIZE-1 &&
//		M_StringWidth(savegamestrings[saveSlot]) <
//		(SAVESTRINGSIZE-2)*8)
//	    {
//		savegamestrings[saveSlot][saveCharIndex++] = ch;
//		savegamestrings[saveSlot][saveCharIndex] = 0;
//	    }
//	    break;
//	}
//	return true;
//    }

//    // [crispy] Enter numeric value
//    if (numeric_enter)
//    {
//        switch(key)
//        {
//            case KEY_BACKSPACE:
//                if (numeric_entry_index > 0)
//                {
//                    numeric_entry_index--;
//                    numeric_entry_str[numeric_entry_index] = '\0';
//                }
//                break;
//            case KEY_ESCAPE:
//                numeric_enter = false;
//                I_StopTextInput();
//                break;
//            case KEY_ENTER:
//                if (numeric_entry_str[0] != '\0')
//                {
//                    numeric_entry = atoi(numeric_entry_str);
//                    currentMenu->menuitems[itemOn].routine(2);
//                }
//                else
//                {
//                    numeric_enter = false;
//                    I_StopTextInput();
//                }
//                break;
//            default:
//                if (ev->type != ev_keydown)
//                {
//                    break;
//                }
//
//                if (vanilla_keyboard_mapping)
//                {
//                    ch = ev->data1;
//                }
//                else
//                {
//                    ch = ev->data3;
//                }
//
//                if (ch >= '0' && ch <= '9' &&
//                        numeric_entry_index < NUMERIC_ENTRY_NUMDIGITS)
//                {
//                    numeric_entry_str[numeric_entry_index++] = ch;
//                    numeric_entry_str[numeric_entry_index] = '\0';
//                }
//                else
//                {
//                    break;
//                }
//        }
//        return true;
//    }

  // Take care of any messages that need input
  If (messageToPrint <> 0) Then Begin
    If (messageNeedsInput) Then Begin
      If (key <> ord(' ')) And (key <> KEY_ESCAPE)
        And (key <> key_menu_confirm) And (key <> key_menu_abort)
        // [crispy] allow to confirm nightmare, end game and quit by pressing Enter key
      And (key <> key_menu_forward)
        Then Begin
        exit;
      End;
    End;

    menuactive := messageLastMenuActive;
    If assigned(messageRoutine) Then
      messageRoutine(key);

    // [crispy] stay in menu
    If (messageToPrint < 2) Then Begin
      menuactive := false;
    End;
    messageToPrint := 0; // [crispy] moved here
    S_StartSoundOptional(Nil, sfx_mnucls, sfx_swtchx); // [NS] Optional menu sounds.
    result := true;
    exit;
  End;

  //    // [crispy] take screen shot without weapons and HUD
  //    if (key != 0 && key == key_menu_cleanscreenshot)
  //    {
  //	crispy->cleanscreenshot = (screenblocks > 10) ? 2 : 1;
  //    }

  //    if ((devparm && key == key_menu_help) ||
  //        (key != 0 && (key == key_menu_screenshot || key == key_menu_cleanscreenshot)))
  //    {
  //	G_ScreenShot ();
  //	return true;
  //    }

  //    // F-Keys
  //    if (!menuactive)
  //    {
  //	if (key == key_menu_decscreen)      // Screen size down
  //        {
  //	    if (automapactive || chat_on)
  //		return false;
  //	    M_SizeDisplay(0);
  //	    S_StartSoundOptional(NULL, sfx_mnusli, sfx_stnmov); // [NS] Optional menu sounds.
  //	    return true;
  //	}
  //        else if (key == key_menu_incscreen) // Screen size up
  //        {
  //	    if (automapactive || chat_on)
  //		return false;
  //	    M_SizeDisplay(1);
  //	    S_StartSoundOptional(NULL, sfx_mnusli, sfx_stnmov); // [NS] Optional menu sounds.
  //	    return true;
  //	}
  //        else if (key == key_menu_help)     // Help key
  //        {
  //	    M_StartControlPanel ();
  //
  //	    if (gameversion >= exe_ultimate)
  //	      currentMenu = &ReadDef2;
  //	    else
  //	      currentMenu = &ReadDef1;
  //
  //	    itemOn = 0;
  //	    S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    return true;
  //	}
  //        else if (key == key_menu_save)     // Save
  //        {
  //	    M_StartControlPanel();
  //	    S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    M_SaveGame(0);
  //	    return true;
  //        }
  //        else if (key == key_menu_load)     // Load
  //        {
  //	    M_StartControlPanel();
  //	    S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    M_LoadGame(0);
  //	    return true;
  //        }
  //        else if (key == key_menu_volume)   // Sound Volume
  //        {
  //	    M_StartControlPanel ();
  //	    currentMenu = &SoundDef;
  //	    itemOn = currentMenu->lastOn; // [crispy] remember cursor position
  //	    S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    return true;
  //	}
  //        else if (key == key_menu_detail)   // Detail toggle
  //        {
  //	    M_ChangeDetail(0);
  //	    S_StartSoundOptional(NULL, sfx_mnusli, sfx_swtchn); // [NS] Optional menu sounds.
  //	    return true;
  //        }
  //        else if (key == key_menu_qsave)    // Quicksave
  //        {
  //	    S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    M_QuickSave();
  //	    return true;
  //        }
  //        else if (key == key_menu_endgame)  // End game
  //        {
  //	    S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    M_EndGame(0);
  //	    return true;
  //        }
  //        else if (key == key_menu_messages) // Toggle messages
  //        {
  //	    M_ChangeMessages(0);
  //	    S_StartSoundOptional(NULL, sfx_mnusli, sfx_swtchn); // [NS] Optional menu sounds.
  //	    return true;
  //        }
  //        else if (key == key_menu_qload)    // Quickload
  //        {
  //	    S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    M_QuickLoad();
  //	    return true;
  //        }
  //        else if (key == key_menu_quit)     // Quit DOOM
  //        {
  //	    S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    M_QuitDOOM(0);
  //	    return true;
  //        }
  //        else if (key == key_menu_gamma)    // gamma toggle
  //        {
  //	    crispy->gamma++;
  //	    if (crispy->gamma > 4+13) // [crispy] intermediate gamma levels
  //		crispy->gamma = 0;
  //	    players[consoleplayer].message = DEH_String(gammamsg[crispy->gamma]);
  //#ifndef CRISPY_TRUECOLOR
  //            I_SetPalette (W_CacheLumpName (DEH_String("PLAYPAL"),PU_CACHE));
  //#else
  //            {
  //		I_SetPalette (0);
  //		R_InitColormaps();
  //		inhelpscreens = true;
  //		R_FillBackScreen();
  //		viewactive = false;
  //            }
  //#endif
  //	    return true;
  //	}

  //        // [crispy] those two can be considered as shortcuts for the IDCLEV cheat
  //        // and should be treated as such, i.e. add "if (!netgame)"
  //        // hovewer, allow while multiplayer demos
  //        else if ((!netgame || netdemo) && key != 0 && key == key_menu_reloadlevel)
  //        {
  //	    if (demoplayback)
  //	    {
  //		if (crispy->demowarp)
  //		{
  //		// [crispy] enable screen render back before replaying
  //		nodrawers = false;
  //		singletics = false;
  //		}
  //		// [crispy] replay demo lump or file
  //		G_DoPlayDemo();
  //		return true;
  //	    }
  //	    else
  //	    if (G_ReloadLevel())
  //		return true;
  //        }
  //        else if ((!netgame || netdemo) && key != 0 && key == key_menu_nextlevel)
  //        {
  //	    if (demoplayback)
  //	    {
  //		// [crispy] go to next level
  //		demo_gotonextlvl = true;
  //		G_DemoGotoNextLevel(true);
  //		return true;
  //	    }
  //	    else
  //	    if (G_GotoNextLevel())
  //		return true;
  //        }
  //
  //    }

  // Pop-up menu?
  If (Not menuactive) Then Begin
    If (key = key_menu_activate) Then Begin
      M_StartControlPanel();
      S_StartSoundOptional(Nil, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
      result := true;
      exit;
    End;
    exit;
  End;

  // Keys usable within menu

  If (key = key_menu_down) Then Begin
    // Move down to next item
    Repeat
      If (itemOn + 1 > currentMenu^.numitems - 1) Then
        itemOn := 0
      Else
        itemOn := itemOn + 1;
      // S_StartSoundOptional(NULL, sfx_mnumov, sfx_pstop); // [NS] Optional menu sounds.
    Until (currentMenu^.menuitems[itemOn].status <> -1);
    result := true;
    exit;
  End
  Else If (key = key_menu_up) Then Begin
    // Move back up to previous item
    Repeat
      If (itemOn = 0) Then
        itemOn := currentMenu^.numitems - 1
      Else
        itemOn := itemOn - 1;
      // S_StartSoundOptional(NULL, sfx_mnumov, sfx_pstop); // [NS] Optional menu sounds.
    Until (currentMenu^.menuitems[itemOn].status <> -1);
    result := true;
    exit;
  End
  Else If (key = key_menu_left) Then Begin
    // Slide slider left

//	if (currentMenu->menuitems[itemOn].routine &&
//	    currentMenu->menuitems[itemOn].status)
//	{
//            if (currentMenu->menuitems[itemOn].status == 2)
//            {
//                S_StartSoundOptional(NULL, sfx_mnusli, sfx_stnmov); // [NS] Optional menu sounds.
//                currentMenu->menuitems[itemOn].routine(0);
//            }
//            // [crispy] LR non-slider
//            else if (currentMenu->menuitems[itemOn].status == 3 && !mousextobutton)
//            {
//                S_StartSoundOptional(NULL, sfx_mnuact, sfx_pistol); // [NS] Optional menu sounds.
//                currentMenu->menuitems[itemOn].routine(0);
//            }
//            // [crispy] Numeric entry
//            else if (currentMenu->menuitems[itemOn].status == 4 && !mousextobutton)
//            {
//                S_StartSoundOptional(NULL, sfx_mnusli, sfx_stnmov); // [NS] Optional menu sounds.
//                currentMenu->menuitems[itemOn].routine(0);
//            }
//        }
//	return true;
  End
  Else If (key = key_menu_right) Then Begin
    // Slide slider right

//	if (currentMenu->menuitems[itemOn].routine &&
//	    currentMenu->menuitems[itemOn].status)
//	{
//            if (currentMenu->menuitems[itemOn].status == 2)
//            {
//                S_StartSoundOptional(NULL, sfx_mnusli, sfx_stnmov); // [NS] Optional menu sounds.
//                currentMenu->menuitems[itemOn].routine(1);
//            }
//            // [crispy] LR non-slider
//            else if (currentMenu->menuitems[itemOn].status == 3 && !mousextobutton)
//            {
//                S_StartSoundOptional(NULL, sfx_mnuact, sfx_pistol); // [NS] Optional menu sounds.
//                currentMenu->menuitems[itemOn].routine(1);
//            }
//            // [crispy] Numeric entry
//            else if (currentMenu->menuitems[itemOn].status == 4 && !mousextobutton)
//            {
//                S_StartSoundOptional(NULL, sfx_mnusli, sfx_stnmov); // [NS] Optional menu sounds.
//                currentMenu->menuitems[itemOn].routine(1);
//            }
//        }
//	return true;

  End
  Else If (key = key_menu_forward) Then Begin
    // Activate menu item
    If assigned(currentMenu^.menuitems[itemOn].routine) And
      (currentMenu^.menuitems[itemOn].status <> 0) Then Begin
      currentMenu^.lastOn := itemOn;
      If (currentMenu^.menuitems[itemOn].status = 2) Then Begin
        currentMenu^.menuitems[itemOn].routine(1); // right arrow
        S_StartSoundOptional(Nil, sfx_mnusli, sfx_stnmov); // [NS] Optional menu sounds.
      End
      Else If (currentMenu^.menuitems[itemOn].status = 3) Then Begin
        currentMenu^.menuitems[itemOn].routine(1); // right arrow
        S_StartSoundOptional(Nil, sfx_mnuact, sfx_pistol); // [NS] Optional menu sounds.
      End
      Else If (currentMenu^.menuitems[itemOn].status = 4) Then Begin // [crispy]
        currentMenu^.menuitems[itemOn].routine(2); // enter key
        numeric_entry_index := 0;
        numeric_entry_str := '';
        S_StartSoundOptional(Nil, sfx_mnuact, sfx_pistol);
      End
      Else Begin
        currentMenu^.menuitems[itemOn].routine(itemOn);
        S_StartSoundOptional(Nil, sfx_mnuact, sfx_pistol); // [NS] Optional menu sounds.
      End;
    End;
    result := true;
    exit;
  End
  Else If (key = key_menu_activate) Then Begin
    // Deactivate menu
    currentMenu^.lastOn := itemOn;
    M_ClearMenus();
    S_StartSoundOptional(Nil, sfx_mnucls, sfx_swtchx); // [NS] Optional menu sounds.
    result := true;
    exit;
  End
  Else If (key = key_menu_back) Then Begin
    // Go back to previous menu
    currentMenu^.lastOn := itemOn;
    If assigned(currentMenu^.prevMenu) Then Begin
      currentMenu := currentMenu^.prevMenu;
      itemOn := currentMenu^.lastOn;
      S_StartSoundOptional(Nil, sfx_mnubak, sfx_swtchn); // [NS] Optional menu sounds.
    End;
    result := true;
  End
    // [crispy] delete a savegame
  Else If (key = key_menu_del) Then Begin
    //	if (currentMenu == &LoadDef || currentMenu == &SaveDef)
    //	{
    //	    if (LoadMenu[itemOn].status)
    //	    {
    //		currentMenu->lastOn = itemOn;
    //		M_ConfirmDeleteGame();
    //		return true;
    //	    }
    //	    else
    //	    {
    //		S_StartSoundOptional(NULL, sfx_mnuerr, sfx_oof); // [NS] Optional menu sounds.
    //	    }
    //	}
  End
    // [crispy] next/prev Crispness menu
  Else If (key = KEY_PGUP) Then Begin

    //	currentMenu->lastOn = itemOn;
    //	if (currentMenu == CrispnessMenus[crispness_cur])
    //	{
    //	    M_CrispnessPrev(0);
    //	    S_StartSoundOptional(NULL, sfx_mnuact, sfx_swtchn); // [NS] Optional menu sounds.
    //	    return true;
    //	}
    //	else if (currentMenu == &LoadDef || currentMenu == &SaveDef)
    //	{
    //	    if (savepage > 0)
    //	    {
    //		savepage--;
    //		quickSaveSlot = -1;
    //		M_ReadSaveStrings();
    //		S_StartSoundOptional(NULL, sfx_mnumov, sfx_pstop);
    //	    }
    //	    return true;
    //	}
  End
  Else If (key = KEY_PGDN) Then Begin

    //	currentMenu->lastOn = itemOn;
    //	if (currentMenu == CrispnessMenus[crispness_cur])
    //	{
    //	    M_CrispnessNext(0);
    //	    S_StartSoundOptional(NULL, sfx_mnuact, sfx_swtchn); // [NS] Optional menu sounds.
    //	    return true;
    //	}
    //	else if (currentMenu == &LoadDef || currentMenu == &SaveDef)
    //	{
    //	    if (savepage < savepage_max)
    //	    {
    //		savepage++;
    //		quickSaveSlot = -1;
    //		M_ReadSaveStrings();
    //		S_StartSoundOptional(NULL, sfx_mnumov, sfx_pstop);
    //	    }
    //	    return true;
    //	}
  End

    // Keyboard shortcut?
    // Vanilla Doom has a weird behavior where it jumps to the scroll bars
    // when the certain keys are pressed, so emulate this.

  Else If ((ch <> #0) Or IsNullKey(key)) Then Begin
    // Sieht komisch aus in 2 Schleifen, macht aber Sinn, wenn man zum nächsten Punkt "hopsen" möchte der mit dem gleichen Buchstaben anfängt (y)
    For i := itemOn + 1 To currentMenu^.numitems - 1 Do Begin
      If (currentMenu^.menuitems[i].alphaKey = ch) Then Begin
        itemOn := i;
        S_StartSoundOptional(Nil, sfx_mnumov, sfx_pstop); // [NS] Optional menu sounds.
        result := true;
        exit;
      End;
    End;

    For i := 0 To itemOn Do Begin
      If (currentMenu^.menuitems[i].alphaKey = ch) Then Begin
        itemOn := i;
        S_StartSoundOptional(Nil, sfx_mnumov, sfx_pstop); // [NS] Optional menu sounds.
        result := true;
        exit;
      End;
    End;
  End;
End;

//
// M_Ticker
//

Procedure M_Ticker;
Begin
  skullAnimCounter := skullAnimCounter - 1;
  If (skullAnimCounter <= 0) Then Begin
    whichSkull := whichSkull Xor 1;
    skullAnimCounter := 8;
  End;
End;

//
// M_Drawer
// Called after the view has been rendered,
// but before it has been blitted.
//

Procedure M_Drawer;
Const
  x: short = 0;
  y: short = 0;
Var
  i: unsigned_int;
  max: unsigned_int;
  str, s, name: String;
  //  start: int;
  nlIndex: integer;
Begin
  //    char		string[80];
  //    const char          *name;
  //    int			;

  inhelpscreens := false;

  //    // Horiz. & Vertically center string and print it.
  If (messageToPrint <> 0) Then Begin

    // [crispy] draw a background for important questions
    If (messageToPrint = 2) Then Begin
      //	    M_DrawCrispnessBackground();
    End;

    y := ORIGHEIGHT Div 2 - M_StringHeight(messageString) Div 2;
    s := messageString;
    While s <> '' Do Begin
      nlIndex := pos('\n', s);
      If nlIndex <> 0 Then Begin
        str := copy(s, 1, nlIndex - 1);
        Delete(s, 1, nlIndex + 1);
      End
      Else Begin
        str := s;
        s := '';
      End;
      x := ORIGWIDTH Div 2 - M_StringWidth(str) Div 2;
      M_WriteText(math.max(0, x), y, str); // [crispy] prevent negative x-coords
      // TODO: hier fehlt ein:
      // dp_translation := nil;
      y := y + hu_font[0]^.height;
    End;

    exit;
  End;

  //  If (opldev) Then Begin
  //    M_DrawOPLDev();
  //  End;

  If (Not menuactive) Then exit;

  If assigned(currentMenu^.routine) Then
    currentMenu^.routine(); // call Draw routine

  // DRAW MENU
  x := currentMenu^.x;
  y := currentMenu^.y;
  max := currentMenu^.numitems;

  //    // [crispy] check current menu for missing menu graphics lumps - only once
  //    if (currentMenu->lumps_missing == 0)
  //    {
  //        for (i = 0; i < max; i++)
  //            if (currentMenu->menuitems[i].name[0])
  //                if (W_CheckNumForName(currentMenu->menuitems[i].name) < 0)
  //                    currentMenu->lumps_missing++;
  //
  //        // [crispy] no lump missing, no need to check again
  //        if (currentMenu->lumps_missing == 0)
  //            currentMenu->lumps_missing = -1;
  //    }

  //    for (i=0;i<max;i++)
  For i := 0 To max - 1 Do Begin
    // TODO: hier ist natürlich gewaltiges Potential drin den Lumindex zu Cachen
    name := currentMenu^.menuitems[i].Name;
    If (name <> '') And (W_CheckNumForName(name) > 0) Then Begin
      V_DrawPatchDirect(x, y, W_CacheLumpName(name, PU_CACHE));
    End;
    y := y + LINEHEIGHT;
  End;

  // DRAW SKULL
//  If (currentMenu = @CrispnessMenus[crispness_cur]) Then Begin
    //	char item[4];
    //	M_snprintf(item, sizeof(item), "%s>", whichSkull ? crstr[CR_NONE] : crstr[CR_DARK]);
    //	M_WriteText(currentMenu->x - 8, currentMenu->y + CRISPY_LINEHEIGHT * itemOn, item);
    //	dp_translation = NULL;
//  End
//  Else Begin
  V_DrawPatchDirect(x + SKULLXOFF, currentMenu^.y - 5 + itemOn * LINEHEIGHT,
    W_CacheLumpName(skullName[whichSkull], PU_CACHE));
  //  End;
End;

Procedure M_Init;
Begin
  currentMenu := @MainDef;

  // TODO: FIX: Default ist hier eigentlich False, aber wenn das Spiel startet ist
  //       es im Main Menu und zeigt dieses auch an -> bliebe das false würde die
  //       Tastatur direkt am Start nicht funktionieren.
  //       Eigentlich sollte da irgendwo ein "M_StartControlPanel" kommen, aber noch konnte
  //       der Entsprechende Aufruf nicht gefunden werden.
  menuactive := false;
  itemOn := currentMenu^.lastOn;
  whichSkull := 0;
  //    skullAnimCounter = 10;
  //    screenSize = screenblocks - 3;
  messageToPrint := 0;
  messageString := '';
  messageLastMenuActive := menuactive;
  messageRoutine := Nil; // Besser ist das!
  //    quickSaveSlot = -1;
  //
  //    M_SetDefaultDifficulty(); // [crispy] pre-select default difficulty
  //
  //    // Here we could catch other version dependencies,
  //    //  like HELP1/2, and four episodes.
  //
  //    // The same hacks were used in the original Doom EXEs.
  //
  //    if (gameversion >= exe_ultimate)
  //    {
  //        MainMenu[readthis].routine = M_ReadThis2;
  //        ReadDef2.prevMenu = NULL;
  //    }
  //
  //    if (gameversion >= exe_final && gameversion <= exe_final2)
  //    {
  //        ReadDef2.routine = M_DrawReadThisCommercial;
  //        // [crispy] rearrange Skull in Final Doom HELP screen
  //        ReadDef2.y -= 10;
  //    }
  //
  //    if (gamemode == commercial)
  //    {
  //        MainMenu[readthis] = MainMenu[quitdoom];
  //        MainDef.numitems--;
  //        MainDef.y += 8;
  //        NewDef.prevMenu = &MainDef;
  //        ReadDef1.routine = M_DrawReadThisCommercial;
  //        ReadDef1.x = 330;
  //        ReadDef1.y = 165;
  //        ReadMenu1[rdthsempty1].routine = M_FinishReadThis;
  //    }
  //
  //    // [crispy] Sigil
  //    if (!crispy->haved1e5 && !crispy->haved1e6)
  //    {
  //        EpiDef.numitems = 4;
  //    }
  //    else if (crispy->haved1e5 != crispy->haved1e6)
  //    {
  //        EpiDef.numitems = 5;
  //        if (crispy->haved1e6)
  //        {
  //            EpiDef.menuitems = EpisodeMenuSII;
  //        }
  //    }
  //
  //    // Versions of doom.exe before the Ultimate Doom release only had
  //    // three episodes; if we're emulating one of those then don't try
  //    // to show episode four. If we are, then do show episode four
  //    // (should crash if missing).
  //    if (gameversion < exe_ultimate)
  //    {
  //        EpiDef.numitems--;
  //    }
  //    // chex.exe shows only one episode.
  //    else if (gameversion == exe_chex)
  //    {
  //        EpiDef.numitems = 1;
  //        // [crispy] never show the Episode menu
  //        NewDef.prevMenu = &MainDef;
  //    }
  //
  //    // [crispy] NRFTL / The Master Levels
  //    if (crispy->havenerve || crispy->havemaster)
  //    {
  //        int i, j;
  //
  //        NewDef.prevMenu = &EpiDef;
  //        EpisodeMenu[0].alphaKey = gamevariant == freedm ||
  //                                  gamevariant == freedoom ?
  //                                 'f' :
  //                                 'h';
  //        EpisodeMenu[0].alttext = gamevariant == freedm ?
  //                                 "FreeDM" :
  //                                 gamevariant == freedoom ?
  //                                 "Freedoom: Phase 2" :
  //                                 "Hell on Earth";
  //        EpiDef.numitems = 1;
  //
  //        if (crispy->havenerve)
  //        {
  //            EpisodeMenu[EpiDef.numitems].alphaKey = 'n';
  //            EpisodeMenu[EpiDef.numitems].alttext = "No Rest for the Living";
  //            EpiDef.numitems++;
  //
  //            i = W_CheckNumForName("M_EPI1");
  //            j = W_CheckNumForName("M_EPI2");
  //
  //            // [crispy] render the episode menu with the HUD font ...
  //            // ... if the graphics are not available
  //            if (i != -1 && j != -1)
  //            {
  //                // ... or if the graphics are both from an IWAD
  //                if (W_IsIWADLump(lumpinfo[i]) && W_IsIWADLump(lumpinfo[j]))
  //                {
  //                    const patch_t *pi, *pj;
  //
  //                    pi = W_CacheLumpNum(i, PU_CACHE);
  //                    pj = W_CacheLumpNum(j, PU_CACHE);
  //
  //                    // ... and if the patch width for "Hell on Earth"
  //                    //     is longer than "No Rest for the Living"
  //                    if (SHORT(pi->width) > SHORT(pj->width))
  //                    {
  //                        EpiDef.lumps_missing = 1;
  //                    }
  //                }
  //            }
  //            else
  //            {
  //                EpiDef.lumps_missing = 1;
  //            }
  //        }
  //
  //        if (crispy->havemaster)
  //        {
  //            EpisodeMenu[EpiDef.numitems].alphaKey = 't';
  //            EpisodeMenu[EpiDef.numitems].alttext = "The Master Levels";
  //            EpiDef.numitems++;
  //
  //            i = W_CheckNumForName(EpiDef.numitems == 3 ? "M_EPI3" : "M_EPI2");
  //
  //            // [crispy] render the episode menu with the HUD font
  //            // if the graphics are not available or not from a PWAD
  //            if (i == -1 || W_IsIWADLump(lumpinfo[i]))
  //            {
  //                EpiDef.lumps_missing = 1;
  //            }
  //        }
  //    }
  //
  //    // [crispy] rearrange Load Game and Save Game menus
  //    {
  //	const patch_t *patchl, *patchs, *patchm;
  //	short captionheight, vstep;
  //
  //	patchl = W_CacheLumpName(DEH_String("M_LOADG"), PU_CACHE);
  //	patchs = W_CacheLumpName(DEH_String("M_SAVEG"), PU_CACHE);
  //	patchm = W_CacheLumpName(DEH_String("M_LSLEFT"), PU_CACHE);
  //
  //	LoadDef_x = (ORIGWIDTH - SHORT(patchl->width)) / 2 + SHORT(patchl->leftoffset);
  //	SaveDef_x = (ORIGWIDTH - SHORT(patchs->width)) / 2 + SHORT(patchs->leftoffset);
  //	LoadDef.x = SaveDef.x = (ORIGWIDTH - 24 * 8) / 2 + SHORT(patchm->leftoffset); // [crispy] see M_DrawSaveLoadBorder()
  //
  //	captionheight = MAX(SHORT(patchl->height), SHORT(patchs->height));
  //
  //	vstep = ORIGHEIGHT - 32; // [crispy] ST_HEIGHT
  //	vstep -= captionheight;
  //	vstep -= (load_end - 1) * LINEHEIGHT + SHORT(patchm->height);
  //	vstep /= 3;
  //
  //	if (vstep > 0)
  //	{
  //		LoadDef_y = vstep + captionheight - SHORT(patchl->height) + SHORT(patchl->topoffset);
  //		SaveDef_y = vstep + captionheight - SHORT(patchs->height) + SHORT(patchs->topoffset);
  //		LoadDef.y = SaveDef.y = vstep + captionheight + vstep + SHORT(patchm->topoffset) - 15; // [crispy] moved up, so savegame date/time may appear above status bar
  //		MouseDef.y = LoadDef.y;
  //	}
  //    }
  //
  //    // [crispy] remove DOS reference from the game quit confirmation dialogs
  //    if (!M_ParmExists("-nodeh"))
  //    {
  //	const char *string;
  //	char *replace;
  //
  //	// [crispy] "i wouldn't leave if i were you.\ndos is much worse."
  //	string = doom1_endmsg[3];
  //	if (!DEH_HasStringReplacement(string))
  //	{
  //		replace = M_StringReplace(string, "dos", crispy->platform);
  //		DEH_AddStringReplacement(string, replace);
  //		free(replace);
  //	}
  //
  //	// [crispy] "you're trying to say you like dos\nbetter than me, right?"
  //	string = doom1_endmsg[4];
  //	if (!DEH_HasStringReplacement(string))
  //	{
  //		replace = M_StringReplace(string, "dos", crispy->platform);
  //		DEH_AddStringReplacement(string, replace);
  //		free(replace);
  //	}
  //
  //	// [crispy] "don't go now, there's a \ndimensional shambler waiting\nat the dos prompt!"
  //	string = doom2_endmsg[2];
  //	if (!DEH_HasStringReplacement(string))
  //	{
  //		replace = M_StringReplace(string, "dos", "command");
  //		DEH_AddStringReplacement(string, replace);
  //		free(replace);
  //	}
  //    }
  //
  //    opldev = M_CheckParm("-opldev") > 0;
End;

//
// M_StartControlPanel
//

Procedure M_StartControlPanel;
Begin
  // intro might call this repeatedly
  If (menuactive) Then exit;


  // [crispy] entering menus while recording demos pauses the game
  If (demorecording) And (Not paused) Then
    sendpause := true;

  menuactive := true;
  currentMenu := @MainDef; // JDC
  itemOn := currentMenu^.lastOn; // JDC
End;

Const
  MainMenu: Array Of menuitem_t =
  (
    (status: 1; Name: 'M_NGAME'; routine: @M_NewGame; alphaKey: 'n'),
    (status: 1; Name: 'M_OPTION'; routine: @M_Options; alphaKey: 'o'),
    (status: 1; Name: 'M_LOADG'; routine: @M_LoadGame; alphaKey: 'l'),
    (status: 1; Name: 'M_SAVEG'; routine: @M_SaveGame; alphaKey: 's'),
    // Another hickup with Special edition.
    (status: 1; Name: 'M_RDTHIS'; routine: @M_ReadThis; alphaKey: 'r'),
    (status: 1; Name: 'M_QUITG'; routine: @M_QuitDOOM; alphaKey: 'q')
    );

  NewGameMenu: Array Of menuitem_t =
  (
    (status: 1; Name: 'M_JKILL'; routine: @M_ChooseSkill; alphaKey: 'i'),
    (status: 1; Name: 'M_ROUGH'; routine: @M_ChooseSkill; alphaKey: 'h'),
    (status: 1; Name: 'M_HURT'; routine: @M_ChooseSkill; alphaKey: 'h'),
    (status: 1; Name: 'M_ULTRA'; routine: @M_ChooseSkill; alphaKey: 'u'),
    (status: 1; Name: 'M_NMARE'; routine: @M_ChooseSkill; alphaKey: 'n')
    );

  EpisodeMenu: Array Of menuitem_t =
  (
    (status: 1; Name: 'M_EPI1'; routine: @M_Episode; alphaKey: 'k'),
    (status: 1; Name: 'M_EPI2'; routine: @M_Episode; alphaKey: 't'),
    (status: 1; Name: 'M_EPI3'; routine: @M_Episode; alphaKey: 'i'),
    (status: 1; Name: 'M_EPI4'; routine: @M_Episode; alphaKey: 't'),
    (status: 1; Name: 'M_EPI5'; routine: @M_Episode; alphaKey: 's'), // [crispy] Sigil
    (status: 1; Name: 'M_EPI6'; routine: @M_Episode; alphaKey: 's') // [crispy] Sigil II
    );

  //  Crispness1Menu: Array Of menuitem_t =
  //  (
  //    (status: - 1; Name: ''; Routine: Nil; alphaKey: #0),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleHires; alphaKey: 'h'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleWidescreen; alphaKey: 'w'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleUncapped; alphaKey: 'u'),
  //    (status: 4; Name: ''; Routine: @M_CrispyToggleFpsLimit; alphaKey: 'f'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleVsync; alphaKey: 'v'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleSmoothScaling; alphaKey: 's'),
  //    (status: - 1; Name: ''; Routine: Nil; alphaKey: #0),
  //    (status: - 1; Name: ''; Routine: Nil; alphaKey: #0),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleColoredhud; alphaKey: 'c'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleTranslucency; alphaKey: 'e'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleSmoothLighting; alphaKey: 's'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleBrightmaps; alphaKey: 'b'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleColoredblood; alphaKey: 'c'),
  //    (status: 3; Name: ''; Routine: @M_CrispyToggleFlipcorpses; alphaKey: 'r'),
  //    (status: - 1; Name: ''; Routine: Nil; alphaKey: #0),
  //    (status: 1; Name: ''; Routine: @M_CrispnessNext; alphaKey: 'n'),
  //    (status: 1; Name: ''; Routine: @M_CrispnessPrev; alphaKey: 'p'),
  //    );

//Var
//  Crispness1Def: menu_t;
//  Crispness2Def: menu_t;
//  Crispness3Def: menu_t;
//  Crispness4Def: menu_t;

Initialization

  With MainDef Do Begin
    numitems := length(MainMenu);
    prevMenu := Nil;
    menuitems := MainMenu;
    routine := @M_DrawMainMenu; // draw routine
    x := 97;
    y := 64; // x,y of menu
    lastOn := 0; // newgame // last item user was on in menu
  End;
  With NewDef Do Begin
    numitems := length(NewGameMenu); // # of menu items
    prevMenu := @MainDef; // Corpsman: FIX, was EpiDef previous menu
    menuitems := NewGameMenu; // menuitem_t ->
    routine := @M_DrawNewGame; // drawing routine ->
    x := 48;
    y := 63; // x,y
    lastOn := e_hurtme; // lastOn
  End;
  With EpiDef Do Begin
    numitems := length(EpisodeMenu); // # of menu items
    prevMenu := @MainDef; // previous menu
    menuitems := EpisodeMenu; // menuitem_t ->
    routine := @M_DrawEpisode; // drawing routine ->
    x := 48;
    y := 63; // x,y
    lastOn := 0; // ep1 // lastOn
  End;

  //  CrispnessMenus := Nil;
  //  setlength(CrispnessMenus, 4);
  //  CrispnessMenus[0] := Crispness1Def;
  //  CrispnessMenus[1] := Crispness2Def;
  //  CrispnessMenus[2] := Crispness3Def;
  //  CrispnessMenus[3] := Crispness4Def;


End.

