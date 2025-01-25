Unit r_defs;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomtype, tables
  , i_video
  , m_fixed
  , info_types
  ;

Const
  // Silhouette, needed for clipping Segs (mainly)
  // and sprites representing things.
  SIL_NONE = 0;
  SIL_BOTTOM = 1;
  SIL_TOP = 2;
  SIL_BOTH = 3;

  MAXDRAWSEGS = 256;

Type

  laserpatch_t = Record
    c: char;
    a: String;
    l, w, h: int;
  End;

  // This could be wider for >8 bit display.
  // Indeed, true color support is posibble
  //  precalculating 24bpp lightmap/colormap LUT.
  //  from darkening PLAYPAL to all black.
  // Could even us emore than 32 levels.
  lighttable_t = pixel_t;

  Plighttable_t = ^lighttable_t;

  (*

  !!!!!!!!!! ACHTUNG !!!!!!!!!!
  ettliche typen sind aus zirkulären abhängigkeitsgründen
  nach  info_types.pas gewandert !

   *)

  //
  // The SideDef.
  //

  side_t = Record

    // add this to the calculated texture column
    textureoffset: fixed_t;

    // add this to the calculated texture top
    rowoffset: fixed_t;

    // Texture indices.
    // We do not maintain names here.
    toptexture: short;
    bottomtexture: short;
    midtexture: short;

    // Sector the SideDef is facing.
    sector: ^sector_t;

    // [crispy] smooth texture scrolling
    basetextureoffset: fixed_t;
  End;

  //
  // The LineSeg.
  //

  seg_t = Record

    v1: Pvertex_t; // Ist tatsächlich nur 1er aber halt ein pointer darauf
    v2: Pvertex_t; // Ist tatsächlich nur 1er aber halt ein pointer darauf

    offset: fixed_t;

    angle: angle_t;

    sidedef: ^side_t;
    linedef: ^line_t;

    // Sector references.
    // Could be retrieved from linedef, too.
    // backsector is NULL for one sided lines
    frontsector: ^sector_t;
    backsector: ^sector_t;

    length: uint32_t; // [crispy] fix long wall wobble
    r_angle: angle_t; // [crispy] re-calculated angle used for rendering
    fakecontrast: int;
  End;
  pseg_t = ^seg_t;


  Pvissprite_t = ^vissprite_t;
  // A vissprite_t is a thing
  //  that will be drawn during a refresh.
  // I.e. a sprite object that is partly visible.
  vissprite_t = Record

    // Doubly linked list.
    prev: Pvissprite_t;
    next: Pvissprite_t;

    x1: int;
    x2: int;

    // for line side calculation
    gx: fixed_t;
    gy: fixed_t;

    // global bottom / top for silhouette clipping
    gz: fixed_t;
    gzt: fixed_t;

    // horizontal position of x1
    startfrac: fixed_t;

    scale: fixed_t;

    // negative if flipped
    xiscale: fixed_t;

    texturemid: fixed_t;
    patch: int;

    // for color translation and shadow draw,
    //  maxbright frames as well
    // [crispy] brightmaps for select sprites
    colormap: Array[0..1] Of Plighttable_t;
    brightmap: Array Of byte;

    mobjflags: int;
    // [crispy] color translation table for blood colored by monster class
    translation: Array Of byte;
    //#ifdef CRISPY_TRUECOLOR
    //    const pixel_t	(*blendfunc)(const pixel_t fg, const pixel_t bg);
    //#endif
  End;


  //
  // Sprites are patches with a special naming convention
  //  so they can be recognized by R_InitSprites.
  // The base name is NNNNFx or NNNNFxFx, with
  //  x indicating the rotation, x = 0, 1-7.
  // The sprite and frame specified by a thing_t
  //  is range checked at run time.
  // A sprite is a patch_t that is assumed to represent
  //  a three dimensional object and may have multiple
  //  rotations pre drawn.
  // Horizontal flipping is used to save space,
  //  thus NNNNF2F5 defines a mirrored patch.
  // Some sprites will only have one picture used
  // for all views: NNNNF0
  //
  spriteframe_t = Record

    // If false use 0 for any position.
    // Note: as eight entries are available,
    //  we might as well insert the same name eight times.
    rotate: int; // [crispy] we use a value of 2 for 16 sprite rotations

    // Lump to use for view angles 0-7.
    lump: Array[0..15] Of short; // [crispy] support 16 sprite rotations

    // Flip bit (1 = flip) to use for view angles 0-7.
    flip: Array[0..15] Of byte; // [crispy] support 16 sprite rotations

  End;
  //  Pspriteframe_t = ^spriteframe_t;

    //
    // A sprite definition:
    //  a number of animation frames.
    //
  spritedef_t = Record
    numframes: int;
    spriteframes: Array Of spriteframe_t;
  End;

  //
  // Now what is a visplane, anyway?
  //
  visplane_t = Record

    height: fixed_t;
    picnum: int;
    lightlevel: int;
    minx: int;
    maxx: int;

    // Here lies the rub for all
    //  dynamic resize/change of resolution.
    top: Array[-1..MAXWIDTH] Of unsigned_int; // leave pads for [minx-1]/[maxx+1]
    // See above.
    bottom: Array[-1..MAXWIDTH] Of unsigned_int; // leave pads for [minx-1]/[maxx+1]
  End;

  Pvisplane_t = ^visplane_t;

  //
  // ?
  //
  drawseg_t = Record

    curline: Pseg_t;
    x1: int;
    x2: int;

    scale1: fixed_t;
    scale2: fixed_t;
    scalestep: fixed_t;

    // 0=none, 1=bottom, 2=top, 3=both
    silhouette: int;

    // do not clip sprites above this
    bsilheight: fixed_t;

    // do not clip sprites below this
    tsilheight: fixed_t;

    // Pointers to lists for sprite clipping,
    //  all three adjusted so [x1] is first value.
    sprtopclip: P_int; // [crispy] 32-bit integer math
    sprbottomclip: P_int; // [crispy] 32-bit integer math
    maskedtexturecol: P_int; // [crispy] 32-bit integer math
  End;

Implementation

End.

