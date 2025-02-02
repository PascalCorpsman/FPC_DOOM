Unit p_sight;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , m_fixed
  ;

Var
  topslope: fixed_t;
  bottomslope: fixed_t; // slopes to top and bottom of target

Function P_CheckSight(t1: Pmobj_t; t2: Pmobj_t): boolean;

Implementation

Uses
  doomstat, doomdata
  , d_mode
  , p_setup, p_local, p_maputl
  , r_main, r_defs
  ;

Var

  sightzstart: fixed_t; // eye z of looker

  strace: divline_t; // from t1 to t2
  t2x: fixed_t;
  t2y: fixed_t;

  sightcounts: Array[0..1] Of int = ((0), (0));



  // PTR_SightTraverse() for Doom 1.2 sight calculations
  // taken from prboom-plus/src/p_sight.c:69-102

Function PTR_SightTraverse(_in: Pintercept_t): boolean;
Var
  li: Pline_t;
  slope: fixed_t;

Begin
  result := false;
  li := _in^.d.line;

  //
  // crosses a two sided line
  //
  P_LineOpening(li);

  If (openbottom >= opentop) Then Begin // quick test for totally closed doors
    exit; // stop
  End;

  If (li^.frontsector^.floorheight <> li^.backsector^.floorheight) Then Begin

    slope := FixedDiv(openbottom - sightzstart, _in^.frac);
    If (slope > bottomslope) Then
      bottomslope := slope;
  End;

  If (li^.frontsector^.ceilingheight <> li^.backsector^.ceilingheight) Then Begin

    slope := FixedDiv(opentop - sightzstart, _in^.frac);
    If (slope < topslope) Then
      topslope := slope;
  End;

  If (topslope <= bottomslope) Then
    exit; // stop

  result := true; // keep going
End;

//
// P_DivlineSide
// Returns side 0 (front), 1 (back), or 2 (on).
//

Function P_DivlineSide(x: fixed_t; y: fixed_t; node: Pdivline_t): int;
Var
  dx, dy,
    left, right: fixed_t;
Begin

  If (node^.dx = 0) Then Begin
    If (x = node^.x) Then Begin
      result := 2;
      exit;
    End;

    If (x <= node^.x) Then Begin
      result := ord(node^.dy > 0);
      exit;
    End;

    result := ord(node^.dy < 0);
    exit;
  End;

  If (node^.dy = 0) Then Begin

    If (x = node^.y) Then Begin
      result := 2;
      exit;
    End;

    If (y <= node^.y) Then Begin
      result := ord(node^.dx < 0);
      exit;
    End;

    result := ord(node^.dx > 0);
    exit;
  End;

  dx := (x - node^.x);
  dy := (y - node^.y);

  left := SarLongint(node^.dy, FRACBITS) * SarLongint(dx, FRACBITS);
  right := SarLongint(dy, FRACBITS) * SarLongint(node^.dx, FRACBITS);

  If (right < left) Then Begin
    result := 0; // front side
    exit;
  End;

  If (left = right) Then
    result := 2
  Else
    result := 1; // back side
End;

//
// P_InterceptVector2
// Returns the fractional intercept point
// along the first divline.
// This is only called by the addthings and addlines traversers.
//

Function P_InterceptVector2(v2: Pdivline_t; v1: Pdivline_t): fixed_t;
Var
  frac: fixed_t;
  num: fixed_t;
  den: fixed_t;

Begin
  den := FixedMul(SarLongint(v1^.dy, 8), v2^.dx) - FixedMul(SarLongint(v1^.dx, 8), v2^.dy);
  If (den = 0) Then Begin
    result := 0;
    exit;
    //	I_Error ("P_InterceptVector: parallel");
  End;
  num := FixedMul(SarLongint(v1^.x - v2^.x, 8), v1^.dy) +
    FixedMul(SarLongint(v2^.y - v1^.y, 8), v1^.dx);
  frac := FixedDiv(num, den);

  result := frac;
End;

//
// P_CrossSubsector
// Returns true
//  if strace crosses the given subsector successfully.
//

Function P_CrossSubsector(num: int): boolean;
Var
  seg: Pseg_t;
  line: Pline_t;
  s1, s2, count: int;
  sub: Psubsector_t;
  front, back: Psector_t;
  opentop, openbottom: fixed_t;
  divl: divline_t;
  v1, v2: ^vertex_t;
  frac: fixed_t;
  slope: fixed_t;
Begin
  //#ifdef RANGECHECK
  //    if (num>=numsubsectors)
  //	I_Error ("P_CrossSubsector: ss %i with numss = %i",
  //		 num,
  //		 numsubsectors);
  //#endif

  sub := @subsectors[num];

  // check lines
  For count := 0 To sub^.numlines - 1 Do Begin
    seg := @segs[sub^.firstline + count];
    line := seg^.linedef;

    // allready checked other side?
    If (line^.validcount = validcount) Then
      continue;


    line^.validcount := validcount;

    v1 := line^.v1;
    v2 := line^.v2;
    s1 := P_DivlineSide(v1^.x, v1^.y, @strace);
    s2 := P_DivlineSide(v2^.x, v2^.y, @strace);

    // line isn't crossed?
    If (s1 = s2) Then
      continue;

    divl.x := v1^.x;
    divl.y := v1^.y;
    divl.dx := v2^.x - v1^.x;
    divl.dy := v2^.y - v1^.y;
    s1 := P_DivlineSide(strace.x, strace.y, @divl);
    s2 := P_DivlineSide(t2x, t2y, @divl);

    // line isn't crossed?
    If (s1 = s2) Then
      continue;

    // Backsector may be NULL if this is an "impassible
    // glass" hack line.

    If (line^.backsector = Nil) Then Begin
      result := false;
      exit;
    End;

    // stop because it is not two sided anyway
    // might do this after updating validcount?
    If ((line^.flags And ML_TWOSIDED) = 0) Then Begin
      result := false;
      exit;
    End;

    // crosses a two sided line
    front := seg^.frontsector;
    back := seg^.backsector;

    // no wall to block sight with?
    If (front^.floorheight = back^.floorheight)
      And (front^.ceilingheight = back^.ceilingheight) Then
      continue;

    // possible occluder
    // because of ceiling height differences
    If (front^.ceilingheight < back^.ceilingheight) Then
      opentop := front^.ceilingheight
    Else
      opentop := back^.ceilingheight;

    // because of ceiling height differences
    If (front^.floorheight > back^.floorheight) Then
      openbottom := front^.floorheight
    Else
      openbottom := back^.floorheight;

    // quick test for totally closed doors
    If (openbottom >= opentop) Then Begin
      result := false; // stop
      exit;
    End;

    frac := P_InterceptVector2(@strace, @divl);

    If (front^.floorheight <> back^.floorheight) Then Begin

      slope := FixedDiv(openbottom - sightzstart, frac);
      If (slope > bottomslope) Then
        bottomslope := slope;
    End;

    If (front^.ceilingheight <> back^.ceilingheight) Then Begin
      slope := FixedDiv(opentop - sightzstart, frac);
      If (slope < topslope) Then
        topslope := slope;
    End;

    If (topslope <= bottomslope) Then Begin
      result := false; // stop
      exit;
    End;
  End;
  // passed the subsector ok
  result := true;
End;

//
// P_CrossBSPNode
// Returns true
//  if strace crosses the given node successfully.
//

Function P_CrossBSPNode(bspnum: int): boolean;
Var
  bsp: Pnode_t;
  side: int;
Begin
  If (bspnum And NF_SUBSECTOR) <> 0 Then Begin
    If (bspnum = -1) Then Begin
      result := P_CrossSubsector(0);
      exit;
    End
    Else Begin
      result := P_CrossSubsector(int(bspnum And (Not NF_SUBSECTOR)));
      exit;
    End;
  End;

  bsp := @nodes[bspnum];

  // decide which side the start point is on
  side := P_DivlineSide(strace.x, strace.y, Pdivline_t(bsp));
  If (side = 2) Then
    side := 0; // an "on" should cross both sides

  // cross the starting side
  If (Not P_CrossBSPNode(bsp^.children[side])) Then Begin
    result := false;
    exit;
  End;

  // the partition plane is crossed here
  If (side = P_DivlineSide(t2x, t2y, Pdivline_t(bsp))) Then Begin

    // the line doesn't touch the other side
    result := true;
    exit;
  End;
  // cross the ending side
  result := P_CrossBSPNode(bsp^.children[side Xor 1]);
End;

//
// P_CheckSight
// Returns true
//  if a straight line between t1 and t2 is unobstructed.
// Uses REJECT.
//

Function P_CheckSight(t1: Pmobj_t; t2: Pmobj_t): boolean;
Var
  s1, s2,
    pnum, bytenum, bitnum: int;
Begin
  // First check for trivial rejection.

  // Determine subsector entries in REJECT table.
  s1 := ((t1^.subsector^.sector - @sectors[0]) Div sizeof(sectors[0]));
  s2 := ((t2^.subsector^.sector - @sectors[0]) Div sizeof(sectors[0]));
  pnum := s1 * numsectors + s2;
  bytenum := pnum Shr 3;
  bitnum := 1 Shl (pnum And 7);

  // Check in REJECT table.
  If (rejectmatrix[bytenum] And bitnum) <> 0 Then Begin
    sightcounts[0] := sightcounts[0] + 1;

    // can't possibly be connected
    result := false;
    exit;
  End;

  // An unobstructed LOS is possible.
  // Now look from eyes of t1 to any part of t2.
  sightcounts[1] := sightcounts[1] + 1;

  validcount := validcount + 1;

  sightzstart := t1^.z + t1^.height - SarLongint(t1^.height, 2);
  topslope := (t2^.z + t2^.height) - sightzstart;
  bottomslope := (t2^.z) - sightzstart;

  If (gameversion <= exe_doom_1_2) Then Begin
    result := P_PathTraverse(t1^.x, t1^.y, t2^.x, t2^.y,
      PT_EARLYOUT Or PT_ADDLINES, @PTR_SightTraverse);
    exit;
  End;

  strace.x := t1^.x;
  strace.y := t1^.y;
  t2x := t2^.x;
  t2y := t2^.y;
  strace.dx := t2^.x - t1^.x;
  strace.dy := t2^.y - t1^.y;

  // the head node is the last node output
  result := P_CrossBSPNode(numnodes - 1);
End;

End.

