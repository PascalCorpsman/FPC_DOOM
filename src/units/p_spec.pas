Unit p_spec;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  info_types
  ;

Procedure P_InitPicAnims();
Procedure P_SpawnSpecials();
Procedure R_InterpolateTextureOffsets();
Procedure P_PlayerInSpecialSector(player: Pplayer_t);
Procedure P_UpdateSpecials();

Procedure P_ShootSpecialLine(thing: Pmobj_t; line: pline_t);

Implementation

Uses
  d_loop
  , p_tick
  , r_draw
  ;

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
//sector_t*	sector;
// int		i;

Begin
  // See if -TIMER was specified.

//    if (timelimit > 0 && deathmatch)
//    {
//        levelTimer = true;
//        levelTimeCount = timelimit * 60 * TICRATE;
//    }
//    else
//    {
//	levelTimer = false;
//    }
//
//    //	Init special SECTORs.
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
Begin
  //  anim_t*	anim;
  //    int		pic;
  //    int		i;
  //    line_t*	line;
  //
  //
  //    //	LEVEL TIMER
  //    if (levelTimer == true)
  //    {
  //	levelTimeCount--;
  //	if (!levelTimeCount)
  //	    G_ExitLevel();
  //    }
  //
  //    //	ANIMATE FLATS AND TEXTURES GLOBALLY
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
  //
  //
  //    //	ANIMATE LINE SPECIALS
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
  //
  //
  //    //	DO BUTTONS
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
  //
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
Begin
  raise exception.create('P_ShootSpecialLine');
  //      int		ok;
  //
  //    //	Impacts that other things can activate.
  //    if (!thing->player)
  //    {
  //	ok = 0;
  //	switch(line->special)
  //	{
  //	  case 46:
  //	    // OPEN DOOR IMPACT
  //	    ok = 1;
  //	    break;
  //	}
  //	if (!ok)
  //	    return;
  //    }
  //
  //    switch(line->special)
  //    {
  //      case 24:
  //	// RAISE FLOOR
  //	EV_DoFloor(line,raiseFloor);
  //	P_ChangeSwitchTexture(line,0);
  //	break;
  //
  //      case 46:
  //	// OPEN DOOR
  //	EV_DoDoor(line,vld_open);
  //	P_ChangeSwitchTexture(line,1);
  //	break;
  //
  //      case 47:
  //	// RAISE FLOOR NEAR AND CHANGE
  //	EV_DoPlat(line,raiseToNearestAndChange,0);
  //	P_ChangeSwitchTexture(line,0);
  //	break;
  //    }
End;

End.

