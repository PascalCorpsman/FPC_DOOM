Unit m_bbox;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , m_fixed
  ;

// Bounding box coordinate storage.
Const
  BOXTOP = 0;
  BOXBOTTOM = 1;
  BOXLEFT = 2;
  BOXRIGHT = 3;
  // bbox coordinates

  // Bounding box functions.
Procedure M_ClearBox(Out box: Array Of fixed_t);

Procedure M_AddToBox(Var box: Array Of fixed_t; x, y: fixed_t);

Implementation

Procedure M_ClearBox(Out box: Array Of fixed_t);
Begin
  box[BOXTOP] := INT_MIN;
  box[BOXRIGHT] := INT_MIN;
  box[BOXBOTTOM] := INT_MAX;
  box[BOXLEFT] := INT_MAX;
End;

Procedure M_AddToBox(Var box: Array Of fixed_t; x, y: fixed_t);
Begin
  If (x < box[BOXLEFT]) Then box[BOXLEFT] := x;
  If (x > box[BOXRIGHT]) Then box[BOXRIGHT] := x;
  If (y < box[BOXBOTTOM]) Then box[BOXBOTTOM] := y;
  If (y > box[BOXTOP]) Then box[BOXTOP] := y;
End;

End.

