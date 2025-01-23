Unit st_stuff;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef
  , i_video
  ;

Var
  st_keyorskull: Array[card_t] Of int; // Es werden aber nur it_bluecard .. it_redcard genutzt

Procedure ST_Start();

Procedure ST_Drawer(fullscreen, refresh: boolean);

Implementation

Uses
  info_types
  , am_map
  , d_items
  , g_game
  , m_menu
  , st_lib
  , v_patch, v_video
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
  CRISPY_HUD = 12;

Var
  st_widescreendelta: int;
  st_stopped: boolean = true;
  st_firsttime: Boolean;
  plyr: ^player_t;
  // whether left-side main status bar is active
  st_statusbaron: boolean;
  // value of st_chat before message popped up
  st_oldchat: boolean;
  // whether status bar chat is active
  st_chat: boolean;
  // current face index, used by w_faces
  st_faceindex: int = 0;
  st_palette: int = 0;
  // used to use appopriately pained face
  st_oldhealth: int = -1;

  // 0-9, tall numbers
  tallnum: Array[0..9] Of patch_t;

  // ready-weapon widget
  w_ready: st_number_t;

  faceindex: int;
  // holds key-type for each key box on bar
  keyboxes: Array[0..2] Of int;
  // used for evil grin
  oldweaponsowned: Array[0..integer(NUMWEAPONS) - 1] Of boolean;

  // [crispy] distinguish classic status bar with background and player face from Crispy HUD
  st_crispyhud: boolean;
  st_classicstatusbar: boolean;
  st_statusbarface: boolean;

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
    tallnum,
    @plyr^.ammo[integer(weaponinfo[integer(plyr^.readyweapon)].ammo)],
    @st_statusbaron,
    ST_AMMOWIDTH);
  //
  //    // the last weapon type
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
  //
  //    // arms background
  //    STlib_initBinIcon(&w_armsbg,
  //		      ST_ARMSBGX,
  //		      ST_ARMSBGY,
  //		      armsbg,
  //		      &st_notdeathmatch,
  //		      &st_classicstatusbar);
  //
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

Procedure ST_Start();
Begin
  If (Not st_stopped) Then ST_Stop();

  ST_initData();
  ST_createWidgets();
  st_stopped := false;
End;


Procedure ST_refreshBackground(force: boolean);
Begin

  //    if (st_classicstatusbar || force)
  //    {
  //        V_UseBuffer(st_backing_screen);
  //
  //	// [crispy] this is our own local copy of R_FillBackScreen() to
  //	// fill the entire background of st_backing_screen with the bezel pattern,
  //	// so it appears to the left and right of the status bar in widescreen mode
  //	if ((SCREENWIDTH >> crispy->hires) != ST_WIDTH)
  //	{
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
  //	}
  //
  //	// [crispy] center unity rerelease wide status bar
  //	if (SHORT(sbar->width) > ORIGWIDTH && SHORT(sbar->leftoffset) == 0)
  //	{
  //	    V_DrawPatch(ST_X + (ORIGWIDTH - SHORT(sbar->width)) / 2, 0, sbar);
  //	}
  //	else
  //	{
  //	    V_DrawPatch(ST_X, 0, sbar);
  //	}
  //
  //	// draw right side of bar if needed (Doom 1.0)
  //	if (sbarr)
  //	    V_DrawPatch(ST_ARMSBGX, 0, sbarr);
  //
  //	// [crispy] back up arms widget background
  //	if (!deathmatch)
  //	    V_DrawPatch(ST_ARMSBGX, 0, armsbg);
  //
  //	// [crispy] killough 3/7/98: make face background change with displayplayer
  //	if (netgame)
  //	    V_DrawPatch(ST_FX, 0, faceback[displayplayer]);
  //
  //        V_RestoreBuffer();
  //
  //	// [crispy] copy entire SCREENWIDTH, to preserve the pattern
  //	// to the left and right of the status bar in widescreen mode
  //	if (!force)
  //	{
  //	    V_CopyRect(ST_X, 0, st_backing_screen, SCREENWIDTH >> crispy->hires, ST_HEIGHT, ST_X, ST_Y);
  //	}
  //	else if (WIDESCREENDELTA > 0 && !st_firsttime)
  //	{
  //	    V_CopyRect(0, 0, st_backing_screen, WIDESCREENDELTA, ST_HEIGHT, 0, ST_Y);
  //	    V_CopyRect(ORIGWIDTH + WIDESCREENDELTA, 0, st_backing_screen, WIDESCREENDELTA, ST_HEIGHT, ORIGWIDTH + WIDESCREENDELTA, ST_Y);
  //	}
  //    }
End;

Procedure ST_drawWidgets(refresh: boolean);
Begin
  //    int		i;
  //    boolean gibbed = false;
  //
  //    // used by w_arms[] widgets
  //    st_armson = st_statusbaron && !deathmatch;
  //
  //    // used by w_frags widget
  //    st_fragson = deathmatch && st_statusbaron;
  //
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

End.

