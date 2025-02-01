Unit p_floor;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , p_spec
  ;

Function EV_DoFloor(line: Pline_t; floortype: floor_e): int;

Function T_MovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t; crush: boolean; floorOrCeiling: int; direction: int): result_e;

Implementation

Uses
  d_loop
  , p_map
  ;

//
// HANDLE FLOOR TYPES
//

Function EV_DoFloor(line: Pline_t; floortype: floor_e): int;
Var
  //   int			secnum;
  rtn: int;
  //    int			i;
  //    sector_t*		sec;
  //    floormove_t*	floor;

Begin
  //
  //    secnum = -1;
  rtn := 0;
  //    while ((secnum = P_FindSectorFromLineTag(line,secnum)) >= 0)
  //    {
  //	sec = &sectors[secnum];
  //
  //	// ALREADY MOVING?  IF SO, KEEP GOING...
  //	if (sec->specialdata)
  //	    continue;
  //
  //	// new floor thinker
  //	rtn = 1;
  //	floor = Z_Malloc (sizeof(*floor), PU_LEVSPEC, 0);
  //	P_AddThinker (&floor->thinker);
  //	sec->specialdata = floor;
  //	floor->thinker.function.acp1 = (actionf_p1) T_MoveFloor;
  //	floor->type = floortype;
  //	floor->crush = false;
  //
  //	switch(floortype)
  //	{
  //	  case lowerFloor:
  //	    floor->direction = -1;
  //	    floor->sector = sec;
  //	    floor->speed = FLOORSPEED;
  //	    floor->floordestheight =
  //		P_FindHighestFloorSurrounding(sec);
  //	    break;
  //
  //	  case lowerFloorToLowest:
  //	    floor->direction = -1;
  //	    floor->sector = sec;
  //	    floor->speed = FLOORSPEED;
  //	    floor->floordestheight =
  //		P_FindLowestFloorSurrounding(sec);
  //	    break;
  //
  //	  case turboLower:
  //	    floor->direction = -1;
  //	    floor->sector = sec;
  //	    floor->speed = FLOORSPEED * 4;
  //	    floor->floordestheight =
  //		P_FindHighestFloorSurrounding(sec);
  //	    if (gameversion <= exe_doom_1_2 ||
  //	        floor->floordestheight != sec->floorheight)
  //		floor->floordestheight += 8*FRACUNIT;
  //	    break;
  //
  //	  case raiseFloorCrush:
  //	    floor->crush = true;
  //	  case raiseFloor:
  //	    floor->direction = 1;
  //	    floor->sector = sec;
  //	    floor->speed = FLOORSPEED;
  //	    floor->floordestheight =
  //		P_FindLowestCeilingSurrounding(sec);
  //	    if (floor->floordestheight > sec->ceilingheight)
  //		floor->floordestheight = sec->ceilingheight;
  //	    floor->floordestheight -= (8*FRACUNIT)*
  //		(floortype == raiseFloorCrush);
  //	    break;
  //
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
  //	  default:
  //	    break;
  //	}
  //    }
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

End.

