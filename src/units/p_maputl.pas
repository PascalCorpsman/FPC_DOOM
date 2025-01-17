Unit p_maputl;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Procedure P_SetThingPosition(thing: pmobj_t);

Implementation

Uses
  p_mobj, p_setup, p_local
  , r_main
  ;

//
// P_SetThingPosition
// Links a thing into both a block and a subsector
// based on it's x y.
// Sets thing->subsector properly
//

Procedure P_SetThingPosition(thing: pmobj_t);
Var
  ss: Psubsector_t;
  sec: ^sector_t;
  blockx, blocky: int;
  link: PPmobj_t;
Begin

  // link into subsector
  ss := R_PointInSubsector(thing^.x, thing^.y);
  thing^.subsector := ss;

  If ((thing^.flags And MF_NOSECTOR) = 0) Then Begin

    // invisible things don't go into the sector links
    sec := ss^.sector;

    thing^.sprev := Nil;
    thing^.snext := sec^.thinglist;

    If assigned(sec^.thinglist) Then Begin
      sec^.thinglist^.sprev := thing;
    End;
    sec^.thinglist := thing;
  End;


  // link into blockmap
  If ((thing^.flags And MF_NOBLOCKMAP) = 0) Then Begin
    // inert things don't need to be in blockmap
    blockx := SarLongint(thing^.x - bmaporgx, MAPBLOCKSHIFT);
    blocky := SarLongint(thing^.y - bmaporgy, MAPBLOCKSHIFT);

    If (blockx >= 0)
      And (blockx < bmapwidth)
      And (blocky >= 0)
      And (blocky < bmapheight) Then Begin
      link := @blocklinks[blocky * bmapwidth + blockx];
      thing^.bprev := Nil;
      thing^.bnext := @link;
      If assigned(link^) Then Begin
        (link^)^.bprev := thing;
      End;
      link^ := thing;
    End
    Else Begin
      // thing is off the map
      thing^.bnext := Nil;
      thing^.bprev := Nil;
    End;
  End;
End;

End.

