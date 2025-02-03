Unit v_video;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,

  v_patch,
  doomtype
  ;

(*
 * If Set, every call of V_DrawPatch will store the loaded patch also on the disk ;)
 *)
{.$DEFINE DebugBMPOut_in_V_DrawPatch}

Procedure V_Init();
Procedure V_DrawPatchDirect(x, y: int; Const patch: ppatch_t);
Procedure V_DrawPatchFullScreen(Const patch: ppatch_t; flipped: boolean);
Procedure V_UseBuffer(Const buffer: pixel_tArray);
Procedure V_DrawBlock(x, y, width, height: int; Const src: pixel_tArray);

Procedure V_RestoreBuffer();
Procedure V_MarkRect(x, y, width, height: int);

Var
  // The screen buffer; this is modified to draw things to the screen
  I_VideoBuffer: pixel_tArray; // Der ist quasi immer ORIGWIDTH * ORIGHEIGHT

  dp_translation: Array Of Byte; // Übersetzt die Aktuellen Farben in "neue" -> Siehe v_trans.pas, Default = nil = Deaktiviert

  Doom8BitTo24RGBBit: Array[0..255] Of uint32; // Das ist im Prinzip die Farbpalette, welche Doom zur Darstellung der RGB Farben nutzt..

  dp_translucent: boolean = false;

Implementation

Uses
{$IFDEF DebugBMPOut_in_V_DrawPatch}
  Graphics,
{$ENDIF}
  m_bbox
  , i_video
  ;

Var
  dest_screen: pixel_tArray = Nil;
  dirtybox: Array[0..3] Of int; // TODO: Das ist eigentlich falsch und sollte ein fixed_t sein ..
  dx, dxi, dy, dyi: fixed_t;

Procedure V_UseBuffer(Const buffer: pixel_tArray);
Begin
  dest_screen := buffer;
End;

Procedure V_RestoreBuffer;
Begin
  dest_screen := I_VideoBuffer;
End;

Procedure V_Init;
Begin
  dp_translation := Nil;
  dx := 1;
  dxi := 0;
  dy := 1;
  dyi := 0;
  //  // [crispy] initialize resolution-agnostic patch drawing
  //    if (NONWIDEWIDTH && SCREENHEIGHT)
  //    {
  //        dx = (NONWIDEWIDTH << FRACBITS) / ORIGWIDTH;
  //        dxi = (ORIGWIDTH << FRACBITS) / NONWIDEWIDTH;
  //        dy = (SCREENHEIGHT << FRACBITS) / ORIGHEIGHT;
  //        dyi = (ORIGHEIGHT << FRACBITS) / SCREENHEIGHT;
  //    }
  // no-op!
  // There used to be separate screens that could be drawn to; these are
  // now handled in the upper layers.
End;

//
// V_MarkRect
//

Procedure V_MarkRect(x, y, width, height: int);
Begin
  // If we are temporarily using an alternate screen, do not
  // affect the update box.

  If (dest_screen = I_VideoBuffer) Then Begin
    M_AddToBox(dirtybox, x, y);
    M_AddToBox(dirtybox, x + width - 1, y + height - 1);
  End;
End;

(*
 Rendert patch so "gestreckt", dass er füllend im Rechteck aus
 x .. x + Width, y .. y + Height
 liegt, genutzt wird die Nearest Neighbour Interpolation
 *)
Type
  TPatchBuffer = Record
    used: Boolean; // Nur wenn True, dann wurde der Pixel auch beschrieben -> soll gerendert werden
    Value: Byte; // Der Aktuelle Farbwert
  End;

Var
  PatchBuffer: Array Of TPatchBuffer = Nil;

// TODO: Das ist nicht gerade schnell, bei 1280x800 dauert so das Main Menu Rendern bereits mehr als 35ms :/
//       bei 640x400 gehts aber noch gut und da Fullscreenpatches nur in den Menü's oder Endscreens vorkommen ists ok.
Procedure V_DrawStretchedPatch(x, y, Width, Height: int; Const patch: ppatch_t);
Var
  col, i, j, srcX, srcY, srcIndex: int;
  column: Pcolumn_t;
  source: PByte;
  row, index: integer;
  count: Byte;
  sc: byte;
Begin
  // 1. Den Patch in einen Internen "nicht" gestretchten Puffer entpacken
  // 1.1 Initialisieren
  If (length(PatchBuffer) <> patch^.width * patch^.height) Then Begin
    setlength(PatchBuffer, patch^.width * patch^.height);
  End;
  FillChar(PatchBuffer[0], patch^.width * patch^.height * sizeof(TPatchBuffer), 0);
  // 1.2 Das eigentliche Rendern in den Puffer
  col := 0;
  While col < patch^.width Do Begin
    column := Pointer(patch) + patch^.columnofs[col];
    row := 0;
    While column^.topdelta <> $FF Do Begin
      source := pointer(column) + 3;
      row := column^.topdelta;
      count := column^.length;
      While count > 0 Do Begin
        sc := source^;
        If assigned(dp_translation) Then Begin
          sc := dp_translation[sc];
        End;
        index := (col) + (row) * patch^.width;
        PatchBuffer[index].Value := sc;
        PatchBuffer[index].used := true;
        source := pointer(source) + 1;
        row := row + 1;
        dec(Count);
      End;
      column := pointer(column) + column^.length + 4;
    End;
    inc(col);
  End;
  // 2. Den Puffer in den Screen rendern
  For i := x To x + Width - 1 Do Begin
    For j := y To y + Height - 1 Do Begin
      srcX := ((i - x) * patch^.width) Div Width; // Nearest Neighbour Interpolation
      srcY := ((j - y) * patch^.height) Div Height; // Nearest Neighbour Interpolation
      srcIndex := srcY * patch^.width + srcX;
      If PatchBuffer[srcIndex].used Then Begin
        index := i + j * SCREENWIDTH;
        dest_screen[index] := PatchBuffer[srcIndex].Value;
      End;
    End;
  End;
End;

Procedure V_DrawPatch(x, y: int; Const patch: ppatch_t);
{$IFDEF DebugBMPOut_in_V_DrawPatch}
Const
  PatchCounter: integer = 0;
Var
  b: tbitmap;
{$ENDIF}

Var
  w, col: int;
  column: Pcolumn_t;
  source: PByte;
  row, index: integer;
  count: Byte;
  sc: byte;
Begin
  y := y - patch^.topoffset;
  x := x + patch^.leftoffset;
{$IFDEF DebugBMPOut_in_V_DrawPatch}
  b := TBitmap.Create;
  b.Width := patch^.width;
  b.Height := patch^.height;
  // TODO: ggf noch mit clfuchsia löschen ?
{$ENDIF}
  w := patch^.width;
  col := 0;
  While col < w Do Begin
    column := Pointer(patch) + patch^.columnofs[col];
    row := 0;
    While column^.topdelta <> $FF Do Begin
      source := pointer(column) + 3;
      row := column^.topdelta;
      count := column^.length;
      While count > 0 Do Begin
        sc := source^;
        If assigned(dp_translation) Then Begin
          sc := dp_translation[sc];
        End;
{$IFDEF DebugBMPOut_in_V_DrawPatch}
        b.canvas.Pixels[col, row] := Doom8BitTo24RGBBit[sc] And $00FFFFFF;
{$ENDIF}
        index := (x + col) + (y + row) * SCREENWIDTH;
        // If (index >= 0) And (index <= high(dest_screen)) Then Begin
        dest_screen[index] := sc;
        // End;
        source := pointer(source) + 1;
        row := row + 1;
        dec(Count);
      End;
      column := pointer(column) + column^.length + 4;
    End;
    inc(col);
  End;
{$IFDEF DebugBMPOut_in_V_DrawPatch}
  b.SaveToFile(format('V_DrawPatch%0.8d.bmp', [PatchCounter]));
  PatchCounter := PatchCounter + 1;
  b.free;
{$ENDIF}
End;

Procedure V_DrawPatchDirect(x, y: int; Const patch: ppatch_t);
Begin
  V_DrawPatch(x, y, patch);
End;

Procedure V_DrawPatchFullScreen(Const patch: ppatch_t; flipped: boolean);
Begin
  patch^.leftoffset := 0;
  patch^.topoffset := 0;

  If (flipped) Then Begin
    raise exception.create('V_DrawPatchFullScreen für flipped implementieren.');
    // V_DrawPatchFlipped(0, 0, patch);
  End
  Else Begin
    If Crispy.hires <> 0 Then Begin
      V_DrawStretchedPatch(0, 0, SCREENWIDTH, SCREENHEIGHT, patch);
    End
    Else Begin
      // Ohne Scallierung ist Fullscreen einfach ;)
      V_DrawPatch(0, 0, patch);
    End;
  End;
End;

Procedure V_DrawBlock(x, y, width, height: int; Const src: pixel_tArray);
Begin
  //     pixel_t *dest;
  //
  //#ifdef RANGECHECK
  //    if (x < 0
  //     || x + width >SCREENWIDTH
  //     || y < 0
  //     || y + height > SCREENHEIGHT)
  //    {
  //	I_Error ("Bad V_DrawBlock");
  //    }
  //#endif

  V_MarkRect(x, y, width, height);

  //    dest = dest_screen + (y << crispy->hires) * SCREENWIDTH + x;
  //
  //    while (height--)
  //    {
  //	memcpy (dest, src, width * sizeof(*dest));
  //	src += width;
  //	dest += SCREENWIDTH;
  //    }
End;

End.

