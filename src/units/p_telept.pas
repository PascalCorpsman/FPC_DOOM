Unit p_telept;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Function EV_Teleport(line: Pline_t; side: int; thing: Pmobj_t): int;

Implementation

Uses
  doomstat, sounds, tables
  , d_mode
  , p_mobj, p_setup, p_tick, p_map
  , s_sound
  ;

//
// TELEPORTATION
//

Function EV_Teleport(line: Pline_t; side: int; thing: Pmobj_t): int;
Var
  i, tag: int;
  m, fog: pmobj_t;
  an: unsigned;
  thinker: Pthinker_t;
  sector: Psector_t;
  oldx, oldy, oldz: fixed_t;
Begin

  // don't teleport missiles
  If (thing^.flags And MF_MISSILE) <> 0 Then Begin
    result := 0;
    exit;
  End;

  // Don't teleport if hit back of line,
  //  so you can get out of teleporter.
  If (side = 1) Then Begin
    result := 0;
    exit;
  End;


  tag := line^.tag;

  For i := 0 To numsectors - 1 Do Begin

    If (sectors[i].tag = tag) Then Begin

      thinker := thinkercap.next;
      While thinker <> @thinkercap Do Begin
        //	    for (thinker = thinkercap.next;
        //		 thinker != &thinkercap;
        //		 thinker = thinker->next)
        // not a mobj
        If (thinker^._function.acp1 <> @P_MobjThinker) Then Begin
          thinker := thinker^.next;
          continue;
        End;

        m := pmobj_t(thinker);

        // not a teleportman
        If (m^._type <> MT_TELEPORTMAN) Then Begin
          thinker := thinker^.next;
          continue;
        End;

        sector := m^.subsector^.sector;
        // wrong sector
        If ((sector - @sectors[0]) Div SizeOf(sectors[0]) <> i) Then Begin
          thinker := thinker^.next;
          continue;
        End;
        oldx := thing^.x;
        oldy := thing^.y;
        oldz := thing^.z;

        If (Not P_TeleportMove(thing, m^.x, m^.y)) Then Begin
          result := 0;
          exit;
        End;

        // The first Final Doom executable does not set thing^.z
        // when teleporting. This quirk is unique to this
        // particular version; the later version included in
        // some versions of the Id Anthology fixed this.

        If (gameversion <> exe_final) Then
          thing^.z := thing^.floorz;

        If assigned(thing^.player) Then Begin

          thing^.player^.viewz := thing^.z + thing^.player^.viewheight;
          // [crispy] center view after teleporting
          thing^.player^.centering := true;
        End;

        // spawn teleport fog at source and destination
        fog := P_SpawnMobj(oldx, oldy, oldz, MT_TFOG);
        S_StartSound(fog, sfx_telept);
        an := m^.angle Shr ANGLETOFINESHIFT;
        fog := P_SpawnMobj(m^.x + 20 * finecosine[an], m^.y + 20 * finesine[an]
          , thing^.z, MT_TFOG);

        // emit sound, where?
        S_StartSound(fog, sfx_telept);

        // don't move for a bit
        If assigned(thing^.player) Then
          thing^.reactiontime := 18;
        thing^.angle := m^.angle;
        thing^.momx := 0;
        thing^.momy := 0;
        thing^.momz := 0;
        result := 1;
        exit;
      End;
    End;
  End;
  result := 0;
End;

End.

