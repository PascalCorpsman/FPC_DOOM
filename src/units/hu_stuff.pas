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
Procedure HU_Start();
Procedure HU_Erase();

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

Procedure HU_Start();
Begin
  //   int		i;
  //    const char *s;
  //    // [crispy] string buffers for map title and WAD file name
  //    char	buf[8], *ptr;
  //
  //    if (headsupactive)
  //	HU_Stop();
  //
  //    plr = &players[displayplayer];
  //    message_on = false;
  //    message_dontfuckwithme = false;
  //    message_nottobefuckedwith = false;
  //    secret_on = false;
  //    chat_on = false;
  //
  //    // [crispy] re-calculate WIDESCREENDELTA
  //    I_GetScreenDimensions();
  //    hu_widescreendelta = WIDESCREENDELTA;
  //
  //    // create the message widget
  //    HUlib_initSText(&w_message,
  //		    HU_MSGX, HU_MSGY, HU_MSGHEIGHT,
  //		    hu_font,
  //		    HU_FONTSTART, &message_on);
  //
  //    // [crispy] create the secret message widget
  //    HUlib_initSText(&w_secret,
  //		    88, 86, HU_MSGHEIGHT,
  //		    hu_font,
  //		    HU_FONTSTART, &secret_on);
  //
  //    // create the map title widget
  //    HUlib_initTextLine(&w_title,
  //		       HU_TITLEX, HU_TITLEY,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    // [crispy] create the generic map title, kills, items, secrets and level time widgets
  //    HUlib_initTextLine(&w_map,
  //		       HU_TITLEX, HU_TITLEY - SHORT(hu_font[0]->height + 1),
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    HUlib_initTextLine(&w_kills,
  //		       HU_TITLEX, HU_MSGY + 1 * 8,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    HUlib_initTextLine(&w_items,
  //		       HU_TITLEX, HU_MSGY + 2 * 8,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    HUlib_initTextLine(&w_scrts,
  //		       HU_TITLEX, HU_MSGY + 3 * 8,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    HUlib_initTextLine(&w_ltime,
  //		       HU_TITLEX, HU_MSGY + 4 * 8,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    HUlib_initTextLine(&w_coordx,
  //		       HU_COORDX, HU_MSGY + 1 * 8,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    HUlib_initTextLine(&w_coordy,
  //		       HU_COORDX, HU_MSGY + 2 * 8,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    HUlib_initTextLine(&w_coorda,
  //		       HU_COORDX, HU_MSGY + 3 * 8,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //    HUlib_initTextLine(&w_fps,
  //		       HU_COORDX, HU_MSGY,
  //		       hu_font,
  //		       HU_FONTSTART);
  //
  //
  //    switch ( logical_gamemission )
  //    {
  //      case doom:
  //	s = HU_TITLE;
  //	break;
  //      case doom2:
  //	 s = HU_TITLE2;
  //         // Pre-Final Doom compatibility: map33-map35 names don't spill over
  //         if (gameversion <= exe_doom_1_9 && gamemap >= 33 && false) // [crispy] disable
  //         {
  //             s = "";
  //         }
  //	 break;
  //      case pack_plut:
  //	s = HU_TITLEP;
  //	break;
  //      case pack_tnt:
  //	s = HU_TITLET;
  //	break;
  //      case pack_nerve:
  //	if (gamemap <= 9)
  //	  s = HU_TITLEN;
  //	else
  //	  s = HU_TITLE2;
  //	break;
  //      case pack_master:
  //	if (gamemap <= 21)
  //	  s = HU_TITLEM;
  //	else
  //	  s = HU_TITLE2;
  //	break;
  //      default:
  //         s = "Unknown level";
  //         break;
  //    }
  //
  //    if (logical_gamemission == doom && gameversion == exe_chex)
  //    {
  //        s = HU_TITLE_CHEX;
  //    }
  //
  //    // [crispy] display names of single special levels in Automap
  //    HU_SetSpecialLevelName(W_WadNameForLump(maplumpinfo), &s);
  //
  //    // [crispy] explicitely display (episode and) map if the
  //    // map is from a PWAD or if the map title string has been dehacked
  //    if (!W_IsIWADLump(maplumpinfo) &&
  //        (DEH_HasStringReplacement(s) ||
  //        (!(crispy->havenerve && gamemission == pack_nerve) &&
  //        !(crispy->havemaster && gamemission == pack_master))))
  //    {
  //	char *m;
  //
  //	ptr = M_StringJoin(crstr[CR_GOLD], W_WadNameForLump(maplumpinfo), ": ", crstr[CR_GRAY], maplumpinfo->name, NULL);
  //	m = ptr;
  //
  //	while (*m)
  //	    HUlib_addCharToTextLine(&w_map, *(m++));
  //
  //	free(ptr);
  //    }
  //
  //    // dehacked substitution to get modified level name
  //
  //    s = DEH_String(s);
  //
  //    // [crispy] print the map title in white from the first colon onward
  //    M_snprintf(buf, sizeof(buf), "%s%s", ":", crstr[CR_GRAY]);
  //    ptr = M_StringReplace(s, ":", buf);
  //    s = ptr;
  //
  //    while (*s)
  //	HUlib_addCharToTextLine(&w_title, *(s++));
  //
  //    free(ptr);
  //
  //    // create the chat widget
  //    HUlib_initIText(&w_chat,
  //		    HU_INPUTX, HU_INPUTY,
  //		    hu_font,
  //		    HU_FONTSTART, &chat_on);
  //
  //    // create the inputbuffer widgets
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //	HUlib_initIText(&w_inputbuffer[i], 0, 0, 0, 0, &always_off);
  //
  //    headsupactive = true;
End;

Procedure HU_Erase();
Begin
  //    HUlib_eraseSText(&w_message);
  //    HUlib_eraseSText(&w_secret);
  //    HUlib_eraseIText(&w_chat);
  //    HUlib_eraseTextLine(&w_title);
  //    HUlib_eraseTextLine(&w_kills);
  //    HUlib_eraseTextLine(&w_items);
  //    HUlib_eraseTextLine(&w_scrts);
  //    HUlib_eraseTextLine(&w_ltime);
  //    HUlib_eraseTextLine(&w_coordx);
  //    HUlib_eraseTextLine(&w_coordy);
  //    HUlib_eraseTextLine(&w_coorda);
  //    HUlib_eraseTextLine(&w_fps);
End;

End.

