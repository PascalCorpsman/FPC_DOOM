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
  Buttons, uwave
  ;

Const
  PadLen = 32;

Type
  // Quelle: https://doomwiki.org/wiki/Sound
  TDMXSound = Packed Record
    Format: UInt16;
    SampleRate: UInt16;
    NumberOfSamples: UInt32;
    PADDING1: Array[0..15] Of ShortInt; // Die ersten 16 und letzten 16 Byte werden nicht genutzt.
    SOUND: Array[0..high(Integer)] Of ShortInt; // Der ist also Gültig im Bereich [0..NumberOfSamples - PadLen - 1]
    // Padding2: Array [0..15] of ShortInt;
  End;

  { TForm4 }

  TForm4 = Class(TForm)
    Button1: TButton;
    CheckBox1: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    SaveDialog1: TSaveDialog;
    SpeedButton1: TSpeedButton;
    Procedure Button1Click(Sender: TObject);
    Procedure FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure SpeedButton1Click(Sender: TObject);
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
  BASS
  , w_wad
  ;

Var
  DMXSound: ^TDMXSound;
  DMXSoundIndex: integer;
  PreviewStream: HSTREAM;

Function GetPreviewData(handle: HSTREAM; buffer: Pointer; length: DWORD; user: Pointer): DWORD;
{$IFDEF Windows} stdcall;
{$ELSE} cdecl;
{$ENDIF}
Var
  cnt: integer;
  buf: PByte;
Begin
  buf := buffer;
  If (DMXSoundIndex + length) <= (DMXSound^.NumberOfSamples - PadLen) Then Begin
    cnt := length;
  End
  Else Begin
    cnt := (DMXSound^.NumberOfSamples - PadLen) - (DMXSoundIndex);
  End;
  move(DMXSound^.SOUND[DMXSoundIndex], buf^, cnt);
  DMXSoundIndex := DMXSoundIndex + cnt;
  result := cnt;
  If cnt <> length Then Begin
    If Form4.CheckBox1.Checked Then Begin // Loop Sounds
      DMXSoundIndex := 0;
    End
    Else Begin // End Sound
      result := result Or BASS_STREAMPROC_END;
    End;
  End;
End;

{ TForm4 }

Procedure TForm4.FormCreate(Sender: TObject);
Begin

  // Einen Dummy erstellen, der wird nachher eh wieder weg geworfen..
  PreviewStream := BASS_StreamCreate(44100, 1, BASS_SAMPLE_8BITS, @GetPreviewData, Nil);
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

Procedure TForm4.FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
Begin
  If BASS_ChannelIsActive(PreviewStream) <> 0 Then Begin
    BASS_ChannelStop(PreviewStream);
  End;
End;

Procedure TForm4.FormDestroy(Sender: TObject);
Begin
  BASS_ChannelStop(PreviewStream);
  BASS_StreamFree(PreviewStream);
  wav.free;
End;

Procedure TForm4.SpeedButton1Click(Sender: TObject);
Begin
  // Play
  If BASS_ChannelIsActive(PreviewStream) <> 0 Then Begin
    BASS_ChannelStop(PreviewStream);
  End;
  DMXSoundIndex := 0;
  If Not BASS_ChannelPlay(PreviewStream, true) Then Begin
    showmessage('Could not start stream playback');
  End;
End;

Function TForm4.LoadSoundLump(Const Lump: String): Boolean;
Var
  i: Integer;
Begin
  LumpName := Lump;
  result := false;
  DMXSound := W_CacheLumpName(lump, 0);
  If DMXSound^.Format <> 3 Then exit;
  If (DMXSound^.SampleRate <> 11025) And (DMXSound^.SampleRate <> 22050) Then exit;
  If (DMXSound^.NumberOfSamples - PadLen) <= 0 Then exit;
  label2.caption := inttostr(DMXSound^.SampleRate);
  label4.caption := inttostr(DMXSound^.NumberOfSamples - PadLen);
  If DMXSound^.NumberOfSamples = 0 Then exit;
  label6.caption := format('%0.1fs', [(DMXSound^.NumberOfSamples - PadLen) / DMXSound^.SampleRate]);
  wav.InitNewBuffer(1, DMXSound^.SampleRate, 8, DMXSound^.NumberOfSamples - PadLen);
  For i := 0 To DMXSound^.NumberOfSamples - 1 - PadLen Do Begin
    wav.Sample[0, i] := (DMXSound^.SOUND[i] / 128);
  End;
  BASS_ChannelStop(PreviewStream);
  BASS_StreamFree(PreviewStream);
  PreviewStream := BASS_StreamCreate(DMXSound^.SampleRate, 1, BASS_SAMPLE_8BITS, @GetPreviewData, Nil);
  result := true;
  SpeedButton1Click(Nil); // Wir starten den Stream mal direct ;)
End;

End.

