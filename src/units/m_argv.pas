Unit m_argv;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Var

  myargc: int;
  myargv: Array Of String;
  exedir: String;

Procedure M_SetExeDir();

// Returns the position of the given parameter
// in the arg list (0 if not found).
Function M_CheckParm(Const check: String): int;

// Same as M_CheckParm, but checks that num_args arguments are available
// following the specified argument.
Function M_CheckParmWithArgs(check: String; num_args: integer): int;

Procedure M_FindResponseFile();

// Parameter has been specified?

Function M_ParmExists(Const check: String): Boolean;

Function M_GetExecutableName(): String;

Implementation

Procedure M_SetExeDir();
Begin
  exedir := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
End;

Function M_CheckParm(Const check: String): int;
Begin
  result := M_CheckParmWithArgs(check, 0);
End;

//
// M_CheckParm
// Checks for the given parameter
// in the program's command line arguments.
// Returns the argument number (1 to argc-1)
// or 0 if not present
//

Function M_CheckParmWithArgs(check: String; num_args: integer): int;
Var
  i: Integer;
Begin
  result := 0;
  For i := 1 To ParamCount - num_args Do Begin
    If check = ParamStr(i) Then result := i;
  End
End;

Procedure M_FindResponseFile();
Begin
  //    int i;
  //
  //    for (i = 1; i < myargc; i++)
  //    {
  //        if (myargv[i][0] == '@')
  //        {
  //            LoadResponseFile(i, myargv[i] + 1);
  //        }
  //    }
  //
  //    for (;;)
  //    {
  //        //!
  //        // @arg <filename>
  //        //
  //        // Load extra command line arguments from the given response file.
  //        // Arguments read from the file will be inserted into the command
  //        // line replacing this argument. A response file can also be loaded
  //        // using the abbreviated syntax '@filename.rsp'.
  //        //
  //        i = M_CheckParmWithArgs("-response", 1);
  //        if (i <= 0)
  //        {
  //            break;
  //        }
  //        // Replace the -response argument so that the next time through
  //        // the loop we'll ignore it. Since some parameters stop reading when
  //        // an argument beginning with a '-' is encountered, we keep something
  //        // that starts with a '-'.
  //        free(myargv[i]);
  //        myargv[i] = M_StringDuplicate("-_");
  //        LoadResponseFile(i + 1, myargv[i + 1]);
  //    }
End;

//
// M_ParmExists
//
// Returns true if the given parameter exists in the program's command
// line arguments, false if not.
//

Function M_ParmExists(Const check: String): Boolean;
Begin
  result := M_CheckParm(check) <> 0;
End;

Function M_GetExecutableName(): String;
Begin
  result := ExtractFileName(ParamStr(0));
End;

End.

