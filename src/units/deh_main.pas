Unit deh_main;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , deh_doom;

Procedure DEH_Init();

// If false, dehacked cheat replacements are ignored.

Var
  deh_initialized: boolean = false;
  deh_apply_cheats: boolean = true;

Implementation

Uses
  m_argv
  ;

Procedure InitializeSections();
Var
  i: integer;
Begin
  For i := 0 To high(deh_section_types) Do Begin
    If (deh_section_types[i]^.init <> Nil) Then Begin
      deh_section_types[i]^.init();
    End;
  End;
End;

Procedure DEH_Init(); // [crispy] un-static
Begin
  //!
  // @category mod
  //
  // Ignore cheats in dehacked files.
  //

  If (M_CheckParm('-nocheats') > 0) Then Begin
    deh_apply_cheats := false;
  End;

  // Call init functions for all the section definitions.
  InitializeSections();

  deh_initialized := true;
End;

End.

