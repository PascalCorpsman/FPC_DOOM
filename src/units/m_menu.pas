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
//
//
//// Called by main loop,
//// only used for menu (skull cursor) animation.
//void M_Ticker (void);
//
//// Called by main loop,
//// draws the menus directly into the screen buffer.
//void M_Drawer (void);

// Called by D_DoomMain,
// loads the config file.
Procedure M_Init();

//// Called by intro code to force menu up upon a keypress,
//// does nothing if menu is already up.
//void M_StartControlPanel (void);
//
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


Procedure M_DrawNewGame(); // TODO: Debug wieder Raus machen, !!

Implementation

Uses
  z_zone,
  v_video, v_patch,
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
    alttext: String; // [crispy] alternative text for menu items
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
    lumps_missing: short; // [crispy] indicate missing menu graphics lumps
  End;

Var
  // current menudef
  currentMenu: Pmenu_t;

  //
  // M_NewGame
  //

Procedure M_DrawNewGame();
Begin
  // [crispy] force status bar refresh
//  inhelpscreens := true;

  V_DrawPatchDirect(96, 14, W_CacheLumpName('M_NEWG', PU_CACHE));
  V_DrawPatchDirect(54, 38, W_CacheLumpName('M_SKILL', PU_CACHE));
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

Const
  MainMenu: Array Of menuitem_t =
  (
    (status: 1; Name: 'M_NGAME'; routine: @M_NewGame; alphaKey: 'n'; alttext: ''),
    (status: 1; Name: 'M_OPTION'; routine: @M_Options; alphaKey: 'o'; alttext: ''),
    (status: 1; Name: 'M_LOADG'; routine: @M_LoadGame; alphaKey: 'l'; alttext: ''),
    (status: 1; Name: 'M_SAVEG'; routine: @M_SaveGame; alphaKey: 's'; alttext: ''),
    // Another hickup with Special edition.
    (status: 1; Name: 'M_RDTHIS'; routine: @M_ReadThis; alphaKey: 'r'; alttext: ''),
    (status: 1; Name: 'M_QUITG'; routine: @M_QuitDOOM; alphaKey: 'q'; alttext: '')
    );

Procedure M_Init;
Begin
  currentMenu := @MainMenu;
End;

End.

