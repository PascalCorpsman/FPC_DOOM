Unit p_doors;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , p_spec
  ;

Function EV_DoDoor(line: Pline_t; _type: vldoor_e): int;

Procedure EV_VerticalDoor(line: Pline_t; thing: Pmobj_t);

Procedure P_SpawnDoorCloseIn30(sec: Psector_t);
Procedure P_SpawnDoorRaiseIn5Mins(sec: Psector_t; secnum: int);

Implementation

Uses
  doomdef, sounds, doomdata
  , d_englsh
  , i_timer
  , m_fixed
  , p_local, p_setup, p_tick, p_floor
  , s_sound
  ;

Var
  Pvldoor_ts: Array Of Pvldoor_t = Nil;
  Pvldoor_ts_cnt: integer = 0;

  //
  // T_VerticalDoor
  //

Procedure T_VerticalDoor(_door: Pmobj_t);
Var
  door: Pvldoor_t;
  res: result_e;
Begin
  door := Pvldoor_t(pointer(_door));
  Case (door^.direction) Of
    0: Begin
        // WAITING
        door^.topcountdown := door^.topcountdown - 1;
        If (door^.topcountdown = 0) Then Begin
          Case (door^._type) Of
            vld_blazeRaise: Begin
                door^.direction := -1; // time to go back down
                S_StartSound(@door^.sector^.soundorg, sfx_bdcls);
              End;
            vld_normal: Begin
                door^.direction := -1; // time to go back down
                S_StartSound(@door^.sector^.soundorg, sfx_dorcls);
              End;
            vld_close30ThenOpen: Begin
                door^.direction := 1;
                S_StartSound(@door^.sector^.soundorg, sfx_doropn);
              End;
          End;
        End;
      End;

    2: Begin
        //  INITIAL WAIT
        door^.topcountdown := door^.topcountdown - 1;
        If (door^.topcountdown = 0) Then Begin
          Case (door^._type) Of
            vld_raiseIn5Mins: Begin
                door^.direction := 1;
                door^._type := vld_normal;
                S_StartSound(@door^.sector^.soundorg, sfx_doropn);
              End;
          End;
        End;
      End;

    -1: Begin
        // DOWN
        res := T_MovePlane(door^.sector,
          door^.speed,
          door^.sector^.floorheight,
          false, 1, door^.direction);
        If (res = pastdest) Then Begin
          Case (door^._type) Of
            vld_blazeRaise,
              vld_blazeClose: Begin
                door^.sector^.specialdata := Nil;
                P_RemoveThinker(@door^.thinker); // unlink and free
                // [crispy] fix "fast doors make two closing sounds"
                If (crispy.soundfix = 0) Then
                  S_StartSound(@door^.sector^.soundorg, sfx_bdcls);
              End;
            vld_normal,
              vld_close: Begin
                door^.sector^.specialdata := Nil;
                P_RemoveThinker(@door^.thinker); // unlink and free
              End;
            vld_close30ThenOpen: Begin
                door^.direction := 0;
                door^.topcountdown := TICRATE * 30;
              End;
          End;
        End
        Else If (res = crushed) Then Begin
          Case (door^._type) Of
            vld_blazeClose,
              vld_close: Begin // DO NOT GO BACK UP!
              End;
            // [crispy] fix "fast doors reopening with wrong sound"
            vld_blazeRaise: Begin
                If (crispy.soundfix <> 0) Then Begin
                  door^.direction := 1;
                  S_StartSound(@door^.sector^.soundorg, sfx_bdopn);
                End
                Else Begin
                  door^.direction := 1;
                  S_StartSound(@door^.sector^.soundorg, sfx_doropn);
                End;
              End;
          Else Begin
              door^.direction := 1;
              S_StartSound(@door^.sector^.soundorg, sfx_doropn);
            End;
          End;
        End;
      End;
    1: Begin
        // UP
        res := T_MovePlane(door^.sector,
          door^.speed,
          door^.topheight,
          false, 1, door^.direction);

        If (res = pastdest) Then Begin
          Case (door^._type) Of
            vld_blazeRaise,
              vld_normal: Begin
                door^.direction := 0; // wait at top
                door^.topcountdown := door^.topwait;
              End;
            vld_close30ThenOpen,
              vld_blazeOpen,
              vld_open: Begin
                door^.sector^.specialdata := Nil;
                P_RemoveThinker(@door^.thinker); // unlink and free
              End;
          End;
        End;
      End;
  End;
End;

Function EV_DoDoor(line: Pline_t; _type: vldoor_e): int;
Var
  secnum, rtn: int;
  sec: Psector_t;
  door: Pvldoor_t;
Begin
  secnum := -1;
  rtn := 0;
  secnum := P_FindSectorFromLineTag(line, secnum);
  While (secnum >= 0) Do Begin
    sec := @sectors[secnum];
    If assigned(sec^.specialdata) Then Begin
      secnum := P_FindSectorFromLineTag(line, secnum);
      continue;
    End;

    // new door thinker
    rtn := 1;
    new(door);
    If Pvldoor_ts_cnt >= high(Pvldoor_ts) Then Begin
      setlength(Pvldoor_ts, high(Pvldoor_ts) + 1025);
    End;
    Pvldoor_ts[Pvldoor_ts_cnt] := door;
    inc(Pvldoor_ts_cnt);
    P_AddThinker(@door^.thinker);
    sec^.specialdata := door;

    door^.thinker._function.acp1 := @T_VerticalDoor;
    door^.sector := sec;
    door^._type := _type;
    door^.topwait := VDOORWAIT;
    door^.speed := VDOORSPEED;

    Case (_type) Of
      vld_blazeClose: Begin
          door^.topheight := P_FindLowestCeilingSurrounding(sec);
          door^.topheight := door^.topheight - 4 * FRACUNIT;
          door^.direction := -1;
          door^.speed := VDOORSPEED * 4;
          // [crispy] fix door-closing sound playing, even when door is already closed (repeatable walkover trigger)
          If (door^.sector^.ceilingheight - door^.sector^.floorheight > 0) Or (crispy.soundfix = 0) Then
            S_StartSound(@door^.sector^.soundorg, sfx_bdcls);
        End;

      vld_close: Begin
          door^.topheight := P_FindLowestCeilingSurrounding(sec);
          door^.topheight := door^.topheight - 4 * FRACUNIT;
          door^.direction := -1;
          // [crispy] fix door-closing sound playing, even when door is already closed (repeatable walkover trigger)
          If (door^.sector^.ceilingheight - door^.sector^.floorheight > 0) Or (crispy.soundfix = 0) Then
            S_StartSound(@door^.sector^.soundorg, sfx_dorcls);
        End;

      vld_close30ThenOpen: Begin
          door^.topheight := sec^.ceilingheight;
          door^.direction := -1;
          // [crispy] fix door-closing sound playing, even when door is already closed (repeatable walkover trigger)
          If (door^.sector^.ceilingheight - door^.sector^.floorheight > 0) Or (crispy.soundfix = 0) Then
            S_StartSound(@door^.sector^.soundorg, sfx_dorcls);
        End;

      vld_blazeRaise,
        vld_blazeOpen: Begin
          door^.direction := 1;
          door^.topheight := P_FindLowestCeilingSurrounding(sec);
          door^.topheight := door^.topheight - 4 * FRACUNIT;
          door^.speed := VDOORSPEED * 4;
          If (door^.topheight <> sec^.ceilingheight) Then
            S_StartSound(@door^.sector^.soundorg, sfx_bdopn);
        End;

      vld_normal,
        vld_open: Begin
          door^.direction := 1;
          door^.topheight := P_FindLowestCeilingSurrounding(sec);
          door^.topheight := door^.topheight - 4 * FRACUNIT;
          If (door^.topheight <> sec^.ceilingheight) Then
            S_StartSound(@door^.sector^.soundorg, sfx_doropn);
        End;
    End;
    secnum := P_FindSectorFromLineTag(line, secnum);
  End;
  result := rtn;
End;

//
// EV_VerticalDoor : open a door manually, no tag value
//

Procedure EV_VerticalDoor(line: Pline_t; thing: Pmobj_t);
Var
  player: Pplayer_t;
  sec: Psector_t;
  door: Pvldoor_t;
  side: int;
Begin
  side := 0; // only front sides can be used

  //	Check for locks
  player := thing^.player;

  Case line^.special Of
    26, // Blue Lock
    32: Begin
        If (player = Nil) Then exit;

        If (Not player^.cards[it_bluecard]) And (Not player^.cards[it_blueskull]) Then Begin

          player^.message := PD_BLUEK;
          // [NS] Locked door sound.
          If crispy.soundfix <> 0 Then Begin
            S_StartSoundOptional(player^.mo, sfx_locked, sfx_oof);
          End
          Else Begin
            S_StartSoundOptional(Nil, sfx_locked, sfx_oof);
          End;
          // [crispy] blinking key or skull in the status bar
          player^.tryopen[it_bluecard] := KEYBLINKTICS;
          exit;
        End;
      End;
    27, // Yellow Lock
    34: Begin
        If (player = Nil) Then exit;

        If (Not player^.cards[it_yellowcard]) And (
          Not player^.cards[it_yellowskull]) Then Begin

          player^.message := PD_YELLOWK;
          // [NS] Locked door sound.
          If crispy.soundfix <> 0 Then Begin
            S_StartSoundOptional(player^.mo, sfx_locked, sfx_oof);
          End
          Else Begin
            S_StartSoundOptional(Nil, sfx_locked, sfx_oof);
          End;
          // [crispy] blinking key or skull in the status bar
          player^.tryopen[it_yellowcard] := KEYBLINKTICS;
          exit;
        End;
      End;
    28, // Red Lock
    33: Begin
        If (player = Nil) Then exit;

        If (Not player^.cards[it_redcard]) And (Not player^.cards[it_redskull]) Then Begin
          player^.message := PD_REDK;
          // [NS] Locked door sound.
          If crispy.soundfix <> 0 Then Begin
            S_StartSoundOptional(player^.mo, sfx_locked, sfx_oof);
          End
          Else Begin
            S_StartSoundOptional(Nil, sfx_locked, sfx_oof);
          End;
          // [crispy] blinking key or skull in the status bar
          player^.tryopen[it_redcard] := KEYBLINKTICS;
          exit;
        End;
      End;
  End;

  // if the sector has an active thinker, use it

  If (line^.sidenum[side Xor 1] = NO_INDEX) Then Begin
    // [crispy] do not crash if the wrong side of the door is pushed
    writeln(stderr, 'EV_VerticalDoor: DR special type on 1-sided linedef');
    exit;
  End;

  sec := sides[line^.sidenum[side Xor 1]].sector;

  If assigned(sec^.specialdata) Then Begin
    door := sec^.specialdata;
    Case (line^.special) Of

      1, // ONLY FOR "RAISE" DOORS, NOT "OPEN"s
      26,
        27,
        28,
        117: Begin
          If (door^.direction = -1) Then Begin

            door^.direction := 1; // go back up
            // [crispy] play sound effect when the door is opened again while going down
            If (crispy.soundfix <> 0) And (door^.thinker._function.acp1 = @T_VerticalDoor) Then Begin

              If line^.special = 117 Then Begin
                S_StartSound(@door^.sector^.soundorg, sfx_bdopn);
              End
              Else Begin
                S_StartSound(@door^.sector^.soundorg, sfx_doropn);
              End;
            End;
          End
          Else Begin
            If (thing^.player = Nil) Then exit; // JDC: bad guys never close doors

            // When is a door not a door?
            // In Vanilla, door^.direction is set, even though
            // "specialdata" might not actually point at a door.

            Raise exception.create('EV_VerticalDoor, Error, missing implementation.');
            //                if (door^.thinker.function.acp1 == (actionf_p1) T_VerticalDoor)
            //                {
            //                    door^.direction = -1;	// start going down immediately
            //                    // [crispy] play sound effect when the door is closed manually
            //                    if (crispy^.soundfix)
            //                    S_StartSound(&door^.sector^.soundorg, line^.special == 117 ? sfx_bdcls : sfx_dorcls);
            //                }
            //                else if (door^.thinker.function.acp1 == (actionf_p1) T_PlatRaise)
            //                {
            //                    // Erm, this is a plat, not a door.
            //                    // This notably causes a problem in ep1-0500.lmp where
            //                    // a plat and a door are cross-referenced; the door
            //                    // doesn't open on 64-bit.
            //                    // The direction field in vldoor_t corresponds to the wait
            //                    // field in plat_t.  Let's set that to -1 instead.
            //
            //                    plat_t *plat;
            //
            //                    plat = (plat_t *) door;
            //                    plat^.wait = -1;
            //                }
            //                else
            //                {
            //                    // This isn't a door OR a plat.  Now we're in trouble.
            //
            //                    fprintf(stderr, "EV_VerticalDoor: Tried to close "
            //                                    "something that wasn't a door.\n");
            //
            //                    // Try closing it anyway. At least it will work on 32-bit
            //                    // machines.
            //
            //                    door^.direction = -1;
            //                }
          End;
          exit;
        End;
    End;
  End;

  // for proper sound
  Case (line^.special) Of
    117, // BLAZING DOOR RAISE
    118: Begin // BLAZING DOOR OPEN
        S_StartSound(@sec^.soundorg, sfx_bdopn);
      End;
    1, // NORMAL DOOR SOUND
    31: Begin
        S_StartSound(@sec^.soundorg, sfx_doropn);
      End;
  Else Begin
      // LOCKED DOOR SOUND
      S_StartSound(@sec^.soundorg, sfx_doropn);
    End;
  End;

  // new door thinker
  new(door);
  If Pvldoor_ts_cnt >= high(Pvldoor_ts) Then Begin
    setlength(Pvldoor_ts, high(Pvldoor_ts) + 1025);
  End;
  Pvldoor_ts[Pvldoor_ts_cnt] := door;
  inc(Pvldoor_ts_cnt);

  P_AddThinker(@door^.thinker);
  sec^.specialdata := door;
  door^.thinker._function.acp1 := @T_VerticalDoor;
  door^.sector := sec;
  door^.direction := 1;
  door^.speed := VDOORSPEED;
  door^.topwait := VDOORWAIT;

  Case (line^.special) Of
    1, 26, 27, 28: Begin
        door^._type := vld_normal;
      End;

    31, 32, 33, 34: Begin
        door^._type := vld_open;
        line^.special := 0;
      End;

    117: Begin // blazing door raise
        door^._type := vld_blazeRaise;
        door^.speed := VDOORSPEED * 4;
      End;
    118: Begin // blazing door open
        door^._type := vld_blazeOpen;
        line^.special := 0;
        door^.speed := VDOORSPEED * 4;
      End;
  End;

  // find the top and bottom of the movement range
  door^.topheight := P_FindLowestCeilingSurrounding(sec);
  door^.topheight := door^.topheight - 4 * FRACUNIT;
End;

//
// Spawn a door that closes after 30 seconds
//

Procedure P_SpawnDoorCloseIn30(sec: Psector_t);
Var
  door: Pvldoor_t;
Begin
  new(door);
  If Pvldoor_ts_cnt >= high(Pvldoor_ts) Then Begin
    setlength(Pvldoor_ts, high(Pvldoor_ts) + 1025);
  End;
  Pvldoor_ts[Pvldoor_ts_cnt] := door;
  inc(Pvldoor_ts_cnt);

  P_AddThinker(@door^.thinker);

  sec^.specialdata := door;
  sec^.special := 0;

  door^.thinker._function.acp1 := @T_VerticalDoor;
  door^.sector := sec;
  door^.direction := 0;
  door^._type := vld_normal;
  door^.speed := VDOORSPEED;
  door^.topcountdown := 30 * TICRATE;
End;

//
// Spawn a door that opens after 5 minutes
//

Procedure P_SpawnDoorRaiseIn5Mins(sec: Psector_t; secnum: int);
Var
  door: Pvldoor_t;
Begin
  new(door);
  If Pvldoor_ts_cnt >= high(Pvldoor_ts) Then Begin
    setlength(Pvldoor_ts, high(Pvldoor_ts) + 1025);
  End;
  Pvldoor_ts[Pvldoor_ts_cnt] := door;
  inc(Pvldoor_ts_cnt);

  P_AddThinker(@door^.thinker);

  sec^.specialdata := door;
  sec^.special := 0;

  door^.thinker._function.acp1 := @T_VerticalDoor;
  door^.sector := sec;
  door^.direction := 2;
  door^._type := vld_raiseIn5Mins;
  door^.speed := VDOORSPEED;
  door^.topheight := P_FindLowestCeilingSurrounding(sec);
  door^.topheight := door^.topheight - 4 * FRACUNIT;
  door^.topwait := VDOORWAIT;
  door^.topcountdown := 5 * 60 * TICRATE;
End;

Var
  i: integer;

Finalization
  For i := 0 To Pvldoor_ts_cnt - 1 Do Begin
    dispose(Pvldoor_ts[i]);
  End;
  setlength(Pvldoor_ts, 0);
  Pvldoor_ts := Nil;

End.

