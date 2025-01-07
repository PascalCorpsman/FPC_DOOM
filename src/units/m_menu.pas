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

Implementation

Procedure M_Init();
Begin
     hier weiter
End;

End.

