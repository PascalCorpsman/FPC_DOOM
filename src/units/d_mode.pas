Unit d_mode;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Type

  // The "mission" controls what game we are playing.
  GameMission_t =
    (
    doom, // Doom 1
    doom2, // Doom 2
    pack_tnt, // Final Doom: TNT: Evilution
    pack_plut, // Final Doom: The Plutonia Experiment
    pack_chex, // Chex Quest (modded doom)
    pack_hacx, // Hacx (modded doom2)
    heretic, // Heretic
    hexen, // Hexen
    strife, // Strife
    doom2f, // Doom 2: L'Enfer sur Terre
    pack_nerve, // Doom 2: No Rest For The Living
    pack_master, // Master Levels for Doom 2

    none
    );

  // The "mode" allows more accurate specification of the game mode we are
  // in: eg. shareware vs. registered.  So doom1.wad and doom.wad are the
  // same mission, but a different mode.
  GameMode_t =
    (
    shareware, // Doom/Heretic shareware
    registered, // Doom/Heretic registered
    commercial, // Doom II/Hexen
    retail, // Ultimate Doom
    indetermined // Unknown.
    );

  // What version are we emulating?
  GameVersion_t =
    (
    exe_doom_1_2, // Doom 1.2: shareware and registered
    exe_doom_1_5, // Doom 1.5: "
    exe_doom_1_666, // Doom 1.666: for shareware, registered and commercial
    exe_doom_1_7, // Doom 1.7/1.7a: "
    exe_doom_1_8, // Doom 1.8: "
    exe_doom_1_9, // Doom 1.9: "
    exe_hacx, // Hacx
    exe_ultimate, // Ultimate Doom (retail)
    exe_final, // Final Doom
    exe_final2, // Final Doom (alternate exe)
    exe_chex, // Chex Quest executable (based on Final Doom)

    exe_heretic_1_3, // Heretic 1.3

    exe_hexen_1_1, // Hexen 1.1
    exe_hexen_1_1r2, // Hexen 1.1 (alternate exe)
    exe_strife_1_2, // Strife v1.2
    exe_strife_1_31 // Strife v1.31
    );

  // What IWAD variant are we using?
  GameVariant_t =
    (
    vanilla, // Vanilla Doom
    freedoom, // FreeDoom: Phase 1 + 2
    freedm, // FreeDM
    bfgedition // Doom Classic (Doom 3: BFG Edition)
    );

  // Skill level.
  skill_t =
    (
    sk_noitems = -1, // the "-skill 0" hack
    sk_baby = 0,
    sk_easy,
    sk_medium,
    sk_hard,
    sk_nightmare
    );

Implementation

End.

