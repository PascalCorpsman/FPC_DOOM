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
  , v_video, v_trans
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

Procedure R_InitHSVColors();
Var
  i, j: Integer;
  playpal: PByte;
  keepgray: Boolean;
Begin
  playpal := W_CacheLumpName('PLAYPAL', PU_STATIC);
  // [crispy] check for status bar graphics replacements
  i := W_CheckNumForName('sttnum0'); // [crispy] Status Bar '0'
  keepgray := (i >= 0) And W_IsIWADLump(lumpinfo[i]);

  If Not assigned(crstr) Then setlength(crstr, CRMAX);

  // [crispy] CRMAX - 2: don't override the original GREN and BLUE2 Boom tables

  For i := 0 To CRMAX - 3 Do Begin
    For j := 0 To 255 Do Begin

      cr[i][j] := V_Colorize(playpal, i, j, keepgray);
    End;
    crstr[i] := cr_esc + chr(ord('0') + i);
  End;
  // Der Original Crispy Code initialisiert das nicht, aber wir machen das ordentlich hier !
  crstr[CR_RED2BLUE] := cr_esc + chr(ord('0') + CR_RED2BLUE);
  crstr[CR_RED2GREEN] := cr_esc + chr(ord('0') + CR_RED2GREEN);

  W_ReleaseLumpName('PLAYPAL');

  i := W_CheckNumForName('CRGREEN');
  If (i >= 0) Then Begin
    playpal := W_CacheLumpNum(i, PU_STATIC);
    For j := 0 To 255 Do Begin
      cr[CR_RED2GREEN][j] := playpal[j];
    End;
  End;

  i := W_CheckNumForName('CRBLUE2');
  If (i = -1) Then i := W_CheckNumForName('CRBLUE');
  If (i >= 0) Then Begin
    playpal := W_CacheLumpNum(i, PU_STATIC);
    For j := 0 To 255 Do Begin
      cr[CR_RED2BLUE][j] := playpal[j];
    End;
  End;
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
  // [crispy] Initialize color translation and color string tables.
  R_InitHSVColors();
  //#ifndef CRISPY_TRUECOLOR
  //    R_InitTranMap(); // [crispy] prints a mark itself
  //#endif
End;

End.

