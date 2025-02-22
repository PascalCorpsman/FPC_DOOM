Unit p_floor;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , p_spec
  ;

Function EV_DoFloor(line: Pline_t; floortype: floor_e): int;
Function EV_BuildStairs(line: Pline_t; _type: stair_e): int;

Function T_MovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t; crush: boolean; floorOrCeiling: int; direction: int): result_e;

Implementation

Uses
  sounds, doomstat, doomdata
  , d_loop, d_mode
  , m_fixed
  , p_map, p_setup, p_tick
  , s_sound
  ;

Const
  STAIRS_UNINITIALIZED_CRUSH_FIELD_VALUE = 10;

Var
  AllocatedFloors: Array Of Pfloormove_t = Nil;

  //
  // MOVE A FLOOR TO IT'S DESTINATION (UP OR DOWN)
  //

Procedure T_MoveFloor(mo: Pmobj_t);
Var
  floor: Pfloormove_t;
  res: result_e;
Begin
  floor := Pfloormove_t(mo);

  res := T_MovePlane(floor^.sector,
    floor^.speed,
    floor^.floordestheight,
    floor^.crush, 0, floor^.direction);

  If ((leveltime And 7) = 0) Then
    S_StartSound(@floor^.sector^.soundorg, sfx_stnmov);

  If (res = pastdest) Then Begin
    floor^.sector^.specialdata := Nil;
    If (floor^.direction = 1) Then Begin
      Case (floor^._type) Of
        donutRaise: Begin
            floor^.sector^.special := floor^.newspecial;
            floor^.sector^.floorpic := floor^.texture;
          End;
      End;
    End
    Else If (floor^.direction = -1) Then Begin
      Case (floor^._type) Of
        lowerAndChange: Begin
            floor^.sector^.special := floor^.newspecial;
            floor^.sector^.floorpic := floor^.texture;
          End;
      End;
    End;
    P_RemoveThinker(@floor^.thinker);
    S_StartSound(@floor^.sector^.soundorg, sfx_pstop);
  End;
End;

//
// HANDLE FLOOR TYPES
//

Function EV_DoFloor(line: Pline_t; floortype: floor_e): int;
Var
  secnum: int;
  rtn: int;
  i: int;
  sec: Psector_t;
  floor: Pfloormove_t;
Begin

  secnum := -1;
  rtn := 0;
  secnum := P_FindSectorFromLineTag(line, secnum);
  While (secnum >= 0) Do Begin
    sec := @sectors[secnum];
    // ALREADY MOVING?  IF SO, KEEP GOING...
    If assigned(sec^.specialdata) Then Begin
      secnum := P_FindSectorFromLineTag(line, secnum);
      continue;
    End;

    // new floor thinker
    rtn := 1;
    new(floor);
    setlength(AllocatedFloors, high(AllocatedFloors) + 2);
    AllocatedFloors[high(AllocatedFloors)] := floor;

    P_AddThinker(@floor^.thinker);
    sec^.specialdata := floor;
    floor^.thinker._function.acp1 := @T_MoveFloor;
    floor^._type := floortype;
    floor^.crush := false;

    Case (floortype) Of
      lowerFloor: Begin
          floor^.direction := -1;
          floor^.sector := sec;
          floor^.speed := FLOORSPEED;
          floor^.floordestheight := P_FindHighestFloorSurrounding(sec);
        End;
      lowerFloorToLowest: Begin
          floor^.direction := -1;
          floor^.sector := sec;
          floor^.speed := FLOORSPEED;
          floor^.floordestheight := P_FindLowestFloorSurrounding(sec);
        End;

      turboLower: Begin
          floor^.direction := -1;
          floor^.sector := sec;
          floor^.speed := FLOORSPEED * 4;
          floor^.floordestheight := P_FindHighestFloorSurrounding(sec);
          If (gameversion <= exe_doom_1_2) Or (
            floor^.floordestheight <> sec^.floorheight) Then
            floor^.floordestheight := floor^.floordestheight + 8 * FRACUNIT;
        End;

      raiseFloorCrush,
        raiseFloor: Begin
          If floortype = raiseFloorCrush Then
            floor^.crush := true;
          floor^.direction := 1;
          floor^.sector := sec;
          floor^.speed := FLOORSPEED;
          floor^.floordestheight := P_FindLowestCeilingSurrounding(sec);
          If (floor^.floordestheight > sec^.ceilingheight) Then
            floor^.floordestheight := sec^.ceilingheight;
          If (floortype = raiseFloorCrush) Then
            floor^.floordestheight := floor^.floordestheight - (8 * FRACUNIT);
        End;

      //	  case raiseFloorTurbo:
      //	    floor->direction = 1;
      //	    floor->sector = sec;
      //	    floor->speed = FLOORSPEED*4;
      //	    floor->floordestheight =
      //		P_FindNextHighestFloor(sec,sec->floorheight);
      //	    break;
      //
      //	  case raiseFloorToNearest:
      //	    floor->direction = 1;
      //	    floor->sector = sec;
      //	    floor->speed = FLOORSPEED;
      //	    floor->floordestheight =
      //		P_FindNextHighestFloor(sec,sec->floorheight);
      //	    break;
      //
      //	  case raiseFloor24:
      //	    floor->direction = 1;
      //	    floor->sector = sec;
      //	    floor->speed = FLOORSPEED;
      //	    floor->floordestheight = floor->sector->floorheight +
      //		24 * FRACUNIT;
      //	    break;
      //	  case raiseFloor512:
      //	    floor->direction = 1;
      //	    floor->sector = sec;
      //	    floor->speed = FLOORSPEED;
      //	    floor->floordestheight = floor->sector->floorheight +
      //		512 * FRACUNIT;
      //	    break;
      //
      //	  case raiseFloor24AndChange:
      //	    floor->direction = 1;
      //	    floor->sector = sec;
      //	    floor->speed = FLOORSPEED;
      //	    floor->floordestheight = floor->sector->floorheight +
      //		24 * FRACUNIT;
      //	    sec->floorpic = line->frontsector->floorpic;
      //	    sec->special = line->frontsector->special;
      //	    break;
      //
      //	  case raiseToTexture:
      //	  {
      //	      int	minsize = INT_MAX;
      //	      side_t*	side;
      //
      //	      floor->direction = 1;
      //	      floor->sector = sec;
      //	      floor->speed = FLOORSPEED;
      //	      for (i = 0; i < sec->linecount; i++)
      //	      {
      //		  if (twoSided (secnum, i) )
      //		  {
      //		      side = getSide(secnum,i,0);
      //		      if (side->bottomtexture >= 0)
      //			  if (textureheight[side->bottomtexture] <
      //			      minsize)
      //			      minsize =
      //				  textureheight[side->bottomtexture];
      //		      side = getSide(secnum,i,1);
      //		      if (side->bottomtexture >= 0)
      //			  if (textureheight[side->bottomtexture] <
      //			      minsize)
      //			      minsize =
      //				  textureheight[side->bottomtexture];
      //		  }
      //	      }
      //	      floor->floordestheight =
      //		  floor->sector->floorheight + minsize;
      //	  }
      //	  break;
      //
      //	  case lowerAndChange:
      //	    floor->direction = -1;
      //	    floor->sector = sec;
      //	    floor->speed = FLOORSPEED;
      //	    floor->floordestheight =
      //		P_FindLowestFloorSurrounding(sec);
      //	    floor->texture = sec->floorpic;
      //
      //	    for (i = 0; i < sec->linecount; i++)
      //	    {
      //		if ( twoSided(secnum, i) )
      //		{
      //		    if (getSide(secnum,i,0)->sector-sectors == secnum)
      //		    {
      //			sec = getSector(secnum,i,1);
      //
      //			if (sec->floorheight == floor->floordestheight)
      //			{
      //			    floor->texture = sec->floorpic;
      //			    floor->newspecial = sec->special;
      //			    break;
      //			}
      //		    }
      //		    else
      //		    {
      //			sec = getSector(secnum,i,0);
      //
      //			if (sec->floorheight == floor->floordestheight)
      //			{
      //			    floor->texture = sec->floorpic;
      //			    floor->newspecial = sec->special;
      //			    break;
      //			}
      //		    }
      //		}
      //	    }
    Else Begin
        Raise exception.create('Missing type.');
      End;
    End;
    secnum := P_FindSectorFromLineTag(line, secnum);
  End;
  result := rtn;
End;

//
// BUILD A STAIRCASE!
//

Function EV_BuildStairs(line: Pline_t; _type: stair_e): int;
Var
  secnum, height, i,
    newsecnum, texture,
    ok, rtn: int;

  sec: Psector_t;
  tsec: Psector_t;

  floor: Pfloormove_t;

  stairsize: fixed_t;
  speed: fixed_t;
Begin
  stairsize := 0;
  speed := 0;
  secnum := -1;
  rtn := 0;
  secnum := P_FindSectorFromLineTag(line, secnum);
  While (secnum >= 0) Do Begin

    sec := @sectors[secnum];

    // ALREADY MOVING?  IF SO, KEEP GOING...
    If assigned(sec^.specialdata) Then Begin
      secnum := P_FindSectorFromLineTag(line, secnum);
      continue;
    End;

    // new floor thinker
    rtn := 1;
    new(floor);
    setlength(AllocatedFloors, high(AllocatedFloors) + 2);
    AllocatedFloors[high(AllocatedFloors)] := floor;
    P_AddThinker(@floor^.thinker);
    sec^.specialdata := floor;
    floor^.thinker._function.acp1 := @T_MoveFloor;
    floor^.direction := 1;
    floor^.sector := sec;
    Case (_type) Of
      build8: Begin
          speed := FLOORSPEED Div 4;
          stairsize := 8 * FRACUNIT;
        End;
      turbo16: Begin
          speed := FLOORSPEED * 4;
          stairsize := 16 * FRACUNIT;
        End;
    End;
    floor^.speed := speed;
    height := sec^.floorheight + stairsize;
    floor^.floordestheight := height;
    // Initialize
    floor^._type := lowerFloor;
    // e6y
    // Uninitialized crush field will not be equal to 0 or 1 (true)
    // with high probability. So, initialize it with any other value
    floor^.crush := odd(STAIRS_UNINITIALIZED_CRUSH_FIELD_VALUE);

    texture := sec^.floorpic;

    // Find next sector to raise
    // 1.	Find 2-sided line with same sector side[0]
    // 2.	Other side is the next sector to raise
    Repeat
      ok := 0;
      For i := 0 To sec^.linecount - 1 Do Begin

        If ((sec^.lines[i].flags And ML_TWOSIDED) = 0) Then
          continue;

        tsec := sec^.lines[i].frontsector;
        newsecnum := (tsec - @sectors[0]) Div sizeof(sectors[0]);

        If (secnum <> newsecnum) Then
          continue;

        tsec := sec^.lines[i].backsector;
        newsecnum := (tsec - @sectors[0]) Div sizeof(sectors[0]);

        If (tsec^.floorpic <> texture) Then
          continue;

        height := height + stairsize;

        If assigned(tsec^.specialdata) Then
          continue;

        sec := tsec;
        secnum := newsecnum;
        new(floor);
        setlength(AllocatedFloors, high(AllocatedFloors) + 2);
        AllocatedFloors[high(AllocatedFloors)] := floor;

        P_AddThinker(@floor^.thinker);

        sec^.specialdata := floor;
        floor^.thinker._function.acp1 := @T_MoveFloor;
        floor^.direction := 1;
        floor^.sector := sec;
        floor^.speed := speed;
        floor^.floordestheight := height;
        // Initialize
        floor^._type := lowerFloor;
        // e6y
        // Uninitialized crush field will not be equal to 0 or 1 (true)
        // with high probability. So, initialize it with any other value
        floor^.crush := odd(STAIRS_UNINITIALIZED_CRUSH_FIELD_VALUE);
        ok := 1;
        break;
      End;

    Until OK = 0;
    secnum := P_FindSectorFromLineTag(line, secnum);
  End;
  result := rtn;
End;

//
// Move a plane (floor or ceiling) and check for crushing
//

Function T_MovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: int; direction: int): result_e;

Var
  flag: boolean;
  lastpos: fixed_t;
Begin
  // [AM] Store old sector heights for interpolation.
  If (sector^.oldgametic <> gametic) Then Begin
    sector^.oldfloorheight := sector^.floorheight;
    sector^.oldceilingheight := sector^.ceilingheight;
    sector^.oldgametic := gametic;
  End;

  Case (floorOrCeiling) Of
    0: Begin
        // FLOOR
        Case (direction) Of
          -1: Begin
              // DOWN
              If (sector^.floorheight - speed < dest) Then Begin
                lastpos := sector^.floorheight;
                sector^.floorheight := dest;
                flag := P_ChangeSector(sector, crush);
                If (flag = true) Then Begin
                  sector^.floorheight := lastpos;
                  P_ChangeSector(sector, crush);
                  //return crushed;
                End;
                result := pastdest;
                exit;
              End
              Else Begin
                lastpos := sector^.floorheight;
                sector^.floorheight := sector^.floorheight - speed;
                flag := P_ChangeSector(sector, crush);
                If (flag) Then Begin
                  sector^.floorheight := lastpos;
                  P_ChangeSector(sector, crush);
                  result := crushed;
                  exit;
                End;
              End;
            End;
          1: Begin
              // UP
              If (sector^.floorheight + speed > dest) Then Begin
                lastpos := sector^.floorheight;
                sector^.floorheight := dest;
                flag := P_ChangeSector(sector, crush);
                If (flag) Then Begin
                  sector^.floorheight := lastpos;
                  P_ChangeSector(sector, crush);
                  //result :=  crushed;
                  // exit;
                End;
                result := pastdest;
                exit;
              End
              Else Begin
                // COULD GET CRUSHED
                lastpos := sector^.floorheight;
                sector^.floorheight := sector^.floorheight + speed;
                flag := P_ChangeSector(sector, crush);
                If (flag) Then Begin
                  If (crush = true) Then Begin
                    result := crushed;
                    exit;
                  End;
                  sector^.floorheight := lastpos;
                  P_ChangeSector(sector, crush);
                  result := crushed;
                  exit;
                End;
              End;
            End;
        End;
      End;
    1: Begin
        // CEILING
        Case (direction) Of
          -1: Begin
              // DOWN
              If (sector^.ceilingheight - speed < dest) Then Begin

                lastpos := sector^.ceilingheight;
                sector^.ceilingheight := dest;
                flag := P_ChangeSector(sector, crush);

                If (flag) Then Begin
                  sector^.ceilingheight := lastpos;
                  P_ChangeSector(sector, crush);
                  // result := crushed;
                  // Exit;
                End;
                result := pastdest;
                exit;
              End
              Else Begin
                // COULD GET CRUSHED
                lastpos := sector^.ceilingheight;
                sector^.ceilingheight := sector^.ceilingheight - speed;
                flag := P_ChangeSector(sector, crush);

                If (flag) Then Begin
                  If (crush = true) Then Begin
                    result := crushed;
                    exit;
                  End;
                  sector^.ceilingheight := lastpos;
                  P_ChangeSector(sector, crush);
                  result := crushed;
                  exit;
                End;
              End;
            End;
          1: Begin
              // UP
              If (sector^.ceilingheight + speed > dest) Then Begin
                lastpos := sector^.ceilingheight;
                sector^.ceilingheight := dest;
                flag := P_ChangeSector(sector, crush);
                If (flag) Then Begin

                  sector^.ceilingheight := lastpos;
                  P_ChangeSector(sector, crush);
                  // result := crushed;
                  // Exit;
                End;
                result := pastdest;
                exit;
              End
              Else Begin
                lastpos := sector^.ceilingheight;
                sector^.ceilingheight := sector^.ceilingheight + speed;
                flag := P_ChangeSector(sector, crush);
                //// UNUSED
                //#if 0
                //		if (flag == true)
                //		{
                //		    sector^.ceilingheight = lastpos;
                //		    P_ChangeSector(sector,crush);
                //		    return crushed;
                //		}
                //#endif
              End;
            End;
        End;
      End;
  End;
  result := ok;
End;

Var
  i: integer;

Finalization

  For i := 0 To high(AllocatedFloors) Do Begin
    dispose(AllocatedFloors[i]);
  End;
  setlength(AllocatedFloors, 0);

End.

