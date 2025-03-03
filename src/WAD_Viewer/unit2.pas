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
Unit Unit2;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

Type

  { TForm2 }

  TForm2 = Class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    RadioGroup1: TRadioGroup;
    SaveDialog1: TSaveDialog;
    Procedure Button1Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
  private
    Procedure LoadAndShowPatch(Const Lump: String);
    Procedure LoadAndShowFlat(Const Lump: String);
    Procedure LoadAndShowSound(Const Lump: String);
    Procedure LoadAndShowMusic(Const Lump: String);
    Procedure LoadAndShowMap(Const Lump: String);
    Procedure ExportAsRaw(Const Lump: String);
  public
    Procedure SelectDatatypeByString(Const Datatype: String);
  End;

Var
  Form2: TForm2;

Implementation

{$R *.lfm}

Uses Unit3, Unit4, Unit5, Unit6, uWAD_viewer, w_wad;

{ TForm2 }

Procedure TForm2.Button1Click(Sender: TObject);
Var
  s: String;
Begin
  If RadioGroup1.ItemIndex < 0 Then exit;
  s := RadioGroup1.Items[RadioGroup1.ItemIndex];
  If s = LumpTypeToString(ltPatch) Then Begin
    LoadAndShowPatch(label2.caption);
  End;
  If s = LumpTypeToString(ltSound) Then Begin
    LoadAndShowSound(label2.caption);
  End;
  If s = LumpTypeToString(ltMusic) Then Begin
    LoadAndShowMusic(label2.caption);
  End;
  If s = LumpTypeToString(ltMap) Then Begin
    LoadAndShowMap(label2.caption);
  End;
  If s = LumpTypeToString(ltExportAsRaw) Then Begin
    ExportAsRaw(label2.caption);
  End;
  If s = LumpTypeToString(ltFlat) Then Begin
    LoadAndShowFlat(label2.caption);
  End;
End;

Procedure TForm2.FormCreate(Sender: TObject);
Var
  i: Integer;
Begin
  caption := 'Select action';
  RadioGroup1.items.Clear;
  For i := 1 To integer(ltCount) - 1 Do Begin // ltUnknown wird ausgelassen
    RadioGroup1.items.Add(
      LumpTypeToString(
      TLumpType(i))
      );
  End;
End;

Procedure TForm2.LoadAndShowPatch(Const Lump: String);
Begin
  If form3.LoadPatchLump(Lump) Then Begin
    form3.ShowModal;
  End
  Else Begin
    showmessage('Error, "' + lump + '" does not seem to be a valild patch_t');
  End;
End;

Procedure TForm2.LoadAndShowFlat(Const Lump: String);
Begin
  If form3.LoadFlatLump(Lump) Then Begin
    form3.ShowModal;
  End
  Else Begin
    showmessage('Error, "' + lump + '" does not seem to be a valild flat');
  End;
End;

Procedure TForm2.LoadAndShowSound(Const Lump: String);
Begin
  If form4.LoadSoundLump(Lump) Then Begin
    form4.ShowModal;
  End
  Else Begin
    showmessage('Error, "' + lump + '" does not seem to be a valild sound');
  End;
End;

Procedure TForm2.LoadAndShowMusic(Const Lump: String);
Begin
  If form5.LoadSoundLump(Lump) Then Begin
    form5.ShowModal;
  End
  Else Begin
    showmessage('Error, "' + lump + '" does not seem to be a valild music');
  End;
End;

Procedure TForm2.LoadAndShowMap(Const Lump: String);
Begin
  If form6.LoadMapLump(Lump) Then Begin
    form6.ShowModal;
  End
  Else Begin
    showmessage('Error, "' + lump + '" does not seem to be a valild map');
  End;
End;

Procedure TForm2.ExportAsRaw(Const Lump: String);
Var
  m: TMemoryStream;
  p: PByte;
Begin
  SaveDialog1.Filename := Lump + '.lump';
  If SaveDialog1.Execute Then Begin
    m := TMemoryStream.Create;
    p := W_CacheLumpName(lump, 0);
    m.Write(p^, W_LumpLength(W_GetNumForName(lump)));
    m.SaveToFile(SaveDialog1.FileName);
    m.free;
  End;
End;

Procedure TForm2.SelectDatatypeByString(Const Datatype: String);
Var
  i: Integer;
Begin
  RadioGroup1.ItemIndex := -1;
  For i := 0 To RadioGroup1.Items.Count - 1 Do Begin
    If Datatype = RadioGroup1.Items[i] Then Begin
      RadioGroup1.ItemIndex := i;
      exit;
    End;
  End;
End;

End.

