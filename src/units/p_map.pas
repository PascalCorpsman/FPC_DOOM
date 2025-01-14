Unit p_map;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; damage: int);

Implementation

//
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//

Procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; damage: int);
Begin
  //   int		x;
  //    int		y;
  //
  //    int		xl;
  //    int		xh;
  //    int		yl;
  //    int		yh;
  //
  //    fixed_t	dist;
  //
  //    dist = (damage+MAXRADIUS)<<FRACBITS;
  //    yh = (spot->y + dist - bmaporgy)>>MAPBLOCKSHIFT;
  //    yl = (spot->y - dist - bmaporgy)>>MAPBLOCKSHIFT;
  //    xh = (spot->x + dist - bmaporgx)>>MAPBLOCKSHIFT;
  //    xl = (spot->x - dist - bmaporgx)>>MAPBLOCKSHIFT;
  //    bombspot = spot;
  //    bombsource = source;
  //    bombdamage = damage;
  //
  //    for (y=yl ; y<=yh ; y++)
  //	for (x=xl ; x<=xh ; x++)
  //	    P_BlockThingsIterator (x, y, PIT_RadiusAttack );
End;

End.

