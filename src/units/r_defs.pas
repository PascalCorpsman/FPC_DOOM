Unit r_defs;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  doomtype;

//Type
  // This could be wider for >8 bit display.
  // Indeed, true color support is posibble
  //  precalculating 24bpp lightmap/colormap LUT.
  //  from darkening PLAYPAL to all black.
  // Could even us emore than 32 levels.

//  lighttable_t = Array Of pixel_t;

Implementation

End.



