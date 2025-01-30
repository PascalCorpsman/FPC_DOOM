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

Procedure P_SpawnPuffSafe(x, y, z: fixed_t; safe: boolean);

Function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;

Implementation

Uses
  info
  , d_mode, d_main
  , g_game
  , hu_stuff
  , i_system
  , m_random, m_bbox
  , p_setup, p_maputl, p_pspr, p_tick, p_map, p_spec
  , r_things, r_data, r_sky, r_main
  , st_stuff
  , v_patch
  , w_wad
  , z_zone
  ;

Const
  STOPSPEED = $1000;
  FRICTION = $E800;

Var
  StateNull: statenum_t = S_NULL; // Der Code braucht einen "Global" Verfügbaren Pointer der immer auf S_NULL zeigt, und hier ist er ;)

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
// P_RemoveMobj
//

//mapthing_t itemrespawnque[ITEMQUESIZE];
//int itemrespawntime[ITEMQUESIZE];
//int iquehead;
//int iquetail;

Procedure P_RemoveMobj(mobj: Pmobj_t);
Begin
  //    if ((mobj->flags & MF_SPECIAL)
  //	&& !(mobj->flags & MF_DROPPED)
  //	&& (mobj->type != MT_INV)
  //	&& (mobj->type != MT_INS))
  //    {
  //	itemrespawnque[iquehead] = mobj->spawnpoint;
  //	itemrespawntime[iquehead] = leveltime;
  //	iquehead = (iquehead+1)&(ITEMQUESIZE-1);
  //
  //	// lose one off the end?
  //	if (iquehead == iquetail)
  //	    iquetail = (iquetail+1)&(ITEMQUESIZE-1);
  //    }
  //
  //    // unlink from sector and block lists
  //    P_UnsetThingPosition (mobj);
  //
  //    // [crispy] removed map objects may finish their sounds
  //    if (crispy->soundfull)
  //    {
  //	S_UnlinkSound(mobj);
  //    }
  //    else
  //    {
  //    // stop any playing sound
  //    S_StopSound (mobj);
  //    }
  //
  //    // free block
  //    P_RemoveThinker ((thinker_t*)mobj);
End;

//
// P_ExplodeMissile
//

Procedure P_ExplodeMissileSafe(mo: Pmobj_t; safe: boolean);
Begin
  //    mo->momx = mo->momy = mo->momz = 0;
  //
  //    P_SetMobjState (mo, safe ? P_LatestSafeState(mobjinfo[mo->type].deathstate) : mobjinfo[mo->type].deathstate);
  //
  //    mo->tics -= safe ? Crispy_Random()&3 : P_Random()&3;
  //
  //    if (mo->tics < 1)
  //	mo->tics = 1;
  //
  //    mo->flags &= ~MF_MISSILE;
  //    // [crispy] missile explosions are translucent
  //    mo->flags |= MF_TRANSLUCENT;
  //
  //    if (mo->info->deathsound)
  //	S_StartSound (mo, mo->info->deathsound);
End;


// Use a heuristic approach to detect infinite state cycles: Count the number
// of times the loop in P_SetMobjState() executes and exit with an error once
// an arbitrary very large limit is reached.

Const
  MOBJ_CYCLE_LIMIT = 1000000;

Function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;
Var
  st: ^state_t;
  cycle_counter: int;
Begin
  cycle_counter := 0;
  Repeat
    If (state = S_NULL) Then Begin
      mobj^.state := @StateNull;
      P_RemoveMobj(mobj);
      result := false;
      exit;
    End;

    st := @states[integer(state)];
    mobj^.state := st;
    mobj^.tics := st^.tics;
    mobj^.sprite := st^.sprite;
    mobj^.frame := st^.frame;

    // Modified handling.
    // Call action functions when the state is set
    If assigned(st^.action.acp3) Then
      st^.action.acp3(mobj, Nil, Nil); // [crispy] let pspr action pointers get called from mobj states

    state := st^.nextstate;
    cycle_counter := cycle_counter + 1;
    If (cycle_counter > MOBJ_CYCLE_LIMIT) Then Begin
      I_Error('P_SetMobjState: Infinite state cycle detected!');
    End;
  Until mobj^.tics <> 0;

  result := true;
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
  If ((mthing^.options And (MTF_EASY Or MTF_NORMAL Or MTF_HARD)) = 0) Then Begin
    writeln(stderr, format('P_SpawnMapThing: Mapthing type %d without any skill tag at (%d, %d)',
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
    If (mthing^._type = mobjinfo[j].doomednum) Then Begin
      i := j;
      break;
    End;
  End;

  If (i = -1) Then Begin
    // [crispy] ignore unknown map things
    writeln(stderr, format('P_SpawnMapThing: Unknown type %d at (%d, %d)', [mthing^._type, mthing^.x, mthing^.y]));
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


//
// MOVEMENT CLIPPING
//

//
// P_CheckPosition
// This is purely informative, nothing is modified
// (except things picked up).
//
// in:
//  a mobj_t (can be valid or invalid)
//  a position to be checked
//   (doesn't need to be related to the mobj_t->x,y)
//
// during:
//  special things are touched if MF_PICKUP
//  early out on solid lines?
//
// out:
//  newsubsec
//  floorz
//  ceilingz
//  tmdropoffz
//   the lowest point contacted
//   (monsters won't move to a dropoff)
//  speciallines[]
//  numspeciallines
//

Function P_CheckPosition(thing: Pmobj_t; x, y: fixed_t): boolean;
Var
  xl, xh, yl, yh, bx, by: int;
  newsubsec: Psubsector_t;
Begin

  tmthing := thing;
  tmflags := thing^.flags;

  tmx := x;
  tmy := y;

  tmbbox[BOXTOP] := y + tmthing^.radius;
  tmbbox[BOXBOTTOM] := y - tmthing^.radius;
  tmbbox[BOXRIGHT] := x + tmthing^.radius;
  tmbbox[BOXLEFT] := x - tmthing^.radius;

  newsubsec := R_PointInSubsector(x, y);
  ceilingline := Nil;

  // The base floor / ceiling is from the subsector
  // that contains the point.
  // Any contacted lines the step closer together
  // will adjust them.
  tmfloorz := newsubsec^.sector^.floorheight;
  tmdropoffz := newsubsec^.sector^.floorheight;
  tmceilingz := newsubsec^.sector^.ceilingheight;

  validcount := validcount + 1;
  numspechit := 0;

  If (tmflags And MF_NOCLIP) <> 0 Then Begin
    result := true;
    exit;
  End;

  // Check things first, possibly picking things up.
  // The bounding box is extended by MAXRADIUS
  // because mobj_ts are grouped into mapblocks
  // based on their origin point, and can overlap
  // into adjacent blocks by up to MAXRADIUS units.
  xl := SarLongint(tmbbox[BOXLEFT] - bmaporgx - MAXRADIUS, MAPBLOCKSHIFT);
  xh := SarLongint(tmbbox[BOXRIGHT] - bmaporgx + MAXRADIUS, MAPBLOCKSHIFT);
  yl := SarLongint(tmbbox[BOXBOTTOM] - bmaporgy - MAXRADIUS, MAPBLOCKSHIFT);
  yh := SarLongint(tmbbox[BOXTOP] - bmaporgy + MAXRADIUS, MAPBLOCKSHIFT);

  //    for (bx=xl ; bx<=xh ; bx++)
  //	for (by=yl ; by<=yh ; by++)
  //	    if (!P_BlockThingsIterator(bx,by,PIT_CheckThing))
  //		return false;

  //    // check lines
  //    xl = (tmbbox[BOXLEFT] - bmaporgx)>>MAPBLOCKSHIFT;
  //    xh = (tmbbox[BOXRIGHT] - bmaporgx)>>MAPBLOCKSHIFT;
  //    yl = (tmbbox[BOXBOTTOM] - bmaporgy)>>MAPBLOCKSHIFT;
  //    yh = (tmbbox[BOXTOP] - bmaporgy)>>MAPBLOCKSHIFT;

  //    for (bx=xl ; bx<=xh ; bx++)
  //	for (by=yl ; by<=yh ; by++)
  //	    if (!P_BlockLinesIterator (bx,by,PIT_CheckLine))
  //		return false;

  result := true;
End;

//
// P_TryMove
// Attempt to move to a new position,
// crossing special lines unless MF_TELEPORT is set.
//

Function P_TryMove(thing: Pmobj_t; x, y: fixed_t): boolean;
Var
  oldx, oldy: fixed_t;
  side, oldside: int;
  ld: Pline_t;
Begin
  result := false;

  floatok := false;
  If (Not P_CheckPosition(thing, x, y)) Then exit; // solid wall or thing

  If ((thing^.flags And MF_NOCLIP) = 0) Then Begin

    If (tmceilingz - tmfloorz < thing^.height) Then exit; // doesn't fit

    floatok := true;

    If ((thing^.flags And MF_TELEPORT) = 0)
      And (tmceilingz - thing^.z < thing^.height) Then
      exit; // mobj must lower itself to fit

    If ((thing^.flags And MF_TELEPORT) = 0)
      And (tmfloorz - thing^.z > 24 * FRACUNIT) Then
      exit; // too big a step up

    If ((thing^.flags And (MF_DROPOFF Or MF_FLOAT)) = 0)
      And (tmfloorz - tmdropoffz > 24 * FRACUNIT) Then
      exit; // don't stand over a dropoff
  End;

  // the move is ok,
  // so link the thing into its new position
  P_UnsetThingPosition(thing);

  oldx := thing^.x;
  oldy := thing^.y;
  thing^.floorz := tmfloorz;
  thing^.ceilingz := tmceilingz;
  thing^.x := x;
  thing^.y := y;

  P_SetThingPosition(thing);

  // if any special lines were hit, do the effect
  If ((thing^.flags And (MF_TELEPORT Or MF_NOCLIP)) = 0) Then Begin

    While (numspechit <> 0) Do Begin

      // see if the line was crossed
      ld := spechit[numspechit];
      side := P_PointOnLineSide(thing^.x, thing^.y, ld);
      oldside := P_PointOnLineSide(oldx, oldy, ld);
      If (side <> oldside) Then Begin
        If (ld^.special <> 0) Then Begin
          P_CrossSpecialLine(ld - @lines[0], oldside, thing);
        End;
      End;
      numspechit := numspechit - 1
    End;
  End;

  result := true;
End;


//
// P_SlideMove
// The momx / momy move is bad, so try to slide
// along a wall.
// Find the first line hit, move flush to it,
// and slide along it
//
// This is a kludgy mess.
//

Procedure P_SlideMove(mo: Pmobj_t);
Begin
  //    fixed_t		leadx;
  //    fixed_t		leady;
  //    fixed_t		trailx;
  //    fixed_t		traily;
  //    fixed_t		newx;
  //    fixed_t		newy;
  //    int			hitcount;
  //
  //    slidemo = mo;
  //    hitcount = 0;
  //
  //  retry:
  //    if (++hitcount == 3)
  //	goto stairstep;		// don't loop forever
  //
  //
  //    // trace along the three leading corners
  //    if (mo->momx > 0)
  //    {
  //	leadx = mo->x + mo->radius;
  //	trailx = mo->x - mo->radius;
  //    }
  //    else
  //    {
  //	leadx = mo->x - mo->radius;
  //	trailx = mo->x + mo->radius;
  //    }
  //
  //    if (mo->momy > 0)
  //    {
  //	leady = mo->y + mo->radius;
  //	traily = mo->y - mo->radius;
  //    }
  //    else
  //    {
  //	leady = mo->y - mo->radius;
  //	traily = mo->y + mo->radius;
  //    }
  //
  //    bestslidefrac = FRACUNIT+1;
  //
  //    P_PathTraverse ( leadx, leady, leadx+mo->momx, leady+mo->momy,
  //		     PT_ADDLINES, PTR_SlideTraverse );
  //    P_PathTraverse ( trailx, leady, trailx+mo->momx, leady+mo->momy,
  //		     PT_ADDLINES, PTR_SlideTraverse );
  //    P_PathTraverse ( leadx, traily, leadx+mo->momx, traily+mo->momy,
  //		     PT_ADDLINES, PTR_SlideTraverse );
  //
  //    // move up to the wall
  //    if (bestslidefrac == FRACUNIT+1)
  //    {
  //	// the move most have hit the middle, so stairstep
  //      stairstep:
  //	if (!P_TryMove (mo, mo->x, mo->y + mo->momy))
  //	    P_TryMove (mo, mo->x + mo->momx, mo->y);
  //	return;
  //    }
  //
  //    // fudge a bit to make sure it doesn't hit
  //    bestslidefrac -= 0x800;
  //    if (bestslidefrac > 0)
  //    {
  //	newx = FixedMul (mo->momx, bestslidefrac);
  //	newy = FixedMul (mo->momy, bestslidefrac);
  //
  //	if (!P_TryMove (mo, mo->x+newx, mo->y+newy))
  //	    goto stairstep;
  //    }
  //
  //    // Now continue along the wall.
  //    // First calculate remainder.
  //    bestslidefrac = FRACUNIT-(bestslidefrac+0x800);
  //
  //    if (bestslidefrac > FRACUNIT)
  //	bestslidefrac = FRACUNIT;
  //
  //    if (bestslidefrac <= 0)
  //	return;
  //
  //    tmxmove = FixedMul (mo->momx, bestslidefrac);
  //    tmymove = FixedMul (mo->momy, bestslidefrac);
  //
  //    P_HitSlideLine (bestslideline);	// clip the moves
  //
  //    mo->momx = tmxmove;
  //    mo->momy = tmymove;
  //
  //    if (!P_TryMove (mo, mo->x+tmxmove, mo->y+tmymove))
  //    {
  //	goto retry;
  //    }
End;

//
// P_XYMovement
//

Procedure P_XYMovement(mo: Pmobj_t);
Var
  ptryx: fixed_t;
  ptryy: fixed_t;
  player: ^player_t;
  xmove: fixed_t;
  ymove: fixed_t;
  safe: Boolean;
Begin
  If (mo^.momx = 0) And (mo^.momy = 0) Then Begin
    If (mo^.flags And MF_SKULLFLY) <> 0 Then Begin
      // the skull slammed into something
      mo^.flags := mo^.flags And Not MF_SKULLFLY;
      mo^.momx := 0;
      mo^.momy := 0;
      mo^.momz := 0;

      P_SetMobjState(mo, mo^.info^.spawnstate);
    End;
    exit;
  End;

  player := mo^.player;

  If (mo^.momx > MAXMOVE) Then
    mo^.momx := MAXMOVE
  Else If (mo^.momx < -MAXMOVE) Then
    mo^.momx := -MAXMOVE;

  If (mo^.momy > MAXMOVE) Then
    mo^.momy := MAXMOVE
  Else If (mo^.momy < -MAXMOVE) Then
    mo^.momy := -MAXMOVE;

  xmove := mo^.momx;
  ymove := mo^.momy;

  Repeat
    If (xmove > MAXMOVE Div 2) Or (ymove > MAXMOVE Div 2) Then Begin
      ptryx := mo^.x + xmove Div 2;
      ptryy := mo^.y + ymove Div 2;
      xmove := xmove Shr 1;
      ymove := ymove Shr 1;
    End
    Else Begin
      ptryx := mo^.x + xmove;
      ptryy := mo^.y + ymove;
      xmove := 0;
      ymove := 0;
    End;

    If (Not P_TryMove(mo, ptryx, ptryy)) Then Begin

      // blocked move
      If assigned(mo^.player) Then Begin
        // try to slide along it
        P_SlideMove(mo);
      End
      Else If (mo^.flags And MF_MISSILE) <> 0 Then Begin

        safe := false;
        // explode a missile
        If assigned(ceilingline) And
          assigned(ceilingline^.backsector) And
          (ceilingline^.backsector^.ceilingpic = skyflatnum) Then Begin
          If (mo^.z > ceilingline^.backsector^.ceilingheight) Then Begin
            // Hack to prevent missiles exploding
            // against the sky.
            // Does not handle sky floors.
            P_RemoveMobj(mo);
            exit;
          End
          Else Begin
            safe := true;
          End;
        End;
        P_ExplodeMissileSafe(mo, safe);
      End
      Else Begin
        mo^.momx := 0;
        mo^.momy := 0;
      End;
    End;
  Until (xmove = 0) And (ymove = 0); //    } while (xmove || ymove);

  // slow down
  If assigned(player) And ((player^.cheats And integer(CF_NOMOMENTUM)) <> 0) Then Begin
    // debug option for no sliding at all
    mo^.momx := 0;
    mo^.momy := 0;
    exit;
  End;

  If (mo^.flags And (MF_MISSILE Or MF_SKULLFLY)) <> 0 Then
    exit; // no friction for missiles ever

  // [crispy] fix mid-air speed boost when using noclip cheat
  //  if (!player || !(player^.mo^.flags & MF_NOCLIP))
  //  {
  //    if (mo^.z > mo^.floorz)
  //	return;		// no friction when airborne
  //  }

  //    if (mo^.flags & MF_CORPSE)
  //    {
  //	// do not stop sliding
  //	//  if halfway off a step with some momentum
  //	if (mo^.momx > FRACUNIT/4
  //	    || mo^.momx < -FRACUNIT/4
  //	    || mo^.momy > FRACUNIT/4
  //	    || mo^.momy < -FRACUNIT/4)
  //	{
  //	    if (mo^.floorz != mo^.subsector^.sector^.floorheight)
  //		return;
  //	}
  //    }

  If (mo^.momx > -STOPSPEED)
    And (mo^.momx < STOPSPEED)
    And (mo^.momy > -STOPSPEED)
    And (mo^.momy < STOPSPEED)
    And (Not assigned(player) Or ((player^.cmd.forwardmove = 0) And (player^.cmd.sidemove = 0)))
    Then Begin
    // if in a walking frame, stop moving
    If assigned(player) And (((player^.mo^.state - @states[0]) - integer(S_PLAY_RUN1)) < 4) Then
      P_SetMobjState(player^.mo, S_PLAY);
    mo^.momx := 0;
    mo^.momy := 0;
  End
  Else Begin
    mo^.momx := FixedMul(mo^.momx, FRICTION);
    mo^.momy := FixedMul(mo^.momy, FRICTION);
  End;
End;

//
// P_ZMovement
//

Procedure P_ZMovement(mo: Pmobj_t);
Var
  dist, delta: fixed_t;
Begin

  //    // check for smooth step up
  //    if (mo->player && mo->z < mo->floorz)
  //    {
  //	mo->player->viewheight -= mo->floorz-mo->z;
  //
  //	mo->player->deltaviewheight
  //	    = (DEFINE_VIEWHEIGHT - mo->player->viewheight)>>3;
  //    }
  //
  //    // adjust height
  //    mo->z += mo->momz;
  //
  //    if ( mo->flags & MF_FLOAT
  //	 && mo->target)
  //    {
  //	// float down towards target if too close
  //	if ( !(mo->flags & MF_SKULLFLY)
  //	     && !(mo->flags & MF_INFLOAT) )
  //	{
  //	    dist = P_AproxDistance (mo->x - mo->target->x,
  //				    mo->y - mo->target->y);
  //
  //	    delta =(mo->target->z + (mo->height>>1)) - mo->z;
  //
  //	    if (delta<0 && dist < -(delta*3) )
  //		mo->z -= FLOATSPEED;
  //	    else if (delta>0 && dist < (delta*3) )
  //		mo->z += FLOATSPEED;
  //	}
  //
  //    }
  //
  //    // clip movement
  //    if (mo->z <= mo->floorz)
  //    {
  //	// hit the floor
  //
  //	// Note (id):
  //	//  somebody left this after the setting momz to 0,
  //	//  kinda useless there.
  //	//
  //	// cph - This was the a bug in the linuxdoom-1.10 source which
  //	//  caused it not to sync Doom 2 v1.9 demos. Someone
  //	//  added the above comment and moved up the following code. So
  //	//  demos would desync in close lost soul fights.
  //	// Note that this only applies to original Doom 1 or Doom2 demos - not
  //	//  Final Doom and Ultimate Doom.  So we test demo_compatibility *and*
  //	//  gamemission. (Note we assume that Doom1 is always Ult Doom, which
  //	//  seems to hold for most published demos.)
  //        //
  //        //  fraggle - cph got the logic here slightly wrong.  There are three
  //        //  versions of Doom 1.9:
  //        //
  //        //  * The version used in registered doom 1.9 + doom2 - no bounce
  //        //  * The version used in ultimate doom - has bounce
  //        //  * The version used in final doom - has bounce
  //        //
  //        // So we need to check that this is either retail or commercial
  //        // (but not doom2)
  //
  //	int correct_lost_soul_bounce = gameversion >= exe_ultimate;
  //
  //	if (correct_lost_soul_bounce && mo->flags & MF_SKULLFLY)
  //	{
  //	    // the skull slammed into something
  //	    mo->momz = -mo->momz;
  //	}
  //
  //	if (mo->momz < 0)
  //	{
  //	    // [crispy] delay next jump
  //	    if (mo->player)
  //		mo->player->jumpTics = 7;
  //	    if (mo->player
  //		&& mo->momz < -GRAVITY*8)
  //	    {
  //		// Squat down.
  //		// Decrease viewheight for a moment
  //		// after hitting the ground (hard),
  //		// and utter appropriate sound.
  //		mo->player->deltaviewheight = mo->momz>>3;
  //		// [crispy] center view if not using permanent mouselook
  //		if (!crispy->mouselook)
  //		    mo->player->centering = true;
  //		// [crispy] dead men don't say "oof"
  //		if (mo->health > 0 || !crispy->soundfix)
  //		{
  //		// [NS] Landing sound for longer falls. (Hexen's calculation.)
  //		if (mo->momz < -GRAVITY * 12)
  //		{
  //		    S_StartSoundOptional(mo, sfx_plland, sfx_oof);
  //		}
  //		else
  //		S_StartSound (mo, sfx_oof);
  //		}
  //	    }
  //	    // [NS] Beta projectile bouncing.
  //	    if ( (mo->flags & MF_MISSILE) && (mo->flags & MF_BOUNCES) )
  //	    {
  //		mo->momz = -mo->momz;
  //	    }
  //	    else
  //	    {
  //	    mo->momz = 0;
  //	    }
  //	}
  //	mo->z = mo->floorz;
  //
  //
  //	// cph 2001/05/26 -
  //	// See lost soul bouncing comment above. We need this here for bug
  //	// compatibility with original Doom2 v1.9 - if a soul is charging and
  //	// hit by a raising floor this incorrectly reverses its Y momentum.
  //	//
  //
  //        if (!correct_lost_soul_bounce && mo->flags & MF_SKULLFLY)
  //            mo->momz = -mo->momz;
  //
  //	if ( (mo->flags & MF_MISSILE)
  //	     // [NS] Beta projectile bouncing.
  //	     && !(mo->flags & MF_NOCLIP) && !(mo->flags & MF_BOUNCES) )
  //	{
  //	    P_ExplodeMissile (mo);
  //	    return;
  //	}
  //    }
  //    else if (! (mo->flags & MF_NOGRAVITY) )
  //    {
  //	if (mo->momz == 0)
  //	    mo->momz = -GRAVITY*2;
  //	else
  //	    mo->momz -= GRAVITY;
  //    }
  //
  //    if (mo->z + mo->height > mo->ceilingz)
  //    {
  //	// hit the ceiling
  //	if (mo->momz > 0)
  //	{
  //	// [NS] Beta projectile bouncing.
  //	    if ( (mo->flags & MF_MISSILE) && (mo->flags & MF_BOUNCES) )
  //	    {
  //		mo->momz = -mo->momz;
  //	    }
  //	    else
  //	    {
  //	    mo->momz = 0;
  //	    }
  //	}
  //	{
  //	    mo->z = mo->ceilingz - mo->height;
  //	}
  //
  //	if (mo->flags & MF_SKULLFLY)
  //	{	// the skull slammed into something
  //	    mo->momz = -mo->momz;
  //	}
  //
  //	if ( (mo->flags & MF_MISSILE)
  //	     && !(mo->flags & MF_NOCLIP) && !(mo->flags & MF_BOUNCES) )
  //	{
  //	    P_ExplodeMissile (mo);
  //	    return;
  //	}
  //    }
End;

Procedure P_MobjThinker(mobj: Pmobj_t);
Begin
  // [crispy] support MUSINFO lump (dynamic music changing)
  If (mobjtype_t(mobj^._type) = MT_MUSICSOURCE) Then Begin
    //MusInfoThinker(mobj);
    exit;
  End;
  // [crispy] suppress interpolation of player missiles for the first tic
  // and Archvile fire to mitigate it being spawned at the wrong location
  If (mobj^.interp < 0) Then Begin
    mobj^.interp := mobj^.interp + 1;
  End
    // [AM] Handle interpolation unless we're an active player.
  Else Begin
    // TODO: Prüfen ob das so passt, der C Code ist hier komisch ..
    If (mobj^.player = Nil) Or (mobj <> mobj^.player^.mo) Then Begin
      // Assume we can interpolate at the beginning
      // of the tic.
      mobj^.interp := 1;

      // Store starting position for mobj interpolation.
      mobj^.oldx := mobj^.x;
      mobj^.oldy := mobj^.y;
      mobj^.oldz := mobj^.z;
      mobj^.oldangle := mobj^.angle;
    End;
  End;

  // momentum movement
  If (mobj^.momx <> 0)
    Or (mobj^.momy <> 0)
    Or ((mobj^.flags And MF_SKULLFLY) <> 0) Then Begin

    P_XYMovement(mobj);
    // FIXME: decent NOP/NULL/Nil function pointer please.
    If (mobj^.thinker._function.acv = Nil) Then exit; // mobj was removed
  End;
  If ((mobj^.z <> mobj^.floorz)) Or (mobj^.momz <> 0) Then Begin
    P_ZMovement(mobj);
    // FIXME: decent NOP/NULL/Nil function pointer please.
    If (mobj^.thinker._function.acv = Nil) Then exit; // mobj was removed
  End;

  // cycle through states,
  // calling action functions at transitions
  If (mobj^.tics <> -1) Then Begin

    mobj^.tics := mobj^.tics - 1;

    // you can cycle through multiple states in a tic
    If (mobj^.tics = 0) Then Begin
      If (Not P_SetMobjState(mobj, mobj^.state^.nextstate)) Then
        exit; // freed itself
    End;
  End
  Else Begin
    //	// check for nightmare respawn
    //	if (! (mobj^.flags & MF_COUNTKILL) )
    //	    return;
    //
    //	if (!respawnmonsters)
    //	    return;
    //
    //	mobj^.movecount++;
    //
    //	if (mobj^.movecount < 12*TICRATE)
    //	    return;
    //
    //	if ( leveltime&31 )
    //	    return;
    //
    //	if (P_Random () > 4)
    //	    return;
    //
    //	P_NightmareRespawn (mobj);
  End;
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
  mobj^.interp := 0;

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

Procedure P_SpawnPuffSafe(x, y, z: fixed_t; safe: boolean);
Begin
  Raise exception.create('P_SpawnPuffSafe');
  //    mobj_t*	th;
  //
  //    z += safe ? (Crispy_SubRandom() << 10) : (P_SubRandom() << 10);
  //
  //    th = P_SpawnMobjSafe (x,y,z, MT_PUFF, safe);
  //    th->momz = FRACUNIT;
  //    th->tics -= safe ? Crispy_Random()&3 : P_Random()&3;
  //
  //    if (th->tics < 1)
  //	th->tics = 1;
  //
  //    // don't make punches spark on the wall
  //    if (attackrange == MELEERANGE)
  //	P_SetMobjState (th, safe ? P_LatestSafeState(S_PUFF3) : S_PUFF3);
End;

Finalization

  FreeAllocations();

End.

