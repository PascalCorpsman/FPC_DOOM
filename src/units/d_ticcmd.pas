Unit d_ticcmd;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  doomtype;

Type

  // The data sampled per tick (single player)
  // and transmitted to other peers (multiplayer).
  // Mainly movements/button commands per game tick,
  // plus a checksum for internal state consistency.
  ticcmd_t = Record
    forwardmove: signed_char; // *2048 for move
    sidemove: signed_char; // *2048 for move
    angleturn: short; // <<16 for angle delta
    chatchar: byte;
    buttons: byte;
    // villsa [STRIFE] according to the asm,
    // consistancy is a short, not a byte
    consistancy: byte; // checks for net game

    // villsa - Strife specific:

    buttons2: byte;
    inventory: int;

    // Heretic/Hexen specific:

    lookfly: byte; // look/fly up/down/centering
    arti: byte; // artitype_t to use

    lookdir: int;
  End;

Implementation

End.

