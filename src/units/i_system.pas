Unit i_system;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Procedure I_PrintStartupBanner(gamedescription: String);
Procedure I_PrintBanner(msg: String);
Procedure I_Error(Error: String);

Implementation

Uses config;

Procedure I_Error(Error: String);
Begin
  Raise Exception.Create(error);
  halt;
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

