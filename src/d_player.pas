Unit d_player;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , net_defs
  // The player data structure depends on a number
  // of other structs: items (internal inventory),
  // animation states (closely tied to the sprites
  // used to represent them, unfortunately).
//  #include "d_items.h"

  // Finally, for odd reasons, the player input
  // is buffered within the player data struct,
  // as commands per game tick.
  , d_ticcmd
  //  #include "p_pspr.h"

    // In addition, the player is just a special
    // case of the generic moving object/actor.
  // , p_mobj

  ;

Type
  //
  // Player states.
  //
  playerstate_t = (
    // Playing or camping.
    PST_LIVE,
    // Dead on the ground, view follows killer.
    PST_DEAD,
    // Ready to restart/respawn???
    PST_REBORN
    );

  //
  // Player internal flags, for cheats and debug.
  //
  cheat_t = (
    // No clipping, walk through barriers.
    CF_NOCLIP = 1,
    // No damage, no health loss.
    CF_GODMODE = 2,
    // Not really a cheat, just a debug aid.
    CF_NOMOMENTUM = 4,
    // [crispy] monsters don't target
    CF_NOTARGET = 8
    );

// player_t -> moved p_mobj

  ////
  //// INTERMISSION
  //// Structure passed e.g. to WI_Start(wb)
  ////
  //typedef struct
  //{
  //    boolean	in;	// whether the player is in game
  //
  //    // Player stats, kills, collected items etc.
  //    int		skills;
  //    int		sitems;
  //    int		ssecret;
  //    int		stime;
  //    int		frags[4];
  //    int		score;	// current score on entry, modified on return
  //
  //} wbplayerstruct_t;
  //
  //typedef struct
  //{
  //    int		epsd;	// episode # (0-2)
  //
  //    // if true, splash the secret level
  //    boolean	didsecret;
  //
  //    // previous and next levels, origin 0
  //    int		last;
  //    int		next;
  //
  //    int		maxkills;
  //    int		maxitems;
  //    int		maxsecret;
  //    int		maxfrags;
  //
  //    // the par time
  //    int		partime;
  //
  //    // index of this player in game
  //    int		pnum;
  //
  //    wbplayerstruct_t	plyr[MAXPLAYERS];
  //
  //    // [crispy] CPhipps - total game time for completed levels so far
  //    int		totaltimes;
  //} wbstartstruct_t;


Implementation

End.

