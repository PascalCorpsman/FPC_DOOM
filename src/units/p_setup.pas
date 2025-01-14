Unit p_setup;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef, doomdata
  ;

Var
  playerstarts: Array[0..MAXPLAYERS - 1] Of mapthing_t;


Function P_GetNumForMap(episode, map: int; critical: boolean): int;

Implementation

Uses
  doomstat
  , d_mode
  , w_wad
  ;

Function P_GetNumForMap(episode, map: int; critical: boolean): int;
Var
  lumpName: String;
Begin
  // find map name
  If (gamemode = commercial) Then Begin
    If (map < 10) Then Begin
      lumpname := 'map0' + inttostr(map);
    End
    Else Begin
      lumpname := 'map' + inttostr(map);
    End;
  End
  Else Begin
    lumpName := format('E%dM%d', [episode, map]);
  End;

  // [crispy] special-casing for E1M10 "Sewers" support
//      if (crispy->havee1m10 && episode == 1 && map == 10)
//      {
//  	DEH_snprintf(lumpname, 9, "E1M10");
//      }

  // [crispy] NRFTL / The Master Levels
//    if (crispy->havenerve && episode == 2 && map <= 9)
//    {
//	strcat(lumpname, "N");
//    }
//    if (crispy->havemaster && episode == 3 && map <= 21)
//    {
//	strcat(lumpname, "M");
//    }
  If critical Then Begin
    result := W_GetNumForName(lumpname);
  End
  Else Begin
    result := W_CheckNumForName(lumpname);
  End;
End;

End.

