Unit d_loop;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type
  TProcedure = Procedure();

  loop_interface_t = Record

    // Read events from the event queue, and process them.
    ProcessEvents: TProcedure;

    // Given the current input state, fill in the fields of the specified
    // ticcmd_t structure with data for a new tic.

//    void (*BuildTiccmd)(ticcmd_t *cmd, int maketic);

    // Advance the game forward one tic, using the specified player input.

//    void (*RunTic)(ticcmd_t *cmds, boolean *ingame);

    // Run the menu (runs independently of the game).

    RunMenu: TProcedure;
  End;

  Ploop_interface_t = ^loop_interface_t;

Var
  // The number of tics that have been run (using RunTic) so far.
  gametic: int;

Procedure TryRunTics();
Procedure D_RegisterLoopCallbacks(i: Ploop_interface_t);

Implementation

Uses net_client, net_defs;

Var
  // Current players in the multiplayer game.
  // This is distinct from playeringame[] used by the game code, which may
  // modify playeringame[] when playing back multiplayer demos.


  local_playeringame: Array[0..NET_MAXPLAYERS - 1] Of Boolean;

  // When set to true, a single tic is run each time TryRunTics() is called.
  // This is used for -timedemo mode.

  singletics: boolean = false;

  // Used for original sync code.

  skiptics: int = 0;

  // Reduce the bandwidth needed by sampling game input less and transmitting
  // less.  If ticdup is 2, sample half normal, 3 = one third normal, etc.

  ticdup: int;


  // Callback functions for loop code.

  loop_interface: Ploop_interface_t = Nil;

Procedure D_RegisterLoopCallbacks(i: Ploop_interface_t);
Begin
  loop_interface := i;
End;

Function BuildNewTic(): Boolean;
Begin
  //      int	gameticdiv;
  //      ticcmd_t cmd;
  //
  //      gameticdiv = gametic/ticdup;
  //
  //      I_StartTic ();
  loop_interface^.ProcessEvents();

  // Always run the menu

  loop_interface^.RunMenu();

  //      if (drone)
  //      {
  //          // In drone mode, do not generate any ticcmds.
  //
  //          return false;
  //      }
  //
  //      if (new_sync)
  //      {
  //         // If playing single player, do not allow tics to buffer
  //         // up very far
  //
  //         if (!net_client_connected && maketic - gameticdiv > 2)
  //             return false;
  //
  //         // Never go more than ~200ms ahead
  //
  //         if (maketic - gameticdiv > 8)
  //             return false;
  //      }
  //      else
  //      {
  //         if (maketic - gameticdiv >= 5)
  //             return false;
  //      }
  //
  //      //printf ("mk:%i ",maketic);
  //      memset(&cmd, 0, sizeof(ticcmd_t));
  //      loop_interface->BuildTiccmd(&cmd, maketic);
  //
  //      if (net_client_connected)
  //      {
  //          NET_CL_SendTiccmd(&cmd, maketic);
  //      }
  //
  //      ticdata[maketic % BACKUPTICS].cmds[localplayer] = cmd;
  //      ticdata[maketic % BACKUPTICS].ingame[localplayer] = true;
  //
  //      ++maketic;
  //
  result := true;
End;

//
// NetUpdate
// Builds ticcmds for console player,
// sends out a packet
//
Var
  lasttime: int;

Procedure NetUpdate();
Var
  newtics, nowtime, i: int;
Begin
  // If we are running with singletics (timing a demo), this
  // is all done separately.

  If (singletics) Then exit;


  // Run network subsystems

  // TODO: Das hier ist erst mal so deaktiviert, dass überhaupt irgendwas gemacht wird..

//    NET_CL_Run();
//    NET_SV_Run();

  // check time
//  nowtime := GetAdjustedTime() Div ticdup;
  newtics := nowtime - lasttime;

  lasttime := nowtime;

  If (skiptics <= newtics) Then Begin
    newtics := newtics - skiptics;
    skiptics := 0;
  End
  Else Begin
    skiptics := skiptics - newtics;
    newtics := 0;
  End;

  // build new ticcmds for console player
//  For i := 0 To newtics - 1 Do Begin
  If (Not BuildNewTic()) Then Begin
    //    break;
  End;
  //  End;
End;

// Returns true if there are players in the game:

Function PlayersInGame(): boolean;
Var
  i: integer;
Begin
  result := false;

  // If we are connected to a server, check if there are any players
  // in the game.

  If (net_client_connected) Then Begin
    For i := 0 To NET_MAXPLAYERS - 1
      Do Begin
      result := result Or local_playeringame[i];
    End;
  End;
  // Whether single or multi-player, unless we are running as a drone,
  // we are in the game.

  If (Not drone) Then Begin
    result := true;
  End;
End;

Procedure TryRunTics();
Begin
  //    int	i;
  //    int	lowtic;
  //    int	entertic;
  //    static int oldentertics;
  //    int realtics;
  //    int	availabletics;
  //    int	counts;
  //
  //    // [AM] If we've uncapped the framerate and there are no tics
  //    //      to run, return early instead of waiting around.
  //    extern int leveltime;
  //    #define return_early (crispy->uncapped && counts == 0 && leveltime > oldleveltime && screenvisible)
  //
  //    // get real tics
  //    entertic = I_GetTime() / ticdup;
  //    realtics = entertic - oldentertics;
  //    oldentertics = entertic;

      // in singletics mode, run a single tic every time this function
      // is called.

  If (singletics) Then Begin
    BuildNewTic();
  End
  Else Begin
    NetUpdate();
  End;

  //    lowtic = GetLowTic();

  //    availabletics = lowtic - gametic/ticdup;
  //
  //    // decide how many tics to run
  //
  //    if (new_sync)
  //    {
  //        if (crispy->uncapped)
  //        {
  //            // decide how many tics to run
  //            if (realtics < availabletics-1)
  //                counts = realtics+1;
  //            else if (realtics < availabletics)
  //                counts = realtics;
  //            else
  //                counts = availabletics;
  //        }
  //        else
  //        {
  //	counts = availabletics;
  //        }
  //
  //        // [AM] If we've uncapped the framerate and there are no tics
  //        //      to run, return early instead of waiting around.
  //        if (return_early)
  //            return;
  //    }
  //    else
  //    {
  //        // decide how many tics to run
  //        if (realtics < availabletics-1)
  //            counts = realtics+1;
  //        else if (realtics < availabletics)
  //            counts = realtics;
  //        else
  //            counts = availabletics;
  //
  //        // [AM] If we've uncapped the framerate and there are no tics
  //        //      to run, return early instead of waiting around.
  //        if (return_early)
  //            return;
  //
  //        if (counts < 1)
  //            counts = 1;
  //
  //        if (net_client_connected)
  //        {
  //            OldNetSync();
  //        }
  //    }
  //
  //    if (counts < 1)
  //	counts = 1;
  //
  //    // wait for new tics if needed
  //    while (!PlayersInGame() || lowtic < gametic/ticdup + counts)
  //    {
  //	NetUpdate ();
  //
  //        lowtic = GetLowTic();
  //
  //	if (lowtic < gametic/ticdup)
  //	    I_Error ("TryRunTics: lowtic < gametic");
  //
  //        // Still no tics to run? Sleep until some are available.
  //        if (lowtic < gametic/ticdup + counts)
  //        {
  //            // If we're in a netgame, we might spin forever waiting for
  //            // new network data to be received. So don't stay in here
  //            // forever - give the menu a chance to work.
  //            if (I_GetTime() / ticdup - entertic >= MAX_NETGAME_STALL_TICS)
  //            {
  //                return;
  //            }
  //
  //            I_Sleep(1);
  //        }
  //    }

  //    // run the count * ticdup dics
  //    while (counts--)
  //    {
  //        ticcmd_set_t *set;
  //
  //        if (!PlayersInGame())
  //        {
  //            return;
  //        }
  //
  //        set = &ticdata[(gametic / ticdup) % BACKUPTICS];
  //
  //        if (!net_client_connected)
  //        {
  //            SinglePlayerClear(set);
  //        }
  //
  //	for (i=0 ; i<ticdup ; i++)
  //	{
  //            if (gametic/ticdup > lowtic)
  //                I_Error ("gametic>lowtic");
  //
  //            memcpy(local_playeringame, set->ingame, sizeof(local_playeringame));
  //
//              loop_interface^.RunTic(set^.cmds, set^.ingame);
  gametic := gametic + 1;

  	    // modify command for duplicated tics

  //            TicdupSquash(set);
  //	}

  NetUpdate(); // check for new console commands

End;

End.






