// Ported 100%
Unit r_bsp;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , r_defs
  ;

Var
  ds_p: int; // index in drawsegs
  drawsegs: Array Of drawseg_t = Nil;
  numdrawsegs: int = 0;
  curline: ^seg_t;
  sidedef: ^side_t;
  linedef: ^line_t;

  frontsector: ^sector_t;
  backsector: ^sector_t;

Procedure R_ClearClipSegs();
Procedure R_ClearDrawSegs();
Procedure R_RenderBSPNode(Const bspnum: int);

Implementation

Uses
  doomdata, tables
  , d_loop
  , i_video
  , m_bbox
  , p_setup
  , r_draw, r_main, r_plane, r_sky, r_things, r_segs
  ;

//
// ClipWallSegment
// Clips the given range of columns
// and includes it in the new clip list.
//
Type
  cliprange_t = Record
    first: int;
    last: int;
  End;

Const
  // We must expand MAXSEGS to the theoretical limit of the number of solidsegs
  // that can be generated in a scene by the DOOM engine. This was determined by
  // Lee Killough during BOOM development to be a function of the screensize.
  // The simplest thing we can do, other than fix this bug, is to let the game
  // render overage and then bomb out by detecting the overflow after the
  // fact. -haleyjd
  //#define MAXSEGS 32
  MAXSEGS = (MAXWIDTH Div 2 + 1);

Var
  // newend is one past the last valid seg
  newend: ^cliprange_t;
  solidsegs: Array[0..MAXSEGS - 1] Of cliprange_t;

Procedure R_ClearDrawSegs();
Begin
  ds_p := 0;
End;

//
// R_ClipSolidWallSegment
// Does handle solid walls,
//  e.g. single sided LineDefs (middle texture)
//  that entirely block the view.
//

Procedure R_ClipSolidWallSegment(first, last: int);
Label
  crunch;
Var
  next: ^cliprange_t;
  start: ^cliprange_t;
Begin

  // Find the first range that touches the range
  //  (adjacent pixels are touching).
  start := solidsegs;
  While (start^.last < first - 1) Do
    inc(start);

  If (first < start^.first) Then Begin
    If (last < start^.first - 1) Then Begin

      // Post is entirely visible (above start),
      //  so insert a new clippost.
      R_StoreWallRange(first, last);
      next := newend;
      newend := newend + 1;

      While (next <> start) Do Begin
        next^ := (next - 1)^;
        dec(next);
      End;
      next^.first := first;
      next^.last := last;
      exit;
    End;

    // There is a fragment above *start.
    R_StoreWallRange(first, start^.first - 1);
    // Now adjust the clip size.
    start^.first := first;
  End;

  // Bottom contained in start?
  If (last <= start^.last) Then exit;

  next := start;
  While (last >= (next + 1)^.first - 1) Do Begin

    // There is a fragment between two posts.
    R_StoreWallRange(next^.last + 1, (next + 1)^.first - 1);
    inc(next);

    If (last <= next^.last) Then Begin
      // Bottom is contained in next.
      // Adjust the clip size.
      start^.last := next^.last;
      Goto crunch;
    End;
  End;

  // There is a fragment after *next.
  R_StoreWallRange(next^.last + 1, last);
  // Adjust the clip size.
  start^.last := last;

  // Remove start+1 to next from the clip list,
  // because start now covers their area.
  crunch:

  If (next = start) Then Begin
    // Post just extended past the bottom of one post.
    exit;
  End;

  // Übersetzt mit ChatGPT, mal sehen ob das passt
  // Das foglende soll alle Elemente im Array um 1 verschieben
  While (next <> newend) Do Begin
    inc(next);
    inc(start);
    // Remove a post.
    start^ := next^;
  End;

  newend := start + 1;
End;

//
// R_ClipPassWallSegment
// Clips the given range of columns,
//  but does not includes it in the clip list.
// Does handle windows,
//  e.g. LineDefs with upper and lower texture.
//

Procedure R_ClipPassWallSegment(first, last: int);
Var
  start: ^cliprange_t;
Begin

  // Find the first range that touches the range
  //  (adjacent pixels are touching).
  start := solidsegs;
  While (start^.last < first - 1) Do
    inc(start);

  If (first < start^.first) Then Begin

    If (last < start^.first - 1) Then Begin
      // Post is entirely visible (above start).
      R_StoreWallRange(first, last);
      exit;
    End;

    // There is a fragment above *start.
    R_StoreWallRange(first, start^.first - 1);
  End;

  // Bottom contained in start?
  If (last <= start^.last) Then exit;

  While (last >= (start + 1)^.first - 1) Do Begin
    // There is a fragment between two posts.
    R_StoreWallRange(start^.last + 1, (start + 1)^.first - 1);
    inc(start);
    If (last <= start^.last) Then exit;
  End;

  // There is a fragment after *next.
  R_StoreWallRange(start^.last + 1, last);
End;

Procedure R_ClearClipSegs();
Begin
  solidsegs[0].first := -$7FFFFFFF;
  solidsegs[0].last := -1;
  solidsegs[1].first := viewwidth;
  solidsegs[1].last := $7FFFFFFF;
  newend := @solidsegs[2];
End;

// [AM] Interpolate the passed sector, if prudent.

Procedure R_MaybeInterpolateSector(sector: psector_t);
Begin
  If (crispy.uncapped <> 0) And
    // Only if we moved the sector last tic ...
  (sector^.oldgametic = gametic - 1) And
    // ... and it has a thinker associated with it.
  assigned(sector^.specialdata) Then Begin

    // Interpolate between current and last floor/ceiling position.
    If (sector^.floorheight <> sector^.oldfloorheight) Then
      sector^.interpfloorheight :=
        LerpFixed(sector^.oldfloorheight, sector^.floorheight)
    Else
      sector^.interpfloorheight := sector^.floorheight;
    If (sector^.ceilingheight <> sector^.oldceilingheight) Then
      sector^.interpceilingheight :=
        LerpFixed(sector^.oldceilingheight, sector^.ceilingheight)
    Else
      sector^.interpceilingheight := sector^.ceilingheight;
  End
  Else Begin
    sector^.interpfloorheight := sector^.floorheight;
    sector^.interpceilingheight := sector^.ceilingheight;
  End;
End;

//
// R_AddLine
// Clips the given segment
// and adds any visible pieces to the line list.
//

Procedure R_AddLine(line: Pseg_t); // Geprüft
Var
  x1: int;
  x2: int;
  angle1: angle_t;
  angle2: angle_t;
  span: angle_t;
  clipangle2, tspan: angle_t;
Begin
  curline := line;

  // OPTIMIZE: quickly reject orthogonal back sides.
  // [crispy] remove slime trails
  angle1 := R_PointToAngleCrispy(line^.v1^.r_x, line^.v1^.r_y);
  angle2 := R_PointToAngleCrispy(line^.v2^.r_x, line^.v2^.r_y);

  // Clip to view edges.
  // OPTIMIZE: make constant out of 2*clipangle (FIELDOFVIEW).
  span := angle_t(angle1 - angle2);

  // Back side? I.e. backface culling?
  If (span >= ANG180) Then exit;

  // Global angle needed by segcalc.
  rw_angle1 := angle1;
  angle1 := angle_t(angle1 - viewangle);
  angle2 := angle_t(angle2 - viewangle);

  tspan := angle_t(angle1 + clipangle);
  clipangle2 := 2 * clipangle;
  If (tspan > clipangle2) Then Begin
    tspan := tspan - clipangle2;
    // Totally off the left edge?
    If (tspan >= span) Then exit;
    angle1 := clipangle;
  End;
  tspan := angle_t(clipangle - angle2);
  If (tspan > clipangle2) Then Begin
    tspan := tspan - clipangle2;
    // Totally off the left edge?
    If (tspan >= span) Then exit;
    angle2 := angle_t(-clipangle);
  End;

  // The seg is in the view range,
  // but not necessarily visible.

  angle1 := angle_t(angle1 + ANG90) Shr ANGLETOFINESHIFT;
  angle2 := angle_t(angle2 + ANG90) Shr ANGLETOFINESHIFT;

  x1 := viewangletox[angle1];
  x2 := viewangletox[angle2];

  // Does not cross a pixel?
  If (x1 >= x2) Then exit;

  backsector := line^.backsector;

  // Single sided line?
  If backsector = Nil Then Begin
    R_ClipSolidWallSegment(x1, x2 - 1);
    exit;
  End;

  // [AM] Interpolate sector movement before
  //      running clipping tests.  Frontsector
  //      should already be interpolated.
  R_MaybeInterpolateSector(backsector);

  // Closed door.
  If (backsector^.interpceilingheight <= frontsector^.interpfloorheight) Or
    (backsector^.interpfloorheight >= frontsector^.interpceilingheight) Then Begin
    R_ClipSolidWallSegment(x1, x2 - 1);
    exit;
  End;

  // Window.
  If (backsector^.interpceilingheight <> frontsector^.interpceilingheight)
    Or (backsector^.interpfloorheight <> frontsector^.interpfloorheight) Then Begin
    R_ClipPassWallSegment(x1, x2 - 1);
    exit;
  End;

  // Reject empty lines used for triggers
  //  and special events.
  // Identical floor and ceiling on both sides,
  // identical light levels on both sides,
  // and no middle texture.
  If (backsector^.ceilingpic = frontsector^.ceilingpic)
    And (backsector^.floorpic = frontsector^.floorpic)
    And (backsector^.rlightlevel = frontsector^.rlightlevel)
    And (curline^.sidedef^.midtexture = 0)
    Then Begin
    exit;
  End;

  R_ClipPassWallSegment(x1, x2 - 1);
End;

//
// R_CheckBBox
// Checks BSP node/subtree bounding box.
// Returns true
//  if some part of the bbox might be visible.
//
Const
  checkcoord: Array[0..11, 0..3] Of int =
  (
    (3, 0, 2, 1),
    (3, 0, 2, 0),
    (3, 1, 2, 0),
    (0, 0, 0, 0),

    (2, 0, 2, 1),
    (0, 0, 0, 0),
    (3, 1, 3, 0),
    (0, 0, 0, 0),

    (2, 0, 3, 1),
    (2, 1, 3, 1),
    (2, 1, 3, 0),
    (0, 0, 0, 0)
    );

Function R_CheckBBox(bspcoord: pfixed_t): boolean;
Var
  boxx, boxy, boxpos: int;
  x1, y1, x2, y2: fixed_t;
  angle1, angle2, span, tspan: angle_t;
  i, j, sx1, sx2: int;
Begin

  // Find the corners of the box
  // that define the edges from current viewpoint.
  If (viewx <= bspcoord[BOXLEFT]) Then
    boxx := 0
  Else If (viewx < bspcoord[BOXRIGHT]) Then
    boxx := 1
  Else
    boxx := 2;

  If (viewy >= bspcoord[BOXTOP]) Then
    boxy := 0
  Else If (viewy > bspcoord[BOXBOTTOM]) Then
    boxy := 1
  Else
    boxy := 2;

  boxpos := (boxy Shl 2) + boxx;
  If (boxpos = 5) Then Begin
    result := true;
    exit;
  End;

  x1 := bspcoord[checkcoord[boxpos][0]];
  y1 := bspcoord[checkcoord[boxpos][1]];
  x2 := bspcoord[checkcoord[boxpos][2]];
  y2 := bspcoord[checkcoord[boxpos][3]];

  // check clip list for an open space
  angle1 := angle_t(R_PointToAngleCrispy(x1, y1) - viewangle);
  angle2 := angle_t(R_PointToAngleCrispy(x2, y2) - viewangle);

  span := angle_t(angle1 - angle2);

  // Sitting on a line?
  If (span >= ANG180) Then Begin
    result := true;
    exit;
  End;

  tspan := angle_t(angle1 + clipangle);

  If (tspan > 2 * clipangle) Then Begin
    tspan := tspan - 2 * clipangle;
    // Totally off the left edge?
    If (tspan >= span) Then Begin
      result := false;
      exit;
    End;
    angle1 := clipangle;
  End;

  tspan := angle_t(clipangle - angle2);
  If (tspan > 2 * clipangle) Then Begin
    tspan := tspan - 2 * clipangle;
    // Totally off the left edge?
    If (tspan >= span) Then Begin
      result := false;
      exit;
    End;
    angle2 := angle_t(-clipangle);
  End;

  // Find the first clippost
  //  that touches the source post
  //  (adjacent pixels are touching).
  angle1 := angle_t(angle1 + ANG90) Shr ANGLETOFINESHIFT;
  angle2 := angle_t(angle2 + ANG90) Shr ANGLETOFINESHIFT;
  sx1 := viewangletox[angle1];
  sx2 := viewangletox[angle2];

  // Does not cross a pixel.
  If (sx1 = sx2) Then Begin
    result := false;
    exit;
  End;
  sx2 := sx2 - 1;

  j := -1;
  For i := 0 To high(solidsegs) Do Begin
    If solidsegs[i].last >= sx2 Then Begin
      j := i - 1;
      break;
    End;
  End;

  If (j <> -1) And (sx1 >= solidsegs[j].first) And (sx2 <= solidsegs[j].last) Then Begin
    result := false;
    exit;
  End;

  result := true;
End;

//
// R_Subsector
// Determine floor/ceiling planes.
// Add sprites of things in sector.
// Draw one or more line segments.
//

Procedure R_Subsector(num: int); // grob geprüft (ohne aufgerufene Routinen)
Var
  count: int;
  line: ^seg_t;
  sub: ^subsector_t;
Begin

  //#ifdef RANGECHECK
  //    if (num>=numsubsectors)
  //	I_Error ("R_Subsector: ss %i with numss = %i",
  //		 num,
  //		 numsubsectors);
  //#endif

  sscount := sscount + 1;
  sub := @subsectors[num];
  frontsector := sub^.sector;

  // [AM] Interpolate sector movement.  Usually only needed
  //      when you're standing inside the sector.
  R_MaybeInterpolateSector(frontsector);

  If (frontsector^.interpfloorheight < viewz) Then Begin
    If (frontsector^.floorpic = skyflatnum) And ((frontsector^.sky And PL_SKYFLAT) <> 0) Then Begin
      floorplane := R_FindPlane(frontsector^.interpfloorheight,
        frontsector^.sky,
        frontsector^.rlightlevel); // [crispy] A11Y
    End
    Else Begin
      floorplane := R_FindPlane(frontsector^.interpfloorheight,
        frontsector^.floorpic,
        frontsector^.rlightlevel); // [crispy] A11Y
    End;
  End
  Else
    floorplane := -1;

  If (frontsector^.interpceilingheight > viewz) Or (
    frontsector^.ceilingpic = skyflatnum) Then Begin
    If (frontsector^.ceilingpic = skyflatnum) And ((frontsector^.sky And PL_SKYFLAT) <> 0) Then Begin
      ceilingplane := R_FindPlane(frontsector^.interpceilingheight,
        // [crispy] add support for MBF sky tranfers
        frontsector^.sky,
        frontsector^.rlightlevel); // [crispy] A11Y
    End
    Else Begin
      ceilingplane := R_FindPlane(frontsector^.interpceilingheight,
        // [crispy] add support for MBF sky tranfers
        frontsector^.ceilingpic,
        frontsector^.rlightlevel); // [crispy] A11Y
    End;
  End
  Else
    ceilingplane := -1;

  R_AddSprites(frontsector); // Fügt alle Sprites des Sektors die vor uns liegen in die "zu" Rendern Liste ein

  line := @segs[sub^.firstline];
  For count := 0 To sub^.numlines - 1 Do Begin
    R_AddLine(line);
    inc(line);
  End;

  // check for solidsegs overflow - extremely unsatisfactory!
  //    if(newend > &solidsegs[32] && false)
  //        I_Error("R_Subsector: solidsegs overflow (vanilla may crash here)\n");
End;

//
// RenderBSPNode
// Renders all subsectors below a given node,
//  traversing subtree recursively.
// Just call with BSP root.

Procedure R_RenderBSPNode(Const bspnum: int); // -- Geprüft
Var
  bsp: ^node_t;
  side: int;
Begin
  // Found a subsector?
  If (bspnum And NF_SUBSECTOR) <> 0 Then Begin
    If (bspnum = -1) Then Begin
      R_Subsector(0);
    End
    Else Begin
      R_Subsector(int(bspnum And (Not NF_SUBSECTOR)));
    End;
    exit;
  End;

  bsp := @nodes[bspnum];
  // Decide which side the view point is on.
  side := R_PointOnSide(viewx, viewy, bsp);
  // Recursively divide front space.
  R_RenderBSPNode(bsp^.children[side]);
  // Possibly divide back space.
  If (R_CheckBBox(bsp^.bbox[side Xor 1])) Then
    R_RenderBSPNode(bsp^.children[side Xor 1]);
End;

End.

