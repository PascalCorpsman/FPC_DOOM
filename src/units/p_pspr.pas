Unit p_pspr;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Procedure A_Light0(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);

Implementation

Procedure A_Light0(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  player^.extralight := 0;
End;



End.

