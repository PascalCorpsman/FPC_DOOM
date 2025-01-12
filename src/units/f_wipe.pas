Unit f_wipe;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomtype
  ;

Function wipe_StartScreen(x, y, width, height: int): int;

Function wipe_EndScreen(x, y, width, height: int): int;

Function wipe_ScreenWipe(wipeno, x, y, width, height, ticks: int): int;

Implementation

Uses
  i_video
  , v_video
  ;

Var
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
  V_DrawBlock(x, y, width, height, wipe_scr_start); // restore start scr.
  result := 0;
End;

Function wipe_ScreenWipe(wipeno, x, y, width, height, ticks: int): int;
Begin

End;

End.

