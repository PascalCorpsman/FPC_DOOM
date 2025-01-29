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
Procedure HU_Ticker();

Implementation

Uses
  doomstat
  , d_mode
  , m_argv
  , r_things
  , w_wad
  , z_zone;

Procedure HU_Init();
Var
  i, j: int;
  buffer: String;
  patch: ^patch_t;
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
  For i := 0 To high(laserpatch) Do Begin

    // [crispy] check for alternative crosshair patches from e.g. prboom-plus.wad first
   //	if ((laserpatch[i].l = W_CheckNumForName(laserpatch[i].a)) == -1)
    Begin
      //		DEH_snprintf(buffer, 9, "STCFN%.3d", toupper(laserpatch[i].c));
      buffer := format('STCFN%0.3d', [ord(UpperCase(laserpatch[i].c)[1])]);
      laserpatch[i].l := W_GetNumForName(buffer);

      patch := W_CacheLumpNum(laserpatch[i].l, PU_STATIC);

      laserpatch[i].w := laserpatch[i].w - patch^.leftoffset;
      laserpatch[i].h := laserpatch[i].h - patch^.topoffset;

      // [crispy] special-case the chevron crosshair type
      If (laserpatch[i].c = '^') Then Begin
        laserpatch[i].h := laserpatch[i].h - patch^.height Div 2;
      End;
    End;

    laserpatch[i].w := laserpatch[i].w + patch^.width Div 2;
    laserpatch[i].h := laserpatch[i].h + patch^.height Div 2;
  End;

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

Procedure HU_Ticker();
Begin
  //    int i, rc;
  //    char c;
  //    char str[32], *s;
  //
  //    // tick down message counter if message is up
  //    if (message_counter && !--message_counter)
  //    {
  //	message_on = false;
  //	message_nottobefuckedwith = false;
  //	crispy->screenshotmsg >>= 1;
  //    }
  //
  //    if (secret_counter && !--secret_counter)
  //    {
  //	secret_on = false;
  //    }
  //
  //    if (showMessages || message_dontfuckwithme)
  //    {
  //
  //	// [crispy] display centered message
  //	if (plr->centermessage)
  //	{
  //	    extern int M_StringWidth(const char *string);
  //	    w_secret.l[0].x = ORIGWIDTH/2 - M_StringWidth(plr->centermessage)/2;
  //
  //	    HUlib_addMessageToSText(&w_secret, 0, plr->centermessage);
  //	    plr->centermessage = 0;
  //	    secret_on = true;
  //	    secret_counter = 5*TICRATE/2; // [crispy] 2.5 seconds
  //	}
  //
  //	// display message if necessary
  //	if ((plr->message && !message_nottobefuckedwith)
  //	    || (plr->message && message_dontfuckwithme))
  //	{
  //	    HUlib_addMessageToSText(&w_message, 0, plr->message);
  //	    plr->message = 0;
  //	    message_on = true;
  //	    message_counter = HU_MSGTIMEOUT;
  //	    message_nottobefuckedwith = message_dontfuckwithme;
  //	    message_dontfuckwithme = 0;
  //	    crispy->screenshotmsg >>= 1;
  //	}
  //
  //    } // else message_on = false;
  //
  //    w_kills.y = HU_MSGY + 1 * 8;
  //
  //    // check for incoming chat characters
  //    if (netgame)
  //    {
  //	for (i=0 ; i<MAXPLAYERS; i++)
  //	{
  //	    if (!playeringame[i])
  //		continue;
  //	    if (i != consoleplayer
  //		&& (c = players[i].cmd.chatchar))
  //	    {
  //		if (c <= HU_BROADCAST)
  //		    chat_dest[i] = c;
  //		else
  //		{
  //		    rc = HUlib_keyInIText(&w_inputbuffer[i], c);
  //		    if (rc && c == KEY_ENTER)
  //		    {
  //			if (w_inputbuffer[i].l.len
  //			    && (chat_dest[i] == consoleplayer+1
  //				|| chat_dest[i] == HU_BROADCAST))
  //			{
  //			    HUlib_addMessageToSText(&w_message,
  //						    DEH_String(player_names[i]),
  //						    w_inputbuffer[i].l.l);
  //
  //			    message_nottobefuckedwith = true;
  //			    message_on = true;
  //			    message_counter = HU_MSGTIMEOUT;
  //			    if ( gamemode == commercial )
  //			      S_StartSound(0, sfx_radio);
  //			    else if (gameversion > exe_doom_1_2)
  //			      S_StartSound(0, sfx_tink);
  //			}
  //			HUlib_resetIText(&w_inputbuffer[i]);
  //		    }
  //		}
  //		players[i].cmd.chatchar = 0;
  //	    }
  //	}
  //    // [crispy] shift widgets one line down so chat typing line may appear
  //    if (crispy->automapstats != WIDGETS_STBAR)
  //    {
  //        const int chat_line = chat_on ? 8 : 0;
  //
  //        w_kills.y = HU_MSGY + 1 * 8 + chat_line;
  //        w_items.y = HU_MSGY + 2 * 8 + chat_line;
  //        w_scrts.y = HU_MSGY + 3 * 8 + chat_line;
  //        // [crispy] do not shift level time widget if no stats widget is used
  //        w_ltime.y = HU_MSGY + 4 * 8 + (crispy->automapstats ? chat_line : 0);
  //        w_coordx.y = HU_MSGY + 1 * 8 + chat_line;
  //        w_coordy.y = HU_MSGY + 2 * 8 + chat_line;
  //        w_coorda.y = HU_MSGY + 3 * 8 + chat_line;
  //    }
  //    }
  //
  //    if (automapactive)
  //    {
  //	// [crispy] move map title to the bottom
  //	if (crispy->automapoverlay && screenblocks >= CRISPY_HUD - 1)
  //	    w_title.y = HU_TITLEY + ST_HEIGHT;
  //	else
  //	    w_title.y = HU_TITLEY;
  //    }
  //
  //    if (crispy->automapstats == WIDGETS_STBAR && (!automapactive || w_title.y != HU_TITLEY))
  //    {
  //	crispy_statsline_func_t crispy_statsline = crispy_statslines[crispy->statsformat];
  //
  //	w_kills.x = - ST_WIDESCREENDELTA;
  //
  //	w_kills.y = HU_TITLEY;
  //
  //	crispy_statsline(str, sizeof(str), "K ", plr->killcount, totalkills, extrakills);
  //	HUlib_clearTextLine(&w_kills);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_kills, *(s++));
  //
  //	crispy_statsline(str, sizeof(str), "I ", plr->itemcount, totalitems, 0);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_kills, *(s++));
  //
  //	crispy_statsline(str, sizeof(str), "S ", plr->secretcount, totalsecret, 0);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_kills, *(s++));
  //    }
  //    else
  //    if ((crispy->automapstats & WIDGETS_ALWAYS) || (automapactive && crispy->automapstats == WIDGETS_AUTOMAP))
  //    {
  //
  //	crispy_statsline_func_t crispy_statsline = crispy_statslines[crispy->statsformat];
  //
  //	w_kills.x = HU_TITLEX; // to handle switching from Status bar to Always and Automap kills line options
  //
  //	crispy_statsline(str, sizeof(str), kills, plr->killcount, totalkills, extrakills);
  //	HUlib_clearTextLine(&w_kills);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_kills, *(s++));
  //
  //	crispy_statsline(str, sizeof(str), "I\t", plr->itemcount, totalitems, 0);
  //	HUlib_clearTextLine(&w_items);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_items, *(s++));
  //
  //	crispy_statsline(str, sizeof(str), "S\t", plr->secretcount, totalsecret, 0);
  //	HUlib_clearTextLine(&w_scrts);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_scrts, *(s++));
  //    }
  //
  //    if (crispy->leveltime == WIDGETS_ALWAYS || (automapactive && crispy->leveltime == WIDGETS_AUTOMAP))
  //    {
  //	const int time = leveltime / TICRATE;
  //
  //	if (time >= 3600)
  //	    M_snprintf(str, sizeof(str), "%s%02d:%02d:%02d", crstr[CR_GRAY],
  //	            time/3600, (time%3600)/60, time%60);
  //	else
  //	    M_snprintf(str, sizeof(str), "%s%02d:%02d", crstr[CR_GRAY],
  //	            time/60, time%60);
  //	HUlib_clearTextLine(&w_ltime);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_ltime, *(s++));
  //    }
  //
  //    // [crispy] "use" button timer overrides the level time widget
  //    if (crispy->btusetimer && plr->btuse_tics)
  //    {
  //	const int mins = plr->btuse / (60 * TICRATE);
  //	const float secs = (float)(plr->btuse % (60 * TICRATE)) / TICRATE;
  //
  //	plr->btuse_tics--;
  //
  //	M_snprintf(str, sizeof(str), "%sU\t%02i:%05.02f", crstr[CR_GRAY], mins, secs);
  //	HUlib_clearTextLine(&w_ltime);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_ltime, *(s++));
  //    }
  //
  //    if (crispy->playercoords == WIDGETS_ALWAYS || (automapactive && crispy->playercoords == WIDGETS_AUTOMAP))
  //    {
  //	M_snprintf(str, sizeof(str), "%sX\t%s%-5d", cr_stat2, crstr[CR_GRAY],
  //	        (plr->mo->x)>>FRACBITS);
  //	HUlib_clearTextLine(&w_coordx);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_coordx, *(s++));
  //
  //	M_snprintf(str, sizeof(str), "%sY\t%s%-5d", cr_stat2, crstr[CR_GRAY],
  //	        (plr->mo->y)>>FRACBITS);
  //	HUlib_clearTextLine(&w_coordy);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_coordy, *(s++));
  //
  //	M_snprintf(str, sizeof(str), "%sA\t%s%-5d", cr_stat2, crstr[CR_GRAY],
  //	        (plr->mo->angle)/ANG1);
  //	HUlib_clearTextLine(&w_coorda);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_coorda, *(s++));
  //    }
  //
  //    if (plr->powers[pw_showfps])
  //    {
  //	M_snprintf(str, sizeof(str), "%s%-4d %sFPS", crstr[CR_GRAY], crispy->fps, cr_stat2);
  //	HUlib_clearTextLine(&w_fps);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_fps, *(s++));
  //    }
End;

End.

