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



  // Psector_t,  sector_t -> Moved nach info_types

  // Psubsector_t, subsector_t -> Moved nach info_types




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

  // This could be wider for >8 bit display.
  // Indeed, true color support is posibble
  //  precalculating 24bpp lightmap/colormap LUT.
  //  from darkening PLAYPAL to all black.
  // Could even us emore than 32 levels.

//  lighttable_t = Array Of pixel_t;

Implementation

End.

