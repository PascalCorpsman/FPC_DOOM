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

  //  cheatseq_t cheat_amap = CHEAT("iddt", 0);
  cheat_amap: cheatseq_t = (
    sequence: 'iddt'; parameter_chars: 0
    );

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

Procedure AM_Ticker();

Function AM_Responder(Const ev: Pevent_t): boolean;

Procedure AM_Drawer();

Implementation

Uses
  doomtype, g_game, info_types, tables
  , d_loop
  , i_video
  , m_controls, m_menu, m_fixed
  , p_setup, p_tick
  , r_main, r_things
  , st_stuff
  , v_patch, v_video
  , w_wad
  , z_zone
  ;

Const

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
  //   WALLCOLORS=	(crispy->extautomap ? REDS+4 : REDS) // [crispy] slightly darker red
  WALLRANGE = REDRANGE;
  TSWALLCOLORS = GRAYS;
  TSWALLRANGE = GRAYSRANGE;
  //   FDWALLCOLORS	=(crispy->extautomap ? BROWNS+6 : BROWNS) // [crispy] darker brown
  FDWALLRANGE = BROWNRANGE;
  //   CDWALLCOLORS	=(crispy->extautomap ? 163 : YELLOWS) // [crispy] golden yellow
  CDWALLRANGE = YELLOWRANGE;
  THINGCOLORS = GREENS;
  THINGRANGE = GREENRANGE;
  //  SECRETWALLCOLORS = WALLCOLORS;
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

Var
  lastlevel: int = -1;
  lastepisode: int = -1;

  cheating: int = 0;
  grid: int = 0;

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
  Raise exception.create('AM_drawFline_Smooth, not ported.');
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

Procedure AM_clearMarks();
Var
  i: int;
Begin
  For i := 0 To AM_NUMMARKPOINTS - 1 Do Begin
    markpoints[i].x := -1; // means empty
  End;
  markpointnum := 0;
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

  a := FixedDiv(SarLongint(f_w, FRACBITS), max_w);
  b := FixedDiv(SarLongint(f_h, FRACBITS), max_h);

  If a < b Then Begin
    min_scale_mtof := a;
  End
  Else Begin
    min_scale_mtof := b;
  End;
  max_scale_mtof := FixedDiv(SarLongint(f_h, FRACBITS), 2 * MAPPLAYERRADIUS);
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
    // TODO: das Braucht man nur im Smooth mode, den haben wir eh nicht ...

    //        unsigned char *playpal = W_CacheLumpName("PLAYPAL", PU_STATIC);

    precalc_once := 1;
    //        for (int color = 0; color < 256; ++color)
    //        {
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
    //        }
    //
    //        // [crispy] Make secret wall colors independent from PLAYPAL color indexes
    //        secretwallcolors = V_GetPaletteIndex(playpal, 255, 0, 255);
    //        revealedsecretwallcolors = V_GetPaletteIndex(playpal, 119, 255, 111);
    //
    //        W_ReleaseLumpName("PLAYPAL");
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
    AM_rotate(@incx, @incy, -mapangle);
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
  //        f_paninc = F_PANINC;
  //        m_zoomin_kbd = M_ZOOMIN;
  //        m_zoomout_kbd = M_ZOOMOUT;
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
      //            // [crispy] keep the map static in overlay mode
      //            // if not following the player
      //            if (!followplayer)
      //                m_paninc.x = crispy->fliplevels ?
      //                    -FTOM(f_paninc << crispy->hires) : FTOM(f_paninc << crispy->hires);
      //            else rc = false;
    End
      //        else if (key == key_map_west)     // pan left
      //        {
      //            if (!followplayer)
      //                m_paninc.x = crispy->fliplevels ?
      //                    FTOM(f_paninc << crispy->hires) : -FTOM(f_paninc << crispy->hires);
      //            else rc = false;
      //        }
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
      //        else if (key == key_map_zoomout)  // zoom out
      //        {
      //            mtof_zoommul = m_zoomout_kbd;
      //            ftom_zoommul = m_zoomin_kbd;
      //        }
      //        else if (key == key_map_zoomin)   // zoom in
      //        {
      //            mtof_zoommul = m_zoomin_kbd;
      //            ftom_zoommul = m_zoomout_kbd;
      //        }
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
      //        else if (key == key_map_mark)
      //        {
      //            M_snprintf(buffer, sizeof(buffer), "%s %d",
      //                       DEH_String(AMSTR_MARKEDSPOT), markpointnum);
      //            plr->message = buffer;
      //            AM_addMark();
      //        }
      //        else if (key == key_map_clearmark)
      //        {
      //            AM_clearMarks();
      //            plr->message = DEH_String(AMSTR_MARKSCLEARED);
      //        }
      //        else if (key == key_map_overlay)
      //        {
      //            // [crispy] force redraw status bar
      //            inhelpscreens = true;
      //
      //            crispy->automapoverlay = !crispy->automapoverlay;
      //            if (crispy->automapoverlay)
      //                plr->message = DEH_String(AMSTR_OVERLAYON);
      //            else
      //                plr->message = DEH_String(AMSTR_OVERLAYOFF);
      //        }
      //        else if (key == key_map_rotate)
      //        {
      //            crispy->automaprotate = !crispy->automaprotate;
      //            if (crispy->automaprotate)
      //                plr->message = DEH_String(AMSTR_ROTATEON);
      //            else
      //                plr->message = DEH_String(AMSTR_ROTATEOFF);
      //        }
    Else Begin
      rc := false;
    End;
    //
    //        if ((!deathmatch || gameversion <= exe_doom_1_8)
    //         && cht_CheckCheat(&cheat_amap, ev->data2))
    //        {
    //            rc = false;
    //            cheating = (cheating + 1) % 3;
    //        }
  End
  Else If (ev^._type = ev_keyup) Then Begin

    //        rc = false;
    //        key = ev->data1;
    //
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
    //        else if (key == key_map_zoomout || key == key_map_zoomin)
    //        {
    //            mtof_zoommul = FRACUNIT;
    //            ftom_zoommul = FRACUNIT;
    //        }
  End;

  result := rc;
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
      mapangle := ANG90 - plr^.mo^.angle;
  End;

  If (crispy.automapoverlay = 0) Then Begin
    AM_clearFB(BACKGROUND);
    pspr_interp := false; // interpolate weapon bobbing
  End;

  Jetzt kann das eigentliche "Malen" los gehen ;)

  //  If (grid) Then AM_drawGrid(GRIDCOLORS);
  //  AM_drawWalls();
  //  AM_drawPlayers();
  //  If (cheating = 2) Then AM_drawThings(THINGCOLORS, THINGRANGE);
  //  AM_drawCrosshair(XHAIRCOLORS, false);

  //  AM_drawMarks();

  V_MarkRect(f_x, f_y, f_w, f_h);
End;

End.

