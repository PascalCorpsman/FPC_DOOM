Unit r_main;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , tables
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

Function R_PointToAngleCrispy(x, y: fixed_t): angle_t;

Implementation

Uses
  r_data, r_sky, r_draw, r_plane
  , m_menu
  ;

Var
  // just for profiling purposes
  framecount: int;

  setsizeneeded: boolean;
  setblocks: int;
  setdetail: int;

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


End.

