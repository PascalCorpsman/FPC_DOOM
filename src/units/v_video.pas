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

Const
  ORIGWIDTH = 320;
  ORIGHEIGHT = 200;

Procedure V_Init();
Procedure V_DrawPatchDirect(x, y: int; Const patch: ppatch_t);
Procedure V_UseBuffer(Const buffer: pixel_tArray);

Procedure V_RestoreBuffer();

Var
  // The screen buffer; this is modified to draw things to the screen
  I_VideoBuffer: pixel_tArray; // Der ist quasi immer ORIGWIDTH * ORIGHEIGHT

  dp_translation: Array Of Byte; // Übersetzt die Aktuellen Farben in "neue" -> Siehe v_trans.pas, Default = nil = Deaktiviert

  Doom8BitTo24RGBBit: Array[0..255] Of uint32; // Das ist im Prinzip die Farbpalette, welche Doom zur Darstellung der RGB Farben nutzt..

Implementation

Uses
{$IFDEF DebugBMPOut_in_V_DrawPatch}
  Graphics,
{$ENDIF}
  m_fixed, m_bbox
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

Procedure V_RestoreBuffer();
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
  Pint: ^integer;
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
  Pint := @patch^.columnofs[0];
  While col < w Do Begin
    column := Pointer(patch) + pint^;
    inc(Pint);
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
        b.canvas.Pixels[col, row] := Doom8BitTo24RGBBit[sc];
{$ENDIF}
        dest_screen[(x + col) + (y + row) * SCREENWIDTH] := sc;
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

End.

