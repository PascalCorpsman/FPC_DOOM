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

Implementation

//
// Restart a ceiling that's in-stasis
//

Procedure P_ActivateInStasisCeiling(line: Pline_t);
Begin
  Raise Exception.Create('Port me.');
  //      int		i;
  //
  //    for (i = 0;i < MAXCEILINGS;i++)
  //    {
  //	if (activeceilings[i]
  //	    && (activeceilings[i]->tag == line->tag)
  //	    && (activeceilings[i]->direction == 0))
  //	{
  //	    activeceilings[i]->direction = activeceilings[i]->olddirection;
  //	    activeceilings[i]->thinker.function.acp1
  //	      = (actionf_p1)T_MoveCeiling;
  //	}
  //    }
End;

//
// EV_DoCeiling
// Move a ceiling up/down and all around!
//

Function EV_DoCeiling(line: Pline_t; _type: ceiling_e): int;
Begin
  Raise Exception.Create('Port me.');
  //   int		secnum;
  //   int		rtn;
  //   sector_t*	sec;
  //   ceiling_t*	ceiling;
  //
  //   secnum = -1;
  //   rtn = 0;
  //
  //   //	Reactivate in-stasis ceilings...for certain types.
  //   switch(type)
  //   {
  //     case fastCrushAndRaise:
  //     case silentCrushAndRaise:
  //     case crushAndRaise:
  //P_ActivateInStasisCeiling(line);
  //     default:
  //break;
  //   }
  //
  //   while ((secnum = P_FindSectorFromLineTag(line,secnum)) >= 0)
  //   {
  //sec = &sectors[secnum];
  //if (sec->specialdata)
  //    continue;
  //
  //// new door thinker
  //rtn = 1;
  //ceiling = Z_Malloc (sizeof(*ceiling), PU_LEVSPEC, 0);
  //P_AddThinker (&ceiling->thinker);
  //sec->specialdata = ceiling;
  //ceiling->thinker.function.acp1 = (actionf_p1)T_MoveCeiling;
  //ceiling->sector = sec;
  //ceiling->crush = false;
  //
  //switch(type)
  //{
  //  case fastCrushAndRaise:
  //    ceiling->crush = true;
  //    ceiling->topheight = sec->ceilingheight;
  //    ceiling->bottomheight = sec->floorheight + (8*FRACUNIT);
  //    ceiling->direction = -1;
  //    ceiling->speed = CEILSPEED * 2;
  //    break;
  //
  //  case silentCrushAndRaise:
  //  case crushAndRaise:
  //    ceiling->crush = true;
  //    ceiling->topheight = sec->ceilingheight;
  //  case lowerAndCrush:
  //  case lowerToFloor:
  //    ceiling->bottomheight = sec->floorheight;
  //    if (type != lowerToFloor)
  //	ceiling->bottomheight += 8*FRACUNIT;
  //    ceiling->direction = -1;
  //    ceiling->speed = CEILSPEED;
  //    break;
  //
  //  case raiseToHighest:
  //    ceiling->topheight = P_FindHighestCeilingSurrounding(sec);
  //    ceiling->direction = 1;
  //    ceiling->speed = CEILSPEED;
  //    break;
  //}
  //
  //ceiling->tag = sec->tag;
  //ceiling->type = type;
  //P_AddActiveCeiling(ceiling);
  //   }
  //   return rtn;
End;

End.

