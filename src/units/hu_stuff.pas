Unit hu_stuff;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_event
  , hu_lib
  , i_timer
  , v_patch
  ;

Const
  HU_FONTSTART = '!'; // the first font characters
  HU_FONTEND = '_'; // the last font characters

  // Calculate # of glyphs in font.
  HU_FONTSIZE = (ord(HU_FONTEND) - ord(HU_FONTSTART) + 1);

  HU_MSGTIMEOUT = (4 * TICRATE);

Var
  hu_font: Array[0..HU_FONTSIZE - 1] Of Ppatch_t;
  w_title: hu_textline_t;

Procedure HU_Init();
Procedure HU_Start();
Procedure HU_Erase();
Procedure HU_Ticker();
Procedure HU_Drawer();
Function HU_Responder(Const ev: Pevent_t): boolean;

Implementation

Uses
  doomstat, info_types
  , am_map
  , d_mode, d_englsh
  , g_game
  , i_video
  , m_argv, m_menu
  , p_setup
  , r_things
  , st_stuff
  , v_video, v_trans
  , w_wad
  , z_zone;

Const
  HU_MSGY = 0;
  HU_MSGWIDTH = 64; // in characters
  HU_MSGHEIGHT = 1; // in lines

  //
  // Builtin map names.
  // The actual names can be found in DStrings.h.
  //

  mapnames: Array Of String = // DOOM shareware/registered/retail (Ultimate) names.
  (
    HUSTR_E1M1,
    HUSTR_E1M2,
    HUSTR_E1M3,
    HUSTR_E1M4,
    HUSTR_E1M5,
    HUSTR_E1M6,
    HUSTR_E1M7,
    HUSTR_E1M8,
    HUSTR_E1M9,

    HUSTR_E2M1,
    HUSTR_E2M2,
    HUSTR_E2M3,
    HUSTR_E2M4,
    HUSTR_E2M5,
    HUSTR_E2M6,
    HUSTR_E2M7,
    HUSTR_E2M8,
    HUSTR_E2M9,

    HUSTR_E3M1,
    HUSTR_E3M2,
    HUSTR_E3M3,
    HUSTR_E3M4,
    HUSTR_E3M5,
    HUSTR_E3M6,
    HUSTR_E3M7,
    HUSTR_E3M8,
    HUSTR_E3M9,

    HUSTR_E4M1,
    HUSTR_E4M2,
    HUSTR_E4M3,
    HUSTR_E4M4,
    HUSTR_E4M5,
    HUSTR_E4M6,
    HUSTR_E4M7,
    HUSTR_E4M8,
    HUSTR_E4M9,

    // [crispy] Sigil
    HUSTR_E5M1,
    HUSTR_E5M2,
    HUSTR_E5M3,
    HUSTR_E5M4,
    HUSTR_E5M5,
    HUSTR_E5M6,
    HUSTR_E5M7,
    HUSTR_E5M8,
    HUSTR_E5M9,

    // [crispy] Sigil II
    HUSTR_E6M1,
    HUSTR_E6M2,
    HUSTR_E6M3,
    HUSTR_E6M4,
    HUSTR_E6M5,
    HUSTR_E6M6,
    HUSTR_E6M7,
    HUSTR_E6M8,
    HUSTR_E6M9,

    'NEWLEVEL',
    'NEWLEVEL',
    'NEWLEVEL',
    'NEWLEVEL',
    'NEWLEVEL',
    'NEWLEVEL',
    'NEWLEVEL',
    'NEWLEVEL',
    'NEWLEVEL'
    );

  // List of names for levels in commercial IWADs
  // (doom2.wad, plutonia.wad, tnt.wad).  These are stored in a
  // single large array; WADs like pl2.wad have a MAP33, and rely on
  // the layout in the Vanilla executable, where it is possible to
  // overflow the end of one array into the next.

  mapnames_commercial: Array Of String =
  (
    // DOOM 2 map names.

    HUSTR_1,
    HUSTR_2,
    HUSTR_3,
    HUSTR_4,
    HUSTR_5,
    HUSTR_6,
    HUSTR_7,
    HUSTR_8,
    HUSTR_9,
    HUSTR_10,
    HUSTR_11,

    HUSTR_12,
    HUSTR_13,
    HUSTR_14,
    HUSTR_15,
    HUSTR_16,
    HUSTR_17,
    HUSTR_18,
    HUSTR_19,
    HUSTR_20,

    HUSTR_21,
    HUSTR_22,
    HUSTR_23,
    HUSTR_24,
    HUSTR_25,
    HUSTR_26,
    HUSTR_27,
    HUSTR_28,
    HUSTR_29,
    HUSTR_30,
    HUSTR_31,
    HUSTR_32,

    // Plutonia WAD map names.

    PHUSTR_1,
    PHUSTR_2,
    PHUSTR_3,
    PHUSTR_4,
    PHUSTR_5,
    PHUSTR_6,
    PHUSTR_7,
    PHUSTR_8,
    PHUSTR_9,
    PHUSTR_10,
    PHUSTR_11,

    PHUSTR_12,
    PHUSTR_13,
    PHUSTR_14,
    PHUSTR_15,
    PHUSTR_16,
    PHUSTR_17,
    PHUSTR_18,
    PHUSTR_19,
    PHUSTR_20,

    PHUSTR_21,
    PHUSTR_22,
    PHUSTR_23,
    PHUSTR_24,
    PHUSTR_25,
    PHUSTR_26,
    PHUSTR_27,
    PHUSTR_28,
    PHUSTR_29,
    PHUSTR_30,
    PHUSTR_31,
    PHUSTR_32,

    // TNT WAD map names.

    THUSTR_1,
    THUSTR_2,
    THUSTR_3,
    THUSTR_4,
    THUSTR_5,
    THUSTR_6,
    THUSTR_7,
    THUSTR_8,
    THUSTR_9,
    THUSTR_10,
    THUSTR_11,

    THUSTR_12,
    THUSTR_13,
    THUSTR_14,
    THUSTR_15,
    THUSTR_16,
    THUSTR_17,
    THUSTR_18,
    THUSTR_19,
    THUSTR_20,

    THUSTR_21,
    THUSTR_22,
    THUSTR_23,
    THUSTR_24,
    THUSTR_25,
    THUSTR_26,
    THUSTR_27,
    THUSTR_28,
    THUSTR_29,
    THUSTR_30,
    THUSTR_31,
    THUSTR_32,

    // Emulation: TNT maps 33-35 can be warped to and played if they exist
    // so include blank names instead of spilling over
    '',
    '',
    ''
    ,
    NHUSTR_1,
    NHUSTR_2,
    NHUSTR_3,
    NHUSTR_4,
    NHUSTR_5,
    NHUSTR_6,
    NHUSTR_7,
    NHUSTR_8,
    NHUSTR_9,

    MHUSTR_1,
    MHUSTR_2,
    MHUSTR_3,
    MHUSTR_4,
    MHUSTR_5,
    MHUSTR_6,
    MHUSTR_7,
    MHUSTR_8,
    MHUSTR_9,
    MHUSTR_10,
    MHUSTR_11,
    MHUSTR_12,
    MHUSTR_13,
    MHUSTR_14,
    MHUSTR_15,
    MHUSTR_16,
    MHUSTR_17,
    MHUSTR_18,
    MHUSTR_19,
    MHUSTR_20,
    MHUSTR_21
    );


Var
  plr: ^player_t;

  //static hu_textline_t	w_map;
  //static hu_textline_t	w_kills;
  //static hu_textline_t	w_items;
  //static hu_textline_t	w_scrts;
  //static hu_textline_t	w_ltime;
  //static hu_textline_t	w_coordx;
  //static hu_textline_t	w_coordy;
  //static hu_textline_t	w_coorda;
  //static hu_textline_t	w_fps;

  chat_on: boolean;
  //  static hu_itext_t	w_chat;
  //  static boolean		always_off = false;
  //  static char		chat_dest[MAXPLAYERS];
  //  static hu_itext_t w_inputbuffer[MAXPLAYERS];

  message_on: boolean;
  message_dontfuckwithme: boolean;
  message_nottobefuckedwith: boolean;
  secret_on: Boolean;

  w_message: hu_stext_t;
  message_counter: int;
  //  static hu_stext_t	w_secret;
  //  static int		secret_counter;

  headsupactive: boolean = false;

Function HU_TITLE(): String;
Var
  index: integer;
Begin
  index := (gameepisode - 1) * 9 + gamemap - 1;
  If index >= 0 Then Begin
    result := (mapnames[index]);
  End
  Else Begin
    result := '';
  End;
End;

Function HU_TITLE2(): String;
Begin
  result := '';
  If gamemap > 0 Then Begin
    result := (mapnames_commercial[gamemap - 1]);
  End;
End;

Function HU_TITLEX(): int;
Begin
  result := (0 - WIDESCREENDELTA);
End;

Function HU_TITLEY(): int;
Begin
  result := (SCREENHEIGHT - (ST_HEIGHT Shl Crispy.hires) - (hu_font[0]^.height) - 1);
End;

Function HU_MSGX(): int;
Begin
  result := (0 - WIDESCREENDELTA);
End;

Procedure HU_SetSpecialLevelName(wad: String; Var name: String);
Begin
  //    int i;
  //
  //    for (i = 0; i < arrlen(speciallevels); i++)
  //    {
  //	const speciallevel_t speciallevel = speciallevels[i];
  //
  //	if (logical_gamemission == speciallevel.mission &&
  //	    (!speciallevel.episode || gameepisode == speciallevel.episode) &&
  //	    gamemap == speciallevel.map &&
  //	    (!speciallevel.wad || !strcasecmp(wad, speciallevel.wad)))
  //	{
  //	    *name = speciallevel.name ? speciallevel.name : maplumpinfo->name;
  //	    break;
  //	}
  //    }
End;

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

Procedure HU_Stop();
Begin

End;

Procedure HU_Start();
Var
  i: int;
  s: String;
Begin
  //    // [crispy] string buffers for map title and WAD file name
  //    char	buf[8], *ptr;

  If (headsupactive) Then HU_Stop();

  plr := @players[displayplayer];
  message_on := false;
  message_dontfuckwithme := false;
  message_nottobefuckedwith := false;
  secret_on := false;
  chat_on := false;

  // [crispy] re-calculate WIDESCREENDELTA
  I_GetScreenDimensions();
  //    hu_widescreendelta = WIDESCREENDELTA;

  // create the message widget
  HUlib_initSText(@w_message,
    HU_MSGX, HU_MSGY, HU_MSGHEIGHT,
    hu_font,
    ord(HU_FONTSTART), @message_on);

  // [crispy] create the secret message widget
//    HUlib_initSText(&w_secret,
//		    88, 86, HU_MSGHEIGHT,
//		    hu_font,
//		    HU_FONTSTART, &secret_on);

  // create the map title widget
  HUlib_initTextLine(@w_title,
    HU_TITLEX, HU_TITLEY,
    hu_font,
    ord(HU_FONTSTART));

  // [crispy] create the generic map title, kills, items, secrets and level time widgets
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

  Case (logical_gamemission()) Of
    doom: s := HU_TITLE;
    doom2: Begin
        s := HU_TITLE2;
        // Pre-Final Doom compatibility: map33-map35 names don't spill over
        If (gameversion <= exe_doom_1_9) And (gamemap >= 33) And (false) Then Begin // [crispy] disable
          s := '';
        End;
      End;
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
  Else Begin
      s := 'Unknown level';
    End;
  End;

  //    if (logical_gamemission == doom && gameversion == exe_chex)
  //    {
  //        s = HU_TITLE_CHEX;
  //    }

  // [crispy] display names of single special levels in Automap
  HU_SetSpecialLevelName(W_WadNameForLump(maplumpinfo^), s);

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
  // dehacked substitution to get modified level name

  // [crispy] print the map title in white from the first colon onward
  s := StringReplace(s, ':', ':' + crstr[CR_GRAY], []);

  For i := 1 To length(s) Do Begin
    HUlib_addCharToTextLine(@w_title, s[i]);
  End;

  // create the chat widget
//    HUlib_initIText(&w_chat,
//		    HU_INPUTX, HU_INPUTY,
//		    hu_font,
//		    HU_FONTSTART, &chat_on);

  // create the inputbuffer widgets
//    for (i=0 ; i<MAXPLAYERS ; i++)
//	HUlib_initIText(&w_inputbuffer[i], 0, 0, 0, 0, &always_off);

  headsupactive := true;
End;

Procedure HU_Erase();
Begin
  HUlib_eraseSText(@w_message);
  //    HUlib_eraseSText(&w_secret);
  //    HUlib_eraseIText(&w_chat);
  HUlib_eraseTextLine(@w_title);
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
//    int i, rc;
//    char c;
//    char str[32], *s;
Begin

  // tick down message counter if message is up
  If (message_counter <> 0) Then Begin
    message_counter := message_counter - 1;
    If message_counter = 0 Then Begin
      message_on := false;
      message_nottobefuckedwith := false;
      crispy.screenshotmsg := crispy.screenshotmsg Shr 1;
    End;
  End;

  //    if (secret_counter && !--secret_counter)
  //    {
  //	secret_on = false;
  //    }

  If (showMessages <> 0) Or message_dontfuckwithme Then Begin

    // [crispy] display centered message
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

   // display message if necessary
    If ((plr^.message <> '') And (Not message_nottobefuckedwith))
      Or ((plr^.message <> '') And (message_dontfuckwithme)) Then Begin
      HUlib_addMessageToSText(@w_message, '', plr^.message);
      plr^.message := '';
      message_on := true;
      message_counter := HU_MSGTIMEOUT;
      message_nottobefuckedwith := message_dontfuckwithme;
      message_dontfuckwithme := false;
      crispy.screenshotmsg := crispy.screenshotmsg Shr 1;
    End;
  End; // else message_on = false;

  //    w_kills.y = HU_MSGY + 1 * 8;

  // check for incoming chat characters
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

  If (automapactive) Then Begin
    // [crispy] move map title to the bottom
    If (crispy.automapoverlay <> 0) And (screenblocks >= CRISPY_HUD - 1) Then
      w_title.y := HU_TITLEY + ST_HEIGHT Shl Crispy.hires
    Else
      w_title.y := HU_TITLEY;
  End;

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

  //    if (crispy->playercoords == WIDGETS_ALWAYS || (automapactive && crispy->playercoords == WIDGETS_AUTOMAP))
  //    {
  //	M_snprintf(str, sizeof(str), "%sX\t%s%-5d", cr_stat2, crstr[CR_GRAY],
  //	        (plr->mo->x)>>FRACBITS);
  //	HUlib_clearTextLine(&w_coordx);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_coordx, *(s++));

  //	M_snprintf(str, sizeof(str), "%sY\t%s%-5d", cr_stat2, crstr[CR_GRAY],
  //	        (plr->mo->y)>>FRACBITS);
  //	HUlib_clearTextLine(&w_coordy);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_coordy, *(s++));

  //	M_snprintf(str, sizeof(str), "%sA\t%s%-5d", cr_stat2, crstr[CR_GRAY],
  //	        (plr->mo->angle)/ANG1);
  //	HUlib_clearTextLine(&w_coorda);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_coorda, *(s++));
  //    }

  //    if (plr->powers[pw_showfps])
  //    {
  //	M_snprintf(str, sizeof(str), "%s%-4d %sFPS", crstr[CR_GRAY], crispy->fps, cr_stat2);
  //	HUlib_clearTextLine(&w_fps);
  //	s = str;
  //	while (*s)
  //	    HUlib_addCharToTextLine(&w_fps, *(s++));
  //    }
End;

Procedure HU_Drawer();
Begin
  If (crispy.cleanscreenshot <> 0) Then Begin
    HU_Erase();
    exit;
  End;

  // [crispy] re-calculate widget coordinates on demand
//    if (hu_widescreendelta != WIDESCREENDELTA)
//    {
//        HU_Start();
//    }

  // [crispy] translucent messages for translucent HUD
//    if (screenblocks >= CRISPY_HUD && (screenblocks % 3 == 2) && (!automapactive || crispy->automapoverlay))
//	dp_translucent = true;

//    if (secret_on && !menuactive)
//    {
//	dp_translation = cr[CR_GOLD];
//	HUlib_drawSText(&w_secret);
//    }

  dp_translation := Nil;
  If (crispy.screenshotmsg = 4) Then
    HUlib_eraseSText(@w_message)
  Else
    HUlib_drawSText(@w_message);
  //    HUlib_drawIText(&w_chat);

  //    if (crispy->coloredhud & COLOREDHUD_TEXT)
  //	dp_translation = cr[CR_GOLD];

  If (automapactive) Then Begin
    HUlib_drawTextLine(@w_title, false);
  End;

  //    if (crispy->automapstats == WIDGETS_STBAR && (!automapactive || w_title.y != HU_TITLEY))
  //    {
  //	HUlib_drawTextLine(&w_kills, false);
  //    }
  //    else
  //    if ((crispy->automapstats & WIDGETS_ALWAYS) || (automapactive && crispy->automapstats == WIDGETS_AUTOMAP))
  //    {
  //	// [crispy] move obtrusive line out of player view
  //	if (automapactive && (!crispy->automapoverlay || screenblocks < CRISPY_HUD - 1))
  //	    HUlib_drawTextLine(&w_map, false);
  //
  //	HUlib_drawTextLine(&w_kills, false);
  //	HUlib_drawTextLine(&w_items, false);
  //	HUlib_drawTextLine(&w_scrts, false);
  //    }
  //
  //    if (crispy->leveltime == WIDGETS_ALWAYS || (automapactive && crispy->leveltime == WIDGETS_AUTOMAP) ||
  //        (crispy->btusetimer && plr->btuse_tics))
  //    {
  //	HUlib_drawTextLine(&w_ltime, false);
  //    }
  //
  //    if (crispy->playercoords == WIDGETS_ALWAYS || (automapactive && crispy->playercoords == WIDGETS_AUTOMAP))
  //    {
  //	HUlib_drawTextLine(&w_coordx, false);
  //	HUlib_drawTextLine(&w_coordy, false);
  //	HUlib_drawTextLine(&w_coorda, false);
  //    }
  //
  //    if (plr->powers[pw_showfps])
  //    {
  //	HUlib_drawTextLine(&w_fps, false);
  //    }
  //
  //    if (crispy->crosshair == CROSSHAIR_STATIC)
  //	HU_DrawCrosshair();
  //
  //    dp_translation = NULL;
  //    dp_translucent = false;
  //
  //    // [crispy] demo timer widget
  //    if (demoplayback && (crispy->demotimer & DEMOTIMER_PLAYBACK))
  //    {
  //	ST_DrawDemoTimer(crispy->demotimerdir ? (deftotaldemotics - defdemotics) : defdemotics);
  //    }
  //    else
  //    if (demorecording && (crispy->demotimer & DEMOTIMER_RECORD))
  //    {
  //	ST_DrawDemoTimer(leveltime);
  //    }
  //
  //    // [crispy] demo progress bar
  //    if (demoplayback && crispy->demobar)
  //    {
  //	HU_DemoProgressBar();
  //    }
End;

Function HU_Responder(Const ev: Pevent_t): boolean;
//   static char		lastmessage[HU_MAXLINELENGTH+1];
//    static int		num_nobrainers = 0;
//    static boolean	altdown = false;

//    const char		*macromessage;
//    unsigned char 	c;
//    int			i;
//    int			numplayers;

Var
  eatkey: boolean;

Begin
  eatkey := false;

  //    numplayers = 0;
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //	numplayers += playeringame[i];
  //
  //    if (ev->data1 == KEY_RSHIFT)
  //    {
  //	return false;
  //    }
  //    else if (ev->data1 == KEY_RALT || ev->data1 == KEY_LALT)
  //    {
  //	altdown = ev->type == ev_keydown;
  //	return false;
  //    }
  //
  //    if (ev->type != ev_keydown)
  //	return false;
  //
  //    if (!chat_on)
  //    {
  //	if (ev->data1 == key_message_refresh)
  //	{
  //	    message_on = true;
  //	    message_counter = HU_MSGTIMEOUT;
  //	    eatkey = true;
  //	}
  //	else if (netgame && !demoplayback && ev->data2 == key_multi_msg)
  //	{
  //	    eatkey = true;
  //            StartChatInput(HU_BROADCAST);
  //	}
  //	else if (netgame && !demoplayback && numplayers > 2)
  //	{
  //	    for (i=0; i<MAXPLAYERS ; i++)
  //	    {
  //		if (ev->data2 == key_multi_msgplayer[i])
  //		{
  //		    if (playeringame[i] && i!=consoleplayer)
  //		    {
  //			eatkey = true;
  //                        StartChatInput(i + 1);
  //			break;
  //		    }
  //		    else if (i == consoleplayer)
  //		    {
  //			num_nobrainers++;
  //			if (num_nobrainers < 3)
  //			    plr->message = DEH_String(HUSTR_TALKTOSELF1);
  //			else if (num_nobrainers < 6)
  //			    plr->message = DEH_String(HUSTR_TALKTOSELF2);
  //			else if (num_nobrainers < 9)
  //			    plr->message = DEH_String(HUSTR_TALKTOSELF3);
  //			else if (num_nobrainers < 32)
  //			    plr->message = DEH_String(HUSTR_TALKTOSELF4);
  //			else
  //			    plr->message = DEH_String(HUSTR_TALKTOSELF5);
  //		    }
  //		}
  //	    }
  //	}
  //    }
  //    else
  //    {
  //	// send a macro
  //	if (altdown)
  //	{
  //	    c = ev->data1 - '0';
  //	    if (c > 9)
  //		return false;
  //	    // fprintf(stderr, "got here\n");
  //	    macromessage = chat_macros[c];
  //
  //	    // kill last message with a '\n'
  //	    HU_queueChatChar(KEY_ENTER); // DEBUG!!!
  //
  //	    // send the macro message
  //	    while (*macromessage)
  //		HU_queueChatChar(*macromessage++);
  //	    HU_queueChatChar(KEY_ENTER);
  //
  //            // leave chat mode and notify that it was sent
  //            StopChatInput();
  //            M_StringCopy(lastmessage, chat_macros[c], sizeof(lastmessage));
  //            plr->message = lastmessage;
  //            eatkey = true;
  //	}
  //	else
  //	{
  //            c = ev->data3;
  //
  //	    eatkey = HUlib_keyInIText(&w_chat, c);
  //	    if (eatkey)
  //	    {
  //		// static unsigned char buf[20]; // DEBUG
  //		HU_queueChatChar(c);
  //
  //		// M_snprintf(buf, sizeof(buf), "KEY: %d => %d", ev->data1, c);
  //		//        plr->message = buf;
  //	    }
  //	    if (c == KEY_ENTER)
  //	    {
  //		StopChatInput();
  //                if (w_chat.l.len)
  //                {
  //                    M_StringCopy(lastmessage, w_chat.l.l, sizeof(lastmessage));
  //                    plr->message = lastmessage;
  //                }
  //	    }
  //	    else if (c == KEY_ESCAPE)
  //	    {
  //                StopChatInput();
  //            }
  //	}
  //    }

  result := eatkey;
End;

End.

