Unit g_game;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef, info_types
  , d_event, d_mode, d_ticcmd, d_player
  ;

Const
  DEMOMARKER = $80;

Var
  netdemo: boolean;
  timelimit: int;

  nodrawers: boolean = false; // for comparative timing purposes
  gamestate: gamestate_t;
  gameaction: gameaction_t = ga_nothing;
  gamemap: int;
  gameepisode: int;
  gameskill: skill_t;
  demorecording: Boolean;
  demoplayback: boolean = false;

  // [crispy] demo progress bar and timer widget
  defdemotics: int = 0;
  deftotaldemotics: int;
  // [crispy] moved here
  defdemoname: String;

  paused: int; //
  sendsave: boolean; // send a save event next tic
  sendpause: Boolean; // send a pause event next tic
  usergame: boolean; // ok to save / end game

  viewactive: boolean;
  singledemo: boolean = false; // quit after playing a demo from cmdline
  netgame: boolean; // only true if packets are broadcast

  lowres_turn: boolean; // low resolution turning for longtics
  playeringame: Array[0..MAXPLAYERS - 1] Of boolean;

  // 0=Cooperative; 1=Deathmatch; 2=Altdeath
  deathmatch: int;

  // Player taking events, and displaying.
  consoleplayer: int;
  secretexit: boolean;
  wminfo: wbstartstruct_t; // parms for world map / intermission
  players: Array[0..MAXPLAYERS - 1] Of player_t;

  savedleveltime: int = 0; // [crispy] moved here for level time logging
  totalleveltimes: int; // [crispy] CPhipps - total time for all completed levels
  bodyqueslot: int;
  demo_gotonextlvl: boolean;

  timingdemo: boolean = false; // if true, exit with report on completion
  totalkills, totalitems, totalsecret: int; // for intermission
  displayplayer: int; // view being displayed

  precache: boolean = true; // if true, load all graphics at start

Procedure G_Ticker();
Function G_Responder(Const ev: Pevent_t): boolean;

Function speedkeydown(): boolean;

Procedure G_InitNew(skill: skill_t; episode: int; map: int);

Procedure G_BuildTiccmd(Var cmd: ticcmd_t; maketic: int);

// Can be called by the startup code or M_Responder.
// A normal game starts at map 1,
// but a warp test can start elsewhere
Procedure G_DeferedInitNew(skill: skill_t; episode: int; map: int);

Procedure G_ExitLevel();

Procedure G_DemoGotoNextLevel(start: Boolean);
Function G_CheckDemoStatus(): boolean;
Procedure G_PlayerReborn(player: int);
Procedure G_DeathMatchSpawnPlayer(playernum: int);

Implementation

Uses
  doomdata, doomstat, info, sounds, deh_misc, doomkey
  , am_map
  , d_main, d_loop, d_net
  , i_video, i_timer
  , hu_stuff
  , m_menu, m_argv, m_random, m_fixed, m_controls
  , net_defs
  , p_setup, p_mobj, p_inter, p_tick
  , r_data, r_sky, r_main
  , s_sound, st_stuff
  ;

Const
  NUMKEYS = 256;
  SLOWTURNTICS = 6;

  forwardmove: Array[0..1] Of fixed_t = ($19, $32);
  sidemove: Array[0..1] Of fixed_t = ($18, $28);
  angleturn: Array[0..2] Of fixed_t = (640, 1280, 320); // + slow turn

  // [crispy] for rounding error
Type
  carry_t = Record
    angle: double;
    pitch: double;
    side: double;
    vert: double;
  End;

Var
  d_skill: skill_t;
  d_episode: int;
  d_map: int;
  savename: String;
  respawnmonsters: boolean = false;

  turbodetected: Array[0..MAXPLAYERS - 1] Of boolean;

  demostarttic: int; // [crispy] fix revenant internal demo bug
  levelstarttic: int; // gametic at level start

  gamekeydown: Array[0..NUMKEYS - 1] Of boolean;
  turnheld: int; // for accelerative turning
  prevcarry, carry: carry_t;

  // Set to -1 or +1 to switch to the previous or next weapon.
  next_weapon: int = 0;

  oldgamestate: gamestate_t; // WTF: die gibt es in D_Display auch als Static variable ...

Procedure G_ClearSavename();
Begin
  savename := '';
End;

Procedure G_ReadGameParms();
Begin
  respawnparm := M_CheckParm('-respawn') <> 0;
  fastparm := M_CheckParm('-fast') <> 0;
  nomonsters := M_CheckParm('-nomonsters') <> 0;
End;

//
// G_CheckSpot
// Returns false if the player cannot be respawned
// at the given mapthing_t spot
// because something is occupying it
//

Function G_CheckSpot(playernum: int; Const mthing: mapthing_t): boolean;
Begin
  //    fixed_t		x;
  //    fixed_t		y;
  //    subsector_t*	ss;
  //    mobj_t*		mo;
  //    int			i;
  //
  //    if (!players[playernum].mo)
  //    {
  //	// first spawn of level, before corpses
  //	for (i=0 ; i<playernum ; i++)
  //	    if (players[i].mo->x == mthing->x << FRACBITS
  //		&& players[i].mo->y == mthing->y << FRACBITS)
  //		return false;
  //	return true;
  //    }
  //
  //    x = mthing->x << FRACBITS;
  //    y = mthing->y << FRACBITS;
  //
  //    if (!P_CheckPosition (players[playernum].mo, x, y) )
  //	return false;
  //
  //    // flush an old corpse if needed
  //    if (bodyqueslot >= BODYQUESIZE)
  //	P_RemoveMobj (bodyque[bodyqueslot%BODYQUESIZE]);
  //    bodyque[bodyqueslot%BODYQUESIZE] = players[playernum].mo;
  //    bodyqueslot++;
  //
  //    // spawn a teleport fog
  //    ss = R_PointInSubsector (x,y);
  //
  //
  //    // The code in the released source looks like this:
  //    //
  //    //    an = ( ANG45 * (((unsigned int) mthing->angle)/45) )
  //    //         >> ANGLETOFINESHIFT;
  //    //    mo = P_SpawnMobj (x+20*finecosine[an], y+20*finesine[an]
  //    //                     , ss->sector->floorheight
  //    //                     , MT_TFOG);
  //    //
  //    // But 'an' can be a signed value in the DOS version. This means that
  //    // we get a negative index and the lookups into finecosine/finesine
  //    // end up dereferencing values in finetangent[].
  //    // A player spawning on a deathmatch start facing directly west spawns
  //    // "silently" with no spawn fog. Emulate this.
  //    //
  //    // This code is imported from PrBoom+.
  //
  //    {
  //        fixed_t xa, ya;
  //        signed int an;
  //
  //        // This calculation overflows in Vanilla Doom, but here we deliberately
  //        // avoid integer overflow as it is undefined behavior, so the value of
  //        // 'an' will always be positive.
  //        an = (ANG45 >> ANGLETOFINESHIFT) * ((signed int) mthing->angle / 45);
  //
  //        switch (an)
  //        {
  //            case 4096:  // -4096:
  //                xa = finetangent[2048];    // finecosine[-4096]
  //                ya = finetangent[0];       // finesine[-4096]
  //                break;
  //            case 5120:  // -3072:
  //                xa = finetangent[3072];    // finecosine[-3072]
  //                ya = finetangent[1024];    // finesine[-3072]
  //                break;
  //            case 6144:  // -2048:
  //                xa = finesine[0];          // finecosine[-2048]
  //                ya = finetangent[2048];    // finesine[-2048]
  //                break;
  //            case 7168:  // -1024:
  //                xa = finesine[1024];       // finecosine[-1024]
  //                ya = finetangent[3072];    // finesine[-1024]
  //                break;
  //            case 0:
  //            case 1024:
  //            case 2048:
  //            case 3072:
  //                xa = finecosine[an];
  //                ya = finesine[an];
  //                break;
  //            default:
  //                I_Error("G_CheckSpot: unexpected angle %d\n", an);
  //                xa = ya = 0;
  //                break;
  //        }
  //        mo = P_SpawnMobj(x + 20 * xa, y + 20 * ya,
  //                         ss->sector->floorheight, MT_TFOG);
  //    }
  //
  //    if (players[consoleplayer].viewz != 1)
  //	S_StartSound (mo, sfx_telept);	// don't start sound on first frame

  result := true;
End;

//
// G_DeathMatchSpawnPlayer
// Spawns a player at one of the random death match spots
// called at level load and each death
//

Procedure G_DeathMatchSpawnPlayer(playernum: int);
Begin
  //    int             i,j;
  //    int				selections;
  //
  //    selections = deathmatch_p - deathmatchstarts;
  //    if (selections < 4)
  //	I_Error ("Only %i deathmatch spots, 4 required", selections);
  //
  //    for (j=0 ; j<20 ; j++)
  //    {
  //	i = P_Random() % selections;
  //	if (G_CheckSpot (playernum, &deathmatchstarts[i]) )
  //	{
  //	    deathmatchstarts[i].type = playernum+1;
  //	    P_SpawnPlayer (&deathmatchstarts[i]);
  //	    return;
  //	}
  //    }
  //
  //    // no good spot, so the player will probably get stuck
  //    P_SpawnPlayer (&playerstarts[playernum]);
End;

//
// G_DoReborn
//

Procedure G_DoReborn(playernum: int);
Var
  i: int;
Begin
  If (Not netgame) Then Begin

    // [crispy] if the player dies and the game has been loaded or saved
    // in the mean time, reload that savegame instead of restarting the level
    // when "Run" is pressed upon resurrection
    If (true {crispy->singleplayer }) And (savename <> '') And (speedkeydown()) Then Begin
      gameaction := ga_loadgame;
    End
    Else Begin
      // reload the level from scratch
      gameaction := ga_loadlevel;
      G_ClearSavename();
    End;
  End
  Else Begin
    // respawn at the start

    // first dissasociate the corpse
   //	players[playernum].mo->player = NULL;

    // spawn at random spot if in death match
    If (deathmatch <> 0) Then Begin
      G_DeathMatchSpawnPlayer(playernum);
      exit;
    End;

    If (G_CheckSpot(playernum, playerstarts[playernum])) Then Begin
      P_SpawnPlayer(playerstarts[playernum]);
      exit;
    End;
    //
    //	// try to spawn at one of the other players spots
    //	for (i=0 ; i<MAXPLAYERS ; i++)
    //	{
    //	    if (G_CheckSpot (playernum, &playerstarts[i]) )
    //	    {
    //		playerstarts[i].type = playernum+1;	// fake as other player
    //		P_SpawnPlayer (&playerstarts[i]);
    //		playerstarts[i].type = i+1;		// restore
    //		return;
    //	    }
    //	    // he's going to be inside something.  Too bad.
    //	}
    //	P_SpawnPlayer (&playerstarts[playernum]);
  End;
End;

Procedure G_DoNewGame();
Begin
  demoplayback := false;
  netdemo := false;
  netgame := false;
  deathmatch := 0;
  // [crispy] reset game speed after demo fast-forward
  singletics := false;
  // WTF: warum nur 3 und nicht alle über 0 ?
  playeringame[1] := false;
  playeringame[2] := false;
  playeringame[3] := false;
  // [crispy] do not reset -respawn, -fast and -nomonsters parameters
  (*
  respawnparm = false;
  fastparm = false;
  nomonsters = false;
  *)
  consoleplayer := 0;
  G_InitNew(d_skill, d_episode, d_map);
  gameaction := ga_nothing;
End;


Procedure G_ReadDemoTiccmd(cmd: Pticcmd_t);
Begin
  //    if (*demo_p == DEMOMARKER)
  //    {
  //	last_cmd = cmd; // [crispy] remember last cmd to track joins
  //
  //	// end of demo data stream
  //	G_CheckDemoStatus ();
  //	return;
  //    }
  //
  //    // [crispy] if demo playback is quit by pressing 'q',
  //    // stay in the game, hand over controls to the player and
  //    // continue recording the demo under a different name
  //    if (gamekeydown[key_demo_quit] && singledemo && !netgame)
  //    {
  //	byte *actualbuffer = demobuffer;
  //	char *actualname = M_StringDuplicate(defdemoname);
  //
  //	gamekeydown[key_demo_quit] = false;
  //
  //	// [crispy] find a new name for the continued demo
  //	G_RecordDemo(actualname);
  //	free(actualname);
  //
  //	// [crispy] discard the newly allocated demo buffer
  //	Z_Free(demobuffer);
  //	demobuffer = actualbuffer;
  //
  //	last_cmd = cmd; // [crispy] remember last cmd to track joins
  //
  //	// [crispy] continue recording
  //	G_CheckDemoStatus();
  //	return;
  //    }
  //
  //    cmd->forwardmove = ((signed char)*demo_p++);
  //    cmd->sidemove = ((signed char)*demo_p++);
  //
  //    // If this is a longtics demo, read back in higher resolution
  //
  //    if (longtics)
  //    {
  //        cmd->angleturn = *demo_p++;
  //        cmd->angleturn |= (*demo_p++) << 8;
  //    }
  //    else
  //    {
  //        cmd->angleturn = ((unsigned char) *demo_p++)<<8;
  //    }
  //
  //    cmd->buttons = (unsigned char)*demo_p++;
End;


Procedure G_WriteDemoTiccmd(Const cmd: ticcmd_t);
Begin
  //    byte *demo_start;
  //
  //    if (gamekeydown[key_demo_quit])           // press q to end demo recording
  //	G_CheckDemoStatus ();
  //
  //    demo_start = demo_p;
  //
  //    *demo_p++ = cmd->forwardmove;
  //    *demo_p++ = cmd->sidemove;
  //
  //    // If this is a longtics demo, record in higher resolution
  //
  //    if (longtics)
  //    {
  //        *demo_p++ = (cmd->angleturn & 0xff);
  //        *demo_p++ = (cmd->angleturn >> 8) & 0xff;
  //    }
  //    else
  //    {
  //        *demo_p++ = cmd->angleturn >> 8;
  //    }
  //
  //    *demo_p++ = cmd->buttons;
  //
  //    // reset demo pointer back
  //    demo_p = demo_start;
  //
  //    if (demo_p > demoend - 16)
  //    {
  //        // [crispy] unconditionally disable savegame and demo limits
  //        /*
  //        if (vanilla_demo_limit)
  //        {
  //            // no more space
  //            G_CheckDemoStatus ();
  //            return;
  //        }
  //        else
  //        */
  //        {
  //            // Vanilla demo limit disabled: unlimited
  //            // demo lengths!
  //
  //            IncreaseDemoBuffer();
  //        }
  //    }
  //
  //    G_ReadDemoTiccmd (cmd);         // make SURE it is exactly the same
End;

//
// G_Ticker
// Make ticcmd_ts for the players.
//

Procedure G_Ticker();
Var
  i, buf: int;
  cmd: ^ticcmd_t;
Begin

  // do player reborns if needed
  For i := 0 To MAXPLAYERS - 1 Do Begin
    If (playeringame[i]) And (players[i].playerstate = PST_REBORN) Then Begin
      G_DoReborn(i);
    End;
  End;

  // do things to change the game state
  While (gameaction <> ga_nothing) Do Begin
    Case (gameaction) Of
      ga_loadlevel: Begin
          //	    G_DoLoadLevel ();
        End;
      ga_newgame: Begin
          // [crispy] re-read game parameters from command line
          G_ReadGameParms();
          G_DoNewGame();
        End;
      ga_loadgame: Begin
          //	    // [crispy] re-read game parameters from command line
          //	    G_ReadGameParms();
          //	    G_DoLoadGame ();
        End;
      ga_savegame: Begin
          //	    G_DoSaveGame ();
        End;
      ga_playdemo: Begin
          //	    G_DoPlayDemo ();
        End;
      ga_completed: Begin
          //	    G_DoCompleted ();
        End;
      ga_victory: Begin
          //	    F_StartFinale ();
        End;
      ga_worlddone: Begin
          //	    G_DoWorldDone ();
        End;
      ga_screenshot: Begin
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
          gameaction := ga_nothing;
        End;
      ga_nothing: Begin
        End;
    End;
  End;

  // [crispy] demo sync of revenant tracers and RNG (from prboom-plus)
  If ((paused And 2) <> 0) Or ((Not demoplayback) And menuactive And (Not netgame)) Then Begin
    demostarttic := demostarttic + 1;
  End
  Else Begin
    // get commands, check consistancy,
    // and build new consistancy check
    buf := (gametic Div ticdup) Mod BACKUPTICS;
    For i := 0 To MAXPLAYERS - 1 Do Begin
      If (playeringame[i]) Then Begin
        cmd := @players[i].cmd;
        move(netcmds[i], cmd^, sizeof(ticcmd_t));
        If (demoplayback) Then Begin
          G_ReadDemoTiccmd(cmd);
        End;
        // [crispy] do not record tics while still playing back in demo continue mode
        If (demorecording) And (Not demoplayback) Then
          G_WriteDemoTiccmd(cmd^);

        // check for turbo cheats

               // check ~ 4 seconds whether to display the turbo message.
               // store if the turbo threshold was exceeded in any tics
               // over the past 4 seconds.  offset the checking period
               // for each player so messages are not displayed at the
               // same time.

   //            if (cmd->forwardmove > TURBOTHRESHOLD)
   //            {
   //                turbodetected[i] = true;
   //            }

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
      End;
    End;

    // [crispy] increase demo tics counter
  //    if (demoplayback || demorecording)
  //    {
  //	    defdemotics++;
  //    }

    // check for special buttons
    For i := 0 To MAXPLAYERS - 1 Do Begin
      If (playeringame[i]) Then Begin
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
      End;
    End;
  End;

  // Have we just finished displaying an intermission screen?

//    if (oldgamestate == GS_INTERMISSION && gamestate != GS_INTERMISSION)
//    {
//        WI_End();
//    }

  oldgamestate := gamestate;
  oldleveltime := leveltime;

  //    // [crispy] no pause at intermission screen during demo playback
  //    // to avoid desyncs (from prboom-plus)
  //    if ((paused & 2 || (!demoplayback && menuactive && !netgame))
  //        && gamestate != GS_LEVEL)
  //    {
  //    return;
  //    }

  // do main actions
  Case (gamestate) Of
    GS_LEVEL: Begin
        P_Ticker();
        ST_Ticker();
        AM_Ticker();
        HU_Ticker();
      End;

    GS_INTERMISSION: Begin
        //	WI_Ticker ();
      End;

    GS_FINALE: Begin
        //	F_Ticker ();
      End;

    GS_DEMOSCREEN: Begin
        //	D_PageTicker ();
      End;
  End;
End;

//
// G_Responder
// Get info needed to make ticcmd_ts for the players.
//

Function G_Responder(Const ev: Pevent_t): boolean;
Begin
  result := false;
  // [crispy] demo pause (from prboom-plus)
  If (gameaction = ga_nothing) And (
    ((demoplayback) Or (gamestate = GS_DEMOSCREEN))) Then Begin
    If (ev^._type = ev_keydown) And (ev^.data1 = key_pause) Then Begin
      paused := paused Xor 2;
      If (paused <> 0) Then Begin
        S_PauseSound();
      End
      Else Begin
        S_ResumeSound();
      End;
      result := true;
      exit;
    End;
  End;

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
      If (Not menuactive) And (crispy.soundfix <> 0) Then Begin
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

  If (gamestate = GS_LEVEL) Then Begin
    //	if (HU_Responder (ev))
    //	    return true;	// chat ate the event
    //	if (ST_Responder (ev))
    //	    return true;	// status window ate it
    If (AM_Responder(ev)) Then Begin
      result := true; // automap ate it
      exit;
    End;
  End;

  If (gamestate = GS_FINALE) Then Begin
    //	if (F_Responder (ev))
    //	    return true;	// finale ate the event
  End;
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
  Case ev^._type Of
    ev_keydown: Begin
        If (ev^.data1 = key_pause) Then Begin
          sendpause := true;
        End
        Else If (ev^.data1 < NUMKEYS) Then Begin
          gamekeydown[ev^.data1] := true;
        End;
        result := true; // eat key down events
      End;
    ev_keyup: Begin
        If (ev^.data1 < NUMKEYS) Then Begin
          gamekeydown[ev^.data1] := false;
        End;
        result := false; // always let key up events filter down
      End;
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
  End;

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

//
// G_DoLoadLevel
//

Procedure G_DoLoadLevel();
Var
  skytexturename: String;
  i: int;
Begin
  // Set the sky map.
  // First thing, we have a dummy sky texture name,
  //  a flat. The data is in the WAD only because
  //  we look for an actual index, instead of simply
  //  setting one.

  skyflatnum := R_FlatNumForName(SKYFLATNAME);

  // The "Sky never changes in Doom II" bug was fixed in
  // the id Anthology version of doom2.exe for Final Doom.
  // [crispy] correct "Sky never changes in Doom II" bug
  If ((gamemode = commercial)) And ((gameversion = exe_final2) Or (gameversion = exe_chex) Or (true)) Then Begin
    If (gamemap < 12) Then Begin
      If ((gameepisode = 2) Or (gamemission = pack_nerve)) And (gamemap >= 4) And (gamemap <= 8) Then
        skytexturename := 'SKY3'
      Else
        skytexturename := 'SKY1';
    End
    Else If (gamemap < 21) Then Begin
      // [crispy] BLACKTWR (MAP25) and TEETH (MAP31 and MAP32)
      If ((gameepisode = 3) Or (gamemission = pack_master)) And (gamemap >= 19) Then
        skytexturename := 'SKY3'
      Else Begin
        // [crispy] BLOODSEA and MEPHISTO (both MAP07)
        If ((gameepisode = 3) Or (gamemission = pack_master)) And ((gamemap = 14) Or (gamemap = 15)) Then
          skytexturename := 'SKY1'
        Else
          skytexturename := 'SKY2';
      End;
    End
    Else Begin
      skytexturename := 'SKY3';
    End;
    skytexture := R_TextureNumForName(skytexturename);
  End;

  // [crispy] sky texture scales
  R_InitSkyMap();

  levelstarttic := gametic; // for time calculation

  If (wipegamestate = GS_LEVEL) Then Begin
    wipegamestate := GS_NEG_1; // force a wipe
  End;
  gamestate := GS_LEVEL;

  For i := 0 To MAXPLAYERS - 1 Do Begin
    turbodetected[i] := false;
    If (playeringame[i]) And (players[i].playerstate = PST_DEAD) Then Begin
      players[i].playerstate := PST_REBORN;
    End;
    FillChar(players[i].frags[0], SizeOf(players[i].frags), 0);
  End;

  // [crispy] update the "singleplayer" variable
  CheckCrispySingleplayer(Not demorecording And Not demoplayback And Not netgame);

  //    // [crispy] double ammo
  //    if (crispy->moreammo && !crispy->singleplayer)
  //    {
  //        const char message[] = "The -doubleammo option is not supported"
  //                               " for demos and\n"
  //                               " network play.";
  //        if (!demo_p) demorecording = false;
  //        I_Error(message);
  //    }

  // [crispy] pistol start
  //    if (crispy->pistolstart)
  //    {
  //        if (crispy->singleplayer)
  //        {
  //            G_PlayerReborn(0);
  //        }
  //        else if ((demoplayback || netdemo) && !singledemo)
  //        {
  //            // no-op - silently ignore pistolstart when playing demo from the
  //            // demo reel
  //        }
  //        else
  //        {
  //            const char message[] = "The -pistolstart option is not supported"
  //                                   " for demos and\n"
  //                                   " network play.";
  //            if (!demo_p) demorecording = false;
  //            I_Error(message);
  //        }
  //    }

  P_SetupLevel(gameepisode, gamemap, 0, gameskill);
  displayplayer := consoleplayer; // view the guy you are playing
  gameaction := ga_nothing;
  // Z_CheckHeap();

  // clear cmd building stuff
  FillChar(gamekeydown[0], sizeof(gamekeydown), 0);

  //    joyxmove = joyymove = joystrafemove = joylook = 0;
  //    mousex = mousey = 0;
  //    memset(&localview, 0, sizeof(localview)); // [crispy]
  //    memset(&carry, 0, sizeof(carry)); // [crispy]
  //    memset(&prevcarry, 0, sizeof(prevcarry)); // [crispy]
  //    memset(&basecmd, 0, sizeof(basecmd)); // [crispy]
  sendpause := false;
  sendsave := false;
  paused := 0;
  //    memset(mousearray, 0, sizeof(mousearray));
  //    memset(joyarray, 0, sizeof(joyarray));
  R_SetGoobers(false);

  // [crispy] jff 4/26/98 wake up the status bar in case were coming out of a DM demo
  // [crispy] killough 5/13/98: in case netdemo has consoleplayer other than green
  ST_Start();
  HU_Start();
  //
  //    if (testcontrols)
  //    {
  //        players[consoleplayer].message = "Press escape to quit.";
  //    }
End;

Procedure G_InitNew(skill: skill_t; episode: int; map: int);

// [crispy] make sure "fast" parameters are really only applied once
Const
  fast_applied: boolean = false;

Var
  skytexturename: String;
  i: int;
Begin

  If (paused <> 0) Then Begin
    paused := 0;
    S_ResumeSound();
  End;

  (*
  // Note: This commented-out block of code was added at some point
  // between the DOS version(s) and the Doom source release. It isn't
  // found in disassemblies of the DOS version and causes IDCLEV and
  // the -warp command line parameter to behave differently.
  // This is left here for posterity.

  // This was quite messy with SPECIAL and commented parts.
  // Supposedly hacks to make the latest edition work.
  // It might not work properly.
  If (episode < 1) Then episode := 1;

  If (gamemode = retail) Then Begin
    If (episode > 4) Then episode := 4;
  End
  Else If (gamemode = shareware) Then Begin
    If (episode > 1) Then episode := 1; // only start episode 1 on shareware
  End
  Else Begin
    If (episode > 3) Then episode := 3;
  End;
  // *)

  If (skill > sk_nightmare) Then Begin
    skill := sk_nightmare;
  End;

  // [crispy] if NRFTL is not available, "episode 2" may mean The Master Levels ("episode 3")
  If (gamemode = commercial) Then Begin
    If (episode < 1) Then Begin
      episode := 1;
    End
    Else Begin
      //      if (episode == 2 && !crispy->havenerve)
      //            episode = crispy->havemaster ? 3 : 1;
    End;
  End;

  // [crispy] only fix episode/map if it doesn't exist
  If (P_GetNumForMap(episode, map, false) < 0) Then Begin
    If (gameversion >= exe_ultimate) Then Begin
      If (episode = 0) Then episode := 4;
    End
    Else Begin
      If (episode < 1) Then episode := 1;
      If (episode > 3) Then episode := 3;
    End;
    If (episode > 1) And (gamemode = shareware) Then episode := 1;

    If (map < 1) Then map := 1;

    If ((map > 9) And (gamemode <> commercial)) Then Begin
      // [crispy] support E1M10 "Sewers"
      //      if (!crispy->havee1m10 || episode != 1)
      //      map = 9;
      //      else
      //      map = 10;
    End;
  End;

  M_ClearRandom();

  // [crispy] Spider Mastermind gets increased health in Sigil II. Normally
  // the Sigil II DEH handles this, but we don't load the DEH if the WAD gets
  // sideloaded.
//    if (crispy->havesigil2 && crispy->havesigil2 != (char *)-1)
//    {
//        mobjinfo[MT_SPIDER].spawnhealth = (episode == 6) ? 9000 : 3000;
//    }

  If (skill = sk_nightmare) Or (respawnparm) Then
    respawnmonsters := true
  Else
    respawnmonsters := false;

  // [crispy] make sure "fast" parameters are really only applied once
  If ((fastparm) Or (skill = sk_nightmare)) And (Not fast_applied) Then Begin
    For i := integer(S_SARG_RUN1) To integer(S_SARG_PAIN2) - 1 Do Begin
      // [crispy] Fix infinite loop caused by Demon speed bug
      If (states[i].tics > 1) Then Begin
        states[i].tics := states[i].tics Shr 1;
      End;
    End;
    mobjinfo[integer(MT_BRUISERSHOT)].speed := 20 * FRACUNIT;
    mobjinfo[integer(MT_HEADSHOT)].speed := 20 * FRACUNIT;
    mobjinfo[integer(MT_TROOPSHOT)].speed := 20 * FRACUNIT;
    fast_applied := true;
  End
  Else If (Not fastparm) And (skill <> sk_nightmare) And (fast_applied) Then Begin
    For i := integer(S_SARG_RUN1) To integer(S_SARG_PAIN2) - 1 Do Begin
      states[i].tics := states[i].tics Shl 1;
    End;
    mobjinfo[integer(MT_BRUISERSHOT)].speed := 15 * FRACUNIT;
    mobjinfo[integer(MT_HEADSHOT)].speed := 10 * FRACUNIT;
    mobjinfo[integer(MT_TROOPSHOT)].speed := 10 * FRACUNIT;
    fast_applied := false;
  End;

  // force players to be initialized upon first level load
  For i := 0 To MAXPLAYERS - 1 Do Begin
    players[i].playerstate := PST_REBORN;
  End;

  usergame := true; // will be set false if a demo
  paused := 0;
  demoplayback := false;
  automapactive := false;
  viewactive := true;
  gameepisode := episode;
  gamemap := map;
  gameskill := skill;

  // [crispy] CPhipps - total time for all completed levels
  totalleveltimes := 0;
  defdemotics := 0;
  demostarttic := gametic; // [crispy] fix revenant internal demo bug

  // Set the sky to use.
  //
  // Note: This IS broken, but it is how Vanilla Doom behaves.
  // See http://doomwiki.org/wiki/Sky_never_changes_in_Doom_II.
  //
  // Because we set the sky here at the start of a game, not at the
  // start of a level, the sky texture never changes unless we
  // restore from a saved game.  This was fixed before the Doom
  // source release, but this IS the way Vanilla DOS Doom behaves.

  If (gamemode = commercial) Then Begin

    skytexturename := 'SKY3';
    skytexture := R_TextureNumForName(skytexturename);
    If (gamemap < 21) Then Begin
      If gamemap < 12 Then Begin
        skytexturename := 'SKY1';
      End
      Else Begin
        skytexturename := 'SKY2';
      End;
      skytexture := R_TextureNumForName(skytexturename);
    End;
  End
  Else Begin
    Case (gameepisode) Of
      1: skytexturename := 'SKY1';
      2: skytexturename := 'SKY2';
      3: skytexturename := 'SKY3';
      4: skytexturename := 'SKY4'; // Special Edition sky
      5: Begin // [crispy] Sigil
          skytexturename := 'SKY5_ZD';
          If (R_CheckTextureNumForName(skytexturename) = -1) Then Begin
            skytexturename := 'SKY3';
          End;
        End;
      6: Begin // [crispy] Sigil II
          skytexturename := 'SKY6_ZD';
          If (R_CheckTextureNumForName(skytexturename) = -1) Then Begin
            skytexturename := 'SKY3';
          End;
        End;
    Else Begin
        skytexturename := 'SKY1';
      End;
    End;
    skytexture := R_TextureNumForName(skytexturename);
  End;

  G_DoLoadLevel();
End;

// [crispy] for carrying rounding error

Function CarryError(value: double; Var prevcarry: double; Var carry: double): int;
Var
  desired: double;
  actual: int;
Begin
  desired := value + prevcarry;
  actual := round(desired);
  carry := desired - actual;
  result := actual;
End;

Function CarryAngle(angle: double): short;
Begin
  If (lowres_turn) And (abs(angle + prevcarry.angle) < 128) Then Begin
    carry.angle := angle + prevcarry.angle;
    result := 0;
  End
  Else Begin
    result := CarryError(angle, prevcarry.angle, carry.angle);
  End;
End;

//
// G_BuildTiccmd
// Builds a ticcmd from all of the available inputs
// or reads it from the demo buffer.
// If recording a demo, write it out
//

Procedure G_BuildTiccmd(Var cmd: ticcmd_t; maketic: int);
Var
  i: int;
  strafe,
    bstrafe: boolean;
  speed: int;
  tspeed: int;
  lspeed: int;
  angle: int; // [crispy]
  //    short	mousex_angleturn; // [crispy]
  forward: int;
  side: int;
  look: int;

  player: ^player_t;

  playermessage: String; //    static char playermessage[48];
Begin
  angle := 0;
  player := @players[consoleplayer];

  //    // [crispy] For fast polling.
  //    G_PrepTiccmd();
  //    memcpy(cmd, &basecmd, sizeof(*cmd));
  //    memset(&basecmd, 0, sizeof(ticcmd_t));

  //    cmd->consistancy =
  //	consistancy[consoleplayer][maketic%BACKUPTICS];

  strafe := gamekeydown[key_strafe]
    // Or mousebuttons[mousebstrafe]
//  	|| joybuttons[joybstrafe]
  ;
  //
  //    // fraggle: support the old "joyb_speed = 31" hack which
  //    // allowed an autorun effect
  //
  //    // [crispy] when "always run" is active,
  //    // pressing the "run" key will result in walking
  speed := ord(key_speed >= NUMKEYS
    //         || joybspeed >= MAX_JOY_BUTTONS
    );
  speed := ord(odd(speed) Xor speedkeydown());

  forward := 0;
  side := 0;
  look := 0;

  // use two stage accelerative turning
  // on the keyboard and joystick
  If //(joyxmove < 0
  //	|| joyxmove > 0
  //	||
  gamekeydown[key_right]
    Or gamekeydown[key_left]
    //	|| mousebuttons[mousebturnright]
//	|| mousebuttons[mousebturnleft])
  Then Begin
    turnheld := turnheld + ticdup;
  End
  Else
    turnheld := 0;

  If (turnheld < SLOWTURNTICS) Then
    tspeed := 2 // slow turn
  Else
    tspeed := speed;

  //    // [crispy] use two stage accelerative looking
  //    if (gamekeydown[key_lookdown] || gamekeydown[key_lookup])
  //    {
  //        lookheld += ticdup;
  //    }
  //    else
  //    {
  //        lookheld = 0;
  //    }
  //    if (lookheld < SLOWTURNTICS)
  //    {
  //        lspeed = 1;
  //    }
  //    else
  //    {
  //        lspeed = 2;
  //    }
  //
  //    // [crispy] add quick 180° reverse
  //    if (gamekeydown[key_reverse] || mousebuttons[mousebreverse])
  //    {
  //        angle += ANG180 >> FRACBITS;
  //        gamekeydown[key_reverse] = false;
  //        mousebuttons[mousebreverse] = false;
  //    }
  //
  //    // [crispy] toggle "always run"
  //    if (gamekeydown[key_toggleautorun])
  //    {
  //        static int joybspeed_old = 2;
  //
  //        if (joybspeed >= MAX_JOY_BUTTONS)
  //        {
  //            joybspeed = joybspeed_old;
  //        }
  //        else
  //        {
  //            joybspeed_old = joybspeed;
  //            joybspeed = MAX_JOY_BUTTONS;
  //        }
  //
  //        M_snprintf(playermessage, sizeof(playermessage), "ALWAYS RUN %s%s",
  //            crstr[CR_GREEN],
  //            (joybspeed >= MAX_JOY_BUTTONS) ? "ON" : "OFF");
  //        player->message = playermessage;
  //        S_StartSoundOptional(NULL, sfx_mnusli, sfx_swtchn); // [NS] Optional menu sounds.
  //
  //        gamekeydown[key_toggleautorun] = false;
  //    }
  //
  //    // [crispy] Toggle vertical mouse movement
  //    if (gamekeydown[key_togglenovert])
  //    {
  //        novert = !novert;
  //
  //        M_snprintf(playermessage, sizeof(playermessage),
  //            "vertical mouse movement %s%s",
  //            crstr[CR_GREEN],
  //            !novert ? "ON" : "OFF");
  //        player->message = playermessage;
  //        S_StartSoundOptional(NULL, sfx_mnusli, sfx_swtchn); // [NS] Optional menu sounds.
  //
  //        gamekeydown[key_togglenovert] = false;
  //    }
  //
  //    // [crispy] extra high precision IDMYPOS variant, updates for 10 seconds
  //    if (player->powers[pw_mapcoords])
  //    {
  //        M_snprintf(playermessage, sizeof(playermessage),
  //            "X=%.10f Y=%.10f A=%d",
  //            (double)player->mo->x/FRACUNIT,
  //            (double)player->mo->y/FRACUNIT,
  //            player->mo->angle >> 24);
  //        player->message = playermessage;
  //
  //        player->powers[pw_mapcoords]--;
  //
  //        // [crispy] discard instead of going static
  //        if (!player->powers[pw_mapcoords])
  //        {
  //            player->message = "";
  //        }
  //    }

  // let movement keys cancel each other out
  If (strafe) Then Begin
    //        if (!cmd->angleturn)
    //        {
    //            if (gamekeydown[key_right] || mousebuttons[mousebturnright])
    //            {
    //                // fprintf(stderr, "strafe right\n");
    //                side += sidemove[speed];
    //            }
    //            if (gamekeydown[key_left] || mousebuttons[mousebturnleft])
    //            {
    //                //	fprintf(stderr, "strafe left\n");
    //                side -= sidemove[speed];
    //            }
    //            if (use_analog && joyxmove)
    //            {
    //                joyxmove = joyxmove * joystick_move_sensitivity / 10;
    //                joyxmove = BETWEEN(-FRACUNIT, FRACUNIT, joyxmove);
    //                side += FixedMul(sidemove[speed], joyxmove);
    //            }
    //            else if (joystick_move_sensitivity)
    //            {
    //                if (joyxmove > 0)
    //                    side += sidemove[speed];
    //                if (joyxmove < 0)
    //                    side -= sidemove[speed];
    //            }
    //        }
  End
  Else Begin
    If (gamekeydown[key_right] {|| mousebuttons[mousebturnright]}) Then
      angle := angle - angleturn[tspeed];
    If (gamekeydown[key_left] {|| mousebuttons[mousebturnleft]}) Then
      angle := angle + angleturn[tspeed];
    //        if (use_analog && joyxmove)
    //        {
    //            // Cubic response curve allows for finer control when stick
    //            // deflection is small.
    //            joyxmove = FixedMul(FixedMul(joyxmove, joyxmove), joyxmove);
    //            joyxmove = joyxmove * joystick_turn_sensitivity / 10;
    //            angle -= FixedMul(angleturn[1], joyxmove);
    //        }
    //        else if (joystick_turn_sensitivity)
    //        {
    //            if (joyxmove > 0)
    //                angle -= angleturn[tspeed];
    //            if (joyxmove < 0)
    //                angle += angleturn[tspeed];
    //        }
  End;

  //    if (gamekeydown[key_up] || gamekeydown[key_alt_up]) // [crispy] add key_alt_*
  //    {
  //	// fprintf(stderr, "up\n");
  //	forward += forwardmove[speed];
  //    }
  //    if (gamekeydown[key_down] || gamekeydown[key_alt_down]) // [crispy] add key_alt_*
  //    {
  //	// fprintf(stderr, "down\n");
  //	forward -= forwardmove[speed];
  //    }
  //
  //    if (use_analog && joyymove)
  //    {
  //        joyymove = joyymove * joystick_move_sensitivity / 10;
  //        joyymove = BETWEEN(-FRACUNIT, FRACUNIT, joyymove);
  //        forward -= FixedMul(forwardmove[speed], joyymove);
  //    }
  //    else if (joystick_move_sensitivity)
  //    {
  //        if (joyymove < 0)
  //            forward += forwardmove[speed];
  //        if (joyymove > 0)
  //            forward -= forwardmove[speed];
  //    }

  //    if (gamekeydown[key_strafeleft] || gamekeydown[key_alt_strafeleft] // [crispy] add key_alt_*
  //     || joybuttons[joybstrafeleft]
  //     || mousebuttons[mousebstrafeleft])
  //    {
  //        side -= sidemove[speed];
  //    }

  //    if (gamekeydown[key_straferight] || gamekeydown[key_alt_straferight] // [crispy] add key_alt_*
  //     || joybuttons[joybstraferight]
  //     || mousebuttons[mousebstraferight])
  //    {
  //        side += sidemove[speed];
  //    }

  //    if (use_analog && joystrafemove)
  //    {
  //        joystrafemove = joystrafemove * joystick_move_sensitivity / 10;
  //        joystrafemove = BETWEEN(-FRACUNIT, FRACUNIT, joystrafemove);
  //        side += FixedMul(sidemove[speed], joystrafemove);
  //    }
  //    else if (joystick_move_sensitivity)
  //    {
  //        if (joystrafemove < 0)
  //            side -= sidemove[speed];
  //        if (joystrafemove > 0)
  //            side += sidemove[speed];
  //    }

  //    // [crispy] look up/down/center keys
  //    if (crispy->freelook)
  //    {
  //        static unsigned int kbdlookctrl = 0;
  //
  //        if (gamekeydown[key_lookup])
  //        {
  //            look = lspeed;
  //            kbdlookctrl += ticdup;
  //        }
  //        else
  //        if (gamekeydown[key_lookdown])
  //        {
  //            look = -lspeed;
  //            kbdlookctrl += ticdup;
  //        }
  //        else
  //        if (joylook && joystick_look_sensitivity)
  //        {
  //            if (use_analog)
  //            {
  //                joylook = joylook * joystick_look_sensitivity / 10;
  //                joylook = BETWEEN(-FRACUNIT, FRACUNIT, joylook);
  //                look = -FixedMul(2, joylook);
  //            }
  //            else
  //            {
  //                if (joylook < 0)
  //                {
  //                    look = lspeed;
  //                }
  //
  //                if (joylook > 0)
  //                {
  //                    look = -lspeed;
  //                }
  //            }
  //            kbdlookctrl += ticdup;
  //        }
  //        else
  //        // [crispy] keyboard lookspring
  //        if (gamekeydown[key_lookcenter] || (crispy->freelook == FREELOOK_SPRING && kbdlookctrl))
  //        {
  //            look = TOCENTER;
  //            kbdlookctrl = 0;
  //        }
  //    }

  //    // [crispy] jump keys
  //    if (critical->jump)
  //    {
  //        if (gamekeydown[key_jump] || mousebuttons[mousebjump]
  //            || joybuttons[joybjump])
  //        {
  //            cmd->arti |= AFLAG_JUMP;
  //        }
  //    }

  //    // buttons
  //    cmd->chatchar = HU_dequeueChatChar();

  //    if (gamekeydown[key_fire] || mousebuttons[mousebfire]
  //	|| joybuttons[joybfire])
  //	cmd->buttons |= BT_ATTACK;

  //    if (gamekeydown[key_use]
  //     || joybuttons[joybuse]
  //     || mousebuttons[mousebuse])
  //    {
  //	cmd->buttons |= BT_USE;
  //	// clear double clicks if hit use button
  //	dclicks = 0;
  //    }

  //    // If the previous or next weapon button is pressed, the
  //    // next_weapon variable is set to change weapons when
  //    // we generate a ticcmd.  Choose a new weapon.
  //
  //    if (gamestate == GS_LEVEL && next_weapon != 0)
  //    {
  //        i = G_NextWeapon(next_weapon);
  //        cmd->buttons |= BT_CHANGE;
  //        cmd->buttons |= i << BT_WEAPONSHIFT;
  //    }
  //    else
  //    {
  //        // Check weapon keys.
  //
  //        for (i=0; i<arrlen(weapon_keys); ++i)
  //        {
  //            int key = *weapon_keys[i];
  //
  //            if (gamekeydown[key])
  //            {
  //                cmd->buttons |= BT_CHANGE;
  //                cmd->buttons |= i<<BT_WEAPONSHIFT;
  //                break;
  //            }
  //        }
  //    }

  next_weapon := 0;

  //    // mouse
  //    if (mousebuttons[mousebforward])
  //    {
  //	forward += forwardmove[speed];
  //    }
  //    if (mousebuttons[mousebbackward])
  //    {
  //        forward -= forwardmove[speed];
  //    }
  //
  //    if (dclick_use)
  //    {
  //        // forward double click
  //        if (mousebuttons[mousebforward] != dclickstate && dclicktime > 1 )
  //        {
  //            dclickstate = mousebuttons[mousebforward];
  //            if (dclickstate)
  //                dclicks++;
  //            if (dclicks == 2)
  //            {
  //                cmd->buttons |= BT_USE;
  //                dclicks = 0;
  //            }
  //            else
  //                dclicktime = 0;
  //        }
  //        else
  //        {
  //            dclicktime += ticdup;
  //            if (dclicktime > 20)
  //            {
  //                dclicks = 0;
  //                dclickstate = 0;
  //            }
  //        }
  //
  //        // strafe double click
  //        bstrafe =
  //            mousebuttons[mousebstrafe]
  //            || joybuttons[joybstrafe];
  //        if (bstrafe != dclickstate2 && dclicktime2 > 1 )
  //        {
  //            dclickstate2 = bstrafe;
  //            if (dclickstate2)
  //                dclicks2++;
  //            if (dclicks2 == 2)
  //            {
  //                cmd->buttons |= BT_USE;
  //                dclicks2 = 0;
  //            }
  //            else
  //                dclicktime2 = 0;
  //        }
  //        else
  //        {
  //            dclicktime2 += ticdup;
  //            if (dclicktime2 > 20)
  //            {
  //                dclicks2 = 0;
  //                dclickstate2 = 0;
  //            }
  //        }
  //    }
  //
  //    // [crispy] mouse look
  //    if ((crispy->freelook && mousebuttons[mousebmouselook]) ||
  //         crispy->mouselook)
  //    {
  //        const double vert = CalcMouseVert(mousey);
  //        cmd->lookdir += mouse_y_invert ? CarryPitch(-vert) : CarryPitch(vert);
  //    }
  //    else
  //    if (!novert)
  //    {
  //    forward += CarryMouseVert(CalcMouseVert(mousey));
  //    }
  //
  //    // [crispy] single click on mouse look button centers view
  //    if (crispy->freelook)
  //    {
  //        static unsigned int mbmlookctrl = 0;
  //
  //        // [crispy] single click view centering
  //        if (mousebuttons[mousebmouselook]) // [crispy] clicked
  //        {
  //            mbmlookctrl += ticdup;
  //        }
  //        else
  //        // [crispy] released
  //        if (mbmlookctrl)
  //        {
  //            if (crispy->freelook == FREELOOK_SPRING || mbmlookctrl < SLOWTURNTICS) // [crispy] short click
  //            {
  //                look = TOCENTER;
  //            }
  //            mbmlookctrl = 0;
  //        }
  //    }
  //
  //    if (strafe && !cmd->angleturn)
  //	side += CarryMouseSide(CalcMouseSide(mousex));
  //
  //    mousex_angleturn = cmd->angleturn;
  //
  //    if (mousex_angleturn == 0)
  //    {
  //        // No movement in the previous frame
  //
  //        testcontrols_mousespeed = 0;
  //    }
  //
  If (angle <> 0) Then Begin

    cmd.angleturn := CarryAngle(cmd.angleturn + angle);
    //        localview.ticangleturn = crispy->fliplevels ?
    //            (mousex_angleturn - cmd->angleturn) :
    //            (cmd->angleturn - mousex_angleturn);
  End;

  //    mousex = mousey = 0;

  //    if (forward > MAXPLMOVE)
  //	forward = MAXPLMOVE;
  //    else if (forward < -MAXPLMOVE)
  //	forward = -MAXPLMOVE;
  //    if (side > MAXPLMOVE)
  //	side = MAXPLMOVE;
  //    else if (side < -MAXPLMOVE)
  //	side = -MAXPLMOVE;

  //    cmd->forwardmove += forward;
  //    cmd->sidemove += side;

      // [crispy]
  localview.angle := 0;
  localview.rawangle := 0.0;
  //    prevcarry = carry;

      // [crispy] lookdir delta is stored in the lower 4 bits of the lookfly variable
  If (player^.playerstate = PST_LIVE) Then Begin
    If (look < 0) Then Begin
      look := look + 16;
    End;
    cmd.lookfly := look;
  End;

  //    // special buttons
  //    // [crispy] suppress pause when a new game is started
  //    if (sendpause && gameaction != ga_newgame)
  //    {
  //	sendpause = false;
  //	// [crispy] ignore un-pausing in menus during demo recording
  //	if (!(menuactive && demorecording && paused) && gameaction != ga_loadgame)
  //	{
  //	cmd->buttons = BT_SPECIAL | BTS_PAUSE;
  //	}
  //    }
  //
  //    if (sendsave)
  //    {
  //	sendsave = false;
  //	cmd->buttons = BT_SPECIAL | BTS_SAVEGAME | (savegameslot<<BTS_SAVESHIFT);
  //    }
  //
  //    if (crispy->fliplevels)
  //    {
  //	mousex_angleturn = -mousex_angleturn;
  //	cmd->angleturn = -cmd->angleturn;
  //	cmd->sidemove = -cmd->sidemove;
  //    }
  //
  //    // low-res turning
  //
  //    if (lowres_turn)
  //    {
  //        signed short desired_angleturn;
  //
  //        desired_angleturn = cmd->angleturn;
  //
  //        // round angleturn to the nearest 256 unit boundary
  //        // for recording demos with single byte values for turn
  //
  //        cmd->angleturn = (desired_angleturn + 128) & 0xff00;
  //
  //        if (angle)
  //        {
  //            localview.ticangleturn = cmd->angleturn - mousex_angleturn;
  //        }
  //
  //        // Carry forward the error from the reduced resolution to the
  //        // next tic, so that successive small movements can accumulate.
  //
  //        prevcarry.angle += crispy->fliplevels ?
  //                            cmd->angleturn - desired_angleturn :
  //                            desired_angleturn - cmd->angleturn;
  //    }
End;

(*
===================
=
= G_CheckDemoStatus
=
= Called after a death or level completion to allow demos to be cleaned up
= Returns true if a new demo loop action will take place
===================
*)

Function G_CheckDemoStatus(): boolean;
Begin
  //    int             endtime;
  //
  //    // [crispy] catch the last cmd to track joins
  //    ticcmd_t* cmd = last_cmd;
  //    last_cmd = NULL;
  //
  //    if (timingdemo)
  //    {
  //        float fps;
  //        int realtics;
  //
  //	endtime = I_GetTime ();
  //        realtics = endtime - starttime;
  //        fps = ((float) gametic * TICRATE) / realtics;
  //
  //        // Prevent recursive calls
  //        timingdemo = false;
  //        demoplayback = false;
  //
  //	I_Error ("timed %i gametics in %i realtics (%f fps)",
  //                 gametic, realtics, fps);
  //    }
  //
  //    if (demoplayback)
  //    {
  //        W_ReleaseLumpName(defdemoname);
  //	demoplayback = false;
  //	netdemo = false;
  //	netgame = false;
  //	deathmatch = false;
  //	playeringame[1] = playeringame[2] = playeringame[3] = 0;
  //	// [crispy] leave game parameters intact when continuing a demo
  //	if (!demorecording)
  //	{
  //	respawnparm = false;
  //	fastparm = false;
  //	nomonsters = false;
  //	}
  //	consoleplayer = 0;
  //
  //        // [crispy] in demo continue mode increase the demo buffer and
  //        // continue recording once we are done with playback
  //        if (demorecording)
  //        {
  //            demoend = demo_p;
  //            IncreaseDemoBuffer();
  //
  //            nodrawers = false;
  //            singletics = false;
  //
  //            // [crispy] start music for the current level
  //            if (gamestate == GS_LEVEL)
  //            {
  //                S_Start();
  //            }
  //
  //            // [crispy] record demo join
  //            if (cmd != NULL)
  //            {
  //                cmd->buttons |= BT_JOIN;
  //            }
  //
  //            return true;
  //        }
  //
  //        if (singledemo)
  //            I_Quit ();
  //        else
  //            D_AdvanceDemo ();
  //
  //	return true;
  //    }
  //
  //    if (demorecording)
  //    {
  //	boolean success;
  //	char *msg;
  //
  //	*demo_p++ = DEMOMARKER;
  //	G_AddDemoFooter();
  //	success = M_WriteFile (demoname, demobuffer, demo_p - demobuffer);
  //	msg = success ? "Demo %s recorded%c" : "Failed to record Demo %s%c";
  //	Z_Free (demobuffer);
  //	demorecording = false;
  //	// [crispy] if a new game is started during demo recording, start a new demo
  //	if (gameaction != ga_newgame)
  //	{
  //	    I_Error (msg, demoname, '\0');
  //	}
  //	else
  //	{
  //	    fprintf(stderr, msg, demoname, '\n');
  //	}
  //    }
  result := false;
End;


//
// G_InitNew
// Can be called by the startup code or the menu task,
// consoleplayer, displayplayer, playeringame[] should be set.
//

Procedure G_DeferedInitNew(skill: skill_t; episode: int; map: int);
Begin
  d_skill := skill;
  d_episode := episode;
  d_map := map;
  G_ClearSavename();
  gameaction := ga_newgame;

  // [crispy] if a new game is started during demo recording, start a new demo
  If (demorecording) Then Begin
    // [crispy] reset IDDT cheat when re-starting map during demo recording
    AM_ResetIDDTcheat();

    G_CheckDemoStatus();
    //    Z_Free(demoname);

    //    G_RecordDemo(orig_demoname);
    //    G_BeginRecording();
  End;
End;

Procedure G_ExitLevel();
Begin
  secretexit := false;
  G_ClearSavename();
  gameaction := ga_completed;
End;

Procedure G_DemoGotoNextLevel(start: Boolean);
Begin
  // disable screen rendering while fast forwarding
  nodrawers := start;

  // switch to fast tics running mode if not in -timedemo
  If (timingdemo) Then Begin
    singletics := start;
  End;
End;

//
// G_PlayerReborn
// Called after a player dies
// almost everything is cleared and initialized
//

Procedure G_PlayerReborn(player: int);
Var
  p: ^player_t;
  i: int;
  frags: Array[0..MAXPLAYERS - 1] Of int;
  killcount: int;
  itemcount: int;
  secretcount: int;
Begin
  move(players[player].frags[0], frags[0], sizeof(frags));
  killcount := players[player].killcount;
  itemcount := players[player].itemcount;
  secretcount := players[player].secretcount;

  p := @players[player];
  FillChar(p^, sizeof(player_t), 0);

  move(frags[0], players[player].frags[0], sizeof(frags));
  players[player].killcount := killcount;
  players[player].itemcount := itemcount;
  players[player].secretcount := secretcount;

  p^.usedown := true; // don't do anything immediately
  p^.attackdown := true; // don't do anything immediately
  p^.playerstate := PST_LIVE;
  p^.health := deh_initial_health; // Use dehacked value
  // [crispy] negative player health
  p^.neghealth := p^.health;
  p^.readyweapon := wp_pistol;
  p^.pendingweapon := wp_pistol;
  p^.weaponowned[wp_fist] := true;
  p^.weaponowned[wp_pistol] := true;
  p^.ammo[integer(am_clip)] := deh_initial_bullets;

  For i := 0 To integer(NUMAMMO) - 1 Do Begin
    p^.maxammo[i] := maxammo[i];
  End;
End;

End.

