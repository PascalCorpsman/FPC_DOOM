Unit i_system;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure I_PrintStartupBanner(gamedescription: String);
Procedure I_PrintBanner(msg: String);
Procedure I_Error(Error: String);
Procedure I_Quit(); // Wenn Aufgerufen beendet sich die Anwending ohne weiteres Nachfragen
Procedure I_GetMemoryValue(offset: unsigned_int; value: pointer; size: int);


Procedure I_Tactile(_on: int; off: int; total: int);

Implementation

Uses config, Forms, bass
  , s_sound
  ;

Procedure I_Error(Error: String);
Begin
  Raise Exception.Create(error);
  halt;
End;

Procedure I_Quit();
Begin
  // D_QuitNetGame;
  // I_ShutdownGamepad;
  // I_ShutdownGraphics;
  // CloseLog;
  S_Shutdown();
  // D_Endoom;
  // M_SaveDefaults;
  // G_CheckDemoStatusAtExit;
  Application.Terminate;
End;

Procedure I_GetMemoryValue(offset: unsigned_int; value: pointer; size: int);
Begin
  Raise Exception.create('I_GetMemoryValue');
End;

// Tactile feedback function, probably used for the Logitech Cyberman

Procedure I_Tactile(_on: int; off: int; total: int);
Begin
  // not implemented in Crispy DOOM
End;

Procedure I_PrintDivider();
Var
  i: Integer;
Begin
  For i := 0 To 75 - 1 Do Begin
    write('=');
  End;
  WriteLn('');
End;

Procedure I_PrintBanner(msg: String);
Var
  spaces, i: Integer;
Begin

  spaces := 35 - (length(msg) Div 2);

  For i := 0 To spaces - 1 Do Begin
    write(' ');
  End;

  WriteLn(msg);
End;

Procedure I_PrintStartupBanner(gamedescription: String);
Begin
  I_PrintDivider();
  I_PrintBanner(gamedescription);
  I_PrintDivider();
  writeln(
    ' ' + PACKAGE_NAME + ' is free software, covered by the GNU General Public' + LineEnding +
    ' License.  There is NO warranty; not even for MERCHANTABILITY or FITNESS' + LineEnding +
    ' FOR A PARTICULAR PURPOSE. You are welcome to change and distribute' + LineEnding +
    ' copies under certain conditions. See the source for more information.');
  I_PrintDivider();
End;

End.

