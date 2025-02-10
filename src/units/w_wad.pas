(*
 * Idee: Den Ganzen Speichermanager lassen wir mal schön aus, es wird einfach
 *       die .wad Datei in einem Byte Puffer gehalten und direkt darauf gearbeitet
 *       Alle Anfragen werden als Addressen in diesen Speicher oder NIL beantwortet
 *
 * TODO: Die Lumps sollten via Suchbaum "schneller" gefunden werden, aktuel 1:1 Suche
 *)
Unit w_wad;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type
  lumpindex_t = int;

  lumpinfo_t = Record

    name: String; // Der wird als Uppercase initialisiert !
    wad_file: String;
    //    int		position;
    size: int;
    //    void       *cache;

    // Used for hash table lookups
//    next: lumpindex_t;
  End;

  (*
   * Alle Functionen aus der .h Datei sind schon mal "Portiert" aber nicht alle
   * implementiert
   *)

Function W_AddFile(filename: String): Boolean;
Procedure W_ResetAndFreeALL; // Reset everything, like brand as new..
Procedure W_Reload();

Function W_CheckNumForName(name: String): lumpindex_t;
Function W_GetNumForName(name: String): lumpindex_t;
Function W_CheckNumForNameFromTo(Const name: String; afrom, ato: int): lumpindex_t;

Function W_LumpLength(lump: lumpindex_t): int;
Procedure W_ReadLump(lump: lumpindex_t; dest: Pointer);

Function W_CacheLumpNum(lumpnum: lumpindex_t; tag: int): Pointer;
Function W_CacheLumpName(name: String; tag: int): Pointer;

Procedure W_GenerateHashTable();

Function W_LumpNameHash(Const s: String): unsigned_int;

Procedure W_ReleaseLumpNum(lump: lumpindex_t);
Procedure W_ReleaseLumpName(Const name: String);

Function W_WadNameForLump(Const lump: lumpinfo_t): String;
Function W_IsIWADLump(Const lump: lumpinfo_t): Boolean;

//function W_GetWADFileNames():TStrings;

Var
  lumpinfo: Array Of lumpinfo_t; // Wird für jeden Lump mit angelegt

Implementation

Uses
  FileUtil
  , i_system
  ;

Type

  // Das Format wie es in der .wad Datei liegt, darf nicht geändert werden !
  TLump = Packed Record
    filepos: int;
    size: int;
    name: Array[0..7] Of char;
  End;

  // Das Interne Format arbeitet mit Pointern, so dass evtl. nachgeladene lumps identisch behandelt werden können ;)
  TLumpData = Record
    DataPos: PByte;
    Size: int;
    Name: String; // Der wird als lowercase initialisiert !
  End;

Var
  WadFilename: String = '';
  WadMem: Array Of Byte = Nil; // Das .Wad File als Array im Speicher ohne weiteren Schnickschnack
  Lumps: Array Of TLumpData = Nil; // Liste aller Lumps und ihrer Positionen in WadMem
  PatchLumps: Array Of Array Of Byte = Nil; // Puffer für nachträglich rein gepatchte Lumps

Type
  TWadHeader = Packed Record
    // Should be "IWAD" or "PWAD".
    identification: Array[0..3] Of char;
    numlumps: int;
    infotableofs: int;
  End;

  (*
   * Lädt einen lump aus dem Lumps Ordner und Patcht ihn in die Lump liste
   * so als wäre er schon immer da gewesen ;) Die DOOM Engine hat keine Chance
   * einen Unterschied zu erkennen.
   *)

Procedure PatchLump(LumpFile: String);
Var
  LumpName: String;
  LumpIndex: lumpindex_t;
  m: TMemoryStream;
Begin
  LumpName := ExtractFileName(LumpFile);
  LumpName := copy(LumpName, 1, pos('.', LumpName) - 1);
  LumpIndex := W_CheckNumForName(LumpName);
  If LumpIndex = -1 Then Begin
    writeln('Could not patch: ' + LumpFile + ', lump does not exist in wad file.');
    exit;
  End;
  // Anlegen eines Datenpuffers für den "ersatz" lump
  setlength(PatchLumps, high(PatchLumps) + 2);
  m := TMemoryStream.Create;
  m.LoadFromFile(LumpFile);
  setlength(PatchLumps[high(PatchLumps)], m.Size);
  m.Read(PatchLumps[high(PatchLumps)][0], m.Size);
  // Ersetzen des Originals mit der Gepatchten / geladenen Version ;)
  lumpinfo[LumpIndex].wad_file := LumpFile;
  lumpinfo[LumpIndex].size := m.size;
  Lumps[LumpIndex].DataPos := @PatchLumps[high(PatchLumps)][0];
  Lumps[LumpIndex].size := m.size;
  m.free;
End;

Function W_AddFile(filename: String): Boolean;
Var
  m: TMemoryStream;
  Header: TWadHeader;
  i: Integer;
  FileLumps: Array Of TLump;
  sl: TStringList;
Begin
  If WadFilename = filename Then Begin
    result := true;
    exit; // Wir versuchen 2 mal das Selbe File zu laden
  End;
  If assigned(WadMem) Then Begin
    Raise exception.Create('Error, es ist bereits ein .wad geladen');
  End;
  result := false;
  If (filename[1] = '~') Then Begin
    Raise exception.create('Nicht implementiert');
  End;
  WadFilename := filename;
  // 1. Laden des .wad files in den Speicher
  m := TMemoryStream.Create;
  m.LoadFromFile(filename);
  setlength(WadMem, m.Size);
  m.Read(WadMem[0], m.Size);
  m.Position := 0;
  header.identification := '';
  m.Read(Header, SizeOf(TWadHeader));
  If (header.identification <> 'IWAD') Then Begin
    // Homebrew levels?
    If (header.identification <> 'PWAD') Then Begin
      m.free;
      I_Error(format('Wad file %s doesn''t have IWAD or PWAD id' + LineEnding, [filename]));
    End;
    // ???modifiedgame = true;
  End;

  // Vanilla Doom doesn't like WADs with more than 4046 lumps
  // https://www.doomworld.com/vb/post/1010985
  // [crispy] disable PWAD lump number limit
  If (header.identification = 'PWAD') And (header.numlumps > 4046) And false Then Begin
    m.free;
    I_Error(format('Error: Vanilla limit for lumps in a WAD is 4046, PWAD %s has %d', [filename, header.numlumps]));
  End;
  FileLumps := Nil;
  setlength(FileLumps, Header.numlumps);
  setlength(Lumps, Header.numlumps);
  m.Position := Header.infotableofs;
  m.Read(FileLumps[0], sizeof(TLump) * Header.numlumps);
  setlength(lumpinfo, length(Lumps));
  For i := 0 To high(Lumps) Do Begin
    lumpinfo[i].wad_file := filename;
    lumpinfo[i].name := UpperCase(FileLumps[i].name);
    lumpinfo[i].size := FileLumps[i].size;
    Lumps[i].name := LowerCase(FileLumps[i].name);
    Lumps[i].DataPos := @WadMem[FileLumps[i].filepos];
    Lumps[i].size := FileLumps[i].size;
  End;
  setlength(FileLumps, 0);
  m.free;
  (*
   * ggf nachladen / ersetzen der Lumps durch "externe" Hacks ;)
   *)
  For i := 0 To high(PatchLumps) Do
    setlength(PatchLumps[i], 0);
  setlength(PatchLumps, 0);
  sl := findallfiles('lumps', '*.lump', false);
  For i := 0 To sl.Count - 1 Do Begin
    PatchLump(sl[i]);
  End;
  sl.free;

  result := true;
End;

Procedure W_ResetAndFreeALL;
Var
  i: Integer;
Begin
  setlength(lumpinfo, 0);

  WadFilename := '';
  setlength(WadMem, 0);
  setlength(Lumps, 0);
  For i := 0 To high(PatchLumps) Do
    setlength(PatchLumps[i], 0);
  setlength(PatchLumps, 0);
End;

// The Doom reload hack. The idea here is that if you give a WAD file to -file
// prefixed with the ~ hack, that WAD file will be reloaded each time a new
// level is loaded. This lets you use a level editor in parallel and make
// incremental changes to the level you're working on without having to restart
// the game after every change.
// But: the reload feature is a fragile hack...

Procedure W_Reload;
Begin
  //    char *filename;
  //    lumpindex_t i;
  //
  //    if (reloadname == NULL)
  //    {
  //        return;
  //    }
  //
  //    // We must free any lumps being cached from the PWAD we're about to reload:
  //    for (i = reloadlump; i < numlumps; ++i)
  //    {
  //        if (lumpinfo[i]->cache != NULL)
  //        {
  //            Z_Free(lumpinfo[i]->cache);
  //        }
  //    }
  //
  //    // Reset numlumps to remove the reload WAD file:
  //    numlumps = reloadlump;
  //
  //    // Now reload the WAD file.
  //    filename = reloadname;
  //
  //    W_CloseFile(reloadhandle);
  //    free(reloadlumps);
  //
  //    reloadname = NULL;
  //    reloadlump = -1;
  //    reloadhandle = NULL;
  //    W_AddFile(filename);
  //    free(filename);

  // The WAD directory has changed, so we have to regenerate the
  // fast lookup hashtable:
  W_GenerateHashTable();
End;

//
// W_CheckNumForName
// Returns -1 if name not found.
//

Function W_CheckNumForName(name: String): lumpindex_t;
Var
  i: Integer;
Begin
  result := -1;
  // TODO: Das mittels eines Suchbaums oder was anderem Machen !
  name := LowerCase(name);
  For i := 0 To high(Lumps) Do Begin
    If Lumps[i].name = name Then Begin
      result := i;
      exit;
    End;
  End;
End;

//
// W_GetNumForName
// Calls W_CheckNumForName, but bombs out if not found.
//

Function W_GetNumForName(name: String): lumpindex_t;
Var
  i: lumpindex_t;
Begin
  result := -1;
  i := W_CheckNumForName(name);
  If (i < 0) Then Begin
    I_Error(format('W_GetNumForName: %s not found!', [name]));
  End;
  result := i;
End;

Function W_CheckNumForNameFromTo(Const name: String; afrom, ato: int
  ): lumpindex_t;
Var
  i: int;
Begin
  For i := afrom Downto ato Do Begin
    If lumpinfo[i].name = name Then Begin
      result := i;
      exit;
    End;
  End;
  result := -1;
End;

Function W_LumpLength(lump: lumpindex_t): int;
Begin
  result := -1; // Länge 0 wäre theoretisch gültig ..
  If (Lump >= 0) And (lump <= High(Lumps)) Then Begin
    result := Lumps[lump].size;
  End;
End;

Procedure W_ReadLump(lump: lumpindex_t; dest: Pointer);
Var
  i: integer;
  dest_p, source_p: PByte;
Begin
  dest_p := dest;
  source_p := Lumps[lump].DataPos;
  // TODO: Das könnte man auch mittels move machen ...
  For i := 0 To Lumps[lump].size - 1 Do Begin
    dest_p^ := source_p^;
    inc(dest_p);
    inc(source_p);
  End;
End;

//
// W_CacheLumpNum
//
// Load a lump into memory and return a pointer to a buffer containing
// the lump data.
//
// 'tag' is the type of zone memory buffer to allocate for the lump
// (usually PU_STATIC or PU_CACHE).  If the lump is loaded as
// PU_STATIC, it should be released back using W_ReleaseLumpNum
// when no longer needed (do not use Z_ChangeTag).
//

Function W_CacheLumpName(name: String; tag: int): Pointer;
Var
  index: lumpindex_t;
Begin
  result := Nil;
  index := W_CheckNumForName(name);
  If index >= 0 Then Begin
    result := Lumps[index].DataPos;
  End;
End;

Function W_CacheLumpNum(lumpnum: lumpindex_t; tag: int): Pointer;
Begin
  result := Nil;
  If (lumpnum >= 0) And (lumpnum <= High(Lumps)) Then Begin
    result := Lumps[lumpnum].DataPos;
  End
  Else Begin
    I_Error(format('W_CacheLumpNum: %i >= numlumps', [lumpnum]));
  End;
End;

// Generate a hash table for fast lookups

Procedure W_GenerateHashTable;
Begin
  //   lumpindex_t i;
  //
  //    // Free the old hash table, if there is one:
  //    if (lumphash != NULL)
  //    {
  //        Z_Free(lumphash);
  //    }
  //
  //    // Generate hash table
  //    if (numlumps > 0)
  //    {
  //        lumphash = Z_Malloc(sizeof(lumpindex_t) * numlumps, PU_STATIC, NULL);
  //
  //        for (i = 0; i < numlumps; ++i)
  //        {
  //            lumphash[i] = -1;
  //        }
  //
  //        for (i = 0; i < numlumps; ++i)
  //        {
  //            unsigned int hash;
  //
  //            hash = W_LumpNameHash(lumpinfo[i]->name) % numlumps;
  //
  //            // Hook into the hash table
  //
  //            lumpinfo[i]->next = lumphash[hash];
  //            lumphash[hash] = i;
  //        }
  //    }
End;

// Hash function used for lump names.

Function W_LumpNameHash(Const s: String): unsigned_int;
Var
  i: unsigned_int;
Begin
  // This is the djb2 string hash function, modded to work on strings
  // that have a maximum length of 8.
  result := 5381;
  For i := 1 To length(s) Do Begin
    result := ((result Shl 5) Xor result) Xor ord(Uppercase(s[i])[1]);
  End;
End;

Procedure W_ReleaseLumpNum(lump: lumpindex_t);
Begin
  // Nichts zu tun
End;

Procedure W_ReleaseLumpName(Const name: String);
Begin
  // Nichts zu tun
End;

Function W_WadNameForLump(Const lump: lumpinfo_t): String;
Begin
  result := lump.name;
End;

Function W_IsIWADLump(Const lump: lumpinfo_t): Boolean;
Begin
  result := lump.wad_file = lumpinfo[0].wad_file;
End;

Var
  i: integer;
Finalization

  For i := 0 To high(PatchLumps) Do Begin
    setlength(PatchLumps[i], 0);
  End;
  setlength(PatchLumps, 0);

End.

