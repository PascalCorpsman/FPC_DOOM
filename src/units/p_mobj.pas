Unit p_mobj;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdata, doomdef, tables, info_types
  , d_player //, d_ticcmd
  , m_fixed
  , p_local
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

Var
  itemrespawnque: Array[0..ITEMQUESIZE - 1] Of mapthing_t;
  itemrespawntime: Array[0..ITEMQUESIZE - 1] Of int;
  iquehead: int;
  iquetail: int;

Procedure P_SpawnPlayer(Const mthing: mapthing_t);

Procedure P_SpawnMapThing(mthing: Pmapthing_t);

Function P_SpawnMobj(x, y, z: fixed_t; _type: mobjtype_t): Pmobj_t;

Procedure P_MobjThinker(mobj: Pmobj_t);

Procedure FreeAllocations();

Implementation

Uses
  info
  , d_mode, d_main
  , g_game
  , hu_stuff
  , m_random
  , p_setup, p_maputl, p_pspr, p_tick
  , r_things, r_data
  , st_stuff
  , v_patch
  , w_wad
  , z_zone
  ;

Var
  GlobalAllocs: Array Of Pmobj_t = Nil;
  GlobalAllocCounter: integer = 0;

Procedure SafeGlobalAllocsObj(Const obj: Pmobj_t);
Begin
  If GlobalAllocCounter > high(GlobalAllocs) Then Begin
    setlength(GlobalAllocs, high(GlobalAllocs) + 1024);
  End;
  GlobalAllocs[GlobalAllocCounter] := obj;
  GlobalAllocCounter := GlobalAllocCounter + 1;
End;

Function Crispy_PlayerSO(p: int): Pmobj_t;
Begin
  //	return crispy->soundfull ? (mobj_t *) &muzzles[p] : players[p].mo;
  result := players[p].mo;
End;

//
// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.
//

Procedure P_SpawnPlayer(Const mthing: mapthing_t);
Var
  p: ^player_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;

  mobj: Pmobj_t;

  i: int;
Begin

  // [crispy] stop fast forward after entering new level while demo playback
  If (demo_gotonextlvl) Then Begin
    demo_gotonextlvl := false;
    G_DemoGotoNextLevel(false);
  End;

  If (mthing._type = 0) Then exit;

  // not playing?
  If (Not playeringame[mthing._type - 1]) Then exit;

  p := @players[mthing._type - 1];

  If (p^.playerstate = PST_REBORN) Then G_PlayerReborn(mthing._type - 1);

  x := mthing.x Shl FRACBITS;
  y := mthing.y Shl FRACBITS;
  z := ONFLOORZ;
  mobj := P_SpawnMobj(x, y, z, MT_PLAYER);

  // set color translations for player sprites
  If (mthing._type > 1) Then Begin
    mobj^.flags := mobj^.flags Or (mthing._type - 1) Shl MF_TRANSSHIFT;
  End;

  mobj^.angle := ANG45 * (mthing.angle Div 45);
  mobj^.player := p;
  mobj^.health := p^.health;

  p^.mo := mobj;
  p^.playerstate := PST_LIVE;
  p^.refire := 0;
  p^.message := '';
  p^.damagecount := 0;
  p^.bonuscount := 0;
  p^.extralight := 0;
  p^.fixedcolormap := 0;
  p^.viewheight := DEFINE_VIEWHEIGHT;

  // [crispy] weapon sound source
  p^.so := Crispy_PlayerSO(mthing._type - 1);

  pspr_interp := false; // interpolate weapon bobbing

  // setup gun psprite
  P_SetupPsprites(p);

  // give all cards in death match mode
  If (deathmatch <> 0) Then Begin
    For i := 0 To integer(NUMCARDS) - 1 Do Begin
      p^.cards[card_t(i)] := true;
    End;
  End;
  If (mthing._type - 1 = consoleplayer) Then Begin
    // wake up the status bar
    ST_Start();
    // wake up the heads up text
    HU_Start();
  End;
End;

//
// P_SpawnMapThing
// The fields of the mapthing should
// already be in host byte order.
//

Procedure P_SpawnMapThing(mthing: Pmapthing_t);
Var
  i, j: int;
  bit: int;
  mobj: Pmobj_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  musid: int = 0;
Begin

  // count deathmatch start positions
  If (mthing^._type = 11) Then Begin
    If (deathmatch_p <= high(deathmatchstarts)) Then Begin
      deathmatchstarts[deathmatch_p] := mthing^;
      inc(deathmatch_p);
    End;
    exit;
  End;

  If (mthing^._type <= 0) Then Begin
    // Thing type 0 is actually "player -1 start".
    // For some reason, Vanilla Doom accepts/ignores this.
    exit;
  End;

  // check for players specially
  If (mthing^._type <= MAXPLAYERS) Then Begin
    // save spots for respawning in network games
    playerstarts[mthing^._type - 1] := mthing^;
    playerstartsingame[mthing^._type - 1] := true;
    If (deathmatch = 0) Then Begin
      P_SpawnPlayer(mthing^);
    End;
    exit;
  End;

  // check for appropriate skill level
  If (Not coop_spawns) And (Not netgame) And ((mthing^.options And 16) <> 0) Then exit;

  If (gameskill = sk_baby) Then
    bit := 1
  Else If (gameskill = sk_nightmare) Then
    bit := 4
  Else Begin
    // avoid undefined behavior (left shift by negative value and rhs too big)
    // by accurately emulating what doom.exe did: reduce mod 32.
    // For more details check:
    // https://github.com/chocolate-doom/chocolate-doom/issues/1677
    bit := (1 Shl ((integer(gameskill) - 1) And $1F));
  End;
  // [crispy] warn about mapthings without any skill tag set
  If ((mthing^.options And (MTF_EASY Or MTF_NORMAL Or MTF_HARD)) <> 0) Then Begin
    writeln(stderr, format('P_SpawnMapThing: Mapthing type %i without any skill tag at (%i, %i)',
      [mthing^._type, mthing^.x, mthing^.y]));
  End;

  If ((mthing^.options And bit) = 0) Then exit;

  // [crispy] support MUSINFO lump (dynamic music changing)
  If (mthing^._type >= 14100) And (mthing^._type <= 14164) Then Begin
    musid := mthing^._type - 14100;
    mthing^._type := mobjinfo[integer(MT_MUSICSOURCE)].doomednum;
  End;

  // find which type to spawn
  i := -1;
  For j := 0 To integer(NUMMOBJTYPES) - 1 Do Begin
    If (mthing^._type = mobjinfo[i].doomednum) Then Begin
      i := j;
      break;
    End;
  End;

  If (i = -1) Then Begin
    // [crispy] ignore unknown map things
    writeln(stderr, format('P_SpawnMapThing: Unknown type %i at (%i, %i)', [mthing^._type, mthing^.x, mthing^.y]));
    exit;
  End;

  // don't spawn keycards and players in deathmatch
  If (deathmatch <> 0) And ((mobjinfo[i].flags And MF_NOTDMATCH) <> 0) Then exit;

  // don't spawn any monsters if -nomonsters
  If (nomonsters) And ((i = integer(MT_SKULL)) Or ((mobjinfo[i].flags And MF_COUNTKILL) <> 0)) Then exit;

  // spawn it
  x := mthing^.x Shl FRACBITS;
  y := mthing^.y Shl FRACBITS;

  If (mobjinfo[i].flags And MF_SPAWNCEILING) <> 0 Then
    z := ONCEILINGZ
  Else
    z := ONFLOORZ;

  mobj := P_SpawnMobj(x, y, z, mobjtype_t(i));
  mobj^.spawnpoint := mthing^;

  If (mobj^.tics > 0) Then
    mobj^.tics := 1 + (P_Random() Mod mobj^.tics);
  If (mobj^.flags And MF_COUNTKILL) <> 0 Then
    totalkills := totalkills + 1;
  If (mobj^.flags And MF_COUNTITEM) <> 0 Then
    totalitems := totalitems + 1;

  mobj^.angle := ANG45 * (mthing^.angle Div 45);
  If (mthing^.options And MTF_AMBUSH) <> 0 Then
    mobj^.flags := mobj^.flags Or MF_AMBUSH;

  // [crispy] support MUSINFO lump (dynamic music changing)
  If (i = integer(MT_MUSICSOURCE)) Then Begin
    mobj^.health := 1000 + musid;
  End;
  // [crispy] Lost Souls bleed Puffs
  If (false {crispy^.coloredblood = COLOREDBLOOD_ALL}) And (i = integer(MT_SKULL)) Then
    mobj^.flags := mobj^.flags Or MF_NOBLOOD;

  // [crispy] blinking key or skull in the status bar
  If (mobj^.sprite = SPR_BSKU) Then
    st_keyorskull[it_bluecard] := 3
  Else If (mobj^.sprite = SPR_RSKU) Then
    st_keyorskull[it_redcard] := 3
  Else If (mobj^.sprite = SPR_YSKU) Then
    st_keyorskull[it_yellowcard] := 3;
End;

// [crispy] return the latest "safe" state in a state sequence,
// so that no action pointer is ever called

Var
  laststate, lastsafestate: statenum_t;

Function P_LatestSafeState(state: statenum_t): statenum_t;
Var
  safestate: statenum_t = S_NULL;
Begin
  Raise exception.create('P_LatestSafeState: hier fehlt noch was');
  If (state = laststate) Then Begin
    result := lastsafestate;
  End;

  //    for (laststate = state; state != S_NULL; state = states[state].nextstate)
  //    {
  //	if (safestate == S_NULL)
  //	{
  //	    safestate = state;
  //	}
  //
  //	if (states[state].action.acp1)
  //	{
  //	    safestate = S_NULL;
  //	}
  //
  //	// [crispy] a state with -1 tics never changes
  //	if (states[state].tics == -1 || state == states[state].nextstate)
  //	{
  //	    break;
  //	}
  //    }
  //
  //    return lastsafestate = safestate;
End;

Procedure P_MobjThinker(mobj: Pmobj_t);
Begin
  // [crispy] support MUSINFO lump (dynamic music changing)
//    if (mobj->type == MT_MUSICSOURCE)
//    {
//	return MusInfoThinker(mobj);
//    }
//    // [crispy] suppress interpolation of player missiles for the first tic
//    // and Archvile fire to mitigate it being spawned at the wrong location
//    if (mobj->interp < 0)
//    {
//        mobj->interp++;
//    }
//    else
//    // [AM] Handle interpolation unless we're an active player.
//    if (!(mobj->player != NULL && mobj == mobj->player->mo))
//    {
//        // Assume we can interpolate at the beginning
//        // of the tic.
//        mobj->interp = true;
//
//        // Store starting position for mobj interpolation.
//        mobj->oldx = mobj->x;
//        mobj->oldy = mobj->y;
//        mobj->oldz = mobj->z;
//        mobj->oldangle = mobj->angle;
//    }
//
//    // momentum movement
//    if (mobj->momx
//	|| mobj->momy
//	|| (mobj->flags&MF_SKULLFLY) )
//    {
//	P_XYMovement (mobj);
//
//	// FIXME: decent NOP/NULL/Nil function pointer please.
//	if (mobj->thinker.function.acv == (actionf_v) (-1))
//	    return;		// mobj was removed
//    }
//    if ( (mobj->z != mobj->floorz)
//	 || mobj->momz )
//    {
//	P_ZMovement (mobj);
//
//	// FIXME: decent NOP/NULL/Nil function pointer please.
//	if (mobj->thinker.function.acv == (actionf_v) (-1))
//	    return;		// mobj was removed
//    }
//
//
//    // cycle through states,
//    // calling action functions at transitions
//    if (mobj->tics != -1)
//    {
//	mobj->tics--;
//
//	// you can cycle through multiple states in a tic
//	if (!mobj->tics)
//	    if (!P_SetMobjState (mobj, mobj->state->nextstate) )
//		return;		// freed itself
//    }
//    else
//    {
//	// check for nightmare respawn
//	if (! (mobj->flags & MF_COUNTKILL) )
//	    return;
//
//	if (!respawnmonsters)
//	    return;
//
//	mobj->movecount++;
//
//	if (mobj->movecount < 12*TICRATE)
//	    return;
//
//	if ( leveltime&31 )
//	    return;
//
//	if (P_Random () > 4)
//	    return;
//
//	P_NightmareRespawn (mobj);
//    }
End;

Function P_SpawnMobjSafe(x, y, z: fixed_t; _type: mobjtype_t; safe: boolean): Pmobj_t; // TODO: Wo werden die hier erzeugten Pointer wieder frei gegeben ?
Var
  mobj: Pmobj_t;
  st: ^state_t;
  info: ^mobjinfo_t;
  sprdef: ^spritedef_t;
  sprframe: ^spriteframe_t;
  lump: int;
  patch: Ppatch_t;
Begin
  new(mobj);
  SafeGlobalAllocsObj(mobj);
  FillChar(mobj^, sizeof(mobj_t), 0);
  info := @mobjinfo[integer(_type)];

  mobj^._type := _type;
  mobj^.info := info;
  mobj^.x := x;
  mobj^.y := y;
  mobj^.radius := info^.radius;
  mobj^.height := info^.height;
  mobj^.flags := info^.flags;
  mobj^.health := info^.spawnhealth;

  If (gameskill <> sk_nightmare) Then Begin
    mobj^.reactiontime := info^.reactiontime;
  End;

  If safe Then Begin
    mobj^.lastlook := Crispy_Random() Mod MAXPLAYERS;
  End
  Else Begin
    mobj^.lastlook := P_Random() Mod MAXPLAYERS;
  End;

  // do not set the state with P_SetMobjState,
  // because action routines can not be called yet
  If safe Then Begin
    st := @states[integer(P_LatestSafeState(info^.spawnstate))];
  End
  Else Begin
    st := @states[integer(info^.spawnstate)];
  End;

  mobj^.state := st;
  mobj^.tics := st^.tics;
  mobj^.sprite := st^.sprite;
  mobj^.frame := st^.frame;

  // set subsector and/or block links
  P_SetThingPosition(mobj);

  mobj^.floorz := mobj^.subsector^.sector^.floorheight;
  mobj^.ceilingz := mobj^.subsector^.sector^.ceilingheight;

  If (z = ONFLOORZ) Then
    mobj^.z := mobj^.floorz
  Else If (z = ONCEILINGZ) Then
    mobj^.z := mobj^.ceilingz - mobj^.info^.height
  Else
    mobj^.z := z;

  // [crispy] randomly flip corpse, blood and death animation sprites
  If ((mobj^.flags And MF_FLIPPABLE) <> 0) And ((mobj^.flags And MF_SHOOTABLE) = 0) Then Begin
    mobj^.health := (mobj^.health And Not int(1)) - (Crispy_Random() And 1);
  End;

  // [AM] Do not interpolate on spawn.
  mobj^.interp := false;

  // [AM] Just in case interpolation is attempted...
  mobj^.oldx := mobj^.x;
  mobj^.oldy := mobj^.y;
  mobj^.oldz := mobj^.z;
  mobj^.oldangle := mobj^.angle;

  // [crispy] height of the spawnstate's first sprite in pixels
  If (info^.actualheight = 0) Then Begin

    sprdef := @sprites[integer(mobj^.sprite)];

    If ((sprdef^.numframes = 0) Or ((mobj^.flags And (MF_SOLID Or MF_SHOOTABLE)) = 0)) Then Begin
      info^.actualheight := info^.height;
    End
    Else Begin

      //
      sprframe := @sprdef^.spriteframes[mobj^.frame And FF_FRAMEMASK];
      lump := sprframe^.lump[0];
      patch := W_CacheLumpNum(lump + firstspritelump, PU_CACHE);

      // [crispy] round up to the next integer multiple of 8
      info^.actualheight := ((SHORT(patch^.height) + 7) Shr 3) Shl (FRACBITS + 3);
    End;
  End;

  mobj^.thinker._function.acp1 := @P_MobjThinker;

  P_AddThinker(@mobj^.thinker);

  result := mobj;
End;

Function P_SpawnMobj(x, y, z: fixed_t; _type: mobjtype_t): Pmobj_t;
Begin
  result := P_SpawnMobjSafe(x, y, z, _Type, false);
End;

Procedure FreeAllocations();
Var
  i: Integer;
Begin
  For i := 0 To GlobalAllocCounter - 1 Do Begin
    Dispose(GlobalAllocs[i]);
  End;
  GlobalAllocCounter := 0;
End;

Finalization

  FreeAllocations();



End.

