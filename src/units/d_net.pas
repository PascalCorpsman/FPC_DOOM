Unit d_net;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure D_CheckNetGame();

Implementation

Uses
  m_Menu
  , d_loop, d_main
  ;

Const
  doom_loop_interface: loop_interface_t = (
    ProcessEvents: @D_ProcessEvents;
    //   BuildTiccmd: @G_BuildTiccmd;
    //   RunTic: @RunTic;
    RunMenu: @M_Ticker
    )
  ;

  //
  // D_CheckNetGame
  // Works out player numbers among the net participants
  //

Procedure D_CheckNetGame();
//Var
//  settings: net_gamesettings_t;
Begin

  //    if (netgame)
  //    {
  //        autostart = true;
  //    }

  D_RegisterLoopCallbacks(@doom_loop_interface);

  //    SaveGameSettings(&settings);
  //    D_StartNetGame(&settings, NULL);
  //    LoadGameSettings(&settings);
  //
  //    DEH_printf("startskill %i  deathmatch: %i  startmap: %i  startepisode: %i\n",
  //               startskill, deathmatch, startmap, startepisode);
  //
  //    DEH_printf("player %i of %i (%i nodes)\n",
  //               consoleplayer+1, settings.num_players, settings.num_players);
  //
  //    // Show players here; the server might have specified a time limit
  //
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

