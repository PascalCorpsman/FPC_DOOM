Unit r_bsp;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;


Procedure R_ClearClipSegs();
Procedure R_ClearDrawSegs();
Procedure R_RenderBSPNode(bspnum: int);

Implementation

Uses
  info_types, doomdata
  , d_loop
  , i_video
  , m_fixed
  , p_setup
  , r_draw, r_defs, r_main, r_plane, r_sky
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

  curline: ^seg_t;
  sidedef: ^side_t;
  linedef: ^line_t;
  frontsector: ^sector_t;
  backsector: ^sector_t;

  drawsegs: ^drawseg_t = Nil;
  ds_p: ^drawseg_t;
  numdrawsegs: int = 0;

  // newend is one past the last valid seg
  newend: ^cliprange_t;
  solidsegs: Array[0..MAXSEGS - 1] Of cliprange_t;

Procedure R_ClearClipSegs();
Begin
  solidsegs[0].first := -$7FFFFFFF;
  solidsegs[0].last := -1;
  solidsegs[1].first := viewwidth;
  solidsegs[1].last := $7FFFFFFF;
  newend := @solidsegs[2];
End;

Procedure R_ClearDrawSegs();
Begin
  ds_p := drawsegs;
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
// R_Subsector
// Determine floor/ceiling planes.
// Add sprites of things in sector.
// Draw one or more line segments.
//

Procedure R_Subsector(num: int);
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
  count := sub^.numlines;
  line := @segs[sub^.firstline];

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
    floorplane := Nil;

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
    ceilingplane := Nil;

  hier gehts weiter

  R_AddSprites(frontsector);

  //    while (count--)
  //    {
  //	R_AddLine (line);
  //	line++;
  //    }
  //
  //    // check for solidsegs overflow - extremely unsatisfactory!
  //    if(newend > &solidsegs[32] && false)
  //        I_Error("R_Subsector: solidsegs overflow (vanilla may crash here)\n");
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
Begin
  //    int			boxx;
  //    int			boxy;
  //    int			boxpos;
  //
  //    fixed_t		x1;
  //    fixed_t		y1;
  //    fixed_t		x2;
  //    fixed_t		y2;
  //
  //    angle_t		angle1;
  //    angle_t		angle2;
  //    angle_t		span;
  //    angle_t		tspan;
  //
  //    cliprange_t*	start;
  //
  //    int			sx1;
  //    int			sx2;
  //
  //    // Find the corners of the box
  //    // that define the edges from current viewpoint.
  //    if (viewx <= bspcoord[BOXLEFT])
  //	boxx = 0;
  //    else if (viewx < bspcoord[BOXRIGHT])
  //	boxx = 1;
  //    else
  //	boxx = 2;
  //
  //    if (viewy >= bspcoord[BOXTOP])
  //	boxy = 0;
  //    else if (viewy > bspcoord[BOXBOTTOM])
  //	boxy = 1;
  //    else
  //	boxy = 2;
  //
  //    boxpos = (boxy<<2)+boxx;
  //    if (boxpos == 5)
  //	return true;
  //
  //    x1 = bspcoord[checkcoord[boxpos][0]];
  //    y1 = bspcoord[checkcoord[boxpos][1]];
  //    x2 = bspcoord[checkcoord[boxpos][2]];
  //    y2 = bspcoord[checkcoord[boxpos][3]];
  //
  //    // check clip list for an open space
  //    angle1 = R_PointToAngleCrispy (x1, y1) - viewangle;
  //    angle2 = R_PointToAngleCrispy (x2, y2) - viewangle;
  //
  //    span = angle1 - angle2;
  //
  //    // Sitting on a line?
  //    if (span >= ANG180)
  //	return true;
  //
  //    tspan = angle1 + clipangle;
  //
  //    if (tspan > 2*clipangle)
  //    {
  //	tspan -= 2*clipangle;
  //
  //	// Totally off the left edge?
  //	if (tspan >= span)
  //	    return false;
  //
  //	angle1 = clipangle;
  //    }
  //    tspan = clipangle - angle2;
  //    if (tspan > 2*clipangle)
  //    {
  //	tspan -= 2*clipangle;
  //
  //	// Totally off the left edge?
  //	if (tspan >= span)
  //	    return false;
  //
  //	angle2 = -clipangle;
  //    }
  //
  //
  //    // Find the first clippost
  //    //  that touches the source post
  //    //  (adjacent pixels are touching).
  //    angle1 = (angle1+ANG90)>>ANGLETOFINESHIFT;
  //    angle2 = (angle2+ANG90)>>ANGLETOFINESHIFT;
  //    sx1 = viewangletox[angle1];
  //    sx2 = viewangletox[angle2];
  //
  //    // Does not cross a pixel.
  //    if (sx1 == sx2)
  //	return false;
  //    sx2--;
  //
  //    start = solidsegs;
  //    while (start->last < sx2)
  //	start++;
  //
  //    if (sx1 >= start->first
  //	&& sx2 <= start->last)
  //    {
  //	// The clippost contains the new span.
  //	return false;
  //    }

  result := true;
End;


//
// RenderBSPNode
// Renders all subsectors below a given node,
//  traversing subtree recursively.
// Just call with BSP root.

Procedure R_RenderBSPNode(bspnum: int);
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

