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

Procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; damage: int);

// [crispy] update laser spot position
// call P_AimLineAttack() to check if a target is aimed at (linetarget)
// then call P_LineAttack() with either aimslope or the passed slope
Procedure P_LineLaser(t1: pmobj_t; angle: angle_t; distance: fixed_t; slope: fixed_t);

Procedure P_LineAttack(t1: pmobj_t; angle: angle_t; distance: fixed_t; slope: fixed_t; damage: int);

Implementation

Uses
  doomdata
  , i_video
  , p_sight, p_maputl, p_local, p_mobj, p_spec, p_setup
  , r_things, r_main, r_sky
  ;

Var
  shootthing: Pmobj_t;
  // Height if not aiming up or down
  // ???: use slope for monsters?
  shootz: fixed_t;

  la_damage: int;
  attackrange: fixed_t;
  aimslope: fixed_t;

  // Certain functions assume that a mobj_t pointer is non-NULL,
  // causing a crash in some situations where it is NULL.  Vanilla
  // Doom did not crash because of the lack of proper memory
  // protection. This function substitutes NULL pointers for
  // pointers to a dummy mobj, to avoid a crash.
Var
  dummy_mobj: mobj_t;

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
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//

Procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; damage: int);
Begin
  //   int		x;
  //    int		y;
  //
  //    int		xl;
  //    int		xh;
  //    int		yl;
  //    int		yh;
  //
  //    fixed_t	dist;
  //
  //    dist = (damage+MAXRADIUS)<<FRACBITS;
  //    yh = (spot->y + dist - bmaporgy)>>MAPBLOCKSHIFT;
  //    yl = (spot->y - dist - bmaporgy)>>MAPBLOCKSHIFT;
  //    xh = (spot->x + dist - bmaporgx)>>MAPBLOCKSHIFT;
  //    xl = (spot->x - dist - bmaporgx)>>MAPBLOCKSHIFT;
  //    bombspot = spot;
  //    bombsource = source;
  //    bombdamage = damage;
  //
  //    for (y=yl ; y<=yh ; y++)
  //	for (x=xl ; x<=xh ; x++)
  //	    P_BlockThingsIterator (x, y, PIT_RadiusAttack );
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

  //    if (!(th^.flags&MF_SHOOTABLE))
  //	return true;		// corpse or something
  //
  //    // check angles to see if the thing can be aimed at
  //    dist = FixedMul (attackrange, in^.frac);
  //    // [crispy] mobj or actual sprite height
  //    thingheight = (shootthing^.player && critical^.freeaim == FREEAIM_DIRECT) ?
  //                  th^.info^.actualheight : th^.height;
  //    thingtopslope = FixedDiv (th^.z+thingheight - shootz , dist);
  //
  //    if (thingtopslope < aimslope)
  //	return true;		// shot over the thing
  //
  //    thingbottomslope = FixedDiv (th^.z - shootz, dist);
  //
  //    if (thingbottomslope > aimslope)
  //	return true;		// shot under the thing
  //
  //
  //    // hit thing
  //    // position a bit closer
  //    frac = in^.frac - FixedDiv (10*FRACUNIT,attackrange);
  //
  //    x = trace.x + FixedMul (trace.dx, frac);
  //    y = trace.y + FixedMul (trace.dy, frac);
  //    z = shootz + FixedMul (aimslope, FixedMul(frac, attackrange));
  //
  //    // [crispy] update laser spot position and return
  //    if (la_damage == INT_MIN)
  //    {
  //	// [crispy] pass through Spectres
  //	if (th^.flags & MF_SHADOW)
  //	    return true;
  //
  //	laserspot^.thinker.function.acv = (actionf_v) (1);
  //	laserspot^.x = th^.x;
  //	laserspot^.y = th^.y;
  //	laserspot^.z = z;
  //	return false;
  //    }
  //
  //    // Spawn bullet puffs or blod spots,
  //    // depending on target type.
  //    if (in^.d.thing^.flags & MF_NOBLOOD)
  //	P_SpawnPuff (x,y,z);
  //    else
  //	P_SpawnBlood (x,y,z, la_damage, th); // [crispy] pass thing type
  //
  //    if (la_damage)
  //	P_DamageMobj (th, shootthing, shootthing, la_damage);

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

End.

