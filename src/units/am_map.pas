Unit am_map;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_event
  , m_cheat
  ;

Const
  // Used by ST StatusBar stuff.
  AM_MSGHEADER = ((ord('a') Shl 24) + (ord('m') Shl 16));
  AM_MSGENTERED = (AM_MSGHEADER Or (ord('e') Shl 8));
  AM_MSGEXITED = (AM_MSGHEADER Or (ord('x') Shl 8));

  cheat_amap: cheatseq_t = (sequence: 'iddt'; parameter_chars: 0);

Type

  fpoint_t = Record
    x, y: int;
  End;

  fline_t = Record
    a, b: fpoint_t;
  End;
  Pfline_t = ^fline_t;

  mpoint_t = Record
    x, y: int64_t;
  End;
  Pmpoint_t = ^mpoint_t;

  mline_t = Record
    a, b: mpoint_t;
  End;
  Pmline_t = ^mline_t;

  islope_t = Record
    slp, islp: fixed_t;
  End;

  keycolor_t = (
    no_key,
    red_key,
    yellow_key,
    blue_key
    );

  TdrawFLine = Procedure(fl: Pfline_t; color: int);

Var
  automapactive: boolean = false;

Procedure AM_initVariables();

Procedure AM_Ticker();

Function AM_Responder(Const ev: Pevent_t): boolean;

Procedure AM_Drawer();
Procedure AM_ResetIDDTcheat();
Procedure AM_Stop();

Implementation

Uses
  doomdata, doomtype, doomdef, doomstat, g_game, info_types, tables
  , d_loop, d_mode, d_englsh
  , i_video
  , m_controls, m_menu, m_fixed
  , p_setup, p_tick, p_local, p_mobj
  , r_main, r_things
  , st_stuff
  , v_patch, v_video, v_trans
  , w_wad
  , z_zone
  ;

Const

  // how much the automap moves window per tic in frame-buffer coordinates
  // moves 140 pixels in 1 second
  DEFINE_F_PANINC = 4;
  // [crispy] pan faster by holding run button
  F2_PANINC = 12;

  AM_NUMMARKPOINTS = 10;

  // For use if I do walls with outsides/insides
  REDS = (256 - 5 * 16);
  REDRANGE = 16;
  BLUES = (256 - 4 * 16 + 8);
  BLUERANGE = 8;
  GREENS = (7 * 16);
  GREENRANGE = 16;
  GRAYS = (6 * 16);
  GRAYSRANGE = 16;
  BROWNS = (4 * 16);
  BROWNRANGE = 16;
  YELLOWS = (256 - 32 + 7);
  YELLOWRANGE = 1;
  BLACK = 0;
  WHITE = (256 - 47);

  // Automap colors
  BACKGROUND = BLACK;
  YOURCOLORS = WHITE;
  YOURRANGE = 0;
  WALLRANGE = REDRANGE;
  TSWALLCOLORS = GRAYS;
  TSWALLRANGE = GRAYSRANGE;
  FDWALLRANGE = BROWNRANGE;
  CDWALLRANGE = YELLOWRANGE;
  THINGCOLORS = GREENS;
  THINGRANGE = GREENRANGE;
  //  CRISPY_HIGHLIGHT_ = REVEALED_SECRETS;
  SECRETWALLRANGE = WALLRANGE;
  GRIDCOLORS = (GRAYS + GRAYSRANGE Div 2);
  GRIDRANGE = 0;
  XHAIRCOLORS = GRAYS;

  // [crispy] FRACTOMAPBITS: overflow-safe coordinate system.
  // Written by Andrey Budko (entryway), adapted from prboom-plus/src/am_map.*
  MAPBITS = 12;
  MAPUNIT = (1 Shl MAPBITS);
  FRACTOMAPBITS = (FRACBITS - MAPBITS);
  MAPPLAYERRADIUS = (16 * (1 Shl MAPBITS));

  INITSCALEMTOF = (FRACUNIT Div 5);

  R = ((8 * MAPPLAYERRADIUS) Div 7);

  player_arrow: Array Of mline_t = (
    (a: (x: - R + R Div 8; y: 0); b: (x: R; y: 0)), // -----
    (a: (x: R; y: 0); b: (x: R - R Div 2; y: R Div 4)), // ----->
    (a: (x: R; y: 0); b: (x: R - R Div 2; y: - R Div 4)),
    (a: (x: - R + R Div 8; y: 0); b: (x: - R - R Div 8; y: R Div 4)), // >---->
    (a: (x: - R + R Div 8; y: 0); b: (x: - R - R Div 8; y: - R Div 4)),
    (a: (x: - R + 3 * R Div 8; y: 0); b: (x: - R + R Div 8; y: R Div 4)), // >>--->
    (a: (x: - R + 3 * R Div 8; y: 0); b: (x: - R + R Div 8; y: - R Div 4))
    );

  cheat_player_arrow: Array Of mline_t = (
    (a: (x: - R + R Div 8; y: 0); b: (x: R; y: 0)), // -----
    (a: (x: R; y: 0); b: (x: R - R Div 2; y: R Div 6)), // ----->
    (a: (x: R; y: 0); b: (x: R - R Div 2; y: - R Div 6)),
    (a: (x: - R + R Div 8; y: 0); b: (x: - R - R Div 8; y: R Div 6)), // >----->
    (a: (x: - R + R Div 8; y: 0); b: (x: - R - R Div 8; y: - R Div 6)),
    (a: (x: - R + 3 * R Div 8; y: 0); b: (x: - R + R Div 8; y: R Div 6)), // >>----->
    (a: (x: - R + 3 * R Div 8; y: 0); b: (x: - R + R Div 8; y: - R Div 6)),
    (a: (x: - R Div 2; y: 0); b: (x: - R Div 2; y: - R Div 6)), // >>-d--->
    (a: (x: - R Div 2; y: - R Div 6); b: (x: - R Div 2 + R Div 6; y: - R Div 6)),
    (a: (x: - R Div 2 + R Div 6; y: - R Div 6); b: (x: - R Div 2 + R Div 6; y: R Div 4)),
    (a: (x: - R Div 6; y: 0); b: (x: - R Div 6; y: - R Div 6)), // >>-dd-->
    (a: (x: - R Div 6; y: - R Div 6); b: (x: 0; y: - R Div 6)),
    (a: (x: 0; y: - R Div 6); b: (x: 0; y: R Div 4)),
    (a: (x: R Div 6; y: R Div 4); b: (x: R Div 6; y: - R Div 7)), // >>-ddt->
    (a: (x: R Div 6; y: - R Div 7); b: (x: R Div 6 + R Div 32; y: - R Div 7 - R Div 32)),
    (a: (x: R Div 6 + R Div 32; y: - R Div 7 - R Div 32); b: (x: R Div 6 + R Div 10; y: - R Div 7))
    );

  RR = (FRACUNIT);

  //  triangle_guy: Array Of mline_t = (
  //    (a: (x: trunc(-0.867 * RR); y: trunc(-0.5 * RR)); b: (x: trunc(0.867 * RR); y: trunc(-0.5 * RR))),
  //    (a: (x: trunc(0.867 * RR); y: trunc(-0.5 * RR)); b: (x: trunc(0); y: trunc(RR))),
  //    (a: (x: trunc(0); y: trunc(RR)); b: (x: trunc(-0.867 * RR); y: trunc(-0.5 * RR)))
  //    );

  thintriangle_guy: Array Of mline_t = (
    (a: (x: trunc(-0.5 * RR); y: trunc(-0.7 * RR)); b: (x: RR; y: 0)),
    (a: (x: RR; y: 0); b: (x: trunc(-0.5 * RR); y: trunc(0.7 * RR))),
    (a: (x: trunc(-0.5 * RR); y: trunc(0.7 * RR)); b: (x: trunc(-0.5 * RR); y: trunc(-0.7 * RR)))
    );

  // [crispy] print keys as crosses
  cross_mark: Array Of mline_t = (
    (a: (x: - RR; y: 0); b: (x: RR; y: 0)),
    (a: (x: 0; y: - RR); b: (x: 0; y: RR))
    );
  square_mark: Array Of mline_t = (
    (a: (x: - RR; y: 0); b: (x: 0; y: RR)),
    (a: (x: 0; y: RR); b: (x: RR; y: 0)),
    (a: (x: RR; y: 0); b: (x: 0; y: - RR)),
    (a: (x: 0; y: - RR); b: (x: - RR; y: 0))
    );

  // the following is crap
  LINE_NEVERSEE = ML_DONTDRAW;

Var
  f_paninc: int;
  m_zoomin_kbd: int;
  m_zoomout_kbd: int;
  WALLCOLORS: int; // Wird in AM_Start gesetzt, ist eigentlich const
  FDWALLCOLORS: int; // Wird in AM_Start gesetzt, ist eigentlich const
  CDWALLCOLORS: int; // Wird in AM_Start gesetzt, ist eigentlich const

  // [JN] Make wall colors of secret sectors palette-independent.
  secretwallcolors: int = -1; // wird in AM_LevelInit initialisiert
  revealedsecretwallcolors: int = -1; // wird in AM_LevelInit initialisiert

  lastlevel: int = -1;
  lastepisode: int = -1;

  cheating: int = 0;
  grid: int = 0; // 1 = Grid an, 0 = Grid aus

  // location of window on screen
  f_x: int;
  f_y: int;

  // size of window on screen
  f_w: int;
  f_h: int;

  lightlev: int; // used for funky strobing effect

  amclock: int;

  m_paninc, m_paninc2: mpoint_t; // how far the window pans each tic (map coords)
  m_paninc_target: mpoint_t; // [crispy] for interpolation
  mtof_zoommul: fixed_t; // how far the window zooms in each tic (map coords)
  ftom_zoommul: fixed_t; // how far the window zooms in each tic (fb coords)

  m_x, m_y: int64_t; // LL x,y where the window is on the map (map coords)
  m_x2, m_y2: int64_t; // UR x,y where the window is on the map (map coords)
  prev_m_x, prev_m_y: int64_t; // [crispy] for interpolation
  next_m_x, next_m_y: int64_t; // [crispy] for interpolation

  //
  // width/height of window on map (map coords)
  //
  m_w: int64_t;
  m_h: int64_t;

  // based on level size
  min_x: fixed_t;
  min_y: fixed_t;
  max_x: fixed_t;
  max_y: fixed_t;

  max_w: fixed_t; // max_x-min_x,
  max_h: fixed_t; // max_y-min_y

  // based on player size
  min_w: fixed_t;
  min_h: fixed_t;

  min_scale_mtof: fixed_t; // used to tell when to stop zooming out
  max_scale_mtof: fixed_t; // used to tell when to stop zooming in

  // old stuff for recovery later
  old_m_w, old_m_h: int64_t;
  old_m_x, old_m_y: int64_t;

  // used by MTOF to scale from map-to-frame-buffer coords
  scale_mtof: fixed_t = INITSCALEMTOF;
  // used by FTOM to scale from frame-buffer-to-map coords (=1/scale_mtof)
  scale_ftom: fixed_t;

  plr: ^player_t; // the player represented by an arrow

  marknums: Array[0..9] Of Ppatch_t; // numbers used for marking by the automap
  markpoints: Array[0..AM_NUMMARKPOINTS - 1] Of mpoint_t; // where the points are
  markpointnum: int = 0; // next point to be assigned

  followplayer: int = 1; // specifies whether to follow the player around

  stopped: boolean = true;

  AM_drawFline: TdrawFLine = Nil;
  mapangle: angle_t = 0;
  mapcenter: mpoint_t = (x: 0; y: 0);

  // translates between frame-buffer and map distances
  // [crispy] fix int overflow that causes map and grid lines to disappear

Function FTOM(x: int64): int64;
Begin
  result := SarInt64((((x) Shl FRACBITS) * scale_ftom), FRACBITS)
End;

Function MTOF(x: int64): int64;
Begin
  result := SarInt64(SarInt64(((x) * scale_mtof), FRACBITS), FRACBITS)
End;

Function CXMTOF(x: int64): int64;
Begin
  result := (f_x + MTOF((x) - m_x));
End;

Function CYMTOF(y: int64): int64;
Begin
  result := (f_y + (f_h - MTOF((y) - m_y)));
End;

//
// Classic Bresenham w/ whatever optimizations needed for speed
//

Procedure AM_drawFline_Vanilla(fl: Pfline_t; color: int);
  Procedure PutDot(xx, yy, cc: int);
  Begin
    I_VideoBuffer[yy * f_w + flipscreenwidth[xx]] := cc;
  End;
Var
  x, y, dx, dy, sx, sy, ax, ay, d: int;
Begin

  //    static int fuck = 0;
  //
  //    // For debugging only
  //    if (      fl->a.x < 0 || fl->a.x >= f_w
  //	   || fl->a.y < 0 || fl->a.y >= f_h
  //	   || fl->b.x < 0 || fl->b.x >= f_w
  //	   || fl->b.y < 0 || fl->b.y >= f_h)
  //    {
  //        DEH_fprintf(stderr, "fuck %d \r", fuck++);
  //	return;
  //    }

  dx := fl^.b.x - fl^.a.x;
  If dx < 0 Then Begin
    ax := 2 * (-dx);
    sx := -1;
  End
  Else Begin
    ax := 2 * (dx);
    sx := 1;
  End;

  dy := fl^.b.y - fl^.a.y;
  If dy < 0 Then Begin
    ay := 2 * (-dy);
    sy := -1;
  End
  Else Begin
    ay := 2 * (dy);
    sy := 1;
  End;

  x := fl^.a.x;
  y := fl^.a.y;

  If (ax > ay) Then Begin
    d := ay - ax Div 2;
    While (true) Do Begin
      PUTDOT(x, y, color);
      If (x = fl^.b.x) Then exit;
      If (d >= 0) Then Begin
        y := y + sy;
        d := d - ax;
      End;
      x := x + sx;
      d := d + ay;
    End;
  End
  Else Begin
    d := ax - ay Div 2;
    While (true) Do Begin
      PUTDOT(x, y, color);
      If (y = fl^.b.y) Then exit;
      If (d >= 0) Then Begin
        x := x + sx;
        d := d - ay;
      End;
      y := y + sy;
      d := d + ax;
    End;
  End;
End;

// [crispy] Adapted from Heretic's DrawWuLine

Procedure AM_drawFline_Smooth(fl: Pfline_t; color: int);
Begin
  Raise exception.create('Port me.');
  //      int X0 = fl->a.x, Y0 = fl->a.y, X1 = fl->b.x, Y1 = fl->b.y;
  //    pixel_t* BaseColor = &color_shades[color * NUMSHADES];
  //
  //    unsigned short IntensityShift, ErrorAdj, ErrorAcc;
  //    unsigned short ErrorAccTemp, Weighting, WeightingComplementMask;
  //    short DeltaX, DeltaY, Temp, XDir;
  //
  //    /* Make sure the line runs top to bottom */
  //    if (Y0 > Y1)
  //    {
  //        Temp = Y0;
  //        Y0 = Y1;
  //        Y1 = Temp;
  //        Temp = X0;
  //        X0 = X1;
  //        X1 = Temp;
  //    }
  //
  //    /* Draw the initial pixel, which is always exactly intersected by
  //       the line and so needs no weighting */
  //    /* Always write the raw color value because we've already performed the necessary lookup
  //     * into colormap */
  //    PUTDOT_RAW(X0, Y0, BaseColor[0]);
  //
  //    if ((DeltaX = X1 - X0) >= 0)
  //    {
  //        XDir = 1;
  //    }
  //    else
  //    {
  //        XDir = -1;
  //        DeltaX = -DeltaX;       /* make DeltaX positive */
  //    }
  //    /* Special-case horizontal, vertical, and diagonal lines, which
  //       require no weighting because they go right through the center of
  //       every pixel */
  //    if ((DeltaY = Y1 - Y0) == 0)
  //    {
  //        /* Horizontal line */
  //        while (DeltaX-- != 0)
  //        {
  //            X0 += XDir;
  //            PUTDOT_RAW(X0, Y0, BaseColor[0]);
  //        }
  //        return;
  //    }
  //    if (DeltaX == 0)
  //    {
  //        /* Vertical line */
  //        do
  //        {
  //            Y0++;
  //            PUTDOT_RAW(X0, Y0, BaseColor[0]);
  //        }
  //        while (--DeltaY != 0);
  //        return;
  //    }
  //    //diagonal line.
  //    if (DeltaX == DeltaY)
  //    {
  //        do
  //        {
  //            X0 += XDir;
  //            Y0++;
  //            PUTDOT_RAW(X0, Y0, BaseColor[0]);
  //        }
  //        while (--DeltaY != 0);
  //        return;
  //    }
  //    /* Line is not horizontal, diagonal, or vertical */
  //    ErrorAcc = 0;               /* initialize the line error accumulator to 0 */
  //    /* # of bits by which to shift ErrorAcc to get intensity level */
  //    IntensityShift = 16 - NUMSHADES_BITS;
  //    /* Mask used to flip all bits in an intensity weighting, producing the
  //       result (1 - intensity weighting) */
  //    WeightingComplementMask = NUMSHADES - 1;
  //    /* Is this an X-major or Y-major line? */
  //    if (DeltaY > DeltaX)
  //    {
  //        /* Y-major line; calculate 16-bit fixed-point fractional part of a
  //           pixel that X advances each time Y advances 1 pixel, truncating the
  //           result so that we won't overrun the endpoint along the X axis */
  //        ErrorAdj = ((unsigned int) DeltaX << 16) / (unsigned int) DeltaY;
  //        /* Draw all pixels other than the first and last */
  //        while (--DeltaY)
  //        {
  //            ErrorAccTemp = ErrorAcc;    /* remember currrent accumulated error */
  //            ErrorAcc += ErrorAdj;       /* calculate error for next pixel */
  //            if (ErrorAcc <= ErrorAccTemp)
  //            {
  //                /* The error accumulator turned over, so advance the X coord */
  //                X0 += XDir;
  //            }
  //            Y0++;               /* Y-major, so always advance Y */
  //            /* The IntensityBits most significant bits of ErrorAcc give us the
  //               intensity weighting for this pixel, and the complement of the
  //               weighting for the paired pixel */
  //            Weighting = ErrorAcc >> IntensityShift;
  //            PUTDOT_RAW(X0, Y0, BaseColor[Weighting]);
  //            PUTDOT_RAW(X0 + XDir, Y0, BaseColor[(Weighting ^ WeightingComplementMask)]);
  //        }
  //        /* Draw the final pixel, which is always exactly intersected by the line
  //           and so needs no weighting */
  //        PUTDOT_RAW(X1, Y1, BaseColor[0]);
  //        return;
  //    }
  //    /* It's an X-major line; calculate 16-bit fixed-point fractional part of a
  //       pixel that Y advances each time X advances 1 pixel, truncating the
  //       result to avoid overrunning the endpoint along the X axis */
  //    ErrorAdj = ((unsigned int) DeltaY << 16) / (unsigned int) DeltaX;
  //    /* Draw all pixels other than the first and last */
  //    while (--DeltaX)
  //    {
  //        ErrorAccTemp = ErrorAcc;        /* remember currrent accumulated error */
  //        ErrorAcc += ErrorAdj;   /* calculate error for next pixel */
  //        if (ErrorAcc <= ErrorAccTemp)
  //        {
  //            /* The error accumulator turned over, so advance the Y coord */
  //            Y0++;
  //        }
  //        X0 += XDir;             /* X-major, so always advance X */
  //        /* The IntensityBits most significant bits of ErrorAcc give us the
  //           intensity weighting for this pixel, and the complement of the
  //           weighting for the paired pixel */
  //        Weighting = ErrorAcc >> IntensityShift;
  //        PUTDOT_RAW(X0, Y0, BaseColor[Weighting]);
  //        PUTDOT_RAW(X0, Y0 + 1, BaseColor[(Weighting ^ WeightingComplementMask)]);
  //
  //    }
  //    /* Draw the final pixel, which is always exactly intersected by the line
  //       and so needs no weighting */
  //    PUTDOT_RAW(X1, Y1, BaseColor[0]);
End;

// [crispy] rotate point around map center
// adapted from prboom-plus/src/am_map.c:898-920

Procedure AM_rotatePoint(pt: Pmpoint_t);
Var
  tmpx: int64_t;
  smoothangle: angle_t;
Begin
  // [crispy] smooth automap rotation
  If followplayer <> 0 Then Begin
    smoothangle := angle_t(ANG90 - viewangle);
  End
  Else Begin
    smoothangle := mapangle;
  End;

  pt^.x := pt^.x - mapcenter.x;
  pt^.y := pt^.y - mapcenter.y;

  tmpx := int64_t(FixedMul(pt^.x, finecosine[smoothangle Shr ANGLETOFINESHIFT]))
    - int64_t(FixedMul(pt^.y, finesine[smoothangle Shr ANGLETOFINESHIFT]))
    + mapcenter.x;

  pt^.y := int64_t(FixedMul(pt^.x, finesine[smoothangle Shr ANGLETOFINESHIFT]))
    + int64_t(FixedMul(pt^.y, finecosine[smoothangle Shr ANGLETOFINESHIFT]))
    + mapcenter.y;

  pt^.x := tmpx;
End;

//
// Rotation in 2D.
// Used to rotate player arrow line character.
//

Procedure AM_rotate(x: Pint64_t; y: Pint64_t; a: angle_t);
Var
  tmpx: int64_t;
Begin
  tmpx :=
    FixedMul(x^, finecosine[a Shr ANGLETOFINESHIFT])
    - FixedMul(y^, finesine[a Shr ANGLETOFINESHIFT]);

  y^ :=
    FixedMul(x^, finesine[a Shr ANGLETOFINESHIFT])
    + FixedMul(y^, finecosine[a Shr ANGLETOFINESHIFT]);

  x^ := tmpx;
End;

//
// Clear automap frame buffer.
//

Procedure AM_clearFB(color: int);
Begin
  FillChar(I_VideoBuffer[0], f_w * f_h * sizeof(pixel_t), color);
End;

Procedure AM_unloadPics();
Var
  i: integer;
Begin
  For i := 0 To 9 Do Begin
    W_ReleaseLumpName(format('AMMNUM%d', [i]));
  End;
End;

//
// adds a marker at the current location
//

Procedure AM_addMark();
Begin
  // [crispy] keep the map static in overlay mode
  //  If Not following the player
  If (Not ((followplayer = 0) And (crispy.automapoverlay <> 0))) Then Begin
    markpoints[markpointnum].x := m_x + m_w Div 2;
    markpoints[markpointnum].y := m_y + m_h Div 2;
  End
  Else Begin
    markpoints[markpointnum].x := SarLongint(plr^.mo^.x, FRACTOMAPBITS);
    markpoints[markpointnum].y := SarLongint(plr^.mo^.y, FRACTOMAPBITS);
  End;
  markpointnum := (markpointnum + 1) Mod AM_NUMMARKPOINTS;
End;

Procedure AM_clearMarks();
Var
  i: int;
Begin
  For i := 0 To AM_NUMMARKPOINTS - 1 Do
    markpoints[i].x := -1; // means empty
  markpointnum := 0;
End;

Procedure AM_Stop();
Const
  st_notify: event_t = (
    _type: ev_keyup;
    data1: AM_MSGEXITED;
    data2: 0;
    data3: 0;
    data4: 0;
    data5: 0;
    data6: 0
    );
Begin
  AM_unloadPics();
  automapactive := false;
  ST_Responder(@st_notify);
  stopped := true;
End;

//
// Determines bounding box of all vertices,
// sets global variables controlling zoom range.
//

Procedure AM_findMinMaxBoundaries();
Var
  i: int;
  a: fixed_t;
  b: fixed_t;

Begin

  min_x := INT_MAX;
  min_y := INT_MAX;
  max_x := -INT_MAX;
  max_y := -INT_MAX;

  For i := 0 To numvertexes - 1 Do Begin
    If (vertexes[i].x < min_x) Then
      min_x := vertexes[i].x
    Else If (vertexes[i].x > max_x) Then
      max_x := vertexes[i].x;

    If (vertexes[i].y < min_y) Then
      min_y := vertexes[i].y
    Else If (vertexes[i].y > max_y) Then
      max_y := vertexes[i].y;
  End;

  // [crispy] cope with huge level dimensions which span the entire INT range
  max_x := SarLongint(max_x, FRACTOMAPBITS);
  min_x := SarLongint(min_x, FRACTOMAPBITS);
  max_y := SarLongint(max_y, FRACTOMAPBITS);
  min_y := SarLongint(min_y, FRACTOMAPBITS);
  max_w := (max_x) - (min_x);
  max_h := (max_y) - (min_y);

  min_w := 2 * MAPPLAYERRADIUS; // const? never changed?
  min_h := 2 * MAPPLAYERRADIUS;

  a := FixedDiv(f_w Shl FRACBITS, max_w);
  b := FixedDiv(f_h Shl FRACBITS, max_h);

  If a < b Then Begin
    min_scale_mtof := a;
  End
  Else Begin
    min_scale_mtof := b;
  End;
  max_scale_mtof := FixedDiv(f_h Shl FRACBITS, 2 * MAPPLAYERRADIUS);
End;

Procedure AM_drawCrosshair(color: int; force: boolean);
Const
  h: fline_t = (a: (x: 0; y: 0); b: (x: 0; y: 0));
  v: fline_t = (a: (x: 0; y: 0); b: (x: 0; y: 0));
Begin
  // [crispy] draw an actual crosshair
  If (followplayer = 0) Or (force) Then Begin
    If (h.a.x = 0) Or (force) Then Begin
      h.a.x := f_x + f_w Div 2;
      h.b.x := f_x + f_w Div 2;
      v.a.x := f_x + f_w Div 2;
      v.b.x := f_x + f_w Div 2;
      h.a.y := f_y + f_h Div 2;
      h.b.y := f_y + f_h Div 2;
      v.a.y := f_y + f_h Div 2;
      v.b.y := f_y + f_h Div 2;
      h.a.x := h.a.x - 2;
      h.b.x := h.b.x + 2;
      v.a.y := v.a.y - 2;
      v.b.y := v.b.y + 2;
    End;
    AM_drawFline(@h, color);
    AM_drawFline(@v, color);
  End;
End;

//
// should be called at the start of every level
// right now, i figure it out myself
//

Procedure AM_LevelInit(reinit: boolean);
Const
  f_h_old: int = 0;
  precalc_once: int = 0; // [crispy] Only need to precalculate color lookup tables once
Var
  a, b: fixed_t;
  playpal: PByte;
  // color: int;
Begin

  f_x := 0;
  f_y := 0;
  f_w := SCREENWIDTH;
  f_h := SCREENHEIGHT - (ST_HEIGHT Shl crispy.hires); // im Kartenmodus ist das HUD immer an !

  If Crispy.smoothmap <> 0 Then Begin
    AM_drawFline := @AM_drawFline_Smooth;
  End
  Else Begin
    AM_drawFline := @AM_drawFline_Vanilla;
  End;

  If (Not reinit) Then AM_clearMarks();

  AM_findMinMaxBoundaries();
  // [crispy] preserve map scale when re-initializing
  If (reinit And (f_h_old <> 0)) Then Begin
    scale_mtof := scale_mtof * f_h Div f_h_old;
    AM_drawCrosshair(XHAIRCOLORS, true);
  End
  Else Begin
    // [crispy] initialize zoomlevel on all maps so that a 4096 units
    // square map would just fit in (MAP01 is 3376x3648 units)
    If SarLongint(max_w, MAPBITS) < 2048 Then Begin
      a := FixedDiv(f_w, 2 * SarLongint(max_w, MAPBITS));
    End
    Else Begin
      a := FixedDiv(f_w, 4096);
    End;
    If (SarLongint(max_h, MAPBITS) < 2048) Then Begin
      b := FixedDiv(f_h, 2 * SarLongint(max_h, MAPBITS));
    End
    Else Begin
      b := FixedDiv(f_h, 4096);
    End;
    If a < b Then Begin
      scale_mtof := FixedDiv(a, trunc(0.7 * MAPUNIT));
    End
    Else Begin
      scale_mtof := FixedDiv(b, trunc(0.7 * MAPUNIT));
    End;
  End;
  If (scale_mtof > max_scale_mtof) Then
    scale_mtof := min_scale_mtof;
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);

  f_h_old := f_h;

  // [crispy] Precalculate color lookup tables for antialiased line drawing using COLORMAP
  If (precalc_once = 0) Then Begin
    playpal := W_CacheLumpName('PLAYPAL', PU_STATIC);

    precalc_once := 1;
    //    For color := 0 To 255 Do Begin
    //#define REINDEX(I) (color + I * 256)
    //            // Pick a range of shades for a steep gradient to keep lines thin
    //            int shade_index[NUMSHADES] =
    //            {
    //                REINDEX(0), REINDEX(1), REINDEX(2), REINDEX(3), REINDEX(7), REINDEX(15), REINDEX(23), REINDEX(31),
    //            };
    //#undef REINDEX
    //            for (int shade = 0; shade < NUMSHADES; ++shade)
    //            {
    //                color_shades[color * NUMSHADES + shade] = colormaps[shade_index[shade]];
    //            }
    //    End;

    // [crispy] Make secret wall colors independent from PLAYPAL color indexes
    secretwallcolors := V_GetPaletteIndex(playpal, 255, 0, 255);
    revealedsecretwallcolors := V_GetPaletteIndex(playpal, 119, 255, 111);

    W_ReleaseLumpName('PLAYPAL');
  End;
End;

Procedure AM_changeWindowLoc();
Var
  incx, incy: int64_t;
Begin

  // [crispy] accumulate automap panning by keyboard and mouse
  If (crispy.uncapped <> 0) And (leveltime > oldleveltime) Then Begin
    incx := FixedMul(m_paninc_target.x, fractionaltic);
    incy := FixedMul(m_paninc_target.y, fractionaltic);
  End
  Else Begin
    incx := m_paninc_target.x;
    incy := m_paninc_target.y;
  End;
  If (crispy.automaprotate <> 0) Then Begin
    AM_rotate(@incx, @incy, angle_t(-mapangle));
  End;
  m_x := prev_m_x + incx;
  m_y := prev_m_y + incy;

  If (m_x + m_w Div 2 > max_x) Then Begin
    next_m_x := max_x - m_w Div 2;
    m_x := max_x - m_w Div 2;
  End
  Else If (m_x + m_w Div 2 < min_x) Then Begin
    next_m_x := min_x - m_w Div 2;
    m_x := min_x - m_w Div 2;
  End;

  If (m_y + m_h Div 2 > max_y) Then Begin
    next_m_y := max_y - m_h Div 2;
    m_y := max_y - m_h Div 2;
  End
  Else If (m_y + m_h Div 2 < min_y) Then Begin
    next_m_y := min_y - m_h Div 2;
    m_y := min_y - m_h Div 2;
  End;

  m_x2 := m_x + m_w;
  m_y2 := m_y + m_h;
End;

Procedure AM_initVariables();
Const
  st_notify: event_t = (
    _type: ev_keyup;
    data1: AM_MSGENTERED;
    data2: 0;
    data3: 0;
    data4: 0;
    data5: 0;
    data6: 0
    );
Begin

  automapactive := true;

  amclock := 0;
  lightlev := 0;

  m_paninc.x := 0;
  m_paninc.y := 0;
  m_paninc2.x := 0;
  m_paninc2.y := 0;
  ftom_zoommul := FRACUNIT;
  mtof_zoommul := FRACUNIT;
  // mousewheelzoom := false; // [crispy]

  m_w := FTOM(f_w);
  m_h := FTOM(f_h);

  // [crispy] find player to center
  plr := @players[displayplayer];

  next_m_x := SarLongint(plr^.mo^.x, FRACTOMAPBITS) - m_w Div 2;
  next_m_y := SarLongint(plr^.mo^.y, FRACTOMAPBITS) - m_h Div 2;

  AM_Ticker(); // [crispy] initialize variables for interpolation
  AM_changeWindowLoc();

  // for saving & restoring
  old_m_x := m_x;
  old_m_y := m_y;
  old_m_w := m_w;
  old_m_h := m_h;

  // inform the status bar of the change
  ST_Responder(@st_notify);
End;

Procedure AM_loadPics();
Var
  i: int;
Begin
  For i := 0 To 9 Do Begin
    marknums[i] := W_CacheLumpName(format('AMMNUM%d', [i]), PU_STATIC);
  End;
End;

Procedure AM_Start();
Begin
  If (Not stopped) Then AM_Stop();
  stopped := false;
  If crispy.extautomap <> 0 Then Begin
    WALLCOLORS := REDS + 4; // [crispy] slightly darker red
    FDWALLCOLORS := BROWNS + 6; // [crispy] darker brown
    CDWALLCOLORS := 163; // [crispy] golden yellow
  End
  Else Begin
    WALLCOLORS := REDS; // [crispy] slightly darker red
    FDWALLCOLORS := BROWNS; // [crispy] darker brown
    CDWALLCOLORS := YELLOWS; // [crispy] golden yellow
  End;
  If (lastlevel <> gamemap) Or (lastepisode <> gameepisode) Then Begin
    AM_LevelInit(false);
    lastlevel := gamemap;
    lastepisode := gameepisode;
  End;
  AM_initVariables();
  AM_loadPics();
End;

Procedure AM_doFollowPlayer();
Begin
  // [crispy] FTOM(MTOF()) is needed to fix map line jitter in follow mode.
  If (crispy.hires <> 0) Then Begin
    m_x := SarLongint(viewx, FRACTOMAPBITS) - m_w Div 2;
    m_y := SarLongint(viewy, FRACTOMAPBITS) - m_h Div 2;
  End
  Else Begin
    m_x := FTOM(MTOF(SarLongint(viewx, FRACTOMAPBITS))) - m_w Div 2;
    m_y := FTOM(MTOF(SarLongint(viewy, FRACTOMAPBITS))) - m_h Div 2;
  End;
  next_m_x := m_x;
  next_m_y := m_y;
  m_x2 := m_x + m_w;
  m_y2 := m_y + m_h;
End;

//
//
//

Procedure AM_activateNewScale();
Begin
  m_x := m_x + m_w Div 2;
  m_y := m_y + m_h Div 2;
  m_w := FTOM(f_w);
  m_h := FTOM(f_h);
  m_x := m_x - m_w Div 2;
  m_y := m_y - m_h Div 2;
  m_x2 := m_x + m_w;
  m_y2 := m_y + m_h;
  next_m_x := m_x; // [crispy]
  next_m_y := m_y; // [crispy]
End;

//
// set the window scale to the maximum size
//

Procedure AM_minOutWindowScale();
Begin
  scale_mtof := min_scale_mtof;
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);
  AM_activateNewScale();
End;

//
// set the window scale to the minimum size
//

Procedure AM_maxOutWindowScale();
Begin
  scale_mtof := max_scale_mtof;
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);
  AM_activateNewScale();
End;

//
// Zooming
//

Procedure AM_changeWindowScale();
Begin

  // Change the scaling multipliers
  scale_mtof := FixedMul(scale_mtof, mtof_zoommul);
  scale_ftom := FixedDiv(FRACUNIT, scale_mtof);

  // [crispy] reset after zooming with the mouse wheel
//  If (mousewheelzoom) Then Begin
//    mtof_zoommul := FRACUNIT;
//    ftom_zoommul := FRACUNIT;
//    mousewheelzoom := false;
//  End;

  If (scale_mtof < min_scale_mtof) Then
    AM_minOutWindowScale()
  Else If (scale_mtof > max_scale_mtof) Then
    AM_maxOutWindowScale()
  Else
    AM_activateNewScale();
End;

// [crispy] Function called by AM_Ticker for stable panning interpolation

Procedure AM_changeWindowLocTick();
Var
  incx, incy: int64_t;
Begin

  incx := m_paninc_target.x;
  incy := m_paninc_target.y;

  If (m_paninc_target.x <> 0) Or (m_paninc_target.y <> 0) Then Begin
    followplayer := 0;
  End;

  If (crispy.automaprotate <> 0) Then Begin
    AM_rotate(@incx, @incy, -mapangle);
  End;

  next_m_x := next_m_x + incx;
  next_m_y := next_m_y + incy;

  // next_m_x and next_m_y clipping happen in AM_changeWindowLoc
End;

//
// Updates on Game Tick
//

Procedure AM_Ticker();
Begin
  If (Not automapactive) Then exit;

  amclock := amclock + 1;

  // [crispy] sync up for interpolation
  m_x := next_m_x;
  prev_m_x := next_m_x;
  m_y := next_m_y;
  prev_m_y := next_m_y;

  m_paninc_target.x := m_paninc.x + m_paninc2.x;
  m_paninc_target.y := m_paninc.y + m_paninc2.y;

  // [crispy] reset after moving with the mouse
  m_paninc2.x := 0;
  m_paninc2.y := 0;

  If (followplayer <> 0) Then
    AM_doFollowPlayer();

  // Change the zoom if necessary
  If (ftom_zoommul <> FRACUNIT) Then
    AM_changeWindowScale();

  If (m_paninc_target.x <> 0) Or (m_paninc_target.y <> 0) Then
    AM_changeWindowLocTick();

  // Update light level
  // AM_updateLightLev();
End;

// how much zoom-in per tic
// goes to 2x in 1 second

Function M_ZOOMIN(): int;
Begin
  result := (trunc(1.02 * FRACUNIT));
End;

Function M_ZOOMOUT(): int;
Begin
  result := (trunc(FRACUNIT / 1.02))
End;

Function AM_Responder(Const ev: Pevent_t): boolean;
Var
  rc: boolean;
  bigstate: int;
  //    static char buffer[20];
  key: int;
Begin
  bigstate := 0;
  //    extern boolean speedkeydown (void);
  //
  //    // [crispy] toggleable pan/zoom speed
  //    if (speedkeydown())
  //    {
  //        f_paninc = F2_PANINC;
  //        m_zoomin_kbd = M2_ZOOMIN;
  //        m_zoomout_kbd = M2_ZOOMOUT;
  //        m_zoomin_mouse = M2_ZOOMINFAST;
  //        m_zoomout_mouse = M2_ZOOMOUTFAST;
  //    }
  //    else
  //    {
  f_paninc := DEFINE_F_PANINC;
  m_zoomin_kbd := M_ZOOMIN();
  m_zoomout_kbd := M_ZOOMOUT();
  //        m_zoomin_mouse = M2_ZOOMIN;
  //        m_zoomout_mouse = M2_ZOOMOUT;
  //    }

  rc := false;

  //    if (ev->type == ev_joystick && joybautomap >= 0
  //        && (ev->data1 & (1 << joybautomap)) != 0)
  //    {
  //        joywait = I_GetTime() + 5;
  //
  //        if (!automapactive)
  //        {
  //            AM_Start ();
  //            viewactive = false;
  //        }
  //        else
  //        {
  //            bigstate = 0;
  //            viewactive = true;
  //            AM_Stop ();
  //        }
  //
  //        return true;
  //    }
  //
  If (Not automapactive) Then Begin
    If (ev^._type = ev_keydown) And (ev^.data1 = key_map_toggle) Then Begin
      AM_Start();
      viewactive := false;
      rc := true;
    End;
  End
    // [crispy] zoom and move Automap with the mouse (wheel)
  Else If (ev^._type = ev_mouse) And ((crispy.automapoverlay = 0) And (Not menuactive) And (Not inhelpscreens)) Then Begin
    //	if (mousebmapzoomout >= 0 && ev->data1 & (1 << mousebmapzoomout))
    //	{
    //		mtof_zoommul = m_zoomout_mouse;
    //		ftom_zoommul = m_zoomin_mouse;
    //		mousewheelzoom = true;
    //		rc = true;
    //	}
    //	else
    //	if (mousebmapzoomin >= 0 && ev->data1 & (1 << mousebmapzoomin))
    //	{
    //		mtof_zoommul = m_zoomin_mouse;
    //		ftom_zoommul = m_zoomout_mouse;
    //		mousewheelzoom = true;
    //		rc = true;
    //	}
    //	else
    //	if (mousebmapmaxzoom >= 0 && ev->data1 & (1 << mousebmapmaxzoom))
    //	{
    //		bigstate = !bigstate;
    //		if (bigstate)
    //		{
    //			AM_saveScaleAndLoc();
    //			AM_minOutWindowScale();
    //		}
    //		else AM_restoreScaleAndLoc();
    //	}
    //	else
    //	if (mousebmapfollow >= 0 && ev->data1 & (1 << mousebmapfollow))
    //	{
    //		followplayer = !followplayer;
    //		if (followplayer)
    //			plr->message = DEH_String(AMSTR_FOLLOWON);
    //		else
    //			plr->message = DEH_String(AMSTR_FOLLOWOFF);
    //	}
    //	else
    //	if (!followplayer && (ev->data2 || ev->data3))
    //	{
    //		// [crispy] mouse sensitivity for strafe
    //		const int flip_x = (ev->data2*(mouseSensitivity_x2+5)/(160 >> crispy->hires));
    //		m_paninc2.x = crispy->fliplevels ? -FTOM(flip_x) : FTOM(flip_x);
    //		m_paninc2.y = FTOM(ev->data3*(mouseSensitivity_x2+5)/(160 >> crispy->hires));
    //		rc = true;
    //	}
  End
  Else If (ev^._type = ev_keydown) Then Begin

    rc := true;
    key := ev^.data1;

    If (key = key_map_east) Then Begin // pan right
      // [crispy] keep the map static in overlay mode
      // if not following the player
      If (followplayer = 0) Then Begin
        If crispy.fliplevels Then Begin
          m_paninc.x := -FTOM(f_paninc Shl crispy.hires);
        End
        Else Begin
          m_paninc.x := FTOM(f_paninc Shl crispy.hires);
        End;
      End
      Else
        rc := false;
    End
    Else If (key = key_map_west) Then Begin // pan left
      If (followplayer = 0) Then Begin
        If crispy.fliplevels Then Begin
          m_paninc.x := FTOM(f_paninc Shl crispy.hires);
        End
        Else Begin
          m_paninc.x := -FTOM(f_paninc Shl crispy.hires);
        End;
      End
      Else
        rc := false;
    End
      //        else if (key == key_map_north)    // pan up
      //        {
      //            if (!followplayer)
      //                m_paninc.y = FTOM(f_paninc << crispy->hires);
      //            else rc = false;
      //        }
      //        else if (key == key_map_south)    // pan down
      //        {
      //            if (!followplayer)
      //                m_paninc.y = -FTOM(f_paninc << crispy->hires);
      //            else rc = false;
      //        }
    Else If (key = key_map_zoomout) Then Begin // zoom out
      mtof_zoommul := m_zoomout_kbd;
      ftom_zoommul := m_zoomin_kbd;
    End
    Else If (key = key_map_zoomin) Then Begin // zoom in
      mtof_zoommul := m_zoomin_kbd;
      ftom_zoommul := m_zoomout_kbd;
    End
    Else If (key = key_map_toggle) Then Begin
      bigstate := 0;
      viewactive := true;
      AM_Stop();
    End
      //        else if (key == key_map_maxzoom)
      //        {
      //            bigstate = !bigstate;
      //            if (bigstate)
      //            {
      //                AM_saveScaleAndLoc();
      //                AM_minOutWindowScale();
      //            }
      //            else AM_restoreScaleAndLoc();
      //        }
      //        else if (key == key_map_follow)
      //        {
      //            followplayer = !followplayer;
      //            if (followplayer)
      //                plr->message = DEH_String(AMSTR_FOLLOWON);
      //            else
      //                plr->message = DEH_String(AMSTR_FOLLOWOFF);
      //        }
      //        else if (key == key_map_grid)
      //        {
      //            grid = !grid;
      //            if (grid)
      //                plr->message = DEH_String(AMSTR_GRIDON);
      //            else
      //                plr->message = DEH_String(AMSTR_GRIDOFF);
      //        }
    Else If (key = key_map_mark) Then Begin
      plr^.message := format('%s %d', [AMSTR_MARKEDSPOT, markpointnum]);
      AM_addMark();
    End
    Else If (key = key_map_clearmark) Then Begin
      AM_clearMarks();
      plr^.message := AMSTR_MARKSCLEARED;
    End
    Else If (key = key_map_overlay) Then Begin

      // [crispy] force redraw status bar
      inhelpscreens := true;

      crispy.automapoverlay := 1 - crispy.automapoverlay;
      If (crispy.automapoverlay <> 0) Then
        plr^.message := AMSTR_OVERLAYON
      Else
        plr^.message := AMSTR_OVERLAYOFF;
    End
    Else If (key = key_map_rotate) Then Begin

      crispy.automaprotate := 1 - crispy.automaprotate;
      If (crispy.automaprotate <> 0) Then
        plr^.message := AMSTR_ROTATEON
      Else
        plr^.message := AMSTR_ROTATEOFF;
    End
    Else Begin
      rc := false;
    End;
    If ((deathmatch = 0) Or (gameversion <= exe_doom_1_8))
      And (cht_CheckCheat(cheat_amap, chr(ev^.data2)) <> 0) Then Begin
      rc := false;
      cheating := (cheating + 1) Mod 3;
    End;
  End
  Else If (ev^._type = ev_keyup) Then Begin

    rc := false;
    key := ev^.data1;

    //        if (key == key_map_east)
    //        {
    //            if (!followplayer) m_paninc.x = 0;
    //        }
    //        else if (key == key_map_west)
    //        {
    //            if (!followplayer) m_paninc.x = 0;
    //        }
    //        else if (key == key_map_north)
    //        {
    //            if (!followplayer) m_paninc.y = 0;
    //        }
    //        else if (key == key_map_south)
    //        {
    //            if (!followplayer) m_paninc.y = 0;
    //        }
    //        else
    If (key = key_map_zoomout) Or (key = key_map_zoomin) Then Begin
      mtof_zoommul := FRACUNIT;
      ftom_zoommul := FRACUNIT;
    End;
  End;

  result := rc;
End;


//
// Automap clipping of lines.
//
// Based on Cohen-Sutherland clipping algorithm but with a slightly
// faster reject and precalculated slopes.  If the speed is needed,
// use a hash algorithm to handle the common cases.
//

Function AM_clipMline(ml: Pmline_t; fl: Pfline_t): boolean;
Const
  LEFT = 1;
  RIGHT = 2;
  BOTTOM = 4;
  TOP = 8;

  Procedure DOOUTCODE(Out oc: int; mx, my: int64_t);
  Begin
    oc := 0;
    If ((my) < 0) Then
      oc := oc Or TOP
    Else If ((my) >= f_h) Then
      oc := oc Or BOTTOM;
    If ((mx) < 0) Then
      oc := oc Or LEFT
    Else If ((mx) >= f_w) Then
      oc := oc Or RIGHT;
  End;

Var
  outcode1: int;
  outcode2: int;
  outside: int;
  tmp: fpoint_t;
  dx: int;
  dy: int;
Begin
  result := false;
  outcode1 := 0;
  outcode2 := 0;

  // do trivial rejects and outcodes
  If (ml^.a.y > m_y2) Then
    outcode1 := TOP
  Else If (ml^.a.y < m_y) Then
    outcode1 := BOTTOM;

  If (ml^.b.y > m_y2) Then
    outcode2 := TOP
  Else If (ml^.b.y < m_y) Then
    outcode2 := BOTTOM;

  If (outcode1 <> 0) And (outcode2 <> 0) Then
    exit; // trivially outside

  If (ml^.a.x < m_x) Then
    outcode1 := outcode1 Or LEFT
  Else If (ml^.a.x > m_x2) Then
    outcode1 := outcode1 Or RIGHT;

  If (ml^.b.x < m_x) Then
    outcode2 := outcode2 Or LEFT
  Else If (ml^.b.x > m_x2) Then
    outcode2 := outcode2 Or RIGHT;

  If (outcode1 <> 0) And (outcode2 <> 0) Then
    exit; // trivially outside

  // transform to frame-buffer coordinates.
  fl^.a.x := CXMTOF(ml^.a.x);
  fl^.a.y := CYMTOF(ml^.a.y);
  fl^.b.x := CXMTOF(ml^.b.x);
  fl^.b.y := CYMTOF(ml^.b.y);

  DOOUTCODE(outcode1, fl^.a.x, fl^.a.y);
  DOOUTCODE(outcode2, fl^.b.x, fl^.b.y);

  If (outcode1 <> 0) And (outcode2 <> 0) Then
    exit;

  While (outcode1 <> 0) Or (outcode2 <> 0) Do Begin
    // may be partially inside box
    // find an outside point
    If (outcode1 <> 0) Then
      outside := outcode1
    Else
      outside := outcode2;

    // clip to each side
    If (outside And TOP) <> 0 Then Begin
      dy := fl^.a.y - fl^.b.y;
      dx := fl^.b.x - fl^.a.x;
      // [crispy] 'int64_t' math to avoid overflows on long lines.
      tmp.x := fl^.a.x + fixed_t(((int64_t(dx * (fl^.a.y - f_y))) Div dy));
      tmp.y := 0;
    End
    Else If (outside And BOTTOM) <> 0 Then Begin
      dy := fl^.a.y - fl^.b.y;
      dx := fl^.b.x - fl^.a.x;
      tmp.x := fl^.a.x + fixed_t(((int64_t(dx * (fl^.a.y - (f_y + f_h)))) Div dy));
      tmp.y := f_h - 1;
    End
    Else If (outside And RIGHT) <> 0 Then Begin
      dy := fl^.b.y - fl^.a.y;
      dx := fl^.b.x - fl^.a.x;
      tmp.y := fl^.a.y + fixed_t(((int64_t(dy * (f_x + f_w - 1 - fl^.a.x))) Div dx));
      tmp.x := f_w - 1;
    End
    Else If (outside And LEFT) <> 0 Then Begin
      dy := fl^.b.y - fl^.a.y;
      dx := fl^.b.x - fl^.a.x;
      tmp.y := fl^.a.y + fixed_t(((int64_t(dy * (f_x - fl^.a.x))) Div dx));
      tmp.x := 0;
    End
    Else Begin
      tmp.x := 0;
      tmp.y := 0;
    End;

    If (outside = outcode1) Then Begin
      fl^.a := tmp;
      DOOUTCODE(outcode1, fl^.a.x, fl^.a.y);
    End
    Else Begin
      fl^.b := tmp;
      DOOUTCODE(outcode2, fl^.b.x, fl^.b.y);
    End;

    If (outcode1 <> 0) And (outcode2 <> 0) Then
      exit; // trivially outside
  End;
  result := true;
End;

//
// Clip lines, draw visible part sof lines.
//

Procedure AM_drawMline(ml: Pmline_t; color: int);
Var
  fl: fline_t;
Begin
  If (AM_clipMline(ml, @fl)) Then Begin
    AM_drawFline(@fl, color); // draws it on frame buffer using fb coords
  End;
End;

Procedure AM_drawLineCharacter(
  lineguy: Pmline_t;
  lineguylines: int;
  scale: fixed_t;
  angle: angle_t;
  color: int;
  x: fixed_t;
  y: fixed_t
  );

Var
  i: int;
  l: mline_t;
Begin
  If (crispy.automaprotate <> 0) Then Begin
    angle := angle_t(angle + mapangle);
  End;

  For i := 0 To lineguylines - 1 Do Begin

    l.a.x := lineguy[i].a.x;
    l.a.y := lineguy[i].a.y;

    If (scale <> 0) Then Begin
      l.a.x := FixedMul(scale, l.a.x);
      l.a.y := FixedMul(scale, l.a.y);
    End;

    If (angle <> 0) Then Begin
      AM_rotate(@l.a.x, @l.a.y, angle);
    End;

    l.a.x := l.a.x + x;
    l.a.y := l.a.y + y;

    l.b.x := lineguy[i].b.x;
    l.b.y := lineguy[i].b.y;

    If (scale <> 0) Then Begin
      l.b.x := FixedMul(scale, l.b.x);
      l.b.y := FixedMul(scale, l.b.y);
    End;

    If (angle <> 0) Then Begin
      AM_rotate(@l.b.x, @l.b.y, angle);
    End;

    l.b.x := l.b.x + x;
    l.b.y := l.b.y + y;
    AM_drawMline(@l, color);
  End;
End;

Procedure AM_drawPlayers();
Var
  //int		i;
  //   player_t*	p;
  //   static int 	their_colors[] = { GREENS, GRAYS, BROWNS, REDS };
  //   int		their_color = -1;
  //   int		color;
  pt: mpoint_t;
Var
  smoothangle: angle_t;
Begin
  If (Not netgame) Then Begin

    // [crispy] smooth player arrow rotation
    If crispy.automaprotate <> 0 Then Begin
      smoothangle := plr^.mo^.angle
    End
    Else Begin
      smoothangle := viewangle;
    End;

    // [crispy] interpolate player arrow
    If (crispy.uncapped <> 0) And (leveltime > oldleveltime) Then Begin
      pt.x := SarLongint(viewx, FRACTOMAPBITS);
      pt.y := SarLongint(viewy, FRACTOMAPBITS);
    End
    Else Begin
      pt.x := SarLongint(plr^.mo^.x, FRACTOMAPBITS);
      pt.y := SarLongint(plr^.mo^.y, FRACTOMAPBITS);
    End;
    If (crispy.automaprotate <> 0) Then Begin
      AM_rotatePoint(@pt);
    End;

    If (cheating <> 0) Then Begin
      AM_drawLineCharacter
        (@cheat_player_arrow[0], length(cheat_player_arrow), 0,
        smoothangle, WHITE, pt.x, pt.y);
    End
    Else Begin
      AM_drawLineCharacter
        (@player_arrow[0], length(player_arrow), 0, smoothangle,
        WHITE, pt.x, pt.y);
    End;
    exit;
  End;

  //    for (i=0;i<MAXPLAYERS;i++)
  //    {
  //	// [crispy] interpolate other player arrows angle
  //	angle_t theirangle;
  //
  //	their_color++;
  //	p = &players[i];
  //
  //	if ( (deathmatch && !singledemo) && p != plr)
  //	    continue;
  //
  //	if (!playeringame[i])
  //	    continue;
  //
  //	if (p->powers[pw_invisibility])
  //	    color = 246; // *close* to black
  //	else
  //	    color = their_colors[their_color];
  //
  //	// [crispy] interpolate other player arrows
  //	if (crispy->uncapped && leveltime > oldleveltime)
  //	{
  //	    pt.x = LerpFixed(p->mo->oldx, p->mo->x) >> FRACTOMAPBITS;
  //	    pt.y = LerpFixed(p->mo->oldy, p->mo->y) >> FRACTOMAPBITS;
  //	}
  //	else
  //	{
  //	    pt.x = p->mo->x >> FRACTOMAPBITS;
  //	    pt.y = p->mo->y >> FRACTOMAPBITS;
  //	}
  //
  //	if (crispy->automaprotate)
  //	{
  //	    AM_rotatePoint(&pt);
  //	    theirangle = p->mo->angle;
  //	}
  //	else
  //	{
  //        theirangle = LerpAngle(p->mo->oldangle, p->mo->angle);
  //	}
  //
  //	AM_drawLineCharacter
  //	    (player_arrow, arrlen(player_arrow), 0, theirangle,
  //	     color, pt.x, pt.y);
  //    }
End;

Function AM_DoorColor(_type: int): keycolor_t;
Begin
  result := no_key;
  If (crispy.extautomap <> 0) Then Begin
    Case _Type Of
      26, 32, 99, 133: result := blue_key;
      27, 34, 136, 137: result := yellow_key;
      28, 33, 134, 135: result := red_key;
    End;
  End;
End;

Procedure AM_drawWalls();
Var
  i: int;
  l: mline_t;
  amd: keycolor_t;
Begin
  For i := 0 To numlines - 1 Do Begin
    l.a.x := SarLongint(lines[i].v1^.x, FRACTOMAPBITS);
    l.a.y := SarLongint(lines[i].v1^.y, FRACTOMAPBITS);
    l.b.x := SarLongint(lines[i].v2^.x, FRACTOMAPBITS);
    l.b.y := SarLongint(lines[i].v2^.y, FRACTOMAPBITS);
    If (crispy.automaprotate <> 0) Then Begin
      AM_rotatePoint(@l.a);
      AM_rotatePoint(@l.b);
    End;

    If (cheating <> 0) Or ((lines[i].flags And ML_MAPPED) <> 0) Then Begin
      If ((lines[i].flags And LINE_NEVERSEE) <> 0) And (cheating = 0) Then
        continue;

      // [crispy] draw keyed doors in their respective colors
      // (no Boom multiple keys)
      // make keyed doors flash for easier visibility
      amd := AM_DoorColor(lines[i].special);
      If ((lines[i].flags And ML_SECRET) = 0) And
        (amd > no_key) Then Begin
        Case amd Of
          blue_key: Begin
              If (leveltime And 16) <> 0 Then Begin
                AM_drawMline(@l, BLUES);
              End
              Else Begin
                AM_drawMline(@l, GRIDCOLORS);
              End;
              continue;
            End;
          yellow_key: Begin
              If (leveltime And 16) <> 0 Then Begin
                AM_drawMline(@l, (YELLOWS - 2));
              End
              Else Begin
                AM_drawMline(@l, GRIDCOLORS);
              End;
              continue;
            End;
          red_key: Begin
              If (leveltime And 16) <> 0 Then Begin
                AM_drawMline(@l, (REDS - 2));
              End
              Else Begin
                AM_drawMline(@l, GRIDCOLORS);
              End;
              continue;
            End;
        End;
      End;

      // [crispy] draw exit lines in white (no Boom exit lines 197, 198)
      // NB: Choco does not have this at all, Boom/PrBoom+ have this disabled by default
      If (crispy.extautomap <> 0) And (
        (lines[i].special = 11) Or
        (lines[i].special = 51) Or
        (lines[i].special = 52) Or
        (lines[i].special = 124)) Then Begin
        AM_drawMline(@l, WHITE);
        continue;
      End;
      If (lines[i].backsector = Nil) Then Begin

        // [crispy] draw 1S secret sector boundaries in purple
        If (crispy.extautomap <> 0) And (
          cheating <> 0) And ((lines[i].frontsector^.special = 9)) Then
          AM_drawMline(@l, secretwallcolors)
            // [crispy] draw revealed secret sector boundaries in green
        Else If (crispy.extautomap <> 0) And
          (crispy.secretmessage <> 0) And ((lines[i].frontsector^.oldspecial = 9)) Then
          AM_drawMline(@l, revealedsecretwallcolors)
        Else
          AM_drawMline(@l, WALLCOLORS + lightlev);
      End
      Else Begin
        // [crispy] draw teleporters in green
        // and also WR teleporters 97 if they are not secret
        // (no monsters-only teleporters 125, 126; no Boom teleporters)
        If (lines[i].special = 39) Or
          ((crispy.extautomap <> 0) And ((lines[i].flags And ML_SECRET) = 0) And (lines[i].special = 97)) Then Begin
          // teleporters
          If crispy.extautomap <> 0 Then Begin
            AM_drawMline(@l, (GREENS + GREENRANGE Div 2));
          End
          Else Begin
            AM_drawMline(@l, (WALLCOLORS + WALLRANGE Div 2));
          End;
        End
        Else If (lines[i].flags And ML_SECRET) <> 0 Then Begin // secret door
          // [crispy] NB: Choco has this check, but (SECRETWALLCOLORS == WALLCOLORS)
          // Boom/PrBoom+ does not have this check at all
          If (false) And (cheating <> 0) Then
            AM_drawMline(@l, secretwallcolors + lightlev)
          Else
            AM_drawMline(@l, WALLCOLORS + lightlev);
        End

          // [crispy] draw revealed secret sector boundaries in green
        Else If (crispy.extautomap <> 0) And (crispy.secretmessage <> 0) And (
          ((lines[i].backsector^.oldspecial = 9) Or (
          lines[i].frontsector^.oldspecial = 9))) Then Begin
          AM_drawMline(@l, revealedsecretwallcolors);
        End

          // [crispy] draw 2S secret sector boundaries in purple
        Else If (crispy.extautomap <> 0) And (cheating <> 0) And
          (((lines[i].backsector^.special = 9) Or (
          lines[i].frontsector^.special = 9))) Then Begin
          AM_drawMline(@l, secretwallcolors);
        End
        Else If (lines[i].backsector^.floorheight
          <> lines[i].frontsector^.floorheight) Then Begin
          AM_drawMline(@l, FDWALLCOLORS + lightlev); // floor level change
        End
        Else If (lines[i].backsector^.ceilingheight
          <> lines[i].frontsector^.ceilingheight) Then Begin
          AM_drawMline(@l, CDWALLCOLORS + lightlev); // ceiling level change
        End
        Else If (cheating <> 0) Then Begin
          AM_drawMline(@l, TSWALLCOLORS + lightlev);
        End;
      End;
    End
    Else If (plr^.powers[integer(pw_allmap)] <> 0) Then Begin
      If ((lines[i].flags And LINE_NEVERSEE) = 0) Then AM_drawMline(@l, GRAYS + 3);
    End;
  End;
End;

//
// Draws flat (floor/ceiling tile) aligned grid lines.
//

Procedure AM_drawGrid(color: int);
Var
  x, y: int64_t;
  start, _end: int64_t;
  gridsize: fixed_t;
  ml: mline_t;
Begin
  gridsize := MAPBLOCKUNITS Shl MAPBITS;

  // Figure out start of vertical gridlines
  start := m_x;
  If (crispy.automaprotate <> 0) Then Begin

    start := start - m_h Div 2;
  End;
  // [crispy] fix losing grid lines near the automap boundary
  If ((start - (bmaporgx Shr FRACTOMAPBITS)) Mod gridsize) <> 0 Then
    start := start + // (MAPBLOCKUNITS shl FRACBITS)
    -((start - (bmaporgx Shr FRACTOMAPBITS)) Mod gridsize);
  _end := m_x + m_w;
  If (crispy.automaprotate <> 0) Then Begin
    _end := _end + m_h Div 2;
  End;

  // draw vertical gridlines
  x := start;
  While x < _end Do Begin
    ml.a.x := x;
    ml.b.x := x;
    // [crispy] moved here
    ml.a.y := m_y;
    ml.b.y := m_y + m_h;
    If (crispy.automaprotate <> 0) Then Begin

      ml.a.y := ml.a.y - m_w Div 2;
      ml.b.y := ml.b.y + m_w Div 2;
      AM_rotatePoint(@ml.a);
      AM_rotatePoint(@ml.b);
    End;
    AM_drawMline(@ml, color);
    x := x + gridsize;
  End;

  // Figure out start of horizontal gridlines
  start := m_y;
  If (crispy.automaprotate <> 0) Then Begin

    start := start - m_w Div 2;
  End;
  // [crispy] fix losing grid lines near the automap boundary
  If ((start - (bmaporgy Shr FRACTOMAPBITS)) Mod gridsize) <> 0 Then
    start := start + // (MAPBLOCKUNITS shl FRACBITS)
    -((start - (bmaporgy Shr FRACTOMAPBITS)) Mod gridsize);
  _end := m_y + m_h;
  If (crispy.automaprotate <> 0) Then Begin
    _end := _end + m_w Div 2;
  End;

  // draw horizontal gridlines
  y := start;
  While y < _end Do Begin
    ml.a.y := y;
    ml.b.y := y;
    // [crispy] moved here
    ml.a.x := m_x;
    ml.b.x := m_x + m_w;
    If (crispy.automaprotate <> 0) Then Begin
      ml.a.x := ml.a.x - m_h Div 2;
      ml.b.x := ml.b.x + m_h Div 2;
      AM_rotatePoint(@ml.a);
      AM_rotatePoint(@ml.b);
    End;
    AM_drawMline(@ml, color);
    y := y + gridsize;
  End;
End;

Procedure AM_drawThings(colors, colorrange: int);
Var
  col, i: int;
  t: ^mobj_t;
  key: keycolor_t;
  pt: mpoint_t;
Begin
  For i := 0 To numsectors - 1 Do Begin
    t := sectors[i].thinglist;
    While assigned(t) Do Begin

      // [crispy] do not draw an extra triangle for the player
      If (t = plr^.mo) Then Begin
        t := t^.snext;
        continue;
      End;

      // [crispy] interpolate thing triangles movement
      If (leveltime > oldleveltime) Then Begin
        pt.x := SarLongint(LerpFixed(t^.oldx, t^.x), FRACTOMAPBITS);
        pt.y := SarLongint(LerpFixed(t^.oldy, t^.y), FRACTOMAPBITS);
      End
      Else Begin
        pt.x := SarLongint(t^.x, FRACTOMAPBITS);
        pt.y := SarLongint(t^.y, FRACTOMAPBITS);
      End;
      If (crispy.automaprotate <> 0) Then Begin
        AM_rotatePoint(@pt);
      End;

      If (crispy.extautomap <> 0) Then Begin
        // [crispy] skull keys and key cards
        Case (t^.info^.doomednum) Of
          38, 13: key := red_key;
          39, 6: key := yellow_key;
          40, 5: key := blue_key;
        Else
          key := no_key;
        End;
        // [crispy] draw keys as crosses in their respective colors
        If (key > no_key) Then Begin
          Case key Of
            red_key: col := REDS;
            yellow_key: col := YELLOWS;
            blue_key: col := BLUES
          Else
            col := colors + lightlev;
          End;
          AM_drawLineCharacter
            (@cross_mark[0], length(cross_mark),
            16 Shl MAPBITS, t^.angle,
            col,
            pt.x, pt.y);
        End
          // [crispy] draw blood splats and puffs as small squares
        Else If (t^._type = MT_BLOOD) Or (t^._type = MT_PUFF) Then Begin
          If (t^._type = MT_BLOOD) Then Begin
            col := REDS;
          End
          Else Begin
            col := GRAYS;
          End;
          AM_drawLineCharacter
            (@square_mark[0], length(square_mark),
            (t^.radius Shr 2) Shr FRACTOMAPBITS, t^.angle,
            col,
            pt.x, pt.y);
        End
        Else Begin

          // [crispy] show countable kills in red ...
          If ((t^.flags And (MF_COUNTKILL Or MF_CORPSE)) = MF_COUNTKILL) Then
            col := REDS
              // [crispy] ... show Lost Souls and missiles in orange ...
          Else If (t^.flags And (MF_FLOAT Or MF_MISSILE)) <> 0 Then
            col := 216
              // [crispy] ... show other shootable items in dark gold ...
          Else If (t^.flags And MF_SHOOTABLE) <> 0 Then
            col := 164
              // [crispy] ... corpses in gray ...
          Else If (t^.flags And MF_CORPSE) <> 0 Then
            col := GRAYS
              // [crispy] ... and countable items in yellow
          Else If (t^.flags And MF_COUNTITEM) <> 0 Then
            col := YELLOWS
          Else
            col := colors + lightlev;

          AM_drawLineCharacter
            (@thintriangle_guy[0], length(thintriangle_guy),
            // [crispy] triangle size represents actual thing size
            t^.radius Shr FRACTOMAPBITS, t^.angle,
            col,
            pt.x, pt.y);
        End;
      End
      Else Begin
        AM_drawLineCharacter
          (@thintriangle_guy[0], length(thintriangle_guy),
          16 Shl MAPBITS, t^.angle, colors + lightlev, pt.x, pt.y);
      End;
      t := t^.snext;
    End;
  End;
End;

Procedure AM_drawMarks();
Var
  i, fx, fy, w, h: int;
  fx_flip: int; // [crispy] support for marks drawing in flipped levels
  pt: mpoint_t;
Begin
  For i := 0 To AM_NUMMARKPOINTS - 1 Do Begin
    If (markpoints[i].x <> -1) Then Begin
      //      w = SHORT(marknums[i]->width);
      //      h = SHORT(marknums[i]->height);
      w := 5; // because something's wrong with the wad, i guess
      h := 6; // because something's wrong with the wad, i guess
      // [crispy] center marks around player
      pt.x := markpoints[i].x;
      pt.y := markpoints[i].y;
      If (crispy.automaprotate <> 0) Then Begin
        AM_rotatePoint(@pt);
      End;
      fx := (CXMTOF(pt.x) {Shr crispy.hires}) - 1;
      fy := (CYMTOF(pt.y) {Shr crispy.hires}) - 2;
      fx_flip := (flipscreenwidth[CXMTOF(pt.x)] {Shr crispy.hires}) - 1;
      If (fx >= f_x) And (fx <= (f_w {Shr crispy.hires}) - w) And (fy >= f_y) And (fy <= (f_h {Shr crispy.hires}) - h) Then
        V_DrawPatchDirect(fx_flip - WIDESCREENDELTA, fy, marknums[i]);
    End;
  End;
End;

Procedure AM_Drawer();
Begin
  If (Not automapactive) Then exit;

  // [crispy] move AM_doFollowPlayer and AM_changeWindowLoc
  // from AM_Ticker for interpolation

  If (followplayer <> 0) Then Begin
    AM_doFollowPlayer();
  End;

  // Change x,y location
  If (m_paninc_target.x <> 0) Or (m_paninc_target.y <> 0) Then Begin
    AM_changeWindowLoc();
  End;

  // [crispy] required for AM_rotatePoint()
  If (crispy.automaprotate <> 0) Then Begin

    mapcenter.x := m_x + m_w Div 2;
    mapcenter.y := m_y + m_h Div 2;
    // [crispy] keep the map static in overlay mode
    // if not following the player
    If (Not ((followplayer = 0) And (crispy.automapoverlay = 0))) Then
      mapangle := angle_t(ANG90 - plr^.mo^.angle);
  End;

  If (crispy.automapoverlay = 0) Then Begin
    AM_clearFB(BACKGROUND);
    pspr_interp := false; // interpolate weapon bobbing
  End;
  If (grid <> 0) Then AM_drawGrid(GRIDCOLORS);
  AM_drawWalls();
  AM_drawPlayers();
  If (cheating = 2) Then AM_drawThings(THINGCOLORS, THINGRANGE);
  AM_drawCrosshair(XHAIRCOLORS, false);

  AM_drawMarks();

  V_MarkRect(f_x, f_y, f_w, f_h);
End;

Procedure AM_ResetIDDTcheat();
Begin
  cheating := 0;
End;

End.

