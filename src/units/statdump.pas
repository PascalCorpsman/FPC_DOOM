Unit statdump;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_player
  ;

Procedure StatCopy(stats: Pwbstartstruct_t);

Implementation

Uses
  m_argv
  ;

Const
  MAX_CAPTURES = 32;

Var
  num_captured_stats: int = 0;
  captured_stats: Array[0..MAX_CAPTURES - 1] Of wbstartstruct_t;

Procedure StatCopy(stats: Pwbstartstruct_t);
Begin
  If (M_ParmExists('-statdump') And (num_captured_stats < MAX_CAPTURES)) Then Begin
    Raise exception.create('Port me.');
    //        memcpy(&captured_stats[num_captured_stats], stats,
    //               sizeof(wbstartstruct_t));
    //        ++num_captured_stats;
  End;
End;

End.

