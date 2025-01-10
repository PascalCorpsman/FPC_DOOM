Unit net_defs;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Const
  // The maximum number of players, multiplayer/networking.
  // This is the maximum supported by the networking code; individual games
  // have their own values for MAXPLAYERS that can be smaller.

  NET_MAXPLAYERS = 8;

Implementation

End.

