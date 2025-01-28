Unit r_main;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , tables, info_types
  , i_video
  , m_fixed
  , r_defs
  ;

Type
  localview_t = Record
    oldticangle: angle_t;
    ticangle: angle_t;
    ticangleturn: short;
    rawangle: double;
    angle: angle_t;
  End;

Var
  // [crispy] parameterized for smooth diminishing lighting
  NUMCOLORMAPS: int;

  LIGHTLEVELS: int;
  LIGHTSEGSHIFT: int;
  LIGHTBRIGHT: int;
  MAXLIGHTSCALE: int;
  LIGHTSCALESHIFT: int;
  MAXLIGHTZ: int;
  LIGHTZSHIFT: int;

  viewplayer: pplayer_t;

  viewx: fixed_t;
  viewy: fixed_t;
  viewz: fixed_t;

  viewangle: angle_t;
  viewcos: fixed_t;
  viewsin: fixed_t;
  projection: fixed_t;

  centerxfrac: fixed_t;
  centeryfrac: fixed_t;
  sscount: int;

  // 0 = high, 1 = low
  detailshift: int;

  // bumped light from gun blasts
  extralight: int;

  // increment every time a check is made
  validcount: int = 1;
  scalelight: Array Of Array Of Plighttable_t = Nil;
  scalelightfixed: Array Of Plighttable_t = Nil;

  //
  // precalculated math tables
  //
  clipangle: angle_t;

  // The viewangletox[viewangle + FINEANGLES/4] lookup
  // maps the visible view angles to screen X coordinates,
  // flattening the arc to a flat projection plane.
  // There will be many angles mapped to the same X.
  viewangletox: Array[0..FINEANGLES Div 2] Of int;
  viewangleoffset: int = 0; // Wenn Doom im 3-Fenster modus läuft, dann gibt dieses Offset an wo man hinsieht..

  // The xtoviewangleangle[] table maps a screen pixel
  // to the lowest viewangle that maps back to x ranges
  // from clipangle to -clipangle.
  xtoviewangle: Array[0..MAXWIDTH] Of angle_t;
  fixedcolormap: plighttable_t;

  colfunc: TProcedure = Nil;
  basecolfunc: TProcedure = Nil;
  fuzzcolfunc: TProcedure = Nil;
  transcolfunc: TProcedure = Nil;
  tlcolfunc: TProcedure = Nil;
  spanfunc: TProcedure = Nil;

  zlight: Array Of Array Of Plighttable_t = Nil;
  centery: int;
  centerx: int;

  localview: localview_t; // [crispy]
  setsizeneeded: boolean;
  // [crispy] lookup table for horizontal screen coordinates
  flipscreenwidth: Array[0..MAXWIDTH - 1] Of int;
  //int		*flipviewwidth;


Procedure R_Init();
Procedure R_ExecuteSetViewSize();

Function R_PointToAngle(x, y: fixed_t): angle_t;
Function R_PointToAngleCrispy(x, y: fixed_t): angle_t;

Function R_PointInSubsector(x, y: fixed_t): Psubsector_t;

Procedure R_RenderPlayerView(player: Pplayer_t);

Function R_PointOnSide(x, y: fixed_t; node: Pnode_t): int;

Function LerpFixed(oldvalue, newvalue: fixed_t): fixed_t;
Function LerpAngle(oangle, nangle: angle_t): angle_t;
Procedure R_SetGoobers(mode: boolean);

Function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): int;

Implementation

Uses
  a11y_weapon_pspr, doomdata
  , am_map
  , d_loop
  , r_data, r_sky, r_draw, r_plane, r_bsp, r_things, r_segs
  , m_menu
  , p_setup, p_tick, p_local, p_spec
  , st_stuff
  ;

Const
  DISTMAP = 2;

  // Fineangles in the SCREENWIDTH wide window.
  FIELDOFVIEW = 2048;

Var
  // just for profiling purposes
  framecount: int;
  goobers_mode: boolean = false;


  setblocks: int;
  setdetail: int;

  scaledviewwidth_nonwide, viewwidth_nonwide: int;
  centerxfrac_nonwide: fixed_t;

Procedure R_InitLightTables();
Var
  i, j, level, startmap, scale: int;
Begin
  If assigned(scalelight) Then Begin
    For i := 0 To high(scalelight) Do Begin
      setlength(scalelight[i], 0);
    End;
    setlength(scalelight, 0);
    scalelight := Nil;
  End;

  setlength(scalelightfixed, 0);

  //      if (zlight)
  //      {
  //  	for (i = 0; i < LIGHTLEVELS; i++)
  //  	{
  //  		free(zlight[i]);
  //  	}
  //  	free(zlight);
  //      }

  // [crispy] smooth diminishing lighting
  //      if (crispy->smoothlight)
  //      {
  //  #ifdef CRISPY_TRUECOLOR
  //      if (crispy->truecolor)
  //      {
  //  	    // [crispy] if in TrueColor mode, use smoothest diminished lighting
  //  	    LIGHTLEVELS =      16 << 4;
  //  	    LIGHTSEGSHIFT =     4 -  4;
  //  	    LIGHTBRIGHT =       1 << 4;
  //  	    MAXLIGHTSCALE =    48 << 3;
  //  	    LIGHTSCALESHIFT =  12 -  3;
  //  	    MAXLIGHTZ =       128 << 6;
  //  	    LIGHTZSHIFT =      20 -  6;
  //      }
  //      else
  //  #endif
  //      {
  //  	    // [crispy] else, use paletted approach
  //  	    LIGHTLEVELS =      16 << 1;
  //  	    LIGHTSEGSHIFT =     4 -  1;
  //  	    LIGHTBRIGHT =       1 << 1;
  //  	    MAXLIGHTSCALE =    48 << 0;
  //  	    LIGHTSCALESHIFT =  12 -  0;
  //  	    MAXLIGHTZ =       128 << 3;
  //  	    LIGHTZSHIFT =      20 -  3;
  //      }
  //      }
  //      else
  //      {
  LIGHTLEVELS := 16;
  LIGHTSEGSHIFT := 4;
  LIGHTBRIGHT := 1;
  MAXLIGHTSCALE := 48;
  LIGHTSCALESHIFT := 12;
  MAXLIGHTZ := 128;
  LIGHTZSHIFT := 20;
  //      }


  setlength(scalelight, LIGHTLEVELS);
  setlength(scalelightfixed, MAXLIGHTSCALE);
  setlength(zlight, LIGHTLEVELS);

  // Calculate the light levels to use
  //  for each level / distance combination.
  For i := 0 To LIGHTLEVELS - 1 Do Begin
    setlength(scalelight[i], MAXLIGHTSCALE);
    setlength(zlight[i], MAXLIGHTZ);

    startmap := ((LIGHTLEVELS - LIGHTBRIGHT - i) * 2) * NUMCOLORMAPS Div LIGHTLEVELS;
    For j := 0 To MAXLIGHTZ - 1 Do Begin

      scale := FixedDiv((ORIGWIDTH Div 2 * FRACUNIT), (j + 1) Shl LIGHTZSHIFT);
      scale := SarLongint(scale, LIGHTSCALESHIFT);
      level := startmap - scale Div DISTMAP;

      If (level < 0) Then level := 0;

      If (level >= NUMCOLORMAPS) Then level := NUMCOLORMAPS - 1;

      zlight[i][j] := @colormaps[level * 256];
    End;
  End;
End;

Procedure R_InitPointToAngle();
Begin
  // UNUSED: now getting from tables.c
End;

Procedure R_InitTables();
Begin
  // UNUSED: now getting from tables.c
End;

//
// R_SetViewSize
// Do not really change anything here,
//  because it might be in the middle of a refresh.
// The change will take effect next refresh.
//

Procedure R_SetViewSize(blocks, detail: int);
Begin
  setsizeneeded := true;
  setblocks := blocks;
  setdetail := detail;
End;

Procedure R_Init();
Begin
  R_InitData();
  write('.');
  R_InitPointToAngle();
  write('.');
  R_InitTables();
  // viewwidth / viewheight / detailLevel are set by the defaults
  write('.');
  R_SetViewSize(screenblocks, detailLevel);
  R_InitPlanes();
  write('.');
  R_InitLightTables();
  write('.');
  R_InitSkyMap();
  R_InitTranslationTables();
  write('.');

  framecount := 0;
End;

// [crispy] turned into a general R_PointToAngle() flavor
// called with either slope_div = SlopeDivCrispy() from R_PointToAngleCrispy()
// or slope_div = SlopeDiv() else
//   int (*slope_div) (unsigned int num, unsigned int den)

Function R_PointToAngleSlope(x, y: fixed_t; slope_div: TSlopeDivCrispy): angle_t;
Begin
  result := 0;
  x := x - viewx;
  y := y - viewy;

  If ((x = 0) And (y = 0)) Then Begin
    exit;
  End;

  If (x >= 0) Then Begin
    // x >=0
    If (y >= 0) Then Begin
      // y>= 0
      If (x > y) Then Begin
        // octant 0
        result := tantoangle[slope_div(y, x)];
      End
      Else Begin
        // octant 1
        result := angle_t(ANG90 - 1 - tantoangle[slope_div(x, y)]);
      End;
    End
    Else Begin
      // y<0
      y := -y;
      If (x > y) Then Begin
        // octant 8
        result := angle_t(-tantoangle[slope_div(y, x)]);
      End
      Else Begin
        // octant 7
        result := angle_t(ANG270 + tantoangle[slope_div(x, y)]);
      End;
    End;
  End
  Else Begin
    // x<0
    x := -x;
    If (y >= 0) Then Begin
      // y>= 0
      If (x > y) Then Begin
        // octant 3
        result := angle_t(ANG180 - 1 - tantoangle[slope_div(y, x)]);
      End
      Else Begin
        // octant 2
        result := angle_t(ANG90 + tantoangle[slope_div(x, y)]);
      End;
    End
    Else Begin
      // y<0
      y := -y;
      If (x > y) Then Begin
        // octant 4
        result := angle_t(ANG180 + tantoangle[slope_div(y, x)]);
      End
      Else Begin
        // octant 5
        result := angle_t(ANG270 - 1 - tantoangle[slope_div(x, y)]);
      End;
    End;
  End;
End;

Function R_PointToAngle(x, y: fixed_t): angle_t;
Begin
  result := R_PointToAngleSlope(x, y, @SlopeDiv);
End;

Procedure R_InitTextureMapping();
Var
  i, x, t: int;
  focallength: fixed_t;
Begin
  // Use tangent table to generate viewangletox:
  //  viewangletox will give the next greatest x
  //  after the view angle.
  //
  // Calc focallength
  //  so FIELDOFVIEW angles covers SCREENWIDTH.
  focallength := FixedDiv(centerxfrac_nonwide, finetangent[FINEANGLES Div 4 + FIELDOFVIEW Div 2]);

  For i := 0 To FINEANGLES Div 2 - 1 Do Begin
    If (finetangent[i] > FRACUNIT * 2) Then
      t := -1
    Else If (finetangent[i] < -FRACUNIT * 2) Then
      t := viewwidth + 1
    Else Begin
      t := FixedMul(finetangent[i], focallength);
      t := int(SarLongint(centerxfrac - t + FRACUNIT - 1, FRACBITS));
      If (t < -1) Then
        t := -1
      Else If (t > viewwidth + 1) Then
        t := viewwidth + 1;
    End;
    viewangletox[i] := t;
  End;

  // Scan viewangletox[] to generate xtoviewangle[]:
  //  xtoviewangle will give the smallest view angle
  //  that maps to x.

  For x := 0 To viewwidth Do Begin
    i := 0;
    While (viewangletox[i] > x) Do
      inc(i);

    xtoviewangle[x] := angle_t((i Shl ANGLETOFINESHIFT) - ANG90);
  End;

  // Take out the fencepost cases from viewangletox.
  For i := 0 To FINEANGLES Div 2 - 1 Do Begin

    t := FixedMul(finetangent[i], focallength);
    t := centerx - t;

    If (viewangletox[i] = -1) Then
      viewangletox[i] := 0
    Else If (viewangletox[i] = viewwidth + 1) Then
      viewangletox[i] := viewwidth;
  End;

  clipangle := xtoviewangle[0];
End;

Procedure R_ExecuteSetViewSize();
Var
  cosadj: fixed_t;
  dy: fixed_t;
  i, j, level, startmap: int;
  num: fixed_t;
Begin
  setsizeneeded := false;

  If (setblocks >= 11) Then Begin // [crispy] Crispy HUD
    scaledviewwidth_nonwide := NONWIDEWIDTH;
    scaledviewwidth := SCREENWIDTH;
    viewheight := SCREENHEIGHT;
  End
    // [crispy] hard-code to SCREENWIDTH and SCREENHEIGHT minus status bar height
  Else If (setblocks = 10) Then Begin
    scaledviewwidth_nonwide := NONWIDEWIDTH;
    scaledviewwidth := SCREENWIDTH;
    viewheight := SCREENHEIGHT - (ST_HEIGHT Shl Crispy.hires);
  End
  Else Begin
    scaledviewwidth_nonwide := (setblocks * 32) Shl crispy.hires;
    viewheight := ((setblocks * 168 Div 10) And Not 7) Shl crispy.hires;
    //	// [crispy] regular viewwidth in non-widescreen mode
    //	if (crispy->widescreen)
    //	{
    //		const int widescreen_edge_aligner = (8 << crispy->hires) - 1;
    //
    //		scaledviewwidth = viewheight*SCREENWIDTH/(SCREENHEIGHT-(ST_HEIGHT<<crispy->hires));
    //		// [crispy] make sure scaledviewwidth is an integer multiple of the bezel patch width
    //		scaledviewwidth = (scaledviewwidth + widescreen_edge_aligner) & (int)~widescreen_edge_aligner;
    //		scaledviewwidth = MIN(scaledviewwidth, SCREENWIDTH);
    //	}
    //	else
    //	{
    scaledviewwidth := scaledviewwidth_nonwide;
    //  }
  End;

  detailshift := setdetail;
  viewwidth := scaledviewwidth Shr detailshift;
  viewwidth_nonwide := scaledviewwidth_nonwide Shr detailshift;

  centery := viewheight Div 2;
  centerx := viewwidth Div 2;
  centerxfrac := centerx Shl FRACBITS;
  centeryfrac := centery Shl FRACBITS;
  centerxfrac_nonwide := (viewwidth_nonwide Div 2) Shl FRACBITS;
  projection := centerxfrac_nonwide;

  If (detailshift = 0) Then Begin
    colfunc := @R_DrawColumn;
    basecolfunc := @R_DrawColumn;
    fuzzcolfunc := @R_DrawFuzzColumn;
    transcolfunc := @R_DrawTranslatedColumn;
    tlcolfunc := @R_DrawTLColumn;
    If goobers_mode Then Begin
      spanfunc := @R_DrawSpanSolid;
    End
    Else Begin
      spanfunc := @R_DrawSpan;
    End;
  End
  Else Begin
    Raise exception.create('Missing porting.');
    //	colfunc = basecolfunc = R_DrawColumnLow;
    //	fuzzcolfunc = R_DrawFuzzColumnLow;
    //	transcolfunc = R_DrawTranslatedColumnLow;
    //	tlcolfunc = R_DrawTLColumnLow;
    //	spanfunc = goobers_mode ? R_DrawSpanSolidLow : R_DrawSpanLow;
  End;

  R_InitBuffer(scaledviewwidth, viewheight);

  R_InitTextureMapping();

  // psprite scales
  pspritescale := FRACUNIT * viewwidth_nonwide Div ORIGWIDTH;
  pspriteiscale := FRACUNIT * ORIGWIDTH Div viewwidth_nonwide;

  // thing clipping
  For i := 0 To viewwidth - 1 Do Begin
    screenheightarray[i] := viewheight;
  End;

  // planes

  For i := 0 To VIEWHEIGHT - 1 Do Begin
    // [crispy] re-generate lookup-table for yslope[] (free look)
    // whenever "detailshift" or "screenblocks" change
    num := (viewwidth_nonwide Shl detailshift) Div 2 * FRACUNIT;
    For j := 0 To LOOKDIRS - 1 Do Begin
      If screenblocks < 11 Then Begin
        dy := ((i - (viewheight Div 2 + ((j - LOOKDIRMIN) * (1 Shl crispy.hires)) * (screenblocks) Div 10)) Shl FRACBITS) + FRACUNIT Div 2;
      End
      Else Begin
        dy := ((i - (viewheight Div 2 + ((j - LOOKDIRMIN) * (1 Shl crispy.hires)) * (11) Div 10)) Shl FRACBITS) + FRACUNIT Div 2;
      End;

      dy := abs(dy);
      yslopes[j][i] := FixedDiv(num, dy);
    End;
  End;
  yslope := @yslopes[LOOKDIRMIN];

  For i := 0 To viewwidth - 1 Do Begin
    cosadj := abs(finecosine[xtoviewangle[i] Shr ANGLETOFINESHIFT]); // Hier darf kein SarLongint sein !
    distscale[i] := FixedDiv(FRACUNIT, cosadj);
  End;

  // Calculate the light levels to use
  //  for each level / scale combination.

  For i := 0 To LIGHTLEVELS - 1 Do Begin
    startmap := ((LIGHTLEVELS - LIGHTBRIGHT - i) * 2) * NUMCOLORMAPS Div LIGHTLEVELS;

    For j := 0 To MAXLIGHTSCALE - 1 Do Begin
      level := startmap - j * NONWIDEWIDTH Div (viewwidth_nonwide Shl detailshift) Div DISTMAP;

      If (level < 0) Then level := 0;

      If (level >= NUMCOLORMAPS) Then level := NUMCOLORMAPS - 1;

      scalelight[i][j] := @colormaps[level * 256];
    End;
  End;

  // [crispy] lookup table for horizontal screen coordinates
  For i := 0 To SCREENWIDTH - 1 Do Begin
    If crispy.fliplevels Then Begin
      flipscreenwidth[i] := SCREENWIDTH - i - 1;
    End
    Else Begin
      flipscreenwidth[i] := i;
    End;
  End;
  //    flipviewwidth = flipscreenwidth + (crispy->fliplevels ? (SCREENWIDTH - scaledviewwidth) : 0);

  // [crispy] forcefully initialize the status bar backing screen
  ST_refreshBackground(true);

  pspr_interp := false; // interpolate weapon bobbing
End;

// [crispy] overflow-safe R_PointToAngle() flavor
// called only from R_CheckBBox(), R_AddLine() and P_SegLengths()

Function R_PointToAngleCrispy(x, y: fixed_t): angle_t;
Var
  y_viewy, x_viewx: Int64;
Begin
  // [crispy] fix overflows for very long distances
  y_viewy := int64(y) - viewy;
  x_viewx := int64(x) - viewx;

  // [crispy] the worst that could happen is e.g. INT_MIN-INT_MAX = 2*INT_MIN
  If (x_viewx < INT_MIN) Or (x_viewx > INT_MAX) Or
    (y_viewy < INT_MIN) Or (y_viewy > INT_MAX) Then Begin
    // [crispy] preserving the angle by halfing the distance in both directions
    x := x_viewx Div 2 + viewx;
    y := y_viewy Div 2 + viewy;
  End;

  result := R_PointToAngleSlope(x, y, @SlopeDivCrispy);
End;

//
// R_PointOnSide
// Traverse BSP (sub) tree,
//  check point against partition plane.
// Returns side 0 (front) or 1 (back).
//

Function R_PointOnSide(x, y: fixed_t; node: Pnode_t): int;
Var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
Begin
  If (node^.dx = 0) Then Begin
    If (x <= node^.x) Then Begin
      result := ord(node^.dy > 0);
      exit;
    End;

    result := ord(node^.dy < 0);
  End;
  If (node^.dy = 0) Then Begin
    If (y <= node^.y) Then Begin
      result := ord(node^.dx < 0);
      exit;
    End;

    result := ord(node^.dx > 0);
    exit;
  End;

  dx := (x - node^.x);
  dy := (y - node^.y);

  // Try to quickly decide by looking at sign bits.
  If ((node^.dy Xor node^.dx Xor dx Xor dy) And $80000000) <> 0 Then Begin
    If ((node^.dy Xor dx) And $80000000) <> 0 Then Begin
      // (left is negative)
      result := 1;
    End;
    result := 0;
  End;

  left := FixedMul(SarLongint(node^.dy, FRACBITS), dx);
  right := FixedMul(dy, SarLongint(node^.dx, FRACBITS));

  If (right < left) Then Begin
    // front side
    result := 0;
    exit;
  End;
  // back side
  result := 1;
End;

Function LerpFixed(oldvalue, newvalue: fixed_t): fixed_t;
Begin
  result := (oldvalue + FixedMul(newvalue - oldvalue, fractionaltic));
End;

Function LerpAngle(oangle, nangle: angle_t): angle_t;
//function
Begin
  If (nangle = oangle) Then Begin
    result := nangle;
  End
  Else If (nangle > oangle) Then Begin
    If (nangle - oangle < ANG270) Then Begin
      result := oangle + angle_t(((nangle - oangle) * FIXED2DOUBLE(fractionaltic)));
    End
    Else Begin // Wrapped around
      result := oangle - angle_t(((oangle - nangle) * FIXED2DOUBLE(fractionaltic)));
    End;
  End
  Else Begin // nangle < oangle
    If (oangle - nangle < ANG270) Then Begin
      result := oangle - angle_t(((oangle - nangle) * FIXED2DOUBLE(fractionaltic)));
    End
    Else Begin // Wrapped around
      result := oangle + angle_t(((nangle - oangle) * FIXED2DOUBLE(fractionaltic)));
    End;
  End;
End;

Procedure R_SetGoobers(mode: boolean);
Begin
  If (goobers_mode <> mode) Then Begin
    goobers_mode := mode;
    R_ExecuteSetViewSize();
  End;
End;

Function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): int;
Var
  lx, ly, ldx, ldy, dx, dy, left, right: fixed_t;
Begin

  lx := line^.v1^.x;
  ly := line^.v1^.y;

  ldx := line^.v2^.x - lx;
  ldy := line^.v2^.y - ly;

  If (ldx = 0) Then Begin
    If (x <= lx) Then Begin
      result := ord(ldy > 0);
      exit;
    End;
    result := ord(ldy < 0);
    exit;
  End;

  If (ldy = 0) Then Begin
    If (y <= ly) Then Begin
      result := ord(ldx < 0);
      exit;
    End;
    result := ord(ldx > 0);
    exit;
  End;

  dx := (x - lx);
  dy := (y - ly);

  // Try to quickly decide by looking at sign bits.
  If ((ldy Xor ldx Xor dx Xor dy) And $80000000) <> 0 Then Begin
    If ((ldy Xor dx) And $80000000) <> 0 Then Begin
      // (left is negative)
      result := 1;
      exit;
    End;
    result := 0;
    exit;
  End;

  left := FixedMul(SarLongint(ldy, FRACBITS), dx);
  right := FixedMul(dy, SarLongint(ldx, FRACBITS));

  If (right < left) Then Begin
    // front side
    result := 0;
    exit;
  End;
  // back side
  result := 1;
End;

Function R_PointInSubsector(x, y: fixed_t): Psubsector_t;
Var
  side: int;
  nodenum: int;
Begin
  // single subsector is a special case
  If (numnodes = 0) Then Begin
    result := @subsectors[0];
  End;
  nodenum := numnodes - 1;

  While ((nodenum And NF_SUBSECTOR) = 0) Do Begin
    side := R_PointOnSide(x, y, @nodes[nodenum]);
    nodenum := nodes[nodenum].children[side];
  End;
  result := @subsectors[integer(nodenum And (Not NF_SUBSECTOR))];
End;

Procedure R_SetupFrame(player: Pplayer_t);
Var
  i, tempCentery, pitch: int;
Begin

  viewplayer := player;

  // [AM] Interpolate the player camera if the feature is enabled.
  If ((crispy.uncapped <> 0) And (
    // Don't interpolate on the first tic of a level,
    // otherwise oldviewz might be garbage.
    leveltime > 1) And (
    // Don't interpolate if the player did something
    // that would necessitate turning it off for a tic.
    player^.mo^.interp <> 0) And (
    // Don't interpolate during a paused state
    leveltime > oldleveltime)) Then Begin
    //        const boolean use_localview = CheckLocalView(player);
    //
    //        // Interpolate player camera from their old position to their current one.
    //        viewx = LerpFixed(player->mo->oldx, player->mo->x);
    //        viewy = LerpFixed(player->mo->oldy, player->mo->y);
    //        viewz = LerpFixed(player->oldviewz, player->viewz);
    //        if (use_localview)
    //        {
    //            viewangle = (player->mo->angle + localview.angle -
    //                        localview.ticangle + LerpAngle(localview.oldticangle,
    //                                                       localview.ticangle)) + viewangleoffset;
    //        }
    //        else
    //        {
    //            viewangle = LerpAngle(player->mo->oldangle, player->mo->angle) + viewangleoffset;
    //        }
    //
    //        pitch = LerpInt(player->oldlookdir, player->lookdir) / MLOOKUNIT
    //                + LerpFixed(player->oldrecoilpitch, player->recoilpitch);
  End
  Else Begin
    viewx := player^.mo^.x;
    viewy := player^.mo^.y;
    viewz := player^.viewz;
    viewangle := angle_t(player^.mo^.angle + viewangleoffset);

    // [crispy] pitch is actual lookdir and weapon pitch
    pitch := player^.lookdir Div MLOOKUNIT + player^.recoilpitch;
  End;

  // [crispy] A11Y
  If (a11y_weapon_flash <> 0) Then Begin
    extralight := player^.extralight;
  End
  Else Begin
    extralight := 0;
  End;
  // [crispy] A11Y
  extralight := extralight + a11y_extra_lighting;

  If (pitch > LOOKDIRMAX) Then
    pitch := LOOKDIRMAX
  Else If (pitch < -LOOKDIRMIN) Then
    pitch := -LOOKDIRMIN;

  // apply new yslope[] whenever "lookdir", "detailshift" or "screenblocks" change
  If screenblocks < 11 Then Begin
    tempCentery := viewheight Div 2 + (pitch * (1 Shr crispy.hires)) * (screenblocks) Div 10;
  End
  Else Begin
    tempCentery := viewheight Div 2 + (pitch * (1 Shr crispy.hires)) * (11) Div 10;
  End;
  If (centery <> tempCentery) Then Begin
    centery := tempCentery;
    centeryfrac := centery Shl FRACBITS;
    yslope := @yslopes[LOOKDIRMIN + pitch];
  End;

  viewsin := finesine[viewangle Shr ANGLETOFINESHIFT];
  viewcos := finecosine[viewangle Shr ANGLETOFINESHIFT];

  sscount := 0;

  If (player^.fixedcolormap <> 0) Then Begin
    fixedcolormap :=
      colormaps
      + player^.fixedcolormap * (NUMCOLORMAPS Div 32) * 256; // [crispy] smooth diminishing lighting

    walllights := scalelightfixed;

    For i := 0 To MAXLIGHTSCALE - 1 Do
      scalelightfixed[i] := fixedcolormap;
  End
  Else Begin
    fixedcolormap := Nil;
  End;

  framecount := framecount + 1;
  validcount := validcount + 1;
End;

Procedure R_RenderPlayerView(player: Pplayer_t);
Begin
  R_SetupFrame(player);

  // Clear buffers.
  R_ClearClipSegs();
  R_ClearDrawSegs();
  R_ClearPlanes();
  R_ClearSprites();
  If (automapactive) And (crispy.automapoverlay = 0) Then Begin
    R_RenderBSPNode(numnodes - 1);
    exit;
  End;

  // [crispy] flashing HOM indicator
  If (crispy.flashinghom) Then Begin
    //        V_DrawFilledBox(viewwindowx, viewwindowy,
    //            scaledviewwidth, viewheight,
    //#ifndef CRISPY_TRUECOLOR
    //            176 + (gametic % 16));
    //#else
    //            pal_color[176 + (gametic % 16)]);
    //#endif
  End;

  // check for new console commands.
  NetUpdate();

  // [crispy] smooth texture scrolling
  R_InterpolateTextureOffsets();
  // The head node is the last node output.
  R_RenderBSPNode(numnodes - 1);

  // Check for new console commands.
  NetUpdate();

  R_DrawPlanes();

  // Check for new console commands.
  NetUpdate();

  // [crispy] draw fuzz effect independent of rendering frame rate
  R_SetFuzzPosDraw();
  R_DrawMasked();

  // Check for new console commands.
  NetUpdate();
End;

End.

