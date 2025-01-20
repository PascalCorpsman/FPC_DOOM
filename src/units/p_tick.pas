Unit p_tick;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  info_types
  ;

Var
  thinkercap: thinker_t;

Procedure P_InitThinkers();

Procedure P_AddThinker(thinker: Pthinker_t);

Implementation

Procedure P_InitThinkers();
Begin
  thinkercap.prev := @thinkercap;
  thinkercap.next := @thinkercap;
End;

//
// P_AddThinker
// Adds a new thinker at the end of the list.
//

Procedure P_AddThinker(thinker: Pthinker_t);
Begin
  thinkercap.prev^.next := thinker;
  thinker^.next := @thinkercap;
  thinker^.prev := thinkercap.prev;
  thinkercap.prev := thinker;
End;

End.

