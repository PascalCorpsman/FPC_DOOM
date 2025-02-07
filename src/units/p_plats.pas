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

Implementation

//
// Do Platforms
//  "amount" is only used for SOME platforms.
//

Function EV_DoPlat(line: Pline_t; _type: plattype_e; amount: int): int;
Var
  rtn: int;
Begin
  Raise exception.create('Port me.');
  //    plat_t*	plat;
  //    int		secnum;

  //    sector_t*	sec;
  //
  //    secnum = -1;
  rtn := 0;
  //
  //
  //    //	Activate all <type> plats that are in_stasis
  //    switch(type)
  //    {
  //      case perpetualRaise:
  //	P_ActivateInStasis(line->tag);
  //	break;
  //
  //      default:
  //	break;
  //    }
  //
  //    while ((secnum = P_FindSectorFromLineTag(line,secnum)) >= 0)
  //    {
  //	sec = &sectors[secnum];
  //
  //	if (sec->specialdata)
  //	    continue;
  //
  //	// Find lowest & highest floors around sector
  //	rtn = 1;
  //	plat = Z_Malloc( sizeof(*plat), PU_LEVSPEC, 0);
  //	P_AddThinker(&plat->thinker);
  //
  //	plat->type = type;
  //	plat->sector = sec;
  //	plat->sector->specialdata = plat;
  //	plat->thinker.function.acp1 = (actionf_p1) T_PlatRaise;
  //	plat->crush = false;
  //	plat->tag = line->tag;
  //
  //	switch(type)
  //	{
  //	  case raiseToNearestAndChange:
  //	    plat->speed = PLATSPEED/2;
  //	    sec->floorpic = sides[line->sidenum[0]].sector->floorpic;
  //	    plat->high = P_FindNextHighestFloor(sec,sec->floorheight);
  //	    plat->wait = 0;
  //	    plat->status = up;
  //	    // NO MORE DAMAGE, IF APPLICABLE
  //	    sec->special = 0;
  //
  //	    S_StartSound(&sec->soundorg,sfx_stnmov);
  //	    break;
  //
  //	  case raiseAndChange:
  //	    plat->speed = PLATSPEED/2;
  //	    sec->floorpic = sides[line->sidenum[0]].sector->floorpic;
  //	    plat->high = sec->floorheight + amount*FRACUNIT;
  //	    plat->wait = 0;
  //	    plat->status = up;
  //
  //	    S_StartSound(&sec->soundorg,sfx_stnmov);
  //	    break;
  //
  //	  case downWaitUpStay:
  //	    plat->speed = PLATSPEED * 4;
  //	    plat->low = P_FindLowestFloorSurrounding(sec);
  //
  //	    if (plat->low > sec->floorheight)
  //		plat->low = sec->floorheight;
  //
  //	    plat->high = sec->floorheight;
  //	    plat->wait = TICRATE*PLATWAIT;
  //	    plat->status = down;
  //	    S_StartSound(&sec->soundorg,sfx_pstart);
  //	    break;
  //
  //	  case blazeDWUS:
  //	    plat->speed = PLATSPEED * 8;
  //	    plat->low = P_FindLowestFloorSurrounding(sec);
  //
  //	    if (plat->low > sec->floorheight)
  //		plat->low = sec->floorheight;
  //
  //	    plat->high = sec->floorheight;
  //	    plat->wait = TICRATE*PLATWAIT;
  //	    plat->status = down;
  //	    S_StartSound(&sec->soundorg,sfx_pstart);
  //	    break;
  //
  //	  case perpetualRaise:
  //	    plat->speed = PLATSPEED;
  //	    plat->low = P_FindLowestFloorSurrounding(sec);
  //
  //	    if (plat->low > sec->floorheight)
  //		plat->low = sec->floorheight;
  //
  //	    plat->high = P_FindHighestFloorSurrounding(sec);
  //
  //	    if (plat->high < sec->floorheight)
  //		plat->high = sec->floorheight;
  //
  //	    plat->wait = TICRATE*PLATWAIT;
  //	    plat->status = P_Random()&1;
  //
  //	    S_StartSound(&sec->soundorg,sfx_pstart);
  //	    break;
  //	}
  //	P_AddActivePlat(plat);
  //    }
  result := rtn;
End;

End.

