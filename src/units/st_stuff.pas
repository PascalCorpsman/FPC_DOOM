Unit st_stuff;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef
  , d_event
  , i_video
  , m_cheat
  ;

Const
  // Das wirkt sich auf viewheight aus, und das dann wohl auf die Sprites ..
  ST_HEIGHT = 32;
  CRISPY_HUD = 12;

  //cheatseq_t cheat_mus = CHEAT("idmus", 2);
  cheat_god: cheatseq_t = (sequence: 'iddqd'; parameter_chars: 0);
  cheat_ammo: cheatseq_t = (sequence: 'idkfa'; parameter_chars: 0);
  cheat_ammonokey: cheatseq_t = (sequence: 'idfa'; parameter_chars: 0);
  cheat_noclip: cheatseq_t = (sequence: 'idspispopd'; parameter_chars: 0);
  cheat_commercial_noclip: cheatseq_t = (sequence: 'idclip'; parameter_chars: 0);

Var
  st_keyorskull: Array[card_t] Of int; // Es werden aber nur it_bluecard .. it_redcard genutzt

Procedure ST_Init();
Procedure ST_Start();
Procedure ST_Ticker();

Procedure ST_Drawer(fullscreen, refresh: boolean);

Function cht_CheckCheatSP(Var cht: cheatseq_t; key: char): int;

Function ST_Responder(Const ev: Pevent_t): boolean;

Procedure ST_refreshBackground(force: boolean);
Procedure ST_DrawDemoTimer(time: int);

Implementation

Uses
  info_types, doomstat, doomdata, tables, sounds, doomtype
  , am_map
  , d_items, d_player, d_englsh, deh_misc, d_mode
  , g_game
  , m_menu, m_fixed, m_random
  , p_mobj
  , st_lib, s_sound
  , v_patch, v_video
  , w_wad
  , z_zone
  ;

Const
  // Location and size of statistics,
  //  justified according to widget type.
  // Problem is, within which space? STbar? Screen?
  // Note: this could be read in by a lump.
  //       Problem is, is the stuff rendered
  //       into a buffer,
  //       or into the frame buffer?

  // AMMO number pos.
  ST_AMMOWIDTH = 3;
  ST_AMMOX = (44 {- ST_WIDESCREENDELTA});
  ST_AMMOY = 171;

  // Weapon pos.
  ST_ARMSX = (111 {- ST_WIDESCREENDELTA});
  ST_ARMSY = 172;
  ST_ARMSBGX = (104 {- ST_WIDESCREENDELTA});
  ST_ARMSBGY = 168;
  ST_ARMSXSPACE = 12;
  ST_ARMSYSPACE = 10;

  // Number of status faces.
  ST_NUMPAINFACES = 5;
  ST_NUMSTRAIGHTFACES = 3;
  ST_NUMTURNFACES = 2;
  ST_NUMSPECIALFACES = 3;

  ST_FACESTRIDE = (ST_NUMSTRAIGHTFACES + ST_NUMTURNFACES + ST_NUMSPECIALFACES);

  ST_NUMEXTRAFACES = 2;

  ST_NUMFACES = (ST_FACESTRIDE * ST_NUMPAINFACES + ST_NUMEXTRAFACES);

  ST_WIDTH = ORIGWIDTH;
  ST_Y = (ORIGHEIGHT - ST_HEIGHT);
  // Location of status bar
  ST_X = 0;
  ST_X2 = 104;

  ST_FX = 143;
  ST_FY = 169;

Type
  load_callback_t = Procedure(lumpname: String; variable: PPPatch_t);

Var
  // graphics are drawn to a backing screen and blitted to the real screen
  st_backing_screen: Array Of pixel_t = Nil;

  // main player in game
  plyr: ^player_t;

  // ST_Start() has just been called
  st_firsttime: Boolean;

  // lump number for PLAYPAL
  lu_palette: int;

  //  // used for making messages go away
  st_msgcounter: int = 0;

  // whether left-side main status bar is active
  st_statusbaron: boolean;

  // [crispy] distinguish classic status bar with background and player face from Crispy HUD
  st_crispyhud: boolean;
  st_classicstatusbar: boolean;
  st_statusbarface: boolean;

  // whether status bar chat is active
  st_chat: boolean;

  // value of st_chat before message popped up
  st_oldchat: boolean;

  // !deathmatch
  st_notdeathmatch: Boolean;

  // !deathmatch && st_statusbaron
  st_armson: boolean;

  // !deathmatch
  st_fragson: boolean;

  // main bar left
  sbar: ppatch_t;

  // main bar right, for doom 1.0
  sbarr: ppatch_t;

  // 0-9, tall numbers
  tallnum: Array[0..9] Of ppatch_t;

  // tall % sign
  tallpercent: ppatch_t;

  // 0-9, short, yellow (,different!) numbers
  shortnum: Array[0..9] Of ppatch_t;

  // 3 key-cards, 3 skulls
  keys: Array[0..integer(NUMCARDS) + 3 - 1] Of ppatch_t; // [crispy] support combined card and skull keys

  // face status patches
  faces: Array[0..integer(ST_NUMFACES) - 1] Of ppatch_t;

  //  // face background
  faceback: Array[0..MAXPLAYERS - 1] Of ppatch_t; // [crispy] killough 3/7/98: make array

  // main bar right
  armsbg: ppatch_t;

  // weapon ownership patches
  arms: Array[0..5, 0..1] Of ppatch_t;

  // ready-weapon widget
  w_ready: st_number_t;

  //   // in deathmatch only, summary of frags stats
  //  static st_number_t	w_frags;
  //
  //  // health widget
  //  static st_percent_t	w_health;

    // arms background
  w_armsbg: st_binicon_t;


  //  // weapon ownership widgets
  //  static st_multicon_t	w_arms[6];
  //  // [crispy] show SSG availability in the Shotgun slot of the arms widget
  //  static int st_shotguns;

  //  // face status widget
  //  static st_multicon_t	w_faces;

  //  // keycard widgets
  //  static st_multicon_t	w_keyboxes[3];

  //  // armor widget
  //  static st_percent_t	w_armor;

  //  // ammo widgets
  //  static st_number_t	w_ammo[4];

  //  // max ammo widgets
  //  static st_number_t	w_maxammo[4];

  //   // number of frags so far in deathmatch
  //  static int	st_fragscount;

  // used to use appopriately pained face
  st_oldhealth: int = -1;

  // used for evil grin
  oldweaponsowned: Array[0..integer(NUMWEAPONS) - 1] Of boolean;

  // count until face changes
  st_facecount: int = 0;

  // current face index, used by w_faces
  faceindex: int;

  // holds key-type for each key box on bar
  keyboxes: Array[0..2] Of int;

  //  // [crispy] blinking key or skull in the status bar
  //  int		st_keyorskull[3];

  // a random number per tick
  st_randomnumber: int;

  st_widescreendelta: int;
  st_stopped: boolean = true;

  // current face index, used by w_faces
  st_faceindex: int = 0;
  st_palette: int = 0;

Procedure ST_Stop();
Begin
  If (st_stopped) Then exit;

  //#ifndef CRISPY_TRUECOLOR
  //    I_SetPalette (W_CacheLumpNum (lu_palette, PU_CACHE));
  //#else
  //    I_SetPalette (0);
  //#endif

  st_stopped := true;
End;

Procedure ST_initData();
Var
  i: int;
Begin

  st_firsttime := true;
  plyr := @players[displayplayer];

  st_statusbaron := true;
  st_oldchat := false;
  st_chat := false;

  faceindex := 0; // [crispy] fix status bar face hysteresis across level changes
  st_faceindex := 0;
  st_palette := -1;

  st_oldhealth := -1;

  For i := 0 To integer(NUMWEAPONS) - 1 Do Begin
    oldweaponsowned[i] := plyr^.weaponowned[weapontype_t(i)];
  End;

  For i := 0 To 2 Do Begin
    keyboxes[i] := -1;
  End;

  STlib_init();
End;

// [crispy] in non-widescreen mode WIDESCREENDELTA is 0 anyway

Function ST_WIDESCREENDELTA_(): int;
Begin
  //  If (false {screenblocks >= CRISPY_HUD + 3 && (!automapactive || crispy->automapoverlay) }) Then Begin
  //    result := WIDESCREENDELTA;
  //  End
  //  Else Begin
  result := 0;
  //  End;
End;

Procedure ST_createWidgets();
Var
  i: int;
Begin
  // [crispy] re-calculate WIDESCREENDELTA
  I_GetScreenDimensions();
  st_widescreendelta := ST_WIDESCREENDELTA_;

  // ready weapon ammo
  STlib_initNum(w_ready,
    ST_AMMOX,
    ST_AMMOY,
    @tallnum[0],
    @plyr^.ammo[integer(weaponinfo[integer(plyr^.readyweapon)].ammo)],
    @st_statusbaron,
    ST_AMMOWIDTH);

  // the last weapon type
//    w_ready.data = plyr->readyweapon;
//
//    // health percentage
//    STlib_initPercent(&w_health,
//		      ST_HEALTHX,
//		      ST_HEALTHY,
//		      tallnum,
//		      &plyr->health,
//		      &st_statusbaron,
//		      tallpercent);

  // arms background
  STlib_initBinIcon(w_armsbg,
    ST_ARMSBGX,
    ST_ARMSBGY,
    armsbg,
    @st_notdeathmatch,
    @st_classicstatusbar);

  //    // weapons owned
  //    for(i=0;i<6;i++)
  //    {
  //        STlib_initMultIcon(&w_arms[i],
  //                           ST_ARMSX+(i%3)*ST_ARMSXSPACE,
  //                           ST_ARMSY+(i/3)*ST_ARMSYSPACE,
  //                           arms[i],
  //                           &plyr->weaponowned[i+1],
  //                           &st_armson);
  //    }
  //    // [crispy] show SSG availability in the Shotgun slot of the arms widget
  //    w_arms[1].inum = &st_shotguns;
  //
  //    // frags sum
  //    STlib_initNum(&w_frags,
  //		  ST_FRAGSX,
  //		  ST_FRAGSY,
  //		  tallnum,
  //		  &st_fragscount,
  //		  &st_fragson,
  //		  ST_FRAGSWIDTH);
  //
  //    // faces
  //    STlib_initMultIcon(&w_faces,
  //		       ST_FACESX,
  //		       ST_FACESY,
  //		       faces,
  //		       &st_faceindex,
  //		       &st_statusbarface);
  //
  //    // armor percentage - should be colored later
  //    STlib_initPercent(&w_armor,
  //		      ST_ARMORX,
  //		      ST_ARMORY,
  //		      tallnum,
  //		      &plyr->armorpoints,
  //		      &st_statusbaron, tallpercent);
  //
  //    // keyboxes 0-2
  //    STlib_initMultIcon(&w_keyboxes[0],
  //		       ST_KEY0X,
  //		       ST_KEY0Y,
  //		       keys,
  //		       &keyboxes[0],
  //		       &st_statusbaron);
  //
  //    STlib_initMultIcon(&w_keyboxes[1],
  //		       ST_KEY1X,
  //		       ST_KEY1Y,
  //		       keys,
  //		       &keyboxes[1],
  //		       &st_statusbaron);
  //
  //    STlib_initMultIcon(&w_keyboxes[2],
  //		       ST_KEY2X,
  //		       ST_KEY2Y,
  //		       keys,
  //		       &keyboxes[2],
  //		       &st_statusbaron);
  //
  //    // ammo count (all four kinds)
  //    STlib_initNum(&w_ammo[0],
  //		  ST_AMMO0X,
  //		  ST_AMMO0Y,
  //		  shortnum,
  //		  &plyr->ammo[0],
  //		  &st_statusbaron,
  //		  ST_AMMO0WIDTH);
  //
  //    STlib_initNum(&w_ammo[1],
  //		  ST_AMMO1X,
  //		  ST_AMMO1Y,
  //		  shortnum,
  //		  &plyr->ammo[1],
  //		  &st_statusbaron,
  //		  ST_AMMO1WIDTH);
  //
  //    STlib_initNum(&w_ammo[2],
  //		  ST_AMMO2X,
  //		  ST_AMMO2Y,
  //		  shortnum,
  //		  &plyr->ammo[2],
  //		  &st_statusbaron,
  //		  ST_AMMO2WIDTH);
  //
  //    STlib_initNum(&w_ammo[3],
  //		  ST_AMMO3X,
  //		  ST_AMMO3Y,
  //		  shortnum,
  //		  &plyr->ammo[3],
  //		  &st_statusbaron,
  //		  ST_AMMO3WIDTH);
  //
  //    // max ammo count (all four kinds)
  //    STlib_initNum(&w_maxammo[0],
  //		  ST_MAXAMMO0X,
  //		  ST_MAXAMMO0Y,
  //		  shortnum,
  //		  &plyr->maxammo[0],
  //		  &st_statusbaron,
  //		  ST_MAXAMMO0WIDTH);
  //
  //    STlib_initNum(&w_maxammo[1],
  //		  ST_MAXAMMO1X,
  //		  ST_MAXAMMO1Y,
  //		  shortnum,
  //		  &plyr->maxammo[1],
  //		  &st_statusbaron,
  //		  ST_MAXAMMO1WIDTH);
  //
  //    STlib_initNum(&w_maxammo[2],
  //		  ST_MAXAMMO2X,
  //		  ST_MAXAMMO2Y,
  //		  shortnum,
  //		  &plyr->maxammo[2],
  //		  &st_statusbaron,
  //		  ST_MAXAMMO2WIDTH);
  //
  //    STlib_initNum(&w_maxammo[3],
  //		  ST_MAXAMMO3X,
  //		  ST_MAXAMMO3Y,
  //		  shortnum,
  //		  &plyr->maxammo[3],
  //		  &st_statusbaron,
  //		  ST_MAXAMMO3WIDTH);

End;

Procedure ST_Start;
Begin
  If (Not st_stopped) Then ST_Stop();

  ST_initData();
  ST_createWidgets();
  st_stopped := false;
End;

Procedure ST_updateWidgets();
Begin
  //    static int	largeammo = 1994; // means "n/a"
  //    int		i;
  //
  //    // must redirect the pointer if the ready weapon has changed.
  //    //  if (w_ready.data != plyr->readyweapon)
  //    //  {
  //    if (weaponinfo[plyr->readyweapon].ammo == am_noammo)
  //	w_ready.num = &largeammo;
  //    else
  //	w_ready.num = &plyr->ammo[weaponinfo[plyr->readyweapon].ammo];
  //    //{
  //    // static int tic=0;
  //    // static int dir=-1;
  //    // if (!(tic&15))
  //    //   plyr->ammo[weaponinfo[plyr->readyweapon].ammo]+=dir;
  //    // if (plyr->ammo[weaponinfo[plyr->readyweapon].ammo] == -100)
  //    //   dir = 1;
  //    // tic++;
  //    // }
  w_ready.data := int(plyr^.readyweapon);

  //    // if (*w_ready.on)
  //    //  STlib_updateNum(&w_ready, true);
  //    // refresh weapon change
  //    //  }
  //
  //    // update keycard multiple widgets
  //    for (i=0;i<3;i++)
  //    {
  //	keyboxes[i] = plyr->cards[i] ? i : -1;
  //
  //	if (plyr->cards[i+3])
  //	    keyboxes[i] = (keyboxes[i] == -1) ? i+3 : i+6; // [crispy] support combined card and skull keys
  //
  //	// [crispy] blinking key or skull in the status bar
  //	if (plyr->tryopen[i])
  //	{
  //#if defined(CRISPY_KEYBLINK_WITH_SOUND)
  //		if (!(plyr->tryopen[i] & (2*KEYBLINKMASK-1)))
  //		{
  //			S_StartSound(NULL, sfx_itemup);
  //		}
  //#endif
  //#if defined(CRISPY_KEYBLINK_IN_CLASSIC_HUD)
  //		if (st_classicstatusbar && !(plyr->tryopen[i] & (KEYBLINKMASK-1)))
  //		{
  //			st_firsttime = true;
  //		}
  //#endif
  //		plyr->tryopen[i]--;
  //#if !defined(CRISPY_KEYBLINK_IN_CLASSIC_HUD)
  //		if (st_crispyhud)
  //#endif
  //		{
  //			keyboxes[i] = (plyr->tryopen[i] & KEYBLINKMASK) ? i + st_keyorskull[i] : -1;
  //		}
  //
  //		if (!plyr->tryopen[i])
  //		{
  //			w_keyboxes[i].oldinum = -1;
  //		}
  //	}
  //    }
  //
  //    // refresh everything if this is him coming back to life
  //    ST_updateFaceWidget();

  // used by the w_armsbg widget
  st_notdeathmatch := deathmatch = 0;

  // used by w_arms[] widgets
  st_armson := st_statusbaron And (deathmatch = 0);

  //    // used by w_frags widget
  //    st_fragson = deathmatch && st_statusbaron;
  //    st_fragscount = 0;
  //
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //    {
  //	if (i != displayplayer)
  //	    st_fragscount += plyr->frags[i];
  //	else
  //	    st_fragscount -= plyr->frags[i];
  //    }

  //    // get rid of chat window if up because of message
  //    if (!--st_msgcounter)
  //	st_chat = st_oldchat;

End;


Procedure ST_doPaletteStuff();
Begin

  //    int		palette;
  //#ifndef CRISPY_TRUECOLOR
  //    byte*	pal;
  //#endif
  //    int		cnt;
  //    int		bzc;
  //
  //    cnt = plyr->damagecount;
  //
  //    if (plyr->powers[pw_strength])
  //    {
  //	// slowly fade the berzerk out
  //  	bzc = 12 - (plyr->powers[pw_strength]>>6);
  //
  //	if (bzc > cnt)
  //	    cnt = bzc;
  //    }
  //
  //    // [crispy] A11Y
  //    if (!a11y_palette_changes)
  //    {
  //	palette = 0;
  //    }
  //    else
  //    if (cnt)
  //    {
  //	palette = (cnt+7)>>3;
  //
  //	if (palette >= NUMREDPALS)
  //	    palette = NUMREDPALS-1;
  //
  //	// [crispy] tune down a bit so the menu remains legible
  //	if (menuactive || paused)
  //	    palette >>= 1;
  //
  //	palette += STARTREDPALS;
  //    }
  //
  //    else if (plyr->bonuscount && plyr->health > 0) // [crispy] never show the yellow bonus palette for a dead player
  //    {
  //	palette = (plyr->bonuscount+7)>>3;
  //
  //	if (palette >= NUMBONUSPALS)
  //	    palette = NUMBONUSPALS-1;
  //
  //	palette += STARTBONUSPALS;
  //    }
  //
  //    else if ( plyr->powers[pw_ironfeet] > 4*32
  //	      || plyr->powers[pw_ironfeet]&8)
  //	palette = RADIATIONPAL;
  //    else
  //	palette = 0;
  //
  //    // In Chex Quest, the player never sees red.  Instead, the
  //    // radiation suit palette is used to tint the screen green,
  //    // as though the player is being covered in goo by an
  //    // attacking flemoid.
  //
  //    if (gameversion == exe_chex
  //     && palette >= STARTREDPALS && palette < STARTREDPALS + NUMREDPALS)
  //    {
  //        palette = RADIATIONPAL;
  //    }
  //
  //    // [crispy] prevent palette changes when in help screen or Crispness menu
  //    if (inhelpscreens)
  //    {
  //	palette = 0;
  //    }
  //
  //    if (palette != st_palette)
  //    {
  //	st_palette = palette;
  //#ifndef CRISPY_TRUECOLOR
  //	pal = (byte *) W_CacheLumpNum (lu_palette, PU_CACHE)+palette*768;
  //	I_SetPalette (pal);
  //#else
  //	I_SetPalette (palette);
  //#endif
  //    }

End;

Procedure ST_Ticker();
Begin
  st_randomnumber := M_Random.M_Random();
  ST_updateWidgets();
  st_oldhealth := plyr^.health;

  // Do red-/gold-shifts from damage/items
  ST_doPaletteStuff();
End;

Procedure ST_refreshBackground(force: boolean);
Begin
  If (st_classicstatusbar) Or (force) Then Begin

    V_UseBuffer(st_backing_screen);

    // [crispy] this is our own local copy of R_FillBackScreen() to
    // fill the entire background of st_backing_screen with the bezel pattern,
    // so it appears to the left and right of the status bar in widescreen mode
    If ((SCREENWIDTH Shr crispy.hires) <> ST_WIDTH) Then Begin
      Raise exception.create('Not planed to support widescreen mode ?');
      //		byte *src;
      //		pixel_t *dest;
      //		const char *name = (gamemode == commercial) ? DEH_String("GRNROCK") : DEH_String("FLOOR7_2");
      //
      //		src = W_CacheLumpName(name, PU_CACHE);
      //		dest = st_backing_screen;
      //
      //		// [crispy] use unified flat filling function
      //		V_FillFlat(SCREENHEIGHT-(ST_HEIGHT<<crispy->hires), SCREENHEIGHT, 0, SCREENWIDTH, src, dest);
      //
      //		// [crispy] preserve bezel bottom edge
      //		if (scaledviewwidth == SCREENWIDTH)
      //		{
      //			int x;
      //			patch_t *const patch = W_CacheLumpName(DEH_String("brdr_b"), PU_CACHE);
      //
      //			for (x = 0; x < WIDESCREENDELTA; x += 8)
      //			{
      //				V_DrawPatch(x - WIDESCREENDELTA, 0, patch);
      //				V_DrawPatch(ORIGWIDTH + WIDESCREENDELTA - x - 8, 0, patch);
      //			}
      //		}
    End;

    // [crispy] center unity rerelease wide status bar
    If (sbar^.width > ORIGWIDTH) And (sbar^.leftoffset = 0) Then Begin
      V_DrawPatch(ST_X + (ORIGWIDTH - sbar^.width) Div 2, 0, sbar);
    End
    Else Begin
      V_DrawPatch(ST_X, 0, sbar);
    End;

    // draw right side of bar if needed (Doom 1.0)
    If assigned(sbarr) Then
      V_DrawPatch(ST_ARMSBGX, 0, sbarr);

    // [crispy] back up arms widget background
    If (deathmatch = 0) Then
      V_DrawPatch(ST_ARMSBGX, 0, armsbg);

    // [crispy] killough 3/7/98: make face background change with displayplayer
    If (netgame) Then
      V_DrawPatch(ST_FX, 0, faceback[displayplayer]);

    V_RestoreBuffer();

    // [crispy] copy entire SCREENWIDTH, to preserve the pattern
    // to the left and right of the status bar in widescreen mode
    If (Not force) Then Begin
      V_CopyRect(ST_X, 0, st_backing_screen, SCREENWIDTH Shr crispy.hires, ST_HEIGHT, ST_X, ST_Y);
    End
    Else If (WIDESCREENDELTA > 0) And (Not st_firsttime) Then Begin
      V_CopyRect(0, 0, st_backing_screen, WIDESCREENDELTA, ST_HEIGHT, 0, ST_Y);
      V_CopyRect(ORIGWIDTH + WIDESCREENDELTA, 0, st_backing_screen, WIDESCREENDELTA, ST_HEIGHT, ORIGWIDTH + WIDESCREENDELTA, ST_Y);
    End;
  End;
End;

Procedure ST_DrawDemoTimer(time: int);
Begin
  Raise Exception.Create('Port me.');
End;

Procedure ST_drawWidgets(refresh: boolean);
Var
  i: int;
  gibbed: boolean;
Begin

  gibbed := false;

  // used by w_arms[] widgets
  st_armson := st_statusbaron And (deathmatch = 0);

  // used by w_frags widget
  st_fragson := (deathmatch <> 0) And st_statusbaron;

  //    dp_translation = ST_WidgetColor(hudcolor_ammo);
  //    STlib_updateNum(&w_ready, refresh);
  //    dp_translation = NULL;
  //
  //    // [crispy] draw "special widgets" in the Crispy HUD
  //    if (st_crispyhud)
  //    {
  //	// [crispy] draw berserk pack instead of no ammo if appropriate
  //	if (plyr->readyweapon == wp_fist && plyr->powers[pw_strength])
  //	{
  //		static int lump = -1;
  //		patch_t *patch;
  //
  //		if (lump == -1)
  //		{
  //			lump = W_CheckNumForName(DEH_String("PSTRA0"));
  //
  //			if (lump == -1)
  //			{
  //				lump = W_CheckNumForName(DEH_String("MEDIA0"));
  //			}
  //		}
  //
  //		patch = W_CacheLumpNum(lump, PU_CACHE);
  //
  //		// [crispy] (23,179) is the center of the Ammo widget
  //		V_DrawPatch(ST_AMMOX - 21 - SHORT(patch->width)/2 + SHORT(patch->leftoffset),
  //		            179 - SHORT(patch->height)/2 + SHORT(patch->topoffset),
  //		            patch);
  //
  //	}
  //
  //	// [crispy] draw the gibbed death state frames in the Health widget
  //	// in sync with the actual player sprite
  //	if ((gibbed = ST_PlayerIsGibbed()))
  //	{
  //		ST_DrawGibbedPlayerSprites();
  //	}
  //   }
  //
  //    for (i=0;i<4;i++)
  //    {
  //	STlib_updateNum(&w_ammo[i], refresh);
  //	STlib_updateNum(&w_maxammo[i], refresh);
  //    }
  //
  //    if (!gibbed)
  //    {
  //    dp_translation = ST_WidgetColor(hudcolor_health);
  //    // [crispy] negative player health
  //    w_health.n.num = crispy->neghealth ? &plyr->neghealth : &plyr->health;
  //    STlib_updatePercent(&w_health, refresh);
  //    }
  //    dp_translation = ST_WidgetColor(hudcolor_armor);
  //    STlib_updatePercent(&w_armor, refresh);
  //    dp_translation = NULL;
  //
  //    STlib_updateBinIcon(&w_armsbg, refresh);
  //
  //    // [crispy] show SSG availability in the Shotgun slot of the arms widget
  //    st_shotguns = plyr->weaponowned[wp_shotgun] | plyr->weaponowned[wp_supershotgun];
  //
  //    for (i=0;i<6;i++)
  //	STlib_updateMultIcon(&w_arms[i], refresh);
  //
  //    // [crispy] draw the actual face widget background
  //    if (st_crispyhud && (screenblocks % 3 == 0))
  //    {
  //		if (netgame)
  //		V_DrawPatch(ST_FX, ST_Y + 1, faceback[displayplayer]);
  //		else
  //		V_CopyRect(ST_FX + WIDESCREENDELTA, 1, st_backing_screen, SHORT(faceback[0]->width), ST_HEIGHT - 1, ST_FX + WIDESCREENDELTA, ST_Y + 1);
  //    }
  //
  //    STlib_updateMultIcon(&w_faces, refresh);
  //
  //    for (i=0;i<3;i++)
  //	STlib_updateMultIcon(&w_keyboxes[i], refresh);
  //
  //    dp_translation = ST_WidgetColor(hudcolor_frags);
  //    STlib_updateNum(&w_frags, refresh);
  //
  //    dp_translation = NULL;
End;

Procedure ST_doRefresh();
Begin
  st_firsttime := false;

  // draw status bar background to off-screen buff
  ST_refreshBackground(false);

  // and refresh all widgets
  ST_drawWidgets(true);
End;

Procedure ST_diffDraw();
Begin
  // update all widgets
  ST_drawWidgets(false);
End;

Procedure ST_Drawer(fullscreen, refresh: boolean);
Begin
  st_statusbaron := (Not fullscreen) Or ((automapactive) And (true {!crispy->automapoverlay}));
  // [crispy] immediately redraw status bar after help screens have been shown
  st_firsttime := st_firsttime Or refresh Or inhelpscreens;

  // [crispy] distinguish classic status bar with background and player face from Crispy HUD
  st_crispyhud := (screenblocks >= CRISPY_HUD) And (Not automapactive Or false {crispy->automapoverlay});
  st_classicstatusbar := st_statusbaron And Not st_crispyhud;
  st_statusbarface := st_classicstatusbar Or (st_crispyhud And (screenblocks Mod 3 = 0));

  //    // [crispy] re-calculate widget coordinates on demand
  //    if (st_widescreendelta != ST_WIDESCREENDELTA)
  //    {
  //        void ST_createWidgets (void);
  //        ST_createWidgets();
  //    }

  //    if (crispy->cleanscreenshot == 2)
  //        return;

  // [crispy] translucent HUD
  If (st_crispyhud And (screenblocks Mod 3 = 2)) Then
    dp_translucent := true;

  If (st_firsttime) Then Begin
    // If just after ST_Start(), refresh all
    ST_doRefresh();
  End
  Else Begin
    // Otherwise, update as little as possible
    ST_diffDraw();
  End;

  dp_translucent := false;
End;

Function cht_CheckCheatSP(Var cht: cheatseq_t; key: char): int;
Begin
  If (cht_CheckCheat(cht, key) = 0) Then Begin
    result := 0;
    exit;
  End
  Else Begin
    If (Not crispy.singleplayer) Then Begin
      plyr^.message := 'Cheater!';
      result := 0;
      exit;
    End;
  End;
  result := 1;
End;

// [crispy] give or take backpack

Procedure GiveBackpack(give: boolean);
Var
  i: int;
Begin
  If (give) And (Not plyr^.backpack) Then Begin
    For i := 0 To integer(NUMAMMO) - 1 Do Begin
      plyr^.maxammo[i] := plyr^.maxammo[i] * 2;
    End;
    plyr^.backpack := true;
  End
  Else If (Not give) And (plyr^.backpack) Then Begin
    For i := 0 To integer(NUMAMMO) - 1 Do Begin
      plyr^.maxammo[i] := plyr^.maxammo[i] Div 2;
    End;
    plyr^.backpack := false;
  End;
End;

// [crispy] only give available weapons

Function WeaponAvailable(w: int): boolean;
Begin
  result := false;

  If (w < 0) Or (w >= integer(NUMWEAPONS)) Then exit;

  If (w = integer(wp_supershotgun)) And (Not crispy.havessg) Then exit;

  If ((w = integer(wp_bfg)) Or (w = integer(wp_plasma))) And (gamemode = shareware) Then exit;

  result := true;
End;

// Respond to keyboard input events,
//  intercept cheats.

Function ST_Responder(Const ev: Pevent_t): boolean;
Var
  i: int;
  mt: mapthing_t;
  an: angle_t;
Begin
  result := false;
  // Filter automap on/off.
  If (ev^._type = ev_keyup)
    And ((ev^.data1 And $FFFF0000) = AM_MSGHEADER) Then Begin

    Case ev^.data1 Of

      AM_MSGENTERED: Begin
          st_firsttime := true;
        End;

      AM_MSGEXITED: Begin
          //	writeln(stderr, 'AM exited');
        End;
    End;
  End
    // if a user keypress...
  Else If (ev^._type = ev_keydown) Then Begin
    If (Not netgame) And (gameskill <> sk_nightmare) Then Begin
      // 'dqd' cheat for toggleable god mode
      If (cht_CheckCheatSP(cheat_god, chr(ev^.data2)) <> 0) Then Begin
        // [crispy] dead players are first respawned at the current position
        If (plyr^.playerstate = PST_DEAD) Then Begin
          FillChar(mt, sizeof(mt), 0);
          mt.x := SarLongint(plyr^.mo^.x, FRACBITS);
          mt.y := SarLongint(plyr^.mo^.y, FRACBITS);
          mt.angle := angle_t((plyr^.mo^.angle + ANG45 Div 2) * uint64_t(45) Div ANG45);
          mt._type := consoleplayer + 1;
          P_SpawnPlayer(mt);

          // [crispy] spawn a teleport fog
          an := plyr^.mo^.angle Shr ANGLETOFINESHIFT;
          P_SpawnMobj(plyr^.mo^.x + 20 * finecosine[an], plyr^.mo^.y + 20 * finesine[an], plyr^.mo^.z, MT_TFOG);
          S_StartSound(plyr, sfx_slop);

          // Fix reviving as "zombie" if god mode was already enabled
          If assigned(plyr^.mo) Then
            plyr^.mo^.health := deh_god_mode_health;
          plyr^.health := deh_god_mode_health;
        End;

        plyr^.cheats := plyr^.cheats Xor integer(CF_GODMODE);
        If (plyr^.cheats And integer(CF_GODMODE)) <> 0 Then Begin
          If assigned(plyr^.mo) Then
            plyr^.mo^.health := deh_god_mode_health;

          plyr^.health := deh_god_mode_health;
          plyr^.message := STSTR_DQDON;
        End
        Else
          plyr^.message := STSTR_DQDOFF;

        // [crispy] eat key press when respawning
        If (mt._type <> 0) Then Begin
          result := true;
          exit;
        End;
      End
        // 'fa' cheat for killer fucking arsenal
      Else If (cht_CheckCheatSP(cheat_ammonokey, chr(ev^.data2)) <> 0) Then Begin
        plyr^.armorpoints := deh_idfa_armor;
        plyr^.armortype := deh_idfa_armor_class;

        // [crispy] give backpack
        GiveBackpack(true);

        For i := 0 To integer(NUMWEAPONS) - 1 Do
          If (WeaponAvailable(i)) Then // [crispy] only give available weapons
            plyr^.weaponowned[weapontype_t(i)] := true;

        For i := 0 To integer(NUMAMMO) - 1 Do
          plyr^.ammo[i] := plyr^.maxammo[i];

        // [crispy] trigger evil grin now
        plyr^.bonuscount := plyr^.bonuscount + 2;

        plyr^.message := STSTR_FAADDED;
      End
        // 'kfa' cheat for key full ammo
      Else If (cht_CheckCheatSP(cheat_ammo, chr(ev^.data2)) <> 0) Then Begin

        plyr^.armorpoints := deh_idkfa_armor;
        plyr^.armortype := deh_idkfa_armor_class;

        // [crispy] give backpack
        GiveBackpack(true);

        For i := 0 To integer(NUMWEAPONS) - 1 Do
          If (WeaponAvailable(i)) Then // [crispy] only give available weapons
            plyr^.weaponowned[weapontype_t(i)] := true;

        For i := 0 To integer(NUMAMMO) - 1 Do
          plyr^.ammo[i] := plyr^.maxammo[i];

        For i := 0 To integer(NUMCARDS) - 1 Do
          plyr^.cards[card_t(i)] := true;

        // [crispy] trigger evil grin now
        plyr^.bonuscount := plyr^.bonuscount + 2;

        plyr^.message := STSTR_KFAADDED;
      End
        //      // 'mus' cheat for changing music
        //      else if (cht_CheckCheat(&cheat_mus, ev->data2))
        //      {
        //
        //	char	buf[3];
        //	int		musnum;
        //
        //	plyr->message = DEH_String(STSTR_MUS);
        //	cht_GetParam(&cheat_mus, buf);
        //
        //        // Note: The original v1.9 had a bug that tried to play back
        //        // the Doom II music regardless of gamemode.  This was fixed
        //        // in the Ultimate Doom executable so that it would work for
        //        // the Doom 1 music as well.
        //
        //	// [crispy] restart current music if IDMUS00 is entered
        //	if (buf[0] == '0' && buf[1] == '0')
        //	{
        //	  S_ChangeMusic(0, 2);
        //	  // [crispy] eat key press, i.e. don't change weapon upon music change
        //	  return true;
        //	}
        //	else
        //	// [JN] Fixed: using a proper IDMUS selection for shareware
        //	// and registered game versions.
        //	if (gamemode == commercial /* || gameversion < exe_ultimate */ )
        //	{
        //	  musnum = mus_runnin + (buf[0]-'0')*10 + buf[1]-'0' - 1;
        //
        //	  /*
        //	  if (((buf[0]-'0')*10 + buf[1]-'0') > 35
        //       && gameversion >= exe_doom_1_8)
        //	  */
        //	  // [crispy] prevent crash with IDMUS00
        //	  if (musnum < mus_runnin || musnum >= NUMMUSIC)
        //	    plyr->message = DEH_String(STSTR_NOMUS);
        //	  else
        //	  {
        //	    S_ChangeMusic(musnum, 1);
        //	    // [crispy] eat key press, i.e. don't change weapon upon music change
        //	    return true;
        //	  }
        //	}
        //	else
        //	{
        //	  musnum = mus_e1m1 + (buf[0]-'1')*9 + (buf[1]-'1');
        //
        //	  /*
        //	  if (((buf[0]-'1')*9 + buf[1]-'1') > 31)
        //	  */
        //	  // [crispy] prevent crash with IDMUS0x or IDMUSx0
        //	  if (musnum < mus_e1m1 || musnum >= mus_runnin ||
        //	      // [crispy] support dedicated music tracks for the 4th episode
        //	      S_music[musnum].lumpnum == -1)
        //	    plyr->message = DEH_String(STSTR_NOMUS);
        //	  else
        //	  {
        //	    S_ChangeMusic(musnum, 1);
        //	    // [crispy] eat key press, i.e. don't change weapon upon music change
        //	    return true;
        //	  }
        //	}
        //      }
        //      // [crispy] eat up the first digit typed after a cheat expecting two parameters
        //      else if (cht_CheckCheat(&cheat_mus1, ev->data2))
        //      {
        //	char buf[2];
        //
        //	cht_GetParam(&cheat_mus1, buf);
        //
        //	return isdigit(buf[0]);
        //      }
        //      // [crispy] allow both idspispopd and idclip cheats in all gamemissions
      Else If (cht_CheckCheatSP(cheat_noclip, chr(ev^.data2)) <> 0)
        Or (cht_CheckCheatSP(cheat_commercial_noclip, chr(ev^.data2)) <> 0)
        Then Begin
        plyr^.cheats := plyr^.cheats Xor integer(CF_NOCLIP);
        If (plyr^.cheats And integer(CF_NOCLIP)) <> 0 Then
          plyr^.message := STSTR_NCON
        Else
          plyr^.message := STSTR_NCOFF;
      End;
      //      // 'behold?' power-up cheats
    //      for (i=0;i<6;i++)
    //      {
    //	if (i < 4 ? cht_CheckCheatSP(&cheat_powerup[i], ev->data2) : cht_CheckCheat(&cheat_powerup[i], ev->data2))
    //	{
    //	  if (!plyr->powers[i])
    //	    P_GivePower( plyr, i);
    //	  else if (i!=pw_strength && i!=pw_allmap) // [crispy] disable full Automap
    //	    plyr->powers[i] = 1;
    //	  else
    //	    plyr->powers[i] = 0;
    //
    //	  plyr->message = DEH_String(STSTR_BEHOLDX);
    //	}
    //      }
    //      // [crispy] idbehold0
    //      if (cht_CheckCheatSP(&cheat_powerup[7], ev->data2))
    //      {
    //	memset(plyr->powers, 0, sizeof(plyr->powers));
    //	plyr->mo->flags &= ~MF_SHADOW; // [crispy] cancel invisibility
    //	plyr->message = DEH_String(STSTR_BEHOLDX);
    //      }
    //
    //      // 'behold' power-up menu
    //      if (cht_CheckCheat(&cheat_powerup[6], ev->data2))
    //      {
    //	plyr->message = DEH_String(STSTR_BEHOLD);
    //      }
    //      // 'choppers' invulnerability & chainsaw
    //      else if (cht_CheckCheatSP(&cheat_choppers, ev->data2))
    //      {
    //	plyr->weaponowned[wp_chainsaw] = true;
    //	plyr->powers[pw_invulnerability] = true;
    //	plyr->message = DEH_String(STSTR_CHOPPERS);
    //      }
    //      // 'mypos' for player position
    //      else if (cht_CheckCheat(&cheat_mypos, ev->data2))
    //      {
    ///*
    //        static char buf[ST_MSGWIDTH];
    //        M_snprintf(buf, sizeof(buf), "ang=0x%x;x,y=(0x%x,0x%x)",
    //                   players[consoleplayer].mo->angle,
    //                   players[consoleplayer].mo->x,
    //                   players[consoleplayer].mo->y);
    //        plyr->message = buf;
    //*/
    //        // [crispy] extra high precision IDMYPOS variant, updates for 10 seconds
    //        plyr->powers[pw_mapcoords] = 10*TICRATE;
    //      }
    //
    //// [crispy] now follow "critical" Crispy Doom specific cheats
    //
    //      // [crispy] implement Boom's "tntem" cheat
    //      else if (cht_CheckCheatSP(&cheat_massacre, ev->data2) ||
    //               cht_CheckCheatSP(&cheat_massacre2, ev->data2) ||
    //               cht_CheckCheatSP(&cheat_massacre3, ev->data2))
    //      {
    //	int killcount = ST_cheat_massacre();
    //	const char *const monster = (gameversion == exe_chex) ? "Flemoid" : "Monster";
    //	const char *const killed = (gameversion == exe_chex) ? "returned" : "killed";
    //
    //	M_snprintf(msg, sizeof(msg), "%s%d %s%s%s %s",
    //	           crstr[CR_GOLD],
    //	           killcount, crstr[CR_NONE], monster, (killcount == 1) ? "" : "s", killed);
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement Crispy Doom's "spechits" cheat
    //      else if (cht_CheckCheatSP(&cheat_spechits, ev->data2))
    //      {
    //	int triggeredlines = ST_cheat_spechits();
    //
    //	M_snprintf(msg, sizeof(msg), "%s%d %sSpecial Line%s Triggered",
    //	           crstr[CR_GOLD],
    //	           triggeredlines, crstr[CR_NONE], (triggeredlines == 1) ? "" : "s");
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement PrBoom+'s "notarget" cheat
    //      else if (cht_CheckCheatSP(&cheat_notarget, ev->data2) ||
    //               cht_CheckCheatSP(&cheat_notarget2, ev->data2))
    //      {
    //	plyr->cheats ^= CF_NOTARGET;
    //
    //	if (plyr->cheats & CF_NOTARGET)
    //	{
    //		int i;
    //		thinker_t *th;
    //
    //		// [crispy] let mobjs forget their target and tracer
    //		for (th = thinkercap.next; th != &thinkercap; th = th->next)
    //		{
    //			if (th->function.acp1 == (actionf_p1)P_MobjThinker)
    //			{
    //				mobj_t *const mo = (mobj_t *)th;
    //
    //				if (mo->target && mo->target->player)
    //				{
    //					mo->target = NULL;
    //				}
    //
    //				if (mo->tracer && mo->tracer->player)
    //				{
    //					mo->tracer = NULL;
    //				}
    //			}
    //		}
    //		// [crispy] let sectors forget their soundtarget
    //		for (i = 0; i < numsectors; i++)
    //		{
    //			sector_t *const sector = &sectors[i];
    //
    //			sector->soundtarget = NULL;
    //		}
    //	}
    //
    //	M_snprintf(msg, sizeof(msg), "Notarget Mode %s%s",
    //	           crstr[CR_GREEN],
    //	           (plyr->cheats & CF_NOTARGET) ? "ON" : "OFF");
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement "nomomentum" cheat, ne debug aid -- pretty useless, though
    //      else if (cht_CheckCheatSP(&cheat_nomomentum, ev->data2))
    //      {
    //	plyr->cheats ^= CF_NOMOMENTUM;
    //
    //	M_snprintf(msg, sizeof(msg), "Nomomentum Mode %s%s",
    //	           crstr[CR_GREEN],
    //	           (plyr->cheats & CF_NOMOMENTUM) ? "ON" : "OFF");
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement Crispy Doom's "goobers" cheat, ne easter egg
    //      else if (cht_CheckCheatSP(&cheat_goobers, ev->data2))
    //      {
    //	extern void EV_DoGoobers (void);
    //
    //	EV_DoGoobers();
    //
    //	R_SetGoobers(true);
    //
    //	M_snprintf(msg, sizeof(msg), "Get Psyched!");
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement Boom's "tntweap?" weapon cheats
    //      else if (cht_CheckCheatSP(&cheat_weapon, ev->data2))
    //      {
    //	char		buf[2];
    //	int		w;
    //
    //	cht_GetParam(&cheat_weapon, buf);
    //	w = *buf - '1';
    //
    //	// [crispy] TNTWEAP0 takes away all weapons and ammo except for the pistol and 50 bullets
    //	if (w == -1)
    //	{
    //	    GiveBackpack(false);
    //	    plyr->powers[pw_strength] = 0;
    //
    //	    for (i = 0; i < NUMWEAPONS; i++)
    //	    {
    //		oldweaponsowned[i] = plyr->weaponowned[i] = false;
    //	    }
    //	    oldweaponsowned[wp_fist] = plyr->weaponowned[wp_fist] = true;
    //	    oldweaponsowned[wp_pistol] = plyr->weaponowned[wp_pistol] = true;
    //
    //	    for (i = 0; i < NUMAMMO; i++)
    //	    {
    //		plyr->ammo[i] = 0;
    //	    }
    //	    plyr->ammo[am_clip] = deh_initial_bullets;
    //
    //	    if (plyr->readyweapon > wp_pistol)
    //	    {
    //		plyr->pendingweapon = wp_pistol;
    //	    }
    //
    //	    plyr->message = "All weapons removed!";
    //
    //	    return true;
    //	}
    //
    //	// [crispy] only give available weapons
    //	if (!WeaponAvailable(w))
    //	    return false;
    //
    //	// make '1' apply beserker strength toggle
    //	if (w == wp_fist)
    //	{
    //	    if (!plyr->powers[pw_strength])
    //	    {
    //		P_GivePower(plyr, pw_strength);
    //		S_StartSound(NULL, sfx_getpow);
    //		plyr->message = DEH_String(GOTBERSERK);
    //	    }
    //	    else
    //	    {
    //		plyr->powers[pw_strength] = 0;
    //		plyr->message = DEH_String(STSTR_BEHOLDX);
    //	    }
    //	}
    //	else
    //	{
    //	    if (!plyr->weaponowned[w])
    //	    {
    //		extern boolean P_GiveWeapon (player_t* player, weapontype_t weapon, boolean dropped);
    //		extern const char *const WeaponPickupMessages[NUMWEAPONS];
    //
    //		P_GiveWeapon(plyr, w, false);
    //		S_StartSound(NULL, sfx_wpnup);
    //
    //		if (w > 1)
    //		{
    //		    plyr->message = DEH_String(WeaponPickupMessages[w]);
    //		}
    //
    //		// [crispy] trigger evil grin now
    //		plyr->bonuscount += 2;
    //	    }
    //	    else
    //	    {
    //		// [crispy] no reason for evil grin
    //		oldweaponsowned[w] = plyr->weaponowned[w] = false;
    //
    //		// [crispy] removed current weapon, select another one
    //		if (w == plyr->readyweapon)
    //		{
    //		    extern boolean P_CheckAmmo (player_t* player);
    //
    //		    P_CheckAmmo(plyr);
    //		}
    //	    }
    //	}
    //
    //	if (!plyr->message)
    //	{
    //	    M_snprintf(msg, sizeof(msg), "Weapon %s%d%s %s",
    //	               crstr[CR_GOLD], w + 1, crstr[CR_NONE],
    //	               plyr->weaponowned[w] ? "added" : "removed");
    //	    plyr->message = msg;
    //	}
    //      }

    End;


    //// [crispy] now follow "harmless" Crispy Doom specific cheats
    //
    //    // [crispy] implement Crispy Doom's "showfps" cheat, ne debug aid
    //    if (cht_CheckCheat(&cheat_showfps, ev->data2) ||
    //             cht_CheckCheat(&cheat_showfps2, ev->data2))
    //    {
    //	plyr->powers[pw_showfps] ^= 1;
    //    }
    //    // [crispy] implement Boom's "tnthom" cheat
    //    else if (cht_CheckCheat(&cheat_hom, ev->data2))
    //    {
    //	crispy->flashinghom = !crispy->flashinghom;
    //
    //	M_snprintf(msg, sizeof(msg), "HOM Detection %s%s",
    //	           crstr[CR_GREEN],
    //	           (crispy->flashinghom) ? "ON" : "OFF");
    //	plyr->message = msg;
    //    }
    //    // [crispy] Show engine version, build date and SDL version
    //    else if (cht_CheckCheat(&cheat_version, ev->data2))
    //    {
    //#ifndef BUILD_DATE
    //#define BUILD_DATE __DATE__
    //#endif
    //      M_snprintf(msg, sizeof(msg), "%s (%s) x%ld SDL%s",
    //                 PACKAGE_STRING,
    //                 BUILD_DATE,
    //                 (long) sizeof(void *) * CHAR_BIT,
    //                 crispy->sdlversion);
    //#undef BUILD_DATE
    //      plyr->message = msg;
    //      fprintf(stderr, "%s\n", msg);
    //    }
    //    // [crispy] Show skill level
    //    else if (cht_CheckCheat(&cheat_skill, ev->data2))
    //    {
    //      extern const char *skilltable[];
    //
    //      M_snprintf(msg, sizeof(msg), "Skill: %s",
    //                 skilltable[BETWEEN(0,5,(int) gameskill+1)]);
    //      plyr->message = msg;
    //    }
    //    // [crispy] snow
    //    else if (cht_CheckCheat(&cheat_snow, ev->data2))
    //    {
    //      crispy->snowflakes = !crispy->snowflakes;
    //    }
    //
    //    // 'clev' change-level cheat
    //    if (!netgame && cht_CheckCheat(&cheat_clev, ev->data2) && !menuactive) // [crispy] prevent only half the screen being updated
    //    {
    //      char		buf[3];
    //      int		epsd;
    //      int		map;
    //
    //      cht_GetParam(&cheat_clev, buf);
    //
    //      if (gamemode == commercial)
    //      {
    //	if (gamemission == pack_master)
    //	    epsd = 3;
    //	else
    //	if (gamemission == pack_nerve)
    //	    epsd = 2;
    //	else
    //	epsd = 0;
    //	map = (buf[0] - '0')*10 + buf[1] - '0';
    //      }
    //      else
    //      {
    //	epsd = buf[0] - '0';
    //	map = buf[1] - '0';
    //
    //        // Chex.exe always warps to episode 1.
    //
    //        if (gameversion == exe_chex)
    //        {
    //            if (epsd > 1)
    //            {
    //                epsd = 1;
    //            }
    //            if (map > 5)
    //            {
    //                map = 5;
    //            }
    //        }
    //      }
    //
    //  // [crispy] only fix episode/map if it doesn't exist
    //  if (P_GetNumForMap(epsd, map, false) < 0)
    //  {
    //      // Catch invalid maps.
    //      if (gamemode != commercial)
    //      {
    //          // [crispy] allow IDCLEV0x to work in Doom 1
    //          if (epsd == 0)
    //          {
    //              epsd = gameepisode;
    //          }
    //          if (epsd < 1)
    //          {
    //              return false;
    //          }
    //          if (epsd > 4)
    //          {
    //              // [crispy] Sigil
    //              if (!(crispy->haved1e5 && epsd == 5) &&
    //                  !(crispy->haved1e6 && epsd == 6))
    //              return false;
    //          }
    //          if (epsd == 4 && gameversion < exe_ultimate)
    //          {
    //              return false;
    //          }
    //          // [crispy] IDCLEV00 restarts current map
    //          if ((map == 0) && (buf[0] - '0' == 0))
    //          {
    //              map = gamemap;
    //          }
    //          // [crispy] support E1M10 "Sewers"
    //          if ((map == 0 || map > 9) && crispy->havee1m10 && epsd == 1)
    //          {
    //              map = 10;
    //          }
    //          if (map < 1)
    //          {
    //              return false;
    //          }
    //          if (map > 9)
    //          {
    //              // [crispy] support E1M10 "Sewers"
    //              if (!(crispy->havee1m10 && epsd == 1 && map == 10))
    //              return false;
    //          }
    //      }
    //      else
    //      {
    //          // [crispy] IDCLEV00 restarts current map
    //          if ((map == 0) && (buf[0] - '0' == 0))
    //          {
    //              map = gamemap;
    //          }
    //          if (map < 1)
    //          {
    //              return false;
    //          }
    //          if (map > 40)
    //          {
    //              return false;
    //          }
    //          if (map > 9 && gamemission == pack_nerve)
    //          {
    //              return false;
    //          }
    //          if (map > 21 && gamemission == pack_master)
    //          {
    //              return false;
    //          }
    //      }
    //  }
    //
    //      // [crispy] prevent idclev to nonexistent levels exiting the game
    //      if (P_GetNumForMap(epsd, map, false) >= 0)
    //      {
    //      // So be it.
    //      plyr->message = DEH_String(STSTR_CLEV);
    //      // [crisp] allow IDCLEV during demo playback and warp to the requested map
    //      if (demoplayback)
    //      {
    //          crispy->demowarp = map;
    //          nodrawers = true;
    //          singletics = true;
    //
    //          if (map <= gamemap)
    //          {
    //              G_DoPlayDemo();
    //          }
    //
    //           return true;
    //      }
    //      else
    //      G_DeferedInitNew(gameskill, epsd, map);
    //      // [crispy] eat key press, i.e. don't change weapon upon level change
    //      return true;
    //      }
    //    }
    //    // [crispy] eat up the first digit typed after a cheat expecting two parameters
    //    else if (!netgame && cht_CheckCheat(&cheat_clev1, ev->data2) && !menuactive)
    //    {
    //	char buf[2];
    //
    //	cht_GetParam(&cheat_clev1, buf);
    //
    //	return isdigit(buf[0]);
    //    }
  End;
End;

// Iterates through all graphics to be loaded or unloaded, along with
// the variable they use, invoking the specified callback function.

Procedure ST_loadUnloadGraphics(callback: load_callback_t);
Var
  i, j: int;
  facenum: int;
  namebuf: String;
Begin
  // Load the numbers, tall and short
  For i := 0 To 9 Do Begin

    namebuf := format('STTNUM%d', [i]);
    callback(namebuf, @tallnum[i]);

    namebuf := format('STYSNUM%d', [i]);
    callback(namebuf, @shortnum[i]);
  End;

  // Load percent key.
  //Note: why not load STMINUS here, too?

  callback('STTPRCNT', @tallpercent);

  // key cards
  For i := 0 To integer(NUMCARDS) - 1 Do Begin
    namebuf := format('STKEYS%d', [i]);
    callback(namebuf, @keys[i]);
  End;

  // arms background
  callback('STARMS', @armsbg);

  // arms ownership widgets
  For i := 0 To 5 Do Begin
    namebuf := format('STGNUM%d', [i + 2]);

    // gray #
    callback(namebuf, @arms[i][0]);

    // yellow #
    arms[i][1] := shortnum[i + 2];
  End;

  // face backgrounds for different color players
  // [crispy] killough 3/7/98: add better support for spy mode by loading
  // all player face backgrounds and using displayplayer to choose them:

  For i := 0 To MAXPLAYERS - 1 Do Begin
    namebuf := format('STFB%d', [i]);
    callback(namebuf, @faceback[i]);
  End;

  // status bar background bits
  If (W_CheckNumForName('STBAR') >= 0) Then Begin
    callback('STBAR', @sbar);
    sbarr := Nil;
  End
  Else Begin
    callback('STMBARL', @sbar);
    callback('STMBARR', @sbarr);
  End;

  // face states
  facenum := 0;
  For i := 0 To ST_NUMPAINFACES - 1 Do Begin
    For j := 0 To ST_NUMSTRAIGHTFACES - 1 Do Begin
      namebuf := format('STFST%d%d', [i, j]);
      callback(namebuf, @faces[facenum]);
      facenum := facenum + 1;
    End;
    namebuf := format('STFTR%d0', [i]); // turn right
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
    namebuf := format('STFTL%d0', [i]); // turn left
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
    namebuf := format('STFOUCH%d', [i]); // ouch!
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
    namebuf := format('STFEVL%d', [i]); // evil grin ;)
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
    namebuf := format('STFKILL%d', [i]); // pissed off
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
  End;

  callback('STFGOD0', @faces[facenum]);
  facenum := facenum + 1;
  callback('STFDEAD0', @faces[facenum]);
  facenum := facenum + 1;
End;

Procedure ST_loadCallback(lumpname: String; variable: PPPatch_t);
Begin
  variable^ := W_CacheLumpName(lumpname, PU_STATIC);
End;

Procedure ST_loadGraphics();
Begin
  ST_loadUnloadGraphics(@ST_loadCallback);
End;

Procedure ST_loadData();
Var
  i: int;
  lumpname: String;
  lumpnum: int;
Begin
  lu_palette := W_GetNumForName('PLAYPAL');
  ST_loadGraphics();

  // [crispy] support combined card and skull keys (if provided by PWAD)
  // i.e. only for display in the status bar
  For i := integer(NUMCARDS) To integer(NUMCARDS) + 3 - 1 Do Begin
    lumpname := format('STKEYS%d', [i]);
    lumpnum := W_CheckNumForName(lumpname);
    If (lumpnum <> -1) Then Begin
      keys[i] := W_CacheLumpNum(lumpnum, PU_STATIC);
    End
    Else Begin
      keys[i] := keys[i - 3];
    End;
  End;
End;

Procedure ST_Init();
Begin
  // [crispy] colorize the confusing 'behold' power-up menu
  //    if (!DEH_HasStringReplacement(STSTR_BEHOLD) &&
  //        !M_ParmExists("-nodeh"))
  //    {
  //	char str_behold[80];
  //	M_snprintf(str_behold, sizeof(str_behold),
  //	           "in%sV%suln, %sS%str, %sI%snviso, %sR%sad, %sA%sllmap, or %sL%site-amp",
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE]);
  //	DEH_AddStringReplacement(STSTR_BEHOLD, str_behold);
  //    }

  ST_loadData();
  setlength(st_backing_screen, MAXWIDTH * (ST_HEIGHT Shl 1) * sizeof(pixel_t)); // WTF: müsste hier nicht Crispy.hires +1 stehen ?
End;


End.

