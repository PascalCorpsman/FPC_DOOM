(******************************************************************************)
(* WAD_Viewer                                                      04.02.2025 *)
(*                                                                            *)
(* Version     : 0.04                                                         *)
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
(*               0.02 - Export Lump as RAW                                    *)
(*               0.03 - Preview sfx lumps                                     *)
(*                      Preview map                                           *)
(*               0.04 - Lumpsize filter                                       *)
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
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    OpenDialog1: TOpenDialog;
    StringGrid1: TStringGrid;
    Procedure Button1Click(Sender: TObject);
    Procedure Button2Click(Sender: TObject);
    Procedure Button3Click(Sender: TObject);
    Procedure Button4Click(Sender: TObject);
    Procedure Edit1Change(Sender: TObject);
    Procedure Edit2Change(Sender: TObject);
    Procedure Edit3Change(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure StringGrid1ButtonClick(Sender: TObject; aCol, aRow: Integer);
    Procedure StringGrid1DblClick(Sender: TObject);
  private
    Procedure InitColorPallete;
    Procedure ArrangeColumnEdit(Const Edit: Tedit; ColIndex: integer);
    Procedure ClearOtherFilter(Const SkipFilter: TEdit);
  public
    Procedure LoadWadFile(Const Filename: String);
  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

Uses
  bass,
  unit2, unit3
  , w_wad
  , uWAD_viewer
  , ufpc_doom_types
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
  // LoadWadFile('Doom1.wad'); // TODO: Debug- remove
  // LoadWadFile('Doom2.wad'); // TODO: Debug- remove
  // exit; // TODO: Debug- remove
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
  c, i: Integer;
  s: String;
Begin
  StringGrid1.BeginUpdate;
  ClearOtherFilter(edit1);
  If Edit1.text = '' Then Begin
    For i := 1 To StringGrid1.RowCount - 1 Do Begin
      StringGrid1.RowHeights[i] := StringGrid1.RowHeights[0];
    End;
    c := StringGrid1.RowCount - 1;
  End
  Else Begin
    s := UpperCase(edit1.text);
    c := 0;
    For i := 1 To StringGrid1.RowCount - 1 Do Begin
      If pos(s, StringGrid1.Cells[IndexLumpName, i]) = 0 Then Begin
        StringGrid1.RowHeights[i] := 0;
      End
      Else Begin
        StringGrid1.RowHeights[i] := StringGrid1.RowHeights[0];
        c := c + 1;
      End;
    End;
  End;
  StringGrid1.EndUpdate();
  label2.caption := format('%d of %d lumps', [c, StringGrid1.RowCount - 1]);
End;

Procedure TForm1.Edit2Change(Sender: TObject);
Var
  c, i: Integer;
  s: String;
Begin
  StringGrid1.BeginUpdate;
  ClearOtherFilter(edit2);
  If Edit2.text = '' Then Begin
    For i := 1 To StringGrid1.RowCount - 1 Do Begin
      StringGrid1.RowHeights[i] := StringGrid1.RowHeights[0];
      c := StringGrid1.RowCount - 1;
    End;
  End
  Else Begin
    s := UpperCase(edit2.text);
    c := 0;
    For i := 1 To StringGrid1.RowCount - 1 Do Begin
      If pos(s, UpperCase(StringGrid1.Cells[IndexLumpType, i])) = 0 Then Begin
        StringGrid1.RowHeights[i] := 0;
      End
      Else Begin
        StringGrid1.RowHeights[i] := StringGrid1.RowHeights[0];
        c := c + 1;
      End;
    End;
  End;
  StringGrid1.EndUpdate();
  label2.caption := format('%d of %d lumps', [c, StringGrid1.RowCount - 1]);
End;

Procedure TForm1.Edit3Change(Sender: TObject);
Type
  tOperand = (lt, eq, gt);
Var
  si, s, c, i: Integer;
  op: tOperand;
  b: Boolean;
  str: String;
Begin
  StringGrid1.BeginUpdate;
  op := gt;
  ClearOtherFilter(edit3);
  If Edit3.text = '' Then Begin
    For i := 1 To StringGrid1.RowCount - 1 Do Begin
      StringGrid1.RowHeights[i] := StringGrid1.RowHeights[0];
      c := StringGrid1.RowCount - 1;
    End;
  End
  Else Begin
    str := Edit3.Text;
    If str[1] In ['=', '>', '<'] Then Begin
      Case str[1] Of
        '<': op := lt;
        '=': op := eq;
        '>': op := gt;
      End;
      delete(str, 1, 1);
    End;
    s := StrToIntDef(str, 0);
    c := 0;
    For i := 1 To StringGrid1.RowCount - 1 Do Begin
      b := false;
      si := StrToIntDef(StringGrid1.Cells[IndexLumpSize, i], 0);
      Case op Of
        lt: b := s > si;
        eq: b := s = si;
        gt: b := s < si;
      End;
      If Not b Then Begin
        StringGrid1.RowHeights[i] := 0;
      End
      Else Begin
        StringGrid1.RowHeights[i] := StringGrid1.RowHeights[0];
        c := c + 1;
      End;
    End;
  End;
  StringGrid1.EndUpdate();
  label2.caption := format('%d of %d lumps', [c, StringGrid1.RowCount - 1]);
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  edit1.text := '';
  edit2.text := '';
  edit3.text := '';
  label2.caption := '';
  caption := 'Wad viewer, ver. 0.04';
  If (BASS_GetVersion() Shr 16) <> Bassversion Then Begin
    showmessage('Unable to init the Bass Library ver. :' + BASSVERSIONTEXT);
    halt;
  End;
  If (Not Bass_init(-1, 44100, 0, {$IFDEF Windows}0{$ELSE}Nil{$ENDIF}, Nil)) Then Begin
    showmessage('Unable to init sound device, playsound option will be disabled.');
    halt;
  End;
End;

Procedure TForm1.FormDestroy(Sender: TObject);
Begin
  Bass_Free;
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

Procedure TForm1.ArrangeColumnEdit(Const Edit: Tedit; ColIndex: integer);
Var
  s, i: integer;
Begin
  s := StringGrid1.Left;
  For i := 0 To ColIndex - 1 Do Begin
    s := s + StringGrid1.ColWidths[i]
  End;
  edit.Left := s;
  edit.Width := StringGrid1.ColWidths[ColIndex];
End;

Procedure TForm1.ClearOtherFilter(Const SkipFilter: TEdit);
Var
  i: Integer;
  oc: TNotifyEvent;
Begin
  For i := 0 To ComponentCount - 1 Do Begin
    If Components[i] Is TEdit Then Begin
      If Components[i] <> SkipFilter Then Begin
        oc := TEdit(Components[i]).OnChange;
        TEdit(Components[i]).OnChange := Nil;
        TEdit(Components[i]).Text := '';
        TEdit(Components[i]).OnChange := oc;
      End;
    End;
  End;
End;

Procedure TForm1.LoadWadFile(Const Filename: String);
Var
  i: Integer;
Begin
  W_ResetAndFreeALL;
  If Not W_AddFile(Filename) Then Begin
    showmessage('Error, could not load: ' + Filename);
  End;
  caption := 'Loaded: ' + ExtractFileName(Filename);
  InitColorPallete;
  StringGrid1.RowCount := length(lumpinfo) + 1;
  For i := 0 To high(lumpinfo) Do Begin
    If i = 497 - 1 Then Begin // Zum Debuggen einen Haltepunkt ..
      nop();
    End;
    StringGrid1.Cells[IndexIndex, i + 1] := Inttostr(i + 1);
    StringGrid1.Cells[IndexLumpName, i + 1] := lumpinfo[i].name;
    StringGrid1.Cells[IndexLumpSize, i + 1] := inttostr(lumpinfo[i].size);
    StringGrid1.Cells[IndexLumpType, i + 1] := LumpTypeToString(GuessLumpTypeByPointer(W_CacheLumpNum(i, 0), lumpinfo[i].name));
  End;

  StringGrid1.AutoSizeColumns;
  ArrangeColumnEdit(edit1, IndexLumpName);
  ArrangeColumnEdit(edit2, IndexLumpType);
  ArrangeColumnEdit(edit3, IndexLumpSize);

  edit1.text := '';
  edit2.text := '';
  edit3.text := '';
  label2.caption := format('%d lumps', [StringGrid1.RowCount - 1]);
End;

End.

