Unit d_net;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure D_CheckNetGame();

Implementation

Uses
  doomstat, doomdef
  , d_loop, d_main
  , g_game
  , m_Menu, m_argv
  , net_defs
  ;


// Load game settings from the specified structure and
// set global variables.

Procedure LoadGameSettings(Const settings: net_gamesettings_t);
Var
  i: unsigned_int;
Begin
  deathmatch := settings.deathmatch;
  startepisode := settings.episode;
  startmap := settings.map;
  startskill := settings.skill;
  startloadgame := settings.loadgame;
  lowres_turn := settings.lowres_turn;
  nomonsters := settings.nomonsters;
  fastparm := settings.fast_monsters;
  respawnparm := settings.respawn_monsters;
  timelimit := settings.timelimit;
  consoleplayer := settings.consoleplayer;

  If (lowres_turn) Then Begin
    Writeln('NOTE: Turning resolution is reduced; this is probably ' +
      'because there is a client recording a Vanilla demo.');
  End;
  For i := 0 To MAXPLAYERS - 1 Do Begin
    playeringame[i] := i < settings.num_players;
  End;
End;

// Save the game settings from global variables to the specified
// game settings structure.

Procedure SaveGameSettings(Out settings: net_gamesettings_t);
Begin
  // Fill in game settings structure with appropriate parameters
  // for the new game

  settings.deathmatch := deathmatch;
  settings.episode := startepisode;
  settings.map := startmap;
  settings.skill := startskill;
  settings.loadgame := startloadgame;
  settings.gameversion := gameversion;
  settings.nomonsters := nomonsters;
  settings.fast_monsters := fastparm;
  settings.respawn_monsters := respawnparm;
  settings.timelimit := timelimit;

  settings.lowres_turn := (M_ParmExists('-record') And (Not M_ParmExists('-longtics')))
    Or M_ParmExists('-shorttics');
End;


Procedure RunTic({ticcmd_t *cmds, boolean *ingame});
Begin

  //    unsigned int i;
  //
  //    // Check for player quits.
  //
  //    for (i = 0; i < MAXPLAYERS; ++i)
  //    {
  //        if (!demoplayback && playeringame[i] && !ingame[i])
  //        {
  //            PlayerQuitGame(&players[i]);
  //        }
  //    }
  //
  //    netcmds = cmds;

  // check that there are players in the game.  if not, we cannot
  // run a tic.

  If (advancedemo) Then D_DoAdvanceDemo();

  G_Ticker();
End;

Const
  doom_loop_interface: loop_interface_t = (
    ProcessEvents: @D_ProcessEvents;
    BuildTiccmd: @G_BuildTiccmd;
    RunTic: @RunTic;
    RunMenu: @M_Ticker
    )
  ;


  //
  // D_CheckNetGame
  // Works out player numbers among the net participants
  //

Procedure D_CheckNetGame();
Var
  settings: net_gamesettings_t;
Begin

  If (netgame) Then Begin
    autostart := true;
  End;

  D_RegisterLoopCallbacks(@doom_loop_interface);

  SaveGameSettings(settings);
  D_StartNetGame(settings, Nil);
  LoadGameSettings(settings);

  writeln(format('startskill %d  deathmatch: %d  startmap: %d  startepisode: %d',
    [int(startskill), deathmatch, startmap, startepisode]));

  writeln(format('player %d of %d (%d nodes)',
    [consoleplayer + 1, settings.num_players, settings.num_players]));

  // Show players here; the server might have specified a time limit

//    if (timelimit > 0 && deathmatch)
//    {
//        // Gross hack to work like Vanilla:
//
//        if (timelimit == 20 && M_CheckParm("-avg"))
//        {
//            DEH_printf("Austin Virtual Gaming: Levels will end "
//                           "after 20 minutes\n");
//        }
//        else
//        {
//            DEH_printf("Levels will end after %d minute", timelimit);
//            if (timelimit > 1)
//                printf("s");
//            printf(".\n");
//        }
//    }
End;

End.

