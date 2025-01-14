Unit p_mobj;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdata, doomdef, tables, info_types
  , d_player //, d_ticcmd
  , m_fixed
  , r_defs
  ;

//
// Misc. mobj flags
//

// mobjflag_t -> Sollte eigentlich ein Enum sein, aber wenn man sich diese Konstanten ansieht ...
Const
  // Call P_SpecialThing when touched.
  MF_SPECIAL = 1;
  // Blocks.
  MF_SOLID = 2;
  // Can be hit.
  MF_SHOOTABLE = 4;
  // Don't use the sector links (invisible but touchable).
  MF_NOSECTOR = 8;
  // Don't use the blocklinks (inert but displayable)
  MF_NOBLOCKMAP = 16;

  // Not to be activated by sound, deaf monster.
  MF_AMBUSH = 32;
  // Will try to attack right back.
  MF_JUSTHIT = 64;
  // Will take at least one step before attacking.
  MF_JUSTATTACKED = 128;
  // On level spawning (initial position),
  //  hang from ceiling instead of stand on floor.
  MF_SPAWNCEILING = 256;
  // Don't apply gravity (every tic),
  //  that is, object will float, keeping current height
  //  or changing it actively.
  MF_NOGRAVITY = 512;

  // Movement flags.
  // This allows jumps from high places.
  MF_DROPOFF = $400;
  // For players, will pick up items.
  MF_PICKUP = $800;
  // Player cheat. ???
  MF_NOCLIP = $1000;
  // Player: keep info about sliding along walls.
  MF_SLIDE = $2000;
  // Allow moves to any height, no gravity.
  // For active floaters, e.g. cacodemons, pain elementals.
  MF_FLOAT = $4000;
  // Don't cross lines
  //   ??? or look at heights on teleport.
  MF_TELEPORT = $8000;
  // Don't hit same species, explode on block.
  // Player missiles as well as fireballs of various kinds.
  MF_MISSILE = $10000;
  // Dropped by a demon, not level spawned.
  // E.g. ammo clips dropped by dying former humans.
  MF_DROPPED = $20000;
  // Use fuzzy draw (shadow demons or spectres),
  //  temporary player invisibility powerup.
  MF_SHADOW = $40000;
  // Flag: don't bleed when shot (use puff),
  //  barrels and shootable furniture shall not bleed.
  MF_NOBLOOD = $80000;
  // Don't stop moving halfway off a step,
  //  that is, have dead bodies slide down all the way.
  MF_CORPSE = $100000;
  // Floating to a height for a move, ???
  //  don't auto float to target's height.
  MF_INFLOAT = $200000;

  // On kill, count this enemy object
  //  towards intermission kill total.
  // Happy gathering.
  MF_COUNTKILL = $400000;

  // On picking up, count this item object
  //  towards intermission item total.
  MF_COUNTITEM = $800000;

  // Special handling: skull in flight.
  // Neither a cacodemon nor a missile.
  MF_SKULLFLY = $1000000;

  // Don't spawn this object
  //  in death match mode (e.g. key cards).
  MF_NOTDMATCH = $2000000;

  // Player sprites in multiplayer modes are modified
  //  using an internal color lookup table for re-indexing.
  // If $4 $8 or $c,
  //  use a translation table for player colormaps
  MF_TRANSLATION = $C000000;
  // Hmm ???.
  // [crispy] Turns MF_TRANSLATION into player index and vice versa
  MF_TRANSSHIFT = 26;

  // [NS] Beta projectile bouncing.
  MF_BOUNCES = $20000000;

  // [crispy] randomly flip corpse, blood and death animation sprites
  MF_FLIPPABLE = $40000000;

  // [crispy] translucent sprite
  MF_TRANSLUCENT = $80000000;


Procedure P_SpawnPlayer(Var mthing: mapthing_t);

Implementation

//
// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.
//

Procedure P_SpawnPlayer(Var mthing: mapthing_t);
Begin
  //  player_t*		p;
  //    fixed_t		x;
  //    fixed_t		y;
  //    fixed_t		z;
  //
  //    mobj_t*		mobj;
  //
  //    int			i;
  //
  //    // [crispy] stop fast forward after entering new level while demo playback
  //    if (demo_gotonextlvl)
  //    {
  //        demo_gotonextlvl = false;
  //        G_DemoGotoNextLevel(false);
  //    }
  //
  //    if (mthing->type == 0)
  //    {
  //        return;
  //    }
  //
  //    // not playing?
  //    if (!playeringame[mthing->type-1])
  //	return;
  //
  //    p = &players[mthing->type-1];
  //
  //    if (p->playerstate == PST_REBORN)
  //	G_PlayerReborn (mthing->type-1);
  //
  //    x 		= mthing->x << FRACBITS;
  //    y 		= mthing->y << FRACBITS;
  //    z		= ONFLOORZ;
  //    mobj	= P_SpawnMobj (x,y,z, MT_PLAYER);
  //
  //    // set color translations for player sprites
  //    if (mthing->type > 1)
  //	mobj->flags |= (mthing->type-1)<<MF_TRANSSHIFT;
  //
  //    mobj->angle	= ANG45 * (mthing->angle/45);
  //    mobj->player = p;
  //    mobj->health = p->health;
  //
  //    p->mo = mobj;
  //    p->playerstate = PST_LIVE;
  //    p->refire = 0;
  //    p->message = NULL;
  //    p->damagecount = 0;
  //    p->bonuscount = 0;
  //    p->extralight = 0;
  //    p->fixedcolormap = 0;
  //    p->viewheight = VIEWHEIGHT;
  //
  //    // [crispy] weapon sound source
  //    p->so = Crispy_PlayerSO(mthing->type-1);
  //
  //    pspr_interp = false; // interpolate weapon bobbing
  //
  //    // setup gun psprite
  //    P_SetupPsprites (p);
  //
  //    // give all cards in death match mode
  //    if (deathmatch)
  //	for (i=0 ; i<NUMCARDS ; i++)
  //	    p->cards[i] = true;
  //
  //    if (mthing->type-1 == consoleplayer)
  //    {
  //	// wake up the status bar
  //	ST_Start ();
  //	// wake up the heads up text
  //	HU_Start ();
  //    }
End;

End.

