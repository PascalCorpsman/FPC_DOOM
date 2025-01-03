Unit m_fixed;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

//
// Fixed point, 32bit as 16.16.
//
Const
  FRACBITS = 16;
  FRACUNIT = (1 Shl FRACBITS);

Type
  fixed_t = int;

Function FixedMul(a, b: fixed_t): fixed_t;
Function FixedDiv(a, b: fixed_t): fixed_t;

Function FIXED2DOUBLE(x: int): Double;

Implementation

Uses math;

Function FixedMul(a, b: fixed_t): fixed_t;
Begin
  result := (int64_t(a) * int64_t(b)) Shr FRACBITS;
End;

Function FixedDiv(a, b: fixed_t): fixed_t;
Var
  res: Int64;
Begin
  If ((abs(a) Shr 14) >= abs(b)) Then Begin
    result := IfThen((a Xor b) < 0, INT_MIN, INT_MAX);
  End
  Else Begin
    res := (int64_t(a) Shr FRACBITS) Div b;
    result := fixed_t(res);
  End;
End;

Function FIXED2DOUBLE(x: int): Double;
Begin
  result := (x / FRACUNIT);
End;

End.

