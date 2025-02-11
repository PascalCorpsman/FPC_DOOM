Unit doomdef;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  ,i_timer
  ;

Const
  // The maximum number of players, multiplayer/networking.
  MAXPLAYERS = 4; // !! ACHTUNG !!  es gibt auch eine Konstante die Heist NET_MAXPLAYERS und die ist 8

  //
  // Difficulty/skill settings/filters.
  //

  // Skill flags.
  MTF_EASY = 1;
  MTF_NORMAL = 2;
  MTF_HARD = 4;

  // Deaf monsters/do not react to sound.
  MTF_AMBUSH = 8;


  //
  // Power up durations,
  //  how many seconds till expiration,
  //  assuming TICRATE is 35 ticks/second.
  //
  INVULNTICS = (30 * TICRATE);
  INVISTICS = (60 * TICRATE);
  INFRATICS = (120 * TICRATE);
  IRONTICS = (60 * TICRATE);

  // The current state of the game: whether we are
  // playing, gazing at the intermission screen,
  // the game final animation, or a demo.
Type

  //
  // Key cards.
  //
  card_t =
    (
    it_bluecard,
    it_yellowcard,
    it_redcard,
    it_blueskull,
    it_yellowskull,
    it_redskull,

    NUMCARDS
    );

  // The defined weapons,
  //  including a marker indicating
  //  user has not changed weapon.
  weapontype_t =
    (
    wp_fist,
    wp_pistol,
    wp_shotgun,
    wp_chaingun,
    wp_missile,
    wp_plasma,
    wp_bfg,
    wp_chainsaw,
    wp_supershotgun,

    NUMWEAPONS,

    // No pending weapon change.
    wp_nochange
    );

  // Ammunition types defined.
  ammotype_t =
    (
    am_clip, // Pistol / chaingun ammo.
    am_shell, // Shotgun / double barreled shotgun.
    am_cell, // Plasma rifle, BFG.
    am_misl, // Missile launcher.
    NUMAMMO,
    am_noammo // Unlimited for chainsaw / fist.
    );

  gamestate_t = (
    GS_NEG_1 = -1, // die FPC Variante für -1
    GS_LEVEL = 0,
    GS_INTERMISSION,
    GS_FINALE,
    GS_DEMOSCREEN
    );

  gameaction_t =
    (
    ga_nothing,
    ga_loadlevel,
    ga_newgame,
    ga_loadgame,
    ga_savegame,
    ga_playdemo,
    ga_completed,
    ga_victory,
    ga_worlddone,
    ga_screenshot
    );

  // Power up artifacts.
  powertype_t =
    (
    pw_invulnerability,
    pw_strength,
    pw_invisibility,
    pw_ironfeet,
    pw_allmap,
    pw_infrared,
    NUMPOWERS,
    // [crispy] showfps and mapcoords are now "powers"
    pw_showfps,
    pw_mapcoords
    );

Implementation

End.

