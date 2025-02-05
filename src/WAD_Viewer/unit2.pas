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
    Procedure Button1Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
  private
    Procedure LoadAndShowPatch(Const Lump: String);

  public

    Procedure SelectDatatypeByString(Const Datatype: String);

  End;

Var
  Form2: TForm2;

Implementation

{$R *.lfm}

Uses Unit3, uWAD_viewer;

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
End;

Procedure TForm2.FormCreate(Sender: TObject);
Var
  i: Integer;
Begin
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

