Unit doomstat;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_mode;

Var
  // Game Mode - identify IWAD as shareware, retail etc.
  gamemode: GameMode_t = indetermined;
  gamemission: GameMission_t = doom;
  gameversion: GameVersion_t = exe_final2;
  gamevariant: GameVariant_t = vanilla;

  // Set if homebrew PWAD stuff has been added.
  modifiedgame: boolean = false;


  // 0=Cooperative; 1=Deathmatch; 2=Altdeath
  deathmatch: int;

  // Player taking events, and displaying.
  consoleplayer: int;

  // Convenience macro.
  // 'gamemission' can be equal to pack_chex or pack_hacx, but these are
  // just modified versions of doom and doom2, and should be interpreted
  // as the same most of the time.

Function logical_gamemission(): GameMission_t Inline;

Implementation

Function logical_gamemission(): GameMission_t;
Begin
  If gamemission = pack_chex Then Begin
    result := doom;
  End
  Else Begin
    If gamemission = pack_hacx Then Begin
      result := doom2;
    End
    Else Begin
      result := gamemission;
    End;
  End;
End;

End.

