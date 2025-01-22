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

  visplanes: Array Of visplane_t = Nil;
  floorplane: int;
  ceilingplane: int;

  distscale: Array[0..MAXWIDTH - 1] Of fixed_t;
  lastopening: P_int; // [crispy] 32-bit integer math
  //
  // Clip values are the solid pixel bounding the range.
  //  floorclip starts out SCREENHEIGHT
  //  ceilingclip starts out -1
  //
  floorclip: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math
  ceilingclip: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math

Procedure R_InitPlanes();
Procedure R_ClearPlanes();

Function R_FindPlane(height: fixed_t; picnum: int; lightlevel: int): int;

Function R_CheckPlane(pl: int; start, stop: int): int;

Procedure R_DrawPlanes();

Implementation

Uses
  tables, info_types
  , p_setup
  , r_draw, r_main, r_sky, r_segs, r_things, r_bmaps
  , w_wad
  , z_zone
  ;

Const
  // Here comes the obnoxious "visplane".
  MAXVISPLANES = 128;
  MAXOPENINGS = MAXWIDTH * 64 * 4;

Var
  lastvisplane: int;
  numvisplanes: int = 0;

  openings: Array[0..MAXOPENINGS - 1] Of int; // [crispy] 32-bit integer math

  //
  // spanstart holds the start of a plane span
  // initialized to 0 at start
  //
  spanstart: Array[0..MAXHEIGHT - 1] Of int;
  spanstop: Array[0..MAXHEIGHT - 1] Of int;

  //
  // texture mapping
  //
  planezlight: Array Of plighttable_t;
  planeheight: fixed_t;

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
  angle := angle_t(viewangle - ANG90) Shr ANGLETOFINESHIFT;

  // scale will be unit scale at SCREENWIDTH/2 distance
  basexscale := FixedDiv(finecosine[angle], centerxfrac);
  baseyscale := -FixedDiv(finesine[angle], centerxfrac);
End;

Procedure R_RaiseVisplanes(vp: int);
Var
  k, numvisplanes_old: int;
Begin
  If Not assigned(visplanes) Or (vp >= length(visplanes) - 1) Then Begin
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
    floorplane := 0;
    ceilingplane := 0;

    If (numvisplanes_old <> 0) Then Begin
      writeln(stderr, format('R_FindPlane: Hit MAXVISPLANES limit at %d, raised to %d.', [numvisplanes_old, numvisplanes]));
    End;
  End;
End;

Function R_FindPlane(height: fixed_t; picnum: int; lightlevel: int
  ): int;
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
      result := check;
      exit;
    End;
  End;

  R_RaiseVisplanes(lastvisplane); // [crispy] remove VISPLANES limit

  //    if (lastvisplane - visplanes == MAXVISPLANES && false)
  //	I_Error ("R_FindPlane: no more visplanes");

  check := lastvisplane;
  lastvisplane := lastvisplane + 1;

  visplanes[check].height := height;
  visplanes[check].picnum := picnum;
  visplanes[check].lightlevel := lightlevel;
  visplanes[check].minx := SCREENWIDTH;
  visplanes[check].maxx := -1;
  FillChar(visplanes[check].top[-1], sizeof(visplanes[check].top), $FF);

  result := check;
End;

Function R_CheckPlane(pl: int; start, stop: int): int;
Var
  intrl: int;
  intrh: int;
  unionl: int;
  unionh: int;
  x: int;
Begin
  If (start < visplanes[pl].minx) Then Begin
    intrl := visplanes[pl].minx;
    unionl := start;
  End
  Else Begin
    unionl := visplanes[pl].minx;
    intrl := start;
  End;
  If (stop > visplanes[pl].maxx) Then Begin
    intrh := visplanes[pl].maxx;
    unionh := stop;
  End
  Else Begin
    unionh := visplanes[pl].maxx;
    intrh := stop;
  End;

  For x := intrl To intrh Do
    If (visplanes[pl].top[x] <> $FFFFFFFF) Then // [crispy] hires / 32-bit integer math
      break;

  // [crispy] fix HOM if ceilingplane and floorplane are the same
  // visplane (e.g. both are skies)
  If (Not (pl = floorplane) And (markceiling) And (floorplane = ceilingplane)) Then Begin
    If (x > intrh) Then Begin
      visplanes[pl].minx := unionl;
      visplanes[pl].maxx := unionh;
      // use the same one
      result := pl;
      exit;
    End;
  End;

  // make a new visplane
//  R_RaiseVisplanes(pl); // [crispy] remove VISPLANES limit
  R_RaiseVisplanes(lastvisplane); // Corpsman
  visplanes[lastvisplane].height := visplanes[pl].height;
  visplanes[lastvisplane].picnum := visplanes[pl].picnum;
  visplanes[lastvisplane].lightlevel := visplanes[pl].lightlevel;

  //  If (lastvisplane - visplanes = MAXVISPLANES) And (false) Then // [crispy] remove VISPLANES limit
  //    I_Error('R_CheckPlane: no more visplanes');
  inc(lastvisplane);
  pl := lastvisplane;
  visplanes[pl].minx := start;
  visplanes[pl].maxx := stop;

  FillChar(visplanes[pl].top[-1], sizeof(visplanes[pl].top), $FF);

  result := pl;
End;

//
// R_MapPlane
//
// Uses global vars:
//  planeheight
//  ds_source
//  basexscale
//  baseyscale
//  viewx
//  viewy
//
// BASIC PRIMITIVE
//

Procedure R_MapPlane(y, x1, x2: int);
Var
  // [crispy] see below
  //  angle_t	angle;
  distance: fixed_t;
  //  fixed_t	length;
  index: unsigned;
  dx, dy: int;
Begin

  //#ifdef RANGECHECK
  //    if (x2 < x1
  //     || x1 < 0
  //     || x2 >= viewwidth
  //     || y > viewheight)
  //    {
  //	I_Error ("R_MapPlane: %i, %i at %i",x1,x2,y);
  //    }
  //#endif

  // [crispy] visplanes with the same flats now match up far better than before
  // adapted from prboom-plus/src/r_plane.c:191-239, translated to fixed-point math
  //
  // SoM: because centery is an actual row of pixels (and it isn't really the
  // center row because there are an even number of rows) some corrections need
  // to be made depending on where the row lies relative to the centery row.

  If (centery = y) Then exit;
  If y < centery Then Begin
    dy := (abs(centery - y) Shl FRACBITS) + (-FRACUNIT) Div 2;
  End
  Else Begin
    dy := (abs(centery - y) Shl FRACBITS) + (FRACUNIT) Div 2;
  End;

  If (planeheight <> cachedheight[y]) Then Begin
    cachedheight[y] := planeheight;
    distance := FixedMul(planeheight, yslope[y]);
    cacheddistance[y] := distance;
    ds_xstep := FixedDiv(FixedMul(viewsin, planeheight), dy) Shl detailshift;
    cachedxstep[y] := ds_xstep;
    ds_ystep := FixedDiv(FixedMul(viewcos, planeheight), dy) Shl detailshift;
    cachedystep[y] := ds_ystep;
  End
  Else Begin
    distance := cacheddistance[y];
    ds_xstep := cachedxstep[y];
    ds_ystep := cachedystep[y];
  End;

  dx := x1 - centerx;

  ds_xfrac := viewx + FixedMul(viewcos, distance) + dx * ds_xstep;
  ds_yfrac := -viewy - FixedMul(viewsin, distance) + dx * ds_ystep;

  If assigned(fixedcolormap) Then Begin
    ds_colormap[0] := fixedcolormap;
    ds_colormap[1] := fixedcolormap;
  End
  Else Begin
    index := distance Shr LIGHTZSHIFT;

    If (index >= MAXLIGHTZ) Then
      index := MAXLIGHTZ - 1;

    ds_colormap[0] := @planezlight[index][0];
    ds_colormap[1] := colormaps;
  End;

  ds_y := y;
  ds_x1 := x1;
  ds_x2 := x2;

  // high or low detail
  spanfunc();
End;

//
// R_MakeSpans
//

Procedure R_MakeSpans(x: int; t1, b1, t2, b2: unsigned_int);
Begin
  While (t1 < t2) And (t1 <= b1) Do Begin
    R_MapPlane(t1, spanstart[t1], x - 1);
    t1 := t1 + 1;
  End;
  While (b1 > b2) And (b1 >= t1) Do Begin
    R_MapPlane(b1, spanstart[b1], x - 1);
    b1 := b1 - 1;
  End;
  While (t2 < t1) And (t2 <= b2) Do Begin
    spanstart[t2] := x;
    t2 := t2 + 1;
  End;
  While (b2 > b1) And (b2 >= t2) Do Begin
    spanstart[b2] := x;
    b2 := b2 - 1;
  End;
End;

//
// R_DrawPlanes
// At the end of each frame.
//

Procedure R_DrawPlanes();
Var
  pl: int;
  texture, light, x, stop, angle, lumpnum: int;
  swirling: Boolean;
  an, flip: angle_t;
  l: ^line_t;
  s: ^side_t;
Begin
  //#ifdef RANGECHECK
  //    if (ds_p - drawsegs > numdrawsegs)
  //	I_Error ("R_DrawPlanes: drawsegs overflow (%td)",
  //		 ds_p - drawsegs);
  //
  //    if (lastvisplane - visplanes > numvisplanes)
  //	I_Error ("R_DrawPlanes: visplane overflow (%td)",
  //		 lastvisplane - visplanes);
  //
  //    if (lastopening - openings > MAXOPENINGS)
  //	I_Error ("R_DrawPlanes: opening overflow (%td)",
  //		 lastopening - openings);
  //#endif

  For pl := 0 To lastvisplane - 1 Do Begin

    If (visplanes[pl].minx > visplanes[pl].maxx) Then
      continue;

    // sky flat
    // [crispy] add support for MBF sky tranfers
    If (visplanes[pl].picnum = skyflatnum) Or ((visplanes[pl].picnum And PL_SKYFLAT) <> 0) Then Begin
      an := viewangle;
      If (visplanes[pl].picnum And PL_SKYFLAT) <> 0 Then Begin
        l := @lines[visplanes[pl].picnum And Not PL_SKYFLAT];
        s := @sides[l^.sidenum[0]]; // WTF: ich glaube nicht das das so funktioniert ..
        texture := texturetranslation[s^.toptexture];
        dc_texturemid := s^.rowoffset - 28 * FRACUNIT;
        If l^.special = 272 Then Begin
          flip := 0;
        End
        Else Begin
          flip := angle_t(Not 0);
        End;
        an := angle_t(an + s^.textureoffset);
      End
      Else Begin
        texture := skytexture;
        dc_texturemid := skytexturemid;
        flip := 0;
      End;
      dc_iscale := pspriteiscale Shr detailshift;

      // Sky is allways drawn full bright,
      //  i.e. colormaps[0] is used.
      // Because of this hack, sky is not affected
      //  by INVUL inverse mapping.
      // [crispy] no brightmaps for sky
      dc_colormap[0] := colormaps;
      dc_colormap[1] := colormaps;
      dc_texheight := SarLongint(textureheight[texture], FRACBITS); // [crispy] Tutti-Frutti fix

      // [crispy] stretch short skies
      If (crispy.stretchsky) And (dc_texheight < 200) Then Begin
        dc_iscale := dc_iscale * dc_texheight Div SKYSTRETCH_HEIGHT;
        dc_texturemid := dc_texturemid * dc_texheight Div SKYSTRETCH_HEIGHT;
      End;

      For x := visplanes[pl].minx To visplanes[pl].maxx Do Begin
        dc_yl := visplanes[pl].top[x];
        dc_yh := visplanes[pl].bottom[x];

        If (dc_yl <= dc_yh) Then Begin // [crispy] 32-bit integer math
          angle := SarLongint((an + xtoviewangle[x]) Xor flip, ANGLETOSKYSHIFT);
          dc_x := x;
          dc_source := R_GetColumnMod2(texture, angle);
          colfunc();
        End;
      End;
      continue;
    End;

    swirling := (flattranslation[visplanes[pl].picnum] = -1);
    // regular flat
    If swirling Then Begin
      lumpnum := firstflat + (visplanes[pl].picnum);
    End
    Else Begin
      lumpnum := firstflat + (flattranslation[visplanes[pl].picnum]);
    End;
    // [crispy] add support for SMMU swirling flats
    If swirling Then Begin
      Raise exception.create('Need port');
      //      ds_source := R_DistortedFlat(lumpnum);
    End
    Else Begin
      ds_source := W_CacheLumpNum(lumpnum, PU_STATIC);
    End;
    ds_brightmap := R_BrightmapForFlatNum(lumpnum - firstflat);

    planeheight := abs(visplanes[pl].height - viewz);
    light := (visplanes[pl].lightlevel Shr LIGHTSEGSHIFT) + (extralight * LIGHTBRIGHT);

    If (light >= LIGHTLEVELS) Then
      light := LIGHTLEVELS - 1;

    If (light < 0) Then light := 0;

    planezlight := zlight[light];

    // Initialisieren der Padding Bytes
    visplanes[pl].top[visplanes[pl].maxx + 1] := unsigned_int($FFFFFFFF); // [crispy] hires / 32-bit integer math
    visplanes[pl].top[visplanes[pl].minx - 1] := unsigned_int($FFFFFFFF); // [crispy] hires / 32-bit integer math
    visplanes[pl].bottom[visplanes[pl].maxx + 1] := 0;
    visplanes[pl].bottom[visplanes[pl].minx - 1] := 0;

    stop := visplanes[pl].maxx + 1;
    For x := visplanes[pl].minx To stop Do Begin
      R_MakeSpans(x, visplanes[pl].top[x - 1],
        visplanes[pl].bottom[x - 1],
        visplanes[pl].top[x],
        visplanes[pl].bottom[x]);
    End;
    //        W_ReleaseLumpNum(lumpnum);
  End;
End;

End.

