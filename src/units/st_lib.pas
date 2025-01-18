Unit st_lib;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  info_types
  , v_patch
  ;

Type

  // Number widget

  st_number_t = Record

    // upper right-hand corner
    //  of the number (right-justified)
    x: int;
    y: int;

    // max # of digits in number
    width: int;

    // last number value
    oldnum: int;

    // pointer to current value
    num: P_int;

    // pointer to boolean stating
    //  whether to update number
    _on: Pboolean;

    // list of patches for 0-9
    p: ppatch_t;

    // user data
    data: int;
  End;

Procedure STlib_initNum(Out n: st_number_t;
  x: int;
  y: int;
  pl: ppatch_t;
  num: P_int;
  _on: Pboolean;
  width: int);

Procedure STlib_init();

Implementation

Uses
  w_wad
  , z_zone
  ;

Var
  sttminus: Ppatch_t;

Procedure STlib_init();
Begin
  If (W_CheckNumForName('STTMINUS') >= 0) Then
    sttminus := W_CacheLumpName('STTMINUS', PU_STATIC)
  Else
    sttminus := Nil;
End;

Procedure STlib_initNum(Out n: st_number_t;
  x: int;
  y: int;
  pl: ppatch_t;
  num: P_int;
  _on: Pboolean;
  width: int);
Begin
  n.x := x;
  n.y := y;
  n.oldnum := 0;
  n.width := width;
  n.num := num;
  n._on := _on;
  n.p := pl;
End;

End.

