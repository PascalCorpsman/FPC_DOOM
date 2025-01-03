Unit w_main;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_mode
  ;

Procedure W_CheckCorrectIWAD(mission: GameMission_t);

Implementation

Uses
  w_wad
  , i_system
  ;

// Lump names that are unique to particular game types. This lets us check
// the user is not trying to play with the wrong executable, eg.
// chocolate-doom -iwad hexen.wad.
Type
  unique_lumps_t = Record
    mission: GameMission_t;
    lumpname: String;
  End;

Const
  unique_lumps: Array Of unique_lumps_t = (
    (mission: doom; lumpname: 'POSSA1'),
    (mission: heretic; lumpname: 'IMPXA1'),
    (mission: hexen; lumpname: 'ETTNA1'),
    (mission: strife; lumpname: 'AGRDA1')
    );

Procedure W_CheckCorrectIWAD(mission: GameMission_t);
Var
  i: Integer;
  lumpnum: lumpindex_t;
Begin
  //    lumpnum;
  For i := 0 To high(unique_lumps) Do Begin

    If (mission <> unique_lumps[i].mission) Then Begin
      lumpnum := W_CheckNumForName(unique_lumps[i].lumpname);

      If (lumpnum >= 0) Then Begin
        I_Error('W_CheckCorrectIWAD invalid .wad file for game.');
        // TODO: Das hier noch richtig portieren!
//        I_Error("\nYou are trying to use a %s IWAD file with "
//                        "the %s%s binary.\nThis isn't going to work.\n"
//                        "You probably want to use the %s%s binary.",
//                        D_SuggestGameName(unique_lumps[i].mission,
//                                          indetermined),
//                        PROGRAM_PREFIX,
//                        D_GameMissionString(mission),
//                        PROGRAM_PREFIX,
//                        D_GameMissionString(unique_lumps[i].mission));
      End;
    End;
  End;
End;

End.

