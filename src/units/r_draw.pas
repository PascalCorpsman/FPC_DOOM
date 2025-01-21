Unit r_draw;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Var
  translationtables: Array Of byte;
  viewheight: int;
  viewwidth: int;
  scaledviewwidth: int;

Procedure R_InitTranslationTables();

Procedure R_InitBuffer(width, height: int);

Procedure R_DrawColumn();
Procedure R_DrawFuzzColumn();
Procedure R_DrawTranslatedColumn();
Procedure R_DrawTLColumn();
Procedure R_DrawSpanSolid();
Procedure R_DrawSpan();

Implementation

Uses
  m_fixed
  ;

//
// R_InitTranslationTables
// Creates the translation tables to map
//  the green color ramp to gray, brown, red.
// Assumes a given structure of the PLAYPAL.
// Could be read from a lump instead.
//

Procedure R_InitTranslationTables();
Var
  i: int;
Begin
  setlength(translationtables, 256 * 3);
  // translate just the 16 green colors
  For i := 0 To 255 Do Begin
    If (i >= $70) And (i <= $7F) Then Begin
      // map green ramp to gray, brown, red
      translationtables[i] := $60 + (i And $F);
      translationtables[i + 256] := $40 + (i And $F);
      translationtables[i + 512] := $20 + (i And $F);
    End
    Else Begin
      // Keep all other colors as is.
      translationtables[i] := i;
      translationtables[i + 256] := i;
      translationtables[i + 512] := i;
    End;
  End;
End;

//
// R_InitBuffer
// Creats lookup tables that avoid
//  multiplies and other hazzles
//  for getting the framebuffer address
//  of a pixel to draw.
//

Procedure R_InitBuffer(width, height: int);
Var
  i: int;
Begin
  // Handle resize,
  //  e.g. smaller view windows
  //  with border and/or status bar.
//    viewwindowx := (SCREENWIDTH-width) >> 1;
//
//    // Column offset. For windows.
//    for (i=0 ; i<width ; i++)
//	columnofs[i] = viewwindowx + i;
//
//    // Samw with base row offset.
//    if (width == SCREENWIDTH)
//	viewwindowy = 0;
//    else
//	viewwindowy = (SCREENHEIGHT-SBARHEIGHT-height) >> 1;
//
//    // Preclaculate all row offsets.
//    for (i=0 ; i<height ; i++)
//	ylookup[i] = I_VideoBuffer + (i+viewwindowy)*SCREENWIDTH;
End;

//
// A column is a vertical slice/span from a wall texture that,
//  given the DOOM style restrictions on the view orientation,
//  will always have constant z depth.
// Thus a special case loop for very fast rendering can
//  be used. It has also been used with Wolfenstein 3D.
//
// [crispy] replace R_DrawColumn() with Lee Killough's implementation
// found in MBF to fix Tutti-Frutti, taken from mbfsrc/R_DRAW.C:99-1979

Procedure R_DrawColumn();
Begin
  //    int			count;
  //    pixel_t*		dest;
  //    fixed_t		frac;
  //    fixed_t		fracstep;
  //    int			heightmask = dc_texheight - 1;
  //
  //    count = dc_yh - dc_yl;
  //
  //    // Zero length, column does not exceed a pixel.
  //    if (count < 0)
  //	return;
  //
  //#ifdef RANGECHECK
  //    if ((unsigned)dc_x >= SCREENWIDTH
  //	|| dc_yl < 0
  //	|| dc_yh >= SCREENHEIGHT)
  //	I_Error ("R_DrawColumn: %i to %i at %i", dc_yl, dc_yh, dc_x);
  //#endif
  //
  //    // Framebuffer destination address.
  //    // Use ylookup LUT to avoid multiply with ScreenWidth.
  //    // Use columnofs LUT for subwindows?
  //    dest = ylookup[dc_yl] + columnofs[flipviewwidth[dc_x]];
  //
  //    // Determine scaling,
  //    //  which is the only mapping to be done.
  //    fracstep = dc_iscale;
  //    frac = dc_texturemid + (dc_yl-centery)*fracstep;
  //
  //    // Inner loop that does the actual texture mapping,
  //    //  e.g. a DDA-lile scaling.
  //    // This is as fast as it gets.
  //
  //  // heightmask is the Tutti-Frutti fix -- killough
  //  if (dc_texheight & heightmask) // not a power of 2 -- killough
  //  {
  //    heightmask++;
  //    heightmask <<= FRACBITS;
  //
  //    if (frac < 0)
  //	while ((frac += heightmask) < 0);
  //    else
  //	while (frac >= heightmask)
  //	    frac -= heightmask;
  //
  //    do
  //    {
  //	// [crispy] brightmaps
  //	const byte source = dc_source[frac>>FRACBITS];
  //	*dest = dc_colormap[dc_brightmap[source]][source];
  //
  //	dest += SCREENWIDTH;
  //	if ((frac += fracstep) >= heightmask)
  //	    frac -= heightmask;
  //    } while (count--);
  //  }
  //  else // texture height is a power of 2 -- killough
  //  {
  //    do
  //    {
  //	// Re-map color indices from wall texture column
  //	//  using a lighting/special effects LUT.
  //	// [crispy] brightmaps
  //	const byte source = dc_source[(frac>>FRACBITS)&heightmask];
  //	*dest = dc_colormap[dc_brightmap[source]][source];
  //
  //	dest += SCREENWIDTH;
  //	frac += fracstep;
  //
  //    } while (count--);
  //  }
End;

//
// Framebuffer postprocessing.
// Creates a fuzzy image by copying pixels
//  from adjacent ones to left and right.
// Used with an all black colormap, this
//  could create the SHADOW effect,
//  i.e. spectres and invisible players.
//

Procedure R_DrawFuzzColumn();
Begin
  //   int			count;
  //    pixel_t*		dest;
  //    boolean		cutoff = false;
  //
  //    // Adjust borders. Low...
  //    if (!dc_yl)
  //	dc_yl = 1;
  //
  //    // .. and high.
  //    if (dc_yh == viewheight-1)
  //    {
  //	dc_yh = viewheight - 2;
  //	cutoff = true;
  //    }
  //
  //    count = dc_yh - dc_yl;
  //
  //    // Zero length.
  //    if (count < 0)
  //	return;
  //
  //#ifdef RANGECHECK
  //    if ((unsigned)dc_x >= SCREENWIDTH
  //	|| dc_yl < 0 || dc_yh >= SCREENHEIGHT)
  //    {
  //	I_Error ("R_DrawFuzzColumn: %i to %i at %i",
  //		 dc_yl, dc_yh, dc_x);
  //    }
  //#endif
  //
  //    dest = ylookup[dc_yl] + columnofs[flipviewwidth[dc_x]];
  //
  //    // Looks like an attempt at dithering,
  //    //  using the colormap #6 (of 0-31, a bit
  //    //  brighter than average).
  //    do
  //    {
  //	// Lookup framebuffer, and retrieve
  //	//  a pixel that is either one column
  //	//  left or right of the current one.
  //	// Add index from colormap to index.
  //#ifndef CRISPY_TRUECOLOR
  //	*dest = colormaps[6*256+dest[SCREENWIDTH*fuzzoffset[fuzzpos]]];
  //#else
  //	*dest = I_BlendDark(dest[SCREENWIDTH*fuzzoffset[fuzzpos]], 0xD3);
  //#endif
  //
  //	// Clamp table lookup index.
  //	if (++fuzzpos == FUZZTABLE)
  //	    fuzzpos = 0;
  //
  //	dest += SCREENWIDTH;
  //    } while (count--);
  //
  //    // [crispy] if the line at the bottom had to be cut off,
  //    // draw one extra line using only pixels of that line and the one above
  //    if (cutoff)
  //    {
  //#ifndef CRISPY_TRUECOLOR
  //	*dest = colormaps[6*256+dest[SCREENWIDTH*(fuzzoffset[fuzzpos]-FUZZOFF)/2]];
  //#else
  //	*dest = I_BlendDark(dest[SCREENWIDTH*(fuzzoffset[fuzzpos]-FUZZOFF)/2], 0xD3);
  //#endif
  //    }
End;

//
// R_DrawTranslatedColumn
// Used to draw player sprites
//  with the green colorramp mapped to others.
// Could be used with different translation
//  tables, e.g. the lighter colored version
//  of the BaronOfHell, the HellKnight, uses
//  identical sprites, kinda brightened up.
//

Procedure R_DrawTranslatedColumn();
Begin
  //   int			count;
  //    pixel_t*		dest;
  //    fixed_t		frac;
  //    fixed_t		fracstep;
  //
  //    count = dc_yh - dc_yl;
  //    if (count < 0)
  //	return;
  //
  //#ifdef RANGECHECK
  //    if ((unsigned)dc_x >= SCREENWIDTH
  //	|| dc_yl < 0
  //	|| dc_yh >= SCREENHEIGHT)
  //    {
  //	I_Error ( "R_DrawColumn: %i to %i at %i",
  //		  dc_yl, dc_yh, dc_x);
  //    }
  //
  //#endif
  //
  //
  //    dest = ylookup[dc_yl] + columnofs[flipviewwidth[dc_x]];
  //
  //    // Looks familiar.
  //    fracstep = dc_iscale;
  //    frac = dc_texturemid + (dc_yl-centery)*fracstep;
  //
  //    // Here we do an additional index re-mapping.
  //    do
  //    {
  //	// Translation tables are used
  //	//  to map certain colorramps to other ones,
  //	//  used with PLAY sprites.
  //	// Thus the "green" ramp of the player 0 sprite
  //	//  is mapped to gray, red, black/indigo.
  //	// [crispy] brightmaps
  //	const byte source = dc_source[frac>>FRACBITS];
  //	*dest = dc_colormap[dc_brightmap[source]][dc_translation[source]];
  //	dest += SCREENWIDTH;
  //
  //	frac += fracstep;
  //    } while (count--);
End;

Procedure R_DrawTLColumn();
Begin
  //   int			count;
  //    pixel_t*		dest;
  //    fixed_t		frac;
  //    fixed_t		fracstep;
  //
  //    count = dc_yh - dc_yl;
  //    if (count < 0)
  //	return;
  //
  //#ifdef RANGECHECK
  //    if ((unsigned)dc_x >= SCREENWIDTH
  //	|| dc_yl < 0
  //	|| dc_yh >= SCREENHEIGHT)
  //    {
  //	I_Error ( "R_DrawColumn: %i to %i at %i",
  //		  dc_yl, dc_yh, dc_x);
  //    }
  //#endif
  //
  //    dest = ylookup[dc_yl] + columnofs[flipviewwidth[dc_x]];
  //
  //    fracstep = dc_iscale;
  //    frac = dc_texturemid + (dc_yl-centery)*fracstep;
  //
  //    do
  //    {
  //        // [crispy] brightmaps
  //        const byte source = dc_source[frac>>FRACBITS];
  //#ifndef CRISPY_TRUECOLOR
  //        // actual translucency map lookup taken from boom202s/R_DRAW.C:255
  //        *dest = tranmap[(*dest<<8)+dc_colormap[dc_brightmap[source]][source]];
  //#else
  //        const pixel_t destrgb = dc_colormap[dc_brightmap[source]][source];
  //        *dest = blendfunc(*dest, destrgb);
  //#endif
  //	dest += SCREENWIDTH;
  //
  //	frac += fracstep;
  //    } while (count--);
End;

Procedure R_DrawSpanSolid();
Begin
  //   const byte source = *ds_source;
  //    pixel_t *dest;
  //    int count;
  //
  //#ifdef RANGECHECK
  //    if (ds_x2 < ds_x1
  //	|| ds_x1<0
  //	|| ds_x2>=SCREENWIDTH
  //	|| (unsigned)ds_y>SCREENHEIGHT)
  //    {
  //	I_Error( "R_DrawSpanSolid: %i to %i at %i",
  //		 ds_x1,ds_x2,ds_y);
  //    }
  //#endif
  //
  //    count = ds_x2 - ds_x1;
  //
  //    do
  //    {
  //	dest = ylookup[ds_y] + columnofs[flipviewwidth[ds_x1++]];
  //	*dest = ds_colormap[ds_brightmap[source]][source];
  //    } while (count--);
End;

//
// R_DrawSpan
// With DOOM style restrictions on view orientation,
//  the floors and ceilings consist of horizontal slices
//  or spans with constant z depth.
// However, rotation around the world z axis is possible,
//  thus this mapping, while simpler and faster than
//  perspective correct texture mapping, has to traverse
//  the texture at an angle in all but a few cases.
// In consequence, flats are not stored by column (like walls),
//  and the inner loop has to step in texture space u and v.
//
Var
  ds_y: int;
  ds_x1: int;
  ds_x2: int;

  //lighttable_t*		ds_colormap[2];
  //const byte*			ds_brightmap;

  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;

  // start of a 64*64 tile image
  //byte*			ds_source;

  // just for profiling
  dscount: int;
  //
  // Draws the actual span.

Procedure R_DrawSpan();
Begin
  //  unsigned int position, step;
  //    pixel_t *dest;
  //    int count;
  //    int spot;
  //    unsigned int xtemp, ytemp;
  //
  //#ifdef RANGECHECK
  //    if (ds_x2 < ds_x1
  //	|| ds_x1<0
  //	|| ds_x2>=SCREENWIDTH
  //	|| (unsigned)ds_y>SCREENHEIGHT)
  //    {
  //	I_Error( "R_DrawSpan: %i to %i at %i",
  //		 ds_x1,ds_x2,ds_y);
  //    }
  ////	dscount++;
  //#endif
  //
  //    // Pack position and step variables into a single 32-bit integer,
  //    // with x in the top 16 bits and y in the bottom 16 bits.  For
  //    // each 16-bit part, the top 6 bits are the integer part and the
  //    // bottom 10 bits are the fractional part of the pixel position.
  //
  ///*
  //    position = ((ds_xfrac << 10) & 0xffff0000)
  //             | ((ds_yfrac >> 6)  & 0x0000ffff);
  //    step = ((ds_xstep << 10) & 0xffff0000)
  //         | ((ds_ystep >> 6)  & 0x0000ffff);
  //*/
  //
  ////  dest = ylookup[ds_y] + columnofs[ds_x1];
  //
  //    // We do not check for zero spans here?
  //    count = ds_x2 - ds_x1;
  //
  //    do
  //    {
  //	byte source;
  //	// Calculate current texture index in u,v.
  //        // [crispy] fix flats getting more distorted the closer they are to the right
  //        ytemp = (ds_yfrac >> 10) & 0x0fc0;
  //        xtemp = (ds_xfrac >> 16) & 0x3f;
  //        spot = xtemp | ytemp;
  //
  //	// Lookup pixel from flat texture tile,
  //	//  re-index using light/colormap.
  //	source = ds_source[spot];
  //	dest = ylookup[ds_y] + columnofs[flipviewwidth[ds_x1++]];
  //	*dest = ds_colormap[ds_brightmap[source]][source];
  //
  ////      position += step;
  //        ds_xfrac += ds_xstep;
  //        ds_yfrac += ds_ystep;
  //
  //    } while (count--);
End;

End.

