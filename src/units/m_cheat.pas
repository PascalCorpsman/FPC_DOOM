Unit m_cheat;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type
  cheatseq_t = Record
    // settings for this cheat
    sequence: String;
    parameter_chars: int;

    // state used during the game
    chars_read: int;
    param_chars_read: int;
    parameter_buf: String;
  End;

Function cht_CheckCheat(Var cht: cheatseq_t; key: char): int;
Procedure cht_GetParam(Var cht: cheatseq_t; Out buffer: String);

Implementation

//
// Called in st_stuff module, which handles the input.
// Returns a 1 if the cheat was successful, 0 if failed.
//

Function cht_CheckCheat(Var cht: cheatseq_t; key: char): int;
Begin
  key := lowercase(key); // Alle Cheats sind immer in kleinbuchstaben geschrieben !
  // cheat not matched yet
  result := 0;

  If (cht.chars_read < length(cht.sequence)) Then Begin
    // still reading characters from the cheat code
    // and verifying.  reset back to the beginning
    // if a key is wrong

    If (key = cht.sequence[cht.chars_read + 1]) Then
      cht.chars_read := cht.chars_read + 1
    Else
      cht.chars_read := 0;

    cht.param_chars_read := 0;
    cht.parameter_buf := '';
  End
  Else If (cht.param_chars_read < cht.parameter_chars) Then Begin
    // we have passed the end of the cheat sequence and are
    // entering parameters now
    cht.parameter_buf := cht.parameter_buf + key;
    cht.param_chars_read := cht.param_chars_read + 1;
  End;

  If (cht.chars_read >= length(cht.sequence))
    And (cht.param_chars_read >= cht.parameter_chars) Then Begin
    cht.chars_read := 0;
    cht.param_chars_read := 0;
    result := 1;
  End;

End;

Procedure cht_GetParam(Var cht: cheatseq_t; Out buffer: String);
Begin
  buffer := cht.parameter_buf;
End;

End.

