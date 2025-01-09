Unit d_main;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure D_DoomMain(); // Init und alles was geladen werden muss
Procedure D_DoomLoop(); // Main Loop -> Rendert die Frames

Implementation

Uses
  config
  , doom_icon, doomstat
  , d_iwad, d_mode, d_englsh
  , g_game
  , i_system, i_video, i_timer, i_sound
  , m_misc, m_config, m_argv, m_menu
  , r_main
  , v_video
  , w_wad, w_main
  , z_zone
  ;

Var
  gamedescription: String = '';

  // location of IWAD and WAD files

  iwadfile: String = '';

  devparm: Boolean; // started game with -devparm
  nomonsters: boolean; // checkparm of -nomonsters
  respawnparm: boolean; // checkparm of -respawn
  fastparm: boolean; // checkparm of -fast

  startskill: skill_t;
  startepisode: int;
  startmap: int;
  autostart: Boolean;

Function D_AddFile(filename: String): boolean;
Begin
  writeln(format(' adding %s', [filename]));
  result := W_AddFile(filename);
End;

Procedure D_BindVariables();
Begin
  //    int i;
  //
  //    M_ApplyPlatformDefaults();
  //
  //    I_BindInputVariables();
  //    I_BindVideoVariables();
  //    I_BindJoystickVariables();
  //    I_BindSoundVariables();
  //
  //    M_BindBaseControls();
  //    M_BindWeaponControls();
  //    M_BindMapControls();
  //    M_BindMenuControls();
  //    M_BindChatControls(MAXPLAYERS);
  //
  //    key_multi_msgplayer[0] = HUSTR_KEYGREEN;
  //    key_multi_msgplayer[1] = HUSTR_KEYINDIGO;
  //    key_multi_msgplayer[2] = HUSTR_KEYBROWN;
  //    key_multi_msgplayer[3] = HUSTR_KEYRED;
  //
  //    NET_BindVariables();
  //
  //    M_BindIntVariable("mouse_sensitivity",      &mouseSensitivity);
  //    M_BindIntVariable("mouse_sensitivity_x2",   &mouseSensitivity_x2); // [crispy]
  //    M_BindIntVariable("mouse_sensitivity_y",    &mouseSensitivity_y); // [crispy]
  //    M_BindIntVariable("sfx_volume",             &sfxVolume);
  //    M_BindIntVariable("music_volume",           &musicVolume);
  //    M_BindIntVariable("show_messages",          &showMessages);
  //    M_BindIntVariable("screenblocks",           &screenblocks);
  //    M_BindIntVariable("detaillevel",            &detailLevel);
  //    M_BindIntVariable("snd_channels",           &snd_channels);
  //    // [crispy] unconditionally disable savegame and demo limits
  ////  M_BindIntVariable("vanilla_savegame_limit", &vanilla_savegame_limit);
  ////  M_BindIntVariable("vanilla_demo_limit",     &vanilla_demo_limit);
  //    M_BindIntVariable("a11y_sector_lighting",   &a11y_sector_lighting);
  //    M_BindIntVariable("a11y_extra_lighting",    &a11y_extra_lighting);
  //    M_BindIntVariable("a11y_weapon_flash",      &a11y_weapon_flash);
  //    M_BindIntVariable("a11y_weapon_pspr",       &a11y_weapon_pspr);
  //    M_BindIntVariable("a11y_palette_changes",   &a11y_palette_changes);
  //    M_BindIntVariable("a11y_invul_colormap",    &a11y_invul_colormap);
  //    M_BindIntVariable("show_endoom",            &show_endoom);
  //    M_BindIntVariable("show_diskicon",          &show_diskicon);
  //
  //    // Multiplayer chat macros
  //
  //    for (i=0; i<10; ++i)
  //    {
  //        char buf[12];
  //
  //        chat_macros[i] = M_StringDuplicate(chat_macro_defaults[i]);
  //        M_snprintf(buf, sizeof(buf), "chatmacro%i", i);
  //        M_BindStringVariable(buf, &chat_macros[i]);
  //    }
  //
  //    // [crispy] bind "crispness" config variables
  //    M_BindIntVariable("crispy_automapoverlay",  &crispy->automapoverlay);
  //    M_BindIntVariable("crispy_automaprotate",   &crispy->automaprotate);
  //    M_BindIntVariable("crispy_automapstats",    &crispy->automapstats);
  //    M_BindIntVariable("crispy_bobfactor",       &crispy->bobfactor);
  //    M_BindIntVariable("crispy_btusetimer",      &crispy->btusetimer);
  //    M_BindIntVariable("crispy_brightmaps",      &crispy->brightmaps);
  //    M_BindIntVariable("crispy_centerweapon",    &crispy->centerweapon);
  //    M_BindIntVariable("crispy_coloredblood",    &crispy->coloredblood);
  //    M_BindIntVariable("crispy_coloredhud",      &crispy->coloredhud);
  //    M_BindIntVariable("crispy_crosshair",       &crispy->crosshair);
  //    M_BindIntVariable("crispy_crosshairhealth", &crispy->crosshairhealth);
  //    M_BindIntVariable("crispy_crosshairtarget", &crispy->crosshairtarget);
  //    M_BindIntVariable("crispy_crosshairtype",   &crispy->crosshairtype);
  //    M_BindIntVariable("crispy_defaultskill",    &crispy->defaultskill);
  //    M_BindIntVariable("crispy_demobar",         &crispy->demobar);
  //    M_BindIntVariable("crispy_demotimer",       &crispy->demotimer);
  //    M_BindIntVariable("crispy_demotimerdir",    &crispy->demotimerdir);
  //    M_BindIntVariable("crispy_extautomap",      &crispy->extautomap);
  //    M_BindIntVariable("crispy_flipcorpses",     &crispy->flipcorpses);
  //    M_BindIntVariable("crispy_fpslimit",        &crispy->fpslimit);
  //    M_BindIntVariable("crispy_freeaim",         &crispy->freeaim);
  //    M_BindIntVariable("crispy_freelook",        &crispy->freelook);
  //    M_BindIntVariable("crispy_gamma",           &crispy->gamma);
  //    M_BindIntVariable("crispy_hires",           &crispy->hires);
  //    M_BindIntVariable("crispy_jump",            &crispy->jump);
  //    M_BindIntVariable("crispy_leveltime",       &crispy->leveltime);
  //    M_BindIntVariable("crispy_mouselook",       &crispy->mouselook);
  //    M_BindIntVariable("crispy_neghealth",       &crispy->neghealth);
  //    M_BindIntVariable("crispy_overunder",       &crispy->overunder);
  //    M_BindIntVariable("crispy_pitch",           &crispy->pitch);
  //    M_BindIntVariable("crispy_playercoords",    &crispy->playercoords);
  //    M_BindIntVariable("crispy_secretmessage",   &crispy->secretmessage);
  //    M_BindIntVariable("crispy_smoothlight",     &crispy->smoothlight);
  //    M_BindIntVariable("crispy_smoothmap",       &crispy->smoothmap);
  //    M_BindIntVariable("crispy_smoothscaling",   &crispy->smoothscaling);
  //    M_BindIntVariable("crispy_soundfix",        &crispy->soundfix);
  //    M_BindIntVariable("crispy_soundfull",       &crispy->soundfull);
  //    M_BindIntVariable("crispy_soundmono",       &crispy->soundmono);
  //    M_BindIntVariable("crispy_statsformat",     &crispy->statsformat);
  //    M_BindIntVariable("crispy_translucency",    &crispy->translucency);
  //#ifdef CRISPY_TRUECOLOR
  //    M_BindIntVariable("crispy_truecolor",       &crispy->truecolor);
  //#endif
  //    M_BindIntVariable("crispy_uncapped",        &crispy->uncapped);
  //    M_BindIntVariable("crispy_vsync",           &crispy->vsync);
  //    M_BindIntVariable("crispy_widescreen",      &crispy->widescreen);
End;

//
// Get game name: if the startup banner has been replaced, use that.
// Otherwise, use the name given
//

Function GetGameName(Const gamename: String): String;
Begin
  //    size_t i;

  //    for (i=0; i<arrlen(banners); ++i)
  //    {
  //        const char *deh_sub;
  //        // Has the banner been replaced?
  //
  //        deh_sub = DEH_String(banners[i]);
  //
  //        if (deh_sub != banners[i])
  //        {
  //            size_t gamename_size;
  //            int version;
  //            char *deh_gamename;
  //
  //            // Has been replaced.
  //            // We need to expand via printf to include the Doom version number
  //            // We also need to cut off spaces to get the basic name
  //
  //            gamename_size = strlen(deh_sub) + 10;
  //            deh_gamename = malloc(gamename_size);
  //            if (deh_gamename == NULL)
  //            {
  //                I_Error("GetGameName: Failed to allocate new string");
  //            }
  //            version = G_VanillaVersionCode();
  //            DEH_snprintf(deh_gamename, gamename_size, banners[i],
  //                         version / 100, version % 100);
  //
  //            while (deh_gamename[0] != '\0' && isspace(deh_gamename[0]))
  //            {
  //                memmove(deh_gamename, deh_gamename + 1, gamename_size - 1);
  //            }
  //
  //            while (deh_gamename[0] != '\0' && isspace(deh_gamename[strlen(deh_gamename)-1]))
  //            {
  //                deh_gamename[strlen(deh_gamename) - 1] = '\0';
  //            }
  //
  //            return deh_gamename;
  //        }
  //    }

  result := M_StringDuplicate(gamename);
End;

Procedure D_SetGameDescription();
Begin
  If (logical_gamemission() = doom) Then Begin
    // Doom 1.  But which version?
    If (gamevariant = freedoom) Then Begin
      gamedescription := GetGameName('Freedoom: Phase 1');
    End
    Else If (gamemode = retail) Then Begin
      // Ultimate Doom
      gamedescription := GetGameName('The Ultimate DOOM');
    End
    Else If (gamemode = registered) Then Begin
      gamedescription := GetGameName('DOOM Registered');
    End
    Else If (gamemode = shareware) Then Begin
      gamedescription := GetGameName('DOOM Shareware');
    End;
  End
  Else Begin
    // Doom 2 of some kind.  But which mission?
    If (gamevariant = freedm) Then Begin
      gamedescription := GetGameName('FreeDM');
    End
    Else If (gamevariant = freedoom) Then Begin
      gamedescription := GetGameName('Freedoom: Phase 2');
    End
    Else If (logical_gamemission = doom2) Then Begin
      gamedescription := GetGameName('DOOM 2: Hell On Earth');
    End
    Else If (logical_gamemission = pack_plut) Then Begin
      gamedescription := GetGameName('DOOM 2: Plutonia Experiment');
    End
    Else If (logical_gamemission = pack_tnt) Then Begin
      gamedescription := GetGameName('DOOM 2: TNT - Evilution');
    End
    Else If (logical_gamemission = pack_nerve) Then Begin
      gamedescription := GetGameName('DOOM 2: No Rest For The Living');
    End
    Else If (logical_gamemission = pack_master) Then Begin
      gamedescription := GetGameName('Master Levels for DOOM 2');
    End;
  End;

  If gamedescription = '' Then Begin
    gamedescription := M_StringDuplicate('Unknown');
  End;
End;

// Initialize the game version

Procedure InitGameVersion();
Var
  i, p: int;
  demolumpname: String;
  demolump: ^Byte;
  demoversion: int;
  status: Boolean;
Begin

  //!
  // @arg <version>
  // @category compat
  //
  // Emulate a specific version of Doom. Valid values are "1.2",
  // "1.5", "1.666", "1.7", "1.8", "1.9", "ultimate", "final",
  // "final2", "hacx" and "chex".
  //

  p := M_CheckParmWithArgs('-gameversion', 1);

  If (p <> 0) Then Begin
    //        for (i=0; gameversions[i].description != NULL; ++i)
    //        {
    //            if (!strcmp(myargv[p+1], gameversions[i].cmdline))
    //            {
    //                gameversion = gameversions[i].version;
    //                break;
    //            }
    //        }
    //
    //        if (gameversions[i].description == NULL)
    //        {
    //            printf("Supported game versions:\n");
    //
    //            for (i=0; gameversions[i].description != NULL; ++i)
    //            {
    //                printf("\t%s (%s)\n", gameversions[i].cmdline,
    //                        gameversions[i].description);
    //            }
    //
    //            I_Error("Unknown game version '%s'", myargv[p+1]);
    //        }
  End
  Else Begin
    // Determine automatically

    If (gamemission = pack_chex) Then Begin

      // chex.exe - identified by iwad filename

      gameversion := exe_chex;
    End
    Else If (gamemission = pack_hacx)
      Then Begin
      // hacx.exe: identified by iwad filename

      gameversion := exe_hacx;
    End
    Else If (gamemode = shareware) Or (gamemode = registered)
      Or ((gamemode = commercial) And (gamemission = doom2)) Then Begin
      // original
      gameversion := exe_doom_1_9;

      // Detect version from demo lump
      For i := 1 To 3 Do Begin
        demolumpname := 'demo' + inttostr(i);

        If (W_CheckNumForName(demolumpname) > 0) Then Begin

          demolump := W_CacheLumpName(demolumpname, PU_STATIC);
          demoversion := demolump[0];
          status := true;

          Case (demoversion) Of
            0, 1, 2, 3, 4: gameversion := exe_doom_1_2;
            106: gameversion := exe_doom_1_666;
            107: gameversion := exe_doom_1_7;
            108: gameversion := exe_doom_1_8;
            109: gameversion := exe_doom_1_9;
          Else
            status := false;
          End;
          If (status) Then break;
        End;
      End;
    End
    Else If (gamemode = retail)
      Then Begin
      gameversion := exe_ultimate;
    End
    Else If (gamemode = commercial)
      Then Begin
      // Final Doom: tnt or plutonia
      // Defaults to emulating the first Final Doom executable,
      // which has the crash in the demo loop; however, having
      // this as the default should mean that it plays back
      // most demos correctly.

      gameversion := exe_final;
    End;
  End;

  // Deathmatch 2.0 did not exist until Doom v1.4
  If (gameversion <= exe_doom_1_2) And (deathmatch = 2) Then Begin

    deathmatch := 1;
  End;

  // The original exe does not support retail - 4th episode not supported

  If (gameversion < exe_ultimate) And (gamemode = retail) Then Begin
    gamemode := registered;
  End;

  // EXEs prior to the Final Doom exes do not support Final Doom.

  If (gameversion < exe_final) And (gamemode = commercial)
    And ((gamemission = pack_tnt) Or (gamemission = pack_plut))
    Then Begin
    gamemission := doom2;
  End;
End;

//
// Find out what version of Doom is playing.
//

Procedure D_IdentifyVersion();
Var
  p: int;
Begin
  // gamemission is set up by the D_FindIWAD function.  But if
  // we specify '-iwad', we have to identify using
  // IdentifyIWADByName.  However, if the iwad does not match
  // any known IWAD name, we may have a dilemma.  Try to
  // identify by its contents.

  If (gamemission = none) Then Begin
    Raise exception.create('D_IdentifyVersion');
    //        unsigned int i;
    //
    //        for (i=0; i<numlumps; ++i)
    //        {
    //            if (!strncasecmp(lumpinfo[i]->name, "MAP01", 8))
    //            {
    //                gamemission = doom2;
    //                break;
    //            }
    //            else if (!strncasecmp(lumpinfo[i]->name, "E1M1", 8))
    //            {
    //                gamemission = doom;
    //                break;
    //            }
    //        }
    //
    //        if (gamemission == none)
    //        {
    //            // Still no idea.  I don't think this is going to work.
    //
    //            I_Error("Unknown or invalid IWAD file.");
    //        }
  End;

  // Make sure gamemode is set up correctly

  If (logical_gamemission = doom) Then Begin
    // Doom 1.  But which version?
    If (W_CheckNumForName('E4M1') > 0) Then Begin
      // Ultimate Doom
      gamemode := retail;
    End
    Else If (W_CheckNumForName('E3M1') > 0) Then Begin
      gamemode := registered;
    End
    Else Begin
      gamemode := shareware;
    End;
  End
  Else Begin
    // Doom 2 of some kind.
    gamemode := commercial;

    // We can manually override the gamemission that we got from the
    // IWAD detection code. This allows us to eg. play Plutonia 2
    // with Freedoom and get the right level names.

    //!
    // @category compat
    // @arg <pack>
    //
    // Explicitly specify a Doom II "mission pack" to run as, instead of
    // detecting it based on the filename. Valid values are: "doom2",
    // "tnt" and "plutonia".
    //
    p := M_CheckParmWithArgs('-pack', 1);
    If (p > 0) Then Begin
      Raise exception.create('Missing porting.');
      // SetMissionForPackName(myargv[p + 1]);
    End;
  End;
End;

//
//  D_RunFrame
//

Procedure D_RunFrame();
Begin
  //    int nowtime;
  //    int tics;
  //    static int wipestart;
  //    static boolean wipe;
  //    static int oldgametic;
  //
  //    if (wipe)
  //    {
  //        do
  //        {
  //            nowtime = I_GetTime ();
  //            tics = nowtime - wipestart;
  //            I_Sleep(1);
  //        } while (tics <= 0);
  //
  //        wipestart = nowtime;
  //        wipe = !wipe_ScreenWipe(wipe_Melt
  //                               , 0, 0, SCREENWIDTH, SCREENHEIGHT, tics);
  //        I_UpdateNoBlit ();
  //        M_Drawer ();                            // menu is drawn even on top of wipes
  //        I_FinishUpdate ();                      // page flip or blit buffer
  //        return;
  //    }
  //
  //    // frame syncronous IO operations
  //    I_StartFrame ();
  //
  //    TryRunTics (); // will run at least one tic
  //
  //    if (oldgametic < gametic)
  //    {
  //        S_UpdateSounds (players[displayplayer].mo);// move positional sounds
  //        oldgametic = gametic;
  //    }
  //
  //    // Update display, next frame, with current state if no profiling is on
  //    if (screenvisible && !nodrawers)
  //    {
  //        if ((wipe = D_Display ()))
  //        {
  //            // start wipe on this frame
  //            wipe_EndScreen(0, 0, SCREENWIDTH, SCREENHEIGHT);
  //
  //            wipestart = I_GetTime () - 1;
  //        } else {
  //            // normal update
  //            I_FinishUpdate ();              // page flip or blit buffer
  //        }
  //    }
  //
  //	// [crispy] post-rendering function pointer to apply config changes
  //	// that affect rendering and that are better applied after the current
  //	// frame has finished rendering
  //	if (crispy->post_rendering_hook && !wipe)
  //	{
  //		crispy->post_rendering_hook();
  //		crispy->post_rendering_hook = NULL;
  //	}
End;

Procedure D_DoomLoop();
Begin
  //
  //     while (1)
  //     {
  D_RunFrame();
  //     }
End;

Procedure D_DoomMain();
Var
  p: int;
Begin
  //    char file[256];
  //    char demolumpname[9] = {0};

  //    // [crispy] unconditionally initialize DEH tables
  //    DEH_Init();

  //    I_AtExit(D_Endoom, false);

  // print banner

  I_PrintBanner(PACKAGE_STRING);



  //    DEH_printf("Z_Init: Init zone memory allocation daemon. \n");
  //    Z_Init ();

  //!
  // @category net
  //
  // Start a dedicated server, routing packets but not participating
  // in the game itself.
  //

  If (M_CheckParm('-dedicated') > 0) Then Begin
    writeln('Dedicated server mode.');

    // NET_DedicatedServer();

    // Never returns
    exit;
  End;

  //!
  // @category net
  //
  // Query the Internet master server for a global list of active
  // servers.
  //

  If (M_CheckParm('-search') <> 0) Then Begin

    //        NET_MasterQuery();
    exit;
  End;

  //!
  // @arg <address>
  // @category net
  //
  // Query the status of the server running on the given IP
  // address.
  //

  p := M_CheckParmWithArgs('-query', 1);

  If (p <> 0) Then Begin

    //        NET_QueryAddress(myargv[p+1]);
    exit;
  End;

  //!
  // @category net
  //
  // Search the local LAN for running servers.
  //

  If (M_CheckParm('-localsearch') <> 0) Then Begin

    //        NET_LANQuery();
    exit;
  End;

  //!
  // @category game
  // @vanilla
  //
  // Disable monsters.
  //

  nomonsters := M_CheckParm('-nomonsters') <> 0;

  //!
  // @category game
  // @vanilla
  //
  // Monsters respawn after being killed.
  //

  respawnparm := M_CheckParm('-respawn') <> 0;

  //!
  // @category game
  // @vanilla
  //
  // Monsters move faster.
  //

  fastparm := M_CheckParm('-fast') <> 0;

  //!
  // @vanilla
  //
  // Developer mode. F1 saves a screenshot in the current working
  // directory.
  //

  devparm := M_CheckParm('-devparm') <> 0;

  I_DisplayFPSDots(devparm);

  //!
  // @category net
  // @vanilla
  //
  // Start a deathmatch game.
  //

  If (M_CheckParm('-deathmatch') <> 0) Then deathmatch := 1;

  //!
  // @category net
  // @vanilla
  //
  // Start a deathmatch 2.0 game.  Weapons do not stay in place and
  // all items respawn after 30 seconds.
  //

  If (M_CheckParm('-altdeath') <> 0) Then deathmatch := 2;

  //!
  // @category net
  // @vanilla
  //
  // Start a deathmatch 3.0 game.  Weapons stay in place and
  // all items respawn after 30 seconds.
  //

  If (M_CheckParm('-dm3') <> 0) Then deathmatch := 3;

  If (devparm) Then Begin
    writeln(D_DEVSTR);
  End;

  // find which dir to use for config files

{$IFDEF WINDOWS}

  //!
  // @category obscure
  // @platform windows
  // @vanilla
  //
  // Save configuration data and savegames in c:\doomdata,
  // allowing play from CD.
  //

  If (M_ParmExists('-cdrom')) Then Begin
    //        printf(D_CDROM);

    M_SetConfigDir('c:\doomdata\');
  End
  Else
{$ENDIF}Begin
    // Auto-detect the configuration dir.

    M_SetConfigDir('');
  End;

  //!
  // @category game
  // @arg <x>
  // @vanilla
  //
  // Turbo mode.  The player's speed is multiplied by x%.  If unspecified,
  // x defaults to 200.  Values are rounded up to 10 and down to 400.
  //

//    if ( (p=M_CheckParm ("-turbo")) )
//    {
//	int     scale = 200;
//
//	if (p<myargc-1)
//	    scale = atoi (myargv[p+1]);
//	if (scale < 10)
//	    scale = 10;
//	if (scale > 400)
//	    scale = 400;
//        DEH_printf("turbo scale: %i%%\n", scale);
//	forwardmove[0] = forwardmove[0]*scale/100;
//	forwardmove[1] = forwardmove[1]*scale/100;
//	sidemove[0] = sidemove[0]*scale/100;
//	sidemove[1] = sidemove[1]*scale/100;
//    }

  // init subsystems
  writeln('V_Init: allocate screens.');
  V_Init();

  // Load configuration files before initialising other subsystems.
  writeln('M_LoadDefaults: Load system defaults.');
  M_SetConfigFilenames('default.cfg', PROGRAM_PREFIX + 'doom.cfg');
  D_BindVariables();
  M_LoadDefaults();

  // Save configuration at exit.
  //    I_AtExit(M_SaveDefaults, true); // [crispy] always save configuration at exit

  // Find main IWAD file and load it.
  iwadfile := D_FindIWAD(IWAD_MASK_DOOM, gamemission);

  // None found?

  If (iwadfile = '') Then Begin
    I_Error('Game mode indeterminate.  No IWAD file was found.  Try' + LineEnding +
      'specifying one with the ''-iwad'' command line parameter.' + LineEnding);
  End;

  modifiedgame := false;

  writeln('W_Init: Init WADfiles.');
  D_AddFile(iwadfile);

  W_CheckCorrectIWAD(doom);

  // Now that we've loaded the IWAD, we can figure out what gamemission
  // we're playing and which version of Vanilla Doom we need to emulate.
  D_IdentifyVersion();
  InitGameVersion();
  //
  //    // Check which IWAD variant we are using.
  //
  //    if (W_CheckNumForName("FREEDOOM") >= 0)
  //    {
  //        if (W_CheckNumForName("FREEDM") >= 0)
  //        {
  //            gamevariant = freedm;
  //        }
  //        else
  //        {
  //            gamevariant = freedoom;
  //        }
  //    }
  //    else if (W_CheckNumForName("DMENUPIC") >= 0)
  //    {
  //        gamevariant = bfgedition;
  //    }
  //
  //    //!
  //    // @category mod
  //    //
  //    // Disable automatic loading of Dehacked patches for certain
  //    // IWAD files.
  //    //
  //    if (!M_ParmExists("-nodeh"))
  //    {
  //        // Some IWADs have dehacked patches that need to be loaded for
  //        // them to be played properly.
  //        LoadIwadDeh();
  //    }
  //
  //    // Doom 3: BFG Edition includes modified versions of the classic
  //    // IWADs which can be identified by an additional DMENUPIC lump.
  //    // Furthermore, the M_GDHIGH lumps have been modified in a way that
  //    // makes them incompatible to Vanilla Doom and the modified version
  //    // of doom2.wad is missing the TITLEPIC lump.
  //    // We specifically check for DMENUPIC here, before PWADs have been
  //    // loaded which could probably include a lump of that name.
  //
  //    if (gamevariant == bfgedition)
  //    {
  //        printf("BFG Edition: Using workarounds as needed.\n");
  //
  //        // BFG Edition changes the names of the secret levels to
  //        // censor the Wolfenstein references. It also has an extra
  //        // secret level (MAP33). In Vanilla Doom (meaning the DOS
  //        // version), MAP33 overflows into the Plutonia level names
  //        // array, so HUSTR_33 is actually PHUSTR_1.
  //        DEH_AddStringReplacement(HUSTR_31, "level 31: idkfa");
  //        DEH_AddStringReplacement(HUSTR_32, "level 32: keen");
  //        DEH_AddStringReplacement(PHUSTR_1, "level 33: betray");
  //
  //        // The BFG edition doesn't have the "low detail" menu option (fair
  //        // enough). But bizarrely, it reuses the M_GDHIGH patch as a label
  //        // for the options menu (says "Fullscreen:"). Why the perpetrators
  //        // couldn't just add a new graphic lump and had to reuse this one,
  //        // I don't know.
  //        //
  //        // The end result is that M_GDHIGH is too wide and causes the game
  //        // to crash. As a workaround to get a minimum level of support for
  //        // the BFG edition IWADs, use the "ON"/"OFF" graphics instead.
  //        DEH_AddStringReplacement("M_GDHIGH", "M_MSGON");
  //        DEH_AddStringReplacement("M_GDLOW", "M_MSGOFF");
  //
  //        // The BFG edition's "Screen Size:" graphic has also been changed
  //        // to say "Gamepad:". Fortunately, it (along with the original
  //        // Doom IWADs) has an unused graphic that says "Display". So we
  //        // can swap this in instead, and it kind of makes sense.
  //        DEH_AddStringReplacement("M_SCRNSZ", "M_DISP");
  //    }
  //
  //    //!
  //    // @category game
  //    //
  //    // Automatic pistol start when advancing from one level to the next. At the
  //    // beginning of each level, the player's health is reset to 100, their
  //    // armor to 0 and their inventory is reduced to the following: pistol,
  //    // fists and 50 bullets. This option is not allowed when recording a demo,
  //    // playing back a demo or when starting a network game.
  //    //
  //
  //    crispy->pistolstart = M_ParmExists("-pistolstart");
  //
  //    //!
  //    // @category game
  //    //
  //    // Double ammo pickup rate. This option is not allowed when recording a
  //    // demo, playing back a demo or when starting a network game.
  //    //
  //
  //    crispy->moreammo = M_ParmExists("-doubleammo");
  //
  //    //!
  //    // @category mod
  //    //
  //    // Disable auto-loading of .wad and .deh files.
  //    //
  //    if (!M_ParmExists("-noautoload") && gamemode != shareware)
  //    {
  //        char *autoload_dir;
  //
  //        // common auto-loaded files for all Doom flavors
  //
  //        if (gamemission < pack_chex && gamevariant != freedoom)
  //        {
  //            autoload_dir = M_GetAutoloadDir("doom-all", true);
  //            if (autoload_dir != NULL)
  //            {
  //                DEH_AutoLoadPatches(autoload_dir);
  //                W_AutoLoadWADs(autoload_dir);
  //                free(autoload_dir);
  //            }
  //        }
  //
  //        // auto-loaded files per IWAD
  //        autoload_dir = M_GetAutoloadDir(D_SaveGameIWADName(gamemission, gamevariant), true);
  //        if (autoload_dir != NULL)
  //        {
  //            DEH_AutoLoadPatches(autoload_dir);
  //            W_AutoLoadWADs(autoload_dir);
  //            free(autoload_dir);
  //        }
  //    }
  //
  //    // Load Dehacked patches specified on the command line with -deh.
  //    // Note that there's a very careful and deliberate ordering to how
  //    // Dehacked patches are loaded. The order we use is:
  //    //  1. IWAD dehacked patches.
  //    //  2. Command line dehacked patches specified with -deh.
  //    //  3. PWAD dehacked patches in DEHACKED lumps.
  //    DEH_ParseCommandLine();
  //
  //    // Load PWAD files.
  //    modifiedgame = W_ParseCommandLine();
  //
  //    //!
  //    // @arg <file>
  //    // @category mod
  //    //
  //    // [crispy] experimental feature: in conjunction with -merge <files>
  //    // merges PWADs into the main IWAD and writes the merged data into <file>
  //    //
  //
  //    p = M_CheckParm("-mergedump");
  //
  //    if (p)
  //    {
  //	p = M_CheckParmWithArgs("-mergedump", 1);
  //
  //	if (p)
  //	{
  //	    int merged;
  //
  //	    if (M_StringEndsWith(myargv[p+1], ".wad"))
  //	    {
  //		M_StringCopy(file, myargv[p+1], sizeof(file));
  //	    }
  //	    else
  //	    {
  //		DEH_snprintf(file, sizeof(file), "%s.wad", myargv[p+1]);
  //	    }
  //
  //	    merged = W_MergeDump(file);
  //	    I_Error("W_MergeDump: Merged %d lumps into file '%s'.", merged, file);
  //	}
  //	else
  //	{
  //	    I_Error("W_MergeDump: The '-mergedump' parameter requires an argument.");
  //	}
  //    }
  //
  //    //!
  //    // @arg <file>
  //    // @category mod
  //    //
  //    // [crispy] experimental feature: dump lump data into a new LMP file <file>
  //    //
  //
  //    p = M_CheckParm("-lumpdump");
  //
  //    if (p)
  //    {
  //	p = M_CheckParmWithArgs("-lumpdump", 1);
  //
  //	if (p)
  //	{
  //	    int dumped;
  //
  //	    M_StringCopy(file, myargv[p+1], sizeof(file));
  //
  //	    dumped = W_LumpDump(file);
  //
  //	    if (dumped < 0)
  //	    {
  //		I_Error("W_LumpDump: Failed to write lump '%s'.", file);
  //	    }
  //	    else
  //	    {
  //		I_Error("W_LumpDump: Dumped lump into file '%s.lmp'.", file);
  //	    }
  //	}
  //	else
  //	{
  //	    I_Error("W_LumpDump: The '-lumpdump' parameter requires an argument.");
  //	}
  //    }
  //
  //    // Debug:
  ////    W_PrintDirectory();
  //
  //    // [crispy] add wad files from autoload PWAD directories
  //
  //    if (!M_ParmExists("-noautoload") && gamemode != shareware)
  //    {
  //        int i;
  //
  //        for (i = 0; loadparms[i]; i++)
  //        {
  //            int p;
  //            p = M_CheckParmWithArgs(loadparms[i], 1);
  //            if (p)
  //            {
  //                while (++p != myargc && myargv[p][0] != '-')
  //                {
  //                    char *autoload_dir;
  //                    if ((autoload_dir = M_GetAutoloadDir(M_BaseName(myargv[p]), false)))
  //                    {
  //                        W_AutoLoadWADs(autoload_dir);
  //                        free(autoload_dir);
  //                    }
  //                }
  //            }
  //        }
  //    }
  //
  //    //!
  //    // @arg <demo>
  //    // @category demo
  //    // @vanilla
  //    //
  //    // Play back the demo named demo.lmp.
  //    //
  //
  //    p = M_CheckParmWithArgs ("-playdemo", 1);
  //
  //    if (!p)
  //    {
  //        //!
  //        // @arg <demo>
  //        // @category demo
  //        // @vanilla
  //        //
  //        // Play back the demo named demo.lmp, determining the framerate
  //        // of the screen.
  //        //
  //	p = M_CheckParmWithArgs("-timedemo", 1);
  //
  //    }
  //
  //    if (p)
  //    {
  //        char *uc_filename = strdup(myargv[p + 1]);
  //        M_ForceUppercase(uc_filename);
  //
  //        // With Vanilla you have to specify the file without extension,
  //        // but make that optional.
  //        if (M_StringEndsWith(uc_filename, ".LMP"))
  //        {
  //            M_StringCopy(file, myargv[p + 1], sizeof(file));
  //        }
  //        else
  //        {
  //            DEH_snprintf(file, sizeof(file), "%s.lmp", myargv[p+1]);
  //        }
  //
  //        free(uc_filename);
  //
  //        if (D_AddFile(file))
  //        {
  //	    int i;
  //	    // [crispy] check if the demo file name gets truncated to a lump name that is already present
  //	    if ((i = W_CheckNumForNameFromTo(lumpinfo[numlumps - 1]->name, numlumps - 2, 0)) != -1)
  //	    {
  //		printf("Demo lump name collision detected with lump \'%.8s\' from %s.\n",
  //		        lumpinfo[i]->name, W_WadNameForLump(lumpinfo[i]));
  //		// [FG] the DEMO1 lump is almost certainly always a demo lump
  //		M_StringCopy(lumpinfo[numlumps - 1]->name, "DEMO1", 6);
  //	    }
  //
  //            M_StringCopy(demolumpname, lumpinfo[numlumps - 1]->name,
  //                         sizeof(demolumpname));
  //        }
  //        else
  //        {
  //            // If file failed to load, still continue trying to play
  //            // the demo in the same way as Vanilla Doom.  This makes
  //            // tricks like "-playdemo demo1" possible.
  //
  //            M_StringCopy(demolumpname, myargv[p + 1], sizeof(demolumpname));
  //        }
  //
  //        printf("Playing demo %s.\n", file);
  //    }
  //
  //    I_AtExit(G_CheckDemoStatusAtExit, true);
  //
  //    // Generate the WAD hash table.  Speed things up a bit.
  //    W_GenerateHashTable();
  //
  //    // [crispy] allow overriding of special-casing
  //
  //    //!
  //    // @category mod
  //    //
  //    // Disable automatic loading of Master Levels, No Rest for the Living and
  //    // Sigil.
  //    //
  //    if (!M_ParmExists("-nosideload") && gamemode != shareware && !demolumpname[0])
  //    {
  //	if (gamemode == retail &&
  //	    gameversion == exe_ultimate &&
  //	    gamevariant != freedoom &&
  //	    strncasecmp(M_BaseName(iwadfile), "rekkr", 5))
  //	{
  //		D_LoadSigilWads();
  //	}
  //
  //	if (gamemission == doom2)
  //	{
  //		D_LoadNerveWad();
  //		D_LoadMasterlevelsWad();
  //	}
  //    }
  //
  //    // Load DEHACKED lumps from WAD files - but only if we give the right
  //    // command line parameter.
  //
  //    // [crispy] load DEHACKED lumps by default, but allow overriding
  //
  //    //!
  //    // @category mod
  //    //
  //    // Disable automatic loading of embedded DEHACKED lumps in wad files.
  //    //
  //    if (!M_ParmExists("-nodehlump") && !M_ParmExists("-nodeh"))
  //    {
  //        int i, loaded = 0;
  //        int numiwadlumps = numlumps;
  //
  //        while (!W_IsIWADLump(lumpinfo[numiwadlumps - 1]))
  //        {
  //            numiwadlumps--;
  //        }
  //
  //        for (i = numiwadlumps; i < numlumps; ++i)
  //        {
  //            if (!strncmp(lumpinfo[i]->name, "DEHACKED", 8))
  //            {
  //                DEH_LoadLump(i, true, true); // [crispy] allow long, allow error
  //                loaded++;
  //            }
  //        }
  //
  //        printf("  loaded %i DEHACKED lumps from PWAD files.\n", loaded);
  //    }
  //
  //    // [crispy] process .deh files from PWADs autoload directories
  //
  //    if (!M_ParmExists("-noautoload") && gamemode != shareware)
  //    {
  //        int i;
  //
  //        for (i = 0; loadparms[i]; i++)
  //        {
  //            int p;
  //            p = M_CheckParmWithArgs(loadparms[i], 1);
  //            if (p)
  //            {
  //                while (++p != myargc && myargv[p][0] != '-')
  //                {
  //                    char *autoload_dir;
  //                    if ((autoload_dir = M_GetAutoloadDir(M_BaseName(myargv[p]), false)))
  //                    {
  //                        DEH_AutoLoadPatches(autoload_dir);
  //                        free(autoload_dir);
  //                    }
  //                }
  //            }
  //        }
  //    }

  // Set the gamedescription string. This is only possible now that
  // we've finished loading Dehacked patches.
  D_SetGameDescription();

  //    savegamedir = M_GetSaveGameDir(D_SaveGameIWADName(gamemission, gamevariant));

  // Check for -file in shareware
  If (modifiedgame And (gamevariant <> freedoom)) Then Begin
    Raise exception.create('Not ported.');
    // These are the lumps that will be checked in IWAD,
    // if any one is not present, execution will be aborted.
   //	char name[23][8]=
   //	{
   //	    "e2m1","e2m2","e2m3","e2m4","e2m5","e2m6","e2m7","e2m8","e2m9",
   //	    "e3m1","e3m3","e3m3","e3m4","e3m5","e3m6","e3m7","e3m8","e3m9",
   //	    "dphoof","bfgga0","heada1","cybra1","spida1d1"
   //	};
   //	int i;
   //
   //	if ( gamemode == shareware)
   //	    I_Error(DEH_String("\nYou cannot -file with the shareware "
   //			       "version. Register!"));
   //
   //	// Check for fake IWAD with right name,
   //	// but w/o all the lumps of the registered version.
   //	if (gamemode == registered)
   //	    for (i = 0;i < 23; i++)
   //		if (W_CheckNumForName(name[i])<0)
   //		    I_Error(DEH_String("\nThis is not the registered version."));
  End;

  I_PrintStartupBanner(gamedescription);
  //    PrintDehackedBanners();

  Writeln('I_Init: Setting up machine state.');
  //    I_CheckIsScreensaver();
  I_InitTimer();
  //    I_InitJoystick();
  I_InitSound(doom);
  I_InitMusic();

  //    // [crispy] check for SSG resources
  //    crispy->havessg =
  //    (
  //        gamemode == commercial ||
  //        (
  //            W_CheckNumForName("sht2a0")         != -1 && // [crispy] wielding/firing sprite sequence
  //            I_GetSfxLumpNum(&S_sfx[sfx_dshtgn]) != -1 && // [crispy] firing sound
  //            I_GetSfxLumpNum(&S_sfx[sfx_dbopn])  != -1 && // [crispy] opening sound
  //            I_GetSfxLumpNum(&S_sfx[sfx_dbload]) != -1 && // [crispy] reloading sound
  //            I_GetSfxLumpNum(&S_sfx[sfx_dbcls])  != -1    // [crispy] closing sound
  //        )
  //    );

      // [crispy] check for presence of a 5th episode
  //    crispy->haved1e5 = (gameversion == exe_ultimate) &&
  //                       (W_CheckNumForName("m_epi5") != -1) &&
  //                       (W_CheckNumForName("e5m1") != -1) &&
  //                       (W_CheckNumForName("wilv40") != -1);

  //  [crispy]check For presence Of a 6 th episode
  //    crispy->haved1e6 = (gameversion == exe_ultimate) &&
  //                       (W_CheckNumForName("m_epi6") != -1) &&
  //                       (W_CheckNumForName("e6m1") != -1) &&
  //                       (W_CheckNumForName("wilv50") != -1);

      // [crispy] check for presence of E1M10
  //    crispy->havee1m10 = (gamemode == retail) &&
  //                       (W_CheckNumForName("e1m10") != -1) &&
  //                       (W_CheckNumForName("sewers") != -1);

      // [crispy] check for presence of MAP33
  //    crispy->havemap33 = (gamemode == commercial) &&
  //                       (W_CheckNumForName("map33") != -1) &&
  //                       (W_CheckNumForName("cwilv32") != -1);

      // [crispy] change level name for MAP33 if not already changed
  //    if (crispy->havemap33 && !DEH_HasStringReplacement(PHUSTR_1))
  //    {
  //        DEH_AddStringReplacement(PHUSTR_1, "level 33: betray");
  //    }

  //    writeln('NET_Init: Init network subsystem.');
  //    NET_Init (); // TODO: wenn mal nur noch das hier portiert werden muss ...

      // Initial netgame startup. Connect to server etc.
  //    D_ConnectNetGame();

      // get skill / episode / map from parms

      // HMP (or skill #2) being the default, had to be placed at index 0 when drawn in the menu,
      // so all difficulties 'real' positions had to be scaled by -2, hence +2 being added
      // below in order to get the correct skill.
  startskill := sk_medium; //(crispy.defaultskill + SKILL_HMP) Mod NUM_SKILLS;

  startepisode := 1;
  startmap := 1;
  autostart := false;

  //!
  // @category game
  // @arg <skill>
  // @vanilla
  //
  // Set the game skill, 1-5 (1: easiest, 5: hardest).  A skill of
  // 0 disables all monsters.
  //

//    p = M_CheckParmWithArgs("-skill", 1);
//
//    if (p)
//    {
//	startskill = myargv[p+1][0]-'1';
//	autostart = true;
//    }

  //!
  // @category game
  // @arg <n>
  // @vanilla
  //
  // Start playing on episode n (1-4)
  //

//    p = M_CheckParmWithArgs("-episode", 1);
//
//    if (p)
//    {
//	startepisode = myargv[p+1][0]-'0';
//	startmap = 1;
//	autostart = true;
//    }

  timelimit := 0;

  //!
  // @arg <n>
  // @category net
  // @vanilla
  //
  // For multiplayer games: exit each level after n minutes.
  //

//    p = M_CheckParmWithArgs("-timer", 1);
//
//    if (p)
//    {
//	timelimit = atoi(myargv[p+1]);
//    }

    //!
    // @category net
    // @vanilla
    //
    // Austin Virtual Gaming: end levels after 20 minutes.
    //

//    p = M_CheckParm ("-avg");
//
//    if (p)
//    {
//	timelimit = 20;
//    }

    //!
    // @category game
    // @arg [<x> <y> | <xy>]
    // @vanilla
    //
    // Start a game immediately, warping to ExMy (Doom 1) or MAPxy
    // (Doom 2)
    //

//    p = M_CheckParmWithArgs("-warp", 1);
//
//    if (p)
//    {
//        if (gamemode == commercial)
//            startmap = atoi (myargv[p+1]);
//        else
//        {
//            startepisode = myargv[p+1][0]-'0';
//
//            // [crispy] only if second argument is not another option
//            if (p + 2 < myargc && myargv[p+2][0] != '-')
//            {
//                startmap = myargv[p+2][0]-'0';
//            }
//            else
//            {
//                // [crispy] allow second digit without space in between for Doom 1
//                startmap = myargv[p+1][1]-'0';
//            }
//        }
//        autostart = true;
//        // [crispy] if used with -playdemo, fast-forward demo up to the desired map
//        crispy->demowarp = startmap;
//    }

    // Undocumented:
    // Invoked by setup to test the controls.

//    p = M_CheckParm("-testcontrols");
//
//    if (p > 0)
//    {
//        startepisode = 1;
//        startmap = 1;
//        autostart = true;
//        testcontrols = true;
//    }

//    // [crispy] port level flipping feature over from Strawberry Doom
//#ifdef ENABLE_APRIL_1ST_JOKE
//    {
//        time_t curtime = time(NULL);
//        struct tm *curtm = localtime(&curtime);
//
//        if (curtm && curtm->tm_mon == 3 && curtm->tm_mday == 1)
//            crispy->fliplevels = true;
//    }
//#endif

//    p = M_CheckParm("-fliplevels");
//
//    if (p > 0)
//    {
//        crispy->fliplevels = !crispy->fliplevels;
//        crispy->flipweapons = !crispy->flipweapons;
//    }

//    p = M_CheckParm("-flipweapons");
//
//    if (p > 0)
//    {
//        crispy->flipweapons = !crispy->flipweapons;
//    }

    // Check for load game parameter
    // We do this here and save the slot number, so that the network code
    // can override it or send the load slot to other players.

    //!
    // @category game
    // @arg <s>
    // @vanilla
    //
    // Load the game in slot s.
    //

//    p = M_CheckParmWithArgs("-loadgame", 1);
//
//    if (p)
//    {
//        startloadgame = atoi(myargv[p+1]);
//    }
//    else
//    {
//        // Not loading a game
//        startloadgame = -1;
//    }

  write('M_Init: Init miscellaneous info.');
  M_Init();
  writeln('');

  Write('R_Init: Init DOOM refresh daemon - ');
  R_Init();
  writeln('');

  Writeln('P_Init: Init Playloop state.');
  //    P_Init ();
  //
  //    DEH_printf("S_Init: Setting up sound.\n");
  //    S_Init (sfxVolume * 8, musicVolume * 8);
  //
  //    DEH_printf("D_CheckNetGame: Checking network game status.\n");
  //    D_CheckNetGame ();
  //
  //    PrintGameVersion();
  //
  //    DEH_printf("HU_Init: Setting up heads up display.\n");
  //    HU_Init ();
  //
  //    DEH_printf("ST_Init: Init status bar.\n");
  //    ST_Init ();
  //
  //    // If Doom II without a MAP01 lump, this is a store demo.
  //    // Moved this here so that MAP01 isn't constantly looked up
  //    // in the main loop.
  //
  //    if (gamemode == commercial && W_CheckNumForName("map01") < 0)
  //        storedemo = true;
  //
  //    if (M_CheckParmWithArgs("-statdump", 1))
  //    {
  //        I_AtExit(StatDump, true);
  //        DEH_printf("External statistics registered.\n");
  //    }
  //
  //    //!
  //    // @category game
  //    //
  //    // Start single player game with items spawns as in cooperative netgame.
  //    //
  //
  //    p = M_ParmExists("-coop_spawns");
  //
  //    if (p)
  //    {
  //        coop_spawns = true;
  //    }
  //
  //    //!
  //    // @arg <x>
  //    // @category demo
  //    // @vanilla
  //    //
  //    // Record a demo named x.lmp.
  //    //
  //
  //    p = M_CheckParmWithArgs("-record", 1);
  //
  //    if (p)
  //    {
  //	G_RecordDemo (myargv[p+1]);
  //	autostart = true;
  //    }
  //
  //    p = M_CheckParmWithArgs("-playdemo", 1);
  //    if (p)
  //    {
  //	singledemo = true;              // quit after one demo
  //	G_DeferedPlayDemo (demolumpname);
  //	D_DoomLoop ();  // never returns
  //    }
  //    crispy->demowarp = 0; // [crispy] we don't play a demo, so don't skip maps
  //
  //    p = M_CheckParmWithArgs("-timedemo", 1);
  //    if (p)
  //    {
  //	G_TimeDemo (demolumpname);
  //	D_DoomLoop ();  // never returns
  //    }
  //
  //    if (startloadgame >= 0)
  //    {
  //        M_StringCopy(file, P_SaveGameFile(startloadgame), sizeof(file));
  //	G_LoadGame(file);
  //    }
  //
  //    if (gameaction != ga_loadgame )
  //    {
  //	if (autostart || netgame)
  //	    G_InitNew (startskill, startepisode, startmap);
  //	else
  //	    D_StartTitle ();                // start up intro loop
  //    }

  // D_DoomLoop(); // never returns -- Wird aus Paintbox1.Invalidate heraus aufgerufen !

  // Dieser Code hier steht noch am Anfang von DoomLoop bevor die While Schleife los geht, muss natürlich auch irgendwie gemacht werden ;)
  //  if (gamevariant == bfgedition &&
  //         (demorecording || (gameaction == ga_playdemo) || netgame))
  //     {
  //         printf(" WARNING: You are playing using one of the Doom Classic\n"
  //                " IWAD files shipped with the Doom 3: BFG Edition. These are\n"
  //                " known to be incompatible with the regular IWAD files and\n"
  //                " may cause demos and network games to get out of sync.\n");
  //     }
  //
  //     // [crispy] no need to write a demo header in demo continue mode
  //     if (demorecording && gameaction != ga_playdemo)
  // 	G_BeginRecording ();
  //
  //     main_loop_started = true;
  //
  I_SetWindowTitle(gamedescription);
  //     I_GraphicsCheckCommandLine();
  //     I_SetGrabMouseCallback(D_GrabMouseCallback);
  I_RegisterWindowIcon(doom_icon_data, doom_icon_w, doom_icon_h);
  I_InitGraphics();
  //     EnableLoadingDisk();
  //
  //     TryRunTics();
  //
  //     V_RestoreBuffer();
  //     R_ExecuteSetViewSize();
  //
  //     D_StartGameLoop();
  //
  //     if (testcontrols)
  //     {
  //         wipegamestate = gamestate;
  //     }
End;

End.

