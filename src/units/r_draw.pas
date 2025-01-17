Unit r_draw;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Var
  translationtables: Array Of byte;

Procedure R_InitTranslationTables();

Implementation


//
// R_InitTranslationTables
// Creates the translation tables to map
//  the green color ramp to gray, brown, red.
// Assumes a given structure of the PLAYPAL.
// Could be read from a lump instead.
//

Procedure R_InitTranslationTables();
Var
  i: int;
Begin
  setlength(translationtables, 256 * 3);
  // translate just the 16 green colors
  For i := 0 To 255 Do Begin
    If (i >= $70) And (i <= $7F) Then Begin
      // map green ramp to gray, brown, red
      translationtables[i] := $60 + (i And $F);
      translationtables[i + 256] := $40 + (i And $F);
      translationtables[i + 512] := $20 + (i And $F);
    End
    Else Begin
      // Keep all other colors as is.
      translationtables[i] := i;
      translationtables[i + 256] := i;
      translationtables[i + 512] := i;
    End;
  End;
End;

End.

