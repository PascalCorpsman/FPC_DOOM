Unit r_things;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , i_video
  , m_fixed
  , r_defs
  ;

Const
  MAXVISSPRITES = 128;

Var
  // [crispy] extendable, but the last char element must be zero,
  // keep in sync with multiitem_t multiitem_crosshairtype[] in m_menu.c
  laserpatch: Array[0..NUM_CROSSHAIRTYPES - 1] Of laserpatch_t = (
    (c: '+'; a: 'cross1'; l: 0; w: 0; h: 0),
    (c: '^'; a: 'cross2'; l: 0; w: 0; h: 0),
    (c: '.'; a: 'cross3'; l: 0; w: 0; h: 0)
    );

  laserspot: ^degenmobj_t = Nil; // Wird im Initialization und ganz hacky genutzt

  // variables used to look up
  //  and range check thing_t sprites patches
  numsprites: int;

  // [crispy] A11Y number of player sprites to draw
  numrpsprites: int = integer(spritenum_t(NUMPSPRITES)); // [crispy] A11Y number of player sprites to draw

  sprites: Array Of spritedef_t = Nil;
  pspr_interp: boolean = true; // interpolate weapon bobbing

  //
  // Sprite rotation 0 is facing the viewer,
  //  rotation 1 is one angle turn CLOCKWISE around the axis.
  // This is not the same as the angle,
  //  which increases counter clockwise (protractor).
  // There was a lot of stuff grabbed wrong, so I changed it...
  //
  pspritescale: fixed_t;
  pspriteiscale: fixed_t;
  // constant arrays
  //  used for psprite clipping and initializing clipping
  screenheightarray: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math
  negonearray: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math

  mfloorclip: P_int; // [crispy] 32-bit integer math
  mceilingclip: P_int; // [crispy] 32-bit integer math

Procedure R_InitSprites(Const namelist: Array Of String);

Procedure R_ClearSprites();

Procedure R_AddSprites(sec: Psector_t);
Procedure R_DrawMasked();

Implementation

Uses
  doomstat, tables, info, doomdef
  , d_loop, d_mode, d_items, d_player
  , i_system
  , p_tick, p_pspr, p_mobj, p_map, p_local
  , r_data, r_main, r_draw, r_bmaps, r_bsp, r_segs
  , v_trans, v_patch
  , w_wad
  , z_zone
  ;

Const
  MINZ = (FRACUNIT * 4);
  BASEYCENTER = (ORIGHEIGHT Div 2);

Var

  maxframe: int;
  sprtemp: Array[0..28] Of spriteframe_t;
  spritename: String;

  //
  // GAME FUNCTIONS
  //
  vissprites: Array Of vissprite_t = Nil;
  vissprite_p: int;
  newvissprite: int;
  numvissprites: int;

  spritelights: Array Of Plighttable_t;

  //
  // R_InstallSpriteLump
  // Local function for R_InitSprites.
  //

Procedure R_InstallSpriteLump(lump: int; frame: unsigned; rot: char; flipped: boolean);
Var
  r: int;
  rotation: unsigned;
Begin
  // [crispy] support 16 sprite rotations
  If ord(rot) >= ord('A') Then Begin
    rotation := ord(rot) - ord('A') + 10;
  End
  Else Begin
    If ord(rot) >= ord('0') Then Begin
      rotation := ord(rot) - ord('0');
    End
    Else Begin
      rotation := 17;
    End;
  End;

  If (frame >= 29) Or (rotation > 16) Then // [crispy] support 16 sprite rotations
    I_Error(format('R_InstallSpriteLump: Bad frame characters in lump %d', [lump]));

  If (frame > maxframe) Then maxframe := frame;

  If (rotation = 0) Then Begin
    // the lump should be used for all rotations
    // [crispy] make non-fatal
    If (sprtemp[frame].rotate = 0) Then Begin
      writeln(stderr, format('R_InitSprites: Sprite %s frame %s has multip rot = 0 lump',
        [spritename, chr(ord('A') + frame)]));
    End;

    // [crispy] make non-fatal
    If (sprtemp[frame].rotate = 1) Then Begin
      writeln(stderr, format('R_InitSprites: Sprite %s frame %s has rotations and a rot=0 lump',
        [spritename, chr(ord('A') + frame)]));
    End;

    //    [crispy]moved...
    // sprtemp[frame].rotate = false;
    For r := 0 To 8 - 1 Do Begin
      // [crispy] only if not yet substituted
      If (sprtemp[frame].lump[r] = -1) Then Begin

        sprtemp[frame].lump[r] := lump - firstspritelump;
        sprtemp[frame].flip[r] := ord(flipped);
        // [crispy] ... here
        sprtemp[frame].rotate := 0;
      End;
    End;
    exit;
  End;

  // the lump is only used for one rotation
  // [crispy] make non-fatal
  If (sprtemp[frame].rotate = 0) Then Begin
    writeln(stderr, format('R_InitSprites: Sprite %s frame %s has rotations and a rot=0 lump',
      [spritename, chr(ord('A') + frame)]));
  End;
  // [crispy] moved ...
  //    sprtemp[frame].rotate = true;

  // make 0 based
  rotation := rotation - 1;
  If (sprtemp[frame].lump[rotation] <> -1) Then Begin

    // [crispy] make non-fatal
    writeln(stderr, format('R_InitSprites: Sprite %s : %s : %s has two lumps mapped to it',
      [spritename, chr(ord('A') + frame), chr(ord('1') + rotation)]));
    exit;
  End;

  sprtemp[frame].lump[rotation] := lump - firstspritelump;
  sprtemp[frame].flip[rotation] := ord(flipped);
  // [crispy] ... here
  sprtemp[frame].rotate := 1;
End;

//
// R_InitSpriteDefs
// Pass a null terminated list of sprite names
//  (4 chars exactly) to be used.
// Builds the sprite rotation matrixes to account
//  for horizontally flipped sprites.
// Will report an error if the lumps are inconsistant.
// Only called at startup.
//
// Sprite lump names are 4 characters for the actor,
//  a letter for the frame, and a number for the rotation.
// A sprite that is flippable will have an additional
//  letter/number appended.
// The rotation character can be 0 to signify no rotations.
//

Procedure R_InitSpriteDefs(Const namelist: Array Of String);
Var
  rotation: char;
  frame, i, l, r: int;
  start: int;
  _end: int;
  patched: int;
Begin
  numsprites := length(namelist);

  If (numsprites = 0) Then exit;
  setlength(sprites, numsprites);
  start := firstspritelump - 1;
  _end := lastspritelump + 1;

  // scan all the lump names for each of the names,
  //  noting the highest frame letter.
  // Just compare 4 characters as ints
  For i := 0 To numsprites - 1 Do Begin

    spritename := namelist[i];
    FillChar(sprtemp[0], sizeof(sprtemp), $FF);

    maxframe := -1;

    // scan the lumps,
    //  filling in the frames for whatever is found
    For l := start + 1 To _end - 1 Do Begin

      If copy(lumpinfo[l].name, 1, 4) = uppercase(copy(spritename, 1, 4)) Then Begin
        frame := ord(lumpinfo[l].name[5]) - ord('A');
        rotation := lumpinfo[l].name[6];

        If (modifiedgame) Then Begin
          patched := W_GetNumForName(lumpinfo[l].name);
        End
        Else Begin
          patched := l;
        End;

        R_InstallSpriteLump(patched, frame, rotation, false);

        If length(lumpinfo[l].name) >= 8 Then Begin
          frame := ord(lumpinfo[l].name[7]) - ord('A');
          rotation := lumpinfo[l].name[8];
          R_InstallSpriteLump(l, frame, rotation, true);
        End;
      End;
    End;

    // check the frames that were found for completeness
    If (maxframe = -1) Then Begin
      sprites[i].numframes := 0;
      continue;
    End;

    maxframe := maxframe + 1;

    For Frame := 0 To maxframe - 1 Do Begin
      Case sprtemp[frame].rotate Of
        -1: Begin
            // no rotations were found for that frame at all
            // [crispy] make non-fatal
            writeln(stderr, format('R_InitSprites: No patches found for %s frame %s\',
              [spritename, chr(frame + ord('A'))]));
          End;
        0: Begin
            // only the first rotation is needed
          End;
        1: Begin
            // must have all 8 frames
            For r := 0 To 8 - 1 Do Begin
              If (sprtemp[frame].lump[r] = -1) Then Begin
                I_Error(format('R_InitSprites: Sprite %s frame %s is missing rotations',
                  [spritename, chr(frame + ord('A'))]));
              End;
            End;
            // [crispy] support 16 sprite rotations
            sprtemp[frame].rotate := 2;
            For r := 8 To 16 - 1 Do Begin
              If (sprtemp[frame].lump[r] = -1) Then Begin
                sprtemp[frame].rotate := 1;
                break;
              End;
            End;
          End;
      End;
    End;

    // allocate space for the frames present and copy sprtemp to it
    sprites[i].numframes := maxframe;
    setlength(sprites[i].spriteframes, maxframe);
    move(sprtemp[0], sprites[i].spriteframes[0], maxframe * sizeof(spriteframe_t));
  End;
End;

//
// R_InitSprites
// Called at program start.
//

Procedure R_InitSprites(Const namelist: Array Of String);
Var
  i: int;
Begin
  For i := 0 To SCREENWIDTH - 1 Do Begin // WTF: das wird aufgerufen befor SCREENWIDTH initialisiert wird -> Eigentlich nutzlos
    negonearray[i] := -1;
  End;

  R_InitSpriteDefs(namelist);
End;

//
// R_ClearSprites
// Called at frame start.
//

Procedure R_ClearSprites();
Begin
  vissprite_p := 0;
End;

Var
  overflowsprite: vissprite_t;

Function R_NewVisSprite(): Pvissprite_t;
Const
  max: int = 0;

Var
  numvissprites_old, i: int;
Begin
  // [crispy] remove MAXVISSPRITE Vanilla limit
  If (vissprite_p = length(vissprites)) Then Begin
    // Der unten stehende Code müsste eigentlich gehen, aber wenn die AV Kommt schauen wir uns das mal an ;)
    numvissprites_old := numvissprites;
    // [crispy] cap MAXVISSPRITES limit at 4096
    If (max = 0) And (numvissprites = 32 * MAXVISSPRITES) Then Begin
      writeln(stderr, format('R_NewVisSprite: MAXVISSPRITES limit capped at %d.', [numvissprites]));
      max := max + 1;
    End;

    If (max <> 0) Then Begin
      result := @overflowsprite;
      exit;
    End;

    If numvissprites <> 0 Then Begin
      numvissprites := 2 * numvissprites;
    End
    Else Begin
      numvissprites := MAXVISSPRITES;
    End;
    setlength(vissprites, numvissprites);
    For i := numvissprites_old To numvissprites - 1 Do Begin
      fillchar(vissprites[i], sizeof(vissprites[i]), 0);
    End;

    If (numvissprites_old <> 0) Then
      writeln(stderr, format('R_NewVisSprite: Hit MAXVISSPRITES limit at %d, raised to %d.', [numvissprites_old, numvissprites]));
  End;
  result := @vissprites[vissprite_p];
  inc(vissprite_p);
End;

//
// R_ProjectSprite
// Generates a vissprite for a thing
//  if it might be visible.
//

Procedure R_ProjectSprite(thing: Pmobj_t);
Var
  tr_x: fixed_t;
  tr_y: fixed_t;

  gxt: fixed_t;
  gyt: fixed_t;
  gzt: fixed_t; // [JN] killough 3/27/98

  tx: fixed_t;
  tz: fixed_t;

  xscale: fixed_t;

  x1: int;
  x2: int;

  sprdef: ^spritedef_t;
  sprframe: ^spriteframe_t;
  lump: int;

  rot: unsigned;
  flip: boolean;

  index: int;

  vis: Pvissprite_t;

  ang: angle_t;
  iscale: fixed_t;

  interpx: fixed_t;
  interpy: fixed_t;
  interpz: fixed_t;
  interpangle: fixed_t;
  rot2: unsigned;
Begin

  // [AM] Interpolate between current and last position,
  //      if prudent.
  If (crispy.uncapped <> 0) And
    // Don't interpolate if the mobj did something
    // that would necessitate turning it off for a tic.
  (thing^.interp <> 0) And
    // Don't interpolate during a paused state.
  (leveltime > oldleveltime)
    Then Begin
    interpx := LerpFixed(thing^.oldx, thing^.x);
    interpy := LerpFixed(thing^.oldy, thing^.y);
    interpz := LerpFixed(thing^.oldz, thing^.z);
    interpangle := LerpAngle(thing^.oldangle, thing^.angle);
  End
  Else Begin
    interpx := thing^.x;
    interpy := thing^.y;
    interpz := thing^.z;
    interpangle := fixed_t(thing^.angle);
  End;

  // transform the origin point
  tr_x := interpx - viewx;
  tr_y := interpy - viewy;

  gxt := FixedMul(tr_x, viewcos);
  gyt := -FixedMul(tr_y, viewsin);

  tz := gxt - gyt;

  // thing is behind view plane?
  If (tz < MINZ) Then exit;

  xscale := FixedDiv(projection, tz);

  gxt := -FixedMul(tr_x, viewsin);
  gyt := FixedMul(tr_y, viewcos);
  tx := -(gyt + gxt);

  // too far off the side?
  If (abs(tx) > (tz Shl 2)) Then exit;

  // decide which patch to use for sprite relative to player
//#ifdef RANGECHECK
//    if ((unsigned int) thing^.sprite >= (unsigned int) numsprites)
//	I_Error ("R_ProjectSprite: invalid sprite number %i ",
//		 thing^.sprite);
//#endif
  sprdef := @sprites[integer(thing^.sprite)];
  // [crispy] the TNT1 sprite is not supposed to be rendered anyway
  If (sprdef^.numframes = 0) And (thing^.sprite = SPR_TNT1) Then Begin
    exit;
  End;

  //#ifdef RANGECHECK
  //    if ( (thing^.frame&FF_FRAMEMASK) >= sprdef^.numframes )
  //	I_Error ("R_ProjectSprite: invalid sprite frame %i : %i ",
  //		 thing^.sprite, thing^.frame);
  //#endif
  sprframe := @sprdef^.spriteframes[thing^.frame And FF_FRAMEMASK];

  If (sprframe^.rotate <> 0) Then Begin
    // choose a different rotation based on player view
    ang := R_PointToAngle(interpx, interpy);
    // [crispy] now made non-fatal
    If (sprframe^.rotate = -1) Then Begin
      exit;
    End
    Else If (sprframe^.rotate = 2) Then Begin
      rot2 := unsigned((ang - interpangle + (ANG45 Div 4) * 17));
      rot := (rot2 Shr 29) + ((rot2 Shr 25) And 8);
    End
    Else Begin
      rot := (unsigned(ang - interpangle + (ANG45 Div 2) * 9)) Shr 29;
    End;
    lump := sprframe^.lump[rot];
    flip := odd(sprframe^.flip[rot]);
  End
  Else Begin
    // use single rotation for all views
    lump := sprframe^.lump[0];
    flip := odd(sprframe^.flip[0]);
  End;

  // [crispy] randomly flip corpse, blood and death animation sprites
  If (crispy.flipcorpses <> 0) And
    ((thing^.flags And MF_FLIPPABLE) <> 0) And
    ((thing^.flags And MF_SHOOTABLE) = 0) And
    ((thing^.health And 1) = 1)
    Then Begin
    flip := Not flip;
  End;

  // calculate edges of the shape
  // [crispy] fix sprite offsets for mirrored sprites
  If flip Then Begin
    tx := tx - spritewidth[lump] - spriteoffset[lump];
  End
  Else Begin
    tx := tx - spriteoffset[lump];
  End;
  x1 := SarLongint(int(centerxfrac + FixedMul(tx, xscale)), FRACBITS);

  // off the right side?
  If (x1 > viewwidth) Then exit;

  tx := tx + spritewidth[lump];
  x2 := (SarLongint(int(centerxfrac + FixedMul(tx, xscale)), FRACBITS)) - 1;

  // off the left side
  If (x2 < 0) Then exit;

  // [JN] killough 4/9/98: clip things which are out of view due to height
  gzt := interpz + spritetopoffset[lump];
  If (interpz > viewz + FixedDiv(viewheight Shl FRACBITS, xscale)) Or
    (gzt < int64_t(viewz) - FixedDiv((viewheight Shl FRACBITS) - viewheight, xscale)) Then exit;

  // [JN] quickly reject sprites with bad x ranges
  If (x1 >= x2) Then exit;

  // store information in a vissprite
  vis := R_NewVisSprite();
  vis^.translation := Nil; // [crispy] no color translation
  vis^.mobjflags := thing^.flags;
  vis^.scale := xscale Shl detailshift;
  vis^.gx := interpx;
  vis^.gy := interpy;
  vis^.gz := interpz;
  vis^.gzt := gzt; // [JN] killough 3/27/98
  vis^.texturemid := gzt - viewz;
  If x1 < 0 Then
    vis^.x1 := 0
  Else
    vis^.x1 := x1;
  If x2 >= viewwidth Then
    vis^.x2 := viewwidth - 1
  Else
    vis^.x2 := x2;
  iscale := FixedDiv(FRACUNIT, xscale);

  If (flip) Then Begin
    vis^.startfrac := spritewidth[lump] - 1;
    vis^.xiscale := -iscale;
  End
  Else Begin
    vis^.startfrac := 0;
    vis^.xiscale := iscale;
  End;

  If (vis^.x1 > x1) Then
    vis^.startfrac := vis^.startfrac + vis^.xiscale * (vis^.x1 - x1);
  vis^.patch := lump;

  // get light level
  If (thing^.flags And MF_SHADOW) <> 0 Then Begin
    // shadow draw
    vis^.colormap[0] := Nil;
    vis^.colormap[1] := Nil;
  End
  Else If assigned(fixedcolormap) Then Begin
    // fixed map
    vis^.colormap[0] := fixedcolormap;
    vis^.colormap[1] := fixedcolormap;
  End
  Else If (thing^.frame And FF_FULLBRIGHT) <> 0 Then Begin
    // full bright
    vis^.colormap[0] := colormaps;
    vis^.colormap[1] := colormaps;
  End
  Else Begin
    // diminished light
    index := xscale Shr (LIGHTSCALESHIFT - detailshift + crispy.hires);

    If (index >= MAXLIGHTSCALE) Then index := MAXLIGHTSCALE - 1;

    // [crispy] brightmaps for select sprites
    vis^.colormap[0] := spritelights[index];
    vis^.colormap[1] := colormaps;
  End;
  vis^.brightmap := R_BrightmapForSprite(integer(thing^.sprite));

  // [crispy] colored blood
  If (crispy.coloredblood <> 0) And
    ((thing^._type = MT_BLOOD) Or ((thing^.state - @states[0]) = integer(S_GIBS))) And
    assigned(thing^.target) Then Begin
    // [crispy] Thorn Things in Hacx bleed green blood
    If (gamemission = pack_hacx) Then Begin

      If (thing^.target^._type = MT_BABY) Then Begin
        vis^.translation := cr[CR_RED2GREEN];
      End;
    End
    Else Begin
      // [crispy] Barons of Hell and Hell Knights bleed green blood
      If (thing^.target^._type = MT_BRUISER) Or (thing^.target^._type = MT_KNIGHT) Then Begin
        vis^.translation := cr[CR_RED2GREEN];
      End
        // [crispy] Cacodemons bleed blue blood
      Else If (thing^.target^._type = MT_HEAD) Then Begin

        vis^.translation := cr[CR_RED2BLUE];
      End;
    End;
  End;

  //#ifdef CRISPY_TRUECOLOR
  //    // [crispy] translucent sprites
  //    if (thing^.flags & MF_TRANSLUCENT)
  //    {
  //	vis^.blendfunc = (thing^.frame & FF_FULLBRIGHT) ? I_BlendAdd : I_BlendOverTranmap;
  //    }
  //#endif
End;

//
// R_AddSprites
// During BSP traversal, this adds sprites by sector.
//

Procedure R_AddSprites(sec: Psector_t);
Var
  thing: Pmobj_t;
  lightnum: int;
Begin

  // BSP is traversed by subsector.
  // A sector might have been split into several
  //  subsectors during BSP building.
  // Thus we check whether its already added.
  If (sec^.validcount = validcount) Then exit;


  // Well, now it will be done.
  sec^.validcount := validcount;

  lightnum := (sec^.rlightlevel Shr LIGHTSEGSHIFT) + (extralight * LIGHTBRIGHT); // [crispy] A11Y

  If (lightnum < 0) Then
    spritelights := scalelight[0]
  Else If (lightnum >= LIGHTLEVELS) Then
    spritelights := scalelight[LIGHTLEVELS - 1]
  Else
    spritelights := scalelight[lightnum];

  // Handle all things in sector.
  thing := sec^.thinglist;
  While assigned(thing) Do Begin
    R_ProjectSprite(thing);
    thing := thing^.snext;
  End;
End;

//
// R_DrawVisSprite
//  mfloorclip and mceilingclip should also be set.
//

Procedure R_DrawVisSprite(vis: Pvissprite_t; x1, x2: int);
//Const
//  error: boolean = false;
Var
  column: ^column_t;
  texturecolumn: int;
  frac: fixed_t;
  patch: Ppatch_t;
  Pint: ^integer;
Begin
  patch := W_CacheLumpNum(vis^.patch + firstspritelump, PU_CACHE);

  // [crispy] brightmaps for select sprites
  dc_colormap[0] := vis^.colormap[0];
  dc_colormap[1] := vis^.colormap[1];
  dc_brightmap := vis^.brightmap;

  If (dc_colormap[0] = Nil) Then Begin
    // NULL colormap = shadow draw
    colfunc := fuzzcolfunc;
  End
  Else If (vis^.mobjflags And MF_TRANSLATION) <> 0 Then Begin
    colfunc := transcolfunc;
    dc_translation := pointer(@translationtables[0]) - 256 +
      ((vis^.mobjflags And MF_TRANSLATION) Shr (MF_TRANSSHIFT - 8));
  End
    // [crispy] color-translated sprites (i.e. blood)
  Else If assigned(vis^.translation) Then Begin
    colfunc := transcolfunc;
    dc_translation := @vis^.translation[0];
  End
    // [crispy] translucent sprites
  Else If (crispy.translucency <> 0) And ((vis^.mobjflags And MF_TRANSLUCENT) <> 0) Then Begin
    If ((vis^.mobjflags And (MF_NOGRAVITY Or MF_COUNTITEM)) = 0) Or
      (((vis^.mobjflags And MF_NOGRAVITY) <> 0) And ((crispy.translucency And TRANSLUCENCY_MISSILE) <> 0)) Or
      (((vis^.mobjflags And MF_COUNTITEM) <> 0) And ((crispy.translucency And TRANSLUCENCY_ITEM) <> 0))
      Then Begin
      colfunc := tlcolfunc;
    End;
    //# ifdef CRISPY_TRUECOLOR
    //	blendfunc = vis^.blendfunc;
    //#endif
  End;

  dc_iscale := abs(vis^.xiscale) Shr detailshift;
  dc_texturemid := vis^.texturemid;
  frac := vis^.startfrac;
  spryscale := vis^.scale;
  sprtopscreen := centeryfrac - FixedMul(dc_texturemid, spryscale);

  For dc_x := vis^.x1 To vis^.x2 Do Begin

    texturecolumn := frac Shr FRACBITS;
    //#ifdef RANGECHECK
    //	if (texturecolumn < 0 || texturecolumn >= SHORT(patch^.width))
    //	{
    //	    // [crispy] make non-fatal
    //	    if (!error)
    //	    {
    //	    fprintf (stderr, "R_DrawSpriteRange: bad texturecolumn\n");
    //	    error = true;
    //	    }
    //	    continue;
    //	}
    //#endif
    Pint := @patch^.columnofs[0];
    column := pointer(patch) + Pint[texturecolumn];
    R_DrawMaskedColumn(column);
    frac := frac + vis^.xiscale;
  End;

  colfunc := basecolfunc;
  //#ifdef CRISPY_TRUECOLOR
  //    blendfunc = I_BlendOverTranmap;
  //#endif
End;

Var
  clipbot: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math
  cliptop: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math

Procedure R_DrawSprite(spr: Pvissprite_t);
Var
  ds: int;
  x: int;
  r1: int;
  r2: int;
  scale: fixed_t;
  lowscale: fixed_t;
  silhouette: int;
Begin
  For x := spr^.x1 To spr^.x2 Do Begin
    clipbot[x] := -2;
    cliptop[x] := -2;
  End;

  // Scan drawsegs from end to start for obscuring segs.
  // The first drawseg that has a greater scale
  //  is the clip seg.
  For ds := ds_p - 1 Downto 0 Do Begin

    // determine if the drawseg obscures the sprite
    If (drawsegs[ds].x1 > spr^.x2)
      Or (drawsegs[ds].x2 < spr^.x1)
      Or ((drawsegs[ds].silhouette = 0)
      And (drawsegs[ds].maskedtexturecol <> Nil))
      Then Begin
      // does not cover sprite
      continue;
    End;
    If drawsegs[ds].x1 < spr^.x1 Then Begin
      r1 := spr^.x1;
    End
    Else Begin
      r1 := drawsegs[ds].x1;
    End;
    If drawsegs[ds].x2 > spr^.x2 Then Begin
      r2 := spr^.x2;
    End
    Else Begin
      r2 := drawsegs[ds].x2;
    End;

    If (drawsegs[ds].scale1 > drawsegs[ds].scale2) Then Begin
      lowscale := drawsegs[ds].scale2;
      scale := drawsegs[ds].scale1;
    End
    Else Begin
      lowscale := drawsegs[ds].scale1;
      scale := drawsegs[ds].scale2;
    End;

    If (scale < spr^.scale)
      Or ((lowscale < spr^.scale) And (R_PointOnSegSide(spr^.gx, spr^.gy, drawsegs[ds].curline) = 0))
      Then Begin
      // masked mid texture?
      If assigned(drawsegs[ds].maskedtexturecol) Then
        R_RenderMaskedSegRange(ds, r1, r2);
      // seg is behind sprite
      continue;
    End;


    // clip this piece of the sprite
    silhouette := drawsegs[ds].silhouette;

    If (spr^.gz >= drawsegs[ds].bsilheight) Then
      silhouette := silhouette And Not SIL_BOTTOM;

    If (spr^.gzt <= drawsegs[ds].tsilheight) Then
      silhouette := silhouette And Not SIL_TOP;

    If (silhouette = 1) Then Begin
      // bottom sil
      For x := r1 To r2 Do Begin
        If (clipbot[x] = -2) Then
          clipbot[x] := drawsegs[ds].sprbottomclip[x];
      End;
    End
    Else If (silhouette = 2) Then Begin
      // top sil
      For x := r1 To r2 Do Begin
        If (cliptop[x] = -2) Then
          cliptop[x] := drawsegs[ds].sprtopclip[x];
      End;
    End
    Else If (silhouette = 3) Then Begin
      // both
      For x := r1 To r2 Do Begin
        If (clipbot[x] = -2) Then
          clipbot[x] := drawsegs[ds].sprbottomclip[x];
        If (cliptop[x] = -2) Then
          cliptop[x] := drawsegs[ds].sprtopclip[x];
      End;
    End;
  End;

  // all clipping has been performed, so draw the sprite

  // check for unclipped columns
  For x := spr^.x1 To spr^.x2 Do Begin
    If (clipbot[x] = -2) Then
      clipbot[x] := viewheight;

    If (cliptop[x] = -2) Then
      cliptop[x] := -1;
  End;
  mfloorclip := @clipbot[0];
  mceilingclip := @cliptop[0];
  R_DrawVisSprite(spr, spr^.x1, spr^.x2);
End;

(* Sortiert the VisSprites nach .scale *)

Procedure R_SortVisSprites;
  Procedure Quick(li, re: integer);
  Var
    l, r: Integer;
    p: fixed_t;
    h: vissprite_t;
  Begin
    If Li < Re Then Begin
      // Achtung, das Pivotelement darf nur einam vor den While schleifen ausgelesen werden, danach nicht mehr !!
      p := vissprites[Trunc((li + re) / 2)].scale; // Auslesen des Pivo Elementes
      l := Li;
      r := re;
      While l < r Do Begin
        While vissprites[l].scale < p Do
          inc(l);
        While vissprites[r].scale > p Do
          dec(r);
        If L <= R Then Begin
          h := vissprites[l];
          vissprites[l] := vissprites[r];
          vissprites[r] := h;
          inc(l);
          dec(r);
        End;
      End;
      quick(li, r);
      quick(l, re);
    End;
  End;
Begin
  quick(0, vissprite_p - 1);
End;

Function R_LaserspotColor(): TBytes;
Var
  health: int;
Begin
  result := Nil;
  If (crispy.crosshairtarget <> 0) Then Begin
    // [crispy] the projected crosshair code calls P_LineLaser() itself
    If (crispy.crosshair = CROSSHAIR_STATIC) Then Begin

      P_LineLaser(viewplayer^.mo, viewangle,
        16 * 64 * FRACUNIT, PLAYER_SLOPE(viewplayer));
    End;
    If assigned(linetarget) Then Begin
      result := cr[CR_GRAY];
      exit;
    End;
  End;

  // [crispy] keep in sync with st_stuff.c:ST_WidgetColor(hudcolor_health)
  If (crispy.crosshairhealth <> 0) Then Begin
    health := viewplayer^.health;
    // [crispy] Invulnerability powerup and God Mode cheat turn Health values gray
    If ((viewplayer^.cheats And integer(CF_GODMODE)) <> 0) Or
      (viewplayer^.powers[integer(pw_invulnerability)] <> 0) Then
      result := cr[CR_GRAY]
    Else If (health < 25) Then
      result := cr[CR_RED]
    Else If (health < 50) Then
      result := cr[CR_GOLD]
    Else If (health <= 100) Then
      result := cr[CR_GREEN]
    Else
      result := cr[CR_BLUE];
  End;
End;

// [crispy] generate a vissprite for the laser spot

Procedure R_DrawLSprite(); // TODO: hoffentlich ist der Bug, der das Ding nicht sauber zeichnen läst hier drin :/
Const
  lump: int = 0;
Const
  patch: ^patch_t = Nil;
Var
  xscale, tx, tz: fixed_t;
  vis: ^vissprite_t;
Begin
  If (weaponinfo[integer(viewplayer^.readyweapon)].ammo = am_noammo) Or
  (viewplayer^.playerstate <> PST_LIVE) Then exit;

  If (lump <> laserpatch[crispy.crosshairtype].l) Then Begin
    lump := laserpatch[crispy.crosshairtype].l;
    patch := W_CacheLumpNum(lump, PU_STATIC);
  End;

  P_LineLaser(viewplayer^.mo, viewangle, 16 * 64 * FRACUNIT, PLAYER_SLOPE(viewplayer));

  If (laserspot^.thinker._function.acv = Nil) Then exit;

  tz := FixedMul(laserspot^.x - viewx, viewcos) +
    FixedMul(laserspot^.y - viewy, viewsin);

  If (tz < MINZ) Then exit;

  xscale := FixedDiv(projection, tz);
  // [crispy] the original patch has 5x5 pixels, cap the projection at 20x20
  If (xscale > 4 * FRACUNIT) Then Begin
    xscale := 4 * FRACUNIT;
  End;

  tx := -(FixedMul(laserspot^.y - viewy, viewcos) -
    FixedMul(laserspot^.x - viewx, viewsin));

  If (abs(tx) > (tz Shl 2)) Then exit;

  vis := R_NewVisSprite();
  FillChar(vis^, sizeof(vis^), 0); // [crispy] set all fields to NULL, except ...

  vis^.patch := lump - firstspritelump; // [crispy] not a sprite patch
  If assigned(fixedcolormap) Then Begin
    vis^.colormap[0] := fixedcolormap;
    vis^.colormap[1] := fixedcolormap; // [crispy] always full brightness
  End
  Else Begin
    vis^.colormap[0] := colormaps;
    vis^.colormap[1] := colormaps; // [crispy] always full brightness
  End;
  vis^.brightmap := dc_brightmap;
  vis^.translation := R_LaserspotColor();
  //#ifdef CRISPY_TRUECOLOR
  //    vis^.mobjflags |= MF_TRANSLUCENT;
  //    vis^.blendfunc = I_BlendAdd;
  //#endif
  vis^.xiscale := FixedDiv(FRACUNIT, xscale);
  vis^.texturemid := laserspot^.z - viewz;
  vis^.scale := xscale Shl detailshift;
  //
  tx := tx - SHORT(patch^.width Div 2) Shl FRACBITS;
  vis^.x1 := SarLongint(centerxfrac + FixedMul(tx, xscale), FRACBITS);
  tx := tx + SHORT(patch^.width) Shl FRACBITS;
  vis^.x2 := SarLongint(centerxfrac + FixedMul(tx, xscale), FRACBITS) - 1;

  If (vis^.x1 < 0) Or (vis^.x1 >= viewwidth) Or
    (vis^.x2 < 0) Or (vis^.x2 >= viewwidth) Then exit;

  R_DrawVisSprite(vis, vis^.x1, vis^.x2);
End;


//
// R_DrawPSprite
//

Procedure R_DrawPSprite(Const psp: pspdef_t; psprnum: psprnum_t); // [crispy] differentiate gun from flash sprites
Var
  tx: fixed_t;
  x1, x2: int;
  sprdef: ^spritedef_t;
  sprframe: ^spriteframe_t;
  lump: int;
  flip: boolean;
  vis: ^vissprite_t;
  avis: vissprite_t;
Begin
  // decide which patch to use
//#ifdef RANGECHECK
//    if ( (unsigned)psp->state->sprite >= (unsigned int) numsprites)
//	I_Error ("R_ProjectSprite: invalid sprite number %i ",
//		 psp->state->sprite);
//#endif
  sprdef := @sprites[integer(psp.state^.sprite)];
  // [crispy] the TNT1 sprite is not supposed to be rendered anyway
  If (sprdef^.numframes = 0) And (psp.state^.sprite = SPR_TNT1) Then exit;

  //#ifdef RANGECHECK
  //    if ( (psp^.state^.frame & FF_FRAMEMASK)  >= sprdef^.numframes)
  //	I_Error ("R_ProjectSprite: invalid sprite frame %i : %i ",
  //		 psp^.state^.sprite, psp^.state^.frame);
  //#endif
  sprframe := @sprdef^.spriteframes[psp.state^.frame And FF_FRAMEMASK];

  lump := sprframe^.lump[0];
  flip := odd((sprframe^.flip[0] And $01) Xor ord(crispy.flipweapons));

  // calculate edges of the shape
  tx := psp.sx2 - (ORIGWIDTH Div 2) * FRACUNIT;

  //    // [crispy] fix sprite offsets for mirrored sprites
  If flip Then Begin
    tx := tx - 2 * tx - spriteoffset[lump] + spritewidth[lump];
  End
  Else Begin
    tx := tx - spriteoffset[lump];
  End;
  x1 := SarLongint(centerxfrac + FixedMul(tx, pspritescale), FRACBITS);

  // off the right side
  If (x1 > viewwidth) Then exit;

  tx := tx + spritewidth[lump];
  x2 := SarLongint((centerxfrac + FixedMul(tx, pspritescale)), FRACBITS) - 1;

  // off the left side
  If (x2 < 0) Then exit;

  // store information in a vissprite
  vis := @avis;
  vis^.translation := Nil; // [crispy] no color translation
  vis^.mobjflags := 0;
  // [crispy] weapons drawn 1 pixel too high when player is idle
  vis^.texturemid := (BASEYCENTER Shl FRACBITS) + FRACUNIT Div (2 Shl crispy.hires) - (psp.sy2 -spritetopoffset[lump]);
  If x1 < 0 Then Begin
    vis^.x1 := 0;
  End
  Else Begin
    vis^.x1 := x1;
  End;
  If x2 >= viewwidth Then Begin
    vis^.x2 := viewwidth - 1;
  End
  Else Begin
    vis^.x2 := x2;
  End;
  vis^.scale := pspritescale Shl detailshift;

  If (flip) Then Begin
    vis^.xiscale := -pspriteiscale;
    vis^.startfrac := spritewidth[lump] - 1;
  End
  Else Begin
    vis^.xiscale := pspriteiscale;
    vis^.startfrac := 0;
  End;

  If (vis^.x1 > x1) Then
    vis^.startfrac := vis^.startfrac + vis^.xiscale * (vis^.x1 - x1);

  vis^.patch := lump;

  If (viewplayer^.powers[integer(pw_invisibility)] > 4 * 32)
  Or ((viewplayer^.powers[integer(pw_invisibility)] And 8) <> 0) Then Begin
    // shadow draw
    vis^.colormap[0] := Nil;
    vis^.colormap[1] := Nil;
  End
  Else If assigned(fixedcolormap) Then Begin
    // fixed color
    vis^.colormap[0] := fixedcolormap;
    vis^.colormap[1] := fixedcolormap;
  End
  Else If (psp.state^.frame And FF_FULLBRIGHT) <> 0 Then Begin
    // full bright
    vis^.colormap[0] := colormaps;
    vis^.colormap[1] := colormaps;
  End
  Else Begin
    // local light
    vis^.colormap[0] := spritelights[MAXLIGHTSCALE - 1];
    vis^.colormap[1] := colormaps;
  End;
  vis^.brightmap := R_BrightmapForState(psp.state - @states[0]);

  // [crispy] translucent gun flash sprites
  If (psprnum = ps_flash) Then Begin
    vis^.mobjflags := vis^.mobjflags Or MF_TRANSLUCENT;
    //#ifdef CRISPY_TRUECOLOR
    //        vis^.blendfunc = I_BlendOverTranmap; // I_BlendAdd;
    //#endif
  End;

  // interpolate weapon bobbing
  If (crispy.uncapped <> 0) Then Begin
    Raise exception.create('not ported.');
    //        static int     oldx1, x1_saved;
    //        static fixed_t oldtexturemid, texturemid_saved;
    //        static int     oldlump = -1;
    //        static int     oldgametic = -1;
    //
    //        if (oldgametic < gametic)
    //        {
    //            oldx1 = x1_saved;
    //            oldtexturemid = texturemid_saved;
    //            oldgametic = gametic;
    //        }
    //
    //        x1_saved = vis^.x1;
    //        texturemid_saved = vis^.texturemid;
    //
    //        if (lump == oldlump && pspr_interp)
    //        {
    //            int deltax = vis^.x2 - vis^.x1;
    //            vis^.x1 = LerpFixed(oldx1, vis^.x1);
    //            vis^.x2 = vis^.x1 + deltax;
    //            vis^.x2 = vis^.x2 >= viewwidth ? viewwidth - 1 : vis^.x2;
    //            vis^.texturemid = LerpFixed(oldtexturemid, vis^.texturemid);
    //        }
    //        else
    //        {
    //            oldx1 = vis^.x1;
    //            oldtexturemid = vis^.texturemid;
    //            oldlump = lump;
    //            pspr_interp = true;
    //        }
  End;

  // [crispy] free look
  vis^.texturemid := vis^.texturemid + FixedMul(((centery - viewheight Div 2) Shl FRACBITS), pspriteiscale) Shr detailshift;

  R_DrawVisSprite(vis, vis^.x1, vis^.x2);
End;

//
// R_DrawPlayerSprites
//

Procedure R_DrawPlayerSprites();
Var
  i: int;
  lightnum: int;
Begin
  // get light level
  lightnum :=
    SarLongint(viewplayer^.mo^.subsector^.sector^.rlightlevel, LIGHTSEGSHIFT) // [crispy] A11Y
  + (extralight * LIGHTBRIGHT);

  If (lightnum < 0) Then
    spritelights := scalelight[0]
  Else If (lightnum >= LIGHTLEVELS) Then
    spritelights := scalelight[LIGHTLEVELS - 1]
  Else
    spritelights := scalelight[lightnum];

  // clip to screen bounds
  mfloorclip := screenheightarray;
  mceilingclip := negonearray;

  If (crispy.crosshair = CROSSHAIR_PROJECTED) Then Begin
    R_DrawLSprite();
  End;

  // add all active psprites
  For i := 0 To numrpsprites - 1 Do Begin // [crispy] A11Y number of player sprites to draw
    If assigned(viewplayer^.psprites[psprnum_t(i)].state) Then Begin
      R_DrawPSprite(viewplayer^.psprites[psprnum_t(i)], psprnum_t(i)); // [crispy] pass gun or flash sprite
    End;
  End;
End;

Procedure R_DrawMasked();
Var
  ds, spr: int;
  //  ds: ^drawseg_t;
Begin

  R_SortVisSprites();

  If (vissprite_p <> 0) Then Begin

    //	// draw all vissprites back to front
    //#ifdef HAVE_QSORT
    //	for (spr = vissprites;
    //	     spr < vissprite_p;
    //	     spr++)
    //#else
    For spr := 0 To vissprite_p - 1 Do Begin
      R_DrawSprite(@vissprites[spr]);
    End;
  End;

  // render any remaining masked mid textures
  For ds := ds_p - 1 Downto 0 Do Begin
    If assigned(drawsegs[ds].maskedtexturecol) Then Begin
      R_RenderMaskedSegRange(ds, drawsegs[ds].x1, drawsegs[ds].x2);
    End;
  End;

  If (crispy.cleanscreenshot = 2) Then exit;

  // draw the psprites on top of everything
  //  but does not draw on side views
  If (viewangleoffset = 0) Then Begin
    R_DrawPlayerSprites();
  End
End;

Initialization
  new(laserspot);
  FillChar(laserspot^, sizeof(laserspot^), 0);

Finalization
  dispose(laserspot);


End.

