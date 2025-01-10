Unit m_menu;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

//
// MENUS
//
// Called by main loop,
// saves config file and calls I_Quit when user exits.
// Even when the menu is not displayed,
// this can resize the view and change game parameters.
// Does all the real work of the menu interaction.
//boolean M_Responder (event_t *ev);


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

Implementation

Uses
  z_zone,
  v_video,
  w_wad
  ;

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

  Pmenuitem_t = ^menuitem_t;

  Pmenu_t = ^menu_t;

  menu_t = Record
    numitems: short; // # of menu items
    prevMenu: Pmenu_t; // previous menu
    menuitems: Pmenuitem_t; // menu items
    routine: TRoutine; // draw routine
    x: short;
    y: short; // x,y of menu
    lastOn: short; // last item user was on in menu
    // lumps_missing: short; // [crispy] indicate missing menu graphics lumps
  End;

Var
  itemOn: short; // menu item skull is on
  currentMenu: Pmenu_t;
  menuactive: Boolean;

  // 1 = message to be printed
  messageToPrint: int;
  // ...and here is the message string!
  messageString: String;

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
//    if (demorecording)
//    {
//	return;
//    }
//
//    if (netgame && !demoplayback)
//    {
//	M_StartMessage(DEH_String(NEWGAME),NULL,false);
//	return;
//    }
//
//    // Chex Quest disabled the episode select screen, as did Doom II.
//
//    if ((gamemode == commercial && !crispy->havenerve && !crispy->havemaster) || gameversion == exe_chex) // [crispy] NRFTL / The Master Levels
//	M_SetupNextMenu(&NewDef);
//    else
//	M_SetupNextMenu(&EpiDef);
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
//    if (speedkeydown())
//	I_Quit();
//
//    DEH_snprintf(endstring, sizeof(endstring), "%s\n\n" DOSY,
//                 DEH_String(M_SelectEndMessage()));
//
//    M_StartMessage(endstring,M_QuitResponse,true);
End;
//
// M_Ticker
//

Procedure M_Ticker();
Begin
  //    if (--skullAnimCounter <= 0)
  //    {
  //	whichSkull ^= 1;
  //	skullAnimCounter = 8;
  //    }
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

  MainDef: menu_t =
  (
    numitems: 6; // main_end
    prevMenu: Nil;
    menuitems: @MainMenu;
    routine: @M_DrawMainMenu; // draw routine
    x: 97;
    y: 64; // x,y of menu
    lastOn: 0 // last item user was on in menu
    );

  //
  // M_Drawer
  // Called after the view has been rendered,
  // but before it has been blitted.
  //

Procedure M_Drawer();
Const
  x: short = 0;
  y: short = 0;
Var
  i: unsigned_int;
  max: unsigned_int;
Begin
  //    char		string[80];
  //    const char          *name;
  //    int			start;

  // inhelpscreens := false;

  //    // Horiz. & Vertically center string and print it.
  If (messageToPrint <> 0) Then Begin

    //	// [crispy] draw a background for important questions
    //	if (messageToPrint == 2)
    //	{
    //	    M_DrawCrispnessBackground();
    //	}

    //	start = 0;
    //	y = ORIGHEIGHT/2 - M_StringHeight(messageString) / 2;
    //	while (messageString[start] != '\0')
    //	{
    //	    boolean foundnewline = false;
    //
    //            for (i = 0; messageString[start + i] != '\0'; i++)
    //            {
    //                if (messageString[start + i] == '\n')
    //                {
    //                    M_StringCopy(string, messageString + start,
    //                                 sizeof(string));
    //                    if (i < sizeof(string))
    //                    {
    //                        string[i] = '\0';
    //                    }
    //
    //                    foundnewline = true;
    //                    start += i + 1;
    //                    break;
    //                }
    //            }
    //
    //            if (!foundnewline)
    //            {
    //                M_StringCopy(string, messageString + start, sizeof(string));
    //                start += strlen(string);
    //            }
    //
    //	    x = ORIGWIDTH/2 - M_StringWidth(string) / 2;
    //	    M_WriteText(x > 0 ? x : 0, y, string); // [crispy] prevent negative x-coords
    //	    y += SHORT(hu_font[0]->height);
    //	}

    exit;
  End;

  //    if (opldev)
  //    {
  //        M_DrawOPLDev();
  //    }

//  If (Not menuactive) Then exit;

  If assigned(currentMenu^.routine) Then
    currentMenu^.routine(); // call Draw routine

  //    // DRAW MENU
  //    x = currentMenu->x;
  //    y = currentMenu->y;
  //    max = currentMenu->numitems;
  //
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
  //
  //    for (i=0;i<max;i++)
  //    {
  //        const char *alttext = currentMenu->menuitems[i].alttext;
  //        name = DEH_String(currentMenu->menuitems[i].name);
  //
  //	if (name[0] && (W_CheckNumForName(name) > 0 || alttext))
  //	{
  //	    if (W_CheckNumForName(name) > 0 && currentMenu->lumps_missing == -1)
  //	    V_DrawPatchDirect (x, y, W_CacheLumpName(name, PU_CACHE));
  //	    else if (alttext)
  //		M_WriteText(x, y+8-(M_StringHeight(alttext)/2), alttext);
  //	}
  //	y += LINEHEIGHT;
  //    }
  //
  //
  //    // DRAW SKULL
  //    if (currentMenu == CrispnessMenus[crispness_cur])
  //    {
  //	char item[4];
  //	M_snprintf(item, sizeof(item), "%s>", whichSkull ? crstr[CR_NONE] : crstr[CR_DARK]);
  //	M_WriteText(currentMenu->x - 8, currentMenu->y + CRISPY_LINEHEIGHT * itemOn, item);
  //	dp_translation = NULL;
  //    }
  //    else
  //    V_DrawPatchDirect(x + SKULLXOFF, currentMenu->y - 5 + itemOn*LINEHEIGHT,
  //		      W_CacheLumpName(DEH_String(skullName[whichSkull]),
  //				      PU_CACHE));
End;

Procedure M_Init;
Begin
  currentMenu := @MainDef;
  menuactive := false;
  itemOn := currentMenu^.lastOn;
  //    whichSkull = 0;
  //    skullAnimCounter = 10;
  //    screenSize = screenblocks - 3;
  messageToPrint := 0;
  messageString := '';
  //    messageLastMenuActive = menuactive;
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

Procedure M_StartControlPanel();
Begin
  // intro might call this repeatedly
  If (menuactive) Then exit;


  // [crispy] entering menus while recording demos pauses the game
//    if (demorecording && !paused)
//        sendpause = true;

  menuactive := true;
  currentMenu := @MainDef; // JDC
  itemOn := currentMenu^.lastOn; // JDC
End;



End.

