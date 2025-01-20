Unit f_wipe;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomtype
  ;

Const
  wipe_ColorXForm = 0; // simple gradual pixel change for 8-bit only
  wipe_Melt = 1; // weird screen melt

Function wipe_StartScreen(x, y, width, height: int): int;

Function wipe_EndScreen(x, y, width, height: int): int;

Function wipe_ScreenWipe(wipeno, x, y, width, height, ticks: int): Boolean;

Implementation

Uses
  math
  , i_video
  , m_random
  , v_video
  ;

Type
  TWipeFunction = Function(width, height, ticks: int): int;

Var
  // when zero, stop the wipe
  go: boolean = false;
  wipe_scr_start: Array Of pixel_t = Nil;
  wipe_scr_end: Array Of pixel_t = Nil;
  wipe_scr: Array Of pixel_t = Nil;

Function wipe_StartScreen(x, y, width, height: int): int;
Begin
  If length(wipe_scr_start) <> ORIGWIDTH * ORIGHEIGHT Then Begin
    setlength(wipe_scr_start, ORIGWIDTH * ORIGHEIGHT);
  End;
  I_ReadScreen(wipe_scr_start);
  result := 0;
End;

Function wipe_EndScreen(x, y, width, height: int): int;
Begin
  If length(wipe_scr_end) <> ORIGWIDTH * ORIGHEIGHT Then Begin
    setlength(wipe_scr_end, ORIGWIDTH * ORIGHEIGHT);
  End;
  I_ReadScreen(wipe_scr_end);
  // FillChar(wipe_scr_end[0], length(wipe_scr_end), 0); // DEBUG: to be removed makes the Wipe target screen black
  V_DrawBlock(x, y, width, height, wipe_scr_start); // restore start scr.
  result := 0;
End;

Function wipe_initColorXForm(width, height, ticks: int): int;
Begin
  Raise exception.create('wipe: wipe_ColorXForm, nicht portiert.');
  move(wipe_scr_start[0], wipe_scr[0], width * height * sizeof(pixel_t));
  result := 0;
End;

Function wipe_doColorXForm(width, height, ticks: int): int;
Begin
  //   boolean	changed;
  //    pixel_t*	w;
  //    pixel_t*	e;
  //    int		newval;
  //
  //    changed = false;
  //    w = wipe_scr;
  //    e = wipe_scr_end;
  //
  //    while (w!=wipe_scr+width*height)
  //    {
  //	if (*w != *e)
  //	{
  //	    if (*w > *e)
  //	    {
  //		newval = *w - ticks;
  //		if (newval < *e)
  //		    *w = *e;
  //		else
  //		    *w = newval;
  //		changed = true;
  //	    }
  //	    else if (*w < *e)
  //	    {
  //		newval = *w + ticks;
  //		if (newval > *e)
  //		    *w = *e;
  //		else
  //		    *w = newval;
  //		changed = true;
  //	    }
  //	}
  //	w++;
  //	e++;
  //    }
  //
  //    return !changed;
End;

Function wipe_exitColorXForm(width, height, ticks: int): int;
Begin
  result := 0;
End;

Var
  y: Array Of int;

Function wipe_initMelt(width, height, ticks: int): int;
Var
  i, r: int;
Begin
  // copy start screen to main screen
  move(wipe_scr_start[0], wipe_scr[0], width * height * sizeof(pixel_t));
  // setup initial column positions
  // (y<0 => not ready to scroll yet)
  setlength(y, width);
  y[0] := -(M_Random.M_Random() Mod 16);
  For i := 1 To width - 1 Do Begin
    r := (M_Random.M_Random() Mod 3) - 1;
    y[i] := y[i - 1] + r;
    If (y[i] > 0) Then
      y[i] := 0
    Else If (y[i] = -16) Then
      y[i] := -15;
  End;
  result := 0;
End;

Function wipe_doMelt(width, height, ticks: int): int;
Var
  i, j, dy: int;
  done: Boolean;
Begin
  done := true;
  While (ticks <> 0) Do Begin // TODO: Wenn Ticks > 1, dann wird der Puffer unnötig oft hin und her kopiert, das könnte man "optimieren"
    (*
     * Der Originalcode konnte nicht sauber übersetzt werden, aber seine Funktionsweise verstanden
     * 1. wipe_initMelt belegt jede Spalte zufällig vor
     * 2. In wipe_doMelt werden die Spalten verschoben sobald ihre Timer >= 0 werden
     * 3. Das Verschieben ist zu anfangs "Langsam" und wird bis 16 pixel differenz immer schneller, dann bleibt es auf 16
     *)
    For i := 0 To width - 1 Do Begin
      If (y[i] < 0) Then Begin
        y[i] := y[i] + 1;
        done := false;
      End
      Else Begin
        If (y[i] < height) Then Begin
          If (y[i] < 16) Then Begin
            dy := y[i] + 1;
          End
          Else Begin
            dy := 16;
          End;
          y[i] := min(height, y[i] + dy);
          done := false;
        End;
      End;
      // Flickerfreies umkopieren der beiden Wipe Screens in den Framebuffer
      For j := 0 To height - 1 Do Begin
        If y[i] > j Then Begin
          wipe_scr[j * width + i] := wipe_scr_end[j * width + i];
        End
        Else Begin
          If y[i] <= 0 Then Begin
            wipe_scr[j * width + i] := wipe_scr_start[j * width + i];
          End
          Else Begin
            wipe_scr[j * width + i] := wipe_scr_start[(j - y[i]) * width + i];
          End;
        End;
      End;
    End;
    dec(ticks);
  End;
  result := ord(done);
End;

Function wipe_exitMelt(width, height, ticks: int): int;
Begin
  setlength(y, 0);
  setlength(wipe_scr_start, 0);
  setlength(wipe_scr_end, 0);
  result := 0;
End;

Function wipe_ScreenWipe(wipeno, x, y, width, height, ticks: int): boolean;
Const
  wipes: Array Of TWipeFunction = (
    @wipe_initColorXForm, @wipe_doColorXForm, @wipe_exitColorXForm,
    @wipe_initMelt, @wipe_doMelt, @wipe_exitMelt
    );
Var
  rc: int;
Begin
  // initial stuff
  If (Not go) Then Begin

    go := true;
    // wipe_scr = (pixel_t *) Z_Malloc(width*height, PU_STATIC, 0); // DEBUG
    wipe_scr := I_VideoBuffer;
    wipes[wipeno * 3](width, height, ticks); // ruft wipe_initColorXForm oder wipe_initMelt auf
  End;

  // do a piece of wipe-in
  V_MarkRect(0, 0, width, height);
  rc := wipes[wipeno * 3 + 1](width, height, ticks); // ruft wipe_doColorXForm oder wipe_doMelt auf
  //  V_DrawBlock(0, 0, width, height, wipe_scr); // DEBUG

  // final stuff
  If (rc <> 0) Then Begin
    go := false;
    wipes[wipeno * 3 + 2](width, height, ticks); // ruft wipe_exitColorXForm oder wipe_exitMelt auf
  End;

  result := Not go;
End;

End.

