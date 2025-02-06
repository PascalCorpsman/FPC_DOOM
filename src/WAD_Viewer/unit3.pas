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
Unit Unit3;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus;

Type

  { TForm3 }

  TForm3 = Class(TForm)
    Button1: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    MenuItem1: TMenuItem;
    OpenDialog1: TOpenDialog;
    PopupMenu1: TPopupMenu;
    SaveDialog1: TSaveDialog;
    Procedure Button1Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure MenuItem1Click(Sender: TObject);
  private
    LumpImage: TBitmap;
    LumpMem: Array[0..1024 * 100] Of Byte; // Wird für das "Importieren" als Lump benötigt

    Function LoadPatchLumpByPointer(Const ptr: Pointer): Boolean;

  public

    Function LoadPatchLump(Const Lump: String): Boolean;

  End;

Var
  Form3: TForm3;

Implementation

{$R *.lfm}

Uses w_wad, uWAD_viewer, v_patch;


Function V_GetPaletteIndex(color: TColor): integer;
Const
  INT_MAX = 65535;
Var
  best, best_diff, diff: integer;
  i: integer;
  r, g, b: integer;
Begin
  r := color And $FF;
  g := (color And $FF00) Shr 8;
  b := (color And $FF0000) Shr 16;

  best := 0;
  best_diff := INT_MAX;

  For i := 0 To 255 Do Begin
    diff :=
      sqr(r - Doom8BitTo24RGBBit[i] And $FF)
      + sqr(g - (Doom8BitTo24RGBBit[i] And $FF00) Shr 8)
      + sqr(b - (Doom8BitTo24RGBBit[i] And $FF0000) Shr 16);

    If (diff < best_diff) Then Begin
      best := i;
      best_diff := diff;
    End;

    If (diff = 0) Then break; // Besser wirds nemme ;)
  End;

  result := best;
End;

{ TForm3 }

Procedure TForm3.FormCreate(Sender: TObject);
Begin
  LumpImage := TBitmap.Create;
  caption := 'patch_t previewer';
End;


Procedure TForm3.Button1Click(Sender: TObject);
// Doku: https://www.cyotek.com/blog/decoding-doom-picture-files
Var
  p: ^patch_t;
  b: TBitmap;
  Columns: Array Of Array Of post_t;
  j, jStart, jEnd: Integer;
  post_t_cnt, i, DataOffset, index,
    PatchSize: integer; // Zähler wie viele "Streifchen" es insgesammt gibt
  k: Byte;
  c: Byte;
  Dest: PByte;
  m: TMemoryStream;
Begin
  If OpenDialog1.Execute Then Begin
    m := TMemoryStream.Create;
    b := TBitmap.Create;
    b.LoadFromFile(OpenDialog1.FileName);
    p := @LumpMem[0];
    p^.width := b.Width;
    p^.height := b.Height;
    If (b.Height >= 255) Or (b.Width >= 255) Then Begin
      showmessage('Error, image to big, can not be ported.');
      b.free;
      exit;
    End;
    // TODO: Rauskriegen wie man das "Richtig" Macht, oder gibt es das eigentlich gar nicht ?
    p^.leftoffset := b.Width Div 2;
    p^.topoffset := b.Height - 1;
    // 1. die Spalten "Streifchen" raus ziehen / Anzahl und Längen Berechnen
    Columns := Nil;
    setlength(Columns, b.Width);
    post_t_cnt := 0;
    For i := 0 To b.Width - 1 Do Begin
      j := 0;
      // Finden des 1. Pixels der <> clFuchsia ist;
      While j < b.Height Do Begin
        // 1. Pixel <> clFuchsia
        jStart := j;
        While (jStart < b.height) And (b.canvas.Pixels[i, jStart] = clFuchsia) Do Begin
          inc(jStart);
        End;
        // 1. Pixhel = clFuchsia
        jEnd := jStart;
        While (jEnd < b.Height) And (b.canvas.Pixels[i, jEnd] <> clFuchsia) Do Begin
          inc(jEnd);
        End;
        If jStart < b.Height Then Begin
          setlength(Columns[i], high(Columns[i]) + 2);
          Columns[i, high(Columns[i])].topdelta := jStart;
          Columns[i, high(Columns[i])].length := jEnd - jStart;
          post_t_cnt := post_t_cnt + 1;
        End;
        j := jEnd;
      End;
      // Der "Terminierende" post_t
      setlength(Columns[i], high(Columns[i]) + 2);
      Columns[i, high(Columns[i])].topdelta := 255;
      Columns[i, high(Columns[i])].length := 0;
      post_t_cnt := post_t_cnt + 1;
    End;
    // 2. Schreiben der columnofs Tabelle
    DataOffset :=
      sizeof(p^.width) +
      sizeof(p^.height) +
      sizeof(p^.topoffset) +
      sizeof(p^.leftoffset) +
      sizeof(integer) * b.Width // Größe der Columgstabelle
    ;
    index := 0;
    For i := 0 To high(Columns) Do Begin
      p^.columnofs[index] := DataOffset;
      For j := 0 To high(Columns[i]) - 1 Do Begin
        DataOffset := DataOffset + Columns[i, j].length + 2 + 2; // 2-Byte for Colum Header, 2 Byte for Dummy bytes
      End;
      DataOffset := DataOffset + 1; // Terminierungsbyte
      inc(index);
    End;
    PatchSize := DataOffset + 1; // das letzte Terminierungsbyte wird noch um das Längenbyte zu viel gelesen -> deswegen noch 1 Byte mehr
    // 3. Schreiben der eigentlichen Pixeldaten
    dest := pointer(p) + p^.columnofs[0];
    For i := 0 To high(Columns) Do Begin
      For j := 0 To high(Columns[i]) - 1 Do Begin
        dest^ := Columns[i, j].topdelta;
        inc(dest);
        dest^ := Columns[i, j].length;
        inc(dest);
        // Das Unused Stuffbyte am Anfang
        c := V_GetPaletteIndex(b.canvas.Pixels[i, Columns[i, j].topdelta]);
        dest^ := C;
        inc(dest);
        For k := 0 To Columns[i, j].length - 1 Do Begin
          c := V_GetPaletteIndex(b.canvas.Pixels[i, Columns[i, j].topdelta + k]);
          dest^ := C;
          inc(dest);
        End;
        // Das Unused Stuffbyte am Ende
        dest^ := C;
        inc(dest);
      End;
      dest^ := $FF; // Terminierungsbyte
      inc(dest);
    End;
    dest^ := 00; // Längenbyte nach dem Terminierungsbyte
    inc(dest);
    b.free;
    If Not ForceDirectories('lumps') Then Begin
      showmessage('Error could not create lumps directory.');
      m.free;
      exit;
    End;
    // Zur Kontrolle wird der Lump hier geladen und angezeigt ;)
    LoadPatchLumpByPointer(p);
    // Und dann passend abgespeichert
    m.Write(LumpMem, PatchSize);
    m.SaveToFile('lumps' + PathDelim + Label4.Caption + '.lump');
    m.free;
  End;
End;

Procedure TForm3.FormDestroy(Sender: TObject);
Begin
  LumpImage.free;
End;

Procedure TForm3.MenuItem1Click(Sender: TObject);
Begin
  // Export
  If SaveDialog1.Execute Then Begin
    LumpImage.SaveToFile(SaveDialog1.FileName);
  End;
End;

Function TForm3.LoadPatchLumpByPointer(Const ptr: Pointer): Boolean;
Var
  p: ^patch_t;
  i, j: Integer;
  column: Pcolumn_t;
  source: PByte;
  count: Byte;
  //  f: TextFile;
Begin
  result := false;
  p := ptr;

  //  assignfile(f, 'Blub.txt');
  //  Rewrite(f);
  If GuessLumpTypeByPointer(p, '') <> ltPatch Then exit;
  LumpImage.Width := p^.width;
  LumpImage.Height := p^.height;
  //  writeln(f, p^.width);
  //  writeln(f, p^.height);
  LumpImage.canvas.Brush.Color := Doom8BitTo24RGBBit[255];
  LumpImage.canvas.Rectangle(-1, -1, LumpImage.Width + 1, LumpImage.Height + 1);
  For i := 0 To p^.width - 1 Do Begin
    //    writeln(f, p^.columnofs[i]);
    column := Pointer(p) + p^.columnofs[i];
    While column^.topdelta <> $FF Do Begin
      source := pointer(column) + 3;
      j := column^.topdelta;
      For count := 0 To column^.length - 1 Do Begin
        LumpImage.canvas.Pixels[i, j] := Doom8BitTo24RGBBit[source^];
        inc(source);
        j := j + 1;
        If j > p^.height Then Begin
          exit;
        End;
      End;
      column := pointer(column) + column^.length + 4;
    End;
  End;
  image1.Picture.Assign(LumpImage);
  label2.caption := format('%d x %d', [p^.width, p^.height]);
  label6.caption := format('%d , %d', [p^.leftoffset, p^.topoffset]);
  result := true;
  //  CloseFile(f);
End;

Function TForm3.LoadPatchLump(Const Lump: String): Boolean;
Var
  ptr: PByte;
  m: TMemoryStream;
Begin
  ptr := W_CacheLumpName(Lump, 0);
  m := TMemoryStream.Create;
  m.Write(ptr^, W_LumpLength(W_GetNumForName(lump)));
  //  m.SaveToFile(lump + '.lump');
  m.free;
  result := LoadPatchLumpByPointer(ptr);
  label4.caption := Lump;
End;

End.

