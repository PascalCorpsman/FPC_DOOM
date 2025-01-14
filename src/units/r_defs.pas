Unit r_defs;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomtype
  , m_fixed
  ;

Type

  //
  // Move clipping aid for LineDefs.
  //
  slopetype_t =
    (
    ST_HORIZONTAL,
    ST_VERTICAL,
    ST_POSITIVE,
    ST_NEGATIVE
    );

  // Psector_t,  sector_t -> Moved nach p_mobj

  // Psubsector_t, subsector_t -> Moved nach p_mobj


//
// Your plain vanilla vertex.
// Note: transformed values not buffered locally,
//  like some DOOM-alikes ("wt", "WebView") did.
//
  vertex_t = Record
    x: fixed_t;
    y: fixed_t;

    // [crispy] remove slime trails
    // vertex coordinates *only* used in rendering that have been
    // moved towards the linedef associated with their seg by projecting them
    // using the law of cosines in p_setup.c:P_RemoveSlimeTrails();
    r_x: fixed_t;
    r_y: fixed_t;
    moved: boolean;
  End;
  Pvertex_t = ^vertex_t;

  // This could be wider for >8 bit display.
  // Indeed, true color support is posibble
  //  precalculating 24bpp lightmap/colormap LUT.
  //  from darkening PLAYPAL to all black.
  // Could even us emore than 32 levels.

//  lighttable_t = Array Of pixel_t;

Implementation

End.

