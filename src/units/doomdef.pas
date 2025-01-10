Unit doomdef;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

// The current state of the game: whether we are
// playing, gazing at the intermission screen,
// the game final animation, or a demo.
Type
  gamestate_t = (
    GS_LEVEL,
    GS_INTERMISSION,
    GS_FINALE,
    GS_DEMOSCREEN
    );


Implementation

End.

