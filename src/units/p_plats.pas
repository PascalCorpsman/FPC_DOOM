Unit p_plats;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , p_spec
  ;

Var
  activeplats: Array[0..MAXPLATS - 1] Of pplat_t;

Function EV_DoPlat(line: Pline_t; _type: plattype_e; amount: int): int;
Procedure EV_StopPlat(line: Pline_t);

Implementation

Uses
  sounds, doomstat
  , d_mode
  , i_system, i_timer
  , m_fixed, m_random
  , p_setup, p_tick, p_floor
  , s_sound
  ;

Var
  AllocatedPlats: Array Of Pplat_t = Nil;

Procedure P_RemoveActivePlat(plat: Pplat_t);
Var
  i: int;
Begin
  For i := 0 To MAXPLATS - 1 Do Begin
    If (plat = activeplats[i]) Then Begin
      (activeplats[i])^.sector^.specialdata := Nil;
      P_RemoveThinker(@(activeplats[i])^.thinker);
      activeplats[i] := Nil;
      exit;
    End;
  End;
  I_Error('P_RemoveActivePlat: can''t find plat!');
End;

//
// Move a plat up and down
//

Procedure T_PlatRaise(mo: Pmobj_t);
Var
  plat: Pplat_t;
  res: result_e;
Begin
  plat := Pplat_t(mo);
  Case (plat^.status) Of
    up: Begin
        res := T_MovePlane(plat^.sector,
          plat^.speed,
          plat^.high,
          plat^.crush, 0, 1);

        If (plat^._type = raiseAndChange)
          Or (plat^._type = raiseToNearestAndChange) Then Begin

          If ((leveltime And 7) = 0) Then
            S_StartSound(@plat^.sector^.soundorg, sfx_stnmov);
        End;

        If (res = crushed) And ((Not plat^.crush)) Then Begin
          plat^.count := plat^.wait;
          plat^.status := down;
          S_StartSound(@plat^.sector^.soundorg, sfx_pstart);
        End
        Else Begin
          If (res = pastdest) Then Begin
            plat^.count := plat^.wait;
            plat^.status := waiting;
            S_StartSound(@plat^.sector^.soundorg, sfx_pstop);

            Case (plat^._type) Of
              blazeDWUS,
                downWaitUpStay: Begin
                  P_RemoveActivePlat(plat);
                End;

              raiseAndChange,
                raiseToNearestAndChange: Begin
                  // In versions <= v1.2 (at least), platform types besides
                  // downWaitUpStay always remain active.
                  If (gameversion > exe_doom_1_2) Then
                    P_RemoveActivePlat(plat);
                End;
            End;
          End;
        End;
      End;

    down: Begin
        res := T_MovePlane(plat^.sector, plat^.speed, plat^.low, false, 0, -1);
        If (res = pastdest) Then Begin
          plat^.count := plat^.wait;
          plat^.status := waiting;
          S_StartSound(@plat^.sector^.soundorg, sfx_pstop);
        End;
      End;

    waiting: Begin
        plat^.count := plat^.count - 1;
        If (plat^.count = 0) Then Begin
          If (plat^.sector^.floorheight = plat^.low) Then
            plat^.status := up
          Else
            plat^.status := down;
          S_StartSound(@plat^.sector^.soundorg, sfx_pstart);
        End;
      End;
    in_stasis: Begin
      End;
  End;
End;

Procedure P_ActivateInStasis(tag: int);
Var
  i: int;
Begin
  For i := 0 To MAXPLATS - 1 Do Begin
    If assigned(activeplats[i])
      And ((activeplats[i])^.tag = tag)
      And ((activeplats[i])^.status = in_stasis) Then Begin
      (activeplats[i])^.status := (activeplats[i])^.oldstatus;
      (activeplats[i])^.thinker._function.acp1 := @T_PlatRaise;
    End;
  End;
End;

Procedure P_AddActivePlat(plat: Pplat_t);
Var
  i: int;
Begin
  For i := 0 To MAXPLATS - 1 Do Begin
    If (activeplats[i] = Nil) Then Begin
      activeplats[i] := plat;
      exit;
    End;
  End;
  I_Error('P_AddActivePlat: no more plats!');
End;

//
// Do Platforms
//  "amount" is only used for SOME platforms.
//

Function EV_DoPlat(line: Pline_t; _type: plattype_e; amount: int): int;
Var
  rtn: int;
  plat: Pplat_t;
  secnum: int;
  sec: Psector_t;
Begin
  secnum := -1;
  rtn := 0;
  //	Activate all <type> plats that are in_stasis
  Case (_type) Of
    perpetualRaise: Begin
        P_ActivateInStasis(line^.tag);
      End;
  End;
  secnum := P_FindSectorFromLineTag(line, secnum);
  While (secnum >= 0) Do Begin
    sec := @sectors[secnum];

    If assigned(sec^.specialdata) Then Begin
      secnum := P_FindSectorFromLineTag(line, secnum);
      continue;
    End;

    // Find lowest & highest floors around sector
    rtn := 1;
    new(plat);
    setlength(AllocatedPlats, high(AllocatedPlats) + 2);
    AllocatedPlats[high(AllocatedPlats)] := plat;

    P_AddThinker(@plat^.thinker);

    plat^._type := _Type;
    plat^.sector := sec;
    plat^.sector^.specialdata := plat;
    plat^.thinker._Function.acp1 := @T_PlatRaise;
    plat^.crush := false;
    plat^.tag := line^.tag;

    Case (_type) Of
      raiseToNearestAndChange: Begin
          plat^.speed := PLATSPEED Div 2;
          sec^.floorpic := sides[line^.sidenum[0]].sector^.floorpic;
          plat^.high := P_FindNextHighestFloor(sec, sec^.floorheight);
          plat^.wait := 0;
          plat^.status := up;
          // NO MORE DAMAGE, IF APPLICABLE
          sec^.special := 0;

          S_StartSound(@sec^.soundorg, sfx_stnmov);
        End;
      raiseAndChange: Begin
          plat^.speed := PLATSPEED Div 2;
          sec^.floorpic := sides[line^.sidenum[0]].sector^.floorpic;
          plat^.high := sec^.floorheight + amount * FRACUNIT;
          plat^.wait := 0;
          plat^.status := up;
          S_StartSound(@sec^.soundorg, sfx_stnmov);
        End;

      downWaitUpStay: Begin
          plat^.speed := PLATSPEED * 4;
          plat^.low := P_FindLowestFloorSurrounding(sec);

          If (plat^.low > sec^.floorheight) Then
            plat^.low := sec^.floorheight;

          plat^.high := sec^.floorheight;
          plat^.wait := TICRATE * PLATWAIT;
          plat^.status := down;
          S_StartSound(@sec^.soundorg, sfx_pstart);
        End;
      blazeDWUS: Begin
          plat^.speed := PLATSPEED * 8;
          plat^.low := P_FindLowestFloorSurrounding(sec);

          If (plat^.low > sec^.floorheight) Then
            plat^.low := sec^.floorheight;

          plat^.high := sec^.floorheight;
          plat^.wait := TICRATE * PLATWAIT;
          plat^.status := down;
          S_StartSound(@sec^.soundorg, sfx_pstart);
        End;
      perpetualRaise: Begin
          plat^.speed := PLATSPEED;
          plat^.low := P_FindLowestFloorSurrounding(sec);

          If (plat^.low > sec^.floorheight) Then
            plat^.low := sec^.floorheight;

          plat^.high := P_FindHighestFloorSurrounding(sec);

          If (plat^.high < sec^.floorheight) Then
            plat^.high := sec^.floorheight;

          plat^.wait := TICRATE * PLATWAIT;
          plat^.status := plat_e(P_Random() And 1);

          S_StartSound(@sec^.soundorg, sfx_pstart);
        End;
    End;
    P_AddActivePlat(plat);
    secnum := P_FindSectorFromLineTag(line, secnum);
  End;
  result := rtn;
End;

Procedure EV_StopPlat(line: Pline_t);
Begin
  Raise exception.create('Port me.');
  //      int		j;
  //
  //    for (j = 0;j < MAXPLATS;j++)
  //	if (activeplats[j]
  //	    && ((activeplats[j])->status != in_stasis)
  //	    && ((activeplats[j])->tag == line->tag))
  //	{
  //	    (activeplats[j])->oldstatus = (activeplats[j])->status;
  //	    (activeplats[j])->status = in_stasis;
  //	    (activeplats[j])->thinker.function.acv = (actionf_v)NULL;
  //	}
End;

Var
  i: int;

Finalization
  For i := 0 To high(AllocatedPlats) Do Begin
    Dispose(AllocatedPlats[i]);
  End;
  setlength(AllocatedPlats, 0);

End.

