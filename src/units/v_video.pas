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
Procedure V_DrawPatch(x, y: int; Const patch: ppatch_t);
Procedure V_DrawPatchFullScreen(Const patch: ppatch_t; flipped: boolean);
Procedure V_DrawPatchFlipped(x, y: int; Const patch: Ppatch_t);
Procedure V_UseBuffer(Const buffer: pixel_tArray);
Procedure V_DrawBlock(x, y, width, height: int; Const src: pixel_tArray);

Procedure V_RestoreBuffer();
Procedure V_MarkRect(x, y, width, height: int);
Procedure V_CopyRect(srcx, srcy: int; Const source: pixel_tArray; width, height, destx, desty: int);
Procedure V_DrawHorizLine(x, y, w, c: int);
Procedure V_FillFlat(y_start, y_stop, x_start, x_stop: int; Const src: PByte; Const dest: pixel_tArray);
Procedure V_DrawFilledBox(x, y, w, h, c: int);

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

  (*
   * EGAL wie Crispy.hires ist, V_DrawPatch geht immer von ORIGWIDTH / ORIGHEIGHT aus !
   * d.h. dass ggf der Pixel passend Verschoben und "Dicker" gemacht werden muss
   *)

Procedure V_DrawPatchSetPixel(x, y: int; col: Byte);
Var
  d, i, j, index: integer;
Begin
  y := y Shl Crispy.hires;
  x := x Shl Crispy.hires;
  d := (1 Shl Crispy.hires) - 1;
  For j := 0 To d Do Begin
    index := (y + j) * SCREENWIDTH + x;
    For i := 0 To d Do Begin
      dest_screen[index + i] := col;
    End;
  End;
End;

//
// V_DrawPatchFlipped
// Masks a column based masked pic to the screen.
// Flips horizontally, e.g. to mirror face.
//

Procedure V_DrawPatchFlipped(x, y: int; Const patch: Ppatch_t);
{$IFDEF DebugBMPOut_in_V_DrawPatch}
Const
  PatchFlippedCounter: integer = 0;
Var
  b: tbitmap;
{$ENDIF}

Var
  w, col: int;
  column: Pcolumn_t;
  source: PByte;
  row: integer;
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
        b.canvas.Pixels[w - col - 1, row] := Doom8BitTo24RGBBit[sc] And $00FFFFFF;
{$ENDIF}
        V_DrawPatchSetPixel((x + w - col - 1), (y + row), sc);
        // If (index >= 0) And (index <= high(dest_screen)) Then Begin
        // dest_screen[index] := sc;
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
  b.SaveToFile(format('V_DrawPatchFlipped%0.8d.bmp', [PatchFlippedCounter]));
  PatchFlippedCounter := PatchFlippedCounter + 1;
  b.free;
{$ENDIF}
End;

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

Procedure V_CopyRect(srcx, srcy: int; Const source: pixel_tArray; width,
  height, destx, desty: int);
Var
  src: ^pixel_t;
  dest: ^pixel_t;
Begin
  srcx := srcx Shl crispy.hires;
  srcy := srcy Shl crispy.hires;
  width := width Shl crispy.hires;
  height := height Shl crispy.hires;
  destx := destx Shl crispy.hires;
  desty := desty Shl crispy.hires;

  //#ifdef RANGECHECK
  //    if (srcx < 0
  //     || srcx + width > SCREENWIDTH
  //     || srcy < 0
  //     || srcy + height > SCREENHEIGHT
  //     || destx < 0
  //     || destx /* + width */ > SCREENWIDTH
  //     || desty < 0
  //     || desty /* + height */ > SCREENHEIGHT)
  //    {
  //        I_Error ("Bad V_CopyRect");
  //    }
  //#endif

  // [crispy] prevent framebuffer overflow
  If (destx + width > SCREENWIDTH) Then
    width := SCREENWIDTH - destx;
  If (desty + height > SCREENHEIGHT) Then
    height := SCREENHEIGHT - desty;

  V_MarkRect(destx, desty, width, height);

  src := @source[SCREENWIDTH * srcy + srcx];
  dest := @dest_screen[SCREENWIDTH * desty + destx];
  While height > 0 Do Begin
    move(src^, dest^, width * sizeof(pixel_t));
    inc(src, SCREENWIDTH);
    inc(dest, SCREENWIDTH);
    height := height - 1;
  End;
End;

Procedure V_DrawHorizLine(x, y, w, c: int);
Var
  buf: ^pixel_t;
  x1: int;
Begin
  // [crispy] prevent framebuffer overflows
  If (x + w > SCREENWIDTH) Then w := SCREENWIDTH - x;

  buf := @I_VideoBuffer[SCREENWIDTH * y + x];

  For x1 := 0 To w - 1 Do Begin
    buf^ := c;
    inc(buf);
  End;
End;

Procedure V_FillFlat(y_start, y_stop, x_start, x_stop: int; Const src: PByte;
  Const dest: pixel_tArray);
Var
  x, y: int;
  d: ^pixel_t;
Begin
  d := @dest[0];
  For y := y_start To y_stop - 1 Do Begin
    For x := x_start To x_stop - 1 Do Begin
      //#ifndef CRISPY_TRUECOLOR
      d^ := src[((y And 63) * 64) + (x And 63)];
      inc(d);
      //#else
        //*dest++ = pal_color[src[((y & 63) * 64) + (x & 63)]];
      //#endif
    End;
  End;
End;

Procedure V_DrawFilledBox(x, y, w, h, c: int);
Begin
  Raise exception.create('Port me.');
  //pixel_t *buf, *buf1;
  //int x1, y1;
  //
  //buf = I_VideoBuffer + SCREENWIDTH * y + x;
  //
  //for (y1 = 0; y1 < h; ++y1)
  //{
  //    buf1 = buf;
  //
  //    for (x1 = 0; x1 < w; ++x1)
  //    {
  //        *buf1++ = c;
  //    }
  //
  //    buf += SCREENWIDTH;
  //}
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

  // Das ist nicht gerade schnell, bei 1280x800 dauert so das Main Menu Rendern bereits mehr als 35ms :/
  // bei 640x400 gehts aber noch gut und da Fullscreenpatches nur in den Menü's oder Endscreens vorkommen ists ok.

Procedure V_DrawStretchedPatch(x, y, Width, Height: int; Const patch: ppatch_t); Deprecated 'Das wird nicht mehr benötigt, weil V_DrawPatch direkt auf 320x200 skalliert ;)';
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
  row: integer;
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
        V_DrawPatchSetPixel((x + col), (y + row), sc);
        // If (index >= 0) And (index <= high(dest_screen)) Then Begin
        // dest_screen[index] := sc;
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
    V_DrawPatchFlipped(0, 0, patch);
  End
  Else Begin
    V_DrawPatch(0, 0, patch);
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

