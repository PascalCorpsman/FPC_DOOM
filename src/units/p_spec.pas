Unit p_spec;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  info_types
  , m_fixed
  ;

Const
  VDOORSPEED = FRACUNIT * 2;
  VDOORWAIT = 150;

  //
  // P_FLOOR
  //
Type
  floor_e = (
    // lower floor to highest surrounding floor
    lowerFloor,

    // lower floor to lowest surrounding floor
    lowerFloorToLowest,

    // lower floor to highest surrounding floor VERY FAST
    turboLower,

    // raise floor to lowest surrounding CEILING
    raiseFloor,

    // raise floor to next highest surrounding floor
    raiseFloorToNearest,

    // raise floor to shortest height texture around it
    raiseToTexture,

    // lower floor to lowest surrounding floor
    //  and change floorpic
    lowerAndChange,

    raiseFloor24,
    raiseFloor24AndChange,
    raiseFloorCrush,

    // raise to next highest floor, turbo-speed
    raiseFloorTurbo,
    donutRaise,
    raiseFloor512
    );

  //
  // P_DOORS
  //
  vldoor_e = (
    vld_normal,
    vld_close30ThenOpen,
    vld_close,
    vld_open,
    vld_raiseIn5Mins,
    vld_blazeRaise,
    vld_blazeOpen,
    vld_blazeClose
    );

  vldoor_t = Record
    thinker: thinker_t;
    _type: vldoor_e;
    sector: Psector_t;
    topheight: fixed_t;
    speed: fixed_t;

    // 1 = up, 0 = waiting at top, -1 = down
    direction: int;

    // tics to wait at the top
    topwait: int;
    // (keep in case a door going down is reset)
    // when it reaches 0, start going down
    topcountdown: int;
  End;
  Pvldoor_t = ^vldoor_t;

  plattype_e = (
    perpetualRaise,
    downWaitUpStay,
    raiseAndChange,
    raiseToNearestAndChange,
    blazeDWUS
    );

  result_e = (
    ok,
    crushed,
    pastdest
    );

Procedure P_InitPicAnims();
Procedure P_SpawnSpecials();
Procedure R_InterpolateTextureOffsets();
Procedure P_PlayerInSpecialSector(player: Pplayer_t);
Procedure P_UpdateSpecials();

Procedure P_ShootSpecialLine(thing: Pmobj_t; line: pline_t);
Procedure P_CrossSpecialLine(linenum, side: int; thing: Pmobj_t);

Function P_FindLowestCeilingSurrounding(sec: Psector_t): fixed_t;

Implementation

Uses
  doomstat, doomdata
  , d_loop, d_mode
  , i_timer
  , g_game
  , p_tick, p_setup, p_floor, p_switch, p_doors, p_plats
  , r_draw
  ;

Var
  levelTimer: boolean;
  levelTimeCount: int;

Procedure P_InitPicAnims();
Begin
  //     int		i;
  //    boolean init_swirl = false;
  //
  //    // [crispy] add support for ANIMATED lumps
  //    animdef_t *animdefs;
  //    const boolean from_lump = (W_CheckNumForName("ANIMATED") != -1);
  //
  //    if (from_lump)
  //    {
  //	animdefs = W_CacheLumpName("ANIMATED", PU_STATIC);
  //    }
  //    else
  //    {
  //	animdefs = animdefs_vanilla;
  //    }
  //
  //    //	Init animation
  //    lastanim = anims;
  //    for (i=0 ; animdefs[i].istexture != -1 ; i++)
  //    {
  //        const char *startname, *endname;
  //
  //	// [crispy] remove MAXANIMS limit
  //	if (lastanim >= anims + maxanims)
  //	{
  //	    size_t newmax = maxanims ? 2 * maxanims : MAXANIMS;
  //	    anims = I_Realloc(anims, newmax * sizeof(*anims));
  //	    lastanim = anims + maxanims;
  //	    maxanims = newmax;
  //	}
  //
  //        startname = DEH_String(animdefs[i].startname);
  //        endname = DEH_String(animdefs[i].endname);
  //
  //	if (animdefs[i].istexture)
  //	{
  //	    // different episode ?
  //	    if (R_CheckTextureNumForName(startname) == -1)
  //		continue;
  //
  //	    lastanim->picnum = R_TextureNumForName(endname);
  //	    lastanim->basepic = R_TextureNumForName(startname);
  //	}
  //	else
  //	{
  //	    if (W_CheckNumForName(startname) == -1)
  //		continue;
  //
  //	    lastanim->picnum = R_FlatNumForName(endname);
  //	    lastanim->basepic = R_FlatNumForName(startname);
  //	}
  //
  //	lastanim->istexture = animdefs[i].istexture;
  //	lastanim->numpics = lastanim->picnum - lastanim->basepic + 1;
  //	lastanim->speed = from_lump ? LONG(animdefs[i].speed) : animdefs[i].speed;
  //
  //	// [crispy] add support for SMMU swirling flats
  //	if (lastanim->speed > 65535 || lastanim->numpics == 1)
  //	{
  //		init_swirl = true;
  //	}
  //	else
  //	if (lastanim->numpics < 2)
  //	{
  //	    // [crispy] make non-fatal, skip invalid animation sequences
  //	    fprintf (stderr, "P_InitPicAnims: bad cycle from %s to %s\n",
  //		     startname, endname);
  //	    continue;
  //	}
  //
  //	lastanim++;
  //    }
  //
  //    if (from_lump)
  //    {
  //	W_ReleaseLumpName("ANIMATED");
  //    }
  //
  //    if (init_swirl)
  //    {
  //	R_InitDistortedFlats();
  //    }
End;

Procedure P_SpawnSpecials();
Var
  //sector_t*	sector;
  i: int;
Begin
  // See if -TIMER was specified.
  If (timelimit > 0) And (deathmatch <> 0) Then Begin
    levelTimer := true;
    levelTimeCount := timelimit * 60 * TICRATE;
  End
  Else Begin
    levelTimer := false;
  End;

  //	Init special SECTORs.
  //    sector = sectors;
  //    for (i=0 ; i<numsectors ; i++, sector++)
  //    {
  //	if (!sector->special)
  //	    continue;
  //
  //	switch (sector->special)
  //	{
  //	  case 1:
  //	    // FLICKERING LIGHTS
  //	    P_SpawnLightFlash (sector);
  //	    break;
  //
  //	  case 2:
  //	    // STROBE FAST
  //	    P_SpawnStrobeFlash(sector,FASTDARK,0);
  //	    break;
  //
  //	  case 3:
  //	    // STROBE SLOW
  //	    P_SpawnStrobeFlash(sector,SLOWDARK,0);
  //	    break;
  //
  //	  case 4:
  //	    // STROBE FAST/DEATH SLIME
  //	    P_SpawnStrobeFlash(sector,FASTDARK,0);
  //	    sector->special = 4;
  //	    break;
  //
  //	  case 8:
  //	    // GLOWING LIGHT
  //	    P_SpawnGlowingLight(sector);
  //	    break;
  //	  case 9:
  //	    // SECRET SECTOR
  //	    totalsecret++;
  //	    break;
  //
  //	  case 10:
  //	    // DOOR CLOSE IN 30 SECONDS
  //	    P_SpawnDoorCloseIn30 (sector);
  //	    break;
  //
  //	  case 12:
  //	    // SYNC STROBE SLOW
  //	    P_SpawnStrobeFlash (sector, SLOWDARK, 1);
  //	    break;
  //
  //	  case 13:
  //	    // SYNC STROBE FAST
  //	    P_SpawnStrobeFlash (sector, FASTDARK, 1);
  //	    break;
  //
  //	  case 14:
  //	    // DOOR RAISE IN 5 MINUTES
  //	    P_SpawnDoorRaiseIn5Mins (sector, i);
  //	    break;
  //
  //        case 17:
  //            // first introduced in official v1.4 beta
  //            if (gameversion > exe_doom_1_2)
  //            {
  //                P_SpawnFireFlicker(sector);
  //            }
  //            break;
  //	}
End;

Procedure R_InterpolateTextureOffsets();
Begin
  If (crispy.uncapped <> 0) And (leveltime > oldleveltime) Then Begin
    //		int i;
    //
    //		for (i = 0; i < numlinespecials; i++)
    //		{
    //			const line_t *const line = linespeciallist[i];
    //			side_t *const side = &sides[line->sidenum[0]];
    //
    //			if (line->special == 48)
    //			{
    //				side->textureoffset = side->basetextureoffset + fractionaltic;
    //			}
    //			else
    //			if (line->special == 85)
    //			{
    //				side->textureoffset = side->basetextureoffset - fractionaltic;
    //			}
    //		}
  End;
End;

//
// P_PlayerInSpecialSector
// Called every tic frame
//  that the player origin is in a special sector
//

Procedure P_PlayerInSpecialSector(player: Pplayer_t);
Begin
  //    sector_t*	sector;
  //    extern int showMessages;
  //    static sector_t*	error;
  //
  //    sector = player->mo->subsector->sector;
  //
  //    // Falling, not all the way down yet?
  //    if (player->mo->z != sector->floorheight)
  //	return;
  //
  //    // Has hitten ground.
  //    switch (sector->special)
  //    {
  //      case 5:
  //	// HELLSLIME DAMAGE
  //	// [crispy] no nukage damage with NOCLIP cheat
  //	if (!player->powers[pw_ironfeet] && !(player->mo->flags & MF_NOCLIP))
  //	    if (!(leveltime&0x1f))
  //		P_DamageMobj (player->mo, NULL, NULL, 10);
  //	break;
  //
  //      case 7:
  //	// NUKAGE DAMAGE
  //	// [crispy] no nukage damage with NOCLIP cheat
  //	if (!player->powers[pw_ironfeet] && !(player->mo->flags & MF_NOCLIP))
  //	    if (!(leveltime&0x1f))
  //		P_DamageMobj (player->mo, NULL, NULL, 5);
  //	break;
  //
  //      case 16:
  //	// SUPER HELLSLIME DAMAGE
  //      case 4:
  //	// STROBE HURT
  //	// [crispy] no nukage damage with NOCLIP cheat
  //	if ((!player->powers[pw_ironfeet]
  //	    || (P_Random()<5) ) && !(player->mo->flags & MF_NOCLIP))
  //	{
  //	    if (!(leveltime&0x1f))
  //		P_DamageMobj (player->mo, NULL, NULL, 20);
  //	}
  //	break;
  //
  //      case 9:
  //	// SECRET SECTOR
  //	player->secretcount++;
  //	// [crispy] show centered "Secret Revealed!" message
  //	if (showMessages && crispy->secretmessage && player == &players[consoleplayer])
  //	{
  //	    int sfx_id;
  //	    static char str_count[32];
  //
  //	    M_snprintf(str_count, sizeof(str_count), "Secret %d of %d revealed!", player->secretcount, totalsecret);
  //
  //	    // [crispy] play DSSECRET if available
  //	    sfx_id = I_GetSfxLumpNum(&S_sfx[sfx_secret]) != -1 ? sfx_secret :
  //	             I_GetSfxLumpNum(&S_sfx[sfx_itmbk]) != -1 ? sfx_itmbk : -1;
  //
  //	    player->centermessage = (crispy->secretmessage == SECRETMESSAGE_COUNT) ? str_count : HUSTR_SECRETFOUND;
  //	    if (sfx_id != -1)
  //		S_StartSound(NULL, sfx_id);
  //	}
  //	// [crispy] remember revealed secrets
  //	sector->oldspecial = sector->special;
  //	sector->special = 0;
  //	break;
  //
  //      case 11:
  //	// EXIT SUPER DAMAGE! (for E1M8 finale)
  //	player->cheats &= ~CF_GODMODE;
  //
  //	if (!(leveltime&0x1f))
  //	    P_DamageMobj (player->mo, NULL, NULL, 20);
  //
  //	if (player->health <= 10)
  //	    G_ExitLevel();
  //	break;
  //
  //      default:
  //	// [crispy] ignore unknown special sectors
  //	if (error != sector)
  //	{
  //	error = sector;
  //	fprintf (stderr, "P_PlayerInSpecialSector: "
  //		 "unknown special %i\n",
  //		 sector->special);
  //	}
  //	break;
  //    };
End;

Procedure P_UpdateSpecials();
Var
  //  anim_t*	anim;
  //    int		pic;
  i: int;
  //    line_t*	line;

Begin
  //	LEVEL TIMER
  If (levelTimer) Then Begin
    levelTimeCount := levelTimeCount - 1;
    If (levelTimeCount = 0) Then
      G_ExitLevel();
  End;

  //	ANIMATE FLATS AND TEXTURES GLOBALLY
//    for (anim = anims ; anim < lastanim ; anim++)
//    {
//	for (i=anim->basepic ; i<anim->basepic+anim->numpics ; i++)
//	{
//	    pic = anim->basepic + ( (leveltime/anim->speed + i)%anim->numpics );
//	    if (anim->istexture)
//		texturetranslation[i] = pic;
//	    else
//	    {
//		// [crispy] add support for SMMU swirling flats
//		if (anim->speed > 65535 || anim->numpics == 1)
//		{
//		    flattranslation[i] = -1;
//		}
//		else
//		flattranslation[i] = pic;
//	    }
//	}
//    }


    //	ANIMATE LINE SPECIALS
//    for (i = 0; i < numlinespecials; i++)
//    {
//	line = linespeciallist[i];
//	switch(line->special)
//	{
//	  case 48:
//	    // EFFECT FIRSTCOL SCROLL +
//	    // [crispy] smooth texture scrolling
//	    sides[line->sidenum[0]].basetextureoffset += FRACUNIT;
//	    sides[line->sidenum[0]].textureoffset =
//	    sides[line->sidenum[0]].basetextureoffset;
//	    break;
//	  case 85:
//	    // [JN] (Boom) Scroll Texture Right
//	    // [crispy] smooth texture scrolling
//	    sides[line->sidenum[0]].basetextureoffset -= FRACUNIT;
//	    sides[line->sidenum[0]].textureoffset =
//	    sides[line->sidenum[0]].basetextureoffset;
//	    break;
//	}
//    }


    //	DO BUTTONS
//    for (i = 0; i < maxbuttons; i++)
//	if (buttonlist[i].btimer)
//	{
//	    buttonlist[i].btimer--;
//	    if (!buttonlist[i].btimer)
//	    {
//		switch(buttonlist[i].where)
//		{
//		  case top:
//		    sides[buttonlist[i].line->sidenum[0]].toptexture =
//			buttonlist[i].btexture;
//		    break;
//
//		  case middle:
//		    sides[buttonlist[i].line->sidenum[0]].midtexture =
//			buttonlist[i].btexture;
//		    break;
//
//		  case bottom:
//		    sides[buttonlist[i].line->sidenum[0]].bottomtexture =
//			buttonlist[i].btexture;
//		    break;
//		}
//		// [crispy] & [JN] Logically proper sound behavior.
//		// Do not play second "sfx_swtchn" on two-sided linedefs that attached to special sectors,
//		// and always play second sound on single-sided linedefs.
//		if (crispy->soundfix)
//		{
//			if (!buttonlist[i].line->backsector || !buttonlist[i].line->backsector->specialdata)
//			{
//				S_StartSoundOnce(buttonlist[i].soundorg,sfx_swtchn);
//			}
//		}
//		else
//		{
//		S_StartSoundOnce(&buttonlist[i].soundorg,sfx_swtchn);
//		}
//		memset(&buttonlist[i],0,sizeof(button_t));
//	    }
//	}

//    // [crispy] Snow
//    if (crispy->snowflakes)
//	V_SnowUpdate();

  // [crispy] draw fuzz effect independent of rendering frame rate
  R_SetFuzzPosTic();
End;

//
// P_ShootSpecialLine - IMPACT SPECIALS
// Called when a thing shoots a special line.
//

Procedure P_ShootSpecialLine(thing: Pmobj_t; line: pline_t);
Var
  ok: int;
Begin
  // Impacts that other things can activate.
  If (thing^.player = Nil) Then Begin
    ok := 0;
    Case (line^.special) Of
      46: Begin
          // OPEN DOOR IMPACT
          ok := 1;
        End;
    End;
    If (ok = 0) Then
      exit;
  End;

  Case (line^.special) Of
    24: Begin
        // RAISE FLOOR
        EV_DoFloor(line, raiseFloor);
        P_ChangeSwitchTexture(line, 0);
      End;
    46: Begin
        // OPEN DOOR
        EV_DoDoor(line, vld_open);
        P_ChangeSwitchTexture(line, 1);
      End;
    47: Begin
        // RAISE FLOOR NEAR AND CHANGE
        EV_DoPlat(line, raiseToNearestAndChange, 0);
        P_ChangeSwitchTexture(line, 0);
      End;
  End;
End;

// [crispy] more MBF code pointers

Procedure P_CrossSpecialLinePtr(line: pline_t; side: int; thing: Pmobj_t);
Var
  ok: int;
Begin

  //  line = &lines[linenum];

  If (gameversion <= exe_doom_1_2) Then Begin
    If (line^.special > 98) And (line^.special <> 104) Then Begin
      exit;
    End;
  End
  Else Begin
    //	Triggers that other things can activate
    If (thing^.player = Nil) Then Begin

      // Things that should NOT trigger specials...
      Case (thing^._type) Of
        MT_ROCKET,
          MT_PLASMA,
          MT_BFG,
          MT_TROOPSHOT,
          MT_HEADSHOT,
          MT_BRUISERSHOT: Begin
            exit;
          End;
      End;
    End;
  End;

  If (thing^.player = Nil) Then Begin
    ok := 0;
    Case (line^.special) Of
      39, // TELEPORT TRIGGER
      97, // TELEPORT RETRIGGER
      125, // TELEPORT MONSTERONLY TRIGGER
      126, // TELEPORT MONSTERONLY RETRIGGER
      4, // RAISE DOOR
      10, // PLAT DOWN-WAIT-UP-STAY TRIGGER
      88: Begin // PLAT DOWN-WAIT-UP-STAY RETRIGGER
          ok := 1;
        End;
    End;
    If (ok = 0) Then exit;
  End;

  // Note: could use some const's here.
  Case (line^.special) Of
    // TRIGGERS.
    // All from here to RETRIGGERS.
    2: Begin
        // Open Door
        EV_DoDoor(line, vld_open);
        line^.special := 0;
      End;

    3: Begin
        // Close Door
        EV_DoDoor(line, vld_close);
        line^.special := 0;
      End;

    4: Begin
        // Raise Door
        EV_DoDoor(line, vld_normal);
        line^.special := 0;
      End;

    //      case 5:
    //	// Raise Floor
    //	EV_DoFloor(line,raiseFloor);
    //	line^.special = 0;
    //	break;

    //      case 6:
    //	// Fast Ceiling Crush & Raise
    //	EV_DoCeiling(line,fastCrushAndRaise);
    //	line^.special = 0;
    //	break;

    //      case 8:
    //	// Build Stairs
    //	EV_BuildStairs(line,build8);
    //	line^.special = 0;
    //	break;

    //      case 10:
    //	// PlatDownWaitUp
    //	EV_DoPlat(line,downWaitUpStay,0);
    //	line^.special = 0;
    //	break;

    //      case 12:
    //	// Light Turn On - brightest near
    //	EV_LightTurnOn(line,0);
    //	line^.special = 0;
    //	break;

    //      case 13:
    //	// Light Turn On 255
    //	EV_LightTurnOn(line,255);
    //	line^.special = 0;
    //	break;

    //      case 16:
    //	// Close Door 30
    //	EV_DoDoor(line,vld_close30ThenOpen);
    //	line^.special = 0;
    //	break;

    //      case 17:
    //	// Start Light Strobing
    //	EV_StartLightStrobing(line);
    //	line^.special = 0;
    //	break;

    //      case 19:
    //	// Lower Floor
    //	EV_DoFloor(line,lowerFloor);
    //	line^.special = 0;
    //	break;

    //      case 22:
    //	// Raise floor to nearest height and change texture
    //	EV_DoPlat(line,raiseToNearestAndChange,0);
    //	line^.special = 0;
    //	break;

    //      case 25:
    //	// Ceiling Crush and Raise
    //	EV_DoCeiling(line,crushAndRaise);
    //	line^.special = 0;
    //	break;

    //      case 30:
    //	// Raise floor to shortest texture height
    //	//  on either side of lines.
    //	EV_DoFloor(line,raiseToTexture);
    //	line^.special = 0;
    //	break;

    //      case 35:
    //	// Lights Very Dark
    //	EV_LightTurnOn(line,35);
    //	line^.special = 0;
    //	break;

    //      case 36:
    //	// Lower Floor (TURBO)
    //	EV_DoFloor(line,turboLower);
    //	line^.special = 0;
    //	break;

    //      case 37:
    //	// LowerAndChange
    //	EV_DoFloor(line,lowerAndChange);
    //	line^.special = 0;
    //	break;

    //      case 38:
    //	// Lower Floor To Lowest
    //	EV_DoFloor( line, lowerFloorToLowest );
    //	line^.special = 0;
    //	break;

    //      case 39:
    //	// TELEPORT!
    //	EV_Teleport( line, side, thing );
    //	line^.special = 0;
    //	break;

    //      case 40:
    //	// RaiseCeilingLowerFloor
    //	EV_DoCeiling( line, raiseToHighest );
    //	EV_DoFloor( line, lowerFloorToLowest );
    //	line^.special = 0;
    //	break;

    //      case 44:
    //	// Ceiling Crush
    //	EV_DoCeiling( line, lowerAndCrush );
    //	line^.special = 0;
    //	break;

    52: Begin
        // EXIT!
        G_ExitLevel();
      End;

    //      case 53:
    //	// Perpetual Platform Raise
    //	EV_DoPlat(line,perpetualRaise,0);
    //	line^.special = 0;
    //	break;
    //
    //      case 54:
    //	// Platform Stop
    //	EV_StopPlat(line);
    //	line^.special = 0;
    //	break;
    //
    //      case 56:
    //	// Raise Floor Crush
    //	EV_DoFloor(line,raiseFloorCrush);
    //	line^.special = 0;
    //	break;
    //
    //      case 57:
    //	// Ceiling Crush Stop
    //	EV_CeilingCrushStop(line);
    //	line^.special = 0;
    //	break;
    //
    //      case 58:
    //	// Raise Floor 24
    //	EV_DoFloor(line,raiseFloor24);
    //	line^.special = 0;
    //	break;
    //
    //      case 59:
    //	// Raise Floor 24 And Change
    //	EV_DoFloor(line,raiseFloor24AndChange);
    //	line^.special = 0;
    //	break;
    //
    //      case 104:
    //	// Turn lights off in sector(tag)
    //	EV_TurnTagLightsOff(line);
    //	line^.special = 0;
    //	break;
    //
    //      case 108:
    //	// Blazing Door Raise (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeRaise);
    //	line^.special = 0;
    //	break;
    //
    //      case 109:
    //	// Blazing Door Open (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeOpen);
    //	line^.special = 0;
    //	break;
    //
    //      case 100:
    //	// Build Stairs Turbo 16
    //	EV_BuildStairs(line,turbo16);
    //	line^.special = 0;
    //	break;
    //
    //      case 110:
    //	// Blazing Door Close (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeClose);
    //	line^.special = 0;
    //	break;
    //
    //      case 119:
    //	// Raise floor to nearest surr. floor
    //	EV_DoFloor(line,raiseFloorToNearest);
    //	line^.special = 0;
    //	break;
    //
    //      case 121:
    //	// Blazing PlatDownWaitUpStay
    //	EV_DoPlat(line,blazeDWUS,0);
    //	line^.special = 0;
    //	break;

    124: Begin
        // Secret EXIT
        G_SecretExitLevel();
      End;

    //      case 125:
    //	// TELEPORT MonsterONLY
    //	if (!thing^.player)
    //	{
    //	    EV_Teleport( line, side, thing );
    //	    line^.special = 0;
    //	}
    //	break;
    //
    //      case 130:
    //	// Raise Floor Turbo
    //	EV_DoFloor(line,raiseFloorTurbo);
    //	line^.special = 0;
    //	break;
    //
    //      case 141:
    //	// Silent Ceiling Crush & Raise
    //	EV_DoCeiling(line,silentCrushAndRaise);
    //	line^.special = 0;
    //	break;
    //
    //	// RETRIGGERS.  All from here till end.
    //      case 72:
    //	// Ceiling Crush
    //	EV_DoCeiling( line, lowerAndCrush );
    //	break;
    //
    //      case 73:
    //	// Ceiling Crush and Raise
    //	EV_DoCeiling(line,crushAndRaise);
    //	break;
    //
    //      case 74:
    //	// Ceiling Crush Stop
    //	EV_CeilingCrushStop(line);
    //	break;
    //
    //      case 75:
    //	// Close Door
    //	EV_DoDoor(line,vld_close);
    //	break;
    //
    //      case 76:
    //	// Close Door 30
    //	EV_DoDoor(line,vld_close30ThenOpen);
    //	break;
    //
    //      case 77:
    //	// Fast Ceiling Crush & Raise
    //	EV_DoCeiling(line,fastCrushAndRaise);
    //	break;
    //
    //      case 79:
    //	// Lights Very Dark
    //	EV_LightTurnOn(line,35);
    //	break;
    //
    //      case 80:
    //	// Light Turn On - brightest near
    //	EV_LightTurnOn(line,0);
    //	break;
    //
    //      case 81:
    //	// Light Turn On 255
    //	EV_LightTurnOn(line,255);
    //	break;
    //
    //      case 82:
    //	// Lower Floor To Lowest
    //	EV_DoFloor( line, lowerFloorToLowest );
    //	break;
    //
    //      case 83:
    //	// Lower Floor
    //	EV_DoFloor(line,lowerFloor);
    //	break;
    //
    //      case 84:
    //	// LowerAndChange
    //	EV_DoFloor(line,lowerAndChange);
    //	break;
    //
    //      case 86:
    //	// Open Door
    //	EV_DoDoor(line,vld_open);
    //	break;
    //
    //      case 87:
    //	// Perpetual Platform Raise
    //	EV_DoPlat(line,perpetualRaise,0);
    //	break;
    //
    //      case 88:
    //	// PlatDownWaitUp
    //	EV_DoPlat(line,downWaitUpStay,0);
    //	break;
    //
    //      case 89:
    //	// Platform Stop
    //	EV_StopPlat(line);
    //	break;
    //
    //      case 90:
    //	// Raise Door
    //	EV_DoDoor(line,vld_normal);
    //	break;
    //
    //      case 91:
    //	// Raise Floor
    //	EV_DoFloor(line,raiseFloor);
    //	break;
    //
    //      case 92:
    //	// Raise Floor 24
    //	EV_DoFloor(line,raiseFloor24);
    //	break;
    //
    //      case 93:
    //	// Raise Floor 24 And Change
    //	EV_DoFloor(line,raiseFloor24AndChange);
    //	break;
    //
    //      case 94:
    //	// Raise Floor Crush
    //	EV_DoFloor(line,raiseFloorCrush);
    //	break;
    //
    //      case 95:
    //	// Raise floor to nearest height
    //	// and change texture.
    //	EV_DoPlat(line,raiseToNearestAndChange,0);
    //	break;
    //
    //      case 96:
    //	// Raise floor to shortest texture height
    //	// on either side of lines.
    //	EV_DoFloor(line,raiseToTexture);
    //	break;
    //
    //      case 97:
    //	// TELEPORT!
    //	EV_Teleport( line, side, thing );
    //	break;
    //
    //      case 98:
    //	// Lower Floor (TURBO)
    //	EV_DoFloor(line,turboLower);
    //	break;
    //
    //      case 105:
    //	// Blazing Door Raise (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeRaise);
    //	break;
    //
    //      case 106:
    //	// Blazing Door Open (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeOpen);
    //	break;
    //
    //      case 107:
    //	// Blazing Door Close (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeClose);
    //	break;
    //
    //      case 120:
    //	// Blazing PlatDownWaitUpStay.
    //	EV_DoPlat(line,blazeDWUS,0);
    //	break;
    //
    //      case 126:
    //	// TELEPORT MonsterONLY.
    //	if (!thing^.player)
    //	    EV_Teleport( line, side, thing );
    //	break;
    //
    //      case 128:
    //	// Raise To Nearest Floor
    //	EV_DoFloor(line,raiseFloorToNearest);
    //	break;
    //
    //      case 129:
    //	// Raise Floor Turbo
    //	EV_DoFloor(line,raiseFloorTurbo);
    //	break;
  Else Begin // TODO: remove, when finishing porting
      // Nicht jeder Index ist oben definiert, alle Nummern die mal kamen aber nicht relevant sind einfach hier eintragen ;)
      If Not line^.special In [48] Then Begin
        Raise exception.create('P_CrossSpecialLinePtr: missing port for: ' + inttostr(line^.special));
      End;
    End; // TODO: remove, when finishing porting -- Ende
  End;
End;

//
// P_CrossSpecialLine - TRIGGER
// Called every time a thing origin is about
//  to cross a line with a non 0 special.
//

Procedure P_CrossSpecialLine(linenum, side: int; thing: Pmobj_t);
Begin
  P_CrossSpecialLinePtr(@lines[linenum], side, thing);
End;

//
// getNextSector()
// Return sector_t * of sector next to current.
// NULL if not two-sided line
//

Function getNextSector(line: Pline_t; sec: Psector_t): Psector_t;
Begin
  If ((line^.flags And ML_TWOSIDED) = 0) Then Begin
    result := Nil;
    exit;
  End;
  If (line^.frontsector = sec) Then Begin
    result := line^.backsector;
  End
  Else Begin
    result := line^.frontsector;
  End;
End;

//
// FIND LOWEST CEILING IN THE SURROUNDING SECTORS
//

Function P_FindLowestCeilingSurrounding(sec: Psector_t): fixed_t;
Var
  i: int;
  check: pline_t;
  other: psector_t;
  height: fixed_t;

Begin
  height := INT_MAX;

  For i := 0 To sec^.linecount - 1 Do Begin
    check := @sec^.lines[i];
    other := getNextSector(check, sec);

    If (other = Nil) Then continue;
    If (other^.ceilingheight < height) Then
      height := other^.ceilingheight;
  End;
  result := height;
End;

End.

