Unit doomtype;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, config, Classes, SysUtils;

Type
  pixel_t = uint8_t;  // ggf ist das auch 32-Bit weil 1 Byte Pro Kanal ..
  Ppixel_t = ^pixel_t;
  dpixel_t = uint16_t;

Implementation

End.

