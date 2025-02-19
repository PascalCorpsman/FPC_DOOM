Unit d_loop;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , net_defs
  , d_ticcmd
  , m_fixed
  ;

Type

  Tcmds = Array[0..NET_MAXPLAYERS - 1] Of ticcmd_t;
  TInGame = Array[0..NET_MAXPLAYERS - 1] Of boolean;

  ticcmd_set_t = Record
    cmds: Tcmds;
    ingame: TInGame;
  End;

  Pticcmd_set_t = ^ticcmd_set_t;

  TRunTic = Procedure(Const cmds: Tcmds; Var ingame: TInGame);
  TBuildTiccmd = Procedure(Var cmd: ticcmd_t; maketic: int);

  // Callback function invoked while waiting for the netgame to start.
  // The callback is invoked when new players are ready. The callback
  // should return true, or return false to abort startup.
  netgame_startup_callback_t = Function(ready_players: int; num_players: int): Boolean;

  loop_interface_t = Record

    // Read events from the event queue, and process them.
    ProcessEvents: TProcedure;

    // Given the current input state, fill in the fields of the specified
    // ticcmd_t structure with data for a new tic.
    BuildTiccmd: TBuildTiccmd;

    // Advance the game forward one tic, using the specified player input.
    RunTic: TRunTic;

    // Run the menu (runs independently of the game).
    RunMenu: TProcedure;
  End;

  Ploop_interface_t = ^loop_interface_t;

Var

  // Reduce the bandwidth needed by sampling game input less and transmitting
  // less.  If ticdup is 2, sample half normal, 3 = one third normal, etc.
  ticdup: int;

  // The number of tics that have been run (using RunTic) so far.
  gametic: int;
  oldleveltime: int; // [crispy] check if leveltime keeps tickin'
  TicksPerSecond: integer; // Corpsman: DEBUG for Tick per second Measurement

  // When set to true, a single tic is run each time TryRunTics() is called.
  // This is used for -timedemo mode.
  singletics: boolean = false;

Procedure TryRunTics();
Procedure D_RegisterLoopCallbacks(i: Ploop_interface_t);
Procedure D_StartGameLoop();
Procedure D_StartNetGame(Var settings: net_gamesettings_t; callback: netgame_startup_callback_t);
Procedure NetUpdate();
Function D_NonVanillaPlayback(conditional: boolean; lumpnum: int; feature: String): boolean;

Implementation

Uses
  net_client
  , d_event
  , i_timer, i_system, i_video
  , m_argv
  , w_wad
  ;

Var

  //
  // gametic is the tic about to (or currently being) run
  // maketic is the tic that hasn't had control made for it yet
  // recvtic is the latest tic received from the server.
  //
  // a gametic cannot be run until ticcmds are received for it
  // from all players.
  //

  ticdata: Array[0..BACKUPTICS - 1] Of ticcmd_set_t;

  // The index of the next tic to be made (with a call to BuildTiccmd).
  maketic: int;

  // Current players in the multiplayer game.
  // This is distinct from playeringame[] used by the game code, which may
  // modify playeringame[] when playing back multiplayer demos.

  local_playeringame: Array[0..NET_MAXPLAYERS - 1] Of Boolean;

  // Index of the local player.
  localplayer: int;

  // The number of complete tics received from the server so far.
  recvtic: int;

  // Used for original sync code.
  skiptics: int = 0;

  // Callback functions for loop code.
  loop_interface: Ploop_interface_t = Nil;

  // Use new client syncronisation code
  new_sync: boolean = true;

  // Amount to offset the timer for game sync.
  offsetms: fixed_t = 0;

  // Requested player class "sent" to the server on connect.
  // If we are only doing a single player game then this needs to be remembered
  // and saved in the game settings.
  player_class: int = 0;

  lasttime: int;


Function GetLowTic(): int;
Var
  lowtic: int;
Begin
  lowtic := maketic;
  If (net_client_connected) Then Begin
    //          if (drone || recvtic < lowtic)
    //          {
    //              lowtic = recvtic;
    //          }
  End;
  result := lowtic;
End;

// 35 fps clock adjusted by offsetms milliseconds

Function GetAdjustedTime(): int;
Var
  time_ms: int;
Begin
  time_ms := I_GetTimeMS();

  If (new_sync) Then Begin

    // Use the adjustments from net_client.c only if we are
    // using the new sync mode.

    time_ms := time_ms + (offsetms Div FRACUNIT);
  End;

  result := (time_ms * TICRATE) Div 1000;
End;

Procedure D_RegisterLoopCallbacks(i: Ploop_interface_t);
Begin
  loop_interface := i;
End;


//
// Start game loop
//
// Called after the screen is set but before the game starts running.
//

Procedure D_StartGameLoop();
Begin
  lasttime := GetAdjustedTime() Div ticdup;
End;

// Start game with specified settings. The structure will be updated
// with the actual settings for the game.

Procedure D_StartNetGame(Var settings: net_gamesettings_t;
  callback: netgame_startup_callback_t);
Var
  i: int;
Begin

  offsetms := 0;
  recvtic := 0;

  settings.consoleplayer := 0;
  settings.num_players := 1;
  settings.player_classes[0] := player_class;

  //!
  // @category net
  //
  // Use original network client sync code rather than the improved
  // sync code.
  //
  settings.new_sync := ord(Not M_ParmExists('-oldsync'));

  //!
  // @category net
  // @arg <n>
  //
  // Send n extra tics in every packet as insurance against dropped
  // packets.
  //

  i := M_CheckParmWithArgs('-extratics', 1);

  If (i > 0) Then Begin
    settings.extratics := strtoint(myargv[i + 1]);
  End
  Else Begin
    settings.extratics := 1;
  End;

  //!
  // @category net
  // @arg <n>
  //
  // Reduce the resolution of the game by a factor of n, reducing
  // the amount of network bandwidth needed.
  //

  i := M_CheckParmWithArgs('-dup', 1);

  If (i > 0) Then Begin
    settings.ticdup := strtoint(myargv[i + 1]);
  End
  Else Begin
    settings.ticdup := 1;
  End;

  If (net_client_connected) Then Begin

    // Send our game settings and block until game start is received
    // from the server.
//
//        NET_CL_StartGame(settings);
//        BlockUntilStart(settings, callback);

   // Read the game settings that were received.

//        NET_CL_GetSettings(settings);
  End;

  If (drone) Then Begin
    settings.consoleplayer := 0;
  End;

  // Set the local player and playeringame[] values.

  localplayer := settings.consoleplayer;


  For i := 0 To NET_MAXPLAYERS - 1 Do Begin
    local_playeringame[i] := i < settings.num_players;
  End;

  // Copy settings to global variables.

  ticdup := settings.ticdup;
  new_sync := odd(settings.new_sync);

  If (ticdup < 1) Then Begin
    I_Error(format('D_StartNetGame: invalid ticdup value (%d)', [ticdup]));
  End;

  // TODO: Message disabled until we fix new_sync.
  //if (!new_sync)
  //{
  //    printf("Syncing netgames like Vanilla Doom.\n");
  //}
End;

Function BuildNewTic(): Boolean;
Var
  gameticdiv: int;
  cmd: ticcmd_t;
Begin
  TicksPerSecond := TicksPerSecond + 1; // Corpsman: DEBUG for Tick per second Measurement
  result := false;

  gameticdiv := gametic Div ticdup;

  I_StartTic();
  loop_interface^.ProcessEvents();

  // Always run the menu

  loop_interface^.RunMenu();

  If (drone) Then Begin
    // In drone mode, do not generate any ticcmds.
    exit;
  End;

  If (new_sync) Then Begin

    // If playing single player, do not allow tics to buffer
    // up very far

    If (Not net_client_connected) And (maketic - gameticdiv > 2) Then exit;

    // Never go more than ~200ms ahead
    If (maketic - gameticdiv > 8) Then exit;
  End
  Else Begin
    If (maketic - gameticdiv >= 5) Then exit;
  End;

  //  writeln(format('mk:%d ', [maketic]));

  FillChar(cmd, sizeof(cmd), 0);

  loop_interface^.BuildTiccmd(cmd, maketic);

  If (net_client_connected) Then Begin
    Raise exception.create('Port me.');
    // NET_CL_SendTiccmd(&cmd, maketic);
  End;

  ticdata[maketic Mod BACKUPTICS].cmds[localplayer] := cmd;
  ticdata[maketic Mod BACKUPTICS].ingame[localplayer] := true;

  maketic := maketic + 1;

  result := true;
End;

//
// NetUpdate
// Builds ticcmds for console player,
// sends out a packet
//

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
  nowtime := GetAdjustedTime() Div ticdup;
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
  For i := 0 To newtics - 1 Do Begin
    If (Not BuildNewTic()) Then Begin
      break;
    End;
  End;
End;

Function StrictDemos(): Boolean;
Begin
  //!
  // @category demo
  //
  // When recording or playing back demos, disable any extensions
  // of the vanilla demo format - record demos as vanilla would do,
  // and play back demos as vanilla would do.
  //
  result := M_ParmExists('-strictdemos');
End;

// Returns true if the given lump number corresponds to data from a .lmp
// file, as opposed to a WAD.

Function IsDemoFile(lumpnum: int): Boolean;
Var
  lower: String;
Begin
  lower := lumpinfo[lumpnum].wad_file;
  lower := lowercase(lower);
  result := ExtractFileExt(lower) = '.lmp';
End;

// If the provided conditional value is true, we're trying to play back
// a demo that includes a non-vanilla extension. We return true if the
// conditional is true and it's allowed to use this extension, checking
// that:
//  - The -strictdemos command line argument is not provided.
//  - The given lumpnum identifying the demo to play back identifies a
//    demo that comes from a .lmp file, not a .wad file.
//  - Before proceeding, a warning is shown to the user on the console.

Function D_NonVanillaPlayback(conditional: boolean; lumpnum: int;
  feature: String): boolean;
Begin
  If (Not conditional) Or (StrictDemos()) Then Begin
    result := false;
    exit;
  End;

  If (Not IsDemoFile(lumpnum)) Then Begin
    writeln(format('Warning: WAD contains demo with a non-vanilla extension (%s)', [feature]));
    result := false;
    exit;
  End;

  writeln(format('Warning: Playing back a demo File With a non - vanilla extension (%s).Use - strictdemos To disable this extension.', [feature]));

  result := true;
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

// When running in single player mode, clear all the ingame[] array
// except the local player.

Procedure SinglePlayerClear(_set: Pticcmd_set_t);
Var
  i: unsigned_int;
Begin
  For i := 0 To NET_MAXPLAYERS - 1 Do Begin
    If (i <> localplayer) Then Begin
      _set^.ingame[i] := false;
    End;
  End;
End;

// When using ticdup, certain values must be cleared out when running
// the duplicate ticcmds.

Procedure TicdupSquash(Var _set: ticcmd_set_t);
Var
  i: unsigned_int;
Begin
  For i := 0 To NET_MAXPLAYERS - 1 Do Begin
    _set.cmds[i].chatchar := 0;
    If (_set.cmds[i].buttons And BT_SPECIAL) <> 0 Then
      _set.cmds[i].buttons := 0;
  End;
End;

Procedure TryRunTics;
Const
  oldentertics: int = 0;
Var
  realtics, entertic, counts, availabletics, lowtic, i: int;
  _set: ^ticcmd_set_t;
Begin
  //
  //    // [AM] If we've uncapped the framerate and there are no tics
  //    //      to run, return early instead of waiting around.
  //    extern int leveltime;
  //    #define return_early (crispy->uncapped && counts == 0 && leveltime > oldleveltime && screenvisible)
  //
  // get real tics
  entertic := I_GetTime() Div ticdup;
  realtics := entertic - oldentertics;
  oldentertics := entertic;

  // in singletics mode, run a single tic every time this function
  // is called.

  If (singletics) Then Begin
    BuildNewTic();
  End
  Else Begin
    NetUpdate();
  End;

  lowtic := GetLowTic();

  availabletics := lowtic - gametic Div ticdup;

  // decide how many tics to run

  If (new_sync) Then Begin

    If (crispy.uncapped <> 0) Then Begin
      // decide how many tics to run
//            if (realtics < availabletics-1)
//                counts = realtics+1;
//            else if (realtics < availabletics)
//                counts = realtics;
//            else
//                counts = availabletics;
    End
    Else Begin
      counts := availabletics;
    End;

    // [AM] If we've uncapped the framerate and there are no tics
    //      to run, return early instead of waiting around.
//        if (return_early)
//            return;
  End
  Else Begin
    Raise exception.create('Port me.');
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
  End;

  If (counts < 1) Then
    counts := 1;

  //    // wait for new tics if needed
  //    while (!PlayersInGame() || lowtic < gametic/ticdup + counts)
  If lowtic < gametic Div ticdup + counts Then exit;

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
  Repeat
    //        ticcmd_set_t *set;

    If (Not PlayersInGame()) Then Begin
      exit;
    End;

    _set := @ticdata[(gametic Div ticdup) Mod BACKUPTICS];

    If (Not net_client_connected) Then Begin
      SinglePlayerClear(_set);
    End;

    For i := 0 To ticdup - 1 Do Begin

      If (gametic Div ticdup > lowtic) Then
        I_Error('gametic>lowtic');

      move(_set^.ingame[0], local_playeringame[0], sizeof(local_playeringame));

      loop_interface^.RunTic(_set^.cmds, _set^.ingame);
      gametic := gametic + 1;

      // modify command for duplicated tics
      TicdupSquash(_Set^);
    End;

    NetUpdate(); // check for new console commands

    counts := counts - 1;
  Until counts <= 0;
End;

End.

