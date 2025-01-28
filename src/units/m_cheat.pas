Unit m_cheat;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type
  cheatseq_t = Record
    // settings for this cheat
    sequence: String;
  //  sequence_len: int;  // -- Den Braucht man doch eigentlich gar nicht meh, oder ?
    parameter_chars: int;

    // state used during the game
    chars_read: int;
    param_chars_read: int;
    parameter_buf: String;
  End;

Function cht_CheckCheat(Const cht: cheatseq_t; key: char): int;

Implementation

//
// Called in st_stuff module, which handles the input.
// Returns a 1 if the cheat was successful, 0 if failed.
//

Function cht_CheckCheat(Const cht: cheatseq_t; key: char): int;
Begin
  // if we make a short sequence on a cheat with parameters, this
  // will not work in vanilla doom.  behave the same.

//    if (cht->parameter_chars > 0 && strlen(cht->sequence) < cht->sequence_len)
//        return false;
//
//    if (cht->chars_read < strlen(cht->sequence))
//    {
//        // still reading characters from the cheat code
//        // and verifying.  reset back to the beginning
//        // if a key is wrong
//
//        if (key == cht->sequence[cht->chars_read])
//            ++cht->chars_read;
//        else
//            cht->chars_read = 0;
//
//        cht->param_chars_read = 0;
//    }
//    else if (cht->param_chars_read < cht->parameter_chars)
//    {
//        // we have passed the end of the cheat sequence and are
//        // entering parameters now
//
//        cht->parameter_buf[cht->param_chars_read] = key;
//
//        ++cht->param_chars_read;
//    }
//
//    if (cht->chars_read >= strlen(cht->sequence)
//     && cht->param_chars_read >= cht->parameter_chars)
//    {
//        cht->chars_read = cht->param_chars_read = 0;
//
//        return true;
//    }

   // cheat not matched yet
  result := 0;
End;

End.

