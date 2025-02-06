Unit Unit6;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls;

Type

  { TForm6 }

  TForm6 = Class(TForm)
    Image1: TImage;
    Procedure FormCreate(Sender: TObject);
  private
    Procedure CreatepreviewImage();
  public

    Function LoadMapLump(Const Lump: String): Boolean;

  End;

Var
  Form6: TForm6;

Implementation

{$R *.lfm}

Uses
  ufpc_doom_types,
  math
  , w_wad
  ;
Type
  mapvertex_t = Packed Record
    x: Int16;
    y: Int16;
  End;

  maplinedef_t = Packed Record
    v1: uInt16;
    v2: uInt16;
    flags: uInt16;
    special: Int16;
    tag: Int16;
    sidenum: Array[0..1] Of uInt16;
  End;

  TMapLine = Record
    v1: uInt16;
    v2: uInt16;
    flags: uInt16;
    special: Int16;
  End;

Var
  MapVertexes: Array Of TPoint;
  MapLines: Array Of TMapLine;
  MinDim, MaxDim: TPoint;
  MapWidth, MapHeight: Integer;

  { TForm6 }

Procedure TForm6.FormCreate(Sender: TObject);
Begin
  caption := 'Map previewer';
End;

Procedure TForm6.CreatepreviewImage();
Var
  scale: Single;
  MDim, i: Integer;
  b: TBitmap;
  p1, p2: TPoint;
Begin
  // So Scallieren, dass die Karte immer in eine maximal 1024x1024 Graphik Past
  mDim := max(MapWidth, MapHeight);
  scale := 1024 / mdim;
  b := TBitmap.Create;
  b.Width := round(MapWidth * scale);
  b.Height := round(MapHeight * scale);
  // Erst mal Alles Löschen
  b.canvas.Brush.Color := clBlack;
  b.Canvas.Rectangle(-1, -1, b.Width + 1, b.Height + 1);
  For i := 0 To high(MapLines) Do Begin
    p1 := point(
      round((MapVertexes[MapLines[i].v1].X - MinDim.x) * scale),
      round((MapVertexes[MapLines[i].v1].y - MinDim.y) * scale)
      );
    p2 := point(
      round((MapVertexes[MapLines[i].v2].X - MinDim.x) * scale),
      round((MapVertexes[MapLines[i].v2].y - MinDim.y) * scale)
      );
    // Irgendwie sieht es "Natürlicher" aus, wenn man die Karten auf dem Kopf malt..
    p1.y := b.Height - p1.Y;
    p2.y := b.Height - p2.Y;
    // Zeichnen der Linien, es geht nicht alles, weil wir nicht alle Infos des Spieles haben, aber immerhin a bissl was ;)
    b.canvas.Pen.Color := $808080; // Normale Wände..
    Case MapLines[i].special Of // Türen mit Schlüsselfarben
      26, 32, 99, 133: b.canvas.Pen.Color := clBlue;
      27, 34, 136, 137: b.canvas.Pen.Color := clYellow;
      28, 33, 134, 135: b.canvas.Pen.Color := clRed;
    End;
    If MapLines[i].special In [11, 51, 52, 124] Then Begin // Exit Türen
      b.canvas.Pen.Color := clwhite;
    End;
    If MapLines[i].special In [39, 97] Then Begin // Teleporter
      b.canvas.Pen.Color := clFuchsia;
    End;
    b.canvas.Line(p1, p2);
  End;
  Image1.Picture.Assign(b);
  b.free;
End;

Function TForm6.LoadMapLump(Const Lump: String): Boolean;
Var
  MapLumpIndex, VertexLumpIndex, LineDefsLumpIndex: integer;
  Vertexes: ^mapvertex_t;
  Lines: ^maplinedef_t;
  NumVertexes, NumLineDefs, i: Integer;
Begin
  result := false;
  MapLumpIndex := W_CheckNumForName(Lump);
  If MapLumpIndex < 0 Then exit;
  VertexLumpIndex := MapLumpIndex + 4;
  If (VertexLumpIndex > high(lumpinfo)) Or (lumpinfo[VertexLumpIndex].name <> 'VERTEXES') Then exit;
  LineDefsLumpIndex := MapLumpIndex + 2;
  If (LineDefsLumpIndex > high(lumpinfo)) Or (lumpinfo[LineDefsLumpIndex].name <> 'LINEDEFS') Then exit;
  NumVertexes := W_LumpLength(VertexLumpIndex) Div sizeof(mapvertex_t);
  NumLineDefs := W_LumpLength(LineDefsLumpIndex) Div sizeof(maplinedef_t);
  setlength(MapVertexes, NumVertexes);
  setlength(MapLines, NumLineDefs);
  Vertexes := W_CacheLumpNum(VertexLumpIndex, 0);
  Lines := W_CacheLumpNum(LineDefsLumpIndex, 0);
  For i := 0 To high(MapVertexes) Do Begin
    MapVertexes[i].X := Vertexes^.x;
    MapVertexes[i].Y := Vertexes^.y;
    inc(Vertexes);
    If i = 0 Then Begin
      MinDim := MapVertexes[i];
      MaxDim := MapVertexes[i];
    End
    Else Begin
      MinDim.x := min(MinDim.x, MapVertexes[i].x);
      MinDim.y := min(MinDim.y, MapVertexes[i].y);
      MaxDim.x := max(MaxDim.x, MapVertexes[i].x);
      MaxDim.y := max(MaxDim.y, MapVertexes[i].y);
    End;
  End;
  MapWidth := MaxDim.X - MinDim.x;
  MapHeight := MaxDim.y - MinDim.y;
  For i := 0 To NumLineDefs - 1 Do Begin
    MapLines[i].v1 := lines^.v1;
    MapLines[i].v2 := lines^.v2;
    MapLines[i].flags := lines^.flags;
    MapLines[i].special := lines^.special;
    inc(Lines);
  End;
  // TODO: ggf noch die "Dinge" oder wenigstens die Spieler Startposition anzeigen ?
  CreatepreviewImage;
  result := true;
End;

End.

