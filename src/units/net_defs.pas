Unit net_defs;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_mode
  ;

Const
  // The maximum number of players, multiplayer/networking.
  // This is the maximum supported by the networking code; individual games
  // have their own values for MAXPLAYERS that can be smaller.

  NET_MAXPLAYERS = 8;

  // Networking and tick handling related.

  BACKUPTICS = 128;

  // Game settings sent by client to server when initiating game start,
  // and received from the server by clients when the game starts.

Type
  net_gamesettings_t = Record
    ticdup: int;
    extratics: int;
    deathmatch: int;
    episode: int;
    nomonsters: boolean;
    fast_monsters: boolean;
    respawn_monsters: boolean;
    map: int;
    skill: skill_t;
    gameversion: GameVersion_t;
    lowres_turn: boolean;
    new_sync: int;
    timelimit: int;
    loadgame: int;
    random: int; // [Strife only]

    // These fields are only used by the server when sending a game
    // start message:

    num_players: int;
    consoleplayer: int;

    // Hexen player classes:

    player_classes: Array[0..NET_MAXPLAYERS - 1] Of int;
  End;

Implementation

End.

