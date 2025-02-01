Unit p_sight;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , m_fixed
  ;

Var
  topslope: fixed_t;
  bottomslope: fixed_t; // slopes to top and bottom of target

Function P_CheckSight(t1: Pmobj_t; t2: Pmobj_t): boolean;

Implementation

//
// P_CheckSight
// Returns true
//  if a straight line between t1 and t2 is unobstructed.
// Uses REJECT.
//

Function P_CheckSight(t1: Pmobj_t; t2: Pmobj_t): boolean;
Begin
  Raise exception.create('Port me.');
  //    int		s1;
  //    int		s2;
  //    int		pnum;
  //    int		bytenum;
  //    int		bitnum;
  //
  //    // First check for trivial rejection.
  //
  //    // Determine subsector entries in REJECT table.
  //    s1 = (t1->subsector->sector - sectors);
  //    s2 = (t2->subsector->sector - sectors);
  //    pnum = s1*numsectors + s2;
  //    bytenum = pnum>>3;
  //    bitnum = 1 << (pnum&7);
  //
  //    // Check in REJECT table.
  //    if (rejectmatrix[bytenum]&bitnum)
  //    {
  //	sightcounts[0]++;
  //
  //	// can't possibly be connected
  //	return false;
  //    }
  //
  //    // An unobstructed LOS is possible.
  //    // Now look from eyes of t1 to any part of t2.
  //    sightcounts[1]++;
  //
  //    validcount++;
  //
  //    sightzstart = t1->z + t1->height - (t1->height>>2);
  //    topslope = (t2->z+t2->height) - sightzstart;
  //    bottomslope = (t2->z) - sightzstart;
  //
  //    if (gameversion <= exe_doom_1_2)
  //    {
  //        return P_PathTraverse(t1->x, t1->y, t2->x, t2->y,
  //                              PT_EARLYOUT | PT_ADDLINES, PTR_SightTraverse);
  //    }
  //
  //    strace.x = t1->x;
  //    strace.y = t1->y;
  //    t2x = t2->x;
  //    t2y = t2->y;
  //    strace.dx = t2->x - t1->x;
  //    strace.dy = t2->y - t1->y;
  //
  //    // the head node is the last node output
  //    return P_CrossBSPNode (numnodes-1);
End;

End.

