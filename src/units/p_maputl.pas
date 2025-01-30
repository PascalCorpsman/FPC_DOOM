Unit p_maputl;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , m_fixed
  , p_local
  ;

Var
  opentop: fixed_t;
  openbottom: fixed_t;
  openrange: fixed_t;
  lowfloor: fixed_t;
  trace: divline_t;


Function P_PathTraverse(x1, y1, x2, y2: fixed_t; flags: int; trav: traverser_t): boolean;

Procedure P_LineOpening(linedef: Pline_t);
Function P_PointOnLineSide(x, y: fixed_t; line: Pline_t): int;
Procedure P_UnsetThingPosition(thing: Pmobj_t);
Procedure P_SetThingPosition(thing: pmobj_t);

Implementation

Uses
  doomdata
  , p_mobj, p_setup
  , r_main
  ;

Type
  TLineInterceptFunction = Function(ld: Pline_t): Boolean;
  TBlockThingIteratorFunction = Function(obj: Pmobj_t): Boolean;

Var
  earlyout: boolean;
  ptflags: int;

  intercept_p: integer; // = Anzahl der Bereits genutzten Elemente in intercepts
  intercepts: Array Of intercept_t = Nil;

  // [crispy] remove INTERCEPTS limit
  // taken from PrBoom+/src/p_maputl.c:422-433
  // Sorgt dafür, dass noch mindestens 1 Element in Intercepts genutzt werden kann ;)

Procedure check_intercept();
Begin
  If intercept_p + 1 > high(intercepts) Then Begin
    setlength(intercepts, length(intercepts) + MAXINTERCEPTS_ORIGINAL);
  End;
End;

//
// P_SetThingPosition
// Links a thing into both a block and a subsector
// based on it's x y.
// Sets thing->subsector properly
//

Procedure P_SetThingPosition(thing: pmobj_t);
Var
  ss: Psubsector_t;
  sec: ^sector_t;
  blockx, blocky: int;
  link: PPmobj_t;
Begin

  // link into subsector
  ss := R_PointInSubsector(thing^.x, thing^.y);
  thing^.subsector := ss;

  If ((thing^.flags And MF_NOSECTOR) = 0) Then Begin

    // invisible things don't go into the sector links
    sec := ss^.sector;

    thing^.sprev := Nil;
    thing^.snext := sec^.thinglist;

    If assigned(sec^.thinglist) Then Begin
      sec^.thinglist^.sprev := thing;
    End;
    sec^.thinglist := thing;
  End;

  // link into blockmap
  If ((thing^.flags And MF_NOBLOCKMAP) = 0) Then Begin
    // inert things don't need to be in blockmap
    blockx := SarLongint(thing^.x - bmaporgx, MAPBLOCKSHIFT);
    blocky := SarLongint(thing^.y - bmaporgy, MAPBLOCKSHIFT);

    If (blockx >= 0)
      And (blockx < bmapwidth)
      And (blocky >= 0)
      And (blocky < bmapheight) Then Begin
      link := @blocklinks[blocky * bmapwidth + blockx];
      thing^.bprev := Nil;
      thing^.bnext := link^;
      If assigned(link^) Then Begin
        (link^)^.bprev := thing;
      End;
      link^ := thing;
    End
    Else Begin
      // thing is off the map
      thing^.bnext := Nil;
      thing^.bprev := Nil;
    End;
  End;
End;

//
// P_BlockLinesIterator
// The validcount flags are used to avoid checking lines
// that are marked in multiple mapblocks,
// so increment validcount before the first call
// to P_BlockLinesIterator, then make one or more calls
// to it.
//

Function P_BlockLinesIterator(x, y: int; func: TLineInterceptFunction): boolean;
Var
  offset: int;
  list: ^int32_t; // [crispy] BLOCKMAP limit
  ld: ^line_t;
Begin

  If (x < 0)
    Or (y < 0)
    Or (x >= bmapwidth)
    Or (y >= bmapheight)
    Then Begin
    result := true;
    exit;
  End;

  offset := y * bmapwidth + x;

  offset := blockmap[offset];

  list := @blockmaplump[offset];
  While list^ <> -1 Do Begin
    ld := @lines[list^];

    If (ld^.validcount = validcount) Then Begin
      inc(list);
      continue; // line has already been checked
    End;

    ld^.validcount := validcount;

    If (Not func(ld)) Then Begin
      result := false;
      exit;
    End;
    inc(list);
  End;
  result := true; // everything was checked
End;

//
// P_BlockThingsIterator
//

Function P_BlockThingsIterator(x, y: int; func: TBlockThingIteratorFunction): boolean;
Var
  mobj: ^mobj_t;
Begin

  If (x < 0)
    Or (y < 0)
    Or (x >= bmapwidth)
    Or (y >= bmapheight) Then Begin
    result := true;
    exit;
  End;

  // LINKED_LIST_CHECK_NO_CYCLE(mobj_t, blocklinks[y*bmapwidth+x], bnext);

  mobj := blocklinks[y * bmapwidth + x];
  While assigned(mobj) Do Begin
    If Not (func(mobj)) Then Begin
      result := false;
      exit;
    End;
    mobj := mobj^.bnext;
  End;
  result := true;
End;

//
// P_PointOnDivlineSide
// Returns 0 or 1.
//

Function P_PointOnDivlineSide(x, y: fixed_t; line: Pdivline_t): int;
Var
  dx, dy, left, right: fixed_t;
Begin
  If (line^.dx = 0) Then Begin
    If (x <= line^.x) Then Begin
      result := ord(line^.dy > 0);
      exit;
    End;

    result := ord(line^.dy < 0);
    exit;
  End;
  If (line^.dy = 0) Then Begin
    If (y <= line^.y) Then Begin
      result := ord(line^.dx < 0);
      exit;
    End;
    result := ord(line^.dx > 0);
    exit;
  End;

  dx := (x - line^.x);
  dy := (y - line^.y);

  // try to quickly decide by looking at sign bits
  If ((line^.dy Xor line^.dx Xor dx Xor dy) And $80000000) <> 0 Then Begin
    If ((line^.dy Xor dx) And $80000000) <> 0 Then Begin
      result := 1; // (left is negative)
      exit;
    End;
    result := 0;
    exit;
  End;

  left := FixedMul(SarLongint(line^.dy, 8), SarLongint(dx, 8));
  right := FixedMul(SarLongint(dy, 8), SarLongint(line^.dx, 8));

  If (right < left) Then Begin
    result := 0; // front side
    exit;
  End;
  result := 1; // back side
End;

//
// P_PointOnLineSide
// Returns 0 or 1
//

Function P_PointOnLineSide(x, y: fixed_t; line: Pline_t): int;
Var
  dx, dy, left, right: fixed_t;
Begin
  If (line^.dx = 0) Then Begin
    If (x <= line^.v1^.x) Then Begin
      result := ord(line^.dy > 0);
      exit;
    End;
    result := ord(line^.dy < 0);
    exit;
  End;

  If (line^.dy = 0) Then Begin
    If (y <= line^.v1^.y) Then Begin
      result := ord(line^.dx < 0);
      exit;
    End;
    result := ord(line^.dx > 0);
    exit;
  End;

  dx := (x - line^.v1^.x);
  dy := (y - line^.v1^.y);

  left := FixedMul(SarLongint(line^.dy, FRACBITS), dx);
  right := FixedMul(dy, SarLongint(line^.dx, FRACBITS));

  If (right < left) Then Begin
    result := 0; // front side
    exit;
  End;
  result := 1; // back side
End;

//
// P_UnsetThingPosition
// Unlinks a thing from block map and sectors.
// On each position change, BLOCKMAP and other
// lookups maintaining lists of things inside
// these structures need to be updated.
//

Procedure P_UnsetThingPosition(thing: Pmobj_t);
Var
  blockx, blocky: int;
Begin
  If ((thing^.flags And MF_NOSECTOR) = 0) Then Begin
    // inert things don't need to be in blockmap?
    // unlink from subsector
    If assigned(thing^.snext) Then
      thing^.snext^.sprev := thing^.sprev;

    If assigned(thing^.sprev) Then
      thing^.sprev^.snext := thing^.snext
    Else
      thing^.subsector^.sector^.thinglist := thing^.snext;
  End;

  If ((thing^.flags And MF_NOBLOCKMAP) = 0) Then Begin
    // inert things don't need to be in blockmap
    // unlink from block map
    If assigned(thing^.bnext) Then
      thing^.bnext^.bprev := thing^.bprev;

    If assigned(thing^.bprev) Then
      thing^.bprev^.bnext := thing^.bnext
    Else Begin
      blockx := SarLongint(thing^.x - bmaporgx, MAPBLOCKSHIFT);
      blocky := SarLongint(thing^.y - bmaporgy, MAPBLOCKSHIFT);
      If (blockx >= 0) And (blockx < bmapwidth)
        And (blocky >= 0) And (blocky < bmapheight) Then Begin
        blocklinks[blocky * bmapwidth + blockx] := thing^.bnext;
      End;
    End;
  End;
End;

//
// P_MakeDivline
//

Procedure P_MakeDivline(li: pline_t; dl: pdivline_t);
Begin
  dl^.x := li^.v1^.x;
  dl^.y := li^.v1^.y;
  dl^.dx := li^.dx;
  dl^.dy := li^.dy;
End;

//
// P_InterceptVector
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings
// and addlines traversers.
//

Function P_InterceptVector(v2: Pdivline_t; v1: Pdivline_t): fixed_t;
Var
  frac,
    num,
    den: fixed_t;

Begin
  //#if 1
  den := FixedMul(SarLongint(v1^.dy, 8), v2^.dx) - FixedMul(SarLongint(v1^.dx, 8), v2^.dy);

  If (den = 0) Then Begin
    result := 0;
    exit;
  End;
  //	I_Error ('P_InterceptVector: parallel');
  num :=
    FixedMul(SarLongint(v1^.x - v2^.x, 8), v1^.dy)
    + FixedMul(SarLongint(v2^.y - v1^.y, 8), v1^.dx);

  frac := FixedDiv(num, den);

  result := frac;
End;

//
// PIT_AddLineIntercepts.
// Looks for lines in the given block
// that intercept the given trace
// to add to the intercepts list.
//
// A line is crossed if its endpoints
// are on opposite sides of the trace.
// Returns true if earlyout and a solid line hit.
//

Function PIT_AddLineIntercepts(ld: Pline_t): boolean;
Var
  s1, s2: int;
  frac: fixed_t;
  dl: divline_t;
Begin
  // avoid precision problems with two routines
  If (trace.dx > FRACUNIT * 16)
    Or (trace.dy > FRACUNIT * 16)
    Or (trace.dx < -FRACUNIT * 16)
    Or (trace.dy < -FRACUNIT * 16) Then Begin

    s1 := P_PointOnDivlineSide(ld^.v1^.x, ld^.v1^.y, @trace);
    s2 := P_PointOnDivlineSide(ld^.v2^.x, ld^.v2^.y, @trace);
  End
  Else Begin
    s1 := P_PointOnLineSide(trace.x, trace.y, ld);
    s2 := P_PointOnLineSide(trace.x + trace.dx, trace.y + trace.dy, ld);
  End;

  If (s1 = s2) Then Begin
    result := true; // line isn't crossed
    exit;
  End;

  // hit the line
  P_MakeDivline(ld, @dl);
  frac := P_InterceptVector(@trace, @dl);

  If (frac < 0) Then Begin
    result := true; // behind source
    exit;
  End;

  // try to early out the check
  If (earlyout)
    And (frac < FRACUNIT)
    And (ld^.backsector = Nil)
    Then Begin
    result := false; // stop checking
    exit;
  End;


  check_intercept(); // [crispy] remove INTERCEPTS limit
  intercepts[intercept_p].frac := frac;
  intercepts[intercept_p].isaline := true;
  intercepts[intercept_p].d.line := ld;
  // InterceptsOverrun(intercept_p - intercepts, intercept_p); // WTF: äh ne, das wird nicht portiert..
  // [crispy] intercepts overflow guard
  If (intercept_p = MAXINTERCEPTS_ORIGINAL + 1) Then Begin
    If (crispy.crosshair And CROSSHAIR_INTERCEPT) <> 0 Then Begin
      result := false;
      exit;
    End
    Else Begin
      // [crispy] print a warning
      writeln(stderr, 'PIT_AddLineIntercepts: Triggered INTERCEPTS overflow!');
    End;
  End;
  intercept_p := intercept_p + 1;
  result := true; // continue
End;

//
// PIT_AddThingIntercepts
//

Function PIT_AddThingIntercepts(thing: Pmobj_t): boolean;
Var
  x1, y1, x2, y2: fixed_t;
  s1, s2: int;
  tracepositive: boolean;
  dl: divline_t;
  frac: fixed_t;
Begin
  tracepositive := (trace.dx Xor trace.dy) > 0;

  // check a corner to corner crossection for hit
  If (tracepositive) Then Begin
    x1 := thing^.x - thing^.radius;
    y1 := thing^.y + thing^.radius;

    x2 := thing^.x + thing^.radius;
    y2 := thing^.y - thing^.radius;
  End
  Else Begin
    x1 := thing^.x - thing^.radius;
    y1 := thing^.y - thing^.radius;

    x2 := thing^.x + thing^.radius;
    y2 := thing^.y + thing^.radius;
  End;

  s1 := P_PointOnDivlineSide(x1, y1, @trace);
  s2 := P_PointOnDivlineSide(x2, y2, @trace);

  If (s1 = s2) Then Begin
    result := true; // line isn't crossed
    exit;
  End;

  dl.x := x1;
  dl.y := y1;
  dl.dx := x2 - x1;
  dl.dy := y2 - y1;

  frac := P_InterceptVector(@trace, @dl);

  If (frac < 0) Then Begin
    result := true; // behind source
    exit;
  End;

  check_intercept(); // [crispy] remove INTERCEPTS limit
  intercepts[intercept_p].frac := frac;
  intercepts[intercept_p].isaline := false;
  intercepts[intercept_p].d.thing := thing;
  // InterceptsOverrun(intercept_p - intercepts, intercept_p); // WTF: äh ne, das wird nicht portiert..
  // [crispy] intercepts overflow guard
  If (intercept_p = MAXINTERCEPTS_ORIGINAL + 1) Then Begin

    If (crispy.crosshair And CROSSHAIR_INTERCEPT) <> 0 Then Begin
      result := false;
      exit;
    End
    Else Begin
      // [crispy] print a warning
      writeln(stderr, 'PIT_AddThingIntercepts: Triggered INTERCEPTS overflow!');
    End;
  End;
  intercept_p := intercept_p + 1;
  result := true; // keep going
End;

//
// P_TraverseIntercepts
// Returns true if the traverser function returns true
// for all lines.
//

Function P_TraverseIntercepts(func: traverser_t; maxfrac: fixed_t): boolean;
Var
  count: int;
  dist: fixed_t;
  _in: int;
  scan: Integer;
Begin
  _in := -1; // shut up compiler warning
  For count := intercept_p - 1 Downto 0 Do Begin

    dist := INT_MAX;
    For scan := 0 To intercept_p - 1 Do Begin
      If (intercepts[scan].frac < dist) Then Begin
        dist := intercepts[scan].frac;
        _in := scan;
      End;
    End;

    If (dist > maxfrac) Then Begin
      result := true; // checked everything in range
      exit;
    End;

    //#if 0  // UNUSED
    //    {
    //	// don't check these yet, there may be others inserted
    //	in = scan = intercepts;
    //	for ( scan = intercepts ; scan<intercept_p ; scan++)
    //	    if (scan->frac > maxfrac)
    //		*in++ = *scan;
    //	intercept_p = in;
    //	return false;
    //    }
    //#endif

    If (Not func(@intercepts[_in])) Then Begin
      result := false; // don't bother going farther
      exit;
    End;
    intercepts[_in].frac := INT_MAX;
  End;

  result := true; // everything was traversed
End;

//
// PTR_AimTraverse
// Sets linetaget and aimslope when a target is aimed at.
//

Function P_PathTraverse(x1, y1, x2, y2: fixed_t; flags: int; trav: traverser_t
  ): boolean;
Var
  xt1,
    yt1,
    xt2,
    yt2,
    xstep,
    ystep,
    partial,
    xintercept,
    yintercept: fixed_t;

  mapx,
    mapy,
    mapxstep,
    mapystep,
    count: int;

Begin
  earlyout := (flags And PT_EARLYOUT) <> 0;

  validcount := validcount + 1;
  intercept_p := 0;

  If (((x1 - bmaporgx) And (MAPBLOCKSIZE - 1)) = 0) Then
    x1 := x1 + FRACUNIT; // don't side exactly on a line

  If (((y1 - bmaporgy) And (MAPBLOCKSIZE - 1)) = 0) Then
    y1 := y1 + FRACUNIT; // don't side exactly on a line

  trace.x := x1;
  trace.y := y1;
  trace.dx := x2 - x1;
  trace.dy := y2 - y1;

  x1 := x1 - bmaporgx;
  y1 := y1 - bmaporgy;
  xt1 := SarLongint(x1, MAPBLOCKSHIFT);
  yt1 := SarLongint(y1, MAPBLOCKSHIFT);

  x2 := x2 - bmaporgx;
  y2 := y2 - bmaporgy;
  xt2 := SarLongint(x2, MAPBLOCKSHIFT);
  yt2 := SarLongint(y2, MAPBLOCKSHIFT);

  If (xt2 > xt1) Then Begin
    mapxstep := 1;
    partial := FRACUNIT - (SarLongint(x1, MAPBTOFRAC) And (FRACUNIT - 1));
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  End
  Else If (xt2 < xt1) Then Begin
    mapxstep := -1;
    partial := SarLongint(x1, MAPBTOFRAC) And (FRACUNIT - 1);
    ystep := FixedDiv(y2 - y1, abs(x2 - x1));
  End
  Else Begin
    mapxstep := 0;
    partial := FRACUNIT;
    ystep := 256 * FRACUNIT;
  End;

  yintercept := SarLongint(y1, MAPBTOFRAC) + FixedMul(partial, ystep);

  If (yt2 > yt1) Then Begin
    mapystep := 1;
    partial := FRACUNIT - (SarLongint(y1, MAPBTOFRAC) And (FRACUNIT - 1));
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  End
  Else If (yt2 < yt1) Then Begin
    mapystep := -1;
    partial := SarLongint(y1, MAPBTOFRAC) And (FRACUNIT - 1);
    xstep := FixedDiv(x2 - x1, abs(y2 - y1));
  End
  Else Begin
    mapystep := 0;
    partial := FRACUNIT;
    xstep := 256 * FRACUNIT;
  End;
  xintercept := SarLongint(x1, MAPBTOFRAC) + FixedMul(partial, xstep);

  // Step through map blocks.
  // Count is present to prevent a round off error
  // from skipping the break.
  mapx := xt1;
  mapy := yt1;

  For count := 0 To 63 Do Begin

    If (flags And PT_ADDLINES) <> 0 Then Begin
      If (Not P_BlockLinesIterator(mapx, mapy, @PIT_AddLineIntercepts)) Then Begin
        result := false; // early out
        exit;
      End;
    End;

    If (flags And PT_ADDTHINGS) <> 0 Then Begin
      If (Not P_BlockThingsIterator(mapx, mapy, @PIT_AddThingIntercepts)) Then Begin
        result := false; // early out
        exit;
      End;
    End;

    If (mapx = xt2) And (mapy = yt2) Then Begin
      break;
    End;

    If (SarLongint(yintercept, FRACBITS) = mapy) Then Begin
      yintercept := yintercept + ystep;
      mapx := mapx + mapxstep;
    End
    Else If (SarLongint(xintercept, FRACBITS) = mapx) Then Begin
      xintercept := xintercept + xstep;
      mapy := mapy + mapystep;
    End;
  End;
  // go through the sorted list
  result := P_TraverseIntercepts(trav, FRACUNIT);
End;

//
// P_LineOpening
// Sets opentop and openbottom to the window
// through a two sided line.
// OPTIMIZE: keep this precalculated
//

Procedure P_LineOpening(linedef: Pline_t);
Var
  front: ^sector_t;
  back: ^sector_t;
Begin
  If (linedef^.sidenum[1] = NO_INDEX) Then Begin // [crispy] extended nodes
    // single sided line
    openrange := 0;
    exit;
  End;

  front := linedef^.frontsector;
  back := linedef^.backsector;

  If (front^.ceilingheight < back^.ceilingheight) Then
    opentop := front^.ceilingheight
  Else
    opentop := back^.ceilingheight;

  If (front^.floorheight > back^.floorheight) Then Begin
    openbottom := front^.floorheight;
    lowfloor := back^.floorheight;
  End
  Else Begin
    openbottom := back^.floorheight;
    lowfloor := front^.floorheight;
  End;

  openrange := opentop - openbottom;
End;

End.

