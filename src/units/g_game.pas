Unit g_game;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef
  ;

Var
  timelimit: int;

  nodrawers: boolean = false; // for comparative timing purposes
  gamestate: gamestate_t;

Implementation

End.

