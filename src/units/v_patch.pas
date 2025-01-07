Unit v_patch;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

// Patches.
// A patch holds one or more columns.
// Patches are used for sprites and all masked pictures,
// and we compose textures from the TEXTURE1/2 lists
// of patches.

Type
  patch_t = Packed Record

    width: short; // bounding box size
    height: short;
    leftoffset: short; // pixels to the left of origin
    topoffset: short; // pixels below the origin
    columnofs: Array[0..7] Of int; // only [width] used
    // the [0] is &columnofs[width]
  End;

Implementation

End.

