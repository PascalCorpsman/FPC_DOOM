Unit am_map;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_event
  ;

Const
  // Used by ST StatusBar stuff.
  AM_MSGHEADER = ((ord('a') Shl 24) + (ord('m') Shl 16));
  AM_MSGENTERED = (AM_MSGHEADER Or (ord('e') Shl 8));
  AM_MSGEXITED = (AM_MSGHEADER Or (ord('x') Shl 8));

Var
  automapactive: boolean = false;

Procedure AM_Ticker();

Function AM_Responder(Const ev: Pevent_t): boolean;

Procedure AM_Drawer();

Implementation

Uses
  g_game
  , i_video
  , m_controls, m_menu, m_fixed
  , r_main, r_things
  , st_stuff
  , v_patch
  , w_wad
  , z_zone
  ;

Const

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

  INITSCALEMTOF = (FRACUNIT Div 5);

Var
  lastlevel: int = -1;
  lastepisode: int = -1;

  //  static int 	cheating = 0;
  //  static int 	grid = 0;

  //  //static int 	finit_width = SCREENWIDTH;
  //  //static int 	finit_height = SCREENHEIGHT - (ST_HEIGHT << crispy->hires);

  // location of window on screen
  f_x: int;
  f_y: int;

  // size of window on screen
  f_w: int;
  f_h: int;

  //  static int 	lightlev; 		// used for funky strobing effect
  //  #define fb I_VideoBuffer // [crispy] simplify
  //  //static pixel_t*	fb; 			// pseudo-frame buffer
  //  static int 	amclock;
  //
  //  static mpoint_t m_paninc, m_paninc2; // how far the window pans each tic (map coords)
  //  static mpoint_t m_paninc_target; // [crispy] for interpolation
  //  static fixed_t 	mtof_zoommul; // how far the window zooms in each tic (map coords)
  //  static fixed_t 	ftom_zoommul; // how far the window zooms in each tic (fb coords)

  m_x, m_y: int64_t; // LL x,y where the window is on the map (map coords)
  m_x2, m_y2: int64_t; // UR x,y where the window is on the map (map coords)
  //  static int64_t 	prev_m_x, prev_m_y; // [crispy] for interpolation
  next_m_x, next_m_y: int64_t; // [crispy] for interpolation

  //
  // width/height of window on map (map coords)
  //
  m_w: int64_t;
  m_h: int64_t;
  //
  //  // based on level size
  //  static fixed_t 	min_x;
  //  static fixed_t	min_y;
  //  static fixed_t 	max_x;
  //  static fixed_t  max_y;
  //
  //  static fixed_t 	max_w; // max_x-min_x,
  //  static fixed_t  max_h; // max_y-min_y
  //
  //  // based on player size
  //  static fixed_t 	min_w;
  //  static fixed_t  min_h;
  //
  //
  //  static fixed_t 	min_scale_mtof; // used to tell when to stop zooming out
  //  static fixed_t 	max_scale_mtof; // used to tell when to stop zooming in
  //
  //  // old stuff for recovery later
  //  static int64_t old_m_w, old_m_h;
  //  static int64_t old_m_x, old_m_y;
  //
  //  // used by MTOF to scale from map-to-frame-buffer coords
  scale_mtof: fixed_t = INITSCALEMTOF;
  // used by FTOM to scale from frame-buffer-to-map coords (=1/scale_mtof)
  scale_ftom: fixed_t;

  //  static player_t *plr; // the player represented by an arrow

  marknums: Array[0..9] Of Ppatch_t; // numbers used for marking by the automap
  //  static mpoint_t markpoints[AM_NUMMARKPOINTS]; // where the points are
  //  static int markpointnum = 0; // next point to be assigned

  followplayer: int = 1; // specifies whether to follow the player around

  //  cheatseq_t cheat_amap = CHEAT("iddt", 0);
  //
  stopped: boolean = true;

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
// Clear automap frame buffer.
//

Procedure AM_clearFB(color: int);
Begin
  //    memset(fb, color, f_w*f_h*sizeof(*fb));
End;

Procedure AM_unloadPics();
Begin
  //      int i;
  //      char namebuf[9];
  //
  //      for (i=0;i<10;i++)
  //      {
  //  	DEH_snprintf(namebuf, 9, "AMMNUM%d", i);
  //  	W_ReleaseLumpName(namebuf);
  //      }
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
// should be called at the start of every level
// right now, i figure it out myself
//

Procedure AM_LevelInit(reinit: boolean);
Begin
  //    fixed_t a, b;
  //    static int f_h_old;
  //    // [crispy] Only need to precalculate color lookup tables once
  //    static int precalc_once;

  f_x := 0;
  f_y := 0;
  f_w := SCREENWIDTH;
  f_h := SCREENHEIGHT - (ST_HEIGHT Shl crispy.hires);

  //    AM_drawFline = crispy->smoothmap ? AM_drawFline_Smooth : AM_drawFline_Vanilla;

//  If (Not reinit) Then AM_clearMarks();

  //    AM_findMinMaxBoundaries();
  //    // [crispy] preserve map scale when re-initializing
  //    if (reinit && f_h_old)
  //    {
  //	scale_mtof = scale_mtof * f_h / f_h_old;
  //	AM_drawCrosshair(XHAIRCOLORS, true);
  //    }
  //    else
  //    {
  //    // [crispy] initialize zoomlevel on all maps so that a 4096 units
  //    // square map would just fit in (MAP01 is 3376x3648 units)
  //    a = FixedDiv(f_w, (max_w>>MAPBITS < 2048) ? 2*(max_w>>MAPBITS) : 4096);
  //    b = FixedDiv(f_h, (max_h>>MAPBITS < 2048) ? 2*(max_h>>MAPBITS) : 4096);
  //    scale_mtof = FixedDiv(a < b ? a : b, (int) (0.7*MAPUNIT));
  //    }
  //    if (scale_mtof > max_scale_mtof)
  //	scale_mtof = min_scale_mtof;
  //    scale_ftom = FixedDiv(FRACUNIT, scale_mtof);
  //
  //    f_h_old = f_h;
  //
  //    // [crispy] Precalculate color lookup tables for antialiased line drawing using COLORMAP
  //    if (!precalc_once)
  //    {
  //        unsigned char *playpal = W_CacheLumpName("PLAYPAL", PU_STATIC);
  //
  //        precalc_once = 1;
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
  //    }
End;

Procedure AM_initVariables();
Begin
  //    static event_t st_notify = { ev_keyup, AM_MSGENTERED, 0, 0 };
  //
  //    automapactive = true;
  ////  fb = I_VideoBuffer; // [crispy] simplify
  //
  //    amclock = 0;
  //    lightlev = 0;
  //
  //    m_paninc.x = m_paninc.y = m_paninc2.x = m_paninc2.y = 0;
  //    ftom_zoommul = FRACUNIT;
  //    mtof_zoommul = FRACUNIT;
  //    mousewheelzoom = false; // [crispy]
  //
  //    m_w = FTOM(f_w);
  //    m_h = FTOM(f_h);
  //
  //    // [crispy] find player to center
  //    plr = &players[displayplayer];
  //
  //    next_m_x = (plr->mo->x >> FRACTOMAPBITS) - m_w/2;
  //    next_m_y = (plr->mo->y >> FRACTOMAPBITS) - m_h/2;
  //
  //    AM_Ticker(); // [crispy] initialize variables for interpolation
  //    AM_changeWindowLoc();
  //
  //    // for saving & restoring
  //    old_m_x = m_x;
  //    old_m_y = m_y;
  //    old_m_w = m_w;
  //    old_m_h = m_h;
  //
  //    // inform the status bar of the change
  //    ST_Responder(&st_notify);
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

//
// Updates on Game Tick
//

Procedure AM_Ticker();
Begin
  If (Not automapactive) Then exit;

  //    amclock++;
  //
  //    // [crispy] sync up for interpolation
  //    m_x = prev_m_x = next_m_x;
  //    m_y = prev_m_y = next_m_y;
  //
  //    m_paninc_target.x = m_paninc.x + m_paninc2.x;
  //    m_paninc_target.y = m_paninc.y + m_paninc2.y;
  //
  //    // [crispy] reset after moving with the mouse
  //    m_paninc2.x = m_paninc2.y = 0;
  //
  //    if (followplayer)
  //	AM_doFollowPlayer();
  //
  //    // Change the zoom if necessary
  //    if (ftom_zoommul != FRACUNIT)
  //	AM_changeWindowScale();
  //
  //    if (m_paninc_target.x || m_paninc_target.y)
  //        AM_changeWindowLocTick();
  //
  //    // Update light level
  //    // AM_updateLightLev();
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

Procedure AM_Drawer();
Begin

  exit; // DEBUG, aktuell noch deaktiviert weil noch nicht sauber initialisiert!

  If (Not automapactive) Then exit;

  // [crispy] move AM_doFollowPlayer and AM_changeWindowLoc
  // from AM_Ticker for interpolation

  If (followplayer <> 0) Then Begin
    //AM_doFollowPlayer();
  End;

  //    // Change x,y location
  //    if (m_paninc_target.x || m_paninc_target.y)
  //    {
  //        AM_changeWindowLoc();
  //    }
  //
  //    // [crispy] required for AM_rotatePoint()
  //    if (crispy->automaprotate)
  //    {
  //	mapcenter.x = m_x + m_w / 2;
  //	mapcenter.y = m_y + m_h / 2;
  //	// [crispy] keep the map static in overlay mode
  //	// if not following the player
  //	if (!(!followplayer && crispy->automapoverlay))
  //	mapangle = ANG90 - plr->mo->angle;
  //    }

  If (crispy.automapoverlay = 0) Then Begin
    AM_clearFB(BACKGROUND);
    pspr_interp := false; // interpolate weapon bobbing
  End;

  //  If (grid) Then AM_drawGrid(GRIDCOLORS);
    //    AM_drawWalls();
    //    AM_drawPlayers();
//  If (cheating = 2) Then AM_drawThings(THINGCOLORS, THINGRANGE);
  //    AM_drawCrosshair(XHAIRCOLORS, false);
  //
  //    AM_drawMarks();
  //
  //    V_MarkRect(f_x, f_y, f_w, f_h);
End;

End.

