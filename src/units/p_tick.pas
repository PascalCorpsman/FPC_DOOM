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

//
// P_RespawnSpecials
//

Procedure P_RespawnSpecials();
//    fixed_t		x;
//    fixed_t		y;
//    fixed_t		z;
//
//    subsector_t*	ss;
//    mobj_t*		mo;
//    mapthing_t*		mthing;
//
//    int			i;
Begin
  // only respawn items in deathmatch
  // AX: deathmatch 3 is a Crispy-specific change
  If (deathmatch <> 2) And (deathmatch <> 3) Then exit;


  // nothing left to respawn?
  //    if (iquehead == iquetail)
  //	return;
  //
  //    // wait at least 30 seconds
  //    if (leveltime - itemrespawntime[iquetail] < 30*TICRATE)
  //	return;
  //
  //    mthing = &itemrespawnque[iquetail];
  //
  //    x = mthing->x << FRACBITS;
  //    y = mthing->y << FRACBITS;
  //
  //    // spawn a teleport fog at the new spot
  //    ss = R_PointInSubsector (x,y);
  //    mo = P_SpawnMobj (x, y, ss->sector->floorheight , MT_IFOG);
  //    S_StartSound (mo, sfx_itmbk);
  //
  //    // find which type to spawn
  //    for (i=0 ; i< NUMMOBJTYPES ; i++)
  //    {
  //	if (mthing->type == mobjinfo[i].doomednum)
  //	    break;
  //    }
  //
  //    if (i >= NUMMOBJTYPES)
  //    {
  //        I_Error("P_RespawnSpecials: Failed to find mobj type with doomednum "
  //                "%d when respawning thing. This would cause a buffer overrun "
  //                "in vanilla Doom", mthing->type);
  //    }
  //
  //    // spawn it
  //    if (mobjinfo[i].flags & MF_SPAWNCEILING)
  //	z = ONCEILINGZ;
  //    else
  //	z = ONFLOORZ;
  //
  //    mo = P_SpawnMobj (x,y,z, i);
  //    mo->spawnpoint = *mthing;
  //    mo->angle = ANG45 * (mthing->angle/45);
  //
  //    // pull it from the que
  //    iquetail = (iquetail+1)&(ITEMQUESIZE-1);
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

