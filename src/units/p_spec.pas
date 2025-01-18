Unit p_spec;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure P_InitPicAnims();

Implementation

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

End.

