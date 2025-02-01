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

Procedure P_RemoveThinker(thinker: Pthinker_t);

Implementation

Uses
  doomdef, doomdata, info, sounds, tables
  , g_game
  , i_timer, i_system
  , m_fixed
  , p_user, p_spec, p_mobj, p_local
  , r_main
  , s_sound, s_musinfo
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
  // [crispy] support MUSINFO lump (dynamic music changing)
  T_MusInfo();
End;

//
// P_RespawnSpecials
//

Procedure P_RespawnSpecials();
Var
  x, y, z: fixed_t;

  ss: Psubsector_t;
  mo: Pmobj_t;
  mthing: pmapthing_t;

  i, j: int;
Begin
  // only respawn items in deathmatch
  // AX: deathmatch 3 is a Crispy-specific change
  If (deathmatch <> 2) And (deathmatch <> 3) Then exit;


  // nothing left to respawn?
  If (iquehead = iquetail) Then exit;

  // wait at least 30 seconds
  If (leveltime - itemrespawntime[iquetail] < 30 * TICRATE) Then exit;

  mthing := @itemrespawnque[iquetail];

  x := mthing^.x Shl FRACBITS;
  y := mthing^.y Shl FRACBITS;

  // spawn a teleport fog at the new spot
  ss := R_PointInSubsector(x, y);
  mo := P_SpawnMobj(x, y, ss^.sector^.floorheight, MT_IFOG);
  S_StartSound(mo, sfx_itmbk);

  // find which type to spawn
  j := integer(NUMMOBJTYPES);
  For j := 0 To integer(NUMMOBJTYPES) - 1 Do Begin
    If (mthing^._type = mobjinfo[j].doomednum) Then Begin
      i := j;
      break;
    End;
  End;

  If (i >= integer(NUMMOBJTYPES)) Then Begin
    I_Error(format('P_RespawnSpecials: Failed to find mobj type with doomednum ' +
      '%d when respawning thing. This would cause a buffer overrun ' +
      'in vanilla Doom', [mthing^._type]));
  End;

  // spawn it
  If (mobjinfo[i].flags And MF_SPAWNCEILING) <> 0 Then
    z := ONCEILINGZ
  Else
    z := ONFLOORZ;

  mo := P_SpawnMobj(x, y, z, mobjtype_t(i));
  mo^.spawnpoint := mthing^;
  mo^.angle := angle_t(ANG45 * (mthing^.angle Div 45));

  // pull it from the que
  iquetail := (iquetail + 1) And (ITEMQUESIZE - 1);
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
  P_RespawnSpecials();

  // for par times
  leveltime := leveltime + 1;
End;

//
// P_RemoveThinker
// Deallocation is lazy -- it will not actually be freed
// until its thinking turn comes up.
//

Procedure P_RemoveThinker(thinker: Pthinker_t);
Begin
  // FIXME: NOP.
  thinker^._function.acv := Nil;
End;

End.

