Unit r_plane;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , i_video
  , m_fixed
  , r_data, r_defs
  ;

Const
  PL_SKYFLAT = unsigned_int($80000000);

Var
  yslope: ^Fixed_t;
  yslopes: Array[0..LOOKDIRS - 1, 0..MAXHEIGHT - 1] Of fixed_t;

  floorplane: Pvisplane_t;
  ceilingplane: Pvisplane_t;

Procedure R_InitPlanes();
Procedure R_ClearPlanes();

Function R_FindPlane(height: fixed_t; picnum: int; lightlevel: int): Pvisplane_t;

Implementation

Uses
  tables
  , r_draw, r_main, r_sky
  ;

Var

  //
  // Clip values are the solid pixel bounding the range.
  //  floorclip starts out SCREENHEIGHT
  //  ceilingclip starts out -1
  //
  floorclip: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math
  ceilingclip: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math

Const
  // Here comes the obnoxious "visplane".
  MAXVISPLANES = 128;
  MAXOPENINGS = MAXWIDTH * 64 * 4;

Var
  visplanes: Array Of visplane_t = Nil;
  lastvisplane: int;
  numvisplanes: int = 0;

  openings: Array[0..MAXOPENINGS - 1] Of int; // [crispy] 32-bit integer math
  lastopening: P_int; // [crispy] 32-bit integer math

  //
  // spanstart holds the start of a plane span
  // initialized to 0 at start
  //
  spanstart: Array[0..MAXHEIGHT - 1] Of int;
  spanstop: Array[0..MAXHEIGHT - 1] Of int;

  //
  // texture mapping
  //
//  lighttable_t**		planezlight;
//  fixed_t			planeheight;

  distscale: Array[0..MAXWIDTH - 1] Of fixed_t;
  basexscale: fixed_t;
  baseyscale: fixed_t;

  cachedheight: Array[0..MAXHEIGHT - 1] Of fixed_t;
  cacheddistance: Array[0..MAXHEIGHT - 1] Of fixed_t;
  cachedxstep: Array[0..MAXHEIGHT - 1] Of fixed_t;
  cachedystep: Array[0..MAXHEIGHT - 1] Of fixed_t;
  //
  // R_InitPlanes
  // Only at game startup.
  //

Procedure R_InitPlanes();
Begin
  // Doh!
End;

//
// R_ClearPlanes
// At begining of frame.
//

Procedure R_ClearPlanes();
Var
  i: int;
  angle: angle_t;
Begin
  // opening / clipping determination
  For i := 0 To viewwidth - 1 Do Begin
    floorclip[i] := viewheight;
    ceilingclip[i] := -1;
  End;

  lastvisplane := 0;
  lastopening := openings;

  // texture calculation
  fillchar(cachedheight[0], sizeof(cachedheight), 0);

  // left to right mapping
  angle := (viewangle - ANG90) Shr ANGLETOFINESHIFT;

  // scale will be unit scale at SCREENWIDTH/2 distance
  basexscale := FixedDiv(finecosine[angle], centerxfrac);
  baseyscale := -FixedDiv(finesine[angle], centerxfrac);
End;

Procedure R_RaiseVisplanes(vp: int);
Var
  k, numvisplanes_old: int;
Begin
  If Not assigned(visplanes) Or (vp >= length(visplanes)) Then Begin
    numvisplanes_old := length(visplanes);
    If numvisplanes_old <> 0 Then Begin
      numvisplanes := 2 * numvisplanes;
    End
    Else Begin
      numvisplanes := MAXVISPLANES;
    End;
    setlength(visplanes, numvisplanes);

    For k := numvisplanes_old To high(visplanes) Do Begin
      FillChar(visplanes[k], sizeof(visplanes[k]), 0);
    End;
    floorplane := @visplanes[0];
    ceilingplane := @visplanes[0];

    If (numvisplanes_old <> 0) Then Begin
      writeln(stderr, format('R_FindPlane: Hit MAXVISPLANES limit at %d, raised to %d.', [numvisplanes_old, numvisplanes]));
    End;
  End;
End;

Function R_FindPlane(height: fixed_t; picnum: int; lightlevel: int
  ): Pvisplane_t;
Var
  check: int;
Begin
  // [crispy] add support for MBF sky tranfers
  If (picnum = skyflatnum) Or ((picnum And PL_SKYFLAT) <> 0) Then Begin

    lightlevel := 0; // killough 7/19/98: most skies map together

    // haleyjd 05/06/08: but not all. If height > viewpoint.z, set height to 1
    // instead of 0, to keep ceilings mapping with ceilings, and floors mapping
    // with floors.
    If (height > viewz) Then
      height := 1
    Else
      height := 0;
  End;

  For check := 0 To lastvisplane - 1 Do Begin
    If (height = visplanes[check].height)
      And (picnum = visplanes[check].picnum)
      And (lightlevel = visplanes[check].lightlevel) Then Begin
      result := @visplanes[check];
      exit;
    End;
  End;
  check := lastvisplane;

  R_RaiseVisplanes(check); // [crispy] remove VISPLANES limit

  //    if (lastvisplane - visplanes == MAXVISPLANES && false)
  //	I_Error ("R_FindPlane: no more visplanes");

  lastvisplane := lastvisplane + 1;

  visplanes[check].height := height;
  visplanes[check].picnum := picnum;
  visplanes[check].lightlevel := lightlevel;
  visplanes[check].minx := SCREENWIDTH;
  visplanes[check].maxx := -1;
  FillChar(visplanes[check].top, sizeof(visplanes[check].top), 0);

  result := @visplanes[check];
End;

//Initialization
//  setlength(visplanes, 128);

End.

