Unit p_spec;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure P_InitPicAnims();
Procedure P_SpawnSpecials();
Procedure R_InterpolateTextureOffsets();

Implementation

Uses
  d_loop
  , p_tick
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

End.

