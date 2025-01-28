Unit v_trans;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Const
  CR_NONE = 0;
  CR_DARK = 1;
  CR_GRAY = 2;
  CR_GREEN = 3;
  CR_GOLD = 4;
  CR_RED = 5;
  CR_BLUE = 6;
  CR_RED2BLUE = 7;
  CR_RED2GREEN = 8;
  CRMAX = 9;

  cr_esc = '~';

Var
  cr: Array[0..CRMAX - 1] Of Array Of byte;
  crstr: Array Of String = Nil;

Function V_Colorize(Const playpal: Pbyte; cr: int; source: byte; keepgray109: boolean): Byte;
Function V_GetPaletteIndex(palette: PByte; r, g, b: int): int;

Implementation

Uses
  math
  , v_video
  ;

Const
  CTOLERANCE = (0.0001);

Type
  vect = Record
    x: float;
    y: float;
    z: float;
  End;

Var
  // this one will be the identity matrix
  cr_none_pal: Array[0..255] Of byte;
  // this one will be the ~50% darker matrix
  cr_dark_pal: Array[0..255] Of byte;
  cr_gray_pal: Array[0..255] Of byte;
  cr_green_pal: Array[0..255] Of byte;
  cr_gold_pal: Array[0..255] Of byte;
  cr_red_pal: Array[0..255] Of byte;
  cr_blue_pal: Array[0..255] Of byte;

Const
  cr_red2blue_pal: Array[0..255] Of byte =
  (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 207, 207, 46, 207,
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
    64, 65, 66, 207, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
    80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
    96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
    112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,
    128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
    144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
    160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,
    200, 200, 201, 201, 202, 202, 203, 203, 204, 204, 205, 205, 206, 206, 207, 207,
    192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207,
    208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
    224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255);

  cr_red2green_pal: Array[0..255] Of byte =
  (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 127, 127, 46, 127,
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
    64, 65, 66, 127, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
    80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
    96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
    112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,
    128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
    144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
    160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,
    114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 126, 127, 127,
    192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207,
    208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
    224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255);

Procedure hsv_to_rgb(Var hsv: vect; Out rgb: vect);
Var
  h, s, v: float;
  f, p, q, t: float;
  i: int;
Begin
  h := hsv.x;
  s := hsv.y;
  v := hsv.z;
  h := h * 360;
  If (s < CTOLERANCE) Then Begin
    rgb.x := v;
    rgb.y := v;
    rgb.z := v;
  End
  Else Begin
    If (h >= 360) Then h := h - 360;
    h := h / 60;
    i := trunc(h);
    f := h - i;
    p := v * (1 - s);
    q := v * (1 - (s * f));
    t := v * (1 - (s * (1 - f)));
    Case i Of
      0: Begin
          rgb.x := v;
          rgb.y := t;
          rgb.z := p;
        End;
      1: Begin
          rgb.x := q;
          rgb.y := v;
          rgb.z := p;
        End;
      2: Begin
          rgb.x := p;
          rgb.y := v;
          rgb.z := t;
        End;
      3: Begin
          rgb.x := p;
          rgb.y := q;
          rgb.z := v;
        End;
      4: Begin
          rgb.x := t;
          rgb.y := p;
          rgb.z := v;
        End;
      5: Begin
          rgb.x := v;
          rgb.y := p;
          rgb.z := q;
        End;
    End;
  End;
End;

Procedure rgb_to_hsv(Var rgb: vect; Out hsv: vect);
Var
  h, s, v: Float;
  cmax, cmin: float;
  r, g, b: float;
  cdelta: float;
  rc, gc, bc: float;
Begin
  r := rgb.x;
  g := rgb.y;
  b := rgb.z;
  (* find the cmax and cmin of r g b *)
  cmax := r;
  cmin := r;
  cmax := (max(g, cmax));
  cmin := (min(g, cmin));
  cmax := (max(b, cmax));
  cmin := (min(b, cmin));
  v := cmax; (* value *)
  If (cmax > CTOLERANCE) Then Begin
    s := (cmax - cmin) / cmax;
  End
  Else Begin
    s := 0.0;
    h := 0.0;
  End;
  If (s < CTOLERANCE) Then Begin
    h := 0.0;
  End
  Else Begin
    cdelta := cmax - cmin;
    rc := (cmax - r) / cdelta;
    gc := (cmax - g) / cdelta;
    bc := (cmax - b) / cdelta;
    If (r = cmax) Then Begin
      h := bc - gc;
    End
    Else Begin
      If (g = cmax) Then Begin
        h := 2 + rc - bc;
      End
      Else Begin
        h := 4 + gc - rc;
      End;
    End;
    h := h * 60;
    If (h < 0) Then Begin
      h := h + 360;
    End;
  End;
  hsv.x := h / 360;
  hsv.y := s;
  hsv.z := v;
End;

Function V_GetPaletteIndex(palette: PByte; r, g, b: int): int;
Var
  best, best_diff, diff: int;
  i: int;
Begin
  best := 0;
  best_diff := INT_MAX;

  For i := 0 To 255 Do Begin
    diff :=
      sqr(r - palette[3 * i + 0])
      + sqr(g - palette[3 * i + 1])
      + sqr(b - palette[3 * i + 2]);

    If (diff < best_diff) Then Begin
      best := i;
      best_diff := diff;
    End;

    If (diff = 0) Then break; // Besser wirds nemme ;)
  End;

  result := best;
End;

Function V_Colorize(Const playpal: Pbyte; cr: int; source: byte;
  keepgray109: boolean): Byte;
Var
  rgb, hsv: vect;
Begin
  // [crispy] preserve gray drop shadow in IWAD status bar numbers
  If (cr = CR_NONE) Or ((keepgray109) And (source = 109)) Then Begin
    result := source;
    exit;
  End;

  rgb.x := playpal[3 * source + 0] / 255;
  rgb.y := playpal[3 * source + 1] / 255;
  rgb.z := playpal[3 * source + 2] / 255;

  rgb_to_hsv(rgb, hsv);

  Case cr Of
    CR_DARK: hsv.z := hsv.z * 0.5;
    CR_GRAY: hsv.y := 0;
  Else Begin
      // [crispy] hack colors to full saturation
      hsv.y := 1.0;
      Case cr Of
        CR_GREEN: hsv.x := (144 * hsv.z + 120 * (1 - hsv.z)) / 360;
        CR_GOLD: Begin
            hsv.x := (7.0 + 53 * hsv.z) / 360;
            hsv.y := 1.0 - 0.4 * hsv.z;
            hsv.z := 0.2 + 0.8 * hsv.z;
          End;
        CR_RED: hsv.x := 0;
        CR_BLUE: hsv.x := 240 / 360;
      End;
    End;
  End;
  hsv_to_rgb(hsv, rgb);

  rgb.x := rgb.x * 255;
  rgb.y := rgb.y * 255;
  rgb.z := rgb.z * 255;

  result := V_GetPaletteIndex(playpal, trunc(rgb.x), trunc(rgb.y), trunc(rgb.z));
End;

Initialization

  // Die Warnung ist Falsch, die Array's werden in R_InitHSVColors initialisiert.
  cr[0] := cr_none_pal;
  cr[1] := cr_dark_pal;
  cr[2] := cr_gray_pal;
  cr[3] := cr_green_pal;
  cr[4] := cr_gold_pal;
  cr[5] := cr_red_pal;
  cr[6] := cr_blue_pal;
  cr[7] := cr_red2blue_pal;
  cr[8] := cr_red2green_pal;

End.

