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
  doomdata, sounds, tables, doomstat
  , d_player, d_mode, d_main
  , g_game
  , i_system
  , m_fixed, m_random
  , p_pspr, p_map, p_maputl, p_setup, p_mobj, p_sight, p_local, p_switch, p_inter
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
    actor^.angle := actor^.angle + P_SubRandom() Shl 21;
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
  slope := P_AimLineAttack(actor, bangle, MISSILERANGE);

  For i := 0 To 2 Do Begin
    angle := angle_t(bangle + (P_SubRandom() Shl 20));
    damage := ((P_Random() Mod 5) + 1) * 3;
    P_LineAttack(actor, angle, MISSILERANGE, slope, damage);
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
        sound := integer(sfx_podth1) + P_Random() And 3;
      End;

    sfx_bgdth1,
      sfx_bgdth2: Begin
        sound := integer(sfx_bgdth1) + P_Random() And 2;
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

//
// A_VileChase
// Check for ressurecting a body
//

Procedure A_VileChase(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   int			xl;
  //    int			xh;
  //    int			yl;
  //    int			yh;
  //
  //    int			bx;
  //    int			by;
  //
  //    mobjinfo_t*		info;
  //    mobj_t*		temp;
  //
  //    if (actor->movedir != DI_NODIR)
  //    {
  //	// check for corpses to raise
  //	viletryx =
  //	    actor->x + actor->info->speed*xspeed[actor->movedir];
  //	viletryy =
  //	    actor->y + actor->info->speed*yspeed[actor->movedir];
  //
  //	xl = (viletryx - bmaporgx - MAXRADIUS*2)>>MAPBLOCKSHIFT;
  //	xh = (viletryx - bmaporgx + MAXRADIUS*2)>>MAPBLOCKSHIFT;
  //	yl = (viletryy - bmaporgy - MAXRADIUS*2)>>MAPBLOCKSHIFT;
  //	yh = (viletryy - bmaporgy + MAXRADIUS*2)>>MAPBLOCKSHIFT;
  //
  //	vileobj = actor;
  //	for (bx=xl ; bx<=xh ; bx++)
  //	{
  //	    for (by=yl ; by<=yh ; by++)
  //	    {
  //		// Call PIT_VileCheck to check
  //		// whether object is a corpse
  //		// that canbe raised.
  //		if (!P_BlockThingsIterator(bx,by,PIT_VileCheck))
  //		{
  //		    // got one!
  //		    temp = actor->target;
  //		    actor->target = corpsehit;
  //		    A_FaceTarget (actor);
  //		    actor->target = temp;
  //
  //		    P_SetMobjState (actor, S_VILE_HEAL1);
  //		    S_StartSound (corpsehit, sfx_slop);
  //		    info = corpsehit->info;
  //
  //		    P_SetMobjState (corpsehit,info->raisestate);
  //		    corpsehit->height <<= 2;
  //		    corpsehit->flags = info->flags;
  //		    corpsehit->health = info->spawnhealth;
  //		    corpsehit->target = NULL;
  //
  //		    // [crispy] count resurrected monsters
  //		    extrakills++;
  //
  //		    // [crispy] resurrected pools of gore ("ghost monsters") are translucent
  //		    if (corpsehit->height == 0 && corpsehit->radius == 0)
  //		    {
  //		        corpsehit->flags |= MF_TRANSLUCENT;
  //		        fprintf(stderr, "A_VileChase: Resurrected ghost monster (%d) at (%d/%d)!\n",
  //		                corpsehit->type, corpsehit->x>>FRACBITS, corpsehit->y>>FRACBITS);
  //		    }
  //
  //		    return;
  //		}
  //	    }
  //	}
  //    }
  //
  //    // Return to normal attack.
  //    A_Chase (actor);
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
Begin
  Raise exception.create('Port me.');

  //   mobj_t*	fog;
  //
  //    if (!actor->target)
  //	return;
  //
  //    A_FaceTarget (actor);
  //
  //    fog = P_SpawnMobj (actor->target->x,
  //		       actor->target->x,
  //		       actor->target->z, MT_FIRE);
  //
  //    actor->tracer = fog;
  //    fog->target = actor;
  //    fog->tracer = actor->target;
  //    // [crispy] play DSFLAMST sound when Arch-Vile spawns fire attack
  //    if (crispy->soundfix && I_GetSfxLumpNum(&S_sfx[sfx_flamst]) != -1)
  //    {
  //	S_StartSound(fog, sfx_flamst);
  //	// [crispy] make DSFLAMST sound uninterruptible
  //	if (crispy->soundfull)
  //	{
  //		S_UnlinkSound(fog);
  //	}
  //    }
  //
  //    A_Fire (fog);
End;

Procedure A_VileAttack(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   mobj_t*	fire;
  //    int		an;
  //
  //    if (!actor->target)
  //	return;
  //
  //    A_FaceTarget (actor);
  //
  //    if (!P_CheckSight (actor, actor->target) )
  //	return;
  //
  //    S_StartSound (actor, sfx_barexp);
  //    P_DamageMobj (actor->target, actor, actor, 20);
  //    actor->target->momz = 1000*FRACUNIT/actor->target->info->mass;
  //
  //    an = actor->angle >> ANGLETOFINESHIFT;
  //
  //    fire = actor->tracer;
  //
  //    if (!fire)
  //	return;
  //
  //    // move the fire between the vile and the player
  //    fire->x = actor->target->x - FixedMul (24*FRACUNIT, finecosine[an]);
  //    fire->y = actor->target->y - FixedMul (24*FRACUNIT, finesine[an]);
  //P_RadiusAttack(fire, actor, 70);
End;

Procedure A_StartFire(actor: Pmobj_t);
Begin
  S_StartSound(actor, sfx_flamst);
  A_Fire(actor);
End;

Procedure A_Fire(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   mobj_t*	dest;
  //    mobj_t*     target;
  //    unsigned	an;
  //
  //    dest = actor->tracer;
  //    if (!dest)
  //	return;
  //
  //    target = P_SubstNullMobj(actor->target);
  //
  //    // don't move it if the vile lost sight
  //    if (!P_CheckSight (target, dest) )
  //	return;
  //
  //    an = dest->angle >> ANGLETOFINESHIFT;
  //
  //    P_UnsetThingPosition (actor);
  //    actor->x = dest->x + FixedMul (24*FRACUNIT, finecosine[an]);
  //    actor->y = dest->y + FixedMul (24*FRACUNIT, finesine[an]);
  //    actor->z = dest->z;
  //    P_SetThingPosition (actor);
  //
  //    // [crispy] suppress interpolation of Archvile fire
  //    // to mitigate it being spawned at the wrong location
  //    actor->interp = -actor->tics;
End;

Procedure A_FireCrackle(actor: Pmobj_t);
Begin
  S_StartSound(actor, sfx_flame);
  A_Fire(actor);
End;

Const
  TRACEANGLE: int = $C000000;

Procedure A_Tracer(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   angle_t	exact;
  //    fixed_t	dist;
  //    fixed_t	slope;
  //    mobj_t*	dest;
  //    mobj_t*	th;
  //    extern int demostarttic;
  //
  //    if ((gametic  - demostarttic) & 3) // [crispy] fix revenant internal demo bug
  //	return;
  //
  //    // spawn a puff of smoke behind the rocket
  //    P_SpawnPuff (actor->x, actor->y, actor->z);
  //
  //    th = P_SpawnMobj (actor->x-actor->momx,
  //		      actor->y-actor->momy,
  //		      actor->z, MT_SMOKE);
  //
  //    th->momz = FRACUNIT;
  //    th->tics -= P_Random()&3;
  //    if (th->tics < 1)
  //	th->tics = 1;
  //
  //    // adjust direction
  //    dest = actor->tracer;
  //
  //    if (!dest || dest->health <= 0)
  //	return;
  //
  //    // change angle
  //    exact = R_PointToAngle2 (actor->x,
  //			     actor->y,
  //			     dest->x,
  //			     dest->y);
  //
  //    if (exact != actor->angle)
  //    {
  //	if (exact - actor->angle > 0x80000000)
  //	{
  //	    actor->angle -= TRACEANGLE;
  //	    if (exact - actor->angle < 0x80000000)
  //		actor->angle = exact;
  //	}
  //	else
  //	{
  //	    actor->angle += TRACEANGLE;
  //	    if (exact - actor->angle > 0x80000000)
  //		actor->angle = exact;
  //	}
  //    }
  //
  //    exact = actor->angle>>ANGLETOFINESHIFT;
  //    actor->momx = FixedMul (actor->info->speed, finecosine[exact]);
  //    actor->momy = FixedMul (actor->info->speed, finesine[exact]);
  //
  //    // change slope
  //    dist = P_AproxDistance (dest->x - actor->x,
  //			    dest->y - actor->y);
  //
  //    dist = dist / actor->info->speed;
  //
  //    if (dist < 1)
  //	dist = 1;
  //    slope = (dest->z+40*FRACUNIT - actor->z) / dist;
  //
  //    if (slope < actor->momz)
  //	actor->momz -= FRACUNIT/8;
  //    else
  //	actor->momz += FRACUNIT/8;
End;

Procedure A_SkelWhoosh(actor: Pmobj_t);
Begin
  If Not assigned(actor^.target) Then exit;
  A_FaceTarget(actor);
  S_StartSound(actor, sfx_skeswg);
End;

Procedure A_SkelFist(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //    int		damage;
  //
  //    if (!actor->target)
  //	return;
  //
  //    A_FaceTarget (actor);
  //
  //    if (P_CheckMeleeRange (actor))
  //    {
  //	damage = ((P_Random()%10)+1)*6;
  //	S_StartSound (actor, sfx_skepch);
  //	P_DamageMobj (actor->target, actor, actor, damage);
  //    }
End;

Procedure A_SkelMissile(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //    mobj_t*	mo;
  //
  //    if (!actor->target)
  //	return;
  //
  //    A_FaceTarget (actor);
  //    actor->z += 16*FRACUNIT;	// so missile spawns higher
  //    mo = P_SpawnMissile (actor, actor->target, MT_TRACER);
  //    actor->z -= 16*FRACUNIT;	// back to normal
  //
  //    mo->x += mo->momx;
  //    mo->y += mo->momy;
  //    mo->tracer = actor->target;
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
Begin
  Raise exception.create('Port me.');

  //   mobj_t*	mo;
  //    mobj_t*     target;
  //    int		an;
  //
  //    A_FaceTarget (actor);
  //
  //    // Change direction  to ...
  //    actor->angle += FATSPREAD;
  //    target = P_SubstNullMobj(actor->target);
  //    P_SpawnMissile (actor, target, MT_FATSHOT);
  //
  //    mo = P_SpawnMissile (actor, target, MT_FATSHOT);
  //    mo->angle += FATSPREAD;
  //    an = mo->angle >> ANGLETOFINESHIFT;
  //    mo->momx = FixedMul (mo->info->speed, finecosine[an]);
  //    mo->momy = FixedMul (mo->info->speed, finesine[an]);
End;

Procedure A_FatAttack2(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //    mobj_t*	mo;
  //    mobj_t*     target;
  //    int		an;
  //
  //    A_FaceTarget (actor);
  //    // Now here choose opposite deviation.
  //    actor->angle -= FATSPREAD;
  //    target = P_SubstNullMobj(actor->target);
  //    P_SpawnMissile (actor, target, MT_FATSHOT);
  //
  //    mo = P_SpawnMissile (actor, target, MT_FATSHOT);
  //    mo->angle -= FATSPREAD*2;
  //    an = mo->angle >> ANGLETOFINESHIFT;
  //    mo->momx = FixedMul (mo->info->speed, finecosine[an]);
  //    mo->momy = FixedMul (mo->info->speed, finesine[an]);
End;

Procedure A_FatAttack3(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //    mobj_t*	mo;
  //    mobj_t*     target;
  //    int		an;
  //
  //    A_FaceTarget (actor);
  //
  //    target = P_SubstNullMobj(actor->target);
  //
  //    mo = P_SpawnMissile (actor, target, MT_FATSHOT);
  //    mo->angle -= FATSPREAD/2;
  //    an = mo->angle >> ANGLETOFINESHIFT;
  //    mo->momx = FixedMul (mo->info->speed, finecosine[an]);
  //    mo->momy = FixedMul (mo->info->speed, finesine[an]);
  //
  //    mo = P_SpawnMissile (actor, target, MT_FATSHOT);
  //    mo->angle += FATSPREAD/2;
  //    an = mo->angle >> ANGLETOFINESHIFT;
  //    mo->momx = FixedMul (mo->info->speed, finecosine[an]);
  //    mo->momy = FixedMul (mo->info->speed, finesine[an]);
End;

//
// A_BossDeath
// Possibly trigger special effects
// if on first boss level
//

Procedure A_BossDeath(mo: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   thinker_t*	th;
  //    mobj_t*	mo2;
  //    line_t	junk;
  //    int		i;
  //
  //    if ( gamemode == commercial)
  //    {
  //	if (gamemap != 7 &&
  //	// [crispy] Master Levels in PC slot 7
  //	!(gamemission == pack_master && (gamemap == 14 || gamemap == 15 || gamemap == 16)))
  //	    return;
  //
  //	if ((mo->type != MT_FATSO)
  //	    && (mo->type != MT_BABY))
  //	    return;
  //    }
  //    else
  //    {
  //        if (!CheckBossEnd(mo->type))
  //        {
  //            return;
  //        }
  //    }
  //
  //    // make sure there is a player alive for victory
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //	if (playeringame[i] && players[i].health > 0)
  //	    break;
  //
  //    if (i==MAXPLAYERS)
  //	return;	// no one left alive, so do not end game
  //
  //    // scan the remaining thinkers to see
  //    // if all bosses are dead
  //    for (th = thinkercap.next ; th != &thinkercap ; th=th->next)
  //    {
  //	if (th->function.acp1 != (actionf_p1)P_MobjThinker)
  //	    continue;
  //
  //	mo2 = (mobj_t *)th;
  //	if (mo2 != mo
  //	    && mo2->type == mo->type
  //	    && mo2->health > 0)
  //	{
  //	    // other boss not dead
  //	    return;
  //	}
  //    }
  //
  //    // victory!
  //    if ( gamemode == commercial)
  //    {
  //	if (gamemap == 7 ||
  //	// [crispy] Master Levels in PC slot 7
  //	(gamemission == pack_master && (gamemap == 14 || gamemap == 15 || gamemap == 16)))
  //	{
  //	    if (mo->type == MT_FATSO)
  //	    {
  //		junk.tag = 666;
  //		EV_DoFloor(&junk,lowerFloorToLowest);
  //		return;
  //	    }
  //
  //	    if (mo->type == MT_BABY)
  //	    {
  //		junk.tag = 667;
  //		EV_DoFloor(&junk,raiseToTexture);
  //		return;
  //	    }
  //	}
  //    }
  //    else
  //    {
  //	switch(gameepisode)
  //	{
  //	  case 1:
  //	    junk.tag = 666;
  //	    EV_DoFloor (&junk, lowerFloorToLowest);
  //	    return;
  //	    break;
  //
  //	  case 4:
  //	    switch(gamemap)
  //	    {
  //	      case 6:
  //		junk.tag = 666;
  //		EV_DoDoor (&junk, vld_blazeOpen);
  //		return;
  //		break;
  //
  //	      case 8:
  //		junk.tag = 666;
  //		EV_DoFloor (&junk, lowerFloorToLowest);
  //		return;
  //		break;
  //	    }
  //	}
  //    }

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
  slope := P_AimLineAttack(actor, bangle, MISSILERANGE);

  angle := angle_t(bangle + (P_SubRandom() Shl 20));
  damage := ((P_Random() Mod 5) + 1) * 3;
  P_LineAttack(actor, angle, MISSILERANGE, slope, damage);
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
Begin
  Raise exception.create('Port me.');

  //    int		damage;
  //
  //    if (!actor->target)
  //	return;
  //
  //    A_FaceTarget (actor);
  //
  //    if (gameversion >= exe_doom_1_5)
  //    {
  //        if (!P_CheckMeleeRange (actor))
  //            return;
  //    }
  //
  //    damage = ((P_Random()%10)+1)*4;
  //
  //    if (gameversion <= exe_doom_1_2)
  //        P_LineAttack(actor, actor->angle, MELEERANGE, 0, damage);
  //    else
  //        P_DamageMobj (actor->target, actor, actor, damage);
End;

Procedure A_HeadAttack(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   int		damage;
  //
  //    if (!actor->target)
  //	return;
  //
  //    A_FaceTarget (actor);
  //    if (P_CheckMeleeRange (actor))
  //    {
  //	damage = (P_Random()%6+1)*10;
  //	P_DamageMobj (actor->target, actor, actor, damage);
  //	return;
  //    }
  //
  //    // launch a missile
  //    P_SpawnMissile (actor, actor->target, MT_HEADSHOT);
End;

Procedure A_BruisAttack(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //    int		damage;
  //
  //    if (!actor->target)
  //	return;
  //
  //    // [crispy] face the enemy
  ////  A_FaceTarget (actor);
  //    if (P_CheckMeleeRange (actor))
  //    {
  //	S_StartSound (actor, sfx_claw);
  //	damage = (P_Random()%8+1)*10;
  //	P_DamageMobj (actor->target, actor, actor, damage);
  //	return;
  //    }
  //
  //    // launch a missile
  //    P_SpawnMissile (actor, actor->target, MT_BRUISERSHOT);
End;

//
// SkullAttack
// Fly at the player like a missile.
//
Const
  SKULLSPEED = (20 * FRACUNIT);

Procedure A_SkullAttack(actor: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //    mobj_t*		dest;
  //    angle_t		an;
  //    int			dist;
  //
  //    if (!actor->target)
  //	return;
  //
  //    dest = actor->target;
  //    actor->flags |= MF_SKULLFLY;
  //
  //    S_StartSound (actor, actor->info->attacksound);
  //    A_FaceTarget (actor);
  //    an = actor->angle >> ANGLETOFINESHIFT;
  //    actor->momx = FixedMul (SKULLSPEED, finecosine[an]);
  //    actor->momy = FixedMul (SKULLSPEED, finesine[an]);
  //    dist = P_AproxDistance (dest->x - actor->x, dest->y - actor->y);
  //    dist = dist / SKULLSPEED;
  //
  //    if (dist < 1)
  //	dist = 1;
  //    actor->momz = (dest->z+(dest->height>>1) - actor->z) / dist;
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
  Raise exception.create('Port me.');

  // keep firing unless target got out of sight
//    A_FaceTarget (actor);
//
//    if (P_Random () < 10)
//	return;
//
//    if (!actor->target
//	|| actor->target->health <= 0
//	|| !P_CheckSight (actor, actor->target) )
//    {
//	P_SetMobjState (actor, actor->info->seestate);
//    }
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
Begin
  Raise exception.create('Port me.');

  //    fixed_t	x;
  //    fixed_t	y;
  //    fixed_t	z;
  //
  //    mobj_t*	newmobj;
  //    angle_t	an;
  //    int		prestep;
  //    int		count;
  //    thinker_t*	currentthinker;
  //
  //    // count total number of skull currently on the level
  //    count = 0;
  //
  //    currentthinker = thinkercap.next;
  //    while (currentthinker != &thinkercap)
  //    {
  //	if (   (currentthinker->function.acp1 == (actionf_p1)P_MobjThinker)
  //	    && ((mobj_t *)currentthinker)->type == MT_SKULL)
  //	    count++;
  //	currentthinker = currentthinker->next;
  //    }
  //
  //    // if there are allready 20 skulls on the level,
  //    // don't spit another one
  //    if (count > 20)
  //	return;
  //
  //
  //    // okay, there's playe for another one
  //    an = angle >> ANGLETOFINESHIFT;
  //
  //    prestep =
  //	4*FRACUNIT
  //	+ 3*(actor->info->radius + mobjinfo[MT_SKULL].radius)/2;
  //
  //    x = actor->x + FixedMul (prestep, finecosine[an]);
  //    y = actor->y + FixedMul (prestep, finesine[an]);
  //    z = actor->z + 8*FRACUNIT;
  //
  //    newmobj = P_SpawnMobj (x , y, z, MT_SKULL);
  //
  //    // Check for movements.
  //    if (!P_TryMove (newmobj, newmobj->x, newmobj->y))
  //    {
  //	// kill it immediately
  //	P_DamageMobj (newmobj,actor,actor,10000);
  //	return;
  //    }
  //
  //    // [crispy] Lost Souls bleed Puffs
  //    if (crispy->coloredblood == COLOREDBLOOD_ALL)
  //        newmobj->flags |= MF_NOBLOOD;
  //
  //    newmobj->target = actor->target;
  //    A_SkullAttack (newmobj);
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
  A_PainShootSkull(actor, actor^.angle + ANG90);
  A_PainShootSkull(actor, actor^.angle + ANG180);
  A_PainShootSkull(actor, actor^.angle + ANG270);
End;

//
// A_KeenDie
// DOOM II special, map 32.
// Uses special tag 666.
//

Procedure A_KeenDie(mo: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   thinker_t*	th;
  //    mobj_t*	mo2;
  //    line_t	junk;
  //
  //    A_Fall (mo);
  //
  //    // scan the remaining thinkers
  //    // to see if all Keens are dead
  //    for (th = thinkercap.next ; th != &thinkercap ; th=th->next)
  //    {
  //	if (th->function.acp1 != (actionf_p1)P_MobjThinker)
  //	    continue;
  //
  //	mo2 = (mobj_t *)th;
  //	if (mo2 != mo
  //	    && mo2->type == mo->type
  //	    && mo2->health > 0)
  //	{
  //	    // other Keen not dead
  //	    return;
  //	}
  //    }
  //
  //    junk.tag = 666;
  //    EV_DoDoor(&junk, vld_open);
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
Begin
  Raise exception.create('Port me.');

  //   int		x;
  //    int		y;
  //    int		z;
  //    mobj_t*	th;
  //
  //    for (x=mo->x - 196*FRACUNIT ; x< mo->x + 320*FRACUNIT ; x+= FRACUNIT*8)
  //    {
  //	y = mo->y - 320*FRACUNIT;
  //	z = 128 + P_Random()*2*FRACUNIT;
  //	th = P_SpawnMobj (x,y,z, MT_ROCKET);
  //	th->momz = P_Random()*512;
  //
  //	P_SetMobjState (th, S_BRAINEXPLODE1);
  //
  //	th->tics -= P_Random()&7;
  //	if (th->tics < 1)
  //	    th->tics = 1;
  //    }
  //
  //    S_StartSound (NULL,sfx_bosdth);
End;

Procedure A_BrainDie(mo: Pmobj_t);
Begin
  G_ExitLevel();
End;

Procedure A_BrainAwake(mo: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   thinker_t*	thinker;
  //    mobj_t*	m;
  //
  //    // find all the target spots
  //    numbraintargets = 0;
  //    braintargeton = 0;
  //
  //    for (thinker = thinkercap.next ;
  //	 thinker != &thinkercap ;
  //	 thinker = thinker->next)
  //    {
  //	if (thinker->function.acp1 != (actionf_p1)P_MobjThinker)
  //	    continue;	// not a mobj
  //
  //	m = (mobj_t *)thinker;
  //
  //	if (m->type == MT_BOSSTARGET )
  //	{
  //	    // [crispy] remove braintargets limit
  //	    if (numbraintargets == maxbraintargets)
  //	    {
  //		maxbraintargets = maxbraintargets ? 2 * maxbraintargets : 32;
  //		braintargets = I_Realloc(braintargets, maxbraintargets * sizeof(*braintargets));
  //
  //		if (maxbraintargets > 32)
  //		    fprintf(stderr, "R_BrainAwake: Raised braintargets limit to %d.\n", maxbraintargets);
  //	    }
  //
  //	    braintargets[numbraintargets] = m;
  //	    numbraintargets++;
  //	}
  //    }
  //
  //    S_StartSound (NULL,sfx_bossit);
  //
  //    // [crispy] prevent braintarget overflow
  //    // (e.g. in two subsequent maps featuring a brain spitter)
  //    if (braintargeton >= numbraintargets)
  //    {
  //	braintargeton = 0;
  //    }
  //
  //    // [crispy] no spawn spots available
  //    if (numbraintargets == 0)
  //	numbraintargets = -1;
End;

Procedure A_BrainSpit(mo: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   mobj_t*	targ;
  //    mobj_t*	newmobj;
  //
  //    static int	easy = 0;
  //
  //    easy ^= 1;
  //    if (gameskill <= sk_easy && (!easy))
  //	return;
  //
  //    // [crispy] avoid division by zero by recalculating the number of spawn spots
  //    if (numbraintargets == 0)
  //	A_BrainAwake(NULL);
  //
  //    // [crispy] still no spawn spots available
  //    if (numbraintargets == -1)
  //	return;
  //
  //    // shoot a cube at current target
  //    targ = braintargets[braintargeton];
  //    if (numbraintargets == 0)
  //    {
  //        I_Error("A_BrainSpit: numbraintargets was 0 (vanilla crashes here)");
  //    }
  //    braintargeton = (braintargeton+1)%numbraintargets;
  //
  //    // spawn brain missile
  //    newmobj = P_SpawnMissile (mo, targ, MT_SPAWNSHOT);
  //    newmobj->target = targ;
  //    newmobj->reactiontime =
  //	((targ->y - mo->y)/newmobj->momy) / newmobj->state->tics;
  //
  //    S_StartSound(NULL, sfx_bospit);
End;

Procedure A_BrainExplode(mo: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //    int		x;
  //    int		y;
  //    int		z;
  //    mobj_t*	th;
  //
  //    x = mo->x +  P_SubRandom() * 2048;
  //    y = mo->y;
  //    z = 128 + P_Random()*2*FRACUNIT;
  //    th = P_SpawnMobj (x,y,z, MT_ROCKET);
  //    th->momz = P_Random()*512;
  //
  //    P_SetMobjState (th, S_BRAINEXPLODE1);
  //
  //    th->tics -= P_Random()&7;
  //    if (th->tics < 1)
  //	th->tics = 1;
  //
  //    // [crispy] brain explosions are translucent
  //    th->flags |= MF_TRANSLUCENT;
End;

Procedure A_SpawnSound(mo: Pmobj_t);
Begin
  S_StartSound(mo, sfx_boscub);
  A_SpawnFly(mo);
End;

Procedure A_SpawnFly(mo: Pmobj_t);
Begin
  Raise exception.create('Port me.');

  //   mobj_t*	newmobj;
  //    mobj_t*	fog;
  //    mobj_t*	targ;
  //    int		r;
  //    mobjtype_t	type;
  //
  //    if (--mo->reactiontime)
  //	return;	// still flying
  //
  //    targ = P_SubstNullMobj(mo->target);
  //
  //    // First spawn teleport fog.
  //    fog = P_SpawnMobj (targ->x, targ->y, targ->z, MT_SPAWNFIRE);
  //    S_StartSound (fog, sfx_telept);
  //
  //    // Randomly select monster to spawn.
  //    r = P_Random ();
  //
  //    // Probability distribution (kind of :),
  //    // decreasing likelihood.
  //    if ( r<50 )
  //	type = MT_TROOP;
  //    else if (r<90)
  //	type = MT_SERGEANT;
  //    else if (r<120)
  //	type = MT_SHADOWS;
  //    else if (r<130)
  //	type = MT_PAIN;
  //    else if (r<160)
  //	type = MT_HEAD;
  //    else if (r<162)
  //	type = MT_VILE;
  //    else if (r<172)
  //	type = MT_UNDEAD;
  //    else if (r<192)
  //	type = MT_BABY;
  //    else if (r<222)
  //	type = MT_FATSO;
  //    else if (r<246)
  //	type = MT_KNIGHT;
  //    else
  //	type = MT_BRUISER;
  //
  //    newmobj	= P_SpawnMobj (targ->x, targ->y, targ->z, type);
  //
  //    // [crispy] count spawned monsters
  //    extrakills++;
  //
  //    if (P_LookForPlayers (newmobj, true) )
  //	P_SetMobjState (newmobj, newmobj->info->seestate);
  //
  //    // telefrag anything in this spot
  //    P_TeleportMove (newmobj, newmobj->x, newmobj->y);
  //
  //    // remove self (i.e., cube).
  //    P_RemoveMobj (mo);
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

