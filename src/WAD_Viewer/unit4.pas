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
Unit Unit4;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uwave;

Type

  { TForm4 }

  TForm4 = Class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    SaveDialog1: TSaveDialog;
    Procedure Button1Click(Sender: TObject);
    Procedure Button2Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
  private
    wav: TWave;
    LumpName: String;

  public

    Function LoadSoundLump(Const Lump: String): Boolean;

  End;

Var
  Form4: TForm4;

Implementation

{$R *.lfm}

Uses
  w_wad;

Type
  // Quelle: https://doomwiki.org/wiki/Sound
  TDMXHeader = Packed Record
    Format: UInt16;
    SampleRate: UInt16;
    NumberOfSamples: UInt32;
    PADDING1: Array[0..15] Of ShortInt; // Die ersten 16 und letzten 16 Byte werden nicht genutzt.
    SOUND: Array[0..high(Integer)] Of ShortInt;
    // Padding2: Array [0..15] of ShortInt;
  End;

  { TForm4 }

Procedure TForm4.FormCreate(Sender: TObject);
Begin
  caption := 'Sound previewer';
  Constraints.MinWidth := Width;
  Constraints.MinHeight := Height;
  Constraints.MaxWidth := Width;
  Constraints.MaxHeight := Height;
  wav := TWave.Create;
End;

Procedure TForm4.Button1Click(Sender: TObject);
Begin
  SaveDialog1.FileName := LumpName + '.wav';
  If SaveDialog1.Execute Then Begin
    wav.SaveToFile(SaveDialog1.FileName);
  End;
End;

Procedure TForm4.Button2Click(Sender: TObject);
Begin
  showmessage('todo.');
End;

Procedure TForm4.FormDestroy(Sender: TObject);
Begin
  wav.free;
End;

Function TForm4.LoadSoundLump(Const Lump: String): Boolean;
Const
  PadLen = 32;
Var
  Header: ^TDMXHeader;
  i: Integer;
Begin
  LumpName := Lump;
  result := false;
  Header := W_CacheLumpName(lump, 0);
  If Header^.Format <> 3 Then exit;
  If (Header^.SampleRate <> 11025) And (Header^.SampleRate <> 22050) Then exit;
  If (header^.NumberOfSamples - PadLen) <= 0 Then exit;
  label2.caption := inttostr(Header^.SampleRate);
  label4.caption := inttostr(Header^.NumberOfSamples - PadLen);
  If Header^.NumberOfSamples = 0 Then exit;
  label6.caption := format('%0.1fs', [(Header^.NumberOfSamples - PadLen) / Header^.SampleRate]);
  wav.InitNewBuffer(1, Header^.SampleRate, 8, Header^.NumberOfSamples - PadLen);
  For i := 0 To Header^.NumberOfSamples - 1 - PadLen Do Begin
    wav.Sample[0, i] := (Header^.SOUND[i] / 128);
  End;
  result := true;
End;

End.

