Unit r_data;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, r_defs;

Procedure R_InitData();

//Var
//  colormaps: lighttable_t;

Implementation

Uses
  r_main
  , w_wad
  , v_video
  , z_zone
  ;

Procedure R_InitColormaps();
Var
  playpal: Array Of Byte;
  i: Integer;
Begin
  (*
   * Auslesen der FarbPallete, die Dankenswerter weise direct im .wad file steht ;)
   *)
  playpal := W_CacheLumpName('PLAYPAL', PU_STATIC);
  For i := 0 To 255 Do Begin
    Doom8BitTo24RGBBit[i] :=
      (playpal[i * 3] Shl 0)
      Or (playpal[i * 3 + 1] Shl 8)
      Or (playpal[i * 3 + 2] Shl 16);
  End;
  // TODO: Theoretisch werden hier auch noch irgend welche Lightings erzeugt ..
End;

Procedure R_InitData();
Begin
  // [crispy] Moved R_InitFlats() to the top, because it sets firstflat/lastflat
  // which are required by R_InitTextures() to prevent flat lumps from being
  // mistaken as patches and by R_InitBrightmaps() to set brightmaps for flats.
  // R_InitBrightmaps() comes next, because it sets R_BrightmapForTexName()
  // to initialize brightmaps depending on gameversion in R_InitTextures().
//    R_InitFlats ();
//    R_InitBrightmaps ();
//    R_InitTextures ();
//    printf (".");
////  R_InitFlats (); [crispy] moved ...
//    printf (".");
//    R_InitSpriteLumps ();
//    printf (".");
//    // [crispy] Initialize and generate gamma-correction levels.
//    I_SetGammaTable ();
  R_InitColormaps();
  //    // [crispy] Initialize color translation and color string tables.
  //    R_InitHSVColors ();
  //#ifndef CRISPY_TRUECOLOR
  //    R_InitTranMap(); // [crispy] prints a mark itself
  //#endif
End;

End.

