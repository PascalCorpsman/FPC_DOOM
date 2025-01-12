Unit g_game;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef
  , d_event, d_mode
  ;

Var
  timelimit: int;

  nodrawers: boolean = false; // for comparative timing purposes
  gamestate: gamestate_t;
  gameaction: gameaction_t = ga_nothing;
  demorecording: Boolean;
  demoplayback: boolean = false;
  paused: boolean;
  sendpause: Boolean;
  viewactive: boolean;
  singledemo: boolean = false; // quit after playing a demo from cmdline
  netgame: boolean; // only true if packets are broadcast

  lowres_turn: boolean; // low resolution turning for longtics
  playeringame: Array[0..MAXPLAYERS - 1] Of boolean;

Procedure G_Ticker();
Function G_Responder(Const ev: Pevent_t): boolean;

Function speedkeydown(): boolean;

Procedure G_InitNew(skill: skill_t; episode: int; map: int);

Implementation

Uses
  sounds
  , i_video, i_timer
  , m_menu
  , s_sound
  ;

//
// G_Responder
// Get info needed to make ticcmd_ts for the players.
//

Procedure G_Ticker();
Begin
  //   int		i;
  //    int		buf;
  //    ticcmd_t*	cmd;
  //
  //    // do player reborns if needed
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //	if (playeringame[i] && players[i].playerstate == PST_REBORN)
  //	    G_DoReborn (i);
  //
  //    // do things to change the game state
  //    while (gameaction != ga_nothing)
  //    {
  //	switch (gameaction)
  //	{
  //	  case ga_loadlevel:
  //	    G_DoLoadLevel ();
  //	    break;
  //	  case ga_newgame:
  //	    // [crispy] re-read game parameters from command line
  //	    G_ReadGameParms();
  //	    G_DoNewGame ();
  //	    break;
  //	  case ga_loadgame:
  //	    // [crispy] re-read game parameters from command line
  //	    G_ReadGameParms();
  //	    G_DoLoadGame ();
  //	    break;
  //	  case ga_savegame:
  //	    G_DoSaveGame ();
  //	    break;
  //	  case ga_playdemo:
  //	    G_DoPlayDemo ();
  //	    break;
  //	  case ga_completed:
  //	    G_DoCompleted ();
  //	    break;
  //	  case ga_victory:
  //	    F_StartFinale ();
  //	    break;
  //	  case ga_worlddone:
  //	    G_DoWorldDone ();
  //	    break;
  //	  case ga_screenshot:
  //	    // [crispy] redraw view without weapons and HUD
  //	    if (gamestate == GS_LEVEL && (crispy->cleanscreenshot || crispy->screenshotmsg == 1))
  //	    {
  //		crispy->screenshotmsg = 4;
  //		crispy->post_rendering_hook = G_CrispyScreenShot;
  //	    }
  //	    else
  //	    {
  //		G_CrispyScreenShot();
  //	    }
  //	    gameaction = ga_nothing;
  //	    break;
  //	  case ga_nothing:
  //	    break;
  //	}
  //    }
  //
  //    // [crispy] demo sync of revenant tracers and RNG (from prboom-plus)
  //    if (paused & 2 || (!demoplayback && menuactive && !netgame))
  //    {
  //        demostarttic++;
  //    }
  //    else
  //    {
  //    // get commands, check consistancy,
  //    // and build new consistancy check
  //    buf = (gametic/ticdup)%BACKUPTICS;
  //
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //    {
  //	if (playeringame[i])
  //	{
  //	    cmd = &players[i].cmd;
  //
  //	    memcpy(cmd, &netcmds[i], sizeof(ticcmd_t));
  //
  //	    if (demoplayback)
  //		G_ReadDemoTiccmd (cmd);
  //	    // [crispy] do not record tics while still playing back in demo continue mode
  //	    if (demorecording && !demoplayback)
  //		G_WriteDemoTiccmd (cmd);
  //
  //	    // check for turbo cheats
  //
  //            // check ~ 4 seconds whether to display the turbo message.
  //            // store if the turbo threshold was exceeded in any tics
  //            // over the past 4 seconds.  offset the checking period
  //            // for each player so messages are not displayed at the
  //            // same time.
  //
  //            if (cmd->forwardmove > TURBOTHRESHOLD)
  //            {
  //                turbodetected[i] = true;
  //            }
  //
  //            if ((gametic & 31) == 0
  //             && ((gametic >> 5) % MAXPLAYERS) == i
  //             && turbodetected[i])
  //            {
  //                static char turbomessage[80];
  //                M_snprintf(turbomessage, sizeof(turbomessage),
  //                           "%s is turbo!", player_names[i]);
  //                players[consoleplayer].message = turbomessage;
  //                turbodetected[i] = false;
  //            }
  //
  //	    if (netgame && !netdemo && !(gametic%ticdup) )
  //	    {
  //		if (gametic > BACKUPTICS
  //		    && consistancy[i][buf] != cmd->consistancy)
  //		{
  //		    I_Error ("consistency failure (%i should be %i)",
  //			     cmd->consistancy, consistancy[i][buf]);
  //		}
  //		if (players[i].mo)
  //		    consistancy[i][buf] = players[i].mo->x;
  //		else
  //		    consistancy[i][buf] = rndindex;
  //	    }
  //	}
  //    }
  //
  //    // [crispy] increase demo tics counter
  //    if (demoplayback || demorecording)
  //    {
  //	    defdemotics++;
  //    }
  //
  //    // check for special buttons
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //    {
  //	if (playeringame[i])
  //	{
  //	    if (players[i].cmd.buttons & BT_SPECIAL)
  //	    {
  //		switch (players[i].cmd.buttons & BT_SPECIALMASK)
  //		{
  //		  case BTS_PAUSE:
  //		    paused ^= 1;
  //		    if (paused)
  //			S_PauseSound ();
  //		    else
  //		    // [crispy] Fixed bug when music was hearable with zero volume
  //		    if (musicVolume)
  //			S_ResumeSound ();
  //		    break;
  //
  //		  case BTS_SAVEGAME:
  //		    // [crispy] never override savegames by demo playback
  //		    if (demoplayback)
  //			break;
  //		    if (!savedescription[0])
  //                    {
  //                        M_StringCopy(savedescription, "NET GAME",
  //                                     sizeof(savedescription));
  //                    }
  //
  //		    savegameslot =
  //			(players[i].cmd.buttons & BTS_SAVEMASK)>>BTS_SAVESHIFT;
  //		    gameaction = ga_savegame;
  //		    // [crispy] un-pause immediately after saving
  //		    // (impossible to send save and pause specials within the same tic)
  //		    if (demorecording && paused)
  //			sendpause = true;
  //		    break;
  //		}
  //	    }
  //	}
  //    }
  //    }
  //
  //    // Have we just finished displaying an intermission screen?
  //
  //    if (oldgamestate == GS_INTERMISSION && gamestate != GS_INTERMISSION)
  //    {
  //        WI_End();
  //    }
  //
  //    oldgamestate = gamestate;
  //    oldleveltime = leveltime;
  //
  //    // [crispy] no pause at intermission screen during demo playback
  //    // to avoid desyncs (from prboom-plus)
  //    if ((paused & 2 || (!demoplayback && menuactive && !netgame))
  //        && gamestate != GS_LEVEL)
  //    {
  //    return;
  //    }
  //
  //    // do main actions
  //    switch (gamestate)
  //    {
  //      case GS_LEVEL:
  //	P_Ticker ();
  //	ST_Ticker ();
  //	AM_Ticker ();
  //	HU_Ticker ();
  //	break;
  //
  //      case GS_INTERMISSION:
  //	WI_Ticker ();
  //	break;
  //
  //      case GS_FINALE:
  //	F_Ticker ();
  //	break;
  //
  //      case GS_DEMOSCREEN:
  //	D_PageTicker ();
  //	break;
  //    }
End;

Function G_Responder(Const ev: Pevent_t): boolean;
Begin
  result := false;
  //   // [crispy] demo pause (from prboom-plus)
  //    if (gameaction == ga_nothing &&
  //        (demoplayback || gamestate == GS_DEMOSCREEN))
  //    {
  //        if (ev->type == ev_keydown && ev->data1 == key_pause)
  //        {
  //            if (paused ^= 2)
  //                S_PauseSound();
  //            else
  //                S_ResumeSound();
  //            return true;
  //        }
  //    }

  //    // [crispy] demo fast-forward
  //    if (ev->type == ev_keydown && ev->data1 == key_demospeed &&
  //        (demoplayback || gamestate == GS_DEMOSCREEN))
  //    {
  //        singletics = !singletics;
  //        return true;
  //    }

  //    // allow spy mode changes even during the demo
  //    if (gamestate == GS_LEVEL && ev->type == ev_keydown
  //     && ev->data1 == key_spy && (singledemo || !deathmatch) )
  //    {
  //	// spy mode
  //	do
  //	{
  //	    displayplayer++;
  //	    if (displayplayer == MAXPLAYERS)
  //		displayplayer = 0;
  //	} while (!playeringame[displayplayer] && displayplayer != consoleplayer);
  //	// [crispy] killough 3/7/98: switch status bar views too
  //	ST_Start();
  //	HU_Start();
  //	S_UpdateSounds(players[displayplayer].mo);
  //	// [crispy] re-init automap variables for correct player arrow angle
  //	if (automapactive)
  //	AM_initVariables();
  //	return true;
  //    }

      // any other key pops up menu if in demos
  If (gameaction = ga_nothing) And (Not singledemo) And
    (demoplayback Or (gamestate = GS_DEMOSCREEN)) Then Begin
    If ((ev^._type = ev_keydown) Or
      ((ev^._type = ev_mouse) And (ev^.data1 <> 0)) Or
      ((ev^._type = ev_joystick) And (ev^.data1 <> 0))) Then Begin
      // [crispy] play a sound if the menu is activated with a different key than ESC
      If (Not menuactive) {And (crispy^.soundfix)} Then Begin
        S_StartSoundOptional(Nil, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
      End;
      M_StartControlPanel();
      joywait := I_GetTime() + 5;
      result := true;
      exit;
    End;
    result := false;
    exit;
  End;

  //    if (gamestate == GS_LEVEL)
  //    {
  //#if 0
  //	if (devparm && ev->type == ev_keydown && ev->data1 == ';')
  //	{
  //	    G_DeathMatchSpawnPlayer (0);
  //	    return true;
  //	}
  //#endif
  //	if (HU_Responder (ev))
  //	    return true;	// chat ate the event
  //	if (ST_Responder (ev))
  //	    return true;	// status window ate it
  //	if (AM_Responder (ev))
  //	    return true;	// automap ate it
  //    }
  //
  //    if (gamestate == GS_FINALE)
  //    {
  //	if (F_Responder (ev))
  //	    return true;	// finale ate the event
  //    }
  //
  //    if (testcontrols && ev->type == ev_mouse)
  //    {
  //        // If we are invoked by setup to test the controls, save the
  //        // mouse speed so that we can display it on-screen.
  //        // Perform a low pass filter on this so that the thermometer
  //        // appears to move smoothly.
  //
  //        testcontrols_mousespeed = abs(ev->data2);
  //    }
  //
  //    // If the next/previous weapon keys are pressed, set the next_weapon
  //    // variable to change weapons when the next ticcmd is generated.
  //
  //    if (ev->type == ev_keydown && ev->data1 == key_prevweapon)
  //    {
  //        next_weapon = -1;
  //    }
  //    else if (ev->type == ev_keydown && ev->data1 == key_nextweapon)
  //    {
  //        next_weapon = 1;
  //    }
  //
  //    switch (ev->type)
  //    {
  //      case ev_keydown:
  //	if (ev->data1 == key_pause)
  //	{
  //	    sendpause = true;
  //	}
  //        else if (ev->data1 <NUMKEYS)
  //        {
  //	    gamekeydown[ev->data1] = true;
  //        }
  //
  //	return true;    // eat key down events
  //
  //      case ev_keyup:
  //	if (ev->data1 <NUMKEYS)
  //	    gamekeydown[ev->data1] = false;
  //	return false;   // always let key up events filter down
  //
  //      case ev_mouse:
  //        SetMouseButtons(ev->data1);
  //        mousex += ev->data2;
  //        mousey += ev->data3;
  //	return true;    // eat events
  //
  //      case ev_joystick:
  //        SetJoyButtons(ev->data1);
  //	joyxmove = ev->data2;
  //	joyymove = ev->data3;
  //        joystrafemove = ev->data4;
  //        joylook = ev->data5;
  //	return true;    // eat events
  //
  //      default:
  //	break;
  //    }


End;

// [crispy] holding down the "Run" key may trigger special behavior,
// e.g. quick exit, clean screenshots, resurrection from savegames

Function speedkeydown(): boolean;
Begin
  // TODO: Fehlt noch
//   return (key_speed < NUMKEYS && gamekeydown[key_speed]) ||
//           (joybspeed < MAX_JOY_BUTTONS && joybuttons[joybspeed]) ||
//           (mousebspeed < MAX_MOUSE_BUTTONS && mousebuttons[mousebspeed]);
  result := false;
End;

Procedure G_InitNew(skill: skill_t; episode: int; map: int);
Begin
  //  const char *skytexturename;
  //    int             i;
  //    // [crispy] make sure "fast" parameters are really only applied once
  //    static boolean fast_applied;
  //
  //    if (paused)
  //    {
  //	paused = false;
  //	S_ResumeSound ();
  //    }
  //
  //    /*
  //    // Note: This commented-out block of code was added at some point
  //    // between the DOS version(s) and the Doom source release. It isn't
  //    // found in disassemblies of the DOS version and causes IDCLEV and
  //    // the -warp command line parameter to behave differently.
  //    // This is left here for posterity.
  //
  //    // This was quite messy with SPECIAL and commented parts.
  //    // Supposedly hacks to make the latest edition work.
  //    // It might not work properly.
  //    if (episode < 1)
  //      episode = 1;
  //
  //    if ( gamemode == retail )
  //    {
  //      if (episode > 4)
  //	episode = 4;
  //    }
  //    else if ( gamemode == shareware )
  //    {
  //      if (episode > 1)
  //	   episode = 1;	// only start episode 1 on shareware
  //    }
  //    else
  //    {
  //      if (episode > 3)
  //	episode = 3;
  //    }
  //    */
  //
  //    if (skill > sk_nightmare)
  //	skill = sk_nightmare;
  //
  //  // [crispy] if NRFTL is not available, "episode 2" may mean The Master Levels ("episode 3")
  //  if (gamemode == commercial)
  //  {
  //    if (episode < 1)
  //      episode = 1;
  //    else
  //    if (episode == 2 && !crispy->havenerve)
  //      episode = crispy->havemaster ? 3 : 1;
  //  }
  //
  //  // [crispy] only fix episode/map if it doesn't exist
  //  if (P_GetNumForMap(episode, map, false) < 0)
  //  {
  //    if (gameversion >= exe_ultimate)
  //    {
  //        if (episode == 0)
  //        {
  //            episode = 4;
  //        }
  //    }
  //    else
  //    {
  //        if (episode < 1)
  //        {
  //            episode = 1;
  //        }
  //        if (episode > 3)
  //        {
  //            episode = 3;
  //        }
  //    }
  //
  //    if (episode > 1 && gamemode == shareware)
  //    {
  //        episode = 1;
  //    }
  //
  //    if (map < 1)
  //	map = 1;
  //
  //    if ( (map > 9)
  //	 && ( gamemode != commercial) )
  //    {
  //      // [crispy] support E1M10 "Sewers"
  //      if (!crispy->havee1m10 || episode != 1)
  //      map = 9;
  //      else
  //      map = 10;
  //    }
  //  }
  //
  //    M_ClearRandom ();
  //
  //    // [crispy] Spider Mastermind gets increased health in Sigil II. Normally
  //    // the Sigil II DEH handles this, but we don't load the DEH if the WAD gets
  //    // sideloaded.
  //    if (crispy->havesigil2 && crispy->havesigil2 != (char *)-1)
  //    {
  //        mobjinfo[MT_SPIDER].spawnhealth = (episode == 6) ? 9000 : 3000;
  //    }
  //
  //    if (skill == sk_nightmare || respawnparm )
  //	respawnmonsters = true;
  //    else
  //	respawnmonsters = false;
  //
  //    // [crispy] make sure "fast" parameters are really only applied once
  //    if ((fastparm || skill == sk_nightmare) && !fast_applied)
  //    {
  //	for (i=S_SARG_RUN1 ; i<=S_SARG_PAIN2 ; i++)
  //	    // [crispy] Fix infinite loop caused by Demon speed bug
  //	    if (states[i].tics > 1)
  //	    {
  //	    states[i].tics >>= 1;
  //	    }
  //	mobjinfo[MT_BRUISERSHOT].speed = 20*FRACUNIT;
  //	mobjinfo[MT_HEADSHOT].speed = 20*FRACUNIT;
  //	mobjinfo[MT_TROOPSHOT].speed = 20*FRACUNIT;
  //	fast_applied = true;
  //    }
  //    else if (!fastparm && skill != sk_nightmare && fast_applied)
  //    {
  //	for (i=S_SARG_RUN1 ; i<=S_SARG_PAIN2 ; i++)
  //	    states[i].tics <<= 1;
  //	mobjinfo[MT_BRUISERSHOT].speed = 15*FRACUNIT;
  //	mobjinfo[MT_HEADSHOT].speed = 10*FRACUNIT;
  //	mobjinfo[MT_TROOPSHOT].speed = 10*FRACUNIT;
  //	fast_applied = false;
  //    }
  //
  //    // force players to be initialized upon first level load
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //	players[i].playerstate = PST_REBORN;
  //
  //    usergame = true;                // will be set false if a demo
  //    paused = false;
  //    demoplayback = false;
  //    automapactive = false;
  //    viewactive = true;
  //    gameepisode = episode;
  //    gamemap = map;
  //    gameskill = skill;
  //
  //    // [crispy] CPhipps - total time for all completed levels
  //    totalleveltimes = 0;
  //    defdemotics = 0;
  //    demostarttic = gametic; // [crispy] fix revenant internal demo bug
  //
  //    // Set the sky to use.
  //    //
  //    // Note: This IS broken, but it is how Vanilla Doom behaves.
  //    // See http://doomwiki.org/wiki/Sky_never_changes_in_Doom_II.
  //    //
  //    // Because we set the sky here at the start of a game, not at the
  //    // start of a level, the sky texture never changes unless we
  //    // restore from a saved game.  This was fixed before the Doom
  //    // source release, but this IS the way Vanilla DOS Doom behaves.
  //
  //    if (gamemode == commercial)
  //    {
  //        skytexturename = DEH_String("SKY3");
  //        skytexture = R_TextureNumForName(skytexturename);
  //        if (gamemap < 21)
  //        {
  //            skytexturename = DEH_String(gamemap < 12 ? "SKY1" : "SKY2");
  //            skytexture = R_TextureNumForName(skytexturename);
  //        }
  //    }
  //    else
  //    {
  //        switch (gameepisode)
  //        {
  //          default:
  //          case 1:
  //            skytexturename = "SKY1";
  //            break;
  //          case 2:
  //            skytexturename = "SKY2";
  //            break;
  //          case 3:
  //            skytexturename = "SKY3";
  //            break;
  //          case 4:        // Special Edition sky
  //            skytexturename = "SKY4";
  //            break;
  //          case 5:        // [crispy] Sigil
  //            skytexturename = "SKY5_ZD";
  //            if (R_CheckTextureNumForName(DEH_String(skytexturename)) == -1)
  //            {
  //                skytexturename = "SKY3";
  //            }
  //            break;
  //          case 6:        // [crispy] Sigil II
  //            skytexturename = "SKY6_ZD";
  //            if (R_CheckTextureNumForName(DEH_String(skytexturename)) == -1)
  //            {
  //                skytexturename = "SKY3";
  //            }
  //            break;
  //        }
  //        skytexturename = DEH_String(skytexturename);
  //        skytexture = R_TextureNumForName(skytexturename);
  //    }
  //
  //    G_DoLoadLevel ();
End;

End.

