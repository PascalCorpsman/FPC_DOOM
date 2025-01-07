Unit ufpc_doom_types;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Const
  INT_MIN = -2147483648; // = low(int); ?
  INT_MAX = 2147483647; // = high(int); ?

Type

  uint8_t = UInt8;
  uint16_t = UInt16;
  uint64_t = UInt64;
  size_t = UInt64;

  int = int32;
  P_int = ^int;
  unsigned_int = uint32;
  P_unsigned_int = ^unsigned_int;
  int64_t = Int64;

Implementation

End.

