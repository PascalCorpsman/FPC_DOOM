(******************************************************************************)
(* WAD_Viewer                                                      04.02.2025 *)
(*                                                                            *)
(* Version     : 0.01                                                         *)
(*                                                                            *)
(* Author      : Uwe Schächterle (Corpsman)                                   *)
(*                                                                            *)
(* Support     : www.Corpsman.de                                              *)
(*                                                                            *)
(* Description : application to view the DOOM*.wad files, also creates the    *)
(*               *.lump files for FPC_DOOM                                    *)
(*                                                                            *)
(* License     : See the file license.md, located under:                      *)
(*  https://github.com/PascalCorpsman/Software_Licenses/blob/main/license.md  *)
(*  for details about the license.                                            *)
(*                                                                            *)
(*               It is not allowed to change or remove this text from any     *)
(*               source file of the project.                                  *)
(*                                                                            *)
(* Warranty    : There is no warranty, neither in correctness of the          *)
(*               implementation, nor anything other that could happen         *)
(*               or go wrong, use at your own risk.                           *)
(*                                                                            *)
(* Known Issues: none                                                         *)
(*                                                                            *)
(* History     : 0.01 - Initial version                                       *)
(*                                                                            *)
(******************************************************************************)
Unit Unit1;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    OpenDialog1: TOpenDialog;
    StringGrid1: TStringGrid;
    Procedure Button1Click(Sender: TObject);
    Procedure Button2Click(Sender: TObject);
    Procedure Button3Click(Sender: TObject);
    Procedure Button4Click(Sender: TObject);
    Procedure Edit1Change(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure StringGrid1ButtonClick(Sender: TObject; aCol, aRow: Integer);
    Procedure StringGrid1DblClick(Sender: TObject);
  private


    Procedure InitColorPallete;

  public
    Procedure LoadWadFile(Const Filename: String);

  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

Uses
  unit2, unit3
  , w_wad
  , uWAD_viewer
  ;

Const
  IndexIndex = 0;
  IndexLumpName = 1;
  IndexLumpSize = 2;
  IndexLumpType = 3;
  IndexLumpAction = 4;

  { TForm1 }

Procedure TForm1.Button1Click(Sender: TObject);
Begin
  //LoadWadFile('Doom2.wad'); // TODO: Debug- remove
  //exit; // TODO: Debug- remove

  // Select .wad file
  If OpenDialog1.Execute Then Begin
    LoadWadFile(OpenDialog1.FileName);
  End;
End;

Procedure TForm1.Button2Click(Sender: TObject);
Begin
  close;
End;

Procedure TForm1.Button3Click(Sender: TObject);
Begin
  // Debug Load BMP -> Save as Lump Memory
  Form3.Button1Click(Nil);
End;

Procedure TForm1.Button4Click(Sender: TObject);
Begin
  // Debug Load from .wad
  StringGrid1.Selection := rect(0, 626, 3, 626); // 0 Einfarbig
  StringGrid1.Selection := rect(0, 641, 3, 641); // 4 Zweifarbig
  StringGrid1DblClick(Nil);
End;

Procedure TForm1.Edit1Change(Sender: TObject);
Var
  i: Integer;
  s: String;
Begin
  StringGrid1.BeginUpdate;
  If Edit1.text = '' Then Begin
    For i := 1 To StringGrid1.RowCount - 1 Do Begin
      StringGrid1.RowHeights[i] := StringGrid1.RowHeights[0];
    End;
  End
  Else Begin
    s := UpperCase(edit1.text);
    For i := 1 To StringGrid1.RowCount - 1 Do Begin
      If pos(s, StringGrid1.Cells[IndexLumpName, i]) = 0 Then Begin
        StringGrid1.RowHeights[i] := 0;
      End
      Else Begin
        StringGrid1.RowHeights[i] := StringGrid1.RowHeights[0];
      End;
    End;
  End;
  StringGrid1.EndUpdate();
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  edit1.text := '';
  caption := 'Wad viewer, ver. 0.01';
End;

Procedure TForm1.StringGrid1ButtonClick(Sender: TObject; aCol, aRow: Integer);
Begin
  // Button Click
  form2.Label2.Caption := StringGrid1.Cells[IndexLumpName, aRow];
  form2.SelectDatatypeByString(StringGrid1.Cells[IndexLumpType, aRow]);
  form2.ShowModal;
End;

Procedure TForm1.StringGrid1DblClick(Sender: TObject);
Begin
  If StringGrid1.Selection.Top <> -1 Then Begin
    If StringGrid1.Cells[IndexLumpType, StringGrid1.Selection.Top] <> LumpTypeToString(ltUnknown) Then Begin
      form2.Label2.Caption := StringGrid1.Cells[IndexLumpName, StringGrid1.Selection.Top];
      form2.SelectDatatypeByString(StringGrid1.Cells[IndexLumpType, StringGrid1.Selection.Top]);
      form2.Button1.Click;
    End;
  End;
End;

Procedure TForm1.InitColorPallete;
Var
  i: Integer;
  playpal: PByte;
Begin
  (*
   * Auslesen der FarbPallete, die Dankenswerter weise direct im .wad file steht ;)
   *)
  playpal := W_CacheLumpName('PLAYPAL', 0);
  For i := 0 To 255 Do Begin
    Doom8BitTo24RGBBit[i] :=
      (playpal[i * 3 + 0] Shl 0)
      Or (playpal[i * 3 + 1] Shl 8)
      Or (playpal[i * 3 + 2] Shl 16);
  End;
End;

Procedure TForm1.LoadWadFile(Const Filename: String);
Var
  i: Integer;
Begin
  If Not W_AddFile(Filename) Then Begin
    showmessage('Error, could not load: ' + Filename);
  End;
  InitColorPallete;
  StringGrid1.RowCount := length(lumpinfo) + 1;
  For i := 0 To high(lumpinfo) Do Begin
    StringGrid1.Cells[IndexIndex, i + 1] := Inttostr(i + 1);
    StringGrid1.Cells[IndexLumpName, i + 1] := lumpinfo[i].name;
    StringGrid1.Cells[IndexLumpSize, i + 1] := inttostr(lumpinfo[i].size);
    StringGrid1.Cells[IndexLumpType, i + 1] := LumpTypeToString(GuessLumpTypeByPointer(W_CacheLumpNum(i, 0)));
  End;

  StringGrid1.AutoSizeColumns;
End;

End.

