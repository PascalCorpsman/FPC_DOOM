Unit v_patch;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type

  // Patches.
  // A patch holds one or more columns.
  // Patches are used for sprites and all masked pictures,
  // and we compose textures from the TEXTURE1/2 lists
  // of patches.

  patch_t = Packed Record
    width: short; // bounding box size
    height: short;
    leftoffset: short; // pixels to the left of origin
    topoffset: short; // pixels below the origin
    columnofs: Array[0..65535] Of Int; // Eigentlich sind nur width Elemente Gültig, aber da sich das immer ändert schalten wir so die Boundary Check funktion aus ..
  End;
  Ppatch_t = ^patch_t;
  PPpatch_t = ^Ppatch_t; // Das ist eigentlich ein Array of Ppatch_t
  patch_tArray = Packed Array[0..$FFFF] Of patch_t;
  Ppatch_tArray = ^patch_tArray;
  patch_tPArray = Packed Array[0..$FFFF] Of Ppatch_t;
  Ppatch_tPArray = ^patch_tPArray;

  // posts are runs of non masked source pixels
  post_t = Packed Record
    topdelta: byte; // -1 is the last post in a column
    length: byte; // length data bytes follows
  End;
  Ppost_t = ^post_t;

  // column_t is a list of 0 or more post_t, (byte)-1 terminated
  column_t = post_t;
  Pcolumn_t = ^column_t;

Implementation

End.

