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

  //  typedef struct lumpinfo_s ;


  lumpinfo_s = Record

    //    char	name[8];
    wad_file: String;
    //    int		position;
    //    int		size;
    //    void       *cache;

    // Used for hash table lookups
//    next: lumpindex_t;
  End;

  lumpinfo_t = lumpinfo_s;

  (*
   * Alle Functionen aus der .h Datei sind schon mal "Portiert" aber nicht alle
   * implementiert
   *)

Function W_AddFile(filename: String): Boolean;
Procedure W_Reload();

Function W_CheckNumForName(name: String): lumpindex_t;
Function W_GetNumForName(name: String): lumpindex_t;
//Function W_CheckNumForNameFromTo(Const name: String; afrom, ato: int): lumpindex_t;

Function W_LumpLength(lump: lumpindex_t): int;
//Procedure W_ReadLump(lump: lumpindex_t Var dest: Pointer);

Function W_CacheLumpNum(lumpnum: lumpindex_t; tag: int): Pointer;
Function W_CacheLumpName(name: String; tag: int): Pointer;

//Procedure W_GenerateHashTable();

// Function W_LumpNameHash(Const s: String): unsigned_int;

Procedure W_ReleaseLumpNum(lump: lumpindex_t);
Procedure W_ReleaseLumpName(Const name: String);

//Function W_WadNameForLump(Const lump: lumpinfo_t): String;
Function W_IsIWADLump(Const lump: lumpinfo_t): Boolean;

//function W_GetWADFileNames():TStrings;

Var
  lumpinfo: Array Of lumpinfo_t; // Wird für jeden Lum mit angelegt

Implementation

Uses i_system;

Type
  TLump = Packed Record
    filepos: int;
    size: int;
    name: Array[0..7] Of char;
  End;

Var
  WadFilename: String = '';
  WadMem: Array Of Byte = Nil; // Das .Wad File als Array im Speicher ohne weiteren Schnickschnack
  Lumps: Array Of TLump = Nil; // Liste aller Lumps und ihrer Positionen in WadMem

Type
  TWadHeader = Packed Record
    // Should be "IWAD" or "PWAD".
    identification: Array[0..3] Of char;
    numlumps: int;
    infotableofs: int;
  End;

Function W_AddFile(filename: String): Boolean;
Var
  m: TMemoryStream;
  Header: TWadHeader;
  i: Integer;
Begin
  If WadFilename = filename Then exit; // Wir versuchen 2 mal das Selbe File zu laden
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
  setlength(Lumps, Header.numlumps);
  m.Position := Header.infotableofs;
  m.Read(lumps[0], sizeof(TLump) * Header.numlumps);
  // Alle auf Lowercase, dann muss das nicht jedes mal gemacht werden, wenn zugrgriffen wird
  setlength(lumpinfo, length(Lumps));
  For i := 0 To high(Lumps) Do Begin
    lumpinfo[i].wad_file := filename;
    Lumps[i].name := LowerCase(Lumps[i].name);
  End;
  m.free;
  result := true;
End;

Procedure W_Reload();
Begin
  // Nichts zu tun
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

Function W_LumpLength(lump: lumpindex_t): int;
Begin
  result := 0;
  If (Lump >= 0) And (lump <= High(Lumps)) Then Begin
    result := Lumps[lump].size;
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
    result := @WadMem[Lumps[index].filepos];
  End;
End;

Function W_CacheLumpNum(lumpnum: lumpindex_t; tag: int): Pointer;
Begin
  result := Nil;
  If (lumpnum >= 0) And (lumpnum <= High(Lumps)) Then Begin
    result := @Lumps[lumpnum];
  End
  Else Begin
    I_Error(format('W_CacheLumpNum: %i >= numlumps', [lumpnum]));
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

Function W_IsIWADLump(Const lump: lumpinfo_t): Boolean;
Begin
  result := lump.wad_file = lumpinfo[0].wad_file;
End;

End.

