Unit p_extnodes;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type
  mapformat_t =
    (
    MFMT_DOOMBSP = $000,
    MFMT_DEEPBSP = $001,
    MFMT_ZDBSPX = $002,
    MFMT_ZDBSPZ = $004,
    MFMT_HEXEN = $100
    );

Function P_CheckMapFormat(lumpnum: int): mapformat_t;
//
//extern void P_LoadSegs_DeePBSP (int lump);
//extern void P_LoadSubsectors_DeePBSP (int lump);
//extern void P_LoadNodes_DeePBSP (int lump);
//extern void P_LoadNodes_ZDBSP (int lump, boolean compressed);
//extern void P_LoadThings_Hexen (int lump);
//extern void P_LoadLineDefs_Hexen (int lump);

Implementation

Uses
  doomdata
  , w_wad
  , z_zone
  ;

Function memcmp(Const data: Array Of Byte; Str: String): Boolean;
Var
  i: Integer;
Begin
  result := true;
  For i := 1 To Length(str) Do Begin
    If ord(str[i]) <> data[i - 1] Then Begin
      result := false;
      break;
    End;
  End;
End;

// [crispy] support maps with NODES in compressed or uncompressed ZDBSP
// format or DeePBSP format and/or LINEDEFS and THINGS lumps in Hexen format

Function P_CheckMapFormat(lumpnum: INT): mapformat_t;
Var
  _format: mapformat_t;
  nodes: Array Of Byte;
  b: int;
Begin
  _format := MFMT_DOOMBSP;
  b := lumpnum + ML_BLOCKMAP + 1;
  If (b < length(lumpinfo)) And (lumpinfo[b].name = 'BEHAVIOR') Then Begin
    write(stderr, 'Hexen (');
    _format := MFMT_HEXEN;
  End
  Else
    write(stderr, 'Doom (');
  b := lumpnum + ML_NODES;
  nodes := W_CacheLumpNum(b, PU_CACHE);
  If (Not (b < length(lumpinfo)) And (
    (assigned(nodes))) And (
    W_LumpLength(b) > 0)) Then
    write(stderr, 'no nodes')
  Else Begin
    If (memcmp(nodes, 'xNd4'#0#0#0#0))
      Then Begin
      write(stderr, 'DeePBSP');
      _format := MFMT_DEEPBSP;
    End
    Else Begin
      If (memcmp(nodes, 'XNOD')) Then Begin
        write(stderr, 'ZDBSP');
        _format := MFMT_ZDBSPX;
      End
      Else Begin
        If (memcmp(nodes, 'ZNOD')) Then Begin
          write(stderr, 'compressed ZDBSP');
          _format := MFMT_ZDBSPZ;
        End
        Else
          write(stderr, 'BSP');
      End;
    End;
  End;

  //    if (nodes)
  //	W_ReleaseLumpNum(b);

  RESULT := _format;
End;

End.

