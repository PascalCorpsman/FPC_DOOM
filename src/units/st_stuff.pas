Unit st_stuff;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef
  ;

Var
  st_keyorskull: Array[card_t] Of int; // Es werden aber nur it_bluecard .. it_redcard genutzt


Procedure ST_Start();

Implementation

Uses
  info_types
  , d_items
  , g_game
  , i_video
  , st_lib
  , v_patch
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

End.

