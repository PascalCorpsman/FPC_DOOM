Unit p_tick;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  info_types
  ;

Var
  thinkercap: thinker_t;
  leveltime: int; // tics in game play for par

Procedure P_InitThinkers();

Procedure P_AddThinker(thinker: Pthinker_t);

Procedure P_Ticker();

Implementation

Uses
  doomdef
  , g_game
  , p_user, p_spec
  ;

Procedure P_InitThinkers();
Begin
  thinkercap.prev := @thinkercap;
  thinkercap.next := @thinkercap;
End;

//
// P_AddThinker
// Adds a new thinker at the end of the list.
//

Procedure P_AddThinker(thinker: Pthinker_t);
Begin
  thinkercap.prev^.next := thinker;
  thinker^.next := @thinkercap;
  thinker^.prev := thinkercap.prev;
  thinkercap.prev := thinker;
End;

//
// P_RunThinkers
//

Procedure P_RunThinkers();
Var
  nextthinker, currentthinker: ^thinker_t;
Begin
  currentthinker := thinkercap.next;
  While (currentthinker <> @thinkercap) Do Begin

    If (currentthinker^._function.acv = Nil) Then Begin
      // time to remove it
      nextthinker := currentthinker^.next;
      currentthinker^.next^.prev := currentthinker^.prev;
      currentthinker^.prev^.next := currentthinker^.next;
      // Z_Free(currentthinker); -- Muss nicht freigegeben werden, da wir das via FreeAllocations machen ;)
    End
    Else Begin
      If assigned(currentthinker^._function.acp1) Then
        currentthinker^._function.acp1(Pmobj_t(currentthinker));
      nextthinker := currentthinker^.next;
    End;
    currentthinker := nextthinker;
  End;
  //     // [crispy] support MUSINFO lump (dynamic music changing)
  //     T_MusInfo();
End;


Procedure P_Ticker();
Var
  i: int;
Begin

  // run the tic
  If (paused <> 0) Then exit;

  //    // pause if in menu and at least one tic has been run
  //    if ( !netgame
  //	 && menuactive
  //	 && !demoplayback
  //	 && players[consoleplayer].viewz != 1)
  //    {
  //	return;
  //    }

  For i := 0 To MAXPLAYERS - 1 Do Begin
    If (playeringame[i]) Then
      P_PlayerThink(@players[i]);
  End;

  P_RunThinkers();
  P_UpdateSpecials();
  //    P_RespawnSpecials ();

  // for par times
  leveltime := leveltime + 1;
End;

End.


