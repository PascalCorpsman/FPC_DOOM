(******************************************************************************)
(*                                                                            *)
(* Author      : Uwe Schächterle (Corpsman)                                   *)
(*                                                                            *)
(* This file is part of WAD_Viewer                                            *)
(*                                                                            *)
(*  See the file license.md, located under:                                   *)
(*  https://github.com/PascalCorpsman/Software_Licenses/blob/main/license.md  *)
(*  for details about the license.                                            *)
(*                                                                            *)
(*               It is not allowed to change or remove this text from any     *)
(*               source file of the project.                                  *)
(*                                                                            *)
(******************************************************************************)
Unit uWAD_viewer;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Type
  TLumpType = (
    ltUnknown, // Muss immer der 1. sein
    ltPatch,
    ltSound,
    ltMusic,
    ltMap,
    ltExportAsRaw,
    ltFlat,
    ltCount // Muss immer der letzte sein !
    );

Var
  Doom8BitTo24RGBBit: Array[0..255] Of UInt32;

Function GuessLumpTypeByPointer(Const p: Pointer; LumpName: String): TLumpType;

Function LumpTypeToString(value: TLumpType): String;

Implementation

Uses v_patch, f_finale, w_wad;

Function GuessLumpTypeByPointer(Const p: Pointer; LumpName: String): TLumpType;
Const
  MusHeader =
    ord('M') Shl 0
    Or ord('U') Shl 8
    Or ord('S') Shl 16
    Or $1A Shl 24;

Var
  patch: ^patch_t;
  column: Pcolumn_t;
  pui16: ^UInt16;
  pmus: ^Integer;
  s, t: String;
  i: Integer;
  valid: Boolean;
  LumpSize: integer;
Begin
  result := ltUnknown;
  If Not assigned(p) Then exit;
  LumpSize := W_LumpLength(W_GetNumForName(LumpName));

  // Check auf patch_t
  patch := p;
  If (patch^.width <= 640) And (patch^.width > 0) And
    (patch^.height <= 400) And (patch^.height > 0) Then Begin
    // Wir tun tatsächlich so als würden wir das Bild malen, und validieren so die daten..
    valid := true;
    For i := 0 To patch^.width - 1 Do Begin
      column := Pointer(patch) + patch^.columnofs[i];
      If (patch^.columnofs[i] > 0) And (patch^.columnofs[i] < LumpSize) Then Begin
        While (column^.topdelta <> $FF) And valid Do Begin
          If column^.topdelta + column^.length > patch^.height Then Begin
            valid := false;
          End;
          column := pointer(column) + column^.length + 4;
          If pointer(column) > Pointer(patch) + LumpSize Then Begin
            valid := false;
          End;
        End;
      End
      Else Begin
        valid := false;
      End;
      If Not valid Then break;
    End;
    If valid Then Begin
      result := ltPatch;
      exit;
    End;
  End;

  // Check for sound
  pui16 := P;
  If pui16^ = $0003 Then Begin
    inc(pui16);
    If (pui16^ = 11025) Or (pui16^ = 22050) Then Begin
      result := ltSound;
      exit;
    End;
  End;
  // Check for Music
  pmus := p;
  If pmus^ = MusHeader Then Begin
    result := ltMusic;
    exit;
  End;

  // Check for Map
  // Commercial Maps
  LumpName := uppercase(LumpName);
  If pos('MAP', LumpName) = 1 Then Begin
    s := Copy(LumpName, 4, length(LumpName));
    If strtointdef(s, -1) In [0..99] Then Begin
      result := ltMap;
      exit;
    End;
  End;
  // Demo Maps Pattern E<num>M<num>
  If pos('E', LumpName) = 1 Then Begin
    s := copy(LumpName, 2, length(LumpName));
    If pos('M', s) <> 0 Then Begin
      t := copy(s, 1, pos('M', s) - 1);
      If StrToIntDef(t, -1) >= 0 Then Begin
        t := copy(s, pos('M', s) + 1, length(s));
        If StrToIntDef(t, -1) >= 0 Then Begin
          result := ltMap;
          exit;
        End;
      End;
    End;
  End;

  For i := 0 To high(textscreens) Do Begin
    If (uppercase(textscreens[i].Background) = UpperCase(LumpName)) And (Lumpsize = 64 * 64) Then Begin
      result := ltFlat;
      exit;
    End;
  End;


  // Als aller letztes noch den ein oder anderen "FLat" frei schalten, muss aber nicht unbedingt stimmen ..
  If W_LumpLength(W_GetNumForName(LumpName)) = 64 * 64 Then Begin
    result := ltFlat;
  End;
End;

Function LumpTypeToString(value: TLumpType): String;
Begin
  result := '';
  Case value Of
    ltUnknown: result := 'Unknown';
    ltPatch: result := 'patch_t';
    ltSound: Result := 'Sound';
    ltMusic: result := 'Music';
    ltMap: Result := 'Map';
    ltFlat: result := 'Flat';
    ltExportAsRaw: result := 'Export as RAW';
  Else Begin
      Raise exception.create('LumpTypeToString, missing type in case!');
    End;
  End;
End;

End.

