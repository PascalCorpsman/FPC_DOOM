Unit Unit5;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

Type

  { TForm5 }

  TForm5 = Class(TForm)
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Procedure FormCreate(Sender: TObject);
  private

  public
    Function LoadSoundLump(Const Lump: String): Boolean;
  End;

Var
  Form5: TForm5;

Implementation

{$R *.lfm}

Uses
  w_wad;

Type
  MUSheader = Packed Record
    ID: Array[0..3] Of char; // identifier "MUS" 0x1A
    scoreLen: UInt16;
    scoreStart: UInt16;
    channels: UInt16; // count of primary channels
    sec_channels: UInt16; // count of secondary channels
    instrCnt: UInt16;
    dummy: UInt16;
    // variable-length part starts here
    instruments: Array[0..65536] Of UInt16;
  End;

  { TForm5 }

Procedure TForm5.FormCreate(Sender: TObject);
Begin
  caption := 'Music previewer';
End;

Function TForm5.LoadSoundLump(Const Lump: String): Boolean;
Var
  Header: ^MUSheader;
Begin
  result := false;
  Header := W_CacheLumpName(lump, 0);
  If (header^.ID[0] <> 'M') Or
    (header^.ID[1] <> 'U') Or
    (header^.ID[2] <> 'S') Or
    (header^.ID[3] <> chr($1A)) Then exit;
  label6.Caption := inttostr(Header^.scoreLen);
  label7.Caption := inttostr(Header^.scoreStart);
  label8.Caption := inttostr(Header^.channels);
  label9.Caption := inttostr(Header^.sec_channels);
  label10.Caption := inttostr(Header^.instrCnt);
  result := true;
End;

End.

