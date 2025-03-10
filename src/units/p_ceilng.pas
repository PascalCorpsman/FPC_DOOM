Unit p_ceilng;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , p_spec;

Var
  activeceilings: Array[0..MAXCEILINGS - 1] Of Pceiling_t;

Procedure P_ActivateInStasisCeiling(line: Pline_t);

Function EV_DoCeiling(line: Pline_t; _type: ceiling_e): int;
Function EV_CeilingCrushStop(line: Pline_t): int;

Implementation

Uses
  sounds
  , m_fixed
  , p_setup, p_tick, p_floor
  , s_sound
  ;

Var
  AllocatedCeilings: Array Of Pceiling_t = Nil;

Procedure P_RemoveActiveCeiling(c: Pceiling_t);
Var
  i: int;
Begin
  For i := 0 To MAXCEILINGS - 1 Do Begin
    If (activeceilings[i] = c) Then Begin
      activeceilings[i]^.sector^.specialdata := Nil;
      P_RemoveThinker(@activeceilings[i]^.thinker);
      activeceilings[i] := Nil;
      break;
    End;
  End;
End;

Procedure T_MoveCeiling(mo: Pmobj_t);
Var
  ceiling: Pceiling_t;
  res: result_e;
Begin
  ceiling := Pceiling_t(mo);
  Case (ceiling^.direction) Of
    0: Begin
        // IN STASIS
      End;
    1: Begin
        // UP
        res := T_MovePlane(ceiling^.sector,
          ceiling^.speed,
          ceiling^.topheight,
          false, 1, ceiling^.direction);

        If ((leveltime And 7) = 0) Then Begin

          Case (ceiling^._type) Of

            silentCrushAndRaise: Begin
              End;
          Else Begin
              S_StartSound(@ceiling^.sector^.soundorg, sfx_stnmov);
              // ?
            End;
          End;
        End;

        If (res = pastdest) Then Begin
          Case (ceiling^._type) Of
            raiseToHighest: Begin
                P_RemoveActiveCeiling(ceiling);
              End;
            silentCrushAndRaise,
              fastCrushAndRaise,
              crushAndRaise: Begin
                If ceiling^._type = silentCrushAndRaise Then
                  S_StartSound(@ceiling^.sector^.soundorg, sfx_pstop);
                ceiling^.direction := -1;
              End;
          End;
        End;
      End;

    -1: Begin
        // DOWN
        res := T_MovePlane(ceiling^.sector,
          ceiling^.speed,
          ceiling^.bottomheight,
          ceiling^.crush, 1, ceiling^.direction);

        If ((leveltime And 7) = 0) Then Begin
          Case (ceiling^._type) Of
            silentCrushAndRaise: Begin
              End;
          Else Begin
              S_StartSound(@ceiling^.sector^.soundorg, sfx_stnmov);
            End;
          End;
        End;

        If (res = pastdest) Then Begin
          Case (ceiling^._type) Of
            silentCrushAndRaise,
              crushAndRaise,
              fastCrushAndRaise: Begin
                If ceiling^._type = silentCrushAndRaise Then
                  S_StartSound(@ceiling^.sector^.soundorg, sfx_pstop);
                If (ceiling^._type = silentCrushAndRaise)
                  Or (ceiling^._type = crushAndRaise) Then
                  ceiling^.speed := CEILSPEED;
                ceiling^.direction := 1;
              End;

            lowerAndCrush,
              lowerToFloor: Begin
                P_RemoveActiveCeiling(ceiling);
              End;
          End;
        End
        Else Begin // ( res != pastdest )
          If (res = crushed) Then Begin
            Case (ceiling^._type) Of
              silentCrushAndRaise,
                crushAndRaise,
                lowerAndCrush: Begin
                  ceiling^.speed := CEILSPEED Div 8;
                End;
            End;
          End;
        End;
      End;
  End;
End;

//
// Restart a ceiling that's in-stasis
//

Procedure P_ActivateInStasisCeiling(line: Pline_t);
Var
  i: int;
Begin
  For i := 0 To MAXCEILINGS - 1 Do Begin
    If assigned(activeceilings[i])
      And (activeceilings[i]^.tag = line^.tag)
      And (activeceilings[i]^.direction = 0) Then Begin
      activeceilings[i]^.direction := activeceilings[i]^.olddirection;
      activeceilings[i]^.thinker._function.acp1 := @T_MoveCeiling;
    End;
  End;
End;

//
// Add an active ceiling
//

Procedure P_AddActiveCeiling(c: Pceiling_t);
Var
  i: int;
Begin
  For i := 0 To MAXCEILINGS - 1 Do Begin
    If (activeceilings[i] = Nil) Then Begin
      activeceilings[i] := c;
      exit;
    End;
  End;
End;

//
// EV_DoCeiling
// Move a ceiling up/down and all around!
//

Function EV_DoCeiling(line: Pline_t; _type: ceiling_e): int;
Var
  secnum, rtn: int;
  sec: Psector_t;
  ceiling: Pceiling_t;
Begin

  secnum := -1;
  rtn := 0;

  // Reactivate in-stasis ceilings...for certain types.
  Case _type Of
    fastCrushAndRaise,
      silentCrushAndRaise,
      crushAndRaise: P_ActivateInStasisCeiling(line);
  End;

  secnum := P_FindSectorFromLineTag(line, secnum);
  While (secnum >= 0) Do Begin

    sec := @sectors[secnum];
    If assigned(sec^.specialdata) Then Begin
      secnum := P_FindSectorFromLineTag(line, secnum);
      continue;
    End;
    // new door thinker
    rtn := 1;
    //    ceiling = Z_Malloc (sizeof(*ceiling), PU_LEVSPEC, 0);
    new(ceiling);
    setlength(AllocatedCeilings, high(AllocatedCeilings) + 2);
    AllocatedCeilings[high(AllocatedCeilings)] := ceiling;
    P_AddThinker(@ceiling^.thinker);
    sec^.specialdata := ceiling;
    ceiling^.thinker._function.acp1 := @T_MoveCeiling;
    ceiling^.sector := sec;
    ceiling^.crush := false;

    Case _type Of
      fastCrushAndRaise: Begin
          ceiling^.crush := true;
          ceiling^.topheight := sec^.ceilingheight;
          ceiling^.bottomheight := sec^.floorheight + (8 * FRACUNIT);
          ceiling^.direction := -1;
          ceiling^.speed := CEILSPEED * 2;
        End;

      silentCrushAndRaise,
        crushAndRaise,
        lowerAndCrush,
        lowerToFloor: Begin

          If (_type = silentCrushAndRaise) Or
            (_type = crushAndRaise) Then Begin

            ceiling^.crush := true;
            ceiling^.topheight := sec^.ceilingheight;

          End;
          ceiling^.bottomheight := sec^.floorheight;
          If (_type <> lowerToFloor) Then
            ceiling^.bottomheight := ceiling^.bottomheight + 8 * FRACUNIT;
          ceiling^.direction := -1;
          ceiling^.speed := CEILSPEED;
        End;

      raiseToHighest: Begin
          ceiling^.topheight := P_FindHighestCeilingSurrounding(sec);
          ceiling^.direction := 1;
          ceiling^.speed := CEILSPEED;
        End;
    End;

    ceiling^.tag := sec^.tag;
    ceiling^._type := _type;
    P_AddActiveCeiling(ceiling);
    secnum := P_FindSectorFromLineTag(line, secnum);
  End;
  result := rtn;
End;

//
// EV_CeilingCrushStop
// Stop a ceiling from crushing!
//

Function EV_CeilingCrushStop(line: Pline_t): int;
Var
  i, rtn: int;
Begin
  rtn := 0;

  For i := 0 To MAXCEILINGS - 1 Do Begin
    If assigned(activeceilings[i])
      And (activeceilings[i]^.tag = line^.tag)
      And (activeceilings[i]^.direction <> 0) Then Begin
      activeceilings[i]^.olddirection := activeceilings[i]^.direction;
      activeceilings[i]^.thinker._function.acv := Nil;
      activeceilings[i]^.direction := 0; // in-stasis
      rtn := 1;
    End;
  End;

  result := rtn;
End;


Var
  i: integer;

Finalization

  For i := 0 To high(AllocatedCeilings) Do Begin
    dispose(AllocatedCeilings[i]);
  End;
  setlength(AllocatedCeilings, 0);
End.

