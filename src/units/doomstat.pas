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

  // -------------------------------------
// Scores, rating.
// Statistics on a given map, for intermission.
//
  totalkills: int;
  totalitems: int;
  totalsecret: int;
  extrakills: int; // [crispy] count spawned monsters

  // Timer, for scores.
  //extern  int	levelstarttic;	// gametic at level start
  leveltime: int; // tics in game play for par
  //extern  int	totalleveltimes; // [crispy] CPhipps - total time for all completed levels


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

