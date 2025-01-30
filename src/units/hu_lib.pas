Unit hu_lib;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , v_patch
  ;


Const
  HU_MAXLINES = 4;
  HU_MAXLINELENGTH = 80;

Type

  // Text Line widget
  //  (parent of Scrolling Text and Input Text widgets)
  hu_textline_t = Record
    // left-justified position of scrolling text window
    x: int;
    y: int;

    f: PPPatch_t; // font
    sc: int; // start character
    l: String; // line of text
    len: int; // current line length

    // whether this line needs to be udpated
    needsupdate: int;
  End;
  phu_textline_t = ^hu_textline_t;

  // Scrolling Text window widget
  //  (child of Text Line widget)
  hu_stext_t = Record

    l: Array[0..HU_MAXLINES - 1] Of hu_textline_t; // text lines to draw
    h: int; // height in lines
    cl: int; // current line number

    // pointer to boolean stating whether to update window
    _on: PBoolean;
    laston: boolean; // last value of *->on.
  End;
  Phu_stext_t = ^hu_stext_t;

Procedure HUlib_addMessageToSText(s: Phu_stext_t; prefix, msg: String);
Function HUlib_addCharToTextLine(t: Phu_textline_t; ch: char): boolean;

Procedure HUlib_initSText(s: Phu_stext_t; x, y, h: int; font: PPpatch_t; startchar: int; _on: Pboolean);
Procedure HUlib_initTextLine(t: Phu_textline_t; x, y: int; f: PPpatch_t; sc: int);

Procedure HUlib_eraseSText(s: Phu_stext_t);
Procedure HUlib_eraseTextLine(l: Phu_textline_t);
Procedure HUlib_drawSText(s: Phu_stext_t);
Procedure HUlib_drawTextLine(l: Phu_textline_t; drawcursor: boolean);

Implementation

Uses
  i_video
  , v_trans, v_video
  ;

Procedure HUlib_clearTextLine(t: phu_textline_t);
Begin
  t^.len := 0;
  t^.l := '';
  t^.needsupdate := 1;
End;

Procedure HUlib_addLineToSText(s: Phu_stext_t);
Var
  i: int;
Begin

  // add a clear line
  If s^.cl + 1 = s^.h Then
    s^.cl := 0
  Else
    s^.cl := s^.cl + 1;
  HUlib_clearTextLine(@s^.l[s^.cl]);

  // everything needs updating
  For i := 0 To s^.h - 1 Do Begin
    s^.l[i].needsupdate := 4;
  End;
End;

Function HUlib_addCharToTextLine(t: Phu_textline_t; ch: char): boolean;
Begin
  If (t^.len = HU_MAXLINELENGTH) Then Begin
    result := false;
  End
  Else Begin
    t^.l := t^.l + ch;
    t^.len := length(t^.l);
    t^.needsupdate := 4;
    result := true;
  End;
End;

Procedure HUlib_addMessageToSText(s: Phu_stext_t; prefix, msg: String);
Var
  i: Integer;
Begin
  HUlib_addLineToSText(s);
  If (prefix <> '') Then Begin
    For i := 1 To length(prefix) Do Begin
      HUlib_addCharToTextLine(@s^.l[s^.cl], prefix[i]);
    End;
  End;
  For i := 1 To length(msg) Do Begin
    HUlib_addCharToTextLine(@s^.l[s^.cl], msg[i]);
  End;
End;

Procedure HUlib_initTextLine(t: Phu_textline_t; x, y: int; f: PPpatch_t; sc: int
  );
Begin
  t^.x := x;
  t^.y := y;
  t^.f := f;
  t^.sc := sc;
  HUlib_clearTextLine(t);
End;

Procedure HUlib_initSText(s: Phu_stext_t; x, y, h: int; font: PPpatch_t;
  startchar: int; _on: Pboolean);
Var
  i: int;
Begin
  s^.h := h;
  s^._on := _on;
  s^.laston := true;
  s^.cl := 0;
  For i := 0 To h - 1 Do Begin
    HUlib_initTextLine(@s^.l[i],
      x, y - i * ((font[0]^.height) + 1),
      font, startchar);
  End;
End;

// sorta called by HU_Erase and just better darn get things straight

Procedure HUlib_eraseTextLine(l: Phu_textline_t);
Var
  lh, y, yoffset: int;
Begin

  // Only erases when NOT in automap and the screen is reduced,
  // and the text must either need updating or refreshing
  // (because of a recent change back from the automap)

//    if (!automapactive &&
//	viewwindowx && (l->needsupdate || crispy->cleanscreenshot || crispy->screenshotmsg == 4))
//    {
//	lh = (SHORT(l->f[0]->height) + 1) << crispy->hires;
//	// [crispy] support line breaks
//	yoffset = 1;
//	for (y = 0; y < l->len; y++)
//	{
//	    if (l->l[y] == '\n')
//	    {
//		yoffset++;
//	    }
//	}
//	lh *= yoffset;
//	for (y=(l->y << crispy->hires),yoffset=y*SCREENWIDTH ; y<(l->y << crispy->hires)+lh ; y++,yoffset+=SCREENWIDTH)
//	{
//	    if (y < viewwindowy || y >= viewwindowy + viewheight)
//		R_VideoErase(yoffset, SCREENWIDTH); // erase entire line
//	    else
//	    {
//		R_VideoErase(yoffset, viewwindowx); // erase left border
//		R_VideoErase(yoffset + viewwindowx + scaledviewwidth, viewwindowx);
//		// erase right border
//	    }
//	}
//    }

  If (l^.needsupdate <> 0) Then l^.needsupdate := l^.needsupdate - 1;
End;

Procedure HUlib_eraseSText(s: Phu_stext_t);
Var
  i: int;
Begin
  For i := 0 To s^.h - 1 Do Begin
    If (s^.laston) And (Not s^._on^) Then
      s^.l[i].needsupdate := 4;
    HUlib_eraseTextLine(@s^.l[i]);
  End;
  s^.laston := s^._on^;
End;

Procedure HUlib_drawTextLine(l: Phu_textline_t; drawcursor: boolean);
Var
  i, w, x, y: int;
  c: char;
Begin
  // draw the new stuff
  x := l^.x;
  y := l^.y; // [crispy] support line breaks
  i := 0;
  While i < l^.len Do Begin
    c := uppercase(l^.l[i + 1])[1];
    // [crispy] support multi-colored text lines
    If (c = cr_esc) Then Begin
      If (l^.l[i + 2] >= '0') And (ord(l^.l[i + 2]) <= ord('0') + CRMAX - 1) Then Begin
        i := i + 1;
        If (crispy.coloredhud And COLOREDHUD_TEXT) <> 0 Then Begin
          dp_translation := cr[ord(l^.l[i + 1]) - ord('0')];
        End
        Else Begin
          dp_translation := Nil;
        End;
      End;
    End
      // [crispy] support line breaks
    Else If (c = #13) Then Begin // '\n'
      x := l^.x;
      y := y + l^.f[0]^.height + 1;
    End
      // [crispy] support tab stops
    Else If (c = #9) Then Begin // '\t'
      x := x - (x - l^.x) Mod 12 + 12;
      If (x >= ORIGWIDTH + WIDESCREENDELTA) Then
        break;
    End
    Else If (c <> ' ')
      And (ord(c) >= l^.sc)
      And (c <= '_') Then Begin
      w := (l^.f[ord(c) - l^.sc]^.width);
      If (x + w > ORIGWIDTH + WIDESCREENDELTA) Then
        break;
      V_DrawPatchDirect(x, y, l^.f[ord(c) - l^.sc]);
      x := x + w;
    End
    Else Begin
      x := x + 4;
      If (x >= ORIGWIDTH + WIDESCREENDELTA) Then
        break;
    End;
    inc(i);
  End;

  // draw the cursor if requested
  If (drawcursor)
    And (x + SHORT(l^.f[ord('_') - l^.sc]^.width) <= ORIGWIDTH + WIDESCREENDELTA) Then Begin
    V_DrawPatchDirect(x, y, l^.f[ord('_') - l^.sc]);
  End;
  dp_translation := Nil;
End;

Procedure HUlib_drawSText(s: Phu_stext_t);
Var
  i, idx: int;
  l: Phu_textline_t;
Begin
  If (Not s^._on^) Then exit; // if not on, don't draw

  // draw everything

  For i := 0 To s^.h - 1 Do Begin

    idx := s^.cl - i;
    If (idx < 0) Then
      idx := idx + s^.h; // handle queue of lines

    l := @s^.l[idx];

    // need a decision made here on whether to skip the draw
    HUlib_drawTextLine(l, false); // no cursor, please
  End;
End;

End.

