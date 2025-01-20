Unit doomtype;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, config, Classes, SysUtils;

Type
  pixel_t = uint8_t; // Alles in Doom ist 8-Bit -> Für OpenGL brauchen wir es in 24 / 32 Bit ..
  pixel_tArray = Array Of pixel_t;
  //  dpixel_t = uint16_t; // -- Der wird nur fürs wipe gebraucht und dort als schweinerei ..

Implementation

End.

