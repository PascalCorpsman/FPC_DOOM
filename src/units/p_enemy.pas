Unit p_enemy;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Procedure A_OpenShotgun2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_LoadShotgun2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_CloseShotgun2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_Explode(thingy: Pmobj_t);
Procedure A_Pain(actor: Pmobj_t);
Procedure A_PlayerScream(mo: Pmobj_t);
Procedure A_Fall(actor: Pmobj_t);
Procedure A_XScream(actor: Pmobj_t);
Procedure A_Look(actor: Pmobj_t);
Procedure A_Chase(actor: Pmobj_t);
Procedure A_FaceTarget(actor: Pmobj_t);
Procedure A_PosAttack(actor: Pmobj_t);
Procedure A_SPosAttack(actor: Pmobj_t);
Procedure A_Scream(actor: Pmobj_t);
Procedure A_VileChase(actor: Pmobj_t);
Procedure A_VileStart(actor: Pmobj_t);
Procedure A_VileTarget(actor: Pmobj_t);
Procedure A_VileAttack(actor: Pmobj_t);
Procedure A_StartFire(actor: Pmobj_t);
Procedure A_Fire(actor: Pmobj_t);
Procedure A_FireCrackle(actor: Pmobj_t);
Procedure A_Tracer(actor: Pmobj_t);
Procedure A_SkelWhoosh(actor: Pmobj_t);
Procedure A_SkelFist(actor: Pmobj_t);
Procedure A_SkelMissile(actor: Pmobj_t);
Procedure A_FatRaise(actor: Pmobj_t);
Procedure A_FatAttack1(actor: Pmobj_t);
Procedure A_FatAttack2(actor: Pmobj_t);
Procedure A_FatAttack3(actor: Pmobj_t);
Procedure A_BossDeath(mo: Pmobj_t);
Procedure A_CPosAttack(actor: Pmobj_t);
Procedure A_CPosRefire(actor: Pmobj_t);
Procedure A_TroopAttack(actor: Pmobj_t);
Procedure A_SargAttack(actor: Pmobj_t);
Procedure A_HeadAttack(actor: Pmobj_t);
Procedure A_BruisAttack(actor: Pmobj_t);
Procedure A_SkullAttack(actor: Pmobj_t);
Procedure A_Metal(mo: Pmobj_t);
Procedure A_BabyMetal(mo: Pmobj_t);
Procedure A_SpidRefire(actor: Pmobj_t);
Procedure A_BspiAttack(actor: Pmobj_t);
Procedure A_Hoof(mo: Pmobj_t);
Procedure A_CyberAttack(actor: Pmobj_t);
Procedure A_PainAttack(actor: Pmobj_t);
Procedure A_PainDie(actor: Pmobj_t);
Procedure A_KeenDie(mo: Pmobj_t);
Procedure A_BrainPain(mo: Pmobj_t);
Procedure A_BrainScream(mo: Pmobj_t);
Procedure A_BrainDie(mo: Pmobj_t);
Procedure A_BrainAwake(mo: Pmobj_t);
Procedure A_BrainSpit(mo: Pmobj_t);
Procedure A_BrainExplode(mo: Pmobj_t);
Procedure A_SpawnSound(mo: Pmobj_t);
Procedure A_SpawnFly(mo: Pmobj_t);

Procedure P_NoiseAlert(target: Pmobj_t; emmiter: Pmobj_t);

Implementation

Uses
  doomdata, sounds, tables, doomstat, doomdef, info
  , d_player, d_mode, d_main, d_loop
  , g_game
  , i_system, i_sound
  , m_fixed, m_random
  , p_pspr, p_map, p_maputl, p_setup, p_mobj, p_sight, p_local, p_switch, p_inter, p_tick, p_doors, p_spec, p_floor
  , r_main
  , s_sound
  ;


Type
  dirtype_t = (
    DI_EAST,
    DI_NORTHEAST,
    DI_NORTH,
    DI_NORTHWEST,
    DI_WEST,
    DI_SOUTHWEST,
    DI_SOUTH,
    DI_SOUTHEAST,
    DI_NODIR,
    NUMDIRS
    );

Const
  xspeed: Array[0..7] Of fixed_t = (FRACUNIT, 47000, 0, -47000, -FRACUNIT, -47000, 0, 47000);
  yspeed: Array[0..7] Of fixed_t = (0, 47000, FRACUNIT, 47000, 0, -47000, -FRACUNIT, -47000);

  //
  // P_NewChaseDir related LUT.
  //
  opposite: Array Of dirtype_t =
  (
    DI_WEST, DI_SOUTHWEST, DI_SOUTH, DI_SOUTHEAST,
    DI_EAST, DI_NORTHEAST, DI_NORTH, DI_NORTHWEST, DI_NODIR
    );

  diags: Array Of dirtype_t =
  (
    DI_NORTHWEST, DI_NORTHEAST, DI_SOUTHWEST, DI_SOUTHEAST
    );

Var
  soundtarget: Pmobj_t;
  //  mobj_t**		braintargets = NULL;
  //int		numbraintargets = 0; // [crispy] initialize
  //int		braintargeton = 0;
  //static int	maxbraintargets; // [crispy] remove braintargets limit

  corpsehit: pmobj_t;
  vileobj: pmobj_t;
  viletryx: fixed_t;
  viletryy: fixed_t;

  braintargets: Array Of Pmobj_t = Nil;
  numbraintargets: int = 0; // [crispy] initialize
  braintargeton: int = 0;
  maxbraintargets: int; // [crispy] remove braintargets limit

Procedure A_OpenShotgun2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  S_StartSound(player^.so, sfx_dbopn); // [crispy] weapon sound source
End;

Procedure A_LoadShotgun2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  S_StartSound(player^.so, sfx_dbload); // [crispy] weapon sound source
End;

Procedure A_CloseShotgun2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  S_StartSound(player^.so, sfx_dbcls); // [crispy] weapon sound source
  A_ReFire(Nil, player, psp); // [crispy] let pspr action pointers get called from mobj states
End;

Procedure A_Explode(thingy: Pmobj_t);
Begin
  P_RadiusAttack(thingy, thingy^.target, 128);
End;

Procedure A_Pain(actor: Pmobj_t);
Begin
  If (actor^.info^.painsound <> sfx_None) Then Begin
    S_StartSound(actor, actor^.info^.painsound);
  End;
End;

Procedure A_PlayerScream(mo: Pmobj_t);
Var
  sound: sfxenum_t;
Begin
  // Default death sound.
  sound := sfx_pldeth;

  If ((gamemode = commercial)
    And (mo^.health < -50)) Then Begin

    // IF THE PLAYER DIES
    // LESS THAN -50% WITHOUT GIBBING
    sound := sfx_pdiehi;
  End;
  S_StartSound(mo, sound);
End;

Procedure A_Fall(actor: Pmobj_t);
Begin
  // actor is on ground, it can be walked over
  actor^.flags := actor^.flags And Not MF_SOLID;

  // So change this if corpse objects
  // are meant to be obstacles.
End;

Procedure A_XScream(actor: Pmobj_t);
Begin
  S_StartSound(actor, sfx_slop);
End;

//
// P_LookForPlayers
// If allaround is false, only look 180 degrees in front.
// Returns true if a player is targeted.
//

Function P_LookForPlayers(actor: Pmobj_t; allaround: boolean): boolean;
Var
  c: int;
  stop: int;
  player: Pplayer_t;
  an: angle_t;
  dist: fixed_t;
  evalHack: Boolean; // Keine Ahnung wie man die For loop aus C korrekt übersetzt, aber mit dem Flag gehts..
Begin
  c := 0;
  stop := (actor^.lastlook - 1) And 3; // WTF: dass soll durch alle Spieler iterieren, das ginge aber nur wenn maxplayer = 4 ist !
  evalHack := true;
  Repeat
    If Not evalHack Then Begin
      actor^.lastlook := (actor^.lastlook + 1) And 3; // WTF: dass soll durch alle Spieler iterieren, das ginge aber nur wenn maxplayer = 4 ist !
    End;
    evalHack := false;

    If (Not playeringame[actor^.lastlook]) Then Begin
      continue;
    End;

    c := c + 1;
    If (c = 2) Or (actor^.lastlook = stop) Then Begin
      // done looking
      result := false;
      exit;
    End;

    player := @players[actor^.lastlook];

    // [crispy] monsters don't look for players with NOTARGET cheat
    If (player^.cheats And integer(CF_NOTARGET)) <> 0 Then Begin
      continue;
    End;

    If (player^.health <= 0) Then Begin
      continue; // dead
    End;

    If (Not P_CheckSight(actor, player^.mo)) Then Begin
      continue; // out of sight
    End;

    If (Not allaround) Then Begin
      an := angle_t(R_PointToAngle2(actor^.x,
        actor^.y,
        player^.mo^.x,
        player^.mo^.y)
        - actor^.angle);

      If (an > ANG90) And (an < ANG270) Then Begin
        dist := P_AproxDistance(player^.mo^.x - actor^.x,
          player^.mo^.y - actor^.y);
        // if real close, react anyway
        If (dist > MELEERANGE) Then Begin
          actor^.lastlook := (actor^.lastlook + 1) And 3;
          continue; // behind back
        End;
      End;
    End;
    actor^.target := player^.mo;
    result := true;
    exit;
  Until actor^.lastlook = 0;

  result := false;
End;

//
// A_Look
// Stay in state until a player is sighted.
//

Procedure A_Look(actor: Pmobj_t);
Label
  seeyou;
Var
  targ: ^mobj_t;
  sound: int;
Begin

  actor^.threshold := 0; // any shot will wake up
  targ := actor^.subsector^.sector^.soundtarget;

  // [crispy] monsters don't look for players with NOTARGET cheat
  If assigned(targ) And assigned(targ^.player) And ((targ^.player^.cheats And integer(CF_NOTARGET)) <> 0) Then
    exit;

  If assigned(targ)
    And ((targ^.flags And MF_SHOOTABLE) <> 0) Then Begin

    actor^.target := targ;

    If (actor^.flags And MF_AMBUSH) <> 0 Then Begin
      If (P_CheckSight(actor, actor^.target)) Then
        Goto seeyou;
    End
    Else
      Goto seeyou;
  End;
  If (Not P_LookForPlayers(actor, false)) Then
    exit;

  // go into chase state
  seeyou:
  If (actor^.info^.seesound <> sfx_None) Then Begin
    Case (actor^.info^.seesound) Of

      sfx_posit1,
        sfx_posit2,
        sfx_posit3: Begin
          sound := integer(sfx_posit1) + P_Random() Mod 3;
        End;

      sfx_bgsit1,
        sfx_bgsit2: Begin
          sound := integer(sfx_bgsit1) + P_Random() Mod 2;
        End;

    Else Begin
        sound := integer(actor^.info^.seesound);
      End;
    End;

    If (actor^._type = MT_SPIDER)
      Or (actor^._type = MT_CYBORG) Then Begin
      // full volume
      // [crispy] prevent from adding up volume
      If crispy.soundfull <> 0 Then Begin
        S_StartSoundOnce(Nil, sfxenum_t(sound));
      End
      Else Begin
        S_StartSound(Nil, sfxenum_t(sound));
      End;
    End
    Else
      S_StartSound(actor, sfxenum_t(sound));

    // [crispy] make seesounds uninterruptible
    If (crispy.soundfull <> 0) Then Begin
      S_UnlinkSound(actor);
    End;
  End;

  P_SetMobjState(actor, actor^.info^.seestate);
End;

//
// P_Move
// Move in the current direction,
// returns false if the move is blocked.
//

Function P_Move(actor: Pmobj_t): boolean;
Var
  tryx: fixed_t;
  tryy: fixed_t;

  ld: pline_t;

  // warning: 'catch', 'throw', and 'try'
  // are all C++ reserved words
  try_ok: boolean;
  good: boolean;
Begin
  result := false;
  If (actor^.movedir = integer(DI_NODIR)) Then exit;

  If (unsigned_int(actor^.movedir) >= 8) Then Begin
    I_Error('Weird actor^.movedir!');
  End;

  tryx := actor^.x + actor^.info^.speed * xspeed[actor^.movedir];
  tryy := actor^.y + actor^.info^.speed * yspeed[actor^.movedir];

  try_ok := P_TryMove(actor, tryx, tryy);

  If (Not try_ok) Then Begin

    // open any specials
    If ((actor^.flags And MF_FLOAT) <> 0) And (floatok) Then Begin
      // must adjust height
      If (actor^.z < tmfloorz) Then
        actor^.z := actor^.z + FLOATSPEED
      Else
        actor^.z := actor^.z - FLOATSPEED;

      actor^.flags := actor^.flags Or MF_INFLOAT;
      result := true;
      exit;
    End;

    If (numspechit = 0) Then exit;

    actor^.movedir := integer(DI_NODIR);
    good := false;

    Repeat
      ld := spechit[numspechit];
      // if the special is not a door
      // that can be opened,
      // return false
      If (P_UseSpecialLine(actor, ld, 0)) Then
        good := true;
      numspechit := numspechit - 1;
    Until numspechit = 0;
    result := good;
    exit;
  End
  Else Begin
    actor^.flags := actor^.flags And Not MF_INFLOAT;
  End;

  If ((actor^.flags And MF_FLOAT) = 0) Then
    actor^.z := actor^.floorz;
  result := true;
End;

//
// TryWalk
// Attempts to move actor on
// in its current (ob->moveangle) direction.
// If blocked by either a wall or an actor
// returns FALSE
// If move is either clear or blocked only by a door,
// returns TRUE and sets...
// If a door is in the way,
// an OpenDoor call is made to start it opening.
//

Function P_TryWalk(actor: Pmobj_t): boolean;
Begin
  If (Not P_Move(actor)) Then Begin

    result := false;
    exit;
  End;
  actor^.movecount := P_Random() And 15;
  result := true;
End;

Procedure P_NewChaseDir(actor: Pmobj_t);
Var
  deltax: fixed_t;
  deltay: fixed_t;

  d: Array[0..2] Of dirtype_t;

  tdir: int;
  olddir: dirtype_t;

  turnaround: dirtype_t;
Begin

  If (actor^.target = Nil) Then Begin
    I_Error('P_NewChaseDir: called with no target');
  End;

  olddir := dirtype_t(actor^.movedir);
  turnaround := opposite[integer(olddir)];

  deltax := actor^.target^.x - actor^.x;
  deltay := actor^.target^.y - actor^.y;

  If (deltax > 10 * FRACUNIT) Then
    d[1] := DI_EAST
  Else If (deltax < -10 * FRACUNIT) Then
    d[1] := DI_WEST
  Else
    d[1] := DI_NODIR;

  If (deltay < -10 * FRACUNIT) Then
    d[2] := DI_SOUTH
  Else If (deltay > 10 * FRACUNIT) Then
    d[2] := DI_NORTH
  Else
    d[2] := DI_NODIR;

  // try direct route
  If (d[1] <> DI_NODIR)
    And (d[2] <> DI_NODIR) Then Begin

    actor^.movedir := integer(diags[(ord(deltay < 0) Shl 1) + ord(deltax > 0)]);
    If (actor^.movedir <> integer(turnaround)) And (P_TryWalk(actor)) Then
      exit;
  End;

  // try other directions
  If (P_Random() > 200)
    Or (abs(deltay) > abs(deltax)) Then Begin
    tdir := integer(d[1]);
    d[1] := d[2];
    d[2] := dirtype_t(tdir);
  End;

  If (d[1] = turnaround) Then
    d[1] := DI_NODIR;
  If (d[2] = turnaround) Then
    d[2] := DI_NODIR;

  If (d[1] <> DI_NODIR) Then Begin
    actor^.movedir := integer(d[1]);
    If (P_TryWalk(actor)) Then Begin
      // either moved forward or attacked
      exit;
    End;
  End;

  If (d[2] <> DI_NODIR) Then Begin
    actor^.movedir := integer(d[2]);
    If (P_TryWalk(actor)) Then
      exit;
  End;

  // there is no direct path to the player,
  // so pick another direction.
  If (olddir <> DI_NODIR) Then Begin

    actor^.movedir := integer(olddir);

    If (P_TryWalk(actor)) Then
      exit;
  End;

  // randomly determine direction of search
  If (P_Random() And 1) <> 0 Then Begin
    For tdir := integer(DI_EAST) To integer(DI_SOUTHEAST) Do Begin
      If (tdir <> integer(turnaround)) Then Begin
        actor^.movedir := tdir;
        If (P_TryWalk(actor)) Then exit;
      End;
    End;
  End
  Else Begin
    tdir := integer(DI_SOUTHEAST);
    While tdir <> (integer(DI_EAST) - 1) Do Begin
      If (tdir <> integer(turnaround)) Then Begin
        actor^.movedir := tdir;
        If (P_TryWalk(actor)) Then exit;
      End;
      tdir := tdir - 1;
    End;
  End;

  If (turnaround <> DI_NODIR) Then Begin
    actor^.movedir := integer(turnaround);
    If (P_TryWalk(actor)) Then exit;
  End;

  actor^.movedir := integer(DI_NODIR); // can not move
End;

//
// P_CheckMeleeRange
//

Function P_CheckMeleeRange(actor: Pmobj_t): boolean;
Var
  pl: Pmobj_t;
  dist: fixed_t;
  range: fixed_t;
Begin
  result := false;
  If (actor^.target = Nil) Then exit;

  pl := actor^.target;
  dist := P_AproxDistance(pl^.x - actor^.x, pl^.y - actor^.y);

  If (gameversion < exe_doom_1_5) Then
    range := MELEERANGE
  Else
    range := MELEERANGE - 20 * FRACUNIT + pl^.info^.radius;

  If (dist >= range) Then exit;

  If (Not P_CheckSight(actor, actor^.target)) Then exit;

  // [crispy] height check for melee attacks
  If (critical^.overunder <> 0) And assigned(pl^.player) Then Begin
    If (pl^.z >= actor^.z + actor^.height) Or (
      actor^.z >= pl^.z + pl^.height) Then Begin
      exit;
    End;
  End;
  result := true;
End;

//
// P_CheckMissileRange
//

Function P_CheckMissileRange(actor: Pmobj_t): boolean;
Var
  dist: fixed_t;
Begin
  result := false;
  If (Not P_CheckSight(actor, actor^.target)) Then exit;

  If (actor^.flags And MF_JUSTHIT) <> 0 Then Begin
    // the target just hit the enemy,
    // so fight back!
    actor^.flags := actor^.flags And Not MF_JUSTHIT;
    result := true;
  End;

  If (actor^.reactiontime <> 0) Then
    exit; // do not attack yet

  // OPTIMIZE: get this from a global checksight
  dist := P_AproxDistance(actor^.x - actor^.target^.x,
    actor^.y - actor^.target^.y) - 64 * FRACUNIT;

  If (actor^.info^.meleestate = S_NULL) Then
    dist := dist - 128 * FRACUNIT; // no melee attack, so fire more

  dist := dist Shr FRACBITS;

  // [crispy] generalization of the Arch Vile's different attack range
  If (actor^.info^.maxattackrange > 0) Then Begin
    If (dist > actor^.info^.maxattackrange) Then
      exit; // too far away
  End;

  // [crispy] generalization of the Revenant's different melee threshold
  If (actor^.info^.meleethreshold > 0) Then Begin
    If (dist < actor^.info^.meleethreshold) Then
      exit; // close for fist attack
  End;

  // [crispy] generalize missile chance for Cyb, Spider, Revenant & Lost Soul
  If (actor^.info^.missilechancemult <> FRACUNIT) Then Begin
    dist := FixedMul(dist, actor^.info^.missilechancemult);
  End;

  // [crispy] generalization of Min Missile Chance values hardcoded in vanilla
  If (dist > actor^.info^.minmissilechance) Then
    dist := actor^.info^.minmissilechance;

  If (P_Random() < dist) Then exit;

  result := true;
End;

//
// A_Chase
// Actor has a melee attack,
// so it tries to close as fast as possible
//

Procedure A_Chase(actor: Pmobj_t);
Label
  nomissile;
Var
  delta: int;
Begin

  If (actor^.reactiontime <> 0) Then
    actor^.reactiontime := actor^.reactiontime - 1;

  // modify target threshold
  If (actor^.threshold <> 0) Then Begin
    If (gameversion > exe_doom_1_2) And
      (((actor^.target = Nil) Or (actor^.target^.health <= 0))) Then Begin
      actor^.threshold := 0;
    End
    Else
      actor^.threshold := actor^.threshold - 1;
  End;

  // turn towards movement direction if not there yet
  If (actor^.movedir < 8) Then Begin

    actor^.angle := actor^.angle And (7 Shl 29);
    delta := Integer(actor^.angle - (actor^.movedir Shl 29));

    If (delta > 0) Then
      actor^.angle := angle_t(actor^.angle - ANG90 Div 2)
    Else If (delta < 0) Then
      actor^.angle := angle_t(actor^.angle + ANG90 Div 2);
  End;

  If (actor^.target = Nil)
    Or ((actor^.target^.flags And MF_SHOOTABLE) = 0) Then Begin
    // look for a new target
    If (P_LookForPlayers(actor, true)) Then exit; // got a new target

    P_SetMobjState(actor, actor^.info^.spawnstate);
    exit;
  End;

  // do not attack twice in a row
  If (actor^.flags And MF_JUSTATTACKED) <> 0 Then Begin

    actor^.flags := actor^.flags And Not MF_JUSTATTACKED;
    If (gameskill <> sk_nightmare) And (Not fastparm) Then
      P_NewChaseDir(actor);
    exit;
  End;

  // check for melee attack
  If (actor^.info^.meleestate <> S_NULL)
    And (P_CheckMeleeRange(actor)) Then Begin

    If (actor^.info^.attacksound <> sfx_None) Then
      S_StartSound(actor, actor^.info^.attacksound);

    P_SetMobjState(actor, actor^.info^.meleestate);
    exit;
  End;

  // check for missile attack
  If (actor^.info^.missilestate <> S_NULL) Then Begin
    If (gameskill < sk_nightmare)
      And (Not fastparm) And (actor^.movecount <> 0) Then Begin
      Goto nomissile;
    End;

    If (Not P_CheckMissileRange(actor)) Then
      Goto nomissile;

    P_SetMobjState(actor, actor^.info^.missilestate);
    actor^.flags := actor^.flags Or MF_JUSTATTACKED;
    exit;
  End;

  // ?
  nomissile:
  // possibly choose another target
  If netgame
    And (actor^.threshold = 0)
    And (Not P_CheckSight(actor, actor^.target)) Then Begin
    If (P_LookForPlayers(actor, true)) Then
      exit; // got a new target
  End;

  // chase towards player
  actor^.movecount := actor^.movecount - 1;
  If (actor^.movecount < 0)
    Or (Not P_Move(actor)) Then Begin
    P_NewChaseDir(actor);
  End;

  // make active sound
  If (actor^.info^.activesound <> sfx_None)
    And (P_Random() < 3) Then Begin
    S_StartSound(actor, actor^.info^.activesound);
  End;
End;

Procedure A_FaceTarget(actor: Pmobj_t);
Begin
  If (actor^.target = Nil) Then exit;

  actor^.flags := actor^.flags And Not MF_AMBUSH;

  actor^.angle := R_PointToAngle2(actor^.x,
    actor^.y,
    actor^.target^.x,
    actor^.target^.y);

  If (actor^.target^.flags And MF_SHADOW) <> 0 Then
    actor^.angle := angle_t(actor^.angle + P_SubRandom() Shl 21);
End;

Procedure A_PosAttack(actor: Pmobj_t);
Var
  angle: int;
  damage: int;
  slope: int;
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);
  angle := int(actor^.angle);
  slope := P_AimLineAttack(actor, angle_t(angle), MISSILERANGE);

  S_StartSound(actor, sfx_pistol);
  angle := int(angle + P_SubRandom() Shl 20);
  damage := ((P_Random() Mod 5) + 1) * 3;
  P_LineAttack(actor, angle_t(angle), MISSILERANGE, slope, damage);
End;

Procedure A_SPosAttack(actor: Pmobj_t);
Var
  i: Int;
  angle: Int;
  bangle: Int;
  damage: Int;
  slope: Int;
Begin
  If (actor^.target = Nil) Then exit;

  S_StartSound(actor, sfx_shotgn);
  A_FaceTarget(actor);
  bangle := int(actor^.angle);
  slope := P_AimLineAttack(actor, angle_t(bangle), MISSILERANGE);

  For i := 0 To 2 Do Begin
    angle := int(bangle + (P_SubRandom() Shl 20));
    damage := ((P_Random() Mod 5) + 1) * 3;
    P_LineAttack(actor, angle_t(angle), MISSILERANGE, slope, damage);
  End;
End;

Procedure A_Scream(actor: Pmobj_t);
Var
  sound: int;
Begin
  Case (actor^.info^.deathsound) Of
    sfx_None: exit;
    sfx_podth1,
      sfx_podth2,
      sfx_podth3: Begin
        sound := integer(sfx_podth1) + P_Random() Mod 3;
      End;

    sfx_bgdth1,
      sfx_bgdth2: Begin
        sound := integer(sfx_bgdth1) + P_Random() Mod 2;
      End;
  Else Begin
      sound := integer(actor^.info^.deathsound);
    End;
  End;

  // Check for bosses.
  If (actor^._type = MT_SPIDER)
    Or (actor^._type = MT_CYBORG) Then Begin
    // full volume
    // [crispy] prevent from adding up volume
    If crispy.soundfull <> 0 Then Begin
      S_StartSoundOnce(Nil, sfxenum_t(sound));
    End
    Else Begin
      S_StartSound(Nil, sfxenum_t(sound));
    End;
  End
  Else
    S_StartSound(actor, sfxenum_t(sound));
End;

Function PIT_VileCheck(thing: Pmobj_t): boolean;
Var
  maxdist: int;
  check: boolean;
Begin

  If ((thing^.flags And MF_CORPSE) = 0) Then Begin
    result := true; // not a monster
    exit;
  End;

  If (thing^.tics <> -1) Then Begin
    result := true; // not lying still yet
    exit;
  End;

  If (thing^.info^.raisestate = S_NULL) Then Begin
    result := true; // monster doesn't have a raise state
    exit;
  End;

  maxdist := thing^.info^.radius + mobjinfo[int(MT_VILE)].radius;

  If (abs(thing^.x - viletryx) > maxdist)
    Or (abs(thing^.y - viletryy) > maxdist) Then Begin
    result := true; // not actually touching
    exit;
  End;

  corpsehit := thing;
  corpsehit^.momx := 0;
  corpsehit^.momy := 0;
  corpsehit^.height := corpsehit^.height Shl 2;
  check := P_CheckPosition(corpsehit, corpsehit^.x, corpsehit^.y);
  corpsehit^.height := corpsehit^.height Shr 2;

  If (Not check) Then Begin
    result := true; // doesn't fit here
    exit;
  End;
  result := false; // got one, so stop checking
End;

//
// A_VileChase
// Check for ressurecting a body
//

Procedure A_VileChase(actor: Pmobj_t);
Var
  xl: int;
  xh: int;
  yl: int;
  yh: int;

  bx: int;
  by: int;

  info: Pmobjinfo_t;
  temp: Pmobj_t;
Begin

  If (actor^.movedir <> int(DI_NODIR)) Then Begin

    // check for corpses to raise
    viletryx := actor^.x + actor^.info^.speed * xspeed[actor^.movedir];
    viletryy := actor^.y + actor^.info^.speed * yspeed[actor^.movedir];

    xl := SarLongint(viletryx - bmaporgx - MAXRADIUS * 2, MAPBLOCKSHIFT);
    xh := SarLongint(viletryx - bmaporgx + MAXRADIUS * 2, MAPBLOCKSHIFT);
    yl := SarLongint(viletryy - bmaporgy - MAXRADIUS * 2, MAPBLOCKSHIFT);
    yh := SarLongint(viletryy - bmaporgy + MAXRADIUS * 2, MAPBLOCKSHIFT);

    vileobj := actor;
    For bx := xl To xh Do Begin
      For by := yl To yh Do Begin
        // Call PIT_VileCheck to check
        // whether object is a corpse
        // that canbe raised.
        If (Not P_BlockThingsIterator(bx, by, @PIT_VileCheck)) Then Begin

          // got one!
          temp := actor^.target;
          actor^.target := corpsehit;
          A_FaceTarget(actor);
          actor^.target := temp;

          P_SetMobjState(actor, S_VILE_HEAL1);
          S_StartSound(corpsehit, sfx_slop);
          info := corpsehit^.info;

          P_SetMobjState(corpsehit, info^.raisestate);
          corpsehit^.height := corpsehit^.height Shl 2;
          corpsehit^.flags := info^.flags;
          corpsehit^.health := info^.spawnhealth;
          corpsehit^.target := Nil;

          // [crispy] count resurrected monsters
          extrakills := extrakills + 1;

          // [crispy] resurrected pools of gore ("ghost monsters") are translucent
          If (corpsehit^.height = 0) And (corpsehit^.radius = 0) Then Begin
            corpsehit^.flags := corpsehit^.flags Or MF_TRANSLUCENT;
            writeln(stderr, format('A_VileChase: Resurrected ghost monster (%d) at (%d/%d)!',
              [corpsehit^._type, SarLongint(corpsehit^.x, FRACBITS), SarLongint(corpsehit^.y, FRACBITS)]));
          End;
          exit;
        End;
      End;
    End;
  End;

  // Return to normal attack.
  A_Chase(actor);
End;

Procedure A_VileStart(actor: Pmobj_t);
Begin
  S_StartSound(actor, sfx_vilatk);
End;

//
// A_VileTarget
// Spawn the hellfire
//

Procedure A_VileTarget(actor: Pmobj_t);
Var
  fog: Pmobj_t;
Begin
  If (actor^.target = Nil) Then exit;
  A_FaceTarget(actor);

  fog := P_SpawnMobj(actor^.target^.x,
    actor^.target^.x,
    actor^.target^.z, MT_FIRE);

  actor^.tracer := fog;
  fog^.target := actor;
  fog^.tracer := actor^.target;
  // [crispy] play DSFLAMST sound when Arch-Vile spawns fire attack
  If (crispy.soundfix <> 0) And (I_GetSfxLumpNum(@S_sfx[int(sfx_flamst)]) <> -1) Then Begin

    S_StartSound(fog, sfx_flamst);
    // [crispy] make DSFLAMST sound uninterruptible
    If (crispy.soundfull <> 0) Then Begin
      S_UnlinkSound(fog);
    End;
  End;

  A_Fire(fog);
End;

Procedure A_VileAttack(actor: Pmobj_t);
Var
  fire: Pmobj_t;
  an: int;
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);

  If (Not P_CheckSight(actor, actor^.target)) Then exit;

  S_StartSound(actor, sfx_barexp);
  P_DamageMobj(actor^.target, actor, actor, 20);
  actor^.target^.momz := 1000 * FRACUNIT Div actor^.target^.info^.mass;

  an := actor^.angle Shr ANGLETOFINESHIFT;

  fire := actor^.tracer;

  If (fire = Nil) Then exit;

  // move the fire between the vile and the player
  fire^.x := actor^.target^.x - FixedMul(24 * FRACUNIT, finecosine[an]);
  fire^.y := actor^.target^.y - FixedMul(24 * FRACUNIT, finesine[an]);
  P_RadiusAttack(fire, actor, 70);
End;

Procedure A_StartFire(actor: Pmobj_t);
Begin
  S_StartSound(actor, sfx_flamst);
  A_Fire(actor);
End;

Procedure A_Fire(actor: Pmobj_t);
Var
  dest: Pmobj_t;
  target: pmobj_t;
  an: unsigned;
Begin
  dest := actor^.tracer;
  If (dest = Nil) Then exit;

  target := P_SubstNullMobj(actor^.target);

  // don't move it if the vile lost sight
  If (Not P_CheckSight(target, dest)) Then exit;


  an := dest^.angle Shr ANGLETOFINESHIFT;

  P_UnsetThingPosition(actor);
  actor^.x := dest^.x + FixedMul(24 * FRACUNIT, finecosine[an]);
  actor^.y := dest^.y + FixedMul(24 * FRACUNIT, finesine[an]);
  actor^.z := dest^.z;
  P_SetThingPosition(actor);

  // [crispy] suppress interpolation of Archvile fire
  // to mitigate it being spawned at the wrong location
  actor^.interp := -actor^.tics;
End;

Procedure A_FireCrackle(actor: Pmobj_t);
Begin
  S_StartSound(actor, sfx_flame);
  A_Fire(actor);
End;

Const
  TRACEANGLE: int = $C000000;

Procedure A_Tracer(actor: Pmobj_t);
Var
  exact: angle_t;
  dist: fixed_t;
  slope: fixed_t;
  dest: Pmobj_t;
  th: Pmobj_t;
Begin
  If ((gametic - demostarttic) And 3) <> 0 Then exit; // [crispy] fix revenant internal demo bug


  // spawn a puff of smoke behind the rocket
  P_SpawnPuff(actor^.x, actor^.y, actor^.z);

  th := P_SpawnMobj(actor^.x - actor^.momx,
    actor^.y - actor^.momy,
    actor^.z, MT_SMOKE);

  th^.momz := FRACUNIT;
  th^.tics := th^.tics - P_Random() And 3;
  If (th^.tics < 1) Then
    th^.tics := 1;

  // adjust direction
  dest := actor^.tracer;

  If (dest = Nil) Or (dest^.health <= 0) Then exit;

  // change angle
  exact := R_PointToAngle2(actor^.x,
    actor^.y,
    dest^.x,
    dest^.y);

  If (exact <> actor^.angle) Then Begin
    If (angle_t(exact - actor^.angle) > $80000000) Then Begin

      actor^.angle := angle_t(actor^.angle - TRACEANGLE);
      If (angle_t(exact - actor^.angle) < $80000000) Then
        actor^.angle := exact;
    End
    Else Begin
      actor^.angle := angle_t(actor^.angle + TRACEANGLE);
      If (angle_t(exact - actor^.angle) > $80000000) Then
        actor^.angle := exact;
    End;
  End;

  exact := actor^.angle Shr ANGLETOFINESHIFT;
  actor^.momx := FixedMul(actor^.info^.speed, finecosine[exact]);
  actor^.momy := FixedMul(actor^.info^.speed, finesine[exact]);

  // change slope
  dist := P_AproxDistance(dest^.x - actor^.x,
    dest^.y - actor^.y);

  dist := dist Div actor^.info^.speed;

  If (dist < 1) Then
    dist := 1;
  slope := (dest^.z + 40 * FRACUNIT - actor^.z) Div dist;

  If (slope < actor^.momz) Then
    actor^.momz := actor^.momz - FRACUNIT Div 8
  Else
    actor^.momz := actor^.momz + FRACUNIT Div 8;
End;

Procedure A_SkelWhoosh(actor: Pmobj_t);
Begin
  If Not assigned(actor^.target) Then exit;
  A_FaceTarget(actor);
  S_StartSound(actor, sfx_skeswg);
End;

Procedure A_SkelFist(actor: Pmobj_t);
Var
  damage: int;
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);

  If (P_CheckMeleeRange(actor)) Then Begin
    damage := ((P_Random() Mod 10) + 1) * 6;
    S_StartSound(actor, sfx_skepch);
    P_DamageMobj(actor^.target, actor, actor, damage);
  End;
End;

Procedure A_SkelMissile(actor: Pmobj_t);
Var
  mo: Pmobj_t;
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);
  actor^.z := actor^.z + 16 * FRACUNIT; // so missile spawns higher
  mo := P_SpawnMissile(actor, actor^.target, MT_TRACER);
  actor^.z := actor^.z - 16 * FRACUNIT; // back to normal

  mo^.x := mo^.x + mo^.momx;
  mo^.y := mo^.y + mo^.momy;
  mo^.tracer := actor^.target;
End;

//
// Mancubus attack,
// firing three missiles (bruisers)
// in three different directions?
// Doesn't look like it.
//
Const
  FATSPREAD = (ANG90 Div 8);

Procedure A_FatRaise(actor: Pmobj_t);
Begin
  A_FaceTarget(actor);
  S_StartSound(actor, sfx_manatk);
End;

Procedure A_FatAttack1(actor: Pmobj_t);
Var
  mo: Pmobj_t;
  target: Pmobj_t;
  an: int;
Begin
  A_FaceTarget(actor);

  // Change direction  to ...
  actor^.angle := angle_t(actor^.angle + FATSPREAD);
  target := P_SubstNullMobj(actor^.target);
  P_SpawnMissile(actor, target, MT_FATSHOT);

  mo := P_SpawnMissile(actor, target, MT_FATSHOT);
  mo^.angle := angle_t(mo^.angle + FATSPREAD);
  an := mo^.angle Shr ANGLETOFINESHIFT;
  mo^.momx := FixedMul(mo^.info^.speed, finecosine[an]);
  mo^.momy := FixedMul(mo^.info^.speed, finesine[an]);
End;

Procedure A_FatAttack2(actor: Pmobj_t);
Var
  mo: Pmobj_t;
  target: Pmobj_t;
  an: int;
Begin
  A_FaceTarget(actor);
  // Now here choose opposite deviation.
  actor^.angle := angle_t(actor^.angle - FATSPREAD);
  target := P_SubstNullMobj(actor^.target);
  P_SpawnMissile(actor, target, MT_FATSHOT);

  mo := P_SpawnMissile(actor, target, MT_FATSHOT);
  mo^.angle := angle_t(mo^.angle - FATSPREAD * 2);
  an := mo^.angle Shr ANGLETOFINESHIFT;
  mo^.momx := FixedMul(mo^.info^.speed, finecosine[an]);
  mo^.momy := FixedMul(mo^.info^.speed, finesine[an]);
End;

Procedure A_FatAttack3(actor: Pmobj_t);
Var
  mo: Pmobj_t;
  target: Pmobj_t;
  an: int;
Begin
  A_FaceTarget(actor);

  target := P_SubstNullMobj(actor^.target);

  mo := P_SpawnMissile(actor, target, MT_FATSHOT);
  mo^.angle := angle_t(mo^.angle - FATSPREAD Div 2);
  an := mo^.angle Shr ANGLETOFINESHIFT;
  mo^.momx := FixedMul(mo^.info^.speed, finecosine[an]);
  mo^.momy := FixedMul(mo^.info^.speed, finesine[an]);

  mo := P_SpawnMissile(actor, target, MT_FATSHOT);
  mo^.angle := angle_t(mo^.angle + FATSPREAD Div 2);
  an := mo^.angle Shr ANGLETOFINESHIFT;
  mo^.momx := FixedMul(mo^.info^.speed, finecosine[an]);
  mo^.momy := FixedMul(mo^.info^.speed, finesine[an]);
End;


// Check whether the death of the specified monster type is allowed
// to trigger the end of episode special action.
//
// This behavior changed in v1.9, the most notable effect of which
// was to break uac_dead.wad

Function CheckBossEnd(motype: mobjtype_t): Boolean;
Begin
  result := false;
  If (gameversion < exe_ultimate) Then Begin

    If (gamemap <> 8) Then Begin
      exit;
    End;

    // Baron death on later episodes is nothing special.

    If (motype = MT_BRUISER) And (gameepisode <> 1) Then Begin
      exit;
    End;
    result := true;
    exit;
  End
  Else Begin
    // New logic that appeared in Ultimate Doom.
    // Looks like the logic was overhauled while adding in the
    // episode 4 support.  Now bosses only trigger on their
    // specific episode.

    Case (gameepisode) Of
      1: result := (gamemap = 8) And (motype = MT_BRUISER);
      2: result := (gamemap = 8) And (motype = MT_CYBORG);
      3: result := (gamemap = 8) And (motype = MT_SPIDER);
      4: result := ((gamemap = 6) And (motype = MT_CYBORG))
        Or ((gamemap = 8) And (motype = MT_SPIDER));
      // [crispy] no trigger for auto-loaded Sigil E5
      5: result := (gamemap = 8) And (critical^.havesigil <> '');
      // [crispy] no trigger for auto-loaded Sigil II E6
      6: result := (gamemap = 8) And (critical^.havesigil2 <> '');
    Else
      result := gamemap = 8;
    End;
  End;
End;

//
// A_BossDeath
// Possibly trigger special effects
// if on first boss level
//

Procedure A_BossDeath(mo: Pmobj_t);
Var
  th: Pthinker_t;
  mo2: Pmobj_t;
  junk: line_t;
  i, j: int;
Begin

  If (gamemode = commercial) Then Begin
    If (gamemap <> 7) And
      // [crispy] Master Levels in PC slot 7
    (Not ((gamemission = pack_master) And ((gamemap = 14) Or (gamemap = 15) Or (gamemap = 16)))) Then
      exit;
    If ((mo^._type <> MT_FATSO)) And
      ((mo^._type <> MT_BABY)) Then exit;
  End
  Else Begin
    If (Not CheckBossEnd(mo^._type)) Then exit;
  End;

  // make sure there is a player alive for victory
  j := -1;
  For i := 0 To MAXPLAYERS - 1 Do Begin
    If (playeringame[i]) And (players[i].health > 0) Then Begin
      j := i;
      break;
    End;
  End;
  If (j = -1) Then exit; // no one left alive, so do not end game

  // scan the remaining thinkers to see
  // if all bosses are dead
  th := thinkercap.next;
  While (th <> @thinkercap) Do Begin
    If (th^._function.acp1 <> @P_MobjThinker) Then Begin
      th := th^.next;
      continue;
    End;
    mo2 := pmobj_t(th);
    If (mo2 <> mo)
      And (mo2^._type = mo^._type)
      And (mo2^.health > 0) Then Begin
      // other boss not dead
      exit;
    End;
    th := th^.next;
  End;

  // victory!
  If (gamemode = commercial) Then Begin
    If (gamemap = 7) Or
      // [crispy] Master Levels in PC slot 7
    ((gamemission = pack_master) And ((gamemap = 14) Or (gamemap = 15) Or (gamemap = 16))) Then Begin

      If (mo^._type = MT_FATSO) Then Begin
        junk.tag := 666;
        EV_DoFloor(@junk, lowerFloorToLowest);
        exit;
      End;

      If (mo^._type = MT_BABY) Then Begin
        junk.tag := 667;
        EV_DoFloor(@junk, raiseToTexture);
        exit;
      End;
    End;
  End
  Else Begin
    Case (gameepisode) Of
      1: Begin
          junk.tag := 666;
          EV_DoFloor(@junk, lowerFloorToLowest);
          exit;
        End;
      4: Begin
          Case (gamemap) Of
            6: Begin
                junk.tag := 666;
                EV_DoDoor(@junk, vld_blazeOpen);
                exit;
              End;
            8: Begin
                junk.tag := 666;
                EV_DoFloor(@junk, lowerFloorToLowest);
                exit;
              End;
          End;
        End;
    End;
  End;
  G_ExitLevel();
End;

Procedure A_CPosAttack(actor: Pmobj_t);
Var
  angle: int;
  bangle: int;
  damage: int;
  slope: int;
Begin
  If (actor^.target = Nil) Then exit;

  S_StartSound(actor, sfx_shotgn);
  A_FaceTarget(actor);
  bangle := int(actor^.angle);
  slope := P_AimLineAttack(actor, angle_t(bangle), MISSILERANGE);

  angle := int(bangle + (P_SubRandom() Shl 20));
  damage := ((P_Random() Mod 5) + 1) * 3;
  P_LineAttack(actor, angle_t(angle), MISSILERANGE, slope, damage);
End;

Procedure A_CPosRefire(actor: Pmobj_t);
Begin
  // keep firing unless target got out of sight
  A_FaceTarget(actor);

  If (P_Random() < 40) Then exit;

  If (actor^.target = Nil)
    Or (actor^.target^.health <= 0)
    Or (Not P_CheckSight(actor, actor^.target)) Then Begin
    P_SetMobjState(actor, actor^.info^.seestate);
  End;
End;

Procedure A_TroopAttack(actor: Pmobj_t);
Var
  damage: int;
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);
  If (P_CheckMeleeRange(actor)) Then Begin
    S_StartSound(actor, sfx_claw);
    damage := (P_Random() Mod 8 + 1) * 3;
    P_DamageMobj(actor^.target, actor, actor, damage);
    exit;
  End;

  // launch a missile
  P_SpawnMissile(actor, actor^.target, MT_TROOPSHOT);
End;

Procedure A_SargAttack(actor: Pmobj_t);
Var
  damage: int;
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);

  If (gameversion >= exe_doom_1_5) Then Begin
    If (Not P_CheckMeleeRange(actor)) Then exit;
  End;

  damage := ((P_Random() Mod 10) + 1) * 4;

  If (gameversion <= exe_doom_1_2) Then
    P_LineAttack(actor, actor^.angle, MELEERANGE, 0, damage)
  Else
    P_DamageMobj(actor^.target, actor, actor, damage);
End;

Procedure A_HeadAttack(actor: Pmobj_t);
Var
  damage: int;
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);
  If (P_CheckMeleeRange(actor)) Then Begin
    damage := (P_Random() Mod 6 + 1) * 10;
    P_DamageMobj(actor^.target, actor, actor, damage);
    exit;
  End;

  // launch a missile
  P_SpawnMissile(actor, actor^.target, MT_HEADSHOT);
End;

Procedure A_BruisAttack(actor: Pmobj_t);
Var
  damage: int;
Begin
  If (actor^.target = Nil) Then exit;

  // [crispy] face the enemy
//  A_FaceTarget (actor);
  If (P_CheckMeleeRange(actor)) Then Begin

    S_StartSound(actor, sfx_claw);
    damage := (P_Random() Mod 8 + 1) * 10;
    P_DamageMobj(actor^.target, actor, actor, damage);
    exit;
  End;

  // launch a missile
  P_SpawnMissile(actor, actor^.target, MT_BRUISERSHOT);
End;

//
// SkullAttack
// Fly at the player like a missile.
//
Const
  SKULLSPEED = (20 * FRACUNIT);

Procedure A_SkullAttack(actor: Pmobj_t);
Var
  dest: Pmobj_t;
  an: angle_t;
  dist: int;
Begin
  If (actor^.target = Nil) Then exit;

  dest := actor^.target;
  actor^.flags := actor^.flags Or MF_SKULLFLY;

  S_StartSound(actor, actor^.info^.attacksound);
  A_FaceTarget(actor);
  an := actor^.angle Shr ANGLETOFINESHIFT;
  actor^.momx := FixedMul(SKULLSPEED, finecosine[an]);
  actor^.momy := FixedMul(SKULLSPEED, finesine[an]);
  dist := P_AproxDistance(dest^.x - actor^.x, dest^.y - actor^.y);
  dist := dist Div SKULLSPEED;

  If (dist < 1) Then
    dist := 1;
  actor^.momz := (dest^.z + (dest^.height Shr 1) - actor^.z) Div dist;
End;

Procedure A_Metal(mo: Pmobj_t);
Begin
  S_StartSound(mo, sfx_metal);
  A_Chase(mo);
End;

Procedure A_BabyMetal(mo: Pmobj_t);
Begin
  S_StartSound(mo, sfx_bspwlk);
  A_Chase(mo);
End;

Procedure A_SpidRefire(actor: Pmobj_t);
Begin
  // keep firing unless target got out of sight
  A_FaceTarget(actor);

  If (P_Random() < 10) Then exit;

  If (actor^.target = Nil)
    Or (actor^.target^.health <= 0)
    Or (Not P_CheckSight(actor, actor^.target)) Then Begin
    P_SetMobjState(actor, actor^.info^.seestate);
  End;
End;

Procedure A_BspiAttack(actor: Pmobj_t);
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);

  // launch a missile
  P_SpawnMissile(actor, actor^.target, MT_ARACHPLAZ);
End;

Procedure A_Hoof(mo: Pmobj_t);
Begin
  S_StartSound(mo, sfx_hoof);
  A_Chase(mo);
End;

Procedure A_CyberAttack(actor: Pmobj_t);
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);
  P_SpawnMissile(actor, actor^.target, MT_ROCKET);
End;

//
// A_PainShootSkull
// Spawn a lost soul and launch it at the target
//

Procedure A_PainShootSkull(actor: Pmobj_t; angle: angle_t);
Var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  newmobj: Pmobj_t;
  an: angle_t;
  prestep, count: int;
  currentthinker: Pthinker_t;
Begin
  // count total number of skull currently on the level
  count := 0;

  currentthinker := thinkercap.next;
  While (currentthinker <> @thinkercap) Do Begin
    If ((currentthinker^._function.acp1 = @P_MobjThinker)
      And (pmobj_t(currentthinker)^._type = MT_SKULL)) Then
      count := count + 1;
    currentthinker := currentthinker^.next;
  End;

  // if there are allready 20 skulls on the level,
  // don't spit another one
  If (count > 20) Then exit;

  // okay, there's playe for another one
  an := angle Shr ANGLETOFINESHIFT;

  prestep :=
    4 * FRACUNIT
    + 3 * (actor^.info^.radius + mobjinfo[int(MT_SKULL)].radius) Div 2;

  x := actor^.x + FixedMul(prestep, finecosine[an]);
  y := actor^.y + FixedMul(prestep, finesine[an]);
  z := actor^.z + 8 * FRACUNIT;

  newmobj := P_SpawnMobj(x, y, z, MT_SKULL);

  // Check for movements.
  If (Not P_TryMove(newmobj, newmobj^.x, newmobj^.y)) Then Begin
    // kill it immediately
    P_DamageMobj(newmobj, actor, actor, 10000);
    exit;
  End;

  // [crispy] Lost Souls bleed Puffs
  If (crispy.coloredblood = COLOREDBLOOD_ALL) Then
    newmobj^.flags := newmobj^.flags Or MF_NOBLOOD;

  newmobj^.target := actor^.target;
  A_SkullAttack(newmobj);
End;

//
// A_PainAttack
// Spawn a lost soul and launch it at the target
//

Procedure A_PainAttack(actor: Pmobj_t);
Begin
  If (actor^.target = Nil) Then exit;

  A_FaceTarget(actor);
  A_PainShootSkull(actor, actor^.angle);
End;

Procedure A_PainDie(actor: Pmobj_t);
Begin
  A_Fall(actor);
  A_PainShootSkull(actor, angle_t(actor^.angle + ANG90));
  A_PainShootSkull(actor, angle_t(actor^.angle + ANG180));
  A_PainShootSkull(actor, angle_t(actor^.angle + ANG270));
End;

//
// A_KeenDie
// DOOM II special, map 32.
// Uses special tag 666.
//

Procedure A_KeenDie(mo: Pmobj_t);
Var
  th: Pthinker_t;
  mo2: Pmobj_t;
  junk: line_t;
Begin
  A_Fall(mo);
  // scan the remaining thinkers
  // to see if all Keens are dead
  th := thinkercap.next;
  While th <> @thinkercap Do Begin

    If (th^._function.acp1 <> @P_MobjThinker) Then Begin
      th := th^.next;
      continue;
    End;
    mo2 := pmobj_t(th);
    If (mo2 <> mo)
      And (mo2^._type = mo^._type)
      And (mo2^.health > 0) Then Begin
      // other Keen not dead
      exit;
    End;
    th := th^.next;
  End;

  junk.tag := 666;
  EV_DoDoor(@junk, vld_open);
End;

Procedure A_BrainPain(mo: Pmobj_t);
Begin
  // [crispy] prevent from adding up volume
  If crispy.soundfull <> 0 Then Begin
    S_StartSoundOnce(Nil, sfx_bospn);
  End
  Else Begin
    S_StartSound(Nil, sfx_bospn);
  End;
End;

Procedure A_BrainScream(mo: Pmobj_t);
Var
  x, y, z: int;
  th: Pmobj_t;
Begin
  x := mo^.x - 196 * FRACUNIT;
  While x < mo^.x + 320 * FRACUNIT Do Begin
    y := mo^.y - 320 * FRACUNIT;
    z := 128 + P_Random() * 2 * FRACUNIT;
    th := P_SpawnMobj(x, y, z, MT_ROCKET);
    th^.momz := P_Random() * 512;

    P_SetMobjState(th, S_BRAINEXPLODE1);

    th^.tics := th^.tics - P_Random() And 7;
    If (th^.tics < 1) Then
      th^.tics := 1;
    x := x + FRACUNIT * 8;
  End;
  S_StartSound(Nil, sfx_bosdth);
End;

Procedure A_BrainDie(mo: Pmobj_t);
Begin
  G_ExitLevel();
End;

Procedure A_BrainAwake(mo: Pmobj_t);
Var
  thinker: Pthinker_t;
  m: Pmobj_t;
Begin
  // find all the target spots
  numbraintargets := 0;
  braintargeton := 0;
  thinker := thinkercap.next;
  While thinker <> @thinkercap Do Begin
    If (thinker^._function.acp1 <> @P_MobjThinker) Then Begin
      thinker := thinker^.next;
      continue; // not a mobj
    End;

    m := pmobj_t(thinker);

    If (m^._type = MT_BOSSTARGET) Then Begin
      // [crispy] remove braintargets limit
      If (numbraintargets = maxbraintargets) Then Begin
        If maxbraintargets <> 0 Then Begin
          maxbraintargets := 2 * maxbraintargets;
        End
        Else Begin
          maxbraintargets := 32;
        End;
        setlength(braintargets, maxbraintargets);
        If (maxbraintargets > 32) Then
          writeln(stderr, format('R_BrainAwake: Raised braintargets limit to %d.', [maxbraintargets]));
      End;
      braintargets[numbraintargets] := m;
      numbraintargets := numbraintargets + 1;
    End;
    thinker := thinker^.next;
  End;

  S_StartSound(Nil, sfx_bossit);

  // [crispy] prevent braintarget overflow
  // (e.g. in two subsequent maps featuring a brain spitter)
  If (braintargeton >= numbraintargets) Then Begin
    braintargeton := 0;
  End;

  // [crispy] no spawn spots available
  If (numbraintargets = 0) Then numbraintargets := -1;
End;

Procedure A_BrainSpit(mo: Pmobj_t);
Const
  easy: int = 0;
Var
  targ, newmobj: Pmobj_t;
Begin

  easy := easy Xor 1;
  If (gameskill <= sk_easy) And (easy = 0) Then exit;

  // [crispy] avoid division by zero by recalculating the number of spawn spots
  If (numbraintargets = 0) Then
    A_BrainAwake(Nil);

  // [crispy] still no spawn spots available
  If (numbraintargets = -1) Then exit;


  // shoot a cube at current target
  targ := braintargets[braintargeton];
  If (numbraintargets = 0) Then Begin
    I_Error('A_BrainSpit: numbraintargets was 0 (vanilla crashes here)');
  End;
  braintargeton := (braintargeton + 1) Mod numbraintargets;

  // spawn brain missile
  newmobj := P_SpawnMissile(mo, targ, MT_SPAWNSHOT);
  newmobj^.target := targ;
  newmobj^.reactiontime := ((targ^.y - mo^.y) Div newmobj^.momy) Div newmobj^.state^.tics;

  S_StartSound(Nil, sfx_bospit);
End;

Procedure A_BrainExplode(mo: Pmobj_t);
Var
  x, y, z: int;
  th: Pmobj_t;
Begin
  x := mo^.x + P_SubRandom() * 2048;
  y := mo^.y;
  z := 128 + P_Random() * 2 * FRACUNIT;
  th := P_SpawnMobj(x, y, z, MT_ROCKET);
  th^.momz := P_Random() * 512;

  P_SetMobjState(th, S_BRAINEXPLODE1);

  th^.tics := th^.tics - P_Random() And 7;
  If (th^.tics < 1) Then
    th^.tics := 1;

  // [crispy] brain explosions are translucent
  th^.flags := int(th^.flags Or MF_TRANSLUCENT);
End;

Procedure A_SpawnSound(mo: Pmobj_t);
Begin
  S_StartSound(mo, sfx_boscub);
  A_SpawnFly(mo);
End;

Procedure A_SpawnFly(mo: Pmobj_t);
Var
  newmobj: Pmobj_t;
  fog: Pmobj_t;
  targ: Pmobj_t;
  r: int;
  _type: mobjtype_t;
Begin
  mo^.reactiontime := mo^.reactiontime - 1;
  If (mo^.reactiontime > 0) Then exit; // still flying

  targ := P_SubstNullMobj(mo^.target);

  // First spawn teleport fog.
  fog := P_SpawnMobj(targ^.x, targ^.y, targ^.z, MT_SPAWNFIRE);
  S_StartSound(fog, sfx_telept);

  // Randomly select monster to spawn.
  r := P_Random();

  // Probability distribution (kind of :),
  // decreasing likelihood.
  If (r < 50) Then
    _type := MT_TROOP
  Else If (r < 90) Then
    _type := MT_SERGEANT
  Else If (r < 120) Then
    _type := MT_SHADOWS
  Else If (r < 130) Then
    _type := MT_PAIN
  Else If (r < 160) Then
    _type := MT_HEAD
  Else If (r < 162) Then
    _type := MT_VILE
  Else If (r < 172) Then
    _type := MT_UNDEAD
  Else If (r < 192) Then
    _type := MT_BABY
  Else If (r < 222) Then
    _type := MT_FATSO
  Else If (r < 246) Then
    _type := MT_KNIGHT
  Else
    _type := MT_BRUISER;

  newmobj := P_SpawnMobj(targ^.x, targ^.y, targ^.z, _type);

  // [crispy] count spawned monsters
  extrakills := extrakills + 1;

  If (P_LookForPlayers(newmobj, true)) Then
    P_SetMobjState(newmobj, newmobj^.info^.seestate);

  // telefrag anything in this spot
  P_TeleportMove(newmobj, newmobj^.x, newmobj^.y);

  // remove self (i.e., cube).
  P_RemoveMobj(mo);
End;

//
// Called by P_NoiseAlert.
// Recursively traverse adjacent sectors,
// sound blocking lines cut off traversal.
//

Procedure P_RecursiveSound(sec: Psector_t; soundblocks: int);
Var
  i: int;
  check: Pline_t;
  other: Psector_t;
Begin
  // wake up all monsters in this sector
  If (sec^.validcount = validcount)
    And (sec^.soundtraversed <= soundblocks + 1) Then Begin
    exit; // already flooded
  End;

  sec^.validcount := validcount;
  sec^.soundtraversed := soundblocks + 1;
  sec^.soundtarget := soundtarget;

  For i := 0 To sec^.linecount - 1 Do Begin
    check := @sec^.lines[i];
    If ((check^.flags And ML_TWOSIDED) = 0) Then
      continue;

    P_LineOpening(check);

    If (openrange <= 0) Then
      continue; // closed door

    If (sides[check^.sidenum[0]].sector = sec) Then
      other := sides[check^.sidenum[1]].sector
    Else
      other := sides[check^.sidenum[0]].sector;

    If (check^.flags And ML_SOUNDBLOCK) <> 0 Then Begin
      If (soundblocks = 0) Then
        P_RecursiveSound(other, 1);
    End
    Else
      P_RecursiveSound(other, soundblocks);
  End;
End;

//
// P_NoiseAlert
// If a monster yells at a player,
// it will alert other monsters to the player.
//

Procedure P_NoiseAlert(target: Pmobj_t; emmiter: Pmobj_t);
Begin
  // [crispy] monsters are deaf with NOTARGET cheat
  If assigned(target) And assigned(target^.player) And ((target^.player^.cheats And integer(CF_NOTARGET)) <> 0) Then exit;

  soundtarget := target;
  validcount := validcount + 1;
  P_RecursiveSound(emmiter^.subsector^.sector, 0);
End;

End.

