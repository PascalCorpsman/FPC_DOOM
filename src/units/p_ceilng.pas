Unit p_ceilng;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  ,info_types
  , p_spec;

Var
  activeceilings: Array[0..MAXCEILINGS - 1] Of Pceiling_t;

Procedure P_ActivateInStasisCeiling(line: Pline_t);

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

End.

