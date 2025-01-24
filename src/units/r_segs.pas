Unit r_segs;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , tables
  , m_fixed
  , r_defs
  , v_patch
  ;

Var
  // angle to line origin
  rw_angle1: angle_t;

  walllights: Array Of Plighttable_t;
  markceiling: boolean;
  spryscale: fixed_t;
  sprtopscreen: int64_t; // [crispy] WiggleFix

Procedure R_StoreWallRange(start, stop: int);

Procedure R_RenderMaskedSegRange(ds: int; x1, x2: int);
Procedure R_DrawMaskedColumn(column: Pcolumn_t);

Implementation

Uses
  doomdata, info_types
  , am_map
  , i_video
  , r_bsp, r_main, r_data, r_things, r_sky, r_plane, r_draw, r_bmaps
  ;

Const
  DEFINE_HEIGHTBITS = 12;
  DEFINE_HEIGHTUNIT = (1 Shl DEFINE_HEIGHTBITS);

Var

  max_rwscale: int = 64 * FRACUNIT;
  heightbits: int = 12;
  heightunit: int = (1 Shl 12);
  invhgtbits: int = 4;

  // OPTIMIZE: closed two sided lines as single sided

  // True if any of the segs textures might be visible.
  segtextured: boolean;

  // False if the back side is the same plane.
  markfloor: boolean;

  maskedtexture: boolean;
  toptexture: int;
  bottomtexture: int;
  midtexture: int;

  rw_normalangle: angle_t;

  //
  // regular wall
  //
  rw_x: int;
  rw_stopx: int;
  rw_centerangle: angle_t;
  rw_offset: fixed_t;
  rw_distance: fixed_t;
  rw_scale: fixed_t;
  rw_scalestep: fixed_t;
  rw_midtexturemid: fixed_t;
  rw_toptexturemid: fixed_t;
  rw_bottomtexturemid: fixed_t;

  worldtop: int;
  worldbottom: int;
  worldhigh: int;
  worldlow: int;

  pixhigh: int64_t; // [crispy] WiggleFix
  pixlow: int64_t; // [crispy] WiggleFix
  pixhighstep: fixed_t;
  pixlowstep: fixed_t;

  topfrac: int64_t; // [crispy] WiggleFix
  topstep: fixed_t;

  bottomfrac: int64_t; // [crispy] WiggleFix
  bottomstep: fixed_t;

  //  lighttable_t**	walllights;

  maskedtexturecol: ^int; // [crispy] 32-bit integer math

  //
  // R_RenderSegLoop
  // Draws zero, one, or two textures (and possibly a masked
  //  texture) for walls.
  // Can draw or mark the starting pixel of floor and ceiling
  //  textures.
  // CALLED: CORE LOOPING ROUTINE.
  //

Procedure R_RenderSegLoop();
Var
  angle: angle_t;
  index: unsigned;
  yl: int;
  yh: int;
  mid: int;
  texturecolumn: fixed_t;
  top: int;
  bottom: int;
Begin
  While rw_x < rw_stopx Do Begin

    // mark floor / ceiling areas
    yl := SarLongint((topfrac + heightunit - 1), heightbits); // [crispy] WiggleFix

    // no space above wall?
    If (yl < ceilingclip[rw_x] + 1) Then
      yl := ceilingclip[rw_x] + 1;

    If (markceiling) Then Begin

      top := ceilingclip[rw_x] + 1;
      bottom := yl - 1;

      If (bottom >= floorclip[rw_x]) Then
        bottom := floorclip[rw_x] - 1;

      If (top <= bottom) Then Begin
        visplanes[ceilingplane].top[rw_x] := top;
        visplanes[ceilingplane].bottom[rw_x] := bottom;
      End;
    End;

    yh := SarLongint(bottomfrac, heightbits); // [crispy] WiggleFix

    If (yh >= floorclip[rw_x]) Then
      yh := floorclip[rw_x] - 1;

    If (markfloor) Then Begin

      top := yh + 1;
      bottom := floorclip[rw_x] - 1;
      If (top <= ceilingclip[rw_x]) Then
        top := ceilingclip[rw_x] + 1;
      If (top <= bottom) Then Begin
        visplanes[floorplane].top[rw_x] := top;
        visplanes[floorplane].bottom[rw_x] := bottom;
      End;
    End;

    // texturecolumn and lighting are independent of wall tiers
    If (segtextured) Then Begin

      // calculate texture offset
      angle := (angle_t(rw_centerangle + xtoviewangle[rw_x])) Shr ANGLETOFINESHIFT;
      texturecolumn := rw_offset - FixedMul(finetangent[angle], rw_distance);
      texturecolumn := SarLongint(texturecolumn, FRACBITS);
      // calculate lighting
      index := SarLongint(rw_scale, (LIGHTSCALESHIFT + crispy.hires));

      If (index >= MAXLIGHTSCALE) Then
        index := MAXLIGHTSCALE - 1;

      // [crispy] optional brightmaps
      dc_colormap[0] := walllights[index];

      If (Not assigned(fixedcolormap)) And ((crispy.brightmaps And BRIGHTMAPS_TEXTURES) <> 0) Then Begin
        dc_colormap[1] := colormaps;
      End
      Else Begin
        dc_colormap[1] := dc_colormap[0];
      End;
      dc_x := rw_x;
      dc_iscale := $FFFFFFFF Div unsigned(rw_scale);
    End
    Else Begin
      // purely to shut up the compiler
      texturecolumn := 0;
    End;

    // draw the wall tiers
    If (midtexture <> 0) Then Begin
      // single sided line
      dc_yl := yl;
      dc_yh := yh;
      dc_texturemid := rw_midtexturemid;
      dc_source := R_GetColumn(midtexture, texturecolumn);
      dc_texheight := SarLongint(textureheight[midtexture], FRACBITS); // [crispy] Tutti-Frutti fix
      dc_brightmap := texturebrightmap[midtexture];
      colfunc();
      ceilingclip[rw_x] := viewheight;
      floorclip[rw_x] := -1;
    End
    Else Begin
      // two sided line
      If (toptexture <> 0) Then Begin
        // top wall
        mid := SarInt64(pixhigh, heightbits); // [crispy] WiggleFix
        pixhigh := pixhigh + pixhighstep;

        If (mid >= floorclip[rw_x]) Then
          mid := floorclip[rw_x] - 1;

        If (mid >= yl) Then Begin
          dc_yl := yl;
          dc_yh := mid;
          dc_texturemid := rw_toptexturemid;
          dc_source := R_GetColumn(toptexture, texturecolumn);
          dc_texheight := SarLongint(textureheight[toptexture], FRACBITS); // [crispy] Tutti-Frutti fix
          dc_brightmap := texturebrightmap[toptexture];
          colfunc();
          ceilingclip[rw_x] := mid;
        End
        Else
          ceilingclip[rw_x] := yl - 1;
      End
      Else Begin
        // no top wall
        If (markceiling) Then
          ceilingclip[rw_x] := yl - 1;
      End;

      If (bottomtexture <> 0) Then Begin

        // bottom wall
        mid := SarInt64((pixlow + heightunit - 1), heightbits); // [crispy] WiggleFix
        pixlow := pixlow + pixlowstep;

        // no space above wall?
        If (mid <= ceilingclip[rw_x]) Then
          mid := ceilingclip[rw_x] + 1;

        If (mid <= yh) Then Begin
          dc_yl := mid;
          dc_yh := yh;
          dc_texturemid := rw_bottomtexturemid;
          dc_source := R_GetColumn(bottomtexture, texturecolumn);
          dc_texheight := SarLongint(textureheight[bottomtexture], FRACBITS); // [crispy] Tutti-Frutti fix
          dc_brightmap := texturebrightmap[bottomtexture];
          colfunc();
          floorclip[rw_x] := mid;
        End
        Else
          floorclip[rw_x] := yh + 1;
      End
      Else Begin
        // no bottom wall
        If (markfloor) Then
          floorclip[rw_x] := yh + 1;
      End;

      If (maskedtexture) Then Begin
        // save texturecol
        //  for backdrawing of masked mid texture
        maskedtexturecol[rw_x] := texturecolumn;
      End;
    End;

    rw_scale := rw_scale + rw_scalestep;
    topfrac := topfrac + topstep;
    bottomfrac := bottomfrac + bottomstep;
    rw_x := rw_x + 1;
  End;
End;

Type
  TScaleValue = Record
    clamp: int;
    heightbits: int;
  End;

Const
  scale_values: Array[0..7] Of TScaleValue =
  (
    (clamp: 2048 * FRACUNIT; heightbits: 12),
    (clamp: 1024 * FRACUNIT; heightbits: 12),
    (clamp: 1024 * FRACUNIT; heightbits: 11),
    (clamp: 512 * FRACUNIT; heightbits: 11),
    (clamp: 512 * FRACUNIT; heightbits: 10),
    (clamp: 256 * FRACUNIT; heightbits: 10),
    (clamp: 256 * FRACUNIT; heightbits: 9),
    (clamp: 128 * FRACUNIT; heightbits: 9)
    );

Procedure R_FixWiggle(sector: Psector_t);
Const
  lastheight: int = 0;
Var
  height: int;
Begin
  height := SarLongint(sector^.interpceilingheight - sector^.interpfloorheight, FRACBITS);

  // disallow negative heights. using 1 forces cache initialization
  If (height < 1) Then
    height := 1;

  // early out?
  If (height <> lastheight) Then Begin

    lastheight := height;

    // initialize, or handle moving sector
    If (height <> sector^.cachedheight) Then Begin

      sector^.cachedheight := height;
      sector^.scaleindex := 0;
      height := height Shr 7;

      // calculate adjustment
      While (height <> 0) Do Begin
        height := height Shr 1;
        sector^.scaleindex := sector^.scaleindex + 1
      End;
    End;

    // fine-tune renderer for this wall
    max_rwscale := scale_values[sector^.scaleindex].clamp;
    heightbits := scale_values[sector^.scaleindex].heightbits;
    heightunit := (1 Shl heightbits);
    invhgtbits := FRACBITS - heightbits;
  End;
End;


// [crispy] WiggleFix: move R_ScaleFromGlobalAngle function to r_segs.c,
// above R_StoreWallRange

Function R_ScaleFromGlobalAngle(visangle: angle_t): fixed_t;
Var
  anglea: angle_t;
  angleb: angle_t;
  den: int;
  scale, num: fixed_t;
Begin
  anglea := angle_t(ANG90 + (visangle - viewangle));
  angleb := angle_t(ANG90 + (visangle - rw_normalangle));
  den := FixedMul(rw_distance, finesine[anglea Shr ANGLETOFINESHIFT]);
  num := FixedMul(projection, finesine[angleb Shr ANGLETOFINESHIFT]) Shl detailshift;

  If (den > (num Shr 16)) Then Begin

    scale := FixedDiv(num, den);

    // [kb] When this evaluates True, the scale is clamped,
    //  and there will be some wiggling.
    If (scale > max_rwscale) Then
      scale := max_rwscale
    Else If (scale < 256) Then
      scale := 256;
  End
  Else
    scale := max_rwscale;

  result := scale;
End;

//
// R_StoreWallRange
// A wall segment will be drawn
//  between start and stop pixels (inclusive).
//

Procedure R_StoreWallRange(start, stop: int);
Var
  vtop: fixed_t;
  lightnum, i: int;
  dx, dy, dx1, dy1, dist: int64_t; // [crispy] fix long wall wobble
  len: uint32_t;
  numdrawsegs_old: int;
  doorclosed: boolean;
Begin
  len := curline^.length;
  // [crispy] remove MAXDRAWSEGS Vanilla limit
  If (ds_p = numdrawsegs) Then Begin
    numdrawsegs_old := numdrawsegs;
    If numdrawsegs <> 0 Then Begin
      numdrawsegs := numdrawsegs * 2;
    End
    Else Begin
      numdrawsegs := MAXDRAWSEGS;
    End;
    //	drawsegs = I_Realloc(drawsegs, numdrawsegs * sizeof(*drawsegs));
    setlength(drawsegs, numdrawsegs);
    For i := numdrawsegs_old To high(drawsegs) Do Begin
      FillChar(drawsegs[i], sizeof(drawsegs[i]), 0);
    End;
    If (numdrawsegs_old <> 0) Then Begin
      writeln(stderr, format('R_StoreWallRange: Hit MAXDRAWSEGS limit at %d, raised to %d.', [numdrawsegs_old, numdrawsegs]));
    End;
  End;

  //#ifdef RANGECHECK
  //    if (start >=viewwidth || start > stop)
  //	I_Error ("Bad R_RenderWallRange: %i to %i", start , stop);
  //#endif

  sidedef := curline^.sidedef;
  linedef := curline^.linedef;

  // mark the segment as visible for auto map
  linedef^.flags := linedef^.flags Or ML_MAPPED;

  // [crispy] (flags & ML_MAPPED) is all we need to know for automap
  If (automapactive) And (crispy.automapoverlay = 0) Then exit;


  // calculate rw_distance for scale calculation
  rw_normalangle := angle_t(curline^.r_angle + ANG90); // [crispy] use re-calculated angle

  // [crispy] fix long wall wobble
  // thank you very much Linguica, e6y and kb1
  // http://www.doomworld.com/vb/post/1340718
  // shift right to avoid possibility of int64 overflow in rw_distance calculation
  dx := SarInt64(int64(curline^.v2^.r_x - curline^.v1^.r_x), 1);
  dy := SarInt64(int64(curline^.v2^.r_y - curline^.v1^.r_y), 1);
  dx1 := SarInt64(int64(viewx - curline^.v1^.r_x), 1);
  dy1 := SarInt64(int64(viewy - curline^.v1^.r_y), 1);
  dist := ((dy * dx1 - dx * dy1) Div len) Shl 1;
  If dist < INT_MIN Then Begin
    rw_distance := INT_MIN;
  End
  Else Begin
    If dist > INT_MAX Then Begin
      rw_distance := INT_MAX;
    End
    Else Begin
      rw_distance := dist;
    End;
  End;
  drawsegs[ds_p].x1 := start;
  rw_x := start;
  drawsegs[ds_p].x2 := stop;
  drawsegs[ds_p].curline := curline;
  rw_stopx := stop + 1;

  // [crispy] WiggleFix: add this line, in r_segs.c:R_StoreWallRange,
  // right before calls to R_ScaleFromGlobalAngle:
  R_FixWiggle(frontsector);

  // calculate scale at both ends and step
  drawsegs[ds_p].scale1 := R_ScaleFromGlobalAngle(angle_t(viewangle + xtoviewangle[start]));
  rw_scale := drawsegs[ds_p].scale1;

  If (stop > start) Then Begin
    drawsegs[ds_p].scale2 := R_ScaleFromGlobalAngle(angle_t(viewangle + xtoviewangle[stop]));
    drawsegs[ds_p].scalestep := (drawsegs[ds_p].scale2 - rw_scale) Div (stop - start);
    rw_scalestep := drawsegs[ds_p].scalestep;
  End
  Else Begin
    // UNUSED: try to fix the stretched line bug
   //#if 0
   //	if (rw_distance < FRACUNIT/2)
   //	{
   //	    fixed_t		trx,try;
   //	    fixed_t		gxt,gyt;
   //
   //	    trx = curline^.v1^.x - viewx;
   //	    try = curline^.v1^.y - viewy;
   //
   //	    gxt = FixedMul(trx,viewcos);
   //	    gyt = -FixedMul(try,viewsin);
   //	    ds_p^.scale1 = FixedDiv(projection, gxt-gyt)<<detailshift;
   //	}
   //#endif
    drawsegs[ds_p].scale2 := drawsegs[ds_p].scale1;
  End;

  // calculate texture boundaries
  //  and decide if floor / ceiling marks are needed
  worldtop := frontsector^.interpceilingheight - viewz;
  worldbottom := frontsector^.interpfloorheight - viewz;

  midtexture := 0;
  toptexture := 0;
  bottomtexture := 0;
  maskedtexture := false;
  drawsegs[ds_p].maskedtexturecol := Nil;

  If Not assigned(backsector) Then Begin

    // single sided line
    midtexture := texturetranslation[sidedef^.midtexture];
    // a single sided line is terminal, so it must mark ends
    markfloor := true;
    markceiling := true;
    If (linedef^.flags And ML_DONTPEGBOTTOM) <> 0 Then Begin
      vtop := frontsector^.interpfloorheight +
        textureheight[sidedef^.midtexture];
      // bottom of texture at bottom
      rw_midtexturemid := vtop - viewz;
    End
    Else Begin
      // top of texture at top
      rw_midtexturemid := worldtop;
    End;
    rw_midtexturemid := rw_midtexturemid + sidedef^.rowoffset;

    drawsegs[ds_p].silhouette := SIL_BOTH;
    drawsegs[ds_p].sprtopclip := screenheightarray;
    drawsegs[ds_p].sprbottomclip := negonearray;
    drawsegs[ds_p].bsilheight := INT_MAX;
    drawsegs[ds_p].tsilheight := INT_MIN;
  End
  Else Begin
    // [crispy] fix sprites being visible behind closed doors
    // adapted from mbfsrc/R_BSP.C:234-257
    doorclosed :=
      // if door is closed because back is shut:
    (backsector^.interpceilingheight <= backsector^.interpfloorheight
      // preserve a kind of transparent door/lift special effect:
      ) And ((backsector^.interpceilingheight >= frontsector^.interpceilingheight) Or (
      curline^.sidedef^.toptexture <> 0)
      ) And ((backsector^.interpfloorheight <= frontsector^.interpfloorheight) Or (
      curline^.sidedef^.bottomtexture <> 0)
      // properly render skies (consider door "open" if both ceilings are sky):
      ) And ((backsector^.ceilingpic <> skyflatnum) Or (
      frontsector^.ceilingpic <> skyflatnum));

    // two sided line
    drawsegs[ds_p].sprtopclip := Nil;
    drawsegs[ds_p].sprbottomclip := Nil;
    drawsegs[ds_p].silhouette := 0;

    If (frontsector^.interpfloorheight > backsector^.interpfloorheight) Then Begin
      drawsegs[ds_p].silhouette := SIL_BOTTOM;
      drawsegs[ds_p].bsilheight := frontsector^.interpfloorheight;
    End
    Else If (backsector^.interpfloorheight > viewz) Then Begin
      drawsegs[ds_p].silhouette := SIL_BOTTOM;
      drawsegs[ds_p].bsilheight := INT_MAX;
      // drawsegs[ds_p].sprbottomclip = negonearray;
    End;

    If (frontsector^.interpceilingheight < backsector^.interpceilingheight) Then Begin
      drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette Or SIL_TOP;
      drawsegs[ds_p].tsilheight := frontsector^.interpceilingheight;
    End
    Else If (backsector^.interpceilingheight < viewz) Then Begin
      drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette Or SIL_TOP;
      drawsegs[ds_p].tsilheight := INT_MIN;
      // drawsegs[ds_p].sprtopclip = screenheightarray;
    End;

    If (backsector^.interpceilingheight <= frontsector^.interpfloorheight) Or (doorclosed) Then Begin
      drawsegs[ds_p].sprbottomclip := negonearray;
      drawsegs[ds_p].bsilheight := INT_MAX;
      drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette Or SIL_BOTTOM;
    End;

    If (backsector^.interpfloorheight >= frontsector^.interpceilingheight) Or (doorclosed) Then Begin
      drawsegs[ds_p].sprtopclip := screenheightarray;
      drawsegs[ds_p].tsilheight := INT_MIN;
      drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette Or SIL_TOP;
    End;

    worldhigh := backsector^.interpceilingheight - viewz;
    worldlow := backsector^.interpfloorheight - viewz;

    // hack to allow height changes in outdoor areas
    If (frontsector^.ceilingpic = skyflatnum)
      And (backsector^.ceilingpic = skyflatnum) Then Begin
      worldtop := worldhigh;
    End;

    If (worldlow <> worldbottom) Or
      (backsector^.floorpic <> frontsector^.floorpic) Or
      (backsector^.rlightlevel <> frontsector^.rlightlevel)
      Then Begin
      markfloor := true;
    End
    Else Begin
      // same plane on both sides
      markfloor := false;
    End;

    If (worldhigh <> worldtop)
      Or (backsector^.ceilingpic <> frontsector^.ceilingpic)
      Or (backsector^.rlightlevel <> frontsector^.rlightlevel)
      Then Begin
      markceiling := true;
    End
    Else Begin
      // same plane on both sides
      markceiling := false;
    End;

    If (backsector^.interpceilingheight <= frontsector^.interpfloorheight)
      Or (backsector^.interpfloorheight >= frontsector^.interpceilingheight) Then Begin
      // closed door
      markceiling := true;
      markfloor := true;
    End;


    If (worldhigh < worldtop) Then Begin

      // top texture
      toptexture := texturetranslation[sidedef^.toptexture];
      If (linedef^.flags And ML_DONTPEGTOP) <> 0 Then Begin

        // top of texture at top
        rw_toptexturemid := worldtop;
      End
      Else Begin
        vtop := backsector^.interpceilingheight
          + textureheight[sidedef^.toptexture];

        // bottom of texture
        rw_toptexturemid := vtop - viewz;
      End;
    End;
    If (worldlow > worldbottom) Then Begin

      // bottom texture
      bottomtexture := texturetranslation[sidedef^.bottomtexture];

      If (linedef^.flags And ML_DONTPEGBOTTOM) <> 0 Then Begin
        // bottom of texture at bottom
        // top of texture at top
        rw_bottomtexturemid := worldtop;
      End
      Else // top of texture at top
        rw_bottomtexturemid := worldlow;
    End;
    rw_toptexturemid := rw_toptexturemid + sidedef^.rowoffset;
    rw_bottomtexturemid := rw_bottomtexturemid + sidedef^.rowoffset;

    // allocate space for masked texture tables
    If (sidedef^.midtexture <> 0) Then Begin

      // masked midtexture
      maskedtexture := true;
      drawsegs[ds_p].maskedtexturecol := lastopening - rw_x;
      maskedtexturecol := pointer(lastopening - rw_x);
      lastopening := lastopening + rw_stopx - rw_x;
    End;
  End;

  // calculate rw_offset (only needed for textured lines)
  segtextured := (midtexture <> 0) Or (toptexture <> 0) Or (bottomtexture <> 0) Or maskedtexture;

  If (segtextured) Then Begin
    // [crispy] fix long wall wobble
    rw_offset := fixed_t((((dx * dx1 + dy * dy1) Div len) Shl 1));
    rw_offset := rw_offset + sidedef^.textureoffset + curline^.offset;
    rw_centerangle := angle_t(ANG90 + viewangle - rw_normalangle);

    // calculate light table
    //  use different light tables
    //  for horizontal / vertical / diagonal
    // OPTIMIZE: get rid of LIGHTSEGSHIFT globally
    If Not assigned(fixedcolormap) Then Begin

      lightnum := (frontsector^.rlightlevel Shr LIGHTSEGSHIFT) + (extralight * LIGHTBRIGHT); // [crispy] A11Y

      // [crispy] smoother fake contrast
      lightnum := lightnum + curline^.fakecontrast;
      (*
           if (curline^.v1^.y == curline^.v2^.y)
        lightnum--;
           else if (curline^.v1^.x == curline^.v2^.x)
        lightnum++;
      *)

      If (lightnum < 0) Then
        walllights := scalelight[0]
      Else If (lightnum >= LIGHTLEVELS) Then
        walllights := scalelight[LIGHTLEVELS - 1]
      Else
        walllights := scalelight[lightnum];
    End;
  End;

  // if a floor / ceiling plane is on the wrong side
  //  of the view plane, it is definitely invisible
  //  and doesn't need to be marked.

  If (frontsector^.interpfloorheight >= viewz) Then Begin
    // above view plane
    markfloor := false;
  End;

  If (frontsector^.interpceilingheight <= viewz)
    And (frontsector^.ceilingpic <> skyflatnum) Then Begin

    // below view plane
    markceiling := false;
  End;

  // calculate incremental stepping values for texture edges
  worldtop := SarLongint(worldtop, invhgtbits);
  worldbottom := SarLongint(worldbottom, invhgtbits);

  topstep := -FixedMul(rw_scalestep, worldtop);
  topfrac := SarInt64(int64_t(centeryfrac), invhgtbits) - SarInt64((int64_t(worldtop) * rw_scale), FRACBITS); // [crispy] WiggleFix

  bottomstep := -FixedMul(rw_scalestep, worldbottom);
  bottomfrac := SarInt64(int64_t(centeryfrac), invhgtbits) - SarInt64((int64_t(worldbottom) * rw_scale), FRACBITS); // [crispy] WiggleFix

  If assigned(backsector) Then Begin

    worldhigh := SarLongint(worldhigh, invhgtbits);
    worldlow := SarLongint(worldlow, invhgtbits);

    If (worldhigh < worldtop) Then Begin

      pixhigh := SarInt64(int64_t(centeryfrac), invhgtbits) - SarInt64((int64_t(worldhigh) * rw_scale), FRACBITS); // [crispy] WiggleFix
      pixhighstep := -FixedMul(rw_scalestep, worldhigh);
    End;

    If (worldlow > worldbottom) Then Begin
      pixlow := SarInt64(int64_t(centeryfrac), invhgtbits) - SarInt64((int64_t(worldlow) * rw_scale), FRACBITS); // [crispy] WiggleFix
      pixlowstep := -FixedMul(rw_scalestep, worldlow);
    End;
  End;

  // render it
  If (markceiling) Then Begin
    ceilingplane := R_CheckPlane(ceilingplane, rw_x, rw_stopx - 1);
  End;

  If (markfloor) Then Begin
    floorplane := R_CheckPlane(floorplane, rw_x, rw_stopx - 1);
  End;

  R_RenderSegLoop();

  // save sprite clipping info
  If (((drawsegs[ds_p].silhouette And SIL_TOP) <> 0) Or (maskedtexture))
    And (Not assigned(drawsegs[ds_p].sprtopclip)) Then Begin
    move(ceilingclip[start], lastopening^, sizeof(int) * (rw_stopx - start));
    drawsegs[ds_p].sprtopclip := lastopening - start;
    inc(lastopening, (rw_stopx - start));
  End;

  If (((drawsegs[ds_p].silhouette And SIL_BOTTOM) <> 0) Or (maskedtexture))
    And (Not assigned(drawsegs[ds_p].sprbottomclip)) Then Begin
    move(floorclip[start], lastopening^, sizeof(int) * (rw_stopx - start));
    drawsegs[ds_p].sprbottomclip := lastopening - start;
    inc(lastopening, (rw_stopx - start));
  End;

  If (maskedtexture) And ((drawsegs[ds_p].silhouette And SIL_TOP) = 0) Then Begin
    drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette Or SIL_TOP;
    drawsegs[ds_p].tsilheight := INT_MIN;
  End;

  If (maskedtexture) And ((drawsegs[ds_p].silhouette And SIL_BOTTOM) = 0) Then Begin
    drawsegs[ds_p].silhouette := drawsegs[ds_p].silhouette + SIL_BOTTOM;
    drawsegs[ds_p].bsilheight := INT_MAX;
  End;

  inc(ds_p);
End;

//
// R_DrawMaskedColumn
// Used for sprites and masked mid textures.
// Masked means: partly transparent, i.e. stored
//  in posts/runs of opaque pixels.
//

Procedure R_DrawMaskedColumn(column: Pcolumn_t);
Var
  topscreen: int64_t; // [crispy] WiggleFix
  bottomscreen: int64_t; // [crispy] WiggleFix
  basetexturemid: fixed_t;
  top: int;
Begin
  top := -1;
  basetexturemid := dc_texturemid;
  dc_texheight := 0; // [crispy] Tutti-Frutti fix

  While column^.topdelta <> $FF Do Begin
    // [crispy] support for DeePsea tall patches
    If (column^.topdelta <= top) Then Begin
      top := top + column^.topdelta;
    End
    Else Begin
      top := column^.topdelta;
    End;
    // calculate unclipped screen coordinates
    //  for post
    topscreen := sprtopscreen + spryscale * top;
    bottomscreen := topscreen + spryscale * column^.length;

    dc_yl := int(SarInt64(topscreen + FRACUNIT - 1, FRACBITS)); // [crispy] WiggleFix
    dc_yh := int(SarInt64(bottomscreen - 1, FRACBITS)); // [crispy] WiggleFix

    If (dc_yh >= mfloorclip[dc_x]) Then
      dc_yh := mfloorclip[dc_x] - 1;
    If (dc_yl <= mceilingclip[dc_x]) Then
      dc_yl := mceilingclip[dc_x] + 1;

    If (dc_yl <= dc_yh) Then Begin

      dc_source := pointer(column) + 3;
      dc_texturemid := basetexturemid - (top Shl FRACBITS);
      // dc_source = (byte *)column + 3 - top;

      // Drawn by either R_DrawColumn
      //  or (SHADOW) R_DrawFuzzColumn.
      colfunc();
    End;
    column := pointer(column) + column^.length + 4;
  End;
  dc_texturemid := basetexturemid;
End;

Procedure R_RenderMaskedSegRange(ds: int; x1, x2: int);
Var
  index: unsigned;
  col: ^column_t;
  lightnum: int;
  texnum: int;
  t: int64_t;
Begin
  // Calculate light table.
  // Use different light tables
  //   for horizontal / vertical / diagonal. Diagonal?
  // OPTIMIZE: get rid of LIGHTSEGSHIFT globally
  curline := drawsegs[ds].curline;
  frontsector := curline^.frontsector;
  backsector := curline^.backsector;
  texnum := texturetranslation[curline^.sidedef^.midtexture];

  lightnum := (frontsector^.rlightlevel Shr LIGHTSEGSHIFT) + (extralight * LIGHTBRIGHT); // [crispy] A11Y

  // [crispy] smoother fake contrast
  lightnum := lightnum + curline^.fakecontrast;
  (*
      if (curline.v1.y == curline.v2.y)
   lightnum--;
      else if (curline.v1.x == curline.v2.x)
   lightnum++;
  *)

  If (lightnum < 0) Then
    walllights := scalelight[0]
  Else If (lightnum >= LIGHTLEVELS) Then
    walllights := scalelight[LIGHTLEVELS - 1]
  Else
    walllights := scalelight[lightnum];

  maskedtexturecol := drawsegs[ds].maskedtexturecol;

  rw_scalestep := drawsegs[ds].scalestep;
  spryscale := drawsegs[ds].scale1 + (x1 - drawsegs[ds].x1) * rw_scalestep;
  mfloorclip := @drawsegs[ds].sprbottomclip[0];
  mceilingclip := @drawsegs[ds].sprtopclip[0];

  // find positioning
  If (curline^.linedef^.flags And ML_DONTPEGBOTTOM) <> 0 Then Begin
    If frontsector^.interpfloorheight > backsector^.interpfloorheight Then Begin
      dc_texturemid := frontsector^.interpfloorheight;
    End
    Else Begin
      dc_texturemid := backsector^.interpfloorheight;
    End;
    dc_texturemid := dc_texturemid + textureheight[texnum] - viewz;
  End
  Else Begin
    If frontsector^.interpceilingheight < backsector^.interpceilingheight Then Begin
      dc_texturemid := frontsector^.interpceilingheight;
    End
    Else Begin
      dc_texturemid := backsector^.interpceilingheight;
    End;
    dc_texturemid := dc_texturemid - viewz;
  End;
  dc_texturemid := dc_texturemid + curline^.sidedef^.rowoffset;

  If assigned(fixedcolormap) Then Begin
    dc_colormap[0] := fixedcolormap;
    dc_colormap[1] := fixedcolormap;
  End;

  // draw the columns
  For dc_x := x1 To x2 Do Begin
    // calculate lighting
    If (maskedtexturecol[dc_x] <> INT_MAX) Then Begin // [crispy] 32-bit integer math

      If (fixedcolormap = Nil) Then Begin
        index := spryscale Shr (LIGHTSCALESHIFT + crispy.hires);

        If (index >= MAXLIGHTSCALE) Then index := MAXLIGHTSCALE - 1;

        // [crispy] brightmaps for mid-textures
        dc_brightmap := texturebrightmap[texnum];
        dc_colormap[0] := walllights[index];
        If (crispy.brightmaps And BRIGHTMAPS_TEXTURES) <> 0 Then Begin
          dc_colormap[1] := colormaps;
        End
        Else Begin
          dc_colormap[1] := dc_colormap[0];
        End;
      End;

      // [crispy] apply Killough's int64 sprtopscreen overflow fix
      // from winmbf/Source/r_segs.c:174-191
      // killough 3/2/98:
      //
      // This calculation used to overflow and cause crashes in Doom:
      //
      // sprtopscreen = centeryfrac - FixedMul(dc_texturemid, spryscale);
      //
      // This code fixes it, by using double-precision intermediate
      // arithmetic and by skipping the drawing of 2s normals whose
      // mapping to screen coordinates is totally out of range:

      Begin
        t := (int64_t(centeryfrac) Shl FRACBITS) - int64_t(dc_texturemid) * spryscale;
        If (t + int64_t(textureheight[texnum]) * spryscale < 0) Or (
          t > int64_t(SCREENHEIGHT) Shl FRACBITS * 2) Then Begin
          spryscale := spryscale + rw_scalestep; // [crispy] MBF had this in the for-loop iterator
          continue; // skip if the texture is out of screen's range
        End;

        sprtopscreen := SarInt64(t, FRACBITS); // [crispy] WiggleFix
      End;

      dc_iscale := unsigned($FFFFFFFF) Div unsigned(spryscale);

      // draw the texture
      col := pointer(pointer(R_GetColumnMod(texnum, maskedtexturecol[dc_x]) - 3));

      R_DrawMaskedColumn(col);
      maskedtexturecol[dc_x] := INT_MAX; // [crispy] 32-bit integer math
    End;
    spryscale := spryscale + rw_scalestep;
  End;
End;

End.

