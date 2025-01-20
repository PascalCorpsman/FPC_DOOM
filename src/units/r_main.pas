Unit r_main;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , tables, info_types
  , m_fixed
  ;

Procedure R_Init();

Var
  // [crispy] parameterized for smooth diminishing lighting
  NUMCOLORMAPS: int;

  //int LIGHTLEVELS;
  //int LIGHTSEGSHIFT;
  LIGHTBRIGHT: int;
  //int MAXLIGHTSCALE;
  //int LIGHTSCALESHIFT;
  //int MAXLIGHTZ;
  //int LIGHTZSHIFT;

  viewx: fixed_t;
  viewy: fixed_t;
  viewz: fixed_t;

  viewangle: angle_t;
  centerxfrac: fixed_t;
  centeryfrac: fixed_t;
  sscount: int;

Procedure R_ExecuteSetViewSize();

Function R_PointToAngleCrispy(x, y: fixed_t): angle_t;

Function R_PointInSubsector(x, y: fixed_t): Psubsector_t;

Procedure R_RenderPlayerView(player: Pplayer_t);

Function R_PointOnSide(x, y: fixed_t; node: Pnode_t): int;

Function LerpFixed(oldvalue, newvalue: fixed_t): fixed_t;

Implementation

Uses
  a11y_weapon_pspr, doomdata
  , am_map
  , d_loop
  , i_video
  , r_data, r_sky, r_draw, r_plane, r_bsp, r_defs, r_things
  , m_menu
  , p_setup, p_tick, p_local, p_spec
  , st_stuff
  ;

Var
  // just for profiling purposes
  framecount: int;

  setsizeneeded: boolean;
  setblocks: int;
  setdetail: int;

  // bumped light from gun blasts
  extralight: int;

  viewangleoffset: int;
  viewcos: fixed_t;
  viewsin: fixed_t;

  // increment every time a check is made
  validcount: int = 1;


  fixedcolormap: Plighttable_t;

  viewplayer: pplayer_t;

  centerx: int;
  centery: int;

  projection: fixed_t;

  scaledviewwidth_nonwide, viewwidth_nonwide: int;
  centerxfrac_nonwide: fixed_t;

  // 0 = high, 1 = low
  detailshift: int;

  // [crispy] lookup table for horizontal screen coordinates
  //int		flipscreenwidth[MAXWIDTH];
  //int		*flipviewwidth;


  //  lighttable_t***		scalelight = NULL;
  //lighttable_t**		scalelightfixed = NULL;
  //lighttable_t***		zlight = NULL;

Procedure R_InitLightTables();
//        int		i;
//      int		j;
//      int		level;
//      int		startmap;
//      int		scale;
Begin

  //  If assigned(scalelight) Then Begin
  //  	for (i = 0; i < LIGHTLEVELS; i++)
  //  	{
  //  		free(scalelight[i]);
  //  	}
  //  	free(scalelight);
  //  End;

//      if (scalelightfixed)
//      {
//  	free(scalelightfixed);
//      }
//
//      if (zlight)
//      {
//  	for (i = 0; i < LIGHTLEVELS; i++)
//  	{
//  		free(zlight[i]);
//  	}
//  	free(zlight);
//      }
//
//     // [crispy] smooth diminishing lighting
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
//  	LIGHTLEVELS =      16;
//  	LIGHTSEGSHIFT =     4;
  LIGHTBRIGHT := 1;
  //  	MAXLIGHTSCALE =    48;
  //  	LIGHTSCALESHIFT =  12;
  //  	MAXLIGHTZ =       128;
  //  	LIGHTZSHIFT =      20;
  //      }
  //
  //      scalelight = malloc(LIGHTLEVELS * sizeof(*scalelight));
  //      scalelightfixed = malloc(MAXLIGHTSCALE * sizeof(*scalelightfixed));
  //      zlight = malloc(LIGHTLEVELS * sizeof(*zlight));
  //
  //      // Calculate the light levels to use
  //      //  for each level / distance combination.
  //      for (i=0 ; i< LIGHTLEVELS ; i++)
  //      {
  //  	scalelight[i] = malloc(MAXLIGHTSCALE * sizeof(**scalelight));
  //  	zlight[i] = malloc(MAXLIGHTZ * sizeof(**zlight));
  //
  //  	startmap = ((LIGHTLEVELS-LIGHTBRIGHT-i)*2)*NUMCOLORMAPS/LIGHTLEVELS;
  //  	for (j=0 ; j<MAXLIGHTZ ; j++)
  //  	{
  //  	    scale = FixedDiv ((ORIGWIDTH/2*FRACUNIT), (j+1)<<LIGHTZSHIFT);
  //  	    scale >>= LIGHTSCALESHIFT;
  //  	    level = startmap - scale/DISTMAP;
  //
  //  	    if (level < 0)
  //  		level = 0;
  //
  //  	    if (level >= NUMCOLORMAPS)
  //  		level = NUMCOLORMAPS-1;
  //
  //  	    zlight[i][j] = colormaps + level*256;
  //  	}
  //      }
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
    result := 0;
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
        result := ANG270 + tantoangle[slope_div(x, y)];
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
        result := ANG90 + tantoangle[slope_div(x, y)];
      End;
    End
    Else Begin
      // y<0
      y := -y;
      If (x > y) Then Begin
        // octant 4
        result := ANG180 + tantoangle[slope_div(y, x)];
      End
      Else Begin
        // octant 5
        result := angle_t(ANG270 - 1 - tantoangle[slope_div(x, y)]);
      End;
    End;
  End;
End;

// [crispy] overflow-safe R_PointToAngle() flavor
// called only from R_CheckBBox(), R_AddLine() and P_SegLengths()

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
    r_draw.viewheight := SCREENHEIGHT;
  End
    // [crispy] hard-code to SCREENWIDTH and SCREENHEIGHT minus status bar height
  Else If (setblocks = 10) Then Begin
    scaledviewwidth_nonwide := NONWIDEWIDTH;
    scaledviewwidth := SCREENWIDTH;
    r_draw.viewheight := SCREENHEIGHT - (ST_HEIGHT Shl 1);
  End
  Else Begin
    //	scaledviewwidth_nonwide = (setblocks*32)<<crispy->hires;
    //	viewheight = ((setblocks*168/10)&~7)<<crispy->hires;
    //
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
    //		scaledviewwidth = scaledviewwidth_nonwide;
    //	}
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

  //    if (!detailshift)
  //    {
  //	colfunc = basecolfunc = R_DrawColumn;
  //	fuzzcolfunc = R_DrawFuzzColumn;
  //	transcolfunc = R_DrawTranslatedColumn;
  //	tlcolfunc = R_DrawTLColumn;
  //	spanfunc = goobers_mode ? R_DrawSpanSolid : R_DrawSpan;
  //    }
  //    else
  //    {
  //	colfunc = basecolfunc = R_DrawColumnLow;
  //	fuzzcolfunc = R_DrawFuzzColumnLow;
  //	transcolfunc = R_DrawTranslatedColumnLow;
  //	tlcolfunc = R_DrawTLColumnLow;
  //	spanfunc = goobers_mode ? R_DrawSpanSolidLow : R_DrawSpanLow;
  //    }
  //
  //    R_InitBuffer (scaledviewwidth, viewheight);
  //
  //    R_InitTextureMapping ();
  //
  //    // psprite scales
  //    pspritescale = FRACUNIT*viewwidth_nonwide/ORIGWIDTH;
  //    pspriteiscale = FRACUNIT*ORIGWIDTH/viewwidth_nonwide;
  //
  //    // thing clipping
  //    for (i=0 ; i<viewwidth ; i++)
  //	screenheightarray[i] = viewheight;

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
  //
  //    for (i=0 ; i<viewwidth ; i++)
  //    {
  //	cosadj = abs(finecosine[xtoviewangle[i]>>ANGLETOFINESHIFT]);
  //	distscale[i] = FixedDiv (FRACUNIT,cosadj);
  //    }
  //
  //    // Calculate the light levels to use
  //    //  for each level / scale combination.
  //    for (i=0 ; i< LIGHTLEVELS ; i++)
  //    {
  //
  //	startmap = ((LIGHTLEVELS-LIGHTBRIGHT-i)*2)*NUMCOLORMAPS/LIGHTLEVELS;
  //	for (j=0 ; j<MAXLIGHTSCALE ; j++)
  //	{
  //	    level = startmap - j*NONWIDEWIDTH/(viewwidth_nonwide<<detailshift)/DISTMAP;
  //
  //	    if (level < 0)
  //		level = 0;
  //
  //	    if (level >= NUMCOLORMAPS)
  //		level = NUMCOLORMAPS-1;
  //
  //	    scalelight[i][j] = colormaps + level*256;
  //	}
  //    }
  //
  //    // [crispy] lookup table for horizontal screen coordinates
  //    for (i = 0, j = SCREENWIDTH - 1; i < SCREENWIDTH; i++, j--)
  //    {
  //	flipscreenwidth[i] = crispy->fliplevels ? j : i;
  //    }
  //
  //    flipviewwidth = flipscreenwidth + (crispy->fliplevels ? (SCREENWIDTH - scaledviewwidth) : 0);
  //
  //    // [crispy] forcefully initialize the status bar backing screen
  //    ST_refreshBackground(true);
  //
  //    pspr_interp = false; // interpolate weapon bobbing
End;

Function R_PointToAngleCrispy(x, y: fixed_t): angle_t;
Var
  y_viewy, x_viewx: Int64;
Begin
  // [crispy] fix overflows for very long distances
  y_viewy := y - viewy;
  x_viewx := x - viewx;

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
    player^.mo^.interp = true) And (
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
    viewangle := player^.mo^.angle + viewangleoffset;

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
    //	fixedcolormap =
    //	    colormaps
    //	    + player->fixedcolormap*(NUMCOLORMAPS / 32)*256; // [crispy] smooth diminishing lighting
    //
    //	walllights = scalelightfixed;
    //
    //	for (i=0 ; i<MAXLIGHTSCALE ; i++)
    //	    scalelightfixed[i] = fixedcolormap;
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

  //    R_DrawPlanes ();

  // Check for new console commands.
  NetUpdate();

  //    // [crispy] draw fuzz effect independent of rendering frame rate
  //    R_SetFuzzPosDraw();
  //    R_DrawMasked ();

  // Check for new console commands.
  NetUpdate();
End;

End.

