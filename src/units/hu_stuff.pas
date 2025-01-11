Unit hu_stuff;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, v_patch;

Const
  HU_FONTSTART = '!'; // the first font characters
  HU_FONTEND = '_'; // the last font characters

  // Calculate # of glyphs in font.
  HU_FONTSIZE = (ord(HU_FONTEND) - ord(HU_FONTSTART) + 1);

Var
  hu_font: Array[0..HU_FONTSIZE - 1] Of Ppatch_t;

Procedure HU_Init();

Implementation

Uses
  doomstat
  , d_mode
  , m_argv
  , w_wad
  , z_zone;

Procedure HU_Init();
Var
  i, j: int;
  buffer: String;
Begin
  // load the heads-up font
  j := ord(HU_FONTSTART);

  For i := 0 To HU_FONTSIZE - 1 Do Begin
    buffer := format('STCFN%0.3d', [j]);
    j := j + 1;
    hu_font[i] := W_CacheLumpName(buffer, PU_STATIC);
  End;

  If (gameversion = exe_chex) Then Begin
    //	cr_stat = crstr[CR_GREEN];
    //	cr_stat2 = crstr[CR_GOLD];
    //	kills = "F\t";
  End
  Else Begin
    If (gameversion = exe_hacx) Then Begin
      //		cr_stat = crstr[CR_BLUE];
    End
    Else Begin
      //		cr_stat = crstr[CR_RED];
    End;
    //	cr_stat2 = crstr[CR_GREEN];
    //	kills = "K\t";
  End;

  // [crispy] initialize the crosshair types

  //    for (i = 0; laserpatch[i].c; i++)
  //    {
  //	patch_t *patch = NULL;
  //
  //	// [crispy] check for alternative crosshair patches from e.g. prboom-plus.wad first
  ////	if ((laserpatch[i].l = W_CheckNumForName(laserpatch[i].a)) == -1)
  //	{
  //		DEH_snprintf(buffer, 9, "STCFN%.3d", toupper(laserpatch[i].c));
  //		laserpatch[i].l = W_GetNumForName(buffer);
  //
  //		patch = W_CacheLumpNum(laserpatch[i].l, PU_STATIC);
  //
  //		laserpatch[i].w -= SHORT(patch->leftoffset);
  //		laserpatch[i].h -= SHORT(patch->topoffset);
  //
  //		// [crispy] special-case the chevron crosshair type
  //		if (toupper(laserpatch[i].c) == '^')
  //		{
  //			laserpatch[i].h -= SHORT(patch->height)/2;
  //		}
  //	}
  //
  //	if (!patch)
  //	{
  //		patch = W_CacheLumpNum(laserpatch[i].l, PU_STATIC);
  //	}
  //
  //	laserpatch[i].w += SHORT(patch->width)/2;
  //	laserpatch[i].h += SHORT(patch->height)/2;
  //    }

  If (Not M_ParmExists('-nodeh')) Then Begin

    // [crispy] colorize keycard and skull key messages
    //	CrispyReplaceColor(GOTBLUECARD, CR_BLUE, " blue ");
    //	CrispyReplaceColor(GOTBLUESKUL, CR_BLUE, " blue ");
    //	CrispyReplaceColor(PD_BLUEO,    CR_BLUE, " blue ");
    //	CrispyReplaceColor(PD_BLUEK,    CR_BLUE, " blue ");
    //	CrispyReplaceColor(GOTREDCARD,  CR_RED,  " red ");
    //	CrispyReplaceColor(GOTREDSKULL, CR_RED,  " red ");
    //	CrispyReplaceColor(PD_REDO,     CR_RED,  " red ");
    //	CrispyReplaceColor(PD_REDK,     CR_RED,  " red ");
    //	CrispyReplaceColor(GOTYELWCARD, CR_GOLD, " yellow ");
    //	CrispyReplaceColor(GOTYELWSKUL, CR_GOLD, " yellow ");
    //	CrispyReplaceColor(PD_YELLOWO,  CR_GOLD, " yellow ");
    //	CrispyReplaceColor(PD_YELLOWK,  CR_GOLD, " yellow ");

    // [crispy] colorize multi-player messages
    //	CrispyReplaceColor(HUSTR_PLRGREEN,  CR_GREEN, "Green: ");
    //	CrispyReplaceColor(HUSTR_PLRINDIGO, CR_GRAY,  "Indigo: ");
    //	CrispyReplaceColor(HUSTR_PLRBROWN,  CR_GOLD,  "Brown: ");
    //	CrispyReplaceColor(HUSTR_PLRRED,    CR_RED,   "Red: ");
  End;
End;

End.

