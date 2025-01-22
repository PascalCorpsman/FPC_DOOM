Unit r_bmaps;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type
  R_BrightmapForTexNameT = Function(Const texname: String): TBytes;
  R_BrightmapForSpriteT = Function(Const _type: int): TBytes; // TODO: das int sollte spritenum_t sein !
  R_BrightmapForFlatNumT = Function(Const num: int): PByte;
  R_BrightmapForStateT = Function(Const state: int): String;

Var
  R_BrightmapForTexName: R_BrightmapForTexNameT = Nil;
  R_BrightmapForSprite: R_BrightmapForSpriteT = Nil;
  R_BrightmapForFlatNum: R_BrightmapForFlatNumT = Nil;
  R_BrightmapForState: R_BrightmapForStateT = Nil;


Var
  dc_brightmap: Array Of Byte;

Procedure R_InitBrightmaps();

Implementation

Uses
  doomstat, info_types
  , d_mode
  , r_data
  ;

Const
  DOOM1AND2 = 0;
  DOOM1ONLY = 1;
  DOOM2ONLY = 2;

Type
  fullbright_t = Record
    texture: String;
    game: int;
    colormask: Array Of byte;
  End;

Const
  nobrightmap: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  notgray: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    );


  notgrayorbrown: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    );

  notgrayorbrown2: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    );

  bluegreenbrownred: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  bluegreenbrown: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  blueandorange: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  redonly: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  redonly2: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  greenonly1: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  greenonly2: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  greenonly3: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  yellowonly: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0
    );

  blueandgreen: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

  brighttan: Array[0..255] Of byte =
  (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0,
    1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1,
    0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );

Var
  fullbright_doom: Array Of fullbright_t = Nil; // Wird im Initializer gesetzt
  fullbright_finaldoom: Array Of fullbright_t = Nil; // Wird im Initializer gesetzt

Var
  bmapflatnum: Array[0..11] Of int;

Function R_BrightmapForTexName_Doom(Const texname: String): TBytes;
Var
  i: int;
Begin
  For i := 0 To high(fullbright_doom) Do Begin
    If ((gamemission = doom) And (fullbright_doom[i].game = DOOM2ONLY)) Or (
      (gamemission <> doom) And (fullbright_doom[i].game = DOOM1ONLY)) Then continue;

    If fullbright_doom[i].texture = texname Then Begin
      result := fullbright_doom[i].colormask;
      exit;
    End;
  End;

  // Final Doom: Plutonia has no exclusive brightmaps
  If (gamemission = pack_tnt (* || gamemission == pack_plut *)) Then Begin
    For i := 0 To high(fullbright_finaldoom) Do Begin
      If fullbright_finaldoom[i].texture = texname Then Begin
        result := fullbright_finaldoom[i].colormask;
        exit;
      End;
    End;
  End;

  result := nobrightmap;
End;

// [crispy] brightmaps for sprites

// [crispy] adapted from russian-doom/src/doom/r_things.c:617-639

Function R_BrightmapForSprite_Doom(Const _type: int): TBytes;
Begin
  //	if (crispy->brightmaps & BRIGHTMAPS_SPRITES)
  //	{
  //		switch (type)
  //		{
  //			// Armor Bonus
  //			case SPR_BON2:
  //			{
  //				return greenonly1;
  //				break;
  //			}
  //			// Cell Charge
  //			case SPR_CELL:
  //			{
  //				return greenonly2;
  //				break;
  //			}
  //			// Barrel
  //			case SPR_BAR1:
  //			{
  //				return greenonly3;
  //				break;
  //			}
  //			// Cell Charge Pack
  //			case SPR_CELP:
  //			{
  //				return yellowonly;
  //				break;
  //			}
  //			// BFG9000
  //			case SPR_BFUG:
  //			// Plasmagun
  //			case SPR_PLAS:
  //			{
  //				return redonly;
  //				break;
  //			}
  //		}
  //	}
  //
  //	return nobrightmap;
End;

Function R_BrightmapForFlatNum_Doom(Const num: int): PByte;
Begin
  If (crispy.brightmaps And BRIGHTMAPS_TEXTURES) <> 0 Then Begin
    If (num = bmapflatnum[0]) Or
      (num = bmapflatnum[1]) Or
      (num = bmapflatnum[2]) Then Begin
      result := @notgrayorbrown[0];
      exit;
    End;
  End;
  result := @nobrightmap[0];
End;

Function R_BrightmapForState_Doom(Const state: int): String;
Begin
  //	if (crispy->brightmaps & BRIGHTMAPS_SPRITES)
  //	{
  //		switch (state)
  //		{
  //			case S_BFG1:
  //			case S_BFG2:
  //			case S_BFG3:
  //			case S_BFG4:
  //			{
  //				return redonly;
  //				break;
  //			}
  //		}
  //	}
  //
  //	return nobrightmap;
End;

Procedure R_InitBrightmaps();
Begin
  If (gameversion = exe_hacx) Then Begin

    //		bmapflatnum[0] = R_FlatNumForName("FLOOR1_1");
    //		bmapflatnum[1] = R_FlatNumForName("FLOOR1_7");
    //		bmapflatnum[2] = R_FlatNumForName("FLOOR3_3");
    //		bmapflatnum[3] = R_FlatNumForName("NUKAGE1");
    //		bmapflatnum[4] = R_FlatNumForName("NUKAGE2");
    //		bmapflatnum[5] = R_FlatNumForName("NUKAGE3");
    //		bmapflatnum[6] = R_FlatNumForName("BLOOD1");
    //		bmapflatnum[7] = R_FlatNumForName("BLOOD2");
    //		bmapflatnum[8] = R_FlatNumForName("BLOOD3");
    //		bmapflatnum[9] = R_FlatNumForName("SLIME13");
    //		bmapflatnum[10] = R_FlatNumForName("SLIME14");
    //		bmapflatnum[11] = R_FlatNumForName("SLIME15");
    //
    //		R_BrightmapForTexName = R_BrightmapForTexName_Hacx;
    //		R_BrightmapForSprite = R_BrightmapForSprite_Hacx;
    //		R_BrightmapForFlatNum = R_BrightmapForFlatNum_Hacx;
    //		R_BrightmapForState = R_BrightmapForState_Hacx;
  End
  Else If (gameversion = exe_chex) Then Begin

    //		int lump;
    //
    //		// [crispy] detect Chex Quest 2
    //		lump = W_CheckNumForName("INTERPIC");
    //		if (!strcasecmp(W_WadNameForLump(lumpinfo[lump]), "chex2.wad"))
    //		{
    //			chex2 = true;
    //		}
    //
    //		R_BrightmapForTexName = R_BrightmapForTexName_Chex;
    //		R_BrightmapForSprite = R_BrightmapForSprite_Chex;
    //		R_BrightmapForFlatNum = R_BrightmapForFlatNum_None;
    //		R_BrightmapForState = R_BrightmapForState_None;
  End
  Else Begin
    // [crispy] only three select brightmapped flats
    bmapflatnum[0] := R_FlatNumForName('CONS1_1');
    bmapflatnum[1] := R_FlatNumForName('CONS1_5');
    bmapflatnum[2] := R_FlatNumForName('CONS1_7');

    R_BrightmapForTexName := @R_BrightmapForTexName_Doom;
    R_BrightmapForSprite := @R_BrightmapForSprite_Doom;
    R_BrightmapForFlatNum := @R_BrightmapForFlatNum_Doom;
    R_BrightmapForState := @R_BrightmapForState_Doom;
  End;
End;

// [crispy] adapted from russian-doom/src/doom/r_things.c:617-639

Function R_BrightmapForSprite_Doom(Const _type: int): PByte;
Begin
  If (crispy.brightmaps And BRIGHTMAPS_SPRITES) <> 0 Then Begin

    Case (spritenum_t(_type)) Of

      // Armor Bonus
      SPR_BON2: Begin
          result := greenonly1;
          exit;
        End;

      // Cell Charge
      SPR_CELL: Begin
          result := greenonly2;
          exit;
        End;
      // Barrel
      SPR_BAR1: Begin
          result := greenonly3;
          exit;
        End;
      // Cell Charge Pack
      SPR_CELP: Begin
          result := yellowonly;
          exit;
        End;
      // BFG9000
      SPR_BFUG,
        // Plasmagun
      SPR_PLAS: Begin
          result := redonly;
          exit;
        End;
    End;
  End;

  result := nobrightmap;
End;


Procedure Setfullbright_doom(texture: String; game: int;
  Const colormask: TBytes);
Begin
  setlength(fullbright_doom, high(fullbright_doom) + 2);
  fullbright_doom[high(fullbright_doom)].texture := texture;
  fullbright_doom[high(fullbright_doom)].game := game;
  fullbright_doom[high(fullbright_doom)].colormask := colormask;
End;

Procedure Setfullbright_finaldoom(texture: String; game: int;
  Const colormask: TBytes);
Begin
  setlength(fullbright_finaldoom, high(fullbright_finaldoom) + 2);
  fullbright_finaldoom[high(fullbright_finaldoom)].texture := texture;
  fullbright_finaldoom[high(fullbright_finaldoom)].game := game;
  fullbright_finaldoom[high(fullbright_finaldoom)].colormask := colormask;
End;

Initialization
  dc_brightmap := nobrightmap;

  // [crispy] common textures
  Setfullbright_doom('COMP2', DOOM1AND2, blueandgreen);
  Setfullbright_doom('COMPSTA1', DOOM1AND2, notgray);
  Setfullbright_doom('COMPSTA2', DOOM1AND2, notgray);
  Setfullbright_doom('COMPUTE1', DOOM1AND2, bluegreenbrownred);
  Setfullbright_doom('COMPUTE2', DOOM1AND2, bluegreenbrown);
  Setfullbright_doom('COMPUTE3', DOOM1AND2, blueandorange);
  Setfullbright_doom('EXITSIGN', DOOM1AND2, notgray);
  Setfullbright_doom('EXITSTON', DOOM1AND2, redonly);
  Setfullbright_doom('PLANET1', DOOM1AND2, notgray);
  Setfullbright_doom('SILVER2', DOOM1AND2, notgray);
  Setfullbright_doom('SILVER3', DOOM1AND2, notgrayorbrown2);
  Setfullbright_doom('SLADSKUL', DOOM1AND2, redonly);
  Setfullbright_doom('SW1BRCOM', DOOM1AND2, redonly);
  Setfullbright_doom('SW1BRIK', DOOM1AND2, redonly);
  Setfullbright_doom('SW1BRN1', DOOM2ONLY, redonly);
  Setfullbright_doom('SW1COMM', DOOM1AND2, redonly);
  Setfullbright_doom('SW1DIRT', DOOM1AND2, redonly);
  Setfullbright_doom('SW1MET2', DOOM1AND2, redonly);
  Setfullbright_doom('SW1STARG', DOOM2ONLY, redonly);
  Setfullbright_doom('SW1STON1', DOOM1AND2, redonly);
  Setfullbright_doom('SW1STON2', DOOM2ONLY, redonly);
  Setfullbright_doom('SW1STONE', DOOM1AND2, redonly);
  Setfullbright_doom('SW1STRTN', DOOM1AND2, redonly);
  Setfullbright_doom('SW2BLUE', DOOM1AND2, redonly);
  Setfullbright_doom('SW2BRCOM', DOOM1AND2, greenonly2);
  Setfullbright_doom('SW2BRIK', DOOM1AND2, greenonly1);
  Setfullbright_doom('SW2BRN1', DOOM1AND2, greenonly2);
  Setfullbright_doom('SW2BRN2', DOOM1AND2, greenonly1);
  Setfullbright_doom('SW2BRNGN', DOOM1AND2, greenonly3);
  Setfullbright_doom('SW2COMM', DOOM1AND2, greenonly1);
  Setfullbright_doom('SW2COMP', DOOM1AND2, redonly);
  Setfullbright_doom('SW2DIRT', DOOM1AND2, greenonly2);
  Setfullbright_doom('SW2EXIT', DOOM1AND2, notgray);
  Setfullbright_doom('SW2GRAY', DOOM1AND2, notgray);
  Setfullbright_doom('SW2GRAY1', DOOM1AND2, notgray);
  Setfullbright_doom('SW2GSTON', DOOM1AND2, redonly);
  // [crispy] Special case: fewer colors lit.
  Setfullbright_doom('SW2HOT', DOOM1AND2, redonly2);
  Setfullbright_doom('SW2MARB', DOOM2ONLY, redonly);
  Setfullbright_doom('SW2MET2', DOOM1AND2, greenonly1);
  Setfullbright_doom('SW2METAL', DOOM1AND2, greenonly3);
  Setfullbright_doom('SW2MOD1', DOOM1AND2, greenonly1);
  Setfullbright_doom('SW2PANEL', DOOM1AND2, redonly);
  Setfullbright_doom('SW2ROCK', DOOM1AND2, redonly);
  Setfullbright_doom('SW2SLAD', DOOM1AND2, redonly);
  Setfullbright_doom('SW2STARG', DOOM2ONLY, greenonly2);
  Setfullbright_doom('SW2STON1', DOOM1AND2, greenonly3);
  // [crispy] beware!
  Setfullbright_doom('SW2STON2', DOOM1ONLY, redonly);
  Setfullbright_doom('SW2STON2', DOOM2ONLY, greenonly2);
  Setfullbright_doom('SW2STON6', DOOM1AND2, redonly);
  // [crispy] beware!
  Setfullbright_doom('SW2STONE', DOOM1ONLY, greenonly1);
  Setfullbright_doom('SW2STONE', DOOM2ONLY, greenonly2);
  Setfullbright_doom('SW2STRTN', DOOM1AND2, greenonly1);
  Setfullbright_doom('SW2TEK', DOOM1AND2, greenonly1);
  Setfullbright_doom('SW2VINE', DOOM1AND2, greenonly1);
  Setfullbright_doom('SW2WOOD', DOOM1AND2, redonly);
  Setfullbright_doom('SW2ZIM', DOOM1AND2, redonly);
  Setfullbright_doom('WOOD4', DOOM1AND2, redonly);
  Setfullbright_doom('WOODGARG', DOOM1AND2, redonly);
  Setfullbright_doom('WOODSKUL', DOOM1AND2, redonly);
  // Setfullbright_doom('ZELDOOR',  DOOM1AND2, redonly);
  Setfullbright_doom('LITEBLU1', DOOM1AND2, notgray);
  Setfullbright_doom('LITEBLU2', DOOM1AND2, notgray);
  Setfullbright_doom('SPCDOOR3', DOOM2ONLY, greenonly1);
  Setfullbright_doom('PIPEWAL1', DOOM2ONLY, greenonly1);
  Setfullbright_doom('TEKLITE2', DOOM2ONLY, greenonly1);
  Setfullbright_doom('TEKBRON2', DOOM2ONLY, yellowonly);
  // Setfullbright_doom('SW2SKULL', DOOM2ONLY, greenonly2);
  Setfullbright_doom('SW2SATYR', DOOM1AND2, brighttan);
  Setfullbright_doom('SW2LION', DOOM1AND2, brighttan);
  Setfullbright_doom('SW2GARG', DOOM1AND2, brighttan);

  // TNT - Evilution exclusive
  Setfullbright_finaldoom('PNK4EXIT', DOOM2ONLY, redonly);
  Setfullbright_finaldoom('SLAD2', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD3', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD4', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD5', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD6', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD7', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD8', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD9', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD10', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLAD11', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLADRIP1', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('SLADRIP3', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('M_TEC', DOOM2ONLY, greenonly2);
  Setfullbright_finaldoom('LITERED2', DOOM2ONLY, redonly);
  Setfullbright_finaldoom('BTNTMETL', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('BTNTSLVR', DOOM2ONLY, notgrayorbrown);
  Setfullbright_finaldoom('LITEYEL2', DOOM2ONLY, yellowonly);
  Setfullbright_finaldoom('LITEYEL3', DOOM2ONLY, yellowonly);
  Setfullbright_finaldoom('YELMETAL', DOOM2ONLY, yellowonly);
  // Plutonia exclusive
  // Setfullbright_finaldoom('SW2SKULL', DOOM2ONLY, redonly);

End.

