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
    ltExportAsRaw,
    ltCount // Muss immer der letzte sein !
    );

Var
  Doom8BitTo24RGBBit: Array[0..255] Of UInt32;

Function GuessLumpTypeByPointer(Const p: Pointer): TLumpType;

Function LumpTypeToString(value: TLumpType): String;

Implementation

Uses v_patch;

Function GuessLumpTypeByPointer(Const p: Pointer): TLumpType;
Var
  patch: ^patch_t;
  pui16: ^UInt16;

Begin
  result := ltUnknown;
  If Not assigned(p) Then exit;

  // Check auf patch_t
  patch := p;
  If (patch^.width <= 640) And (patch^.width > 0) And
    (patch^.height <= 400) And (patch^.height > 0) Then Begin
    // TODO: Theoretisch könnte hier noch die gesammte Colmun geschichte abgeklappert werden und geschaut ob sich das wirklich alles sauber auflösen lässt.
    result := ltPatch;
    exit;
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

End;

Function LumpTypeToString(value: TLumpType): String;
Begin
  result := '';
  Case value Of
    ltUnknown: result := 'Unknown';
    ltPatch: result := 'patch_t';
    ltSound: Result := 'Sound';
    ltExportAsRaw: result := 'Export as RAW';
  Else Begin
      Raise exception.create('LumpTypeToString, missing type in case!');
    End;
  End;
End;

End.

