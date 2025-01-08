Unit v_video;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,

  v_patch,
  doomtype
  ;


Procedure V_Init();
Procedure V_DrawPatchDirect(x, y: int; Const patch: ppatch_t);
Procedure V_UseBuffer(Const buffer: Ppixel_t);

Var
  // The screen buffer; this is modified to draw things to the screen
  I_VideoBuffer: Ppixel_t = Nil;

Implementation

Uses
  Graphics, // TODO: Debug remove
  m_fixed, m_bbox
  , i_video
  ;

Var
  dest_screen: Ppixel_t = Nil;
  dirtybox: Array[0..3] Of int; // TODO: Das ist eigentlich falsch und sollte ein fixed_t sein ..

  dx, dxi, dy, dyi: fixed_t;

Procedure V_UseBuffer(Const buffer: Ppixel_t);
Begin
  dest_screen := buffer;
End;

Procedure V_Init;
Begin
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
Var
  w, col: int;
  desttop: ^pixel_t;
  b: tbitmap;
  column: Pcolumn_t;
  source: PByte;
  offset, row: integer;
  count: Byte;
  Pint: ^integer;
Begin

  Der Versuch mal überhaupt irgend eine Graphik aus der .wad Datei raus zu bekommen und als .bmp zu speichern

  b := TBitmap.Create;
  b.Width := patch^.width;
  b.Height := patch^.height;
  w := patch^.width;
  col := 0;
  Pint := @patch^.columnofs[0];
  While col < w Do Begin
    column := Pointer(patch) + pint^;
    inc(Pint);
    row := 0;
    While column^.topdelta <> $FF Do Begin
      source := pointer(column) + 3;
      row := row + column^.topdelta;
      count := column^.length;
      While count > 0 Do Begin
        b.canvas.Pixels[col, row] := source^;
        source := pointer(source) + 1;
        row := row + 1;
        dec(Count);
      End;
      column := pointer(column) + column^.length + 4;
    End;
    inc(col);
  End;
  b.SaveToFile('Erstes.bmp');
  b.free;

  //    int count;

  //    column_t *column;
  //    pixel_t *;
  //    pixel_t *dest;
  //    byte *source;

  //    // [crispy] four different rendering functions
  //    drawpatchpx_t *const drawpatchpx = drawpatchpx_a[!dp_translucent][!dp_translation];

  y := y - patch^.topoffset;
  x := x + patch^.leftoffset;
  //    x += WIDESCREENDELTA; // [crispy] horizontal widescreen offset

  (*
      // haleyjd 08/28/10: Strife needs silent error checking here.
      if(patchclip_callback)
      {
          if(!patchclip_callback(patch, x, y))
              return;
      }
  *)

  //  #ifdef RANGECHECK_NOTHANKS
  //    if (x < 0
  //     || x + SHORT(patch->width) > ORIGWIDTH
  //     || y < 0
  //     || y + SHORT(patch->height) > ORIGHEIGHT)
  //    {
  //        I_Error("Bad V_DrawPatch");
  //    }
  //#endif

  V_MarkRect(x, y, patch^.width, patch^.height);

  col := 0;
  If (x < 0) Then Begin
    col := col + dxi * ((-x * dx) Shr FRACBITS);
    x := 0;
  End;

  desttop := dest_screen + ((y * dy) Shr FRACBITS) * SCREENWIDTH + ((x * dx) Shr FRACBITS);

  w := patch^.width;

  // convert x to screen position
  x := (x * dx) Shr FRACBITS;

  //    for ( ; col<w << FRACBITS ; x++, col+=dxi, desttop++)
  While (col < w Shr FRACBITS) Do Begin
    //        int topdelta = -1;
    //
    //        // [crispy] too far right / width
    //        if (x >= SCREENWIDTH)
    //        {
    //            break;
    //        }
    //
    //        column = (column_t *)((byte *)patch + LONG(patch->columnofs[col >> FRACBITS]));
    //
    //        // step through the posts in a column
    //        while (column->topdelta != 0xff)
    //        {
    //            int top, srccol = 0;
    //            // [crispy] support for DeePsea tall patches
    //            if (column->topdelta <= topdelta)
    //            {
    //                topdelta += column->topdelta;
    //            }
    //            else
    //            {
    //                topdelta = column->topdelta;
    //            }
    //            top = ((y + topdelta) * dy) >> FRACBITS;
    //            source = (byte *)column + 3;
    //            dest = desttop + ((topdelta * dy) >> FRACBITS)*SCREENWIDTH;
    //            count = (column->length * dy) >> FRACBITS;
    //
    //            // [crispy] too low / height
    //            if (top + count > SCREENHEIGHT)
    //            {
    //                count = SCREENHEIGHT - top;
    //            }
    //
    //            // [crispy] nothing left to draw?
    //            if (count < 1)
    //            {
    //                break;
    //            }
    //
    //            while (count--)
    //            {
    //                // [crispy] too high
    //                if (top++ >= 0)
    //                {
    //                    *dest = drawpatchpx(*dest, source[srccol >> FRACBITS]);
    //                }
    //                srccol += dyi;
    //                dest += SCREENWIDTH;
    //            }
    //            column = (column_t *)((byte *)column + column->length + 4);
    //        }
    x := x + 1;
    col := col + dxi;
    desttop := desttop + 1;
  End;
End;

Procedure V_DrawPatchDirect(x, y: int; Const patch: ppatch_t);
Begin
  V_DrawPatch(x, y, patch);
End;

End.

