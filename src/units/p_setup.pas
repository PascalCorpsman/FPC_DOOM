Unit p_setup;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef, doomdata, info_types
  , d_mode
  ;

Var
  playerstarts: Array[0..MAXPLAYERS - 1] Of mapthing_t;


Function P_GetNumForMap(episode, map: int; critical: boolean): int;

Procedure P_SetupLevel(episode, map, playermask: int; skill: skill_t);

Implementation

Uses
  doomstat
  , d_loop, d_main
  , i_timer
  , g_game
  , m_argv, m_fixed
  , p_tick, p_extnodes
  , s_musinfo, s_sound
  , w_wad
  ;

Const
  skilltable: Array Of String =
  (
    'Nothing',
    'Baby',
    'Easy',
    'Normal',
    'Hard',
    'Nightmare'
    );

Var
  // pointer to the current map lump info struct
  maplumpinfo: ^lumpinfo_t;

  // BLOCKMAP
  // Created from axis aligned bounding box
  // of the map, a rectangular array of
  // blocks of size ...
  // Used to speed up collision detection
  // by spatial subdivision in 2D.
  //
  // Blockmap size.
  bmapwidth: int;
  bmapheight: int; // size in mapblocks
  blockmap: Array Of int32_t; // int for larger maps // [crispy] BLOCKMAP limit
  // offsets in blockmap are from here
  blockmaplump: Array Of int32_t; // [crispy] BLOCKMAP limit
  // origin of block map
  bmaporgx: fixed_t;
  bmaporgy: fixed_t;
  // for thing chains
  blocklinks: Array Of Pmobj_t;

  //
  // P_LoadBlockMap
  //

Function P_LoadBlockMap(lump: int): boolean;
Var
  i, count, lumplen: int;
  wadblockmaplump: Array Of short;
  t: short;
Begin
  result := false;
  // [crispy] (re-)create BLOCKMAP if necessary
  lumplen := W_LumpLength(lump);
  count := lumplen Div 2;
  If (M_CheckParm('-blockmap') <> 0) Or
    (lump >= length(lumpinfo)) Or
    (lumplen < 8) Or
    (count >= $10000) Then exit;

  // [crispy] remove BLOCKMAP limit
  // adapted from boom202s/P_SETUP.C:1025-1076
  wadblockmaplump := Nil;
  setlength(wadblockmaplump, lumplen);
  W_ReadLump(lump, @wadblockmaplump[0]);
  //    blockmaplump = Z_Malloc(sizeof(*blockmaplump) * count, PU_LEVEL, NULL);
  setlength(blockmaplump, count);
  blockmap := pointer(blockmaplump) + 4;

  blockmaplump[0] := wadblockmaplump[0];
  blockmaplump[1] := wadblockmaplump[1];
  blockmaplump[2] := wadblockmaplump[2] And $FFFF;
  blockmaplump[3] := wadblockmaplump[3] And $FFFF;

  // Swap all short integers to native byte ordering.

  For i := 4 To count - 1 Do Begin
    t := wadblockmaplump[i];
    If (t = -1) Then Begin
      blockmaplump[i] := -1;
    End
    Else Begin
      blockmaplump[i] := t And $FFFF;
    End;
  End;

  //  Z_Free(wadblockmaplump);

  // Read the header

  bmaporgx := blockmaplump[0] Shl FRACBITS;
  bmaporgy := blockmaplump[1] Shl FRACBITS;
  bmapwidth := blockmaplump[2];
  bmapheight := blockmaplump[3];

  // Clear out mobj chains

  count := bmapwidth * bmapheight;
  setlength(blocklinks, count);
  For i := 0 To high(blocklinks) Do
    blocklinks[i] := Nil;

  // [crispy] (re-)create BLOCKMAP if necessary
  writeln(stderr, ')');
  result := true;
End;

Function P_GetNumForMap(episode, map: int; critical: boolean): int;
Var
  lumpName: String;
Begin
  // find map name
  If (gamemode = commercial) Then Begin
    If (map < 10) Then Begin
      lumpname := 'map0' + inttostr(map);
    End
    Else Begin
      lumpname := 'map' + inttostr(map);
    End;
  End
  Else Begin
    lumpName := format('E%dM%d', [episode, map]);
  End;

  // [crispy] special-casing for E1M10 "Sewers" support
//      if (crispy->havee1m10 && episode == 1 && map == 10)
//      {
//  	DEH_snprintf(lumpname, 9, "E1M10");
//      }

  // [crispy] NRFTL / The Master Levels
//    if (crispy->havenerve && episode == 2 && map <= 9)
//    {
//	strcat(lumpname, "N");
//    }
//    if (crispy->havemaster && episode == 3 && map <= 21)
//    {
//	strcat(lumpname, "M");
//    }
  If critical Then Begin
    result := W_GetNumForName(lumpname);
  End
  Else Begin
    result := W_CheckNumForName(lumpname);
  End;
End;

Procedure P_SetupLevel(episode, map, playermask: int; skill: skill_t);
Var
  lumpnum, i: Int;
  rfn_str, lumpname: String;
  ltime, ttime: int;
  crispy_mapformat: mapformat_t;
  crispy_validblockmap: Boolean;
Begin
  totalkills := 0;
  totalitems := 0;
  totalsecret := 0;
  wminfo.maxfrags := 0;

  // [crispy] count spawned monsters
  extrakills := 0;
  wminfo.partime := 180;
  For i := 0 To MAXPLAYERS - 1 Do Begin
    players[i].killcount := 0;
    players[i].secretcount := 0;
    players[i].itemcount := 0;
  End;

  // [crispy] NRFTL / The Master Levels
//    if (crispy->havenerve || crispy->havemaster)
//    {
//        if (crispy->havemaster && episode == 3)
//        {
//            gamemission = pack_master;
//        }
//        else
//        if (crispy->havenerve && episode == 2)
//        {
//            gamemission = pack_nerve;
//        }
//        else
//        {
//            gamemission = doom2;
//        }
//    }
//    else
  Begin
    If (gamemission = pack_master) Then Begin
      episode := 3;
      gameepisode := 3;
    End
    Else If (gamemission = pack_nerve) Then Begin
      episode := 2;
      gameepisode := 2;
    End;
  End;

  // Initial height of PointOfView
  // will be set by player think.
  players[consoleplayer].viewz := 1;

  // [crispy] stop demo warp mode now
//    if (crispy->demowarp == map)
//    {
//	crispy->demowarp = 0;
//	nodrawers = false;
//	singletics = false;
//    }

    // [crispy] don't load map's default music if loaded from a savegame with MUSINFO data
  If (Not musinfo.from_savegame) Then Begin

    // Make sure all sounds are stopped before Z_FreeTags.
    S_Start();
  End;
  musinfo.from_savegame := false;

  //    Z_FreeTags (PU_LEVEL, PU_PURGELEVEL-1); --> Sagt dem SpeicherManager er soll alles Platt machen was er bisher zu "Levels" geladen hat ...

  // UNUSED W_Profile ();
  P_InitThinkers();

  // if working with a devlopment map, reload it
  W_Reload();

  // [crispy] factor out map lump name and number finding into a separate function
(*
      // find map name
      if ( gamemode == commercial)
      {
   if (map<10)
       DEH_snprintf(lumpname, 9, "map0%i", map);
   else
       DEH_snprintf(lumpname, 9, "map%i", map);
      }
      else
      {
   lumpname[0] = 'E';
   lumpname[1] = '0' + episode;
   lumpname[2] = 'M';
   lumpname[3] = '0' + map;
   lumpname[4] = 0;
      }

      lumpnum = W_GetNumForName (lumpname);
  *)
  lumpnum := P_GetNumForMap(episode, map, true);

  maplumpinfo := @lumpinfo[lumpnum];
  lumpname := lumpinfo[lumpnum].name;


  leveltime := 0;
  oldleveltime := 0;

  // [crispy] better logging
  Begin

    ltime := savedleveltime Div TICRATE;
    ttime := (totalleveltimes + savedleveltime) Div TICRATE;
    rfn_str :=
      IfThen(respawnparm, ' -respawn', '') +
      IfThen(fastparm, ' -fast', '') +
      IfThen(nomonsters, ' -nomonsters', '');

    write(stderr,
      format('P_SetupLevel: %s (%s) %s%s %d:%0.2d:%0.2d/%d:%0.2d:%0.2d ',
      [maplumpinfo^.name, W_WadNameForLump(maplumpinfo^),
      skilltable[integer(skill) + 1], rfn_str,
        ltime Div 3600, (ltime Mod 3600) Div 60, ltime Mod 60,
        ttime Div 3600, (ttime Mod 3600) Div 60, ttime Mod 60]));
  End;
  // [crispy] check and log map and nodes format
  crispy_mapformat := P_CheckMapFormat(lumpnum);

  // note: most of this ordering is important
  crispy_validblockmap := P_LoadBlockMap(lumpnum + ML_BLOCKMAP); // [crispy] (re-)create BLOCKMAP if necessary

  hier weiter

  //    P_LoadVertexes (lumpnum+ML_VERTEXES);
  //    P_LoadSectors (lumpnum+ML_SECTORS);
  //    P_LoadSideDefs (lumpnum+ML_SIDEDEFS);
  //
  //    if (crispy_mapformat & MFMT_HEXEN)
  //	P_LoadLineDefs_Hexen (lumpnum+ML_LINEDEFS);
  //    else
  //    P_LoadLineDefs (lumpnum+ML_LINEDEFS);
  //    // [crispy] (re-)create BLOCKMAP if necessary
  //    if (!crispy_validblockmap)
  //    {
  //	extern void P_CreateBlockMap (void);
  //	P_CreateBlockMap();
  //    }
  //    if (crispy_mapformat & (MFMT_ZDBSPX | MFMT_ZDBSPZ))
  //	P_LoadNodes_ZDBSP (lumpnum+ML_NODES, crispy_mapformat & MFMT_ZDBSPZ);
  //    else
  //    if (crispy_mapformat & MFMT_DEEPBSP)
  //    {
  //	P_LoadSubsectors_DeePBSP (lumpnum+ML_SSECTORS);
  //	P_LoadNodes_DeePBSP (lumpnum+ML_NODES);
  //	P_LoadSegs_DeePBSP (lumpnum+ML_SEGS);
  //    }
  //    else
  //    {
  //    P_LoadSubsectors (lumpnum+ML_SSECTORS);
  //    P_LoadNodes (lumpnum+ML_NODES);
  //    P_LoadSegs (lumpnum+ML_SEGS);
  //    }
  //
  //    P_GroupLines ();
  //    P_LoadReject (lumpnum+ML_REJECT);
  //
  //    // [crispy] remove slime trails
  //    P_RemoveSlimeTrails();
  //    // [crispy] fix long wall wobble
  //    P_SegLengths(false);
  //    // [crispy] blinking key or skull in the status bar
  //    memset(st_keyorskull, 0, sizeof(st_keyorskull));
  //
  //    bodyqueslot = 0;
  //    deathmatch_p = deathmatchstarts;
  //    if (crispy_mapformat & MFMT_HEXEN)
  //	P_LoadThings_Hexen (lumpnum+ML_THINGS);
  //    else
  //    P_LoadThings (lumpnum+ML_THINGS);
  //
  //    // if deathmatch, randomly spawn the active players
  //    if (deathmatch)
  //    {
  //	for (i=0 ; i<MAXPLAYERS ; i++)
  //	    if (playeringame[i])
  //	    {
  //		players[i].mo = NULL;
  //		G_DeathMatchSpawnPlayer (i);
  //	    }
  //
  //    }
  //    // [crispy] support MUSINFO lump (dynamic music changing)
  //    if (gamemode != shareware)
  //    {
  //	S_ParseMusInfo(lumpname);
  //    }
  //
  //    // clear special respawning que
  //    iquehead = iquetail = 0;
  //
  //    // set up world state
  //    P_SpawnSpecials ();
  //
  //    // build subsector connect matrix
  //    //	UNUSED P_ConnectSubsectors ();
  //
  //    // preload graphics
  //    if (precache)
  //	R_PrecacheLevel ();

    //printf ("free memory: 0x%x\n", Z_FreeMemory());

End;

End.

