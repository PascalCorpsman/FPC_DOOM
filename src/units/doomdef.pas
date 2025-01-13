Unit doomdef;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Const
  // The maximum number of players, multiplayer/networking.
  MAXPLAYERS = 4; // !! ACHTUNG !!  es gibt auch eine Konstante die Heist NET_MAXPLAYERS und die ist 8

  // The current state of the game: whether we are
  // playing, gazing at the intermission screen,
  // the game final animation, or a demo.
Type
  gamestate_t = (
    GS_NEG_1 = -1, // die FPC Variante für -1
    GS_LEVEL = 0,
    GS_INTERMISSION,
    GS_FINALE,
    GS_DEMOSCREEN
    );

  gameaction_t =
    (
    ga_nothing,
    ga_loadlevel,
    ga_newgame,
    ga_loadgame,
    ga_savegame,
    ga_playdemo,
    ga_completed,
    ga_victory,
    ga_worlddone,
    ga_screenshot
    );


Implementation

End.

