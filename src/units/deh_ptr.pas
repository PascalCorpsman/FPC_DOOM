Unit deh_ptr;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , deh_thing, info_types
  ;
// [BH] extra dehacked states
Const
  EXTRASTATES = 1089;
  NUMSTATES = 4000;

Var
  deh_section_pointer: deh_section_t;
  codeptrs: Array[0..NUMSTATES - 1] Of actionf_t; // [crispy] share with deh_bexptr.c

Implementation

Uses
  info
  ;

Procedure DEH_PointerInit();
Var
  i: int;
Begin
  // Initialize list of dehacked pointers
  For i := 0 To EXTRASTATES - 1 Do Begin
    codeptrs[i] := states[i].action;
  End;

  // [BH] Initialize extra dehacked states
  For i := EXTRASTATES To NUMSTATES - 1 Do Begin
    states[i].sprite := SPR_TNT1;
    states[i].frame := 0;
    states[i].tics := -1;
    states[i].action.acv := Nil;
    states[i].nextstate := statenum_t(i);
    states[i].misc1 := 0;
    states[i].misc2 := 0;
    //	states[i].dehacked = false;
    codeptrs[i] := states[i].action;
  End;
End;


Initialization

  deh_section_pointer.name := 'Pointer';
  deh_section_pointer.init := @DEH_PointerInit; // [crispy] initialize Thing extra properties
  //  deh_section_pointer.start := @DEH_PointerStart;
  //  deh_section_pointer.line_parser := @DEH_PointerParseLine;
  //  deh_section_pointer._end := Nil;
  //  deh_section_pointer.sha1_hash := @DEH_PointerSHA1Sum,

End.

