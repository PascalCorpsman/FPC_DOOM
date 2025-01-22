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
  Pfixed_t = ^fixed_t;

Function FixedMul(a, b: fixed_t): fixed_t;
Function FixedDiv(a, b: fixed_t): fixed_t;

Function FIXED2DOUBLE(x: int): fixed_t;

Implementation

Uses math;

Function FixedMul(a, b: fixed_t): fixed_t;
Var
  t: int64;
Begin
  t := int64_t(a) * int64_t(b);
  result := fixed_t(SarInt64(t, FRACBITS)); // das ist ein Vorzeichen korrektes shr
End;

Function FixedDiv(a, b: fixed_t): fixed_t;
Var
  res: Int64;
Begin
  If ((SarLongint(abs(a), 14)) >= abs(b)) Then Begin // Hier ist das Vorzeichen egal deswegen braucht es kein SarLongint
    result := IfThen((a Xor b) < 0, INT_MIN, INT_MAX);
  End
  Else Begin
    res := (int64(a) Shl FRACBITS) Div b;
    result := fixed_t(res);
  End;
End;

Function FIXED2DOUBLE(x: int): fixed_t;
Begin
  result := (x Div FRACUNIT);
End;

End.

