Unit ufpc_doom_types;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Const
  INT_MIN = -2147483648; // = low(int); ?
  INT_MAX = 2147483647; // = high(int); ?

Type

  signed_char = Int8;

  uint8_t = UInt8;
  uint16_t = UInt16;
  uint64_t = UInt64;
  size_t = UInt64;
  short = Int16;
  unsigned_short = uInt16;

  int = int32;
  int32_t = Int32;
  uint32_t = UInt32;
  unsigned = UInt32; // Geraten, den dass steht nirgends, könnte auch PTR_int sein ??
  P_int = ^int;
  unsigned_int = uint32;
  P_unsigned_int = ^unsigned_int;
  int64_t = Int64;
  float = single;

Procedure Nop(); // Just for debugging to have a breakpoint position ;)

Function IfThen(aValue: Boolean; aTrueString: String; aFalseString: String): String;

Implementation

Procedure Nop();
Begin

End;

Function IfThen(aValue: Boolean; aTrueString: String; aFalseString: String
  ): String;
Begin
  If aValue Then Begin
    result := aTrueString;
  End
  Else Begin
    Result := aFalseString;
  End;
End;

End.

