Unit r_data;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, r_defs
  , m_fixed
  ;

Type

  // A single patch from a texture definition,
  //  basically a rectangular area within
  //  the texture rectangle.
  texpatch_t = Record
    // Block origin (allways UL),
    // which has allready accounted
    // for the internal origin of the patch.
    originx: short;
    originy: short;
    patch: int;
  End;

  // A maptexturedef_t describes a rectangular texture,
  //  which is composed of one or more mappatch_t structures
  //  that arrange graphic patches.

  Ptexture_t = ^texture_t;

  texture_t = Record
    // Keep name for switch changing, etc.
    name: String; // Always Uppercase !
    width: short;
    height: short;

    // Index in textures list
    index: int;

    // Next in hash table chain
    next: Ptexture_t;

    // All the patches[patchcount]
    // are drawn back to front into the cached texture.
    patchcount: short;
    patches: Array Of texpatch_t;
  End;

Procedure R_InitData();

Function R_TextureNumForName(name: String): int;
Function R_CheckTextureNumForName(name: String): int;

Function R_FlatNumForName(Const name: String): int;

Var
  textureheight: Array Of fixed_t; // [crispy] texture height for Tutti-Frutti fix
  firstspritelump: int;
  lastspritelump: int;
  numspritelumps: int;

  //  colormaps: lighttable_t;

Implementation

Uses
  i_system
  , r_bmaps, r_sky
  , w_wad
  , v_video, v_trans, v_patch
  , z_zone
  ;

Type
  //
  // Graphics.
  // DOOM graphics for walls and sprites
  // is stored in vertical runs of opaque pixels (posts).
  // A column is composed of zero or more posts,
  // a patch or sprite is composed of zero or more columns.
  //

  //
  // Texture definition.
  // Each texture is composed of one or more patches,
  // with patches being lumps stored in the WAD.
  // The lumps are referenced by number, and patched
  // into the rectangular texture space using origin
  // and possibly other attributes.
  //
  mappatch_t = Packed Record
    originx: short;
    originy: short;
    patch: short;
    stepdir: short;
    colormap: short;
  End;

  //
  // Texture definition.
  // A DOOM wall texture is a list of patches
  // which are to be combined in a predefined order.
  //
  maptexture_t = Packed Record
    name: Array[0..7] Of char;
    masked: int;
    width: short;
    height: short;
    obsolete: int;
    patchcount: short;
    patches: Array[0..0] Of mappatch_t; // Hat die Länge 1
  End;

Var

  firstflat: int;
  lastflat: int;
  numflats: int;

  //int		firstpatch;
  //int		lastpatch;
  //int		numpatches;

  numtextures: int = 0;
  textures: Array Of texture_t;
  textures_hashtable: Array Of Ptexture_t;

  texturewidthmask: Array Of int;
  texturewidth: Array Of int; // [crispy] texture width for wrapping column getter function
  // needed for texture pegging
  texturecompositesize: Array Of int;
  texturecolumnlump: Array Of Array Of short;
  texturecolumnofs: Array Of Array Of unsigned; // [crispy] column offsets for composited translucent mid-textures on 2S walls
  texturecolumnofs2: Array Of Array Of unsigned; // [crispy] column offsets for composited opaque textures
  texturecomposite: Array Of Array Of byte; // [crispy] composited translucent mid-textures on 2S walls
  texturecomposite2: Array Of Array Of byte; // [crispy] composited opaque textures
  texturebrightmap: Array Of TBytes; // [crispy] brightmaps

  // for global animation
  flattranslation: Array Of Int;
  texturetranslation: Array Of Int;

  // needed for pre rendering
  spritewidth: Array Of fixed_t;
  spriteoffset: Array Of fixed_t;
  spritetopoffset: Array Of fixed_t;

  //  lighttable_t	*colormaps;
  //  lighttable_t	*pal_color; // [crispy] array holding palette colors for true color mode


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

// [FG] check if the lump can be a Doom patch
// taken from PrBoom+ prboom2/src/r_patch.c:L350-L390

Function R_IsPatchLump(lump: int): boolean;
Const
  PNGFileSignature = chr(137) + 'PNG' + chr(13) + chr(10) + chr(26) + chr(10);

Var
  size, x: int;
  width, height: int;
  patch: ppatch_t;
  LumpHeader: Array[0..7] Of Char;
  Pint: ^integer;
  ofs: unsigned_int;
Begin
  result := false;
  If (lump < 0) Then exit;
  size := W_LumpLength(lump);
  // minimum length of a valid Doom patch
  If (size < 13) Then exit;
  patch := W_CacheLumpNum(lump, PU_CACHE);
  // [FG] detect patches in PNG format early
  Move(pointer(patch), LumpHeader, 8); // TODO: ungetestet, da keine .wad datei mit .png Dateien zur Verfügung stehen ..
  If LumpHeader = PNGFileSignature Then exit;

  width := patch^.width;
  height := patch^.height;

  result := (height > 0) And (height <= 16384) And (width > 0) And (width <= 16384) And (width < size Div 4);

  If (result) Then Begin
    // The dimensions seem like they might be valid for a patch, so
    // check the column directory for extra security. All columns
    // must begin after the column directory, and none of them must
    // point past the end of the patch.
    Pint := @patch^.columnofs[0];
    For x := 0 To width - 1 Do Begin
      ofs := pint^;
      // Need one byte for an empty column (but there's patches that don't know that!)
      If (ofs < width * 4 + 8) Or (ofs >= size) Then Begin
        result := false;
        break;
      End;
      inc(Pint);
    End;
  End;
End;

Procedure R_GenerateLookup(texnum: int);
Var
  texture: ^texture_t;
  patchcount: Array Of byte = Nil; // patchcount[texture->width]
  postcount: Array Of byte = Nil; // killough 4/9/98: keep count of posts in addition to patches.
  patch: ^texpatch_t;
  realpatch: ^patch_t;
  x, x1, x2, i: int;
  collump: ^short;
  colofs, colofs2: ^unsigned; // killough 4/9/98: make 32-bit
  csize: int = 0; // killough 10/98
  err: int = 0; // killough 10/98
  cofs: P_int;
  limit: unsigned;
  pat: int;
  col: ^column_t;
  base: ^Byte;
  index: Integer;
Begin

  texture := @textures[texnum];

  // Composited texture not created yet.
  texturecomposite[texnum] := Nil;
  texturecomposite2[texnum] := Nil;

  texturecompositesize[texnum] := 0;
  collump := @texturecolumnlump[texnum];
  colofs := @texturecolumnofs[texnum];
  colofs2 := @texturecolumnofs2[texnum];

  // Now count the number of columns
  //  that are covered by more than one patch.
  // Fill in the lump / offset, so columns
  //  with only a single patch are all done.
  setlength(patchcount, texture^.width);
  setlength(postcount, texture^.width);
  FillChar(patchcount[0], texture^.width, 0);
  FillChar(postcount[0], texture^.width, 0);

  For i := 0 To texture^.patchcount - 1 Do Begin
    patch := @texture^.patches[i];
    realpatch := W_CacheLumpNum(patch^.patch, PU_CACHE);
    x1 := patch^.originx;
    x2 := x1 + realpatch^.width;

    If (x1 < 0) Then
      x := 0
    Else
      x := x1;

    If (x2 > texture^.width) Then
      x2 := texture^.width;
    cofs := @realpatch^.columnofs[0];

    While x < x2 Do Begin

      patchcount[x] := patchcount[x] + 1;
      collump[x] := patch^.patch;
      //      colofs[x] := realpatch^.columnofs[x - x1] + 3;
      colofs[x] := cofs[x - x1] + 3; // Das Muss so, weil sonst der Array Range Checker durch dreht :/
      inc(x);
    End;
  End;

  // killough 4/9/98: keep a count of the number of posts in column,
  // to fix Medusa bug while allowing for transparent multipatches.
  //
  // killough 12/98:
  // Post counts are only necessary if column is multipatched,
  // so skip counting posts if column comes from a single patch.
  // This allows arbitrarily tall textures for 1s walls.
  //
  // If texture is >= 256 tall, assume it's 1s, and hence it has
  // only one post per column. This avoids crashes while allowing
  // for arbitrarily tall multipatched 1s textures.

  // [crispy] generate composites for all textures
//  if (texture->patchcount > 1 && texture->height < 256)
  Begin
    // killough 12/98: Warn about a common column construction bug
    limit := texture^.height * 3 + 3; // absolute column size limit

    //	for (i = texture->patchcount, patch = texture->patches; --i >= 0; )
    For i := 0 To texture^.patchcount - 1 Do Begin
      patch := @texture^.patches[i];
      pat := patch^.patch;
      realpatch := W_CacheLumpNum(pat, PU_CACHE);
      x1 := patch^.originx;
      x2 := x1 + realpatch^.width;

      cofs := @realpatch^.columnofs[0];

      If (x2 > texture^.width) Then x2 := texture^.width;
      If (x1 < 0) Then x1 := 0;
      index := 0;
      For x := x1 To x2 - 1 Do Begin
        // [crispy] generate composites for all columns
//		if (patchcount[x] > 1) // Only multipatched columns
        Begin
          col := pointer(realpatch) + cofs[index];
          inc(index);
          base := pointer(col);

          // count posts
          While col^.topdelta <> $FF Do Begin
            If pointer(col) - pointer(base) <= limit Then Begin
              postcount[x] := postcount[x] + 1;
              col := pointer(col) + col^.length + 4;
            End
            Else Begin
              break;
            End;
          End;
        End;
      End;
    End;
  End;

  // Now count the number of columns
  //  that are covered by more than one patch.
  // Fill in the lump / offset, so columns
  //  with only a single patch are all done.

  For x := 0 To texture^.width - 1 Do Begin
    If (patchcount[x] = 0) And (err = 0) Then Begin // killough 10/98: non-verbose output
      err := err + 1;
      // [crispy] fix absurd texture name in error message
      writeln(format('R_GenerateLookup: column without a patch (%s)',
        [texture^.name]));
      // [crispy] do not return yet
      (*
      exit;
      *)
    End;
    // I_Error ("R_GenerateLookup: column without a patch");

     // [crispy] treat patch-less columns the same as multi-patched
    If (patchcount[x] > 1) Or (patchcount[x] = 0) Then Begin
      // Use the cached block.
      // [crispy] moved up here, the rest in this loop
      // applies to single-patched textures as well
      collump[x] := -1;
    End;
    // killough 1/25/98, 4/9/98:
    //
    // Fix Medusa bug, by adding room for column header
    // and trailer bytes for each post in merged column.
    // For now, just allocate conservatively 4 bytes
    // per post per patch per column, since we don't
    // yet know how many posts the merged column will
    // require, and it's bounded above by this limit.

    colofs[x] := csize + 3; // three header bytes in a column
    // killough 12/98: add room for one extra post
    csize := csize + 4 * postcount[x] + 5; // 1 stop byte plus 4 bytes per post

    // [crispy] remove limit
    (*
    If (texturecompositesize[texnum] > $10000 - texture^.height) Then Begin
      I_Error(format('R_GenerateLookup: texture %d is >64k', [texnum]));
    End;
    *)
    csize := csize + texture^.height; // height bytes of texture data
    // [crispy] initialize opaque texture column offset
    colofs2[x] := x * texture^.height;
  End;

  texturecompositesize[texnum] := csize;

  //    Z_Free(patchcount);
  //    Z_Free(postcount);
End;

Procedure GenerateTextureHashTable();
Var
  key, i: Int;
  rover: Ptexture_t;
Begin
  setlength(textures_hashtable, numtextures);
  For i := 0 To high(textures_hashtable) Do
    textures_hashtable[i] := Nil;

  // Add all textures to hash table

  For i := 0 To numtextures - 1 Do Begin
    // Store index
    textures[i].index := i;

    // Vanilla Doom does a linear search of the texures array
    // and stops at the first entry it finds.  If there are two
    // entries with the same name, the first one in the array
    // wins. The new entry must therefore be added at the end
    // of the hash chain, so that earlier entries win.

    key := W_LumpNameHash(textures[i].name) Mod numtextures;
    If textures_hashtable[key] = Nil Then Begin
      textures_hashtable[key] := @textures[i];
    End
    Else Begin
      rover := textures_hashtable[key];
      While rover^.next <> Nil Do Begin
        rover := rover^.next;
      End;
      rover^.next := @textures[i];
    End;
  End;
End;

//
// R_InitFlats
//

Procedure R_InitFlats();
Var
  i: int;
Begin
  firstflat := W_GetNumForName('F_START') + 1;
  lastflat := W_GetNumForName('F_END') - 1;
  numflats := lastflat - firstflat + 1;

  // Create translation table for global animation.
  setlength(flattranslation, numflats + 1);

  For i := 0 To numflats - 1 Do Begin
    flattranslation[i] := i;
  End;
End;

//
// R_InitTextures
// Initializes the texture list
//  with the textures from the world map.
//
// [crispy] partly rewritten to merge PNAMES and TEXTURE1/2 lumps

Procedure R_InitTextures();
  Function Copy8Chars(Src: PChar): String;
  Begin
    result := '';
    While (Src^ <> #0) And (length(result) < 8) Do Begin
      result := result + src^;
      inc(src);
    End;
    result := UpperCase(Result);
  End;

Type
  texturelump_t = Record
    lumpnum: int;
    maptex: P_int;
    maxoff: integer;
    numtextures: Short;
    sumtextures: short;
    pnamesoffset: short;
  End;

  pnameslump_t = Record
    lumpnum: int;
    names: Pointer; // Ist ein Pointer auf <short><char*>0
    nummappatches: short;
    summappatches: short;
    name_p: PChar;
  End;

Var
  numtexturelumps: int = 0;
  mtexture: ^maptexture_t;
  mpatch: ^mappatch_t;

  i, j, k: int;

  maptex: P_int;

  texturename, name: String;

  patchlookup: Array Of int = Nil; // Liste der Lump Indizees

  nummappatches: int;
  offset: int;
  maxoff: int = 0;

  directory: P_int = Nil;

  //    int			temp1;
  //    int			temp2;
  //    int			temp3;

  pnameslumps: Array Of pnameslump_t = Nil;
  texturelumps: Array Of texturelump_t = Nil; // *;
  texturelump: ^texturelump_t;

  maxpnameslumps: int; // PNAMES
  maxtexturelumps: int; // TEXTURE1, TEXTURE2

  numpnameslumps: int = 0;
  p_: Pointer;
  lumpindex: int;
  p: short;
Begin

  maxtexturelumps := length(lumpinfo);
  maxpnameslumps := length(lumpinfo);

  setlength(pnameslumps, maxpnameslumps);
  setlength(texturelumps, maxtexturelumps);

  // [crispy] make sure the first available TEXTURE1/2 lumps
  // are always processed first
  texturelumps[0].lumpnum := W_GetNumForName('TEXTURE1');
  numtexturelumps := 1;
  i := W_CheckNumForName('TEXTURE2');
  If (i <> -1) Then Begin
    texturelumps[numtexturelumps].lumpnum := i;
    numtexturelumps := numtexturelumps + 1;
  End
  Else Begin
    texturelumps[numtexturelumps].lumpnum := -1; // Muss initialisiert werden, dass die If unten keinen Sonderfall braucht ;)
  End;

  // [crispy] fill the arrays with all available PNAMES lumps
  // and the remaining available TEXTURE1/2 lumps
  nummappatches := 0;
  For i := high(lumpinfo) Downto 0 Do Begin
    If pos('PNAMES', lumpinfo[i].name) = 1 Then Begin
      pnameslumps[numpnameslumps].lumpnum := i;
      p_ := W_CacheLumpNum(pnameslumps[numpnameslumps].lumpnum, PU_STATIC);
      pnameslumps[numpnameslumps].names := p_;
      pnameslumps[numpnameslumps].nummappatches := P_int(p_)^ And $FFFF;

      // [crispy] accumulated number of patches in the lookup tables
      // excluding the current one
      pnameslumps[numpnameslumps].summappatches := nummappatches;
      pnameslumps[numpnameslumps].name_p := p_ + 4;
      // [crispy] calculate total number of patches
      nummappatches := nummappatches + pnameslumps[numpnameslumps].nummappatches;
      numpnameslumps := numpnameslumps + 1;
    End
    Else Begin
      If pos('TEXTURE', lumpinfo[i].name) = 1 Then Begin
        // [crispy] support only TEXTURE1/2 lumps, not TEXTURE3 etc.
        If (lumpinfo[i].name[8] <> '1') And (lumpinfo[i].name[8] <> '2') Then continue;

        // [crispy] make sure the first available TEXTURE1/2 lumps
        // are not processed again
        If (i = texturelumps[0].lumpnum) Or (i = texturelumps[1].lumpnum) Then continue; // [crispy] may still be -1

        // [crispy] do not proceed any further, yet
        // we first need a complete pnameslumps[] array and need
        // to process texturelumps[0] (and also texturelumps[1]) as well
        texturelumps[numtexturelumps].lumpnum := i;
        numtexturelumps := numtexturelumps + 1;
      End;
    End;
  End;
  setlength(pnameslumps, numpnameslumps); // Wieder Einkürzen der TextureLump Tabelle auf die Tatsächlich genutzte Zahl
  setlength(texturelumps, numtexturelumps); // Wieder Einkürzen der TextureLump Tabelle auf die Tatsächlich genutzte Zahl

  // [crispy] fill up the patch lookup table
  setlength(patchlookup, nummappatches);
  k := 0;
  For i := 0 To numpnameslumps - 1 Do Begin
    For j := 0 To pnameslumps[i].nummappatches - 1 Do Begin
      name := Copy8Chars(pnameslumps[i].name_p + j * 8);
      lumpindex := W_CheckNumForName(name);
      If (Not R_IsPatchLump(lumpindex)) Then Begin
        lumpindex := -1;
      End;
      // [crispy] if the name is unambiguous, use the lump we found
      patchlookup[k] := lumpindex;
      k := k + 1;
    End;
  End;

  // [crispy] calculate total number of textures
  numtextures := 0;
  For i := 0 To numtexturelumps - 1 Do Begin
    texturelumps[i].maptex := W_CacheLumpNum(texturelumps[i].lumpnum, PU_STATIC);
    texturelumps[i].maxoff := W_LumpLength(texturelumps[i].lumpnum);
    texturelumps[i].numtextures := P_int(texturelumps[i].maptex)^;

    // [crispy] accumulated number of textures in the texture files
    // including the current one
    numtextures := numtextures + texturelumps[i].numtextures;
    texturelumps[i].sumtextures := numtextures;

    // [crispy] link textures to their own WAD's patch lookup table (if any)
    texturelumps[i].pnamesoffset := 0;
    For j := 0 To numpnameslumps - 1 Do Begin
      // [crispy] both are from the same WAD?
      If (lumpinfo[texturelumps[i].lumpnum].wad_file = lumpinfo[pnameslumps[j].lumpnum].wad_file) Then Begin
        texturelumps[i].pnamesoffset := pnameslumps[j].summappatches;
        break;
      End;
    End;
  End;

  // [crispy] release memory allocated for patch lookup tables
  setlength(pnameslumps, 0);

  // [crispy] pointer to (i.e. actually before) the first texture file
  texturelump := Nil; // [crispy] gets immediately increased below

  setlength(textures, numtextures);
  setlength(texturecolumnlump, numtextures);
  setlength(texturecolumnofs, numtextures);
  setlength(texturecolumnofs2, numtextures);
  setlength(texturecomposite, numtextures);
  setlength(texturecomposite2, numtextures);
  setlength(texturecompositesize, numtextures);
  setlength(texturewidthmask, numtextures);
  setlength(texturewidth, numtextures);
  setlength(textureheight, numtextures);
  setlength(texturebrightmap, numtextures);

  //	Really complex printing shit...
//    temp1 = W_GetNumForName (DEH_String("S_START"));  // P_???????
//    temp2 = W_GetNumForName (DEH_String("S_END")) - 1;
//    temp3 = ((temp2-temp1+63)/64) + ((numtextures+63)/64);
//
//    // If stdout is a real console, use the classic vanilla "filling
//    // up the box" effect, which uses backspace to "step back" inside
//    // the box.  If stdout is a file, don't draw the box.
//
//    if (I_ConsoleStdout())
//    {
//        printf("[");
//#ifndef CRISPY_TRUECOLOR
//        for (i = 0; i < temp3 + 9 + 1; i++) // [crispy] one more for R_InitTranMap()
//#else
//        for (i = 0; i < temp3 + 9; i++)
//#endif
//            printf(" ");
//        printf("]");
//#ifndef CRISPY_TRUECOLOR
//        for (i = 0; i < temp3 + 10 + 1; i++) // [crispy] one more for R_InitTranMap()
//#else
//        for (i = 0; i < temp3 + 10; i++)
//#endif
//            printf("\b");
//    }

//      for (i=0 ; i<numtextures ; i++, directory++)
  For i := 0 To numtextures - 1 Do Begin
    //	if (!(i&63))
    //	    printf (".");

     // [crispy] initialize for the first texture file lump,
     // skip through empty texture file lumps which do not contain any texture
    While (texturelump = Nil) Or (i = texturelump^.sumtextures) Do Begin

      // [crispy] start looking in next texture file
      If assigned(texturelump) Then Begin
        inc(texturelump);
      End
      Else Begin
        texturelump := @texturelumps[0];
      End;
      maptex := texturelump^.maptex;
      maxoff := texturelump^.maxoff;
      directory := maptex + 1;
    End;

    offset := directory^;

    If (offset > maxoff) Then Begin
      I_Error('R_InitTextures: bad texture directory');
    End;

    mtexture := pointer(maptex) + offset;
    setlength(textures[i].patches, mtexture^.patchcount);
    textures[i].width := mtexture^.width;
    textures[i].height := mtexture^.height;
    textures[i].patchcount := mtexture^.patchcount;
    textures[i].name := Copy8Chars(mtexture^.name);
    textures[i].next := Nil;
    mpatch := @mtexture^.patches[0];

    // [crispy] initialize brightmaps
    texturebrightmap[i] := R_BrightmapForTexName(textures[i].name);

    For j := 0 To textures[i].patchcount - 1 Do Begin
      textures[i].patches[j].originx := mpatch^.originx;
      textures[i].patches[j].originy := mpatch^.originy;

      // [crispy] apply offset for patches not in the
      // first available patch offset table
      p := mpatch^.patch + texturelump^.pnamesoffset;
      // [crispy] catch out-of-range patches
      If (p < nummappatches) Then Begin
        textures[i].patches[j].patch := patchlookup[p];
      End;
      If (textures[i].patches[j].patch = -1) Or (p >= nummappatches) Then Begin
        texturename := textures[i].name;
        // [crispy] make non-fatal
        writeln(stderr, format('R_InitTextures: Missing patch in texture %s', [texturename]));
        textures[i].patches[j].patch := W_CheckNumForName('WIPCNT'); // [crispy] dummy patch
      End;
      inc(mpatch);
    End;
    setlength(texturecolumnlump[i], textures[i].width);
    setlength(texturecolumnofs[i], textures[i].width);
    setlength(texturecolumnofs2[i], textures[i].width);

    j := 1;
    While (j * 2 <= textures[i].width) Do Begin
      j := j Shl 1;
    End;

    texturewidthmask[i] := j - 1;
    textureheight[i] := textures[i].height Shl FRACBITS;

    // [crispy] texture width for wrapping column getter function
    texturewidth[i] := textures[i].width;
    inc(directory);
  End;


  setlength(patchlookup, 0);

  // [crispy] release memory allocated for texture files
//    for (i = 0; i < numtexturelumps; i++)
//    {
//	W_ReleaseLumpNum(texturelumps[i].lumpnum);
//    }
  setlength(texturelumps, 0);

  // Precalculate whatever possible.
  For i := 0 To numtextures - 1 Do Begin
    //    R_GenerateLookup(i); -- WTF: Wenn diese Zeile Aktiv ist, dann Knallts beim beenden, so wies aussieht braucht man das ggf aber gar nicht ..
  End;

  // Create translation table for global animation.
  setlength(texturetranslation, numtextures + 1);
  For i := 0 To numtextures - 1 Do Begin
    texturetranslation[i] := i;
  End;

  GenerateTextureHashTable();
End;

//
// R_InitSpriteLumps
// Finds the width and hoffset of all sprites in the wad,
//  so the sprite does not need to be cached completely
//  just for having the header info ready during rendering.
//

Procedure R_InitSpriteLumps();
Var
  i: int;
  patch: ^patch_t;
Begin
  firstspritelump := W_GetNumForName('S_START') + 1;
  lastspritelump := W_GetNumForName('S_END') - 1;

  numspritelumps := lastspritelump - firstspritelump + 1;
  setlength(spritewidth, numspritelumps);
  setlength(spriteoffset, numspritelumps);
  setlength(spritetopoffset, numspritelumps);

  For i := 0 To numspritelumps - 1 Do Begin
    If ((i And 63) = 0) Then
      write('.');

    patch := W_CacheLumpNum(firstspritelump + i, PU_CACHE);
    spritewidth[i] := patch^.width Shl FRACBITS;
    spriteoffset[i] := patch^.leftoffset Shl FRACBITS;
    spritetopoffset[i] := patch^.topoffset Shl FRACBITS;
  End;
End;

Procedure R_InitData();
Begin
  // [crispy] Moved R_InitFlats() to the top, because it sets firstflat/lastflat
  // which are required by R_InitTextures() to prevent flat lumps from being
  // mistaken as patches and by R_InitBrightmaps() to set brightmaps for flats.
  // R_InitBrightmaps() comes next, because it sets R_BrightmapForTexName()
  // to initialize brightmaps depending on gameversion in R_InitTextures().
  R_InitFlats();
  R_InitBrightmaps();
  R_InitTextures();
  write('.');
  //  R_InitFlats (); [crispy] moved ...
  write('.');
  R_InitSpriteLumps();
  write('.');
  //    // [crispy] Initialize and generate gamma-correction levels.
  //    I_SetGammaTable ();
  R_InitColormaps();
  // [crispy] Initialize color translation and color string tables.
  R_InitHSVColors();
  //#ifndef CRISPY_TRUECOLOR
  //    R_InitTranMap(); // [crispy] prints a mark itself
  //#endif
End;

//
// R_CheckTextureNumForName
// Check whether texture is available.
// Filter out NoTexture indicator.
//

Function R_CheckTextureNumForName(name: String): int;
Var
  texture: Ptexture_t;
  key: unsigned_int;
Begin
  // "NoTexture" marker.
  If (name[1] = '-') Then Begin
    result := 0;
    exit;
  End;
  key := W_LumpNameHash(uppercase(name)) Mod numtextures;
  texture := textures_hashtable[key];
  While assigned(texture) Do Begin
    If texture^.name = name Then Begin
      result := texture^.index;
      exit;
    End
    Else Begin
      texture := texture^.next;
    End;
  End;
  result := -1;
End;

Function R_FlatNumForName(Const name: String): int;
Var
  i: int;
Begin
  i := W_CheckNumForNameFromTo(name, lastflat, firstflat);
  If (i = -1) Then Begin
    // [crispy] make non-fatal
    writeln(stderr, format('R_FlatNumForName: %s not found', [name]));
    // [crispy] since there is no "No Flat" marker,
    // render missing flats as SKY
    result := skyflatnum;
    exit;
  End;
  result := i - firstflat;
End;

//
// R_TextureNumForName
// Calls R_CheckTextureNumForName,
//  aborts with error message.
//

Function R_TextureNumForName(name: String): int;
Var
  i: int;
Begin
  i := R_CheckTextureNumForName(name);

  If (i = -1) Then Begin
    // [crispy] fix absurd texture name in error message
     // [crispy] make non-fatal
    WriteLn(StdErr, format('R_TextureNumForName: %s not found', [name]));
    result := 0; // WTF: warum ist das nicht -1 wie immer ?
  End;
  result := i;
End;

End.

