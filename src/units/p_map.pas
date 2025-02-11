Unit p_map;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types, tables
  , m_fixed
  ;

Var
  linetarget: Pmobj_t; // who got hit (or NULL)

  tmbbox: Array[0..3] Of fixed_t; // WTF: gibt es für die BoundingBox nicht einen eigenen Datentyp ?
  tmthing: Pmobj_t;
  tmflags: int;
  tmx: fixed_t;
  tmy: fixed_t;

  // If "floatok" true, move would be ok
  // if within "tmfloorz - tmceilingz".
  floatok: boolean;

  tmfloorz: fixed_t;
  tmceilingz: fixed_t;
  tmdropoffz: fixed_t;

  // keep track of the line that lowers the ceiling,
  // so missiles don't explode against sky hack walls
  ceilingline: Pline_t;

  // keep track of special lines as they are hit,
  // but don't process them until the move is proven valid
  spechit: Array Of Pline_t; // [crispy] remove SPECHIT limit
  numspechit: int;
  spechit_max: int; // [crispy] remove SPECHIT limit
  attackrange: fixed_t;

Procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; damage: int);

// [crispy] update laser spot position
// call P_AimLineAttack() to check if a target is aimed at (linetarget)
// then call P_LineAttack() with either aimslope or the passed slope
Procedure P_LineLaser(t1: pmobj_t; angle: angle_t; distance: fixed_t; slope: fixed_t);

Procedure P_LineAttack(t1: pmobj_t; angle: angle_t; distance: fixed_t; slope: fixed_t; damage: int);

Procedure P_UseLines(player: Pplayer_t);

Function PIT_CheckThing(thing: Pmobj_t): boolean;
Function PIT_CheckLine(ld: Pline_t): boolean;

Function P_TryMove(thing: Pmobj_t; x, y: fixed_t): boolean;
Procedure P_SlideMove(mo: Pmobj_t);

Function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;
Function P_AimLineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t): fixed_t;

Implementation

Uses
  math, doomdata, sounds, doomstat
  , d_mode, deh_misc
  , i_video, i_system
  , m_random, m_bbox
  , p_sight, p_maputl, p_local, p_mobj, p_spec, p_setup, p_inter, p_switch, p_tick, p_enemy
  , r_things, r_main, r_sky
  , s_sound
  ;

Var
  shootthing: Pmobj_t;
  // Height if not aiming up or down
  // ???: use slope for monsters?
  shootz: fixed_t;

  la_damage: int;
  aimslope: fixed_t;

  bestslidefrac: fixed_t;
  secondslidefrac: fixed_t;

  bestslideline: Pline_t;
  secondslideline: Pline_t;

  slidemo: Pmobj_t;
  usething: Pmobj_t;

  tmxmove: fixed_t;
  tmymove: fixed_t;
  crushchange: boolean;
  nofit: boolean;

  // Certain functions assume that a mobj_t pointer is non-NULL,
  // causing a crash in some situations where it is NULL.  Vanilla
  // Doom did not crash because of the lack of proper memory
  // protection. This function substitutes NULL pointers for
  // pointers to a dummy mobj, to avoid a crash.
Var
  dummy_mobj: mobj_t;

  bombsource: Pmobj_t;
  bombspot: Pmobj_t;
  bombdamage: int;

Procedure LaserThinkerDummyProcedure();
Begin
  Raise exception.create('LaserThinkerDummyProcedure, shall never be called.');
End;

Function P_SubstNullMobj(mobj: Pmobj_t): Pmobj_t;
Begin
  If (mobj = Nil) Then Begin
    dummy_mobj.x := 0;
    dummy_mobj.y := 0;
    dummy_mobj.z := 0;
    dummy_mobj.flags := 0;
    result := @dummy_mobj;
  End
  Else Begin
    result := mobj;
  End;
End;

//
// PTR_AimTraverse
// Sets linetaget and aimslope when a target is aimed at.
//

Function PTR_AimTraverse(_in: Pintercept_t): boolean;
Var
  li: ^line_t;
  th: ^mobj_t;
  slope, thingtopslope, thingbottomslope, dist: fixed_t;
Begin
  If (_in^.isaline) Then Begin
    li := _in^.d.line;

    If ((li^.flags And ML_TWOSIDED) = 0) Then Begin
      result := false; // stop
      exit;
    End;

    // Crosses a two sided line.
    // A two sided line will restrict
    // the possible target ranges.
    P_LineOpening(li);

    If (openbottom >= opentop) Then Begin
      result := false; // stop
      exit;
    End;

    dist := FixedMul(attackrange, _in^.frac);

    If (li^.backsector = Nil)
      Or (li^.frontsector^.floorheight <> li^.backsector^.floorheight) Then Begin
      slope := FixedDiv(openbottom - shootz, dist);
      If (slope > bottomslope) Then
        bottomslope := slope;
    End;

    If (li^.backsector = Nil)
      Or (li^.frontsector^.ceilingheight <> li^.backsector^.ceilingheight) Then Begin
      slope := FixedDiv(opentop - shootz, dist);
      If (slope < topslope) Then
        topslope := slope;
    End;

    If (topslope <= bottomslope) Then Begin
      result := false; // stop
      exit;
    End;

    result := true; // shot continues
    exit;
  End;

  // shoot a thing
  th := _in^.d.thing;
  If (th = shootthing) Then Begin
    result := true; // can't shoot self
    exit;
  End;

  If ((th^.flags And MF_SHOOTABLE) = 0) Then Begin
    result := true; // corpse or something
    exit;
  End;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(attackrange, _in^.frac);
  thingtopslope := FixedDiv(th^.z + th^.height - shootz, dist);

  If (thingtopslope < bottomslope) Then Begin
    result := true; // shot over the thing
    exit;
  End;

  thingbottomslope := FixedDiv(th^.z - shootz, dist);

  If (thingbottomslope > topslope) Then Begin
    result := true; // shot under the thing
    exit;
  End;

  // this thing can be hit!
  If (thingtopslope > topslope) Then Begin
    thingtopslope := topslope;
  End;

  If (thingbottomslope < bottomslope) Then Begin
    thingbottomslope := bottomslope;
  End;

  aimslope := (thingtopslope + thingbottomslope) Div 2;
  linetarget := th;
  result := false; // don't go any farther
End;

//
// P_AimLineAttack
//

Function P_AimLineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t): fixed_t;
Var
  x2, y2: fixed_t;
Begin
  t1 := P_SubstNullMobj(t1);

  angle := angle Shr ANGLETOFINESHIFT;

  shootthing := t1;

  x2 := t1^.x + SarLongint(distance, FRACBITS) * finecosine[angle];
  y2 := t1^.y + SarLongint(distance, FRACBITS) * finesine[angle];
  shootz := t1^.z + SarLongint(t1^.height, 1) + 8 * FRACUNIT;

  // can't shoot outside view angles
  topslope := (ORIGHEIGHT Div 2) * FRACUNIT Div (ORIGWIDTH Div 2);
  bottomslope := -(ORIGHEIGHT Div 2) * FRACUNIT Div (ORIGWIDTH Div 2);

  attackrange := distance;
  linetarget := Nil;

  P_PathTraverse(
    t1^.x, t1^.y,
    x2, y2,
    PT_ADDLINES Or PT_ADDTHINGS,
    @PTR_AimTraverse);

  If assigned(linetarget) Then Begin
    result := aimslope;
    exit;
  End;

  result := 0;
End;

//
// PIT_RadiusAttack
// "bombsource" is the creature
// that caused the explosion at "bombspot".
//

Function PIT_RadiusAttack(thing: Pmobj_t): boolean;
Var
  dx: fixed_t;
  dy: fixed_t;
  dist: fixed_t;
Begin
  If ((thing^.flags And MF_SHOOTABLE) = 0) Then Begin
    result := true;
    exit;
  End;

  // Boss spider and cyborg
  // take no damage from concussion.
  If (thing^._type = MT_CYBORG)
    Or (thing^._type = MT_SPIDER) Then Begin
    result := true;
    exit;
  End;

  dx := abs(thing^.x - bombspot^.x);
  dy := abs(thing^.y - bombspot^.y);
  If dx > dy Then Begin
    dist := dx;
  End
  Else Begin
    dist := dy;
  End;
  dist := SarLongint(dist - thing^.radius, FRACBITS);

  If (dist < 0) Then
    dist := 0;

  If (dist >= bombdamage) Then Begin
    result := true; // out of range
    exit;
  End;

  If (P_CheckSight(thing, bombspot)) Then Begin
    // must be in direct path
    P_DamageMobj(thing, bombspot, bombsource, bombdamage - dist);
  End;

  result := true;
End;

//
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//

Procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; damage: int);
Var
  x: int;
  y: int;
  xl: int;
  xh: int;
  yl: int;
  yh: int;
  dist: fixed_t;
Begin
  dist := fixed_t((damage + MAXRADIUS) Shl FRACBITS);
  yh := SarLongint(spot^.y + dist - bmaporgy, MAPBLOCKSHIFT);
  yl := SarLongint(spot^.y - dist - bmaporgy, MAPBLOCKSHIFT);
  xh := SarLongint(spot^.x + dist - bmaporgx, MAPBLOCKSHIFT);
  xl := SarLongint(spot^.x - dist - bmaporgx, MAPBLOCKSHIFT);
  bombspot := spot;
  bombsource := source;
  bombdamage := damage;

  For y := yl To yh Do
    For x := xl To xh Do
      P_BlockThingsIterator(x, y, @PIT_RadiusAttack);
End;

Procedure P_LineLaser(t1: pmobj_t; angle: angle_t; distance: fixed_t;
  slope: fixed_t);
Var
  lslope: fixed_t;
  an: angle_t;
Begin

  laserspot^.thinker._function.acv := Nil;

  // [crispy] intercepts overflow guard
  crispy.crosshair := crispy.crosshair Or CROSSHAIR_INTERCEPT;

  // [crispy] set the linetarget pointer
  lslope := P_AimLineAttack(t1, angle, distance);

  If (critical^.freeaim = FREEAIM_DIRECT) Then Begin
    lslope := slope;
  End
  Else Begin
    // [crispy] increase accuracy
    If (linetarget = Nil) Then Begin
      an := angle;
      an := angle_t(an + 1 Shl 26);
      lslope := P_AimLineAttack(t1, an, distance);

      If (linetarget = Nil) Then Begin

        an := angle_t(an - 2 Shl 26);
        lslope := P_AimLineAttack(t1, an, distance);
        If (linetarget = Nil) And (critical^.freeaim = FREEAIM_BOTH) Then Begin
          lslope := slope;
        End;
      End;
    End;
  End;

  If ((crispy.crosshair And Not CROSSHAIR_INTERCEPT) = CROSSHAIR_PROJECTED) Then Begin
    // [crispy] don't aim at Spectres
    If (linetarget <> Nil) And ((linetarget^.flags And MF_SHADOW) <> 0) And (critical^.freeaim <> FREEAIM_DIRECT) Then
      P_LineAttack(t1, angle, distance, aimslope, INT_MIN)
    Else
      // [crispy] double the auto aim distance
      P_LineAttack(t1, angle, 2 * distance, lslope, INT_MIN);
  End;
  // [crispy] intercepts overflow guard
  crispy.crosshair := crispy.crosshair And Not CROSSHAIR_INTERCEPT;
End;

//
// PTR_ShootTraverse
//

Function PTR_ShootTraverse(_In: Pintercept_t): boolean;
Label
  hitline;
Var
  x, y, z, frac: fixed_t;
  li: ^line_t;
  th: ^mobj_t;
  slope, dist, thingtopslope, thingbottomslope, thingheight: fixed_t; // [crispy] mobj or actual sprite height
  safe: Boolean;
  side, lineside: int;
  sector: ^sector_t;
Begin
  If (_in^.isaline) Then Begin
    safe := false;
    li := _in^.d.line;
    // [crispy] laser spot does not shoot any line
    If (li^.special <> 0) And (la_damage > INT_MIN) Then
      P_ShootSpecialLine(shootthing, li);

    If ((li^.flags And ML_TWOSIDED) = 0) Then
      Goto hitline;

    // crosses a two sided line
    P_LineOpening(li);

    dist := FixedMul(attackrange, _in^.frac);

    // e6y: emulation of missed back side on two-sided lines.
    // backsector can be NULL when emulating missing back side.

    If (li^.backsector = Nil) Then Begin
      slope := FixedDiv(openbottom - shootz, dist);
      If (slope > aimslope) Then
        Goto hitline;

      slope := FixedDiv(opentop - shootz, dist);
      If (slope < aimslope) Then
        Goto hitline;
    End
    Else Begin
      If (li^.frontsector^.floorheight <> li^.backsector^.floorheight) Then Begin
        slope := FixedDiv(openbottom - shootz, dist);
        If (slope > aimslope) Then
          Goto hitline;
      End;

      If (li^.frontsector^.ceilingheight <> li^.backsector^.ceilingheight) Then Begin
        slope := FixedDiv(opentop - shootz, dist);
        If (slope < aimslope) Then
          Goto hitline;
      End;
    End;

    // shot continues
    result := true;
    exit;

    // hit line
    hitline:
    // position a bit closer
    frac := _in^.frac - FixedDiv(4 * FRACUNIT, attackrange);
    x := trace.x + FixedMul(trace.dx, frac);
    y := trace.y + FixedMul(trace.dy, frac);
    z := shootz + FixedMul(aimslope, FixedMul(frac, attackrange));

    If (li^.frontsector^.ceilingpic = skyflatnum) Then Begin

      // don't shoot the sky!
      If (z > li^.frontsector^.ceilingheight) Then Begin
        result := false;
        exit;
      End;

      // it's a sky hack wall
      If (li^.backsector <> Nil) And (li^.backsector^.ceilingpic = skyflatnum) Then Begin

        // [crispy] fix bullet puffs and laser spot not appearing in outdoor areas
        If (li^.backsector^.ceilingheight < z) Then Begin
          result := false;
          exit;
        End
        Else Begin
          safe := true;
        End;
      End;
    End;

    // [crispy] check if the bullet puff's z-coordinate is below or above
    // its spawning sector's floor or ceiling, respectively, and move its
    // coordinates to the point where the trajectory hits the plane
    If (aimslope <> 0) Then Begin
      lineside := P_PointOnLineSide(x, y, li);
      side := li^.sidenum[lineside];
      If ((side) <> NO_INDEX) Then Begin
        sector := sides[side].sector;

        If (z < sector^.floorheight) Or (
          (z > sector^.ceilingheight) And (sector^.ceilingpic <> skyflatnum)) Then Begin

          z := clamp(z, sector^.floorheight, sector^.ceilingheight);
          frac := FixedDiv(z - shootz, FixedMul(aimslope, attackrange));
          x := trace.x + FixedMul(trace.dx, frac);
          y := trace.y + FixedMul(trace.dy, frac);
        End;
      End;
    End;

    // [crispy] update laser spot position and return
    If (la_damage = INT_MIN) Then Begin
      laserspot^.thinker._Function.acv := @LaserThinkerDummyProcedure;
      laserspot^.x := x;
      laserspot^.y := y;
      laserspot^.z := z;
      result := false;
      exit;
    End;

    // Spawn bullet puffs.
    P_SpawnPuffSafe(x, y, z, safe);

    // don't go any farther
    result := false;
    exit;
  End;

  // shoot a thing
  th := _in^.d.thing;
  If (th = shootthing) Then Begin
    result := true; // can't shoot self
    exit;
  End;

  If ((th^.flags And MF_SHOOTABLE) = 0) Then Begin
    result := true; // corpse or something
    exit;
  End;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(attackrange, _in^.frac);
  // [crispy] mobj or actual sprite height
  If assigned(shootthing^.player) And (critical^.freeaim = FREEAIM_DIRECT) Then Begin
    thingheight := th^.info^.actualheight;
  End
  Else Begin
    thingheight := th^.height;
  End;
  thingtopslope := FixedDiv(th^.z + thingheight - shootz, dist);

  If (thingtopslope < aimslope) Then Begin
    result := true; // shot over the thing
    exit;
  End;

  thingbottomslope := FixedDiv(th^.z - shootz, dist);

  If (thingbottomslope > aimslope) Then Begin
    result := true; // shot under the thing
    exit;
  End;

  // hit thing
  // position a bit closer
  frac := _in^.frac - FixedDiv(10 * FRACUNIT, attackrange);

  x := trace.x + FixedMul(trace.dx, frac);
  y := trace.y + FixedMul(trace.dy, frac);
  z := shootz + FixedMul(aimslope, FixedMul(frac, attackrange));

  // [crispy] update laser spot position and return
  If (la_damage = INT_MIN) Then Begin

    // [crispy] pass through Spectres
    If (th^.flags And MF_SHADOW) <> 0 Then Begin
      result := true;
      exit;
    End;

    laserspot^.thinker._function.acv := @LaserThinkerDummyProcedure;
    laserspot^.x := th^.x;
    laserspot^.y := th^.y;
    laserspot^.z := z;
    result := false;
    exit;
  End;

  // Spawn bullet puffs or blod spots,
  // depending on target type.
  If (_in^.d.thing^.flags And MF_NOBLOOD) <> 0 Then
    P_SpawnPuff(x, y, z)
  Else
    P_SpawnBlood(x, y, z, la_damage, th); // [crispy] pass thing type

  If Crispy.fistisquit Then Begin // When fist is quit we need to wake up all the others when a unit on the map is shooting
    P_NoiseAlert(shootthing, shootthing);
  End;

  If (la_damage <> 0) Then
    P_DamageMobj(th, shootthing, shootthing, la_damage);

  // don't go any farther
  result := false;
End;

//
// P_LineAttack
// If damage == 0, it is just a test trace
// that will leave linetarget set.
// [crispy] if damage == INT_MIN, it is a trace
// to update the laser spot position
//

Procedure P_LineAttack(t1: pmobj_t; angle: angle_t; distance: fixed_t;
  slope: fixed_t; damage: int);
Var
  t1x, t1y: fixed_t;
  x2, y2: fixed_t;
Begin
  // [crispy] smooth laser spot movement with uncapped framerate
  If (damage = INT_MIN) Then Begin
    t1x := viewx;
    t1y := viewy;
  End
  Else Begin
    t1x := t1^.x;
    t1y := t1^.y;
  End;

  angle := angle Shr ANGLETOFINESHIFT;
  shootthing := t1;
  la_damage := damage;
  x2 := t1x + SarLongint(distance, FRACBITS) * finecosine[angle];
  y2 := t1y + SarLongint(distance, FRACBITS) * finesine[angle];
  If (damage = INT_MIN) Then Begin
    shootz := viewz;
  End
  Else Begin
    shootz := t1^.z + SarLongint(t1^.height, 1) + 8 * FRACUNIT;
  End;
  attackrange := distance;
  aimslope := slope;

  P_PathTraverse(t1x, t1y,
    x2, y2,
    PT_ADDLINES Or PT_ADDTHINGS,
    @PTR_ShootTraverse);
End;

Function PTR_UseTraverse(_in: Pintercept_t): Boolean;
Var
  side: int;
Begin

  If (_in^.d.line^.special = 0) Then Begin

    P_LineOpening(_in^.d.line);
    If (openrange <= 0) Then Begin

      S_StartSound(usething, sfx_noway);

      // can't use through a wall
      result := false;
      exit;
    End;
    // not a special line, but keep checking
    result := true;
    exit;
  End;

  side := 0;
  If (P_PointOnLineSide(usething^.x, usething^.y, _in^.d.line) = 1) Then
    side := 1;

  //	return false;		// don't use back side

  P_UseSpecialLine(usething, _In^.d.line, side);

  // can't use for than one special line in a row
  result := false;
End;

//
// P_UseLines
// Looks for special lines in front of the player to activate.
//

Procedure P_UseLines(player: Pplayer_t);
Var
  angle: int;
  x1, y1,
    x2, y2: fixed_t;
Begin
  usething := player^.mo;

  angle := player^.mo^.angle Shr ANGLETOFINESHIFT;

  x1 := player^.mo^.x;
  y1 := player^.mo^.y;
  x2 := x1 + (USERANGE Shr FRACBITS) * finecosine[angle];
  y2 := y1 + (USERANGE Shr FRACBITS) * finesine[angle];

  P_PathTraverse(x1, y1, x2, y2, PT_ADDLINES, @PTR_UseTraverse);
End;

//
// PIT_CheckLine
// Adjusts tmfloorz and tmceilingz as lines are contacted
//

Function PIT_CheckLine(ld: Pline_t): boolean;
Begin
  result := false;
  If (tmbbox[BOXRIGHT] <= ld^.bbox[BOXLEFT])
    Or (tmbbox[BOXLEFT] >= ld^.bbox[BOXRIGHT])
    Or (tmbbox[BOXTOP] <= ld^.bbox[BOXBOTTOM])
    Or (tmbbox[BOXBOTTOM] >= ld^.bbox[BOXTOP]) Then Begin
    result := true;
    exit;
  End;

  If (P_BoxOnLineSide(tmbbox, ld) <> -1) Then Begin
    result := true;
    exit;
  End;

  // A line has been hit

  // The moving thing's destination position will cross
  // the given line.
  // If this should not be allowed, return false.
  // If the line is special, keep track of it
  // to process later if the move is proven ok.
  // NOTE: specials are NOT sorted by order,
  // so two special lines that are only 8 pixels apart
  // could be crossed in either order.

  If (ld^.backsector = Nil) Then
    exit; // one sided line

  If ((tmthing^.flags And MF_MISSILE) = 0) Then Begin

    If (ld^.flags And ML_BLOCKING) <> 0 Then
      exit; // explicitly blocking everything

    If (tmthing^.player = Nil) And ((ld^.flags And ML_BLOCKMONSTERS) <> 0) Then
      exit; // block monsters only
  End;

  // set openrange, opentop, openbottom
  P_LineOpening(ld);

  // adjust floor / ceiling heights
  If (opentop < tmceilingz) Then Begin
    tmceilingz := opentop;
    ceilingline := ld;
  End;

  If (openbottom > tmfloorz) Then
    tmfloorz := openbottom;

  If (lowfloor < tmdropoffz) Then
    tmdropoffz := lowfloor;

  // if contacted a special line, add it to the list
  If (ld^.special <> 0) Then Begin

    // [crispy] remove SPECHIT limit
    If (numspechit >= spechit_max) Then Begin
      If spechit_max <> 0 Then Begin
        spechit_max := spechit_max * 2;
      End
      Else Begin
        spechit_max := MAXSPECIALCROSS;
      End;
      setlength(spechit, spechit_max);
    End;
    spechit[numspechit] := ld;
    numspechit := numspechit + 1;

    // fraggle: spechits overrun emulation code from prboom-plus
    If (numspechit > MAXSPECIALCROSS_ORIGINAL) Then Begin

      // [crispy] print a warning
      If (numspechit = MAXSPECIALCROSS_ORIGINAL + 1) Then Begin
        Writeln(stderr, 'PIT_CheckLine: Triggered SPECHITS overflow!');
      End;
      // SpechitOverrun(ld); // WTF: äh nee
    End;
  End;

  result := true;
End;

//
// PIT_CheckThing
//

Function PIT_CheckThing(thing: Pmobj_t): boolean;
Var
  blockdist: fixed_t;
  solid: boolean;
  unblocking: boolean;
  damage: int;
  thingheight: fixed_t;
  step_up: fixed_t;
  newdist: fixed_t;
  olddist: fixed_t;
Begin
  result := false;
  unblocking := false;

  If ((thing^.flags And (MF_SOLID Or MF_SPECIAL Or MF_SHOOTABLE)) = 0) Then Begin
    result := true;
    exit;
  End;
  blockdist := thing^.radius + tmthing^.radius;

  If (abs(thing^.x - tmx) >= blockdist)
    Or (abs(thing^.y - tmy) >= blockdist) Then Begin

    // didn't hit it
    result := true;
    exit;
  End;

  // don't clip against self
  If (thing = tmthing) Then Begin
    result := true;
    exit;
  End;

  // check for skulls slamming into things
  If (tmthing^.flags And MF_SKULLFLY) <> 0 Then Begin

    // [crispy] check if attacking skull flies over player
    If (critical^.overunder <> 0) And assigned(thing^.player) Then Begin

      If (tmthing^.z > thing^.z + thing^.height) Then Begin
        result := true;
        exit;
      End;
    End;

    damage := ((P_Random() Mod 8) + 1) * tmthing^.info^.damage;

    P_DamageMobj(thing, tmthing, tmthing, damage);

    tmthing^.flags := tmthing^.flags And Not MF_SKULLFLY;
    tmthing^.momx := 0;
    tmthing^.momy := 0;
    tmthing^.momz := 0;

    P_SetMobjState(tmthing, tmthing^.info^.spawnstate);

    exit; // stop moving
  End;

  // missiles can hit other things
  If (tmthing^.flags And MF_MISSILE) <> 0 Then Begin

    // [crispy] mobj or actual sprite height
    If assigned(tmthing^.target) And assigned(tmthing^.target^.player) And
      (critical^.freeaim = FREEAIM_DIRECT) Then Begin
      thingheight := thing^.info^.actualheight;
    End
    Else Begin
      thingheight := thing^.height;
    End;
    // see if it went over / under
    If (tmthing^.z > thing^.z + thingheight) Then Begin
      result := true; // overhead
      exit;
    End;
    If (tmthing^.z + tmthing^.height < thing^.z) Then Begin
      result := true; // underneath
      exit;
    End;
    If assigned(tmthing^.target) And
      ((tmthing^.target^._type = thing^._type) Or
      ((tmthing^.target^._type = MT_KNIGHT) And (thing^._type = MT_BRUISER)) Or
      ((tmthing^.target^._type = MT_BRUISER) And (thing^._type = MT_KNIGHT)))
      Then Begin
      // Don't hit same species as originator.
      If (thing = tmthing^.target) Then Begin
        result := true;
        exit;
      End;

      // sdh: Add deh_species_infighting here.  We can override the
      // "monsters of the same species cant hurt each other" behavior
      // through dehacked patches
      If (thing^._type <> MT_PLAYER) And (deh_species_infighting = 0) Then Begin
        // Explode, but do no damage.
        // Let players missile other players.
        exit;
      End;
    End;

    If ((thing^.flags And MF_SHOOTABLE) = 0) Then Begin
      // didn't do any damage
      result := (thing^.flags And MF_SOLID) = 0;
      exit;
    End;

    // damage / explode
    damage := ((P_Random() Mod 8) + 1) * tmthing^.info^.damage;
    P_DamageMobj(thing, tmthing, tmthing^.target, damage);
    // don't traverse any more
    exit;
  End;

  // check for special pickup
  If (thing^.flags And MF_SPECIAL) <> 0 Then Begin
    solid := (thing^.flags And MF_SOLID) <> 0;
    If (tmflags And MF_PICKUP) <> 0 Then Begin
      // can remove thing
      P_TouchSpecialThing(thing, tmthing);
    End;
    result := Not solid;
  End;

  If (critical^.overunder <> 0) Then Begin

    // [crispy] a solid hanging body will allow sufficiently small things underneath it
    If ((thing^.flags And MF_SOLID) <> 0) And ((thing^.flags And MF_SPAWNCEILING) <> 0) Then Begin
      If (tmthing^.z + tmthing^.height <= thing^.z) Then Begin
        If (thing^.z < tmceilingz) Then Begin
          tmceilingz := thing^.z;
        End;
        result := true;
        exit;
      End;
    End;

    // [crispy] allow players to walk over/under shootable objects
    If assigned(tmthing^.player) And ((thing^.flags And MF_SHOOTABLE) <> 0) Then Begin

      // [crispy] allow the usual 24 units step-up even across monsters' heads,
      // only if the current height has not been reached by "low" jumping
      If tmthing^.player^.jumpTics > 7 Then Begin
        step_up := 0;
      End
      Else Begin
        step_up := 24 * FRACUNIT;
      End;

      If (tmthing^.z + step_up >= thing^.z + thing^.height) Then Begin
        // player walks over object
        tmfloorz := MAX(thing^.z + thing^.height, tmfloorz);
        thing^.ceilingz := MIN(tmthing^.z, thing^.ceilingz);
        result := true;
        exit;
      End
      Else If (tmthing^.z + tmthing^.height <= thing^.z) Then Begin
        // player walks underneath object
        tmceilingz := MIN(thing^.z, tmceilingz);
        thing^.floorz := MAX(tmthing^.z + tmthing^.height, thing^.floorz);
        result := true;
        exit;
      End;

      // [crispy] check if things are stuck and allow them to move further apart
      // taken from doomretro/src/p_map.c:319-332
      If (tmx = tmthing^.x) And (tmy = tmthing^.y) Then Begin

        unblocking := true;
      End
      Else Begin
        newdist := P_AproxDistance(thing^.x - tmx, thing^.y - tmy);
        olddist := P_AproxDistance(thing^.x - tmthing^.x, thing^.y - tmthing^.y);

        If (newdist > olddist) Then Begin
          unblocking := (tmthing^.z < thing^.z + thing^.height)
            And (tmthing^.z + tmthing^.height > thing^.z);
        End;
      End;
    End;
  End;

  result := ((thing^.flags And MF_SOLID) = 0) Or unblocking;
End;

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
  result := false;
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

  For bx := xl To xh Do Begin
    For by := yl To yh Do Begin
      If (Not P_BlockThingsIterator(bx, by, @PIT_CheckThing)) Then Begin
        exit;
      End;
    End;
  End;

  // check lines
  xl := SarLongint(tmbbox[BOXLEFT] - bmaporgx, MAPBLOCKSHIFT);
  xh := SarLongint(tmbbox[BOXRIGHT] - bmaporgx, MAPBLOCKSHIFT);
  yl := SarLongint(tmbbox[BOXBOTTOM] - bmaporgy, MAPBLOCKSHIFT);
  yh := SarLongint(tmbbox[BOXTOP] - bmaporgy, MAPBLOCKSHIFT);

  For bx := xl To xh Do Begin
    For by := yl To yh Do Begin
      If (Not P_BlockLinesIterator(bx, by, @PIT_CheckLine)) Then Begin
        exit;
      End;
    End;
  End;

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

    If (fixed_t(tmceilingz - tmfloorz) < thing^.height) Then exit; // doesn't fit

    floatok := true;

    If ((thing^.flags And MF_TELEPORT) = 0)
      And ((tmceilingz - thing^.z) < thing^.height) Then
      exit; // mobj must lower itself to fit

    If ((thing^.flags And MF_TELEPORT) = 0)
      And (fixed_t(tmfloorz - thing^.z) > 24 * FRACUNIT) Then
      exit; // too big a step up

    If ((thing^.flags And (MF_DROPOFF Or MF_FLOAT)) = 0)
      And (fixed_t(tmfloorz - tmdropoffz) > 24 * FRACUNIT) Then
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

    While (numspechit > 0) Do Begin
      numspechit := numspechit - 1;
      // see if the line was crossed
      ld := spechit[numspechit];
      side := P_PointOnLineSide(thing^.x, thing^.y, ld);
      oldside := P_PointOnLineSide(oldx, oldy, ld);
      If (side <> oldside) Then Begin
        If (ld^.special <> 0) Then Begin
          P_CrossSpecialLine((ptrint(ld) - ptrint(@lines[0])) Div sizeof(lines[0]), oldside, thing);
        End;
      End;
    End;
  End;
  result := true;
End;

//
// PTR_SlideTraverse
//

Function PTR_SlideTraverse(_in: Pintercept_t): boolean;
Label
  isblocking;
Var
  li: Pline_t;
Begin

  If (Not _in^.isaline) Then Begin
    I_Error('PTR_SlideTraverse: not a line?');
  End;

  li := _in^.d.line;

  If ((li^.flags And ML_TWOSIDED)) = 0 Then Begin
    If (P_PointOnLineSide(slidemo^.x, slidemo^.y, li) <> 0) Then Begin
      // don't hit the back side
      result := true;
      exit;
    End;
    Goto isblocking;
  End;

  // set openrange, opentop, openbottom
  P_LineOpening(li);

  If (openrange < slidemo^.height) Then
    Goto isblocking; // doesn't fit

  If (opentop - slidemo^.z < slidemo^.height) Then
    Goto isblocking; // mobj is too high

  If (openbottom - slidemo^.z > 24 * FRACUNIT) Then
    Goto isblocking; // too big a step up

  // this line doesn't block movement
  result := true;
  exit;

  // the line does block movement,
  // see if it is closer than best so far
  isblocking:
  If (_in^.frac < bestslidefrac) Then Begin
    secondslidefrac := bestslidefrac;
    secondslideline := bestslideline;
    bestslidefrac := _in^.frac;
    bestslideline := li;
  End;
  result := false; // stop
End;

//
// P_HitSlideLine
// Adjusts the xmove / ymove
// so that the next move will slide along the wall.
//

Procedure P_HitSlideLine(ld: Pline_t);
Var
  side: int;
  lineangle, moveangle, deltaangle: angle_t;
  movelen: fixed_t;
  newlen: fixed_t;
Begin
  If (ld^.slopetype = ST_HORIZONTAL) Then Begin
    tmymove := 0;
    exit;
  End;

  If (ld^.slopetype = ST_VERTICAL) Then Begin
    tmxmove := 0;
    exit;
  End;

  side := P_PointOnLineSide(slidemo^.x, slidemo^.y, ld);

  lineangle := R_PointToAngle2(0, 0, ld^.dx, ld^.dy);

  If (side = 1) Then
    lineangle := angle_t(lineangle + ANG180);

  moveangle := R_PointToAngle2(0, 0, tmxmove, tmymove);
  deltaangle := angle_t(moveangle - lineangle);

  If (deltaangle > ANG180) Then
    deltaangle := angle_t(deltaangle + ANG180);
  // I_Error('SlideLine: ang>ANG180');

  lineangle := lineangle Shr ANGLETOFINESHIFT;
  deltaangle := deltaangle Shr ANGLETOFINESHIFT;

  movelen := P_AproxDistance(tmxmove, tmymove);
  newlen := FixedMul(movelen, finecosine[deltaangle]);

  tmxmove := FixedMul(newlen, finecosine[lineangle]);
  tmymove := FixedMul(newlen, finesine[lineangle]);
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
Label
  retry;
Label
  stairstep;
Var
  leadx, leady,
    trailx, traily,
    newx, newy: fixed_t;
  hitcount: int;
Begin

  slidemo := mo;
  hitcount := 0;

  retry:
  hitcount := hitcount + 1;
  If (hitcount = 3) Then
    Goto stairstep; // don't loop forever

  // trace along the three leading corners
  If (mo^.momx > 0) Then Begin
    leadx := mo^.x + mo^.radius;
    trailx := mo^.x - mo^.radius;
  End
  Else Begin
    leadx := mo^.x - mo^.radius;
    trailx := mo^.x + mo^.radius;
  End;

  If (mo^.momy > 0) Then Begin
    leady := mo^.y + mo^.radius;
    traily := mo^.y - mo^.radius;
  End
  Else Begin
    leady := mo^.y - mo^.radius;
    traily := mo^.y + mo^.radius;
  End;

  bestslidefrac := FRACUNIT + 1;

  P_PathTraverse(leadx, leady, leadx + mo^.momx, leady + mo^.momy,
    PT_ADDLINES, @PTR_SlideTraverse);
  P_PathTraverse(trailx, leady, trailx + mo^.momx, leady + mo^.momy,
    PT_ADDLINES, @PTR_SlideTraverse);
  P_PathTraverse(leadx, traily, leadx + mo^.momx, traily + mo^.momy,
    PT_ADDLINES, @PTR_SlideTraverse);

  // move up to the wall
  If (bestslidefrac = FRACUNIT + 1) Then Begin
    // the move most have hit the middle, so stairstep
    stairstep:
    If (Not P_TryMove(mo, mo^.x, mo^.y + mo^.momy)) Then
      P_TryMove(mo, mo^.x + mo^.momx, mo^.y);
    exit;
  End;

  // fudge a bit to make sure it doesn't hit
  bestslidefrac := bestslidefrac - $800;
  If (bestslidefrac > 0) Then Begin
    newx := FixedMul(mo^.momx, bestslidefrac);
    newy := FixedMul(mo^.momy, bestslidefrac);
    If (Not P_TryMove(mo, mo^.x + newx, mo^.y + newy)) Then
      Goto stairstep;
  End;

  // Now continue along the wall.
  // First calculate remainder.
  bestslidefrac := FRACUNIT - (bestslidefrac + $800);

  If (bestslidefrac > FRACUNIT) Then
    bestslidefrac := FRACUNIT;

  If (bestslidefrac <= 0) Then
    exit;

  tmxmove := FixedMul(mo^.momx, bestslidefrac);
  tmymove := FixedMul(mo^.momy, bestslidefrac);

  P_HitSlideLine(bestslideline); // clip the moves

  mo^.momx := tmxmove;
  mo^.momy := tmymove;

  If (Not P_TryMove(mo, mo^.x + tmxmove, mo^.y + tmymove)) Then Begin
    Goto retry;
  End;
End;

//
// P_ThingHeightClip
// Takes a valid thing and adjusts the thing->floorz,
// thing->ceilingz, and possibly thing->z.
// This is called for all nearby monsters
// whenever a sector changes height.
// If the thing doesn't fit,
// the z will be set to the lowest value
// and false will be returned.
//

Function P_ThingHeightClip(thing: Pmobj_t): boolean;
Var
  onfloor: boolean;
Begin
  onfloor := (thing^.z = thing^.floorz);

  P_CheckPosition(thing, thing^.x, thing^.y);
  // what about stranding a monster partially off an edge?

  thing^.floorz := tmfloorz;
  thing^.ceilingz := tmceilingz;

  If (onfloor) Then Begin

    // walking monsters rise and fall with the floor
    thing^.z := thing^.floorz;
  End
  Else Begin
    // don't adjust a floating monster unless forced to
    If (thing^.z + thing^.height > thing^.ceilingz) Then
      thing^.z := thing^.ceilingz - thing^.height;
  End;

  If (thing^.ceilingz - thing^.floorz < thing^.height) Then Begin
    result := false;
    exit;
  End;

  result := true;
End;

//
// PIT_ChangeSector
//

Function PIT_ChangeSector(thing: Pmobj_t): boolean;
Var
  mo: pmobj_t;
Begin
  If (P_ThingHeightClip(thing)) Then Begin
    // keep checking
    result := true;
    exit;
  End;

  // crunch bodies to giblets
  If (thing^.health <= 0) Then Begin
    P_SetMobjState(thing, S_GIBS);

    // [crispy] no blood, no giblets
    If (thing^.flags And MF_NOBLOOD) <> 0 Then
      thing^.sprite := SPR_TNT1;

    If (gameversion > exe_doom_1_2) Then
      thing^.flags := thing^.flags And Not MF_SOLID;
    thing^.height := 0;
    thing^.radius := 0;

    // [crispy] connect giblet object with the crushed monster
    thing^.target := thing;

    // keep checking
    result := true;
    exit;
  End;

  // crunch dropped items
  If (thing^.flags And MF_DROPPED) <> 0 Then Begin
    P_RemoveMobj(thing);
    // keep checking
    result := true;
    exit;
  End;

  If ((thing^.flags And MF_SHOOTABLE) = 0) Then Begin
    // assume it is bloody gibs or something
    result := true;
    exit;
  End;

  nofit := true;

  If (crushchange And ((leveltime And 3) = 0)) Then Begin

    P_DamageMobj(thing, Nil, Nil, 10);

    // spray blood in a random direction
    If (thing^.flags And MF_NOBLOOD) <> 0 Then Begin
      mo := P_SpawnMobj(thing^.x,
        thing^.y,
        // [crispy] no blood, no.. well.. blood
        thing^.z + thing^.height Div 2, MT_PUFF);
    End
    Else Begin
      mo := P_SpawnMobj(thing^.x,
        thing^.y,
        // [crispy] no blood, no.. well.. blood
        thing^.z + thing^.height Div 2, MT_BLOOD);
    End;

    mo^.momx := P_SubRandom() Shl 12;
    mo^.momy := P_SubRandom() Shl 12;

    // [crispy] connect blood object with the monster that bleeds it
    mo^.target := thing;

    // [crispy] Spectres bleed spectre blood
    If (crispy.coloredblood = COLOREDBLOOD_ALL) Then
      mo^.flags := mo^.flags Or (thing^.flags And MF_SHADOW);
  End;

  // keep checking (crush other things)
  result := true;
End;

Function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;
Var
  x: int;
  y: int;
Begin
  nofit := false;
  crushchange := crunch;
  // re-check heights for all things near the moving sector
  For x := sector^.blockbox[BOXLEFT] To sector^.blockbox[BOXRIGHT] Do Begin
    For y := sector^.blockbox[BOXBOTTOM] To sector^.blockbox[BOXTOP] Do Begin
      P_BlockThingsIterator(x, y, @PIT_ChangeSector);
    End;
  End;
  result := nofit;
End;

End.

