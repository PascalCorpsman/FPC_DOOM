Unit i_timer;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Const
  TICRATE = 35;


  // Called by D_DoomLoop,
  // returns current time in tics.
Function I_GetTime(): int;

// returns current time in ms
Function I_GetTimeMS(): int;

// returns current time in us
//Function I_GetTimeUS(): uint64_t; // [crispy]

// Pause for a specified number of ms
Procedure I_Sleep(ms: int);

// Initialize timer
Procedure I_InitTimer();

// Wait for vertical retrace or pause a bit.
Procedure I_WaitVBL(count: int);

// [crispy]
//Function I_GetFracRealTime(): fixed_t;


Implementation

Var
  basetime: QWord = 0;
  //  basecounter: uint64_t = 0; // [crispy]
  //  basefreq: uint64_t = 0; // [crispy]

Function I_GetTime(): int;
Var
  ticks: QWord;
Begin
  ticks := GetTickCount64();
  If basetime = 0 Then Begin
    basetime := ticks;
  End;
  ticks := ticks - basetime;
  result := (ticks * TICRATE) Div 1000;
End;

Function I_GetTimeMS(): int;
Var
  ticks: QWord;
Begin
  ticks := GetTickCount64();
  If basetime = 0 Then Begin
    basetime := ticks;
  End;
  result := ticks - basetime;
End;

Procedure I_Sleep(ms: int);
Begin
  Sleep(ms);
  Raise exception.create('I_Sleep was called!');
End;

Procedure I_InitTimer();
Begin
  // Nichts zu tun
End;

Procedure I_WaitVBL(count: int);
Begin
  I_Sleep((count * 1000) Div 70);
End;

End.

