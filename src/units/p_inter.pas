Unit p_inter;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef
  ;

Const
  // a weapon is found with two clip loads,
  // a big item has five clip loads
  maxammo: Array[0..integer(NUMAMMO) - 1] Of int = (200, 50, 300, 50);
  clipammo: Array[0..integer(NUMAMMO) - 1] Of int = (10, 4, 20, 1);

Implementation

End.

