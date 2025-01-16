Unit p_tick;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure P_InitThinkers();

Implementation

Uses
  info_types
  ;

Var
  thinkercap: thinker_t;

Procedure P_InitThinkers();
Begin
  thinkercap.prev := @thinkercap;
  thinkercap.next := @thinkercap;
End;

End.

