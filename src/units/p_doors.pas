Unit p_doors;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , p_spec
  ;

Function EV_DoDoor(line: Pline_t; _type: vldoor_e): int;

Implementation

Function EV_DoDoor(line: Pline_t; _type: vldoor_e): int;
Var
  secnum, rtn: int;
  //    sector_t*	sec;
  //    vldoor_t*	door;
Begin
  secnum := -1;
  rtn := 0;
  //
  //    while ((secnum = P_FindSectorFromLineTag(line,secnum)) >= 0)
  //    {
  //	sec = &sectors[secnum];
  //	if (sec->specialdata)
  //	    continue;
  //
  //
  //	// new door thinker
  //	rtn = 1;
  //	door = Z_Malloc (sizeof(*door), PU_LEVSPEC, 0);
  //	P_AddThinker (&door->thinker);
  //	sec->specialdata = door;
  //
  //	door->thinker.function.acp1 = (actionf_p1) T_VerticalDoor;
  //	door->sector = sec;
  //	door->type = type;
  //	door->topwait = VDOORWAIT;
  //	door->speed = VDOORSPEED;
  //
  //	switch(type)
  //	{
  //	  case vld_blazeClose:
  //	    door->topheight = P_FindLowestCeilingSurrounding(sec);
  //	    door->topheight -= 4*FRACUNIT;
  //	    door->direction = -1;
  //	    door->speed = VDOORSPEED * 4;
  //	    // [crispy] fix door-closing sound playing, even when door is already closed (repeatable walkover trigger)
  //	    if (door->sector->ceilingheight - door->sector->floorheight > 0 || !crispy->soundfix)
  //	    S_StartSound(&door->sector->soundorg, sfx_bdcls);
  //	    break;
  //
  //	  case vld_close:
  //	    door->topheight = P_FindLowestCeilingSurrounding(sec);
  //	    door->topheight -= 4*FRACUNIT;
  //	    door->direction = -1;
  //	    // [crispy] fix door-closing sound playing, even when door is already closed (repeatable walkover trigger)
  //	    if (door->sector->ceilingheight - door->sector->floorheight > 0 || !crispy->soundfix)
  //	    S_StartSound(&door->sector->soundorg, sfx_dorcls);
  //	    break;
  //
  //	  case vld_close30ThenOpen:
  //	    door->topheight = sec->ceilingheight;
  //	    door->direction = -1;
  //	    // [crispy] fix door-closing sound playing, even when door is already closed (repeatable walkover trigger)
  //	    if (door->sector->ceilingheight - door->sector->floorheight > 0 || !crispy->soundfix)
  //	    S_StartSound(&door->sector->soundorg, sfx_dorcls);
  //	    break;
  //
  //	  case vld_blazeRaise:
  //	  case vld_blazeOpen:
  //	    door->direction = 1;
  //	    door->topheight = P_FindLowestCeilingSurrounding(sec);
  //	    door->topheight -= 4*FRACUNIT;
  //	    door->speed = VDOORSPEED * 4;
  //	    if (door->topheight != sec->ceilingheight)
  //		S_StartSound(&door->sector->soundorg, sfx_bdopn);
  //	    break;
  //
  //	  case vld_normal:
  //	  case vld_open:
  //	    door->direction = 1;
  //	    door->topheight = P_FindLowestCeilingSurrounding(sec);
  //	    door->topheight -= 4*FRACUNIT;
  //	    if (door->topheight != sec->ceilingheight)
  //		S_StartSound(&door->sector->soundorg, sfx_doropn);
  //	    break;
  //
  //	  default:
  //	    break;
  //	}
  //
  //    }
  result := rtn;
End;

End.

