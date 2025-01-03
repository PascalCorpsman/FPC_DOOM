Unit w_file;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type

  _wad_file_s = Record

    // Class of this file.
//     wad_file_class_t *file_class;

    // If this is NULL, the file cannot be mapped into memory.  If this
    // is non-NULL, it is a pointer to the mapped file.
    mapped: TMemoryStream;

    // Length of the file, in bytes.
    length: unsigned_int; // WTF: Warum ist das nur 32-Bit ?

    // File's location on disk.
    path: String; // [crispy] un-const
  End;


  wad_file_t = _wad_file_s;

  //  p_wad_file_t = ^wad_file_t;

Function W_OpenFile(path: String): wad_file_t;


// Read data from the specified file into the provided buffer.  The
// data is read from the specified offset from the start of the file.
// Returns the number of bytes read.

Function W_Read(Const wad: wad_file_t; offset: unsigned_int; Out buffer; buffer_len: size_t): size_t;

Procedure W_CloseFile(Var wad: wad_file_t);

Implementation

Function W_OpenFile(path: String): wad_file_t;
Begin
  If FileExists(path) Then Begin
    //!
    // @category obscure
    //
    // Use the OS's virtual memory subsystem to map WAD files
    // directly into memory.
    //

    //  If (!M_CheckParm("-mmap"))
    //  {
    //      return stdc_wad_file.OpenFile(path);
    //  }
    result.mapped := TMemoryStream.Create;
    Result.mapped.LoadFromFile(path);
    Result.length := Result.mapped.Size;
    // Try all classes in order until we find one that works

    result.path := path;
  End
  Else Begin
    result.mapped := Nil;
    result.length := 0;
    result.path := '';
  End;
End;

Function W_Read(Const wad: wad_file_t; offset: unsigned_int; Out buffer;
  buffer_len: size_t): size_t;
Begin
  result := 0;
  If assigned(wad.mapped) Then Begin
    wad.mapped.Position := offset;
    result := wad.mapped.Read(buffer, buffer_len);
  End;
End;

Procedure W_CloseFile(Var wad: wad_file_t);
Begin
  If assigned(wad.mapped) Then Begin
    wad.mapped.Free;
  End;
  wad.mapped := Nil;
  wad.length := 0;
  wad.path := '';
End;

End.

