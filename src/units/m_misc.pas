Unit m_misc;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Function M_StringDuplicate(Const orig: String): String;
Function M_FileCaseExists(Const path: String): String;

Implementation

Uses lazFileUtils;

Function M_StringDuplicate(Const orig: String): String;
Begin
  result := Orig;
End;

Function M_FileCaseExists(Const path: String): String;
Var
  name, ext: String;
Begin
  result := '';
  If FileExists(path) Then exit(path);
  // 1: lowercase filename, e.g. doom2.wad
  If FileExists(LowerCase(path)) Then exit(LowerCase(path));
  // 2: uppercase filename, e.g. DOOM2.WAD
  If FileExists(UpperCase(path)) Then exit(UpperCase(path));
  // 3. uppercase basename with lowercase extension, e.g. DOOM2.wad
  name := ExtractFileNameWithoutExt(path);
  ext := ExtractFileExt(path);
  If FileExists(UpperCase(name) + LowerCase(ext)) Then exit(UpperCase(name) + LowerCase(ext));
  // 4. lowercase filename with uppercase first letter, e.g. Doom2.wad
  If length(name) > 0 Then Begin
    name := LowerCase(name);
    name[1] := UpperCase(name[1])[1];
    If FileExists(name + ext) Then exit(name + ext);
  End;
End;

End.

