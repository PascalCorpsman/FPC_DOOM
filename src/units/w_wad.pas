Unit w_wad;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , w_file
  ;

Type
  wadinfo_t = Packed Record
    // Should be "IWAD" or "PWAD".
    identification: Array[0..3] Of char;
    numlumps: int;
    infotableofs: int;
  End;

  filelump_t = Packed Record
    filepos: int;
    size: int;
    name: Array[0..7] Of char;
  End;

  lumpindex_t = int;

  lumpinfo_s = Record
    name: Array[0..7] Of char;
    wad_file: wad_file_t;
    position: int;
    size: int;
    cache: Pointer;
    // Used for hash table lookups
    next: lumpindex_t;
  End;

  lumpinfo_t = lumpinfo_s;

Function W_AddFile(filename: String): wad_file_t; // Orig was das ein *wad_file_t

Function W_CheckNumForName(name: String): lumpindex_t;

Implementation

Uses
  i_system;

Var
  // Location of each lump on disk.
  lumpinfo: Array Of lumpinfo_t = Nil;
  numlumps: unsigned_int = 0;
  lumphash: Array Of lumpindex_t = Nil;

  reloadhandle: wad_file_t;
  reloadname: String = '';
  reloadlumps: Array Of lumpinfo_t;

  wad_filenames: Array Of String = Nil;

Procedure AddWADFileName(filename: String);
Begin
  setlength(wad_filenames, high(wad_filenames) + 2);
  wad_filenames[high(wad_filenames)] := filename;
End;

//
// W_AddFile
// All files are optional, but at least one file must be
//  found (PWAD, if all required lumps are present).
// Files with a .wad extension are wadlink files
//  with multiple lumps.
// Other files are single lumps with the base filename
//

Function W_AddFile(filename: String): wad_file_t;
Var
  wad_file: wad_file_t;
  header: wadinfo_t;
  startlump, numfilelumps, length, i: int;
  fileinfo: Array Of filelump_t;
  filelumps: Array Of lumpinfo_t;
  filerover: ^filelump_t;
Begin

  // If the filename begins with a ~, it indicates that we should use the
  // reload hack.
  If (filename[1] = '~') Then Begin
    Raise exception.create('Fehlende Portierung.');
    //        if (reloadname != NULL)
    //        {
    //            I_Error("Prefixing a WAD filename with '~' indicates that the "
    //                    "WAD should be reloaded\n"
    //                    "on each level restart, for use by level authors for "
    //                    "rapid development. You\n"
    //                    "can only reload one WAD file, and it must be the last "
    //                    "file in the -file list.");
    //        }
    //
    //        reloadname = strdup(filename);
    //        reloadlump = numlumps;
    //        ++filename;
  End;

  // Open the file and add to directory
  wad_file := W_OpenFile(filename);

  If (wad_file.path = '') Then Begin
    //	printf (" couldn't open %s\n", filename);
    exit;
  End;

  If ExtractFileExt(filename) <> '.wad' Then Begin
    // single lump file

    // fraggle: Swap the filepos and size here.  The WAD directory
    // parsing code expects a little-endian directory, so will swap
    // them back.  Effectively we're constructing a "fake WAD directory"
    // here, as it would appear on disk.

//	fileinfo = Z_Malloc(sizeof(filelump_t), PU_STATIC, 0);
//	fileinfo->filepos = LONG(0);
//	fileinfo->size = LONG(wad_file->length);
//
//        // Name the lump after the base of the filename (without the
//        // extension).
//
//	M_ExtractFileBase (filename, fileinfo->name);
    numfilelumps := 1;
  End
  Else Begin
    // WAD file
    W_Read(wad_file, 0, header, sizeof(header));

    If (header.identification <> 'IWAD') Then Begin
      // Homebrew levels?
      If (header.identification <> 'PWAD') Then Begin
        W_CloseFile(wad_file);
        I_Error(format('Wad file %s doesn''t have IWAD or PWAD id' + LineEnding, [filename]));
      End;

      // ???modifiedgame = true;
    End;

    // header.numlumps = LONG(header.numlumps); // WTF: was macht diese Zeile ?

    // Vanilla Doom doesn't like WADs with more than 4046 lumps
    // https://www.doomworld.com/vb/post/1010985
    // [crispy] disable PWAD lump number limit
    If (header.identification = 'PWAD') And (header.numlumps > 4046) And false Then Begin
      W_CloseFile(wad_file);
      I_Error(format('Error: Vanilla limit for lumps in a WAD is 4046, PWAD %s has %d', [filename, header.numlumps]));
    End;

    //	header.infotableofs = LONG(header.infotableofs); // WTF: was macht diese Zeile ?
    length := header.numlumps * sizeof(filelump_t);

    fileinfo := Nil;
    setlength(fileinfo, header.numlumps);

    W_Read(wad_file, header.infotableofs, fileinfo[0], length);
    numfilelumps := header.numlumps;
  End;

  // Increase size of numlumps array to accomodate the new file.
  filelumps := Nil;
  setlength(filelumps, numfilelumps);

  If (filelumps = Nil) Then Begin
    W_CloseFile(wad_file);
    I_Error('Failed to allocate array for lumps from new file.');
  End;


  startlump := numlumps;
  numlumps := numlumps + numfilelumps;
  setlength(lumpinfo, numlumps);
  filerover := @fileinfo[0];

  For i := startlump To numlumps - 1 Do Begin
    filelumps[i - startlump].wad_file := wad_file;
    filelumps[i - startlump].position := filerover^.filepos;
    filelumps[i - startlump].size := filerover^.size;
    filelumps[i - startlump].cache := Nil;
    filelumps[i - startlump].name := filerover^.name;
    lumpinfo[i] := filelumps[i - startlump];
    inc(filerover);
  End;

  setlength(fileinfo, 0);

  If (lumphash <> Nil) Then Begin
    setlength(lumphash, 0);
    lumphash := Nil;
  End;

  // If this is the reload file, we need to save some details about the
  // file so that we can close it later on when we do a reload.
  If (reloadname <> '') Then Begin
    reloadhandle := wad_file;
    reloadlumps := filelumps;
  End;

  AddWADFileName(filename);

  result := wad_file;
End;

//
// W_CheckNumForName
// Returns -1 if name not found.
//

Function W_CheckNumForName(name: String): lumpindex_t;
Var
  i: unsigned_int;
Begin

  // Do we have a hash table yet?

  If (lumphash <> Nil) Then Begin
    Raise exception.create('W_CheckNumForName, portieren.');
    //        int hash;
    //
    //        // We do! Excellent.
    //
    //        hash = W_LumpNameHash(name) % numlumps;
    //
    //        for (i = lumphash[hash]; i != -1; i = lumpinfo[i]->next)
    //        {
    //            if (!strncasecmp(lumpinfo[i]->name, name, 8))
    //            {
    //                return i;
    //            }
    //        }
  End
  Else Begin
    // We don't have a hash table generate yet. Linear search :-(

    // scan backwards so patch lump files take precedence

    For i := numlumps - 1 Downto 0 Do Begin
      If lowercase(lumpinfo[i].name) = lowercase(name) Then Begin
        result := i;
        exit;
      End;
    End;
  End;

  // TFB. Not found.

  result := -1;
End;

End.

