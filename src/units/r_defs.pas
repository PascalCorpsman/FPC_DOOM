Unit r_defs;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomtype, tables
  , m_fixed
  , info_types
  ;

Type

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
  Pspriteframe_t = ^spriteframe_t;

  //
  // A sprite definition:
  //  a number of animation frames.
  //
  spritedef_t = Record
    numframes: int;
    spriteframes: Pspriteframe_t;
  End;

  // This could be wider for >8 bit display.
  // Indeed, true color support is posibble
  //  precalculating 24bpp lightmap/colormap LUT.
  //  from darkening PLAYPAL to all black.
  // Could even us emore than 32 levels.

//  lighttable_t = Array Of pixel_t;

Implementation

End.

