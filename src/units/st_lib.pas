Unit st_lib;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  info_types
  , v_patch, v_trans
  ;

Type

  // Number widget

  st_number_t = Record

    // upper right-hand corner
    //  of the number (right-justified)
    x: int;
    y: int;

    // max # of digits in number
    width: int;

    // last number value
    oldnum: int;

    // pointer to current value
    num: P_int;

    // pointer to boolean stating
    //  whether to update number
    _on: Pboolean;

    // list of patches for 0-9
    p: Pppatch_t;

    // user data
    data: int;
  End;
  Pst_number_t = ^st_number_t;

  // Binary Icon widget
  st_binicon_t = Record
    // center-justified location of icon
    x: int;
    y: int;

    // last icon value
    oldval: boolean;

    // pointer to current icon status
    val: PBoolean;

    // pointer to boolean
    //  stating whether to update icon
    _on: PBoolean;

    p: Ppatch_t; // icon
    data: int; // user data
  End;
  Pst_binicon_t = ^st_binicon_t;

  // Percent widget ("child" of number widget,
  //  or, more precisely, contains a number widget.)
  st_percent_t = Record

    // number information
    n: st_number_t;

    // percent sign graphic
    p: Ppatch_t;

    // [crispy] remember previous colorization
    oldtranslation: Array Of byte;
  End;
  Pst_percent_t = ^st_percent_t;

  // Multiple Icon widget
  st_multicon_t = Record
    // center-justified location of icons
    x: int;
    y: int;

    // last icon number
    oldinum: int;

    // pointer to current icon
    inum: P_int;

    // pointer to boolean stating
    //  whether to update icon
    _on: PBoolean;

    // list of icons
    p: PPpatch_t;

    // user data
    data: int;
  End;
  Pst_multicon_t = ^st_multicon_t;

Procedure STlib_initNum(Out n: st_number_t;
  x: int;
  y: int;
  pl: PPpatch_t;
  num: P_int;
  _on: Pboolean;
  width: int);

Procedure STlib_initBinIcon
  (Out b: st_binicon_t;
  x: int;
  y: int;
  i: Ppatch_t;
  val: Pboolean;
  _on: Pboolean);

Procedure STlib_initPercent
  (Out p: st_percent_t;
  x: int;
  y: int;
  pl: PPpatch_t;
  num: P_int;
  _on: Pboolean;
  percent: Ppatch_t);

Procedure STlib_initMultIcon
  (Out i: st_multicon_t;
  x: int;
  y: int;
  il: PPpatch_t;
  inum: P_int;
  _on: Pboolean);

Procedure STlib_init();

Procedure STlib_updateNum(n: Pst_number_t; refresh: boolean);
Procedure STlib_updatePercent(per: Pst_percent_t; refresh: boolean);
Procedure STlib_updateBinIcon(bi: Pst_binicon_t; refresh: boolean);
Procedure STlib_updateMultIcon(mi: Pst_multicon_t; refresh: boolean);

Implementation

Uses
  am_map
  , i_system, i_video
  , m_menu
  , st_stuff
  , v_video
  , w_wad
  , z_zone
  ;

Var
  sttminus: Ppatch_t;

Procedure STlib_initPercent(Out p: st_percent_t; x: int; y: int; pl: PPpatch_t;
  num: P_int; _on: Pboolean; percent: Ppatch_t);
Begin
  STlib_initNum(p.n, x, y, pl, num, _on, 3);
  p.p := percent;

  // [crispy] remember previous colorization
  p.oldtranslation := Nil;
End;

Procedure STlib_initMultIcon(Out i: st_multicon_t; x: int; y: int;
  il: PPpatch_t; inum: P_int; _on: Pboolean);
Begin
  i.x := x;
  i.y := y;
  i.oldinum := -1;
  i.inum := inum;
  i._on := _on;
  i.p := il;
End;

Procedure STlib_init();
Begin
  If (W_CheckNumForName('STTMINUS') >= 0) Then
    sttminus := W_CacheLumpName('STTMINUS', PU_STATIC)
  Else
    sttminus := Nil;
End;

//
// A fairly efficient way to draw a number
//  based on differences from the old number.
// Note: worth the trouble?
//

Procedure STlib_drawNum(n: Pst_number_t; refresh: boolean);
Var
  numdigits: int;
  num: int;
  w: int;
  h: int;
  x: int;
  neg: boolean;
Begin
  numdigits := n^.width;
  num := n^.num^;
  w := n^.p[0]^.width;
  h := n^.p[0]^.height;
  x := n^.x;

  // [crispy] redraw only if necessary
  If (n^.oldnum = num) And (Not refresh) Then exit;

  n^.oldnum := n^.num^;

  neg := num < 0;

  If (neg) Then Begin
    If (numdigits = 2) And (num < -9) Then
      num := -9
    Else If (numdigits = 3) And (num < -99) Then
      num := -99;
    num := -num;
  End;

  // clear the area
  x := n^.x - numdigits * w;

  If (n^.y - ST_Y < 0) Then
    I_Error('drawNum: n^.y - ST_Y < 0');

  If (screenblocks < CRISPY_HUD) Or ((automapactive) And (crispy.automapoverlay = 0)) Then
    V_CopyRect(x + WIDESCREENDELTA, n^.y - ST_Y, st_backing_screen, w * numdigits, h, x + WIDESCREENDELTA, n^.y);

  // if non-number, do not draw it
  If (num = 1994) Then exit;


  x := n^.x;

  // in the special case of 0, you draw 0
  If (num = 0) Then
    V_DrawPatch(x - w, n^.y, n^.p[0]);

  // draw the new number
  While (num <> 0) And (numdigits > 0) Do Begin
    numdigits := numdigits - 1;
    x := x - w;
    V_DrawPatch(x, n^.y, n^.p[num Mod 10]);
    num := num Div 10;
  End;

  // draw a minus sign if necessary
  If (neg) And assigned(sttminus) Then
    V_DrawPatch(x - 8, n^.y, sttminus);
End;

Procedure STlib_updatePercent(per: Pst_percent_t; refresh: Boolean);
Begin
  // [crispy] remember previous colorization
  If (per^.oldtranslation <> dp_translation) Then Begin

    refresh := true;
    per^.oldtranslation := dp_translation;
  End;

  STlib_updateNum(@per^.n, refresh); // [crispy] moved here

  If (crispy.coloredhud And COLOREDHUD_BAR) <> 0 Then
    dp_translation := cr[CR_GRAY];

  If (refresh) And (per^.n._on^) Then
    V_DrawPatch(per^.n.x, per^.n.y, per^.p);

  dp_translation := Nil;
End;

Procedure STlib_updateBinIcon(bi: Pst_binicon_t; refresh: boolean);
Var
  x: int;
  y: int;
  w: int;
  h: int;
Begin
  If (bi^._on^)
    And ((bi^.oldval <> bi^.val^) Or (refresh)) Then Begin
    x := bi^.x - bi^.p^.leftoffset;
    y := bi^.y - bi^.p^.topoffset;
    w := bi^.p^.width;
    h := bi^.p^.height;

    If (y - ST_Y < 0) Then
      I_Error('updateBinIcon: y - ST_Y < 0');

    If (bi^.val^) Then
      V_DrawPatch(bi^.x, bi^.y, bi^.p)
    Else If (screenblocks < CRISPY_HUD) Or ((automapactive) And (crispy.automapoverlay = 0)) Then
      V_CopyRect(x + WIDESCREENDELTA, y - ST_Y, st_backing_screen, w, h, x + WIDESCREENDELTA, y);

    bi^.oldval := bi^.val^;
  End;
End;

Procedure STlib_updateMultIcon(mi: Pst_multicon_t; refresh: boolean);
Var
  w: int;
  h: int;
  x: int;
  y: int;
Begin
  If (mi^._on^)
    And ((mi^.oldinum <> mi^.inum^) Or (refresh))
    And ((mi^.inum^ <> -1)) Then Begin

    If (mi^.oldinum <> -1) Then Begin
      x := mi^.x - mi^.p[mi^.oldinum]^.leftoffset;
      y := mi^.y - mi^.p[mi^.oldinum]^.topoffset;
      w := mi^.p[mi^.oldinum]^.width;
      h := mi^.p[mi^.oldinum]^.height;

      If (y - ST_Y < 0) Then
        I_Error('updateMultIcon: y - ST_Y < 0');

      If (screenblocks < CRISPY_HUD) Or ((automapactive) And (crispy.automapoverlay = 0)) Then Begin
        //V_CopyRect(x + WIDESCREENDELTA, y - ST_Y, st_backing_screen, w, h, x + WIDESCREENDELTA, y);
        // WTF: Hack für w_faces (Achtung 3 mal)
        V_CopyRect(x - 10 * WIDESCREENDELTA, y - ST_Y, st_backing_screen, w + 4 * WIDESCREENDELTA, h, x - 10 * WIDESCREENDELTA, y);
      End;
    End;
    V_DrawPatch(mi^.x, mi^.y, mi^.p[mi^.inum^]);
    mi^.oldinum := mi^.inum^;
  End;
End;

Procedure STlib_updateNum(n: Pst_number_t; refresh: boolean);
Begin
  If (n^._on^) Then STlib_drawNum(n, refresh);
End;

Procedure STlib_initNum(Out n: st_number_t;
  x: int;
  y: int;
  pl: pppatch_t;
  num: P_int;
  _on: Pboolean;
  width: int);
Begin
  n.x := x;
  n.y := y;
  n.oldnum := 0;
  n.width := width;
  n.num := num;
  n._on := _on;
  n.p := pl;
End;

Procedure STlib_initBinIcon
  (Out b: st_binicon_t;
  x: int;
  y: int;
  i: Ppatch_t;
  val: Pboolean;
  _on: Pboolean);
Begin
  b.x := x;
  b.y := y;
  b.oldval := false;
  b.val := val;
  b._on := _on;
  b.p := i;
End;

End.

