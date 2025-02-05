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
Begin
  result := ltUnknown;
  If Not assigned(p) Then exit;

  // Check auf patch_t
  patch := p;
  // Heuristik zum Erkennen ob der Lump ein patch_t sein könnte oder nicht ..
  If (patch^.width > 640) Or (patch^.width <= 0) Or
    (patch^.height > 400) Or (patch^.height <= 0) Then Begin
    exit;
  End;
  result := ltPatch;
  // TODO: Theoretisch könnte hier noch die gesammte Colmun geschichte abgeklappert werden und geschaut ob sich das wirklich alles sauber auflösen lässt.
End;

Function LumpTypeToString(value: TLumpType): String;
Begin
  result := '';
  Case value Of
    ltUnknown: result := 'Unknown';
    ltPatch: result := 'patch_t';
  Else Begin
      Raise exception.create('LumpTypeToString, missing type in case!');
    End;
  End;
End;

End.

