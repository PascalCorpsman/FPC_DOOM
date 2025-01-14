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

