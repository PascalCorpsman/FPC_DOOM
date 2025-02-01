Unit info;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , p_pspr;

Const
  sprnames: Array Of String = (
    'TROO', 'SHTG', 'PUNG', 'PISG', 'PISF', 'SHTF', 'SHT2', 'CHGG', 'CHGF', 'MISG',
    'MISF', 'SAWG', 'PLSG', 'PLSF', 'BFGG', 'BFGF', 'BLUD', 'PUFF', 'BAL1', 'BAL2',
    'PLSS', 'PLSE', 'MISL', 'BFS1', 'BFE1', 'BFE2', 'TFOG', 'IFOG', 'PLAY', 'POSS',
    'SPOS', 'VILE', 'FIRE', 'FATB', 'FBXP', 'SKEL', 'MANF', 'FATT', 'CPOS', 'SARG',
    'HEAD', 'BAL7', 'BOSS', 'BOS2', 'SKUL', 'SPID', 'BSPI', 'APLS', 'APBX', 'CYBR',
    'PAIN', 'SSWV', 'KEEN', 'BBRN', 'BOSF', 'ARM1', 'ARM2', 'BAR1', 'BEXP', 'FCAN',
    'BON1', 'BON2', 'BKEY', 'RKEY', 'YKEY', 'BSKU', 'RSKU', 'YSKU', 'STIM', 'MEDI',
    'SOUL', 'PINV', 'PSTR', 'PINS', 'MEGA', 'SUIT', 'PMAP', 'PVIS', 'CLIP', 'AMMO',
    'ROCK', 'BROK', 'CELL', 'CELP', 'SHEL', 'SBOX', 'BPAK', 'BFUG', 'MGUN', 'CSAW',
    'LAUN', 'PLAS', 'SHOT', 'SGN2', 'COLU', 'SMT2', 'GOR1', 'POL2', 'POL5', 'POL4',
    'POL3', 'POL1', 'POL6', 'GOR2', 'GOR3', 'GOR4', 'GOR5', 'SMIT', 'COL1', 'COL2',
    'COL3', 'COL4', 'CAND', 'CBRA', 'COL6', 'TRE1', 'TRE2', 'ELEC', 'CEYE', 'FSKU',
    'COL5', 'TBLU', 'TGRN', 'TRED', 'SMBT', 'SMGT', 'SMRT', 'HDB1', 'HDB2', 'HDB3',
    'HDB4', 'HDB5', 'HDB6', 'POB1', 'POB2', 'BRS1', 'TLMP', 'TLP2',
    // [crispy] additional BOOM and MBF states, sprites and code pointers
    'TNT1', 'DOGS', 'PLS1', 'PLS2', 'BON3', 'BON4',
    // [BH] blood splats, [crispy] unused
    'BLD2',
    // [BH] 100 extra sprite names to use in dehacked patches
    'SP00', 'SP01', 'SP02', 'SP03', 'SP04', 'SP05', 'SP06', 'SP07', 'SP08', 'SP09',
    'SP10', 'SP11', 'SP12', 'SP13', 'SP14', 'SP15', 'SP16', 'SP17', 'SP18', 'SP19',
    'SP20', 'SP21', 'SP22', 'SP23', 'SP24', 'SP25', 'SP26', 'SP27', 'SP28', 'SP29',
    'SP30', 'SP31', 'SP32', 'SP33', 'SP34', 'SP35', 'SP36', 'SP37', 'SP38', 'SP39',
    'SP40', 'SP41', 'SP42', 'SP43', 'SP44', 'SP45', 'SP46', 'SP47', 'SP48', 'SP49',
    'SP50', 'SP51', 'SP52', 'SP53', 'SP54', 'SP55', 'SP56', 'SP57', 'SP58', 'SP59',
    'SP60', 'SP61', 'SP62', 'SP63', 'SP64', 'SP65', 'SP66', 'SP67', 'SP68', 'SP69',
    'SP70', 'SP71', 'SP72', 'SP73', 'SP74', 'SP75', 'SP76', 'SP77', 'SP78', 'SP79',
    'SP80', 'SP81', 'SP82', 'SP83', 'SP84', 'SP85', 'SP86', 'SP87', 'SP88', 'SP89',
    'SP90', 'SP91', 'SP92', 'SP93', 'SP94', 'SP95', 'SP96', 'SP97', 'SP98', 'SP99'
    );

Var
  states: Array[0..integer(NUMSTATES)] Of state_t; // Wird im Initialization block initialisiert
  mobjinfo: Array[-1..integer(NUMMOBJTYPES)] Of mobjinfo_t; // Wird im Initialization block initialisiert

Implementation

Uses
  sounds
  , m_fixed
  , p_enemy, p_bexptr, p_mobj
  ;

Procedure Set_StatesP1(
  index: statenum_t;
  sprite: spritenum_t;
  frame: int;
  tics: int;
  // action: actionf_t;
  action: actionf_p1;
  nextstate: statenum_t;
  misc1: int;
  misc2: int);
Begin
  states[integer(index)].frame := frame;
  states[integer(index)].sprite := sprite;
  states[integer(index)].tics := tics;
  states[integer(index)].action.acp1 := action;
  states[integer(index)].nextstate := nextstate;
  states[integer(index)].misc1 := misc1;
  states[integer(index)].misc2 := misc2;
End;

Procedure Set_States(
  index: statenum_t;
  sprite: spritenum_t;
  frame: int;
  tics: int;
  // action: actionf_t;
  action: actionf_p3;
  nextstate: statenum_t;
  misc1: int;
  misc2: int);
Begin
  states[integer(index)].frame := frame;
  states[integer(index)].sprite := sprite;
  states[integer(index)].tics := tics;
  states[integer(index)].action.acp3 := action;
  states[integer(index)].nextstate := nextstate;
  states[integer(index)].misc1 := misc1;
  states[integer(index)].misc2 := misc2;
End;

Procedure Set_MobInfo(
  index: mobjtype_t;
  doomednum: int;
  spawnstate: statenum_t;
  spawnhealth: int;
  seestate: statenum_t;
  seesound: sfxenum_t;
  reactiontime: int;
  attacksound: sfxenum_t;
  painstate: statenum_t;
  painchance: int;
  painsound: sfxenum_t;
  meleestate: statenum_t;
  missilestate: statenum_t;
  deathstate: statenum_t;
  xdeathstate: statenum_t;
  deathsound: sfxenum_t;
  speed: int;
  radius: int;
  height: int;
  mass: int;
  damage: int;
  activesound: sfxenum_t;
  flags: Int;
  raisestate: statenum_t
  );
Begin
  mobjinfo[integer(index)].doomednum := doomednum;
  mobjinfo[integer(index)].spawnstate := spawnstate;
  mobjinfo[integer(index)].spawnhealth := spawnhealth;
  mobjinfo[integer(index)].seestate := seestate;
  mobjinfo[integer(index)].seesound := seesound;
  mobjinfo[integer(index)].reactiontime := reactiontime;
  mobjinfo[integer(index)].attacksound := attacksound;
  mobjinfo[integer(index)].painstate := painstate;
  mobjinfo[integer(index)].painchance := painchance;
  mobjinfo[integer(index)].painsound := painsound;
  mobjinfo[integer(index)].meleestate := meleestate;
  mobjinfo[integer(index)].missilestate := missilestate;
  mobjinfo[integer(index)].deathstate := deathstate;
  mobjinfo[integer(index)].xdeathstate := xdeathstate;
  mobjinfo[integer(index)].deathsound := deathsound;
  mobjinfo[integer(index)].speed := speed;
  mobjinfo[integer(index)].radius := radius;
  mobjinfo[integer(index)].height := height;
  mobjinfo[integer(index)].mass := mass;
  mobjinfo[integer(index)].damage := damage;
  mobjinfo[integer(index)].activesound := activesound;
  mobjinfo[integer(index)].flags := flags;
  mobjinfo[integer(index)].raisestate := raisestate;
  // Ab hier das [crispy] zeug initialisieren
  mobjinfo[integer(index)].actualheight := 0;
  mobjinfo[integer(index)].droppeditem := MT_NULL; // oder sollte dass besser MT_PLAYER weil C ja den Speicher mit 0 initialisiert ?
  mobjinfo[integer(index)].meleethreshold := 0;
  mobjinfo[integer(index)].maxattackrange := 0;
  mobjinfo[integer(index)].minmissilechance := 0;
  mobjinfo[integer(index)].missilechancemult := 0;
End;

Initialization

  Set_States(S_NULL, SPR_TROO, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_LIGHTDONE, SPR_SHTG, 4, 0, @A_Light0, S_NULL, 0, 0);
  Set_States(S_PUNCH, SPR_PUNG, 0, 1, @A_WeaponReady, S_PUNCH, 0, 0);
  Set_States(S_PUNCHDOWN, SPR_PUNG, 0, 1, @A_Lower, S_PUNCHDOWN, 0, 0);
  Set_States(S_PUNCHUP, SPR_PUNG, 0, 1, @A_Raise, S_PUNCHUP, 0, 0);
  Set_States(S_PUNCH1, SPR_PUNG, 1, 4, Nil, S_PUNCH2, 0, 0);
  Set_States(S_PUNCH2, SPR_PUNG, 2, 4, @A_Punch, S_PUNCH3, 0, 0);
  Set_States(S_PUNCH3, SPR_PUNG, 3, 5, Nil, S_PUNCH4, 0, 0);
  Set_States(S_PUNCH4, SPR_PUNG, 2, 4, Nil, S_PUNCH5, 0, 0);
  Set_States(S_PUNCH5, SPR_PUNG, 1, 5, @A_ReFire, S_PUNCH, 0, 0);
  Set_States(S_PISTOL, SPR_PISG, 0, 1, @A_WeaponReady, S_PISTOL, 0, 0);
  Set_States(S_PISTOLDOWN, SPR_PISG, 0, 1, @A_Lower, S_PISTOLDOWN, 0, 0);
  Set_States(S_PISTOLUP, SPR_PISG, 0, 1, @A_Raise, S_PISTOLUP, 0, 0);
  Set_States(S_PISTOL1, SPR_PISG, 0, 4, Nil, S_PISTOL2, 0, 0);
  Set_States(S_PISTOL2, SPR_PISG, 1, 6, @A_FirePistol, S_PISTOL3, 0, 0);
  Set_States(S_PISTOL3, SPR_PISG, 2, 4, Nil, S_PISTOL4, 0, 0);
  Set_States(S_PISTOL4, SPR_PISG, 1, 5, @A_ReFire, S_PISTOL, 0, 0);
  Set_States(S_PISTOLFLASH, SPR_PISF, 32768, 7, @A_Light1, S_LIGHTDONE, 0, 0);
  Set_States(S_SGUN, SPR_SHTG, 0, 1, @A_WeaponReady, S_SGUN, 0, 0);
  Set_States(S_SGUNDOWN, SPR_SHTG, 0, 1, @A_Lower, S_SGUNDOWN, 0, 0);
  Set_States(S_SGUNUP, SPR_SHTG, 0, 1, @A_Raise, S_SGUNUP, 0, 0);
  Set_States(S_SGUN1, SPR_SHTG, 0, 3, Nil, S_SGUN2, 0, 0);
  Set_States(S_SGUN2, SPR_SHTG, 0, 7, @A_FireShotgun, S_SGUN3, 0, 0);
  Set_States(S_SGUN3, SPR_SHTG, 1, 5, Nil, S_SGUN4, 0, 0);
  Set_States(S_SGUN4, SPR_SHTG, 2, 5, Nil, S_SGUN5, 0, 0);
  Set_States(S_SGUN5, SPR_SHTG, 3, 4, Nil, S_SGUN6, 0, 0);
  Set_States(S_SGUN6, SPR_SHTG, 2, 5, Nil, S_SGUN7, 0, 0);
  Set_States(S_SGUN7, SPR_SHTG, 1, 5, Nil, S_SGUN8, 0, 0);
  Set_States(S_SGUN8, SPR_SHTG, 0, 3, Nil, S_SGUN9, 0, 0);
  Set_States(S_SGUN9, SPR_SHTG, 0, 7, @A_ReFire, S_SGUN, 0, 0);
  Set_States(S_SGUNFLASH1, SPR_SHTF, 32768, 4, @A_Light1, S_SGUNFLASH2, 0, 0);
  Set_States(S_SGUNFLASH2, SPR_SHTF, 32769, 3, @A_Light2, S_LIGHTDONE, 0, 0);
  Set_States(S_DSGUN, SPR_SHT2, 0, 1, @A_WeaponReady, S_DSGUN, 0, 0);
  Set_States(S_DSGUNDOWN, SPR_SHT2, 0, 1, @A_Lower, S_DSGUNDOWN, 0, 0);
  Set_States(S_DSGUNUP, SPR_SHT2, 0, 1, @A_Raise, S_DSGUNUP, 0, 0);
  Set_States(S_DSGUN1, SPR_SHT2, 0, 3, Nil, S_DSGUN2, 0, 0);
  // [crispy] killough 9/5/98: make SSG lighting flash more uniform along super shotgun
  Set_States(S_DSGUN2, SPR_SHT2, 0 Or $8000, 7, @A_FireShotgun2, S_DSGUN3, 0, 0);
  Set_States(S_DSGUN3, SPR_SHT2, 1, 7, Nil, S_DSGUN4, 0, 0);
  Set_States(S_DSGUN4, SPR_SHT2, 2, 7, @A_CheckReload, S_DSGUN5, 0, 0);
  Set_States(S_DSGUN5, SPR_SHT2, 3, 7, @A_OpenShotgun2, S_DSGUN6, 0, 0);
  Set_States(S_DSGUN6, SPR_SHT2, 4, 7, Nil, S_DSGUN7, 0, 0);
  Set_States(S_DSGUN7, SPR_SHT2, 5, 7, @A_LoadShotgun2, S_DSGUN8, 0, 0);
  Set_States(S_DSGUN8, SPR_SHT2, 6, 6, Nil, S_DSGUN9, 0, 0);
  Set_States(S_DSGUN9, SPR_SHT2, 7, 6, @A_CloseShotgun2, S_DSGUN10, 0, 0);
  Set_States(S_DSGUN10, SPR_SHT2, 0, 5, @A_ReFire, S_DSGUN, 0, 0);
  Set_States(S_DSNR1, SPR_SHT2, 1, 7, Nil, S_DSNR2, 0, 0);
  Set_States(S_DSNR2, SPR_SHT2, 0, 3, Nil, S_DSGUNDOWN, 0, 0);
  // [crispy] killough 8/20/98: reduce first SSG flash frame one tic, to fix
  // Doom II SSG flash bug, in which SSG raises before flash finishes
  Set_States(S_DSGUNFLASH1, SPR_SHT2, 32776, 5 - 1, @A_Light1, S_DSGUNFLASH2, 0, 0);
  Set_States(S_DSGUNFLASH2, SPR_SHT2, 32777, 4, @A_Light2, S_LIGHTDONE, 0, 0);
  Set_States(S_CHAIN, SPR_CHGG, 0, 1, @A_WeaponReady, S_CHAIN, 0, 0);
  Set_States(S_CHAINDOWN, SPR_CHGG, 0, 1, @A_Lower, S_CHAINDOWN, 0, 0);
  Set_States(S_CHAINUP, SPR_CHGG, 0, 1, @A_Raise, S_CHAINUP, 0, 0);
  Set_States(S_CHAIN1, SPR_CHGG, 0, 4, @A_FireCGun, S_CHAIN2, 0, 0);
  Set_States(S_CHAIN2, SPR_CHGG, 1, 4, @A_FireCGun, S_CHAIN3, 0, 0);
  Set_States(S_CHAIN3, SPR_CHGG, 1, 0, @A_ReFire, S_CHAIN, 0, 0);
  Set_States(S_CHAINFLASH1, SPR_CHGF, 32768, 5, @A_Light1, S_LIGHTDONE, 0, 0);
  Set_States(S_CHAINFLASH2, SPR_CHGF, 32769, 5, @A_Light2, S_LIGHTDONE, 0, 0);
  Set_States(S_MISSILE, SPR_MISG, 0, 1, @A_WeaponReady, S_MISSILE, 0, 0);
  Set_States(S_MISSILEDOWN, SPR_MISG, 0, 1, @A_Lower, S_MISSILEDOWN, 0, 0);
  Set_States(S_MISSILEUP, SPR_MISG, 0, 1, @A_Raise, S_MISSILEUP, 0, 0);
  Set_States(S_MISSILE1, SPR_MISG, 1, 8, @A_GunFlash, S_MISSILE2, 0, 0);
  Set_States(S_MISSILE2, SPR_MISG, 1, 12, @A_FireMissile, S_MISSILE3, 0, 0);
  Set_States(S_MISSILE3, SPR_MISG, 1, 0, @A_ReFire, S_MISSILE, 0, 0);
  Set_States(S_MISSILEFLASH1, SPR_MISF, 32768, 3, @A_Light1, S_MISSILEFLASH2, 0, 0);
  Set_States(S_MISSILEFLASH2, SPR_MISF, 32769, 4, Nil, S_MISSILEFLASH3, 0, 0);
  Set_States(S_MISSILEFLASH3, SPR_MISF, 32770, 4, @A_Light2, S_MISSILEFLASH4, 0, 0);
  Set_States(S_MISSILEFLASH4, SPR_MISF, 32771, 4, @A_Light2, S_LIGHTDONE, 0, 0);
  Set_States(S_SAW, SPR_SAWG, 2, 4, @A_WeaponReady, S_SAWB, 0, 0);
  Set_States(S_SAWB, SPR_SAWG, 3, 4, @A_WeaponReady, S_SAW, 0, 0);
  Set_States(S_SAWDOWN, SPR_SAWG, 2, 1, @A_Lower, S_SAWDOWN, 0, 0);
  Set_States(S_SAWUP, SPR_SAWG, 2, 1, @A_Raise, S_SAWUP, 0, 0);
  Set_States(S_SAW1, SPR_SAWG, 0, 4, @A_Saw, S_SAW2, 0, 0);
  Set_States(S_SAW2, SPR_SAWG, 1, 4, @A_Saw, S_SAW3, 0, 0);
  Set_States(S_SAW3, SPR_SAWG, 1, 0, @A_ReFire, S_SAW, 0, 0);
  Set_States(S_PLASMA, SPR_PLSG, 0, 1, @A_WeaponReady, S_PLASMA, 0, 0);
  Set_States(S_PLASMADOWN, SPR_PLSG, 0, 1, @A_Lower, S_PLASMADOWN, 0, 0);
  Set_States(S_PLASMAUP, SPR_PLSG, 0, 1, @A_Raise, S_PLASMAUP, 0, 0);
  Set_States(S_PLASMA1, SPR_PLSG, 0, 3, @A_FirePlasma, S_PLASMA2, 0, 0);
  Set_States(S_PLASMA2, SPR_PLSG, 1, 20, @A_ReFire, S_PLASMA, 0, 0);
  Set_States(S_PLASMAFLASH1, SPR_PLSF, 32768, 4, @A_Light1, S_LIGHTDONE, 0, 0);
  Set_States(S_PLASMAFLASH2, SPR_PLSF, 32769, 4, @A_Light1, S_LIGHTDONE, 0, 0);
  Set_States(S_BFG, SPR_BFGG, 0, 1, @A_WeaponReady, S_BFG, 0, 0);
  Set_States(S_BFGDOWN, SPR_BFGG, 0, 1, @A_Lower, S_BFGDOWN, 0, 0);
  Set_States(S_BFGUP, SPR_BFGG, 0, 1, @A_Raise, S_BFGUP, 0, 0);
  Set_States(S_BFG1, SPR_BFGG, 0, 20, @A_BFGsound, S_BFG2, 0, 0);
  Set_States(S_BFG2, SPR_BFGG, 1, 10, @A_GunFlash, S_BFG3, 0, 0);
  Set_States(S_BFG3, SPR_BFGG, 1, 10, @A_FireBFG, S_BFG4, 0, 0);
  Set_States(S_BFG4, SPR_BFGG, 1, 20, @A_ReFire, S_BFG, 0, 0);
  Set_States(S_BFGFLASH1, SPR_BFGF, 32768, 11, @A_Light1, S_BFGFLASH2, 0, 0);
  Set_States(S_BFGFLASH2, SPR_BFGF, 32769, 6, @A_Light2, S_LIGHTDONE, 0, 0);
  Set_States(S_BLOOD1, SPR_BLUD, 2, 8, Nil, S_BLOOD2, 0, 0);
  Set_States(S_BLOOD2, SPR_BLUD, 1, 8, Nil, S_BLOOD3, 0, 0);
  Set_States(S_BLOOD3, SPR_BLUD, 0, 8, Nil, S_NULL, 0, 0);
  Set_States(S_PUFF1, SPR_PUFF, 32768, 4, Nil, S_PUFF2, 0, 0);
  Set_States(S_PUFF2, SPR_PUFF, 1, 4, Nil, S_PUFF3, 0, 0);
  Set_States(S_PUFF3, SPR_PUFF, 2, 4, Nil, S_PUFF4, 0, 0);
  Set_States(S_PUFF4, SPR_PUFF, 3, 4, Nil, S_NULL, 0, 0);
  Set_States(S_TBALL1, SPR_BAL1, 32768, 4, Nil, S_TBALL2, 0, 0);
  Set_States(S_TBALL2, SPR_BAL1, 32769, 4, Nil, S_TBALL1, 0, 0);
  Set_States(S_TBALLX1, SPR_BAL1, 32770, 6, Nil, S_TBALLX2, 0, 0);
  Set_States(S_TBALLX2, SPR_BAL1, 32771, 6, Nil, S_TBALLX3, 0, 0);
  Set_States(S_TBALLX3, SPR_BAL1, 32772, 6, Nil, S_NULL, 0, 0);
  Set_States(S_RBALL1, SPR_BAL2, 32768, 4, Nil, S_RBALL2, 0, 0);
  Set_States(S_RBALL2, SPR_BAL2, 32769, 4, Nil, S_RBALL1, 0, 0);
  Set_States(S_RBALLX1, SPR_BAL2, 32770, 6, Nil, S_RBALLX2, 0, 0);
  Set_States(S_RBALLX2, SPR_BAL2, 32771, 6, Nil, S_RBALLX3, 0, 0);
  Set_States(S_RBALLX3, SPR_BAL2, 32772, 6, Nil, S_NULL, 0, 0);
  Set_States(S_PLASBALL, SPR_PLSS, 32768, 6, Nil, S_PLASBALL2, 0, 0);
  Set_States(S_PLASBALL2, SPR_PLSS, 32769, 6, Nil, S_PLASBALL, 0, 0);
  Set_States(S_PLASEXP, SPR_PLSE, 32768, 4, Nil, S_PLASEXP2, 0, 0);
  Set_States(S_PLASEXP2, SPR_PLSE, 32769, 4, Nil, S_PLASEXP3, 0, 0);
  Set_States(S_PLASEXP3, SPR_PLSE, 32770, 4, Nil, S_PLASEXP4, 0, 0);
  Set_States(S_PLASEXP4, SPR_PLSE, 32771, 4, Nil, S_PLASEXP5, 0, 0);
  Set_States(S_PLASEXP5, SPR_PLSE, 32772, 4, Nil, S_NULL, 0, 0);
  Set_States(S_ROCKET, SPR_MISL, 32768, 1, Nil, S_ROCKET, 0, 0);
  Set_States(S_BFGSHOT, SPR_BFS1, 32768, 4, Nil, S_BFGSHOT2, 0, 0);
  Set_States(S_BFGSHOT2, SPR_BFS1, 32769, 4, Nil, S_BFGSHOT, 0, 0);
  Set_States(S_BFGLAND, SPR_BFE1, 32768, 8, Nil, S_BFGLAND2, 0, 0);
  Set_States(S_BFGLAND2, SPR_BFE1, 32769, 8, Nil, S_BFGLAND3, 0, 0);
  Set_States(S_BFGLAND3, SPR_BFE1, 32770, 8, @A_BFGSpray, S_BFGLAND4, 0, 0);
  Set_States(S_BFGLAND4, SPR_BFE1, 32771, 8, Nil, S_BFGLAND5, 0, 0);
  Set_States(S_BFGLAND5, SPR_BFE1, 32772, 8, Nil, S_BFGLAND6, 0, 0);
  Set_States(S_BFGLAND6, SPR_BFE1, 32773, 8, Nil, S_NULL, 0, 0);
  Set_States(S_BFGEXP, SPR_BFE2, 32768, 8, Nil, S_BFGEXP2, 0, 0);
  Set_States(S_BFGEXP2, SPR_BFE2, 32769, 8, Nil, S_BFGEXP3, 0, 0);
  Set_States(S_BFGEXP3, SPR_BFE2, 32770, 8, Nil, S_BFGEXP4, 0, 0);
  Set_States(S_BFGEXP4, SPR_BFE2, 32771, 8, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_EXPLODE1, SPR_MISL, 32769, 8, @A_Explode, S_EXPLODE2, 0, 0);
  Set_States(S_EXPLODE2, SPR_MISL, 32770, 6, Nil, S_EXPLODE3, 0, 0);
  Set_States(S_EXPLODE3, SPR_MISL, 32771, 4, Nil, S_NULL, 0, 0);
  Set_States(S_TFOG, SPR_TFOG, 32768, 6, Nil, S_TFOG01, 0, 0);
  Set_States(S_TFOG01, SPR_TFOG, 32769, 6, Nil, S_TFOG02, 0, 0);
  Set_States(S_TFOG02, SPR_TFOG, 32768, 6, Nil, S_TFOG2, 0, 0);
  Set_States(S_TFOG2, SPR_TFOG, 32769, 6, Nil, S_TFOG3, 0, 0);
  Set_States(S_TFOG3, SPR_TFOG, 32770, 6, Nil, S_TFOG4, 0, 0);
  Set_States(S_TFOG4, SPR_TFOG, 32771, 6, Nil, S_TFOG5, 0, 0);
  Set_States(S_TFOG5, SPR_TFOG, 32772, 6, Nil, S_TFOG6, 0, 0);
  Set_States(S_TFOG6, SPR_TFOG, 32773, 6, Nil, S_TFOG7, 0, 0);
  Set_States(S_TFOG7, SPR_TFOG, 32774, 6, Nil, S_TFOG8, 0, 0);
  Set_States(S_TFOG8, SPR_TFOG, 32775, 6, Nil, S_TFOG9, 0, 0);
  Set_States(S_TFOG9, SPR_TFOG, 32776, 6, Nil, S_TFOG10, 0, 0);
  Set_States(S_TFOG10, SPR_TFOG, 32777, 6, Nil, S_NULL, 0, 0);
  Set_States(S_IFOG, SPR_IFOG, 32768, 6, Nil, S_IFOG01, 0, 0);
  Set_States(S_IFOG01, SPR_IFOG, 32769, 6, Nil, S_IFOG02, 0, 0);
  Set_States(S_IFOG02, SPR_IFOG, 32768, 6, Nil, S_IFOG2, 0, 0);
  Set_States(S_IFOG2, SPR_IFOG, 32769, 6, Nil, S_IFOG3, 0, 0);
  Set_States(S_IFOG3, SPR_IFOG, 32770, 6, Nil, S_IFOG4, 0, 0);
  Set_States(S_IFOG4, SPR_IFOG, 32771, 6, Nil, S_IFOG5, 0, 0);
  Set_States(S_IFOG5, SPR_IFOG, 32772, 6, Nil, S_NULL, 0, 0);
  Set_States(S_PLAY, SPR_PLAY, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_PLAY_RUN1, SPR_PLAY, 0, 4, Nil, S_PLAY_RUN2, 0, 0);
  Set_States(S_PLAY_RUN2, SPR_PLAY, 1, 4, Nil, S_PLAY_RUN3, 0, 0);
  Set_States(S_PLAY_RUN3, SPR_PLAY, 2, 4, Nil, S_PLAY_RUN4, 0, 0);
  Set_States(S_PLAY_RUN4, SPR_PLAY, 3, 4, Nil, S_PLAY_RUN1, 0, 0);
  Set_States(S_PLAY_ATK1, SPR_PLAY, 4, 12, Nil, S_PLAY, 0, 0);
  Set_States(S_PLAY_ATK2, SPR_PLAY, 32773, 6, Nil, S_PLAY_ATK1, 0, 0);
  Set_States(S_PLAY_PAIN, SPR_PLAY, 6, 4, Nil, S_PLAY_PAIN2, 0, 0);
  Set_StatesP1(S_PLAY_PAIN2, SPR_PLAY, 6, 4, @A_Pain, S_PLAY, 0, 0);
  Set_States(S_PLAY_DIE1, SPR_PLAY, 7, 10, Nil, S_PLAY_DIE2, 0, 0);
  Set_StatesP1(S_PLAY_DIE2, SPR_PLAY, 8, 10, @A_PlayerScream, S_PLAY_DIE3, 0, 0);
  Set_StatesP1(S_PLAY_DIE3, SPR_PLAY, 9, 10, @A_Fall, S_PLAY_DIE4, 0, 0);
  Set_States(S_PLAY_DIE4, SPR_PLAY, 10, 10, Nil, S_PLAY_DIE5, 0, 0);
  Set_States(S_PLAY_DIE5, SPR_PLAY, 11, 10, Nil, S_PLAY_DIE6, 0, 0);
  Set_States(S_PLAY_DIE6, SPR_PLAY, 12, 10, Nil, S_PLAY_DIE7, 0, 0);
  Set_States(S_PLAY_DIE7, SPR_PLAY, 13, -1, Nil, S_NULL, 0, 0);
  Set_States(S_PLAY_XDIE1, SPR_PLAY, 14, 5, Nil, S_PLAY_XDIE2, 0, 0);
  Set_StatesP1(S_PLAY_XDIE2, SPR_PLAY, 15, 5, @A_XScream, S_PLAY_XDIE3, 0, 0);
  Set_StatesP1(S_PLAY_XDIE3, SPR_PLAY, 16, 5, @A_Fall, S_PLAY_XDIE4, 0, 0);
  Set_States(S_PLAY_XDIE4, SPR_PLAY, 17, 5, Nil, S_PLAY_XDIE5, 0, 0);
  Set_States(S_PLAY_XDIE5, SPR_PLAY, 18, 5, Nil, S_PLAY_XDIE6, 0, 0);
  Set_States(S_PLAY_XDIE6, SPR_PLAY, 19, 5, Nil, S_PLAY_XDIE7, 0, 0);
  Set_States(S_PLAY_XDIE7, SPR_PLAY, 20, 5, Nil, S_PLAY_XDIE8, 0, 0);
  Set_States(S_PLAY_XDIE8, SPR_PLAY, 21, 5, Nil, S_PLAY_XDIE9, 0, 0);
  Set_States(S_PLAY_XDIE9, SPR_PLAY, 22, -1, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_POSS_STND, SPR_POSS, 0, 10, @A_Look, S_POSS_STND2, 0, 0);
  Set_StatesP1(S_POSS_STND2, SPR_POSS, 1, 10, @A_Look, S_POSS_STND, 0, 0);
  Set_StatesP1(S_POSS_RUN1, SPR_POSS, 0, 4, @A_Chase, S_POSS_RUN2, 0, 0);
  Set_StatesP1(S_POSS_RUN2, SPR_POSS, 0, 4, @A_Chase, S_POSS_RUN3, 0, 0);
  Set_StatesP1(S_POSS_RUN3, SPR_POSS, 1, 4, @A_Chase, S_POSS_RUN4, 0, 0);
  Set_StatesP1(S_POSS_RUN4, SPR_POSS, 1, 4, @A_Chase, S_POSS_RUN5, 0, 0);
  Set_StatesP1(S_POSS_RUN5, SPR_POSS, 2, 4, @A_Chase, S_POSS_RUN6, 0, 0);
  Set_StatesP1(S_POSS_RUN6, SPR_POSS, 2, 4, @A_Chase, S_POSS_RUN7, 0, 0);
  Set_StatesP1(S_POSS_RUN7, SPR_POSS, 3, 4, @A_Chase, S_POSS_RUN8, 0, 0);
  Set_StatesP1(S_POSS_RUN8, SPR_POSS, 3, 4, @A_Chase, S_POSS_RUN1, 0, 0);
  Set_StatesP1(S_POSS_ATK1, SPR_POSS, 4, 10, @A_FaceTarget, S_POSS_ATK2, 0, 0);
  // [crispy] render Zombiman's firing frames full-bright
  Set_StatesP1(S_POSS_ATK2, SPR_POSS, 5 Or $8000, 8, @A_PosAttack, S_POSS_ATK3, 0, 0);
  Set_States(S_POSS_ATK3, SPR_POSS, 4, 8, Nil, S_POSS_RUN1, 0, 0);
  Set_States(S_POSS_PAIN, SPR_POSS, 6, 3, Nil, S_POSS_PAIN2, 0, 0);
  Set_StatesP1(S_POSS_PAIN2, SPR_POSS, 6, 3, @A_Pain, S_POSS_RUN1, 0, 0);
  Set_States(S_POSS_DIE1, SPR_POSS, 7, 5, Nil, S_POSS_DIE2, 0, 0);
  Set_StatesP1(S_POSS_DIE2, SPR_POSS, 8, 5, @A_Scream, S_POSS_DIE3, 0, 0);
  Set_StatesP1(S_POSS_DIE3, SPR_POSS, 9, 5, @A_Fall, S_POSS_DIE4, 0, 0);
  Set_States(S_POSS_DIE4, SPR_POSS, 10, 5, Nil, S_POSS_DIE5, 0, 0);
  Set_States(S_POSS_DIE5, SPR_POSS, 11, -1, Nil, S_NULL, 0, 0);
  Set_States(S_POSS_XDIE1, SPR_POSS, 12, 5, Nil, S_POSS_XDIE2, 0, 0);
  Set_StatesP1(S_POSS_XDIE2, SPR_POSS, 13, 5, @A_XScream, S_POSS_XDIE3, 0, 0);
  Set_StatesP1(S_POSS_XDIE3, SPR_POSS, 14, 5, @A_Fall, S_POSS_XDIE4, 0, 0);
  Set_States(S_POSS_XDIE4, SPR_POSS, 15, 5, Nil, S_POSS_XDIE5, 0, 0);
  Set_States(S_POSS_XDIE5, SPR_POSS, 16, 5, Nil, S_POSS_XDIE6, 0, 0);
  Set_States(S_POSS_XDIE6, SPR_POSS, 17, 5, Nil, S_POSS_XDIE7, 0, 0);
  Set_States(S_POSS_XDIE7, SPR_POSS, 18, 5, Nil, S_POSS_XDIE8, 0, 0);
  Set_States(S_POSS_XDIE8, SPR_POSS, 19, 5, Nil, S_POSS_XDIE9, 0, 0);
  Set_States(S_POSS_XDIE9, SPR_POSS, 20, -1, Nil, S_NULL, 0, 0);
  Set_States(S_POSS_RAISE1, SPR_POSS, 10, 5, Nil, S_POSS_RAISE2, 0, 0);
  Set_States(S_POSS_RAISE2, SPR_POSS, 9, 5, Nil, S_POSS_RAISE3, 0, 0);
  Set_States(S_POSS_RAISE3, SPR_POSS, 8, 5, Nil, S_POSS_RAISE4, 0, 0);
  Set_States(S_POSS_RAISE4, SPR_POSS, 7, 5, Nil, S_POSS_RUN1, 0, 0);
  Set_StatesP1(S_SPOS_STND, SPR_SPOS, 0, 10, @A_Look, S_SPOS_STND2, 0, 0);
  Set_StatesP1(S_SPOS_STND2, SPR_SPOS, 1, 10, @A_Look, S_SPOS_STND, 0, 0);
  Set_StatesP1(S_SPOS_RUN1, SPR_SPOS, 0, 3, @A_Chase, S_SPOS_RUN2, 0, 0);
  Set_StatesP1(S_SPOS_RUN2, SPR_SPOS, 0, 3, @A_Chase, S_SPOS_RUN3, 0, 0);
  Set_StatesP1(S_SPOS_RUN3, SPR_SPOS, 1, 3, @A_Chase, S_SPOS_RUN4, 0, 0);
  Set_StatesP1(S_SPOS_RUN4, SPR_SPOS, 1, 3, @A_Chase, S_SPOS_RUN5, 0, 0);
  Set_StatesP1(S_SPOS_RUN5, SPR_SPOS, 2, 3, @A_Chase, S_SPOS_RUN6, 0, 0);
  Set_StatesP1(S_SPOS_RUN6, SPR_SPOS, 2, 3, @A_Chase, S_SPOS_RUN7, 0, 0);
  Set_StatesP1(S_SPOS_RUN7, SPR_SPOS, 3, 3, @A_Chase, S_SPOS_RUN8, 0, 0);
  Set_StatesP1(S_SPOS_RUN8, SPR_SPOS, 3, 3, @A_Chase, S_SPOS_RUN1, 0, 0);
  Set_StatesP1(S_SPOS_ATK1, SPR_SPOS, 4, 10, @A_FaceTarget, S_SPOS_ATK2, 0, 0);
  Set_StatesP1(S_SPOS_ATK2, SPR_SPOS, 32773, 10, @A_SPosAttack, S_SPOS_ATK3, 0, 0);
  Set_States(S_SPOS_ATK3, SPR_SPOS, 4, 10, Nil, S_SPOS_RUN1, 0, 0);
  Set_States(S_SPOS_PAIN, SPR_SPOS, 6, 3, Nil, S_SPOS_PAIN2, 0, 0);
  Set_StatesP1(S_SPOS_PAIN2, SPR_SPOS, 6, 3, @A_Pain, S_SPOS_RUN1, 0, 0);
  Set_States(S_SPOS_DIE1, SPR_SPOS, 7, 5, Nil, S_SPOS_DIE2, 0, 0);
  Set_StatesP1(S_SPOS_DIE2, SPR_SPOS, 8, 5, @A_Scream, S_SPOS_DIE3, 0, 0);
  Set_StatesP1(S_SPOS_DIE3, SPR_SPOS, 9, 5, @A_Fall, S_SPOS_DIE4, 0, 0);
  Set_States(S_SPOS_DIE4, SPR_SPOS, 10, 5, Nil, S_SPOS_DIE5, 0, 0);
  Set_States(S_SPOS_DIE5, SPR_SPOS, 11, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SPOS_XDIE1, SPR_SPOS, 12, 5, Nil, S_SPOS_XDIE2, 0, 0);
  Set_StatesP1(S_SPOS_XDIE2, SPR_SPOS, 13, 5, @A_XScream, S_SPOS_XDIE3, 0, 0);
  Set_StatesP1(S_SPOS_XDIE3, SPR_SPOS, 14, 5, @A_Fall, S_SPOS_XDIE4, 0, 0);
  Set_States(S_SPOS_XDIE4, SPR_SPOS, 15, 5, Nil, S_SPOS_XDIE5, 0, 0);
  Set_States(S_SPOS_XDIE5, SPR_SPOS, 16, 5, Nil, S_SPOS_XDIE6, 0, 0);
  Set_States(S_SPOS_XDIE6, SPR_SPOS, 17, 5, Nil, S_SPOS_XDIE7, 0, 0);
  Set_States(S_SPOS_XDIE7, SPR_SPOS, 18, 5, Nil, S_SPOS_XDIE8, 0, 0);
  Set_States(S_SPOS_XDIE8, SPR_SPOS, 19, 5, Nil, S_SPOS_XDIE9, 0, 0);
  Set_States(S_SPOS_XDIE9, SPR_SPOS, 20, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SPOS_RAISE1, SPR_SPOS, 11, 5, Nil, S_SPOS_RAISE2, 0, 0);
  Set_States(S_SPOS_RAISE2, SPR_SPOS, 10, 5, Nil, S_SPOS_RAISE3, 0, 0);
  Set_States(S_SPOS_RAISE3, SPR_SPOS, 9, 5, Nil, S_SPOS_RAISE4, 0, 0);
  Set_States(S_SPOS_RAISE4, SPR_SPOS, 8, 5, Nil, S_SPOS_RAISE5, 0, 0);
  Set_States(S_SPOS_RAISE5, SPR_SPOS, 7, 5, Nil, S_SPOS_RUN1, 0, 0);
  Set_StatesP1(S_VILE_STND, SPR_VILE, 0, 10, @A_Look, S_VILE_STND2, 0, 0);
  Set_StatesP1(S_VILE_STND2, SPR_VILE, 1, 10, @A_Look, S_VILE_STND, 0, 0);
  Set_StatesP1(S_VILE_RUN1, SPR_VILE, 0, 2, @A_VileChase, S_VILE_RUN2, 0, 0);
  Set_StatesP1(S_VILE_RUN2, SPR_VILE, 0, 2, @A_VileChase, S_VILE_RUN3, 0, 0);
  Set_StatesP1(S_VILE_RUN3, SPR_VILE, 1, 2, @A_VileChase, S_VILE_RUN4, 0, 0);
  Set_StatesP1(S_VILE_RUN4, SPR_VILE, 1, 2, @A_VileChase, S_VILE_RUN5, 0, 0);
  Set_StatesP1(S_VILE_RUN5, SPR_VILE, 2, 2, @A_VileChase, S_VILE_RUN6, 0, 0);
  Set_StatesP1(S_VILE_RUN6, SPR_VILE, 2, 2, @A_VileChase, S_VILE_RUN7, 0, 0);
  Set_StatesP1(S_VILE_RUN7, SPR_VILE, 3, 2, @A_VileChase, S_VILE_RUN8, 0, 0);
  Set_StatesP1(S_VILE_RUN8, SPR_VILE, 3, 2, @A_VileChase, S_VILE_RUN9, 0, 0);
  Set_StatesP1(S_VILE_RUN9, SPR_VILE, 4, 2, @A_VileChase, S_VILE_RUN10, 0, 0);
  Set_StatesP1(S_VILE_RUN10, SPR_VILE, 4, 2, @A_VileChase, S_VILE_RUN11, 0, 0);
  Set_StatesP1(S_VILE_RUN11, SPR_VILE, 5, 2, @A_VileChase, S_VILE_RUN12, 0, 0);
  Set_StatesP1(S_VILE_RUN12, SPR_VILE, 5, 2, @A_VileChase, S_VILE_RUN1, 0, 0);
  Set_StatesP1(S_VILE_ATK1, SPR_VILE, 32774, 0, @A_VileStart, S_VILE_ATK2, 0, 0);
  Set_StatesP1(S_VILE_ATK2, SPR_VILE, 32774, 10, @A_FaceTarget, S_VILE_ATK3, 0, 0);
  Set_StatesP1(S_VILE_ATK3, SPR_VILE, 32775, 8, @A_VileTarget, S_VILE_ATK4, 0, 0);
  Set_StatesP1(S_VILE_ATK4, SPR_VILE, 32776, 8, @A_FaceTarget, S_VILE_ATK5, 0, 0);
  Set_StatesP1(S_VILE_ATK5, SPR_VILE, 32777, 8, @A_FaceTarget, S_VILE_ATK6, 0, 0);
  Set_StatesP1(S_VILE_ATK6, SPR_VILE, 32778, 8, @A_FaceTarget, S_VILE_ATK7, 0, 0);
  Set_StatesP1(S_VILE_ATK7, SPR_VILE, 32779, 8, @A_FaceTarget, S_VILE_ATK8, 0, 0);
  Set_StatesP1(S_VILE_ATK8, SPR_VILE, 32780, 8, @A_FaceTarget, S_VILE_ATK9, 0, 0);
  Set_StatesP1(S_VILE_ATK9, SPR_VILE, 32781, 8, @A_FaceTarget, S_VILE_ATK10, 0, 0);
  Set_StatesP1(S_VILE_ATK10, SPR_VILE, 32782, 8, @A_VileAttack, S_VILE_ATK11, 0, 0);
  Set_States(S_VILE_ATK11, SPR_VILE, 32783, 20, Nil, S_VILE_RUN1, 0, 0);
  Set_States(S_VILE_HEAL1, SPR_VILE, 32794, 10, Nil, S_VILE_HEAL2, 0, 0);
  Set_States(S_VILE_HEAL2, SPR_VILE, 32795, 10, Nil, S_VILE_HEAL3, 0, 0);
  Set_States(S_VILE_HEAL3, SPR_VILE, 32796, 10, Nil, S_VILE_RUN1, 0, 0);
  Set_States(S_VILE_PAIN, SPR_VILE, 16, 5, Nil, S_VILE_PAIN2, 0, 0);
  Set_StatesP1(S_VILE_PAIN2, SPR_VILE, 16, 5, @A_Pain, S_VILE_RUN1, 0, 0);
  Set_States(S_VILE_DIE1, SPR_VILE, 16, 7, Nil, S_VILE_DIE2, 0, 0);
  Set_StatesP1(S_VILE_DIE2, SPR_VILE, 17, 7, @A_Scream, S_VILE_DIE3, 0, 0);
  Set_StatesP1(S_VILE_DIE3, SPR_VILE, 18, 7, @A_Fall, S_VILE_DIE4, 0, 0);
  Set_States(S_VILE_DIE4, SPR_VILE, 19, 7, Nil, S_VILE_DIE5, 0, 0);
  Set_States(S_VILE_DIE5, SPR_VILE, 20, 7, Nil, S_VILE_DIE6, 0, 0);
  Set_States(S_VILE_DIE6, SPR_VILE, 21, 7, Nil, S_VILE_DIE7, 0, 0);
  Set_States(S_VILE_DIE7, SPR_VILE, 22, 7, Nil, S_VILE_DIE8, 0, 0);
  Set_States(S_VILE_DIE8, SPR_VILE, 23, 5, Nil, S_VILE_DIE9, 0, 0);
  Set_States(S_VILE_DIE9, SPR_VILE, 24, 5, Nil, S_VILE_DIE10, 0, 0);
  Set_States(S_VILE_DIE10, SPR_VILE, 25, -1, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_FIRE1, SPR_FIRE, 32768, 2, @A_StartFire, S_FIRE2, 0, 0);
  Set_StatesP1(S_FIRE2, SPR_FIRE, 32769, 2, @A_Fire, S_FIRE3, 0, 0);
  Set_StatesP1(S_FIRE3, SPR_FIRE, 32768, 2, @A_Fire, S_FIRE4, 0, 0);
  Set_StatesP1(S_FIRE4, SPR_FIRE, 32769, 2, @A_Fire, S_FIRE5, 0, 0);
  Set_StatesP1(S_FIRE5, SPR_FIRE, 32770, 2, @A_FireCrackle, S_FIRE6, 0, 0);
  Set_StatesP1(S_FIRE6, SPR_FIRE, 32769, 2, @A_Fire, S_FIRE7, 0, 0);
  Set_StatesP1(S_FIRE7, SPR_FIRE, 32770, 2, @A_Fire, S_FIRE8, 0, 0);
  Set_StatesP1(S_FIRE8, SPR_FIRE, 32769, 2, @A_Fire, S_FIRE9, 0, 0);
  Set_StatesP1(S_FIRE9, SPR_FIRE, 32770, 2, @A_Fire, S_FIRE10, 0, 0);
  Set_StatesP1(S_FIRE10, SPR_FIRE, 32771, 2, @A_Fire, S_FIRE11, 0, 0);
  Set_StatesP1(S_FIRE11, SPR_FIRE, 32770, 2, @A_Fire, S_FIRE12, 0, 0);
  Set_StatesP1(S_FIRE12, SPR_FIRE, 32771, 2, @A_Fire, S_FIRE13, 0, 0);
  Set_StatesP1(S_FIRE13, SPR_FIRE, 32770, 2, @A_Fire, S_FIRE14, 0, 0);
  Set_StatesP1(S_FIRE14, SPR_FIRE, 32771, 2, @A_Fire, S_FIRE15, 0, 0);
  Set_StatesP1(S_FIRE15, SPR_FIRE, 32772, 2, @A_Fire, S_FIRE16, 0, 0);
  Set_StatesP1(S_FIRE16, SPR_FIRE, 32771, 2, @A_Fire, S_FIRE17, 0, 0);
  Set_StatesP1(S_FIRE17, SPR_FIRE, 32772, 2, @A_Fire, S_FIRE18, 0, 0);
  Set_StatesP1(S_FIRE18, SPR_FIRE, 32771, 2, @A_Fire, S_FIRE19, 0, 0);
  Set_StatesP1(S_FIRE19, SPR_FIRE, 32772, 2, @A_FireCrackle, S_FIRE20, 0, 0);
  Set_StatesP1(S_FIRE20, SPR_FIRE, 32773, 2, @A_Fire, S_FIRE21, 0, 0);
  Set_StatesP1(S_FIRE21, SPR_FIRE, 32772, 2, @A_Fire, S_FIRE22, 0, 0);
  Set_StatesP1(S_FIRE22, SPR_FIRE, 32773, 2, @A_Fire, S_FIRE23, 0, 0);
  Set_StatesP1(S_FIRE23, SPR_FIRE, 32772, 2, @A_Fire, S_FIRE24, 0, 0);
  Set_StatesP1(S_FIRE24, SPR_FIRE, 32773, 2, @A_Fire, S_FIRE25, 0, 0);
  Set_StatesP1(S_FIRE25, SPR_FIRE, 32774, 2, @A_Fire, S_FIRE26, 0, 0);
  Set_StatesP1(S_FIRE26, SPR_FIRE, 32775, 2, @A_Fire, S_FIRE27, 0, 0);
  Set_StatesP1(S_FIRE27, SPR_FIRE, 32774, 2, @A_Fire, S_FIRE28, 0, 0);
  Set_StatesP1(S_FIRE28, SPR_FIRE, 32775, 2, @A_Fire, S_FIRE29, 0, 0);
  Set_StatesP1(S_FIRE29, SPR_FIRE, 32774, 2, @A_Fire, S_FIRE30, 0, 0);
  Set_StatesP1(S_FIRE30, SPR_FIRE, 32775, 2, @A_Fire, S_NULL, 0, 0);
  Set_States(S_SMOKE1, SPR_PUFF, 1, 4, Nil, S_SMOKE2, 0, 0);
  Set_States(S_SMOKE2, SPR_PUFF, 2, 4, Nil, S_SMOKE3, 0, 0);
  Set_States(S_SMOKE3, SPR_PUFF, 1, 4, Nil, S_SMOKE4, 0, 0);
  Set_States(S_SMOKE4, SPR_PUFF, 2, 4, Nil, S_SMOKE5, 0, 0);
  Set_States(S_SMOKE5, SPR_PUFF, 3, 4, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_TRACER, SPR_FATB, 32768, 2, @A_Tracer, S_TRACER2, 0, 0);
  Set_StatesP1(S_TRACER2, SPR_FATB, 32769, 2, @A_Tracer, S_TRACER, 0, 0);
  Set_States(S_TRACEEXP1, SPR_FBXP, 32768, 8, Nil, S_TRACEEXP2, 0, 0);
  Set_States(S_TRACEEXP2, SPR_FBXP, 32769, 6, Nil, S_TRACEEXP3, 0, 0);
  Set_States(S_TRACEEXP3, SPR_FBXP, 32770, 4, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_SKEL_STND, SPR_SKEL, 0, 10, @A_Look, S_SKEL_STND2, 0, 0);
  Set_StatesP1(S_SKEL_STND2, SPR_SKEL, 1, 10, @A_Look, S_SKEL_STND, 0, 0);
  Set_StatesP1(S_SKEL_RUN1, SPR_SKEL, 0, 2, @A_Chase, S_SKEL_RUN2, 0, 0);
  Set_StatesP1(S_SKEL_RUN2, SPR_SKEL, 0, 2, @A_Chase, S_SKEL_RUN3, 0, 0);
  Set_StatesP1(S_SKEL_RUN3, SPR_SKEL, 1, 2, @A_Chase, S_SKEL_RUN4, 0, 0);
  Set_StatesP1(S_SKEL_RUN4, SPR_SKEL, 1, 2, @A_Chase, S_SKEL_RUN5, 0, 0);
  Set_StatesP1(S_SKEL_RUN5, SPR_SKEL, 2, 2, @A_Chase, S_SKEL_RUN6, 0, 0);
  Set_StatesP1(S_SKEL_RUN6, SPR_SKEL, 2, 2, @A_Chase, S_SKEL_RUN7, 0, 0);
  Set_StatesP1(S_SKEL_RUN7, SPR_SKEL, 3, 2, @A_Chase, S_SKEL_RUN8, 0, 0);
  Set_StatesP1(S_SKEL_RUN8, SPR_SKEL, 3, 2, @A_Chase, S_SKEL_RUN9, 0, 0);
  Set_StatesP1(S_SKEL_RUN9, SPR_SKEL, 4, 2, @A_Chase, S_SKEL_RUN10, 0, 0);
  Set_StatesP1(S_SKEL_RUN10, SPR_SKEL, 4, 2, @A_Chase, S_SKEL_RUN11, 0, 0);
  Set_StatesP1(S_SKEL_RUN11, SPR_SKEL, 5, 2, @A_Chase, S_SKEL_RUN12, 0, 0);
  Set_StatesP1(S_SKEL_RUN12, SPR_SKEL, 5, 2, @A_Chase, S_SKEL_RUN1, 0, 0);
  Set_StatesP1(S_SKEL_FIST1, SPR_SKEL, 6, 0, @A_FaceTarget, S_SKEL_FIST2, 0, 0);
  Set_StatesP1(S_SKEL_FIST2, SPR_SKEL, 6, 6, @A_SkelWhoosh, S_SKEL_FIST3, 0, 0);
  Set_StatesP1(S_SKEL_FIST3, SPR_SKEL, 7, 6, @A_FaceTarget, S_SKEL_FIST4, 0, 0);
  Set_StatesP1(S_SKEL_FIST4, SPR_SKEL, 8, 6, @A_SkelFist, S_SKEL_RUN1, 0, 0);
  Set_StatesP1(S_SKEL_MISS1, SPR_SKEL, 32777, 0, @A_FaceTarget, S_SKEL_MISS2, 0, 0);
  Set_StatesP1(S_SKEL_MISS2, SPR_SKEL, 32777, 10, @A_FaceTarget, S_SKEL_MISS3, 0, 0);
  Set_StatesP1(S_SKEL_MISS3, SPR_SKEL, 10, 10, @A_SkelMissile, S_SKEL_MISS4, 0, 0);
  Set_StatesP1(S_SKEL_MISS4, SPR_SKEL, 10, 10, @A_FaceTarget, S_SKEL_RUN1, 0, 0);
  Set_States(S_SKEL_PAIN, SPR_SKEL, 11, 5, Nil, S_SKEL_PAIN2, 0, 0);
  Set_StatesP1(S_SKEL_PAIN2, SPR_SKEL, 11, 5, @A_Pain, S_SKEL_RUN1, 0, 0);
  Set_States(S_SKEL_DIE1, SPR_SKEL, 11, 7, Nil, S_SKEL_DIE2, 0, 0);
  Set_States(S_SKEL_DIE2, SPR_SKEL, 12, 7, Nil, S_SKEL_DIE3, 0, 0);
  Set_StatesP1(S_SKEL_DIE3, SPR_SKEL, 13, 7, @A_Scream, S_SKEL_DIE4, 0, 0);
  Set_StatesP1(S_SKEL_DIE4, SPR_SKEL, 14, 7, @A_Fall, S_SKEL_DIE5, 0, 0);
  Set_States(S_SKEL_DIE5, SPR_SKEL, 15, 7, Nil, S_SKEL_DIE6, 0, 0);
  Set_States(S_SKEL_DIE6, SPR_SKEL, 16, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SKEL_RAISE1, SPR_SKEL, 16, 5, Nil, S_SKEL_RAISE2, 0, 0);
  Set_States(S_SKEL_RAISE2, SPR_SKEL, 15, 5, Nil, S_SKEL_RAISE3, 0, 0);
  Set_States(S_SKEL_RAISE3, SPR_SKEL, 14, 5, Nil, S_SKEL_RAISE4, 0, 0);
  Set_States(S_SKEL_RAISE4, SPR_SKEL, 13, 5, Nil, S_SKEL_RAISE5, 0, 0);
  Set_States(S_SKEL_RAISE5, SPR_SKEL, 12, 5, Nil, S_SKEL_RAISE6, 0, 0);
  Set_States(S_SKEL_RAISE6, SPR_SKEL, 11, 5, Nil, S_SKEL_RUN1, 0, 0);
  Set_States(S_FATSHOT1, SPR_MANF, 32768, 4, Nil, S_FATSHOT2, 0, 0);
  Set_States(S_FATSHOT2, SPR_MANF, 32769, 4, Nil, S_FATSHOT1, 0, 0);
  Set_States(S_FATSHOTX1, SPR_MISL, 32769, 8, Nil, S_FATSHOTX2, 0, 0);
  Set_States(S_FATSHOTX2, SPR_MISL, 32770, 6, Nil, S_FATSHOTX3, 0, 0);
  Set_States(S_FATSHOTX3, SPR_MISL, 32771, 4, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_FATT_STND, SPR_FATT, 0, 15, @A_Look, S_FATT_STND2, 0, 0);
  Set_StatesP1(S_FATT_STND2, SPR_FATT, 1, 15, @A_Look, S_FATT_STND, 0, 0);
  Set_StatesP1(S_FATT_RUN1, SPR_FATT, 0, 4, @A_Chase, S_FATT_RUN2, 0, 0);
  Set_StatesP1(S_FATT_RUN2, SPR_FATT, 0, 4, @A_Chase, S_FATT_RUN3, 0, 0);
  Set_StatesP1(S_FATT_RUN3, SPR_FATT, 1, 4, @A_Chase, S_FATT_RUN4, 0, 0);
  Set_StatesP1(S_FATT_RUN4, SPR_FATT, 1, 4, @A_Chase, S_FATT_RUN5, 0, 0);
  Set_StatesP1(S_FATT_RUN5, SPR_FATT, 2, 4, @A_Chase, S_FATT_RUN6, 0, 0);
  Set_StatesP1(S_FATT_RUN6, SPR_FATT, 2, 4, @A_Chase, S_FATT_RUN7, 0, 0);
  Set_StatesP1(S_FATT_RUN7, SPR_FATT, 3, 4, @A_Chase, S_FATT_RUN8, 0, 0);
  Set_StatesP1(S_FATT_RUN8, SPR_FATT, 3, 4, @A_Chase, S_FATT_RUN9, 0, 0);
  Set_StatesP1(S_FATT_RUN9, SPR_FATT, 4, 4, @A_Chase, S_FATT_RUN10, 0, 0);
  Set_StatesP1(S_FATT_RUN10, SPR_FATT, 4, 4, @A_Chase, S_FATT_RUN11, 0, 0);
  Set_StatesP1(S_FATT_RUN11, SPR_FATT, 5, 4, @A_Chase, S_FATT_RUN12, 0, 0);
  Set_StatesP1(S_FATT_RUN12, SPR_FATT, 5, 4, @A_Chase, S_FATT_RUN1, 0, 0);
  Set_StatesP1(S_FATT_ATK1, SPR_FATT, 6, 20, @A_FatRaise, S_FATT_ATK2, 0, 0);
  Set_StatesP1(S_FATT_ATK2, SPR_FATT, 32775, 10, @A_FatAttack1, S_FATT_ATK3, 0, 0);
  Set_StatesP1(S_FATT_ATK3, SPR_FATT, 8, 5, @A_FaceTarget, S_FATT_ATK4, 0, 0);
  Set_StatesP1(S_FATT_ATK4, SPR_FATT, 6, 5, @A_FaceTarget, S_FATT_ATK5, 0, 0);
  Set_StatesP1(S_FATT_ATK5, SPR_FATT, 32775, 10, @A_FatAttack2, S_FATT_ATK6, 0, 0);
  Set_StatesP1(S_FATT_ATK6, SPR_FATT, 8, 5, @A_FaceTarget, S_FATT_ATK7, 0, 0);
  Set_StatesP1(S_FATT_ATK7, SPR_FATT, 6, 5, @A_FaceTarget, S_FATT_ATK8, 0, 0);
  Set_StatesP1(S_FATT_ATK8, SPR_FATT, 32775, 10, @A_FatAttack3, S_FATT_ATK9, 0, 0);
  Set_StatesP1(S_FATT_ATK9, SPR_FATT, 8, 5, @A_FaceTarget, S_FATT_ATK10, 0, 0);
  Set_StatesP1(S_FATT_ATK10, SPR_FATT, 6, 5, @A_FaceTarget, S_FATT_RUN1, 0, 0);
  Set_States(S_FATT_PAIN, SPR_FATT, 9, 3, Nil, S_FATT_PAIN2, 0, 0);
  Set_StatesP1(S_FATT_PAIN2, SPR_FATT, 9, 3, @A_Pain, S_FATT_RUN1, 0, 0);
  Set_States(S_FATT_DIE1, SPR_FATT, 10, 6, Nil, S_FATT_DIE2, 0, 0);
  Set_StatesP1(S_FATT_DIE2, SPR_FATT, 11, 6, @A_Scream, S_FATT_DIE3, 0, 0);
  Set_StatesP1(S_FATT_DIE3, SPR_FATT, 12, 6, @A_Fall, S_FATT_DIE4, 0, 0);
  Set_States(S_FATT_DIE4, SPR_FATT, 13, 6, Nil, S_FATT_DIE5, 0, 0);
  Set_States(S_FATT_DIE5, SPR_FATT, 14, 6, Nil, S_FATT_DIE6, 0, 0);
  Set_States(S_FATT_DIE6, SPR_FATT, 15, 6, Nil, S_FATT_DIE7, 0, 0);
  Set_States(S_FATT_DIE7, SPR_FATT, 16, 6, Nil, S_FATT_DIE8, 0, 0);
  Set_States(S_FATT_DIE8, SPR_FATT, 17, 6, Nil, S_FATT_DIE9, 0, 0);
  Set_States(S_FATT_DIE9, SPR_FATT, 18, 6, Nil, S_FATT_DIE10, 0, 0);
  Set_StatesP1(S_FATT_DIE10, SPR_FATT, 19, -1, @A_BossDeath, S_NULL, 0, 0);
  Set_States(S_FATT_RAISE1, SPR_FATT, 17, 5, Nil, S_FATT_RAISE2, 0, 0);
  Set_States(S_FATT_RAISE2, SPR_FATT, 16, 5, Nil, S_FATT_RAISE3, 0, 0);
  Set_States(S_FATT_RAISE3, SPR_FATT, 15, 5, Nil, S_FATT_RAISE4, 0, 0);
  Set_States(S_FATT_RAISE4, SPR_FATT, 14, 5, Nil, S_FATT_RAISE5, 0, 0);
  Set_States(S_FATT_RAISE5, SPR_FATT, 13, 5, Nil, S_FATT_RAISE6, 0, 0);
  Set_States(S_FATT_RAISE6, SPR_FATT, 12, 5, Nil, S_FATT_RAISE7, 0, 0);
  Set_States(S_FATT_RAISE7, SPR_FATT, 11, 5, Nil, S_FATT_RAISE8, 0, 0);
  Set_States(S_FATT_RAISE8, SPR_FATT, 10, 5, Nil, S_FATT_RUN1, 0, 0);
  Set_StatesP1(S_CPOS_STND, SPR_CPOS, 0, 10, @A_Look, S_CPOS_STND2, 0, 0);
  Set_StatesP1(S_CPOS_STND2, SPR_CPOS, 1, 10, @A_Look, S_CPOS_STND, 0, 0);
  Set_StatesP1(S_CPOS_RUN1, SPR_CPOS, 0, 3, @A_Chase, S_CPOS_RUN2, 0, 0);
  Set_StatesP1(S_CPOS_RUN2, SPR_CPOS, 0, 3, @A_Chase, S_CPOS_RUN3, 0, 0);
  Set_StatesP1(S_CPOS_RUN3, SPR_CPOS, 1, 3, @A_Chase, S_CPOS_RUN4, 0, 0);
  Set_StatesP1(S_CPOS_RUN4, SPR_CPOS, 1, 3, @A_Chase, S_CPOS_RUN5, 0, 0);
  Set_StatesP1(S_CPOS_RUN5, SPR_CPOS, 2, 3, @A_Chase, S_CPOS_RUN6, 0, 0);
  Set_StatesP1(S_CPOS_RUN6, SPR_CPOS, 2, 3, @A_Chase, S_CPOS_RUN7, 0, 0);
  Set_StatesP1(S_CPOS_RUN7, SPR_CPOS, 3, 3, @A_Chase, S_CPOS_RUN8, 0, 0);
  Set_StatesP1(S_CPOS_RUN8, SPR_CPOS, 3, 3, @A_Chase, S_CPOS_RUN1, 0, 0);
  Set_StatesP1(S_CPOS_ATK1, SPR_CPOS, 4, 10, @A_FaceTarget, S_CPOS_ATK2, 0, 0);
  Set_StatesP1(S_CPOS_ATK2, SPR_CPOS, 32773, 4, @A_CPosAttack, S_CPOS_ATK3, 0, 0);
  Set_StatesP1(S_CPOS_ATK3, SPR_CPOS, 32772, 4, @A_CPosAttack, S_CPOS_ATK4, 0, 0);
  // [crispy] render Minigun zombie's firing frames full-bright
  Set_StatesP1(S_CPOS_ATK4, SPR_CPOS, 5 Or $8000, 1, @A_CPosRefire, S_CPOS_ATK2, 0, 0);
  Set_States(S_CPOS_PAIN, SPR_CPOS, 6, 3, Nil, S_CPOS_PAIN2, 0, 0);
  Set_StatesP1(S_CPOS_PAIN2, SPR_CPOS, 6, 3, @A_Pain, S_CPOS_RUN1, 0, 0);
  Set_States(S_CPOS_DIE1, SPR_CPOS, 7, 5, Nil, S_CPOS_DIE2, 0, 0);
  Set_StatesP1(S_CPOS_DIE2, SPR_CPOS, 8, 5, @A_Scream, S_CPOS_DIE3, 0, 0);
  Set_StatesP1(S_CPOS_DIE3, SPR_CPOS, 9, 5, @A_Fall, S_CPOS_DIE4, 0, 0);
  Set_States(S_CPOS_DIE4, SPR_CPOS, 10, 5, Nil, S_CPOS_DIE5, 0, 0);
  Set_States(S_CPOS_DIE5, SPR_CPOS, 11, 5, Nil, S_CPOS_DIE6, 0, 0);
  Set_States(S_CPOS_DIE6, SPR_CPOS, 12, 5, Nil, S_CPOS_DIE7, 0, 0);
  Set_States(S_CPOS_DIE7, SPR_CPOS, 13, -1, Nil, S_NULL, 0, 0);
  Set_States(S_CPOS_XDIE1, SPR_CPOS, 14, 5, Nil, S_CPOS_XDIE2, 0, 0);
  Set_StatesP1(S_CPOS_XDIE2, SPR_CPOS, 15, 5, @A_XScream, S_CPOS_XDIE3, 0, 0);
  Set_StatesP1(S_CPOS_XDIE3, SPR_CPOS, 16, 5, @A_Fall, S_CPOS_XDIE4, 0, 0);
  Set_States(S_CPOS_XDIE4, SPR_CPOS, 17, 5, Nil, S_CPOS_XDIE5, 0, 0);
  Set_States(S_CPOS_XDIE5, SPR_CPOS, 18, 5, Nil, S_CPOS_XDIE6, 0, 0);
  Set_States(S_CPOS_XDIE6, SPR_CPOS, 19, -1, Nil, S_NULL, 0, 0);
  Set_States(S_CPOS_RAISE1, SPR_CPOS, 13, 5, Nil, S_CPOS_RAISE2, 0, 0);
  Set_States(S_CPOS_RAISE2, SPR_CPOS, 12, 5, Nil, S_CPOS_RAISE3, 0, 0);
  Set_States(S_CPOS_RAISE3, SPR_CPOS, 11, 5, Nil, S_CPOS_RAISE4, 0, 0);
  Set_States(S_CPOS_RAISE4, SPR_CPOS, 10, 5, Nil, S_CPOS_RAISE5, 0, 0);
  Set_States(S_CPOS_RAISE5, SPR_CPOS, 9, 5, Nil, S_CPOS_RAISE6, 0, 0);
  Set_States(S_CPOS_RAISE6, SPR_CPOS, 8, 5, Nil, S_CPOS_RAISE7, 0, 0);
  Set_States(S_CPOS_RAISE7, SPR_CPOS, 7, 5, Nil, S_CPOS_RUN1, 0, 0);
  Set_StatesP1(S_TROO_STND, SPR_TROO, 0, 10, @A_Look, S_TROO_STND2, 0, 0);
  Set_StatesP1(S_TROO_STND2, SPR_TROO, 1, 10, @A_Look, S_TROO_STND, 0, 0);
  Set_StatesP1(S_TROO_RUN1, SPR_TROO, 0, 3, @A_Chase, S_TROO_RUN2, 0, 0);
  Set_StatesP1(S_TROO_RUN2, SPR_TROO, 0, 3, @A_Chase, S_TROO_RUN3, 0, 0);
  Set_StatesP1(S_TROO_RUN3, SPR_TROO, 1, 3, @A_Chase, S_TROO_RUN4, 0, 0);
  Set_StatesP1(S_TROO_RUN4, SPR_TROO, 1, 3, @A_Chase, S_TROO_RUN5, 0, 0);
  Set_StatesP1(S_TROO_RUN5, SPR_TROO, 2, 3, @A_Chase, S_TROO_RUN6, 0, 0);
  Set_StatesP1(S_TROO_RUN6, SPR_TROO, 2, 3, @A_Chase, S_TROO_RUN7, 0, 0);
  Set_StatesP1(S_TROO_RUN7, SPR_TROO, 3, 3, @A_Chase, S_TROO_RUN8, 0, 0);
  Set_StatesP1(S_TROO_RUN8, SPR_TROO, 3, 3, @A_Chase, S_TROO_RUN1, 0, 0);
  Set_StatesP1(S_TROO_ATK1, SPR_TROO, 4, 8, @A_FaceTarget, S_TROO_ATK2, 0, 0);
  Set_StatesP1(S_TROO_ATK2, SPR_TROO, 5, 8, @A_FaceTarget, S_TROO_ATK3, 0, 0);
  Set_StatesP1(S_TROO_ATK3, SPR_TROO, 6, 6, @A_TroopAttack, S_TROO_RUN1, 0, 0);
  Set_States(S_TROO_PAIN, SPR_TROO, 7, 2, Nil, S_TROO_PAIN2, 0, 0);
  Set_StatesP1(S_TROO_PAIN2, SPR_TROO, 7, 2, @A_Pain, S_TROO_RUN1, 0, 0);
  Set_States(S_TROO_DIE1, SPR_TROO, 8, 8, Nil, S_TROO_DIE2, 0, 0);
  Set_StatesP1(S_TROO_DIE2, SPR_TROO, 9, 8, @A_Scream, S_TROO_DIE3, 0, 0);
  Set_States(S_TROO_DIE3, SPR_TROO, 10, 6, Nil, S_TROO_DIE4, 0, 0);
  Set_StatesP1(S_TROO_DIE4, SPR_TROO, 11, 6, @A_Fall, S_TROO_DIE5, 0, 0);
  Set_States(S_TROO_DIE5, SPR_TROO, 12, -1, Nil, S_NULL, 0, 0);
  Set_States(S_TROO_XDIE1, SPR_TROO, 13, 5, Nil, S_TROO_XDIE2, 0, 0);
  Set_StatesP1(S_TROO_XDIE2, SPR_TROO, 14, 5, @A_XScream, S_TROO_XDIE3, 0, 0);
  Set_States(S_TROO_XDIE3, SPR_TROO, 15, 5, Nil, S_TROO_XDIE4, 0, 0);
  Set_StatesP1(S_TROO_XDIE4, SPR_TROO, 16, 5, @A_Fall, S_TROO_XDIE5, 0, 0);
  Set_States(S_TROO_XDIE5, SPR_TROO, 17, 5, Nil, S_TROO_XDIE6, 0, 0);
  Set_States(S_TROO_XDIE6, SPR_TROO, 18, 5, Nil, S_TROO_XDIE7, 0, 0);
  Set_States(S_TROO_XDIE7, SPR_TROO, 19, 5, Nil, S_TROO_XDIE8, 0, 0);
  Set_States(S_TROO_XDIE8, SPR_TROO, 20, -1, Nil, S_NULL, 0, 0);
  Set_States(S_TROO_RAISE1, SPR_TROO, 12, 8, Nil, S_TROO_RAISE2, 0, 0);
  Set_States(S_TROO_RAISE2, SPR_TROO, 11, 8, Nil, S_TROO_RAISE3, 0, 0);
  Set_States(S_TROO_RAISE3, SPR_TROO, 10, 6, Nil, S_TROO_RAISE4, 0, 0);
  Set_States(S_TROO_RAISE4, SPR_TROO, 9, 6, Nil, S_TROO_RAISE5, 0, 0);
  Set_States(S_TROO_RAISE5, SPR_TROO, 8, 6, Nil, S_TROO_RUN1, 0, 0);
  Set_StatesP1(S_SARG_STND, SPR_SARG, 0, 10, @A_Look, S_SARG_STND2, 0, 0);
  Set_StatesP1(S_SARG_STND2, SPR_SARG, 1, 10, @A_Look, S_SARG_STND, 0, 0);
  Set_StatesP1(S_SARG_RUN1, SPR_SARG, 0, 2, @A_Chase, S_SARG_RUN2, 0, 0);
  Set_StatesP1(S_SARG_RUN2, SPR_SARG, 0, 2, @A_Chase, S_SARG_RUN3, 0, 0);
  Set_StatesP1(S_SARG_RUN3, SPR_SARG, 1, 2, @A_Chase, S_SARG_RUN4, 0, 0);
  Set_StatesP1(S_SARG_RUN4, SPR_SARG, 1, 2, @A_Chase, S_SARG_RUN5, 0, 0);
  Set_StatesP1(S_SARG_RUN5, SPR_SARG, 2, 2, @A_Chase, S_SARG_RUN6, 0, 0);
  Set_StatesP1(S_SARG_RUN6, SPR_SARG, 2, 2, @A_Chase, S_SARG_RUN7, 0, 0);
  Set_StatesP1(S_SARG_RUN7, SPR_SARG, 3, 2, @A_Chase, S_SARG_RUN8, 0, 0);
  Set_StatesP1(S_SARG_RUN8, SPR_SARG, 3, 2, @A_Chase, S_SARG_RUN1, 0, 0);
  Set_StatesP1(S_SARG_ATK1, SPR_SARG, 4, 8, @A_FaceTarget, S_SARG_ATK2, 0, 0);
  Set_StatesP1(S_SARG_ATK2, SPR_SARG, 5, 8, @A_FaceTarget, S_SARG_ATK3, 0, 0);
  Set_StatesP1(S_SARG_ATK3, SPR_SARG, 6, 8, @A_SargAttack, S_SARG_RUN1, 0, 0);
  Set_States(S_SARG_PAIN, SPR_SARG, 7, 2, Nil, S_SARG_PAIN2, 0, 0);
  Set_StatesP1(S_SARG_PAIN2, SPR_SARG, 7, 2, @A_Pain, S_SARG_RUN1, 0, 0);
  Set_States(S_SARG_DIE1, SPR_SARG, 8, 8, Nil, S_SARG_DIE2, 0, 0);
  Set_StatesP1(S_SARG_DIE2, SPR_SARG, 9, 8, @A_Scream, S_SARG_DIE3, 0, 0);
  Set_States(S_SARG_DIE3, SPR_SARG, 10, 4, Nil, S_SARG_DIE4, 0, 0);
  Set_StatesP1(S_SARG_DIE4, SPR_SARG, 11, 4, @A_Fall, S_SARG_DIE5, 0, 0);
  Set_States(S_SARG_DIE5, SPR_SARG, 12, 4, Nil, S_SARG_DIE6, 0, 0);
  Set_States(S_SARG_DIE6, SPR_SARG, 13, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SARG_RAISE1, SPR_SARG, 13, 5, Nil, S_SARG_RAISE2, 0, 0);
  Set_States(S_SARG_RAISE2, SPR_SARG, 12, 5, Nil, S_SARG_RAISE3, 0, 0);
  Set_States(S_SARG_RAISE3, SPR_SARG, 11, 5, Nil, S_SARG_RAISE4, 0, 0);
  Set_States(S_SARG_RAISE4, SPR_SARG, 10, 5, Nil, S_SARG_RAISE5, 0, 0);
  Set_States(S_SARG_RAISE5, SPR_SARG, 9, 5, Nil, S_SARG_RAISE6, 0, 0);
  Set_States(S_SARG_RAISE6, SPR_SARG, 8, 5, Nil, S_SARG_RUN1, 0, 0);
  Set_StatesP1(S_HEAD_STND, SPR_HEAD, 0, 10, @A_Look, S_HEAD_STND, 0, 0);
  Set_StatesP1(S_HEAD_RUN1, SPR_HEAD, 0, 3, @A_Chase, S_HEAD_RUN1, 0, 0);
  Set_StatesP1(S_HEAD_ATK1, SPR_HEAD, 1, 5, @A_FaceTarget, S_HEAD_ATK2, 0, 0);
  Set_StatesP1(S_HEAD_ATK2, SPR_HEAD, 2, 5, @A_FaceTarget, S_HEAD_ATK3, 0, 0);
  Set_StatesP1(S_HEAD_ATK3, SPR_HEAD, 32771, 5, @A_HeadAttack, S_HEAD_RUN1, 0, 0);
  Set_States(S_HEAD_PAIN, SPR_HEAD, 4, 3, Nil, S_HEAD_PAIN2, 0, 0);
  Set_StatesP1(S_HEAD_PAIN2, SPR_HEAD, 4, 3, @A_Pain, S_HEAD_PAIN3, 0, 0);
  Set_States(S_HEAD_PAIN3, SPR_HEAD, 5, 6, Nil, S_HEAD_RUN1, 0, 0);
  Set_States(S_HEAD_DIE1, SPR_HEAD, 6, 8, Nil, S_HEAD_DIE2, 0, 0);
  Set_StatesP1(S_HEAD_DIE2, SPR_HEAD, 7, 8, @A_Scream, S_HEAD_DIE3, 0, 0);
  Set_States(S_HEAD_DIE3, SPR_HEAD, 8, 8, Nil, S_HEAD_DIE4, 0, 0);
  Set_States(S_HEAD_DIE4, SPR_HEAD, 9, 8, Nil, S_HEAD_DIE5, 0, 0);
  Set_StatesP1(S_HEAD_DIE5, SPR_HEAD, 10, 8, @A_Fall, S_HEAD_DIE6, 0, 0);
  Set_States(S_HEAD_DIE6, SPR_HEAD, 11, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HEAD_RAISE1, SPR_HEAD, 11, 8, Nil, S_HEAD_RAISE2, 0, 0);
  Set_States(S_HEAD_RAISE2, SPR_HEAD, 10, 8, Nil, S_HEAD_RAISE3, 0, 0);
  Set_States(S_HEAD_RAISE3, SPR_HEAD, 9, 8, Nil, S_HEAD_RAISE4, 0, 0);
  Set_States(S_HEAD_RAISE4, SPR_HEAD, 8, 8, Nil, S_HEAD_RAISE5, 0, 0);
  Set_States(S_HEAD_RAISE5, SPR_HEAD, 7, 8, Nil, S_HEAD_RAISE6, 0, 0);
  Set_States(S_HEAD_RAISE6, SPR_HEAD, 6, 8, Nil, S_HEAD_RUN1, 0, 0);
  Set_States(S_BRBALL1, SPR_BAL7, 32768, 4, Nil, S_BRBALL2, 0, 0);
  Set_States(S_BRBALL2, SPR_BAL7, 32769, 4, Nil, S_BRBALL1, 0, 0);
  Set_States(S_BRBALLX1, SPR_BAL7, 32770, 6, Nil, S_BRBALLX2, 0, 0);
  Set_States(S_BRBALLX2, SPR_BAL7, 32771, 6, Nil, S_BRBALLX3, 0, 0);
  Set_States(S_BRBALLX3, SPR_BAL7, 32772, 6, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_BOSS_STND, SPR_BOSS, 0, 10, @A_Look, S_BOSS_STND2, 0, 0);
  Set_StatesP1(S_BOSS_STND2, SPR_BOSS, 1, 10, @A_Look, S_BOSS_STND, 0, 0);
  Set_StatesP1(S_BOSS_RUN1, SPR_BOSS, 0, 3, @A_Chase, S_BOSS_RUN2, 0, 0);
  Set_StatesP1(S_BOSS_RUN2, SPR_BOSS, 0, 3, @A_Chase, S_BOSS_RUN3, 0, 0);
  Set_StatesP1(S_BOSS_RUN3, SPR_BOSS, 1, 3, @A_Chase, S_BOSS_RUN4, 0, 0);
  Set_StatesP1(S_BOSS_RUN4, SPR_BOSS, 1, 3, @A_Chase, S_BOSS_RUN5, 0, 0);
  Set_StatesP1(S_BOSS_RUN5, SPR_BOSS, 2, 3, @A_Chase, S_BOSS_RUN6, 0, 0);
  Set_StatesP1(S_BOSS_RUN6, SPR_BOSS, 2, 3, @A_Chase, S_BOSS_RUN7, 0, 0);
  Set_StatesP1(S_BOSS_RUN7, SPR_BOSS, 3, 3, @A_Chase, S_BOSS_RUN8, 0, 0);
  Set_StatesP1(S_BOSS_RUN8, SPR_BOSS, 3, 3, @A_Chase, S_BOSS_RUN1, 0, 0);
  Set_StatesP1(S_BOSS_ATK1, SPR_BOSS, 4, 8, @A_FaceTarget, S_BOSS_ATK2, 0, 0);
  Set_StatesP1(S_BOSS_ATK2, SPR_BOSS, 5, 8, @A_FaceTarget, S_BOSS_ATK3, 0, 0);
  Set_StatesP1(S_BOSS_ATK3, SPR_BOSS, 6, 8, @A_BruisAttack, S_BOSS_RUN1, 0, 0);
  Set_States(S_BOSS_PAIN, SPR_BOSS, 7, 2, Nil, S_BOSS_PAIN2, 0, 0);
  Set_StatesP1(S_BOSS_PAIN2, SPR_BOSS, 7, 2, @A_Pain, S_BOSS_RUN1, 0, 0);
  Set_States(S_BOSS_DIE1, SPR_BOSS, 8, 8, Nil, S_BOSS_DIE2, 0, 0);
  Set_StatesP1(S_BOSS_DIE2, SPR_BOSS, 9, 8, @A_Scream, S_BOSS_DIE3, 0, 0);
  Set_States(S_BOSS_DIE3, SPR_BOSS, 10, 8, Nil, S_BOSS_DIE4, 0, 0);
  Set_StatesP1(S_BOSS_DIE4, SPR_BOSS, 11, 8, @A_Fall, S_BOSS_DIE5, 0, 0);
  Set_States(S_BOSS_DIE5, SPR_BOSS, 12, 8, Nil, S_BOSS_DIE6, 0, 0);
  Set_States(S_BOSS_DIE6, SPR_BOSS, 13, 8, Nil, S_BOSS_DIE7, 0, 0);
  Set_StatesP1(S_BOSS_DIE7, SPR_BOSS, 14, -1, @A_BossDeath, S_NULL, 0, 0);
  Set_States(S_BOSS_RAISE1, SPR_BOSS, 14, 8, Nil, S_BOSS_RAISE2, 0, 0);
  Set_States(S_BOSS_RAISE2, SPR_BOSS, 13, 8, Nil, S_BOSS_RAISE3, 0, 0);
  Set_States(S_BOSS_RAISE3, SPR_BOSS, 12, 8, Nil, S_BOSS_RAISE4, 0, 0);
  Set_States(S_BOSS_RAISE4, SPR_BOSS, 11, 8, Nil, S_BOSS_RAISE5, 0, 0);
  Set_States(S_BOSS_RAISE5, SPR_BOSS, 10, 8, Nil, S_BOSS_RAISE6, 0, 0);
  Set_States(S_BOSS_RAISE6, SPR_BOSS, 9, 8, Nil, S_BOSS_RAISE7, 0, 0);
  Set_States(S_BOSS_RAISE7, SPR_BOSS, 8, 8, Nil, S_BOSS_RUN1, 0, 0);
  Set_StatesP1(S_BOS2_STND, SPR_BOS2, 0, 10, @A_Look, S_BOS2_STND2, 0, 0);
  Set_StatesP1(S_BOS2_STND2, SPR_BOS2, 1, 10, @A_Look, S_BOS2_STND, 0, 0);
  Set_StatesP1(S_BOS2_RUN1, SPR_BOS2, 0, 3, @A_Chase, S_BOS2_RUN2, 0, 0);
  Set_StatesP1(S_BOS2_RUN2, SPR_BOS2, 0, 3, @A_Chase, S_BOS2_RUN3, 0, 0);
  Set_StatesP1(S_BOS2_RUN3, SPR_BOS2, 1, 3, @A_Chase, S_BOS2_RUN4, 0, 0);
  Set_StatesP1(S_BOS2_RUN4, SPR_BOS2, 1, 3, @A_Chase, S_BOS2_RUN5, 0, 0);
  Set_StatesP1(S_BOS2_RUN5, SPR_BOS2, 2, 3, @A_Chase, S_BOS2_RUN6, 0, 0);
  Set_StatesP1(S_BOS2_RUN6, SPR_BOS2, 2, 3, @A_Chase, S_BOS2_RUN7, 0, 0);
  Set_StatesP1(S_BOS2_RUN7, SPR_BOS2, 3, 3, @A_Chase, S_BOS2_RUN8, 0, 0);
  Set_StatesP1(S_BOS2_RUN8, SPR_BOS2, 3, 3, @A_Chase, S_BOS2_RUN1, 0, 0);
  Set_StatesP1(S_BOS2_ATK1, SPR_BOS2, 4, 8, @A_FaceTarget, S_BOS2_ATK2, 0, 0);
  Set_StatesP1(S_BOS2_ATK2, SPR_BOS2, 5, 8, @A_FaceTarget, S_BOS2_ATK3, 0, 0);
  Set_StatesP1(S_BOS2_ATK3, SPR_BOS2, 6, 8, @A_BruisAttack, S_BOS2_RUN1, 0, 0);
  Set_States(S_BOS2_PAIN, SPR_BOS2, 7, 2, Nil, S_BOS2_PAIN2, 0, 0);
  Set_StatesP1(S_BOS2_PAIN2, SPR_BOS2, 7, 2, @A_Pain, S_BOS2_RUN1, 0, 0);
  Set_States(S_BOS2_DIE1, SPR_BOS2, 8, 8, Nil, S_BOS2_DIE2, 0, 0);
  Set_StatesP1(S_BOS2_DIE2, SPR_BOS2, 9, 8, @A_Scream, S_BOS2_DIE3, 0, 0);
  Set_States(S_BOS2_DIE3, SPR_BOS2, 10, 8, Nil, S_BOS2_DIE4, 0, 0);
  Set_StatesP1(S_BOS2_DIE4, SPR_BOS2, 11, 8, @A_Fall, S_BOS2_DIE5, 0, 0);
  Set_States(S_BOS2_DIE5, SPR_BOS2, 12, 8, Nil, S_BOS2_DIE6, 0, 0);
  Set_States(S_BOS2_DIE6, SPR_BOS2, 13, 8, Nil, S_BOS2_DIE7, 0, 0);
  Set_States(S_BOS2_DIE7, SPR_BOS2, 14, -1, Nil, S_NULL, 0, 0);
  Set_States(S_BOS2_RAISE1, SPR_BOS2, 14, 8, Nil, S_BOS2_RAISE2, 0, 0);
  Set_States(S_BOS2_RAISE2, SPR_BOS2, 13, 8, Nil, S_BOS2_RAISE3, 0, 0);
  Set_States(S_BOS2_RAISE3, SPR_BOS2, 12, 8, Nil, S_BOS2_RAISE4, 0, 0);
  Set_States(S_BOS2_RAISE4, SPR_BOS2, 11, 8, Nil, S_BOS2_RAISE5, 0, 0);
  Set_States(S_BOS2_RAISE5, SPR_BOS2, 10, 8, Nil, S_BOS2_RAISE6, 0, 0);
  Set_States(S_BOS2_RAISE6, SPR_BOS2, 9, 8, Nil, S_BOS2_RAISE7, 0, 0);
  Set_States(S_BOS2_RAISE7, SPR_BOS2, 8, 8, Nil, S_BOS2_RUN1, 0, 0);
  Set_StatesP1(S_SKULL_STND, SPR_SKUL, 32768, 10, @A_Look, S_SKULL_STND2, 0, 0);
  Set_StatesP1(S_SKULL_STND2, SPR_SKUL, 32769, 10, @A_Look, S_SKULL_STND, 0, 0);
  Set_StatesP1(S_SKULL_RUN1, SPR_SKUL, 32768, 6, @A_Chase, S_SKULL_RUN2, 0, 0);
  Set_StatesP1(S_SKULL_RUN2, SPR_SKUL, 32769, 6, @A_Chase, S_SKULL_RUN1, 0, 0);
  Set_StatesP1(S_SKULL_ATK1, SPR_SKUL, 32770, 10, @A_FaceTarget, S_SKULL_ATK2, 0, 0);
  Set_StatesP1(S_SKULL_ATK2, SPR_SKUL, 32771, 4, @A_SkullAttack, S_SKULL_ATK3, 0, 0);
  Set_States(S_SKULL_ATK3, SPR_SKUL, 32770, 4, Nil, S_SKULL_ATK4, 0, 0);
  Set_States(S_SKULL_ATK4, SPR_SKUL, 32771, 4, Nil, S_SKULL_ATK3, 0, 0);
  Set_States(S_SKULL_PAIN, SPR_SKUL, 32772, 3, Nil, S_SKULL_PAIN2, 0, 0);
  Set_StatesP1(S_SKULL_PAIN2, SPR_SKUL, 32772, 3, @A_Pain, S_SKULL_RUN1, 0, 0);
  Set_States(S_SKULL_DIE1, SPR_SKUL, 32773, 6, Nil, S_SKULL_DIE2, 0, 0);
  Set_StatesP1(S_SKULL_DIE2, SPR_SKUL, 32774, 6, @A_Scream, S_SKULL_DIE3, 0, 0);
  Set_States(S_SKULL_DIE3, SPR_SKUL, 32775, 6, Nil, S_SKULL_DIE4, 0, 0);
  Set_StatesP1(S_SKULL_DIE4, SPR_SKUL, 32776, 6, @A_Fall, S_SKULL_DIE5, 0, 0);
  Set_States(S_SKULL_DIE5, SPR_SKUL, 9, 6, Nil, S_SKULL_DIE6, 0, 0);
  Set_States(S_SKULL_DIE6, SPR_SKUL, 10, 6, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_SPID_STND, SPR_SPID, 0, 10, @A_Look, S_SPID_STND2, 0, 0);
  Set_StatesP1(S_SPID_STND2, SPR_SPID, 1, 10, @A_Look, S_SPID_STND, 0, 0);
  Set_StatesP1(S_SPID_RUN1, SPR_SPID, 0, 3, @A_Metal, S_SPID_RUN2, 0, 0);
  Set_StatesP1(S_SPID_RUN2, SPR_SPID, 0, 3, @A_Chase, S_SPID_RUN3, 0, 0);
  Set_StatesP1(S_SPID_RUN3, SPR_SPID, 1, 3, @A_Chase, S_SPID_RUN4, 0, 0);
  Set_StatesP1(S_SPID_RUN4, SPR_SPID, 1, 3, @A_Chase, S_SPID_RUN5, 0, 0);
  Set_StatesP1(S_SPID_RUN5, SPR_SPID, 2, 3, @A_Metal, S_SPID_RUN6, 0, 0);
  Set_StatesP1(S_SPID_RUN6, SPR_SPID, 2, 3, @A_Chase, S_SPID_RUN7, 0, 0);
  Set_StatesP1(S_SPID_RUN7, SPR_SPID, 3, 3, @A_Chase, S_SPID_RUN8, 0, 0);
  Set_StatesP1(S_SPID_RUN8, SPR_SPID, 3, 3, @A_Chase, S_SPID_RUN9, 0, 0);
  Set_StatesP1(S_SPID_RUN9, SPR_SPID, 4, 3, @A_Metal, S_SPID_RUN10, 0, 0);
  Set_StatesP1(S_SPID_RUN10, SPR_SPID, 4, 3, @A_Chase, S_SPID_RUN11, 0, 0);
  Set_StatesP1(S_SPID_RUN11, SPR_SPID, 5, 3, @A_Chase, S_SPID_RUN12, 0, 0);
  Set_StatesP1(S_SPID_RUN12, SPR_SPID, 5, 3, @A_Chase, S_SPID_RUN1, 0, 0);
  Set_StatesP1(S_SPID_ATK1, SPR_SPID, 32768, 20, @A_FaceTarget, S_SPID_ATK2, 0, 0);
  Set_StatesP1(S_SPID_ATK2, SPR_SPID, 32774, 4, @A_SPosAttack, S_SPID_ATK3, 0, 0);
  Set_StatesP1(S_SPID_ATK3, SPR_SPID, 32775, 4, @A_SPosAttack, S_SPID_ATK4, 0, 0);
  Set_StatesP1(S_SPID_ATK4, SPR_SPID, 32775, 1, @A_SpidRefire, S_SPID_ATK2, 0, 0);
  Set_States(S_SPID_PAIN, SPR_SPID, 8, 3, Nil, S_SPID_PAIN2, 0, 0);
  Set_StatesP1(S_SPID_PAIN2, SPR_SPID, 8, 3, @A_Pain, S_SPID_RUN1, 0, 0);
  Set_StatesP1(S_SPID_DIE1, SPR_SPID, 9, 20, @A_Scream, S_SPID_DIE2, 0, 0);
  Set_StatesP1(S_SPID_DIE2, SPR_SPID, 10, 10, @A_Fall, S_SPID_DIE3, 0, 0);
  Set_States(S_SPID_DIE3, SPR_SPID, 11, 10, Nil, S_SPID_DIE4, 0, 0);
  Set_States(S_SPID_DIE4, SPR_SPID, 12, 10, Nil, S_SPID_DIE5, 0, 0);
  Set_States(S_SPID_DIE5, SPR_SPID, 13, 10, Nil, S_SPID_DIE6, 0, 0);
  Set_States(S_SPID_DIE6, SPR_SPID, 14, 10, Nil, S_SPID_DIE7, 0, 0);
  Set_States(S_SPID_DIE7, SPR_SPID, 15, 10, Nil, S_SPID_DIE8, 0, 0);
  Set_States(S_SPID_DIE8, SPR_SPID, 16, 10, Nil, S_SPID_DIE9, 0, 0);
  Set_States(S_SPID_DIE9, SPR_SPID, 17, 10, Nil, S_SPID_DIE10, 0, 0);
  Set_States(S_SPID_DIE10, SPR_SPID, 18, 30, Nil, S_SPID_DIE11, 0, 0);
  Set_StatesP1(S_SPID_DIE11, SPR_SPID, 18, -1, @A_BossDeath, S_NULL, 0, 0);
  Set_StatesP1(S_BSPI_STND, SPR_BSPI, 0, 10, @A_Look, S_BSPI_STND2, 0, 0);
  Set_StatesP1(S_BSPI_STND2, SPR_BSPI, 1, 10, @A_Look, S_BSPI_STND, 0, 0);
  Set_States(S_BSPI_SIGHT, SPR_BSPI, 0, 20, Nil, S_BSPI_RUN1, 0, 0);
  Set_StatesP1(S_BSPI_RUN1, SPR_BSPI, 0, 3, @A_BabyMetal, S_BSPI_RUN2, 0, 0);
  Set_StatesP1(S_BSPI_RUN2, SPR_BSPI, 0, 3, @A_Chase, S_BSPI_RUN3, 0, 0);
  Set_StatesP1(S_BSPI_RUN3, SPR_BSPI, 1, 3, @A_Chase, S_BSPI_RUN4, 0, 0);
  Set_StatesP1(S_BSPI_RUN4, SPR_BSPI, 1, 3, @A_Chase, S_BSPI_RUN5, 0, 0);
  Set_StatesP1(S_BSPI_RUN5, SPR_BSPI, 2, 3, @A_Chase, S_BSPI_RUN6, 0, 0);
  Set_StatesP1(S_BSPI_RUN6, SPR_BSPI, 2, 3, @A_Chase, S_BSPI_RUN7, 0, 0);
  Set_StatesP1(S_BSPI_RUN7, SPR_BSPI, 3, 3, @A_BabyMetal, S_BSPI_RUN8, 0, 0);
  Set_StatesP1(S_BSPI_RUN8, SPR_BSPI, 3, 3, @A_Chase, S_BSPI_RUN9, 0, 0);
  Set_StatesP1(S_BSPI_RUN9, SPR_BSPI, 4, 3, @A_Chase, S_BSPI_RUN10, 0, 0);
  Set_StatesP1(S_BSPI_RUN10, SPR_BSPI, 4, 3, @A_Chase, S_BSPI_RUN11, 0, 0);
  Set_StatesP1(S_BSPI_RUN11, SPR_BSPI, 5, 3, @A_Chase, S_BSPI_RUN12, 0, 0);
  Set_StatesP1(S_BSPI_RUN12, SPR_BSPI, 5, 3, @A_Chase, S_BSPI_RUN1, 0, 0);
  Set_StatesP1(S_BSPI_ATK1, SPR_BSPI, 32768, 20, @A_FaceTarget, S_BSPI_ATK2, 0, 0);
  Set_StatesP1(S_BSPI_ATK2, SPR_BSPI, 32774, 4, @A_BspiAttack, S_BSPI_ATK3, 0, 0);
  Set_States(S_BSPI_ATK3, SPR_BSPI, 32775, 4, Nil, S_BSPI_ATK4, 0, 0);
  Set_StatesP1(S_BSPI_ATK4, SPR_BSPI, 32775, 1, @A_SpidRefire, S_BSPI_ATK2, 0, 0);
  Set_States(S_BSPI_PAIN, SPR_BSPI, 8, 3, Nil, S_BSPI_PAIN2, 0, 0);
  Set_StatesP1(S_BSPI_PAIN2, SPR_BSPI, 8, 3, @A_Pain, S_BSPI_RUN1, 0, 0);
  Set_StatesP1(S_BSPI_DIE1, SPR_BSPI, 9, 20, @A_Scream, S_BSPI_DIE2, 0, 0);
  Set_StatesP1(S_BSPI_DIE2, SPR_BSPI, 10, 7, @A_Fall, S_BSPI_DIE3, 0, 0);
  Set_States(S_BSPI_DIE3, SPR_BSPI, 11, 7, Nil, S_BSPI_DIE4, 0, 0);
  Set_States(S_BSPI_DIE4, SPR_BSPI, 12, 7, Nil, S_BSPI_DIE5, 0, 0);
  Set_States(S_BSPI_DIE5, SPR_BSPI, 13, 7, Nil, S_BSPI_DIE6, 0, 0);
  Set_States(S_BSPI_DIE6, SPR_BSPI, 14, 7, Nil, S_BSPI_DIE7, 0, 0);
  Set_StatesP1(S_BSPI_DIE7, SPR_BSPI, 15, -1, @A_BossDeath, S_NULL, 0, 0);
  Set_States(S_BSPI_RAISE1, SPR_BSPI, 15, 5, Nil, S_BSPI_RAISE2, 0, 0);
  Set_States(S_BSPI_RAISE2, SPR_BSPI, 14, 5, Nil, S_BSPI_RAISE3, 0, 0);
  Set_States(S_BSPI_RAISE3, SPR_BSPI, 13, 5, Nil, S_BSPI_RAISE4, 0, 0);
  Set_States(S_BSPI_RAISE4, SPR_BSPI, 12, 5, Nil, S_BSPI_RAISE5, 0, 0);
  Set_States(S_BSPI_RAISE5, SPR_BSPI, 11, 5, Nil, S_BSPI_RAISE6, 0, 0);
  Set_States(S_BSPI_RAISE6, SPR_BSPI, 10, 5, Nil, S_BSPI_RAISE7, 0, 0);
  Set_States(S_BSPI_RAISE7, SPR_BSPI, 9, 5, Nil, S_BSPI_RUN1, 0, 0);
  Set_States(S_ARACH_PLAZ, SPR_APLS, 32768, 5, Nil, S_ARACH_PLAZ2, 0, 0);
  Set_States(S_ARACH_PLAZ2, SPR_APLS, 32769, 5, Nil, S_ARACH_PLAZ, 0, 0);
  Set_States(S_ARACH_PLEX, SPR_APBX, 32768, 5, Nil, S_ARACH_PLEX2, 0, 0);
  Set_States(S_ARACH_PLEX2, SPR_APBX, 32769, 5, Nil, S_ARACH_PLEX3, 0, 0);
  Set_States(S_ARACH_PLEX3, SPR_APBX, 32770, 5, Nil, S_ARACH_PLEX4, 0, 0);
  Set_States(S_ARACH_PLEX4, SPR_APBX, 32771, 5, Nil, S_ARACH_PLEX5, 0, 0);
  Set_States(S_ARACH_PLEX5, SPR_APBX, 32772, 5, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_CYBER_STND, SPR_CYBR, 0, 10, @A_Look, S_CYBER_STND2, 0, 0);
  Set_StatesP1(S_CYBER_STND2, SPR_CYBR, 1, 10, @A_Look, S_CYBER_STND, 0, 0);
  Set_StatesP1(S_CYBER_RUN1, SPR_CYBR, 0, 3, @A_Hoof, S_CYBER_RUN2, 0, 0);
  Set_StatesP1(S_CYBER_RUN2, SPR_CYBR, 0, 3, @A_Chase, S_CYBER_RUN3, 0, 0);
  Set_StatesP1(S_CYBER_RUN3, SPR_CYBR, 1, 3, @A_Chase, S_CYBER_RUN4, 0, 0);
  Set_StatesP1(S_CYBER_RUN4, SPR_CYBR, 1, 3, @A_Chase, S_CYBER_RUN5, 0, 0);
  Set_StatesP1(S_CYBER_RUN5, SPR_CYBR, 2, 3, @A_Chase, S_CYBER_RUN6, 0, 0);
  Set_StatesP1(S_CYBER_RUN6, SPR_CYBR, 2, 3, @A_Chase, S_CYBER_RUN7, 0, 0);
  Set_StatesP1(S_CYBER_RUN7, SPR_CYBR, 3, 3, @A_Metal, S_CYBER_RUN8, 0, 0);
  Set_StatesP1(S_CYBER_RUN8, SPR_CYBR, 3, 3, @A_Chase, S_CYBER_RUN1, 0, 0);
  Set_StatesP1(S_CYBER_ATK1, SPR_CYBR, 4, 6, @A_FaceTarget, S_CYBER_ATK2, 0, 0);
  // [crispy] render Cyberdemon's firing frames full-bright
  Set_StatesP1(S_CYBER_ATK2, SPR_CYBR, 5 Or $8000, 12, @A_CyberAttack, S_CYBER_ATK3, 0, 0);
  Set_StatesP1(S_CYBER_ATK3, SPR_CYBR, 4, 12, @A_FaceTarget, S_CYBER_ATK4, 0, 0);
  Set_StatesP1(S_CYBER_ATK4, SPR_CYBR, 5 Or $8000, 12, @A_CyberAttack, S_CYBER_ATK5, 0, 0);
  Set_StatesP1(S_CYBER_ATK5, SPR_CYBR, 4, 12, @A_FaceTarget, S_CYBER_ATK6, 0, 0);
  Set_StatesP1(S_CYBER_ATK6, SPR_CYBR, 5 Or $8000, 12, @A_CyberAttack, S_CYBER_RUN1, 0, 0);
  Set_StatesP1(S_CYBER_PAIN, SPR_CYBR, 6, 10, @A_Pain, S_CYBER_RUN1, 0, 0);
  Set_States(S_CYBER_DIE1, SPR_CYBR, 7, 10, Nil, S_CYBER_DIE2, 0, 0);
  Set_StatesP1(S_CYBER_DIE2, SPR_CYBR, 8, 10, @A_Scream, S_CYBER_DIE3, 0, 0);
  Set_States(S_CYBER_DIE3, SPR_CYBR, 9, 10, Nil, S_CYBER_DIE4, 0, 0);
  Set_States(S_CYBER_DIE4, SPR_CYBR, 10, 10, Nil, S_CYBER_DIE5, 0, 0);
  Set_States(S_CYBER_DIE5, SPR_CYBR, 11, 10, Nil, S_CYBER_DIE6, 0, 0);
  Set_StatesP1(S_CYBER_DIE6, SPR_CYBR, 12, 10, @A_Fall, S_CYBER_DIE7, 0, 0);
  Set_States(S_CYBER_DIE7, SPR_CYBR, 13, 10, Nil, S_CYBER_DIE8, 0, 0);
  Set_States(S_CYBER_DIE8, SPR_CYBR, 14, 10, Nil, S_CYBER_DIE9, 0, 0);
  Set_States(S_CYBER_DIE9, SPR_CYBR, 15, 30, Nil, S_CYBER_DIE10, 0, 0);
  Set_StatesP1(S_CYBER_DIE10, SPR_CYBR, 15, -1, @A_BossDeath, S_NULL, 0, 0);
  Set_StatesP1(S_PAIN_STND, SPR_PAIN, 0, 10, @A_Look, S_PAIN_STND, 0, 0);
  Set_StatesP1(S_PAIN_RUN1, SPR_PAIN, 0, 3, @A_Chase, S_PAIN_RUN2, 0, 0);
  Set_StatesP1(S_PAIN_RUN2, SPR_PAIN, 0, 3, @A_Chase, S_PAIN_RUN3, 0, 0);
  Set_StatesP1(S_PAIN_RUN3, SPR_PAIN, 1, 3, @A_Chase, S_PAIN_RUN4, 0, 0);
  Set_StatesP1(S_PAIN_RUN4, SPR_PAIN, 1, 3, @A_Chase, S_PAIN_RUN5, 0, 0);
  Set_StatesP1(S_PAIN_RUN5, SPR_PAIN, 2, 3, @A_Chase, S_PAIN_RUN6, 0, 0);
  Set_StatesP1(S_PAIN_RUN6, SPR_PAIN, 2, 3, @A_Chase, S_PAIN_RUN1, 0, 0);
  Set_StatesP1(S_PAIN_ATK1, SPR_PAIN, 3, 5, @A_FaceTarget, S_PAIN_ATK2, 0, 0);
  Set_StatesP1(S_PAIN_ATK2, SPR_PAIN, 4, 5, @A_FaceTarget, S_PAIN_ATK3, 0, 0);
  Set_StatesP1(S_PAIN_ATK3, SPR_PAIN, 32773, 5, @A_FaceTarget, S_PAIN_ATK4, 0, 0);
  Set_StatesP1(S_PAIN_ATK4, SPR_PAIN, 32773, 0, @A_PainAttack, S_PAIN_RUN1, 0, 0);
  Set_States(S_PAIN_PAIN, SPR_PAIN, 6, 6, Nil, S_PAIN_PAIN2, 0, 0);
  Set_StatesP1(S_PAIN_PAIN2, SPR_PAIN, 6, 6, @A_Pain, S_PAIN_RUN1, 0, 0);
  Set_States(S_PAIN_DIE1, SPR_PAIN, 32775, 8, Nil, S_PAIN_DIE2, 0, 0);
  Set_StatesP1(S_PAIN_DIE2, SPR_PAIN, 32776, 8, @A_Scream, S_PAIN_DIE3, 0, 0);
  Set_States(S_PAIN_DIE3, SPR_PAIN, 32777, 8, Nil, S_PAIN_DIE4, 0, 0);
  Set_States(S_PAIN_DIE4, SPR_PAIN, 32778, 8, Nil, S_PAIN_DIE5, 0, 0);
  Set_StatesP1(S_PAIN_DIE5, SPR_PAIN, 32779, 8, @A_PainDie, S_PAIN_DIE6, 0, 0);
  Set_States(S_PAIN_DIE6, SPR_PAIN, 32780, 8, Nil, S_NULL, 0, 0);
  Set_States(S_PAIN_RAISE1, SPR_PAIN, 12, 8, Nil, S_PAIN_RAISE2, 0, 0);
  Set_States(S_PAIN_RAISE2, SPR_PAIN, 11, 8, Nil, S_PAIN_RAISE3, 0, 0);
  Set_States(S_PAIN_RAISE3, SPR_PAIN, 10, 8, Nil, S_PAIN_RAISE4, 0, 0);
  Set_States(S_PAIN_RAISE4, SPR_PAIN, 9, 8, Nil, S_PAIN_RAISE5, 0, 0);
  Set_States(S_PAIN_RAISE5, SPR_PAIN, 8, 8, Nil, S_PAIN_RAISE6, 0, 0);
  Set_States(S_PAIN_RAISE6, SPR_PAIN, 7, 8, Nil, S_PAIN_RUN1, 0, 0);
  Set_StatesP1(S_SSWV_STND, SPR_SSWV, 0, 10, @A_Look, S_SSWV_STND2, 0, 0);
  Set_StatesP1(S_SSWV_STND2, SPR_SSWV, 1, 10, @A_Look, S_SSWV_STND, 0, 0);
  Set_StatesP1(S_SSWV_RUN1, SPR_SSWV, 0, 3, @A_Chase, S_SSWV_RUN2, 0, 0);
  Set_StatesP1(S_SSWV_RUN2, SPR_SSWV, 0, 3, @A_Chase, S_SSWV_RUN3, 0, 0);
  Set_StatesP1(S_SSWV_RUN3, SPR_SSWV, 1, 3, @A_Chase, S_SSWV_RUN4, 0, 0);
  Set_StatesP1(S_SSWV_RUN4, SPR_SSWV, 1, 3, @A_Chase, S_SSWV_RUN5, 0, 0);
  Set_StatesP1(S_SSWV_RUN5, SPR_SSWV, 2, 3, @A_Chase, S_SSWV_RUN6, 0, 0);
  Set_StatesP1(S_SSWV_RUN6, SPR_SSWV, 2, 3, @A_Chase, S_SSWV_RUN7, 0, 0);
  Set_StatesP1(S_SSWV_RUN7, SPR_SSWV, 3, 3, @A_Chase, S_SSWV_RUN8, 0, 0);
  Set_StatesP1(S_SSWV_RUN8, SPR_SSWV, 3, 3, @A_Chase, S_SSWV_RUN1, 0, 0);
  Set_StatesP1(S_SSWV_ATK1, SPR_SSWV, 4, 10, @A_FaceTarget, S_SSWV_ATK2, 0, 0);
  Set_StatesP1(S_SSWV_ATK2, SPR_SSWV, 5, 10, @A_FaceTarget, S_SSWV_ATK3, 0, 0);
  Set_StatesP1(S_SSWV_ATK3, SPR_SSWV, 32774, 4, @A_CPosAttack, S_SSWV_ATK4, 0, 0);
  Set_StatesP1(S_SSWV_ATK4, SPR_SSWV, 5, 6, @A_FaceTarget, S_SSWV_ATK5, 0, 0);
  Set_StatesP1(S_SSWV_ATK5, SPR_SSWV, 32774, 4, @A_CPosAttack, S_SSWV_ATK6, 0, 0);
  Set_StatesP1(S_SSWV_ATK6, SPR_SSWV, 5, 1, @A_CPosRefire, S_SSWV_ATK2, 0, 0);
  Set_States(S_SSWV_PAIN, SPR_SSWV, 7, 3, Nil, S_SSWV_PAIN2, 0, 0);
  Set_StatesP1(S_SSWV_PAIN2, SPR_SSWV, 7, 3, @A_Pain, S_SSWV_RUN1, 0, 0);
  Set_States(S_SSWV_DIE1, SPR_SSWV, 8, 5, Nil, S_SSWV_DIE2, 0, 0);
  Set_StatesP1(S_SSWV_DIE2, SPR_SSWV, 9, 5, @A_Scream, S_SSWV_DIE3, 0, 0);
  Set_StatesP1(S_SSWV_DIE3, SPR_SSWV, 10, 5, @A_Fall, S_SSWV_DIE4, 0, 0);
  Set_States(S_SSWV_DIE4, SPR_SSWV, 11, 5, Nil, S_SSWV_DIE5, 0, 0);
  Set_States(S_SSWV_DIE5, SPR_SSWV, 12, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SSWV_XDIE1, SPR_SSWV, 13, 5, Nil, S_SSWV_XDIE2, 0, 0);
  Set_StatesP1(S_SSWV_XDIE2, SPR_SSWV, 14, 5, @A_XScream, S_SSWV_XDIE3, 0, 0);
  Set_StatesP1(S_SSWV_XDIE3, SPR_SSWV, 15, 5, @A_Fall, S_SSWV_XDIE4, 0, 0);
  Set_States(S_SSWV_XDIE4, SPR_SSWV, 16, 5, Nil, S_SSWV_XDIE5, 0, 0);
  Set_States(S_SSWV_XDIE5, SPR_SSWV, 17, 5, Nil, S_SSWV_XDIE6, 0, 0);
  Set_States(S_SSWV_XDIE6, SPR_SSWV, 18, 5, Nil, S_SSWV_XDIE7, 0, 0);
  Set_States(S_SSWV_XDIE7, SPR_SSWV, 19, 5, Nil, S_SSWV_XDIE8, 0, 0);
  Set_States(S_SSWV_XDIE8, SPR_SSWV, 20, 5, Nil, S_SSWV_XDIE9, 0, 0);
  Set_States(S_SSWV_XDIE9, SPR_SSWV, 21, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SSWV_RAISE1, SPR_SSWV, 12, 5, Nil, S_SSWV_RAISE2, 0, 0);
  Set_States(S_SSWV_RAISE2, SPR_SSWV, 11, 5, Nil, S_SSWV_RAISE3, 0, 0);
  Set_States(S_SSWV_RAISE3, SPR_SSWV, 10, 5, Nil, S_SSWV_RAISE4, 0, 0);
  Set_States(S_SSWV_RAISE4, SPR_SSWV, 9, 5, Nil, S_SSWV_RAISE5, 0, 0);
  Set_States(S_SSWV_RAISE5, SPR_SSWV, 8, 5, Nil, S_SSWV_RUN1, 0, 0);
  Set_States(S_KEENSTND, SPR_KEEN, 0, -1, Nil, S_KEENSTND, 0, 0);
  Set_States(S_COMMKEEN, SPR_KEEN, 0, 6, Nil, S_COMMKEEN2, 0, 0);
  Set_States(S_COMMKEEN2, SPR_KEEN, 1, 6, Nil, S_COMMKEEN3, 0, 0);
  Set_StatesP1(S_COMMKEEN3, SPR_KEEN, 2, 6, @A_Scream, S_COMMKEEN4, 0, 0);
  Set_States(S_COMMKEEN4, SPR_KEEN, 3, 6, Nil, S_COMMKEEN5, 0, 0);
  Set_States(S_COMMKEEN5, SPR_KEEN, 4, 6, Nil, S_COMMKEEN6, 0, 0);
  Set_States(S_COMMKEEN6, SPR_KEEN, 5, 6, Nil, S_COMMKEEN7, 0, 0);
  Set_States(S_COMMKEEN7, SPR_KEEN, 6, 6, Nil, S_COMMKEEN8, 0, 0);
  Set_States(S_COMMKEEN8, SPR_KEEN, 7, 6, Nil, S_COMMKEEN9, 0, 0);
  Set_States(S_COMMKEEN9, SPR_KEEN, 8, 6, Nil, S_COMMKEEN10, 0, 0);
  Set_States(S_COMMKEEN10, SPR_KEEN, 9, 6, Nil, S_COMMKEEN11, 0, 0);
  Set_StatesP1(S_COMMKEEN11, SPR_KEEN, 10, 6, @A_KeenDie, S_COMMKEEN12, 0, 0);
  Set_States(S_COMMKEEN12, SPR_KEEN, 11, -1, Nil, S_NULL, 0, 0);
  Set_States(S_KEENPAIN, SPR_KEEN, 12, 4, Nil, S_KEENPAIN2, 0, 0);
  Set_StatesP1(S_KEENPAIN2, SPR_KEEN, 12, 8, @A_Pain, S_KEENSTND, 0, 0);
  Set_States(S_BRAIN, SPR_BBRN, 0, -1, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_BRAIN_PAIN, SPR_BBRN, 1, 36, @A_BrainPain, S_BRAIN, 0, 0);
  Set_StatesP1(S_BRAIN_DIE1, SPR_BBRN, 0, 100, @A_BrainScream, S_BRAIN_DIE2, 0, 0);
  Set_States(S_BRAIN_DIE2, SPR_BBRN, 0, 10, Nil, S_BRAIN_DIE3, 0, 0);
  Set_States(S_BRAIN_DIE3, SPR_BBRN, 0, 10, Nil, S_BRAIN_DIE4, 0, 0);
  Set_StatesP1(S_BRAIN_DIE4, SPR_BBRN, 0, -1, @A_BrainDie, S_NULL, 0, 0);
  Set_StatesP1(S_BRAINEYE, SPR_SSWV, 0, 10, @A_Look, S_BRAINEYE, 0, 0);
  Set_StatesP1(S_BRAINEYESEE, SPR_SSWV, 0, 181, @A_BrainAwake, S_BRAINEYE1, 0, 0);
  Set_StatesP1(S_BRAINEYE1, SPR_SSWV, 0, 150, @A_BrainSpit, S_BRAINEYE1, 0, 0);
  Set_StatesP1(S_SPAWN1, SPR_BOSF, 32768, 3, @A_SpawnSound, S_SPAWN2, 0, 0);
  Set_StatesP1(S_SPAWN2, SPR_BOSF, 32769, 3, @A_SpawnFly, S_SPAWN3, 0, 0);
  Set_StatesP1(S_SPAWN3, SPR_BOSF, 32770, 3, @A_SpawnFly, S_SPAWN4, 0, 0);
  Set_StatesP1(S_SPAWN4, SPR_BOSF, 32771, 3, @A_SpawnFly, S_SPAWN1, 0, 0);
  Set_StatesP1(S_SPAWNFIRE1, SPR_FIRE, 32768, 4, @A_Fire, S_SPAWNFIRE2, 0, 0);
  Set_StatesP1(S_SPAWNFIRE2, SPR_FIRE, 32769, 4, @A_Fire, S_SPAWNFIRE3, 0, 0);
  Set_StatesP1(S_SPAWNFIRE3, SPR_FIRE, 32770, 4, @A_Fire, S_SPAWNFIRE4, 0, 0);
  Set_StatesP1(S_SPAWNFIRE4, SPR_FIRE, 32771, 4, @A_Fire, S_SPAWNFIRE5, 0, 0);
  Set_StatesP1(S_SPAWNFIRE5, SPR_FIRE, 32772, 4, @A_Fire, S_SPAWNFIRE6, 0, 0);
  Set_StatesP1(S_SPAWNFIRE6, SPR_FIRE, 32773, 4, @A_Fire, S_SPAWNFIRE7, 0, 0);
  Set_StatesP1(S_SPAWNFIRE7, SPR_FIRE, 32774, 4, @A_Fire, S_SPAWNFIRE8, 0, 0);
  Set_StatesP1(S_SPAWNFIRE8, SPR_FIRE, 32775, 4, @A_Fire, S_NULL, 0, 0);
  Set_States(S_BRAINEXPLODE1, SPR_MISL, 32769, 10, Nil, S_BRAINEXPLODE2, 0, 0);
  Set_States(S_BRAINEXPLODE2, SPR_MISL, 32770, 10, Nil, S_BRAINEXPLODE3, 0, 0);
  Set_StatesP1(S_BRAINEXPLODE3, SPR_MISL, 32771, 10, @A_BrainExplode, S_NULL, 0, 0);
  Set_States(S_ARM1, SPR_ARM1, 0, 6, Nil, S_ARM1A, 0, 0);
  Set_States(S_ARM1A, SPR_ARM1, 32769, 7, Nil, S_ARM1, 0, 0);
  Set_States(S_ARM2, SPR_ARM2, 0, 6, Nil, S_ARM2A, 0, 0);
  Set_States(S_ARM2A, SPR_ARM2, 32769, 6, Nil, S_ARM2, 0, 0);
  Set_States(S_BAR1, SPR_BAR1, 0, 6, Nil, S_BAR2, 0, 0);
  Set_States(S_BAR2, SPR_BAR1, 1, 6, Nil, S_BAR1, 0, 0);
  Set_States(S_BEXP, SPR_BEXP, 32768, 5, Nil, S_BEXP2, 0, 0);
  Set_StatesP1(S_BEXP2, SPR_BEXP, 32769, 5, @A_Scream, S_BEXP3, 0, 0);
  Set_States(S_BEXP3, SPR_BEXP, 32770, 5, Nil, S_BEXP4, 0, 0);
  Set_StatesP1(S_BEXP4, SPR_BEXP, 32771, 10, @A_Explode, S_BEXP5, 0, 0);
  Set_States(S_BEXP5, SPR_BEXP, 32772, 10, Nil, S_NULL, 0, 0);
  Set_States(S_BBAR1, SPR_FCAN, 32768, 4, Nil, S_BBAR2, 0, 0);
  Set_States(S_BBAR2, SPR_FCAN, 32769, 4, Nil, S_BBAR3, 0, 0);
  Set_States(S_BBAR3, SPR_FCAN, 32770, 4, Nil, S_BBAR1, 0, 0);
  Set_States(S_BON1, SPR_BON1, 0, 6, Nil, S_BON1A, 0, 0);
  Set_States(S_BON1A, SPR_BON1, 1, 6, Nil, S_BON1B, 0, 0);
  Set_States(S_BON1B, SPR_BON1, 2, 6, Nil, S_BON1C, 0, 0);
  Set_States(S_BON1C, SPR_BON1, 3, 6, Nil, S_BON1D, 0, 0);
  Set_States(S_BON1D, SPR_BON1, 2, 6, Nil, S_BON1E, 0, 0);
  Set_States(S_BON1E, SPR_BON1, 1, 6, Nil, S_BON1, 0, 0);
  Set_States(S_BON2, SPR_BON2, 0, 6, Nil, S_BON2A, 0, 0);
  Set_States(S_BON2A, SPR_BON2, 1, 6, Nil, S_BON2B, 0, 0);
  Set_States(S_BON2B, SPR_BON2, 2, 6, Nil, S_BON2C, 0, 0);
  Set_States(S_BON2C, SPR_BON2, 3, 6, Nil, S_BON2D, 0, 0);
  Set_States(S_BON2D, SPR_BON2, 2, 6, Nil, S_BON2E, 0, 0);
  Set_States(S_BON2E, SPR_BON2, 1, 6, Nil, S_BON2, 0, 0);
  Set_States(S_BKEY, SPR_BKEY, 0, 10, Nil, S_BKEY2, 0, 0);
  Set_States(S_BKEY2, SPR_BKEY, 32769, 10, Nil, S_BKEY, 0, 0);
  Set_States(S_RKEY, SPR_RKEY, 0, 10, Nil, S_RKEY2, 0, 0);
  Set_States(S_RKEY2, SPR_RKEY, 32769, 10, Nil, S_RKEY, 0, 0);
  Set_States(S_YKEY, SPR_YKEY, 0, 10, Nil, S_YKEY2, 0, 0);
  Set_States(S_YKEY2, SPR_YKEY, 32769, 10, Nil, S_YKEY, 0, 0);
  Set_States(S_BSKULL, SPR_BSKU, 0, 10, Nil, S_BSKULL2, 0, 0);
  Set_States(S_BSKULL2, SPR_BSKU, 32769, 10, Nil, S_BSKULL, 0, 0);
  Set_States(S_RSKULL, SPR_RSKU, 0, 10, Nil, S_RSKULL2, 0, 0);
  Set_States(S_RSKULL2, SPR_RSKU, 32769, 10, Nil, S_RSKULL, 0, 0);
  Set_States(S_YSKULL, SPR_YSKU, 0, 10, Nil, S_YSKULL2, 0, 0);
  Set_States(S_YSKULL2, SPR_YSKU, 32769, 10, Nil, S_YSKULL, 0, 0);
  Set_States(S_STIM, SPR_STIM, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_MEDI, SPR_MEDI, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SOUL, SPR_SOUL, 32768, 6, Nil, S_SOUL2, 0, 0);
  Set_States(S_SOUL2, SPR_SOUL, 32769, 6, Nil, S_SOUL3, 0, 0);
  Set_States(S_SOUL3, SPR_SOUL, 32770, 6, Nil, S_SOUL4, 0, 0);
  Set_States(S_SOUL4, SPR_SOUL, 32771, 6, Nil, S_SOUL5, 0, 0);
  Set_States(S_SOUL5, SPR_SOUL, 32770, 6, Nil, S_SOUL6, 0, 0);
  Set_States(S_SOUL6, SPR_SOUL, 32769, 6, Nil, S_SOUL, 0, 0);
  Set_States(S_PINV, SPR_PINV, 32768, 6, Nil, S_PINV2, 0, 0);
  Set_States(S_PINV2, SPR_PINV, 32769, 6, Nil, S_PINV3, 0, 0);
  Set_States(S_PINV3, SPR_PINV, 32770, 6, Nil, S_PINV4, 0, 0);
  Set_States(S_PINV4, SPR_PINV, 32771, 6, Nil, S_PINV, 0, 0);
  Set_States(S_PSTR, SPR_PSTR, 32768, -1, Nil, S_NULL, 0, 0);
  Set_States(S_PINS, SPR_PINS, 32768, 6, Nil, S_PINS2, 0, 0);
  Set_States(S_PINS2, SPR_PINS, 32769, 6, Nil, S_PINS3, 0, 0);
  Set_States(S_PINS3, SPR_PINS, 32770, 6, Nil, S_PINS4, 0, 0);
  Set_States(S_PINS4, SPR_PINS, 32771, 6, Nil, S_PINS, 0, 0);
  Set_States(S_MEGA, SPR_MEGA, 32768, 6, Nil, S_MEGA2, 0, 0);
  Set_States(S_MEGA2, SPR_MEGA, 32769, 6, Nil, S_MEGA3, 0, 0);
  Set_States(S_MEGA3, SPR_MEGA, 32770, 6, Nil, S_MEGA4, 0, 0);
  Set_States(S_MEGA4, SPR_MEGA, 32771, 6, Nil, S_MEGA, 0, 0);
  Set_States(S_SUIT, SPR_SUIT, 32768, -1, Nil, S_NULL, 0, 0);
  Set_States(S_PMAP, SPR_PMAP, 32768, 6, Nil, S_PMAP2, 0, 0);
  Set_States(S_PMAP2, SPR_PMAP, 32769, 6, Nil, S_PMAP3, 0, 0);
  Set_States(S_PMAP3, SPR_PMAP, 32770, 6, Nil, S_PMAP4, 0, 0);
  Set_States(S_PMAP4, SPR_PMAP, 32771, 6, Nil, S_PMAP5, 0, 0);
  Set_States(S_PMAP5, SPR_PMAP, 32770, 6, Nil, S_PMAP6, 0, 0);
  Set_States(S_PMAP6, SPR_PMAP, 32769, 6, Nil, S_PMAP, 0, 0);
  Set_States(S_PVIS, SPR_PVIS, 32768, 6, Nil, S_PVIS2, 0, 0);
  Set_States(S_PVIS2, SPR_PVIS, 1, 6, Nil, S_PVIS, 0, 0);
  Set_States(S_CLIP, SPR_CLIP, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_AMMO, SPR_AMMO, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_ROCK, SPR_ROCK, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_BROK, SPR_BROK, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_CELL, SPR_CELL, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_CELP, SPR_CELP, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SHEL, SPR_SHEL, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SBOX, SPR_SBOX, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_BPAK, SPR_BPAK, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_BFUG, SPR_BFUG, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_MGUN, SPR_MGUN, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_CSAW, SPR_CSAW, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_LAUN, SPR_LAUN, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_PLAS, SPR_PLAS, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SHOT, SPR_SHOT, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SHOT2, SPR_SGN2, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_COLU, SPR_COLU, 32768, -1, Nil, S_NULL, 0, 0);
  Set_States(S_STALAG, SPR_SMT2, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_BLOODYTWITCH, SPR_GOR1, 0, 10, Nil, S_BLOODYTWITCH2, 0, 0);
  Set_States(S_BLOODYTWITCH2, SPR_GOR1, 1, 15, Nil, S_BLOODYTWITCH3, 0, 0);
  Set_States(S_BLOODYTWITCH3, SPR_GOR1, 2, 8, Nil, S_BLOODYTWITCH4, 0, 0);
  Set_States(S_BLOODYTWITCH4, SPR_GOR1, 1, 6, Nil, S_BLOODYTWITCH, 0, 0);
  Set_States(S_DEADTORSO, SPR_PLAY, 13, -1, Nil, S_NULL, 0, 0);
  Set_States(S_DEADBOTTOM, SPR_PLAY, 18, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HEADSONSTICK, SPR_POL2, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_GIBS, SPR_POL5, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HEADONASTICK, SPR_POL4, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HEADCANDLES, SPR_POL3, 32768, 6, Nil, S_HEADCANDLES2, 0, 0);
  Set_States(S_HEADCANDLES2, SPR_POL3, 32769, 6, Nil, S_HEADCANDLES, 0, 0);
  Set_States(S_DEADSTICK, SPR_POL1, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_LIVESTICK, SPR_POL6, 0, 6, Nil, S_LIVESTICK2, 0, 0);
  Set_States(S_LIVESTICK2, SPR_POL6, 1, 8, Nil, S_LIVESTICK, 0, 0);
  Set_States(S_MEAT2, SPR_GOR2, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_MEAT3, SPR_GOR3, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_MEAT4, SPR_GOR4, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_MEAT5, SPR_GOR5, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_STALAGTITE, SPR_SMIT, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_TALLGRNCOL, SPR_COL1, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SHRTGRNCOL, SPR_COL2, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_TALLREDCOL, SPR_COL3, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SHRTREDCOL, SPR_COL4, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_CANDLESTIK, SPR_CAND, 32768, -1, Nil, S_NULL, 0, 0);
  Set_States(S_CANDELABRA, SPR_CBRA, 32768, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SKULLCOL, SPR_COL6, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_TORCHTREE, SPR_TRE1, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_BIGTREE, SPR_TRE2, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_TECHPILLAR, SPR_ELEC, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_EVILEYE, SPR_CEYE, 32768, 6, Nil, S_EVILEYE2, 0, 0);
  Set_States(S_EVILEYE2, SPR_CEYE, 32769, 6, Nil, S_EVILEYE3, 0, 0);
  Set_States(S_EVILEYE3, SPR_CEYE, 32770, 6, Nil, S_EVILEYE4, 0, 0);
  Set_States(S_EVILEYE4, SPR_CEYE, 32769, 6, Nil, S_EVILEYE, 0, 0);
  Set_States(S_FLOATSKULL, SPR_FSKU, 32768, 6, Nil, S_FLOATSKULL2, 0, 0);
  Set_States(S_FLOATSKULL2, SPR_FSKU, 32769, 6, Nil, S_FLOATSKULL3, 0, 0);
  Set_States(S_FLOATSKULL3, SPR_FSKU, 32770, 6, Nil, S_FLOATSKULL, 0, 0);
  Set_States(S_HEARTCOL, SPR_COL5, 0, 14, Nil, S_HEARTCOL2, 0, 0);
  Set_States(S_HEARTCOL2, SPR_COL5, 1, 14, Nil, S_HEARTCOL, 0, 0);
  Set_States(S_BLUETORCH, SPR_TBLU, 32768, 4, Nil, S_BLUETORCH2, 0, 0);
  Set_States(S_BLUETORCH2, SPR_TBLU, 32769, 4, Nil, S_BLUETORCH3, 0, 0);
  Set_States(S_BLUETORCH3, SPR_TBLU, 32770, 4, Nil, S_BLUETORCH4, 0, 0);
  Set_States(S_BLUETORCH4, SPR_TBLU, 32771, 4, Nil, S_BLUETORCH, 0, 0);
  Set_States(S_GREENTORCH, SPR_TGRN, 32768, 4, Nil, S_GREENTORCH2, 0, 0);
  Set_States(S_GREENTORCH2, SPR_TGRN, 32769, 4, Nil, S_GREENTORCH3, 0, 0);
  Set_States(S_GREENTORCH3, SPR_TGRN, 32770, 4, Nil, S_GREENTORCH4, 0, 0);
  Set_States(S_GREENTORCH4, SPR_TGRN, 32771, 4, Nil, S_GREENTORCH, 0, 0);
  Set_States(S_REDTORCH, SPR_TRED, 32768, 4, Nil, S_REDTORCH2, 0, 0);
  Set_States(S_REDTORCH2, SPR_TRED, 32769, 4, Nil, S_REDTORCH3, 0, 0);
  Set_States(S_REDTORCH3, SPR_TRED, 32770, 4, Nil, S_REDTORCH4, 0, 0);
  Set_States(S_REDTORCH4, SPR_TRED, 32771, 4, Nil, S_REDTORCH, 0, 0);
  Set_States(S_BTORCHSHRT, SPR_SMBT, 32768, 4, Nil, S_BTORCHSHRT2, 0, 0);
  Set_States(S_BTORCHSHRT2, SPR_SMBT, 32769, 4, Nil, S_BTORCHSHRT3, 0, 0);
  Set_States(S_BTORCHSHRT3, SPR_SMBT, 32770, 4, Nil, S_BTORCHSHRT4, 0, 0);
  Set_States(S_BTORCHSHRT4, SPR_SMBT, 32771, 4, Nil, S_BTORCHSHRT, 0, 0);
  Set_States(S_GTORCHSHRT, SPR_SMGT, 32768, 4, Nil, S_GTORCHSHRT2, 0, 0);
  Set_States(S_GTORCHSHRT2, SPR_SMGT, 32769, 4, Nil, S_GTORCHSHRT3, 0, 0);
  Set_States(S_GTORCHSHRT3, SPR_SMGT, 32770, 4, Nil, S_GTORCHSHRT4, 0, 0);
  Set_States(S_GTORCHSHRT4, SPR_SMGT, 32771, 4, Nil, S_GTORCHSHRT, 0, 0);
  Set_States(S_RTORCHSHRT, SPR_SMRT, 32768, 4, Nil, S_RTORCHSHRT2, 0, 0);
  Set_States(S_RTORCHSHRT2, SPR_SMRT, 32769, 4, Nil, S_RTORCHSHRT3, 0, 0);
  Set_States(S_RTORCHSHRT3, SPR_SMRT, 32770, 4, Nil, S_RTORCHSHRT4, 0, 0);
  Set_States(S_RTORCHSHRT4, SPR_SMRT, 32771, 4, Nil, S_RTORCHSHRT, 0, 0);
  Set_States(S_HANGNOGUTS, SPR_HDB1, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HANGBNOBRAIN, SPR_HDB2, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HANGTLOOKDN, SPR_HDB3, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HANGTSKULL, SPR_HDB4, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HANGTLOOKUP, SPR_HDB5, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_HANGTNOBRAIN, SPR_HDB6, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_COLONGIBS, SPR_POB1, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_SMALLPOOL, SPR_POB2, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_BRAINSTEM, SPR_BRS1, 0, -1, Nil, S_NULL, 0, 0);
  Set_States(S_TECHLAMP, SPR_TLMP, 32768, 4, Nil, S_TECHLAMP2, 0, 0);
  Set_States(S_TECHLAMP2, SPR_TLMP, 32769, 4, Nil, S_TECHLAMP3, 0, 0);
  Set_States(S_TECHLAMP3, SPR_TLMP, 32770, 4, Nil, S_TECHLAMP4, 0, 0);
  Set_States(S_TECHLAMP4, SPR_TLMP, 32771, 4, Nil, S_TECHLAMP, 0, 0);
  Set_States(S_TECH2LAMP, SPR_TLP2, 32768, 4, Nil, S_TECH2LAMP2, 0, 0);
  Set_States(S_TECH2LAMP2, SPR_TLP2, 32769, 4, Nil, S_TECH2LAMP3, 0, 0);
  Set_States(S_TECH2LAMP3, SPR_TLP2, 32770, 4, Nil, S_TECH2LAMP4, 0, 0);
  Set_States(S_TECH2LAMP4, SPR_TLP2, 32771, 4, Nil, S_TECH2LAMP, 0, 0);
  // [crispy] additional BOOM and MBF states, sprites and code pointers
  Set_States(S_TNT1, SPR_TNT1, 0, -1, Nil, S_TNT1, 0, 0);
  Set_StatesP1(S_GRENADE, SPR_MISL, 32768, 1000, @A_Die, S_GRENADE, 0, 0);
  Set_StatesP1(S_DETONATE, SPR_MISL, 32769, 4, @A_Scream, S_DETONATE2, 0, 0);
  Set_StatesP1(S_DETONATE2, SPR_MISL, 32770, 6, @A_Detonate, S_DETONATE3, 0, 0);
  Set_States(S_DETONATE3, SPR_MISL, 32771, 10, Nil, S_NULL, 0, 0);
  Set_StatesP1(S_DOGS_STND, SPR_DOGS, 0, 10, @A_Look, S_DOGS_STND2, 0, 0);
  Set_StatesP1(S_DOGS_STND2, SPR_DOGS, 1, 10, @A_Look, S_DOGS_STND, 0, 0);
  Set_StatesP1(S_DOGS_RUN1, SPR_DOGS, 0, 2, @A_Chase, S_DOGS_RUN2, 0, 0);
  Set_StatesP1(S_DOGS_RUN2, SPR_DOGS, 0, 2, @A_Chase, S_DOGS_RUN3, 0, 0);
  Set_StatesP1(S_DOGS_RUN3, SPR_DOGS, 1, 2, @A_Chase, S_DOGS_RUN4, 0, 0);
  Set_StatesP1(S_DOGS_RUN4, SPR_DOGS, 1, 2, @A_Chase, S_DOGS_RUN5, 0, 0);
  Set_StatesP1(S_DOGS_RUN5, SPR_DOGS, 2, 2, @A_Chase, S_DOGS_RUN6, 0, 0);
  Set_StatesP1(S_DOGS_RUN6, SPR_DOGS, 2, 2, @A_Chase, S_DOGS_RUN7, 0, 0);
  Set_StatesP1(S_DOGS_RUN7, SPR_DOGS, 3, 2, @A_Chase, S_DOGS_RUN8, 0, 0);
  Set_StatesP1(S_DOGS_RUN8, SPR_DOGS, 3, 2, @A_Chase, S_DOGS_RUN1, 0, 0);
  Set_StatesP1(S_DOGS_ATK1, SPR_DOGS, 4, 8, @A_FaceTarget, S_DOGS_ATK2, 0, 0);
  Set_StatesP1(S_DOGS_ATK2, SPR_DOGS, 5, 8, @A_FaceTarget, S_DOGS_ATK3, 0, 0);
  Set_StatesP1(S_DOGS_ATK3, SPR_DOGS, 6, 8, @A_SargAttack, S_DOGS_RUN1, 0, 0);
  Set_States(S_DOGS_PAIN, SPR_DOGS, 7, 2, Nil, S_DOGS_PAIN2, 0, 0);
  Set_StatesP1(S_DOGS_PAIN2, SPR_DOGS, 7, 2, @A_Pain, S_DOGS_RUN1, 0, 0);
  Set_States(S_DOGS_DIE1, SPR_DOGS, 8, 8, Nil, S_DOGS_DIE2, 0, 0);
  Set_StatesP1(S_DOGS_DIE2, SPR_DOGS, 9, 8, @A_Scream, S_DOGS_DIE3, 0, 0);
  Set_States(S_DOGS_DIE3, SPR_DOGS, 10, 4, Nil, S_DOGS_DIE4, 0, 0);
  Set_StatesP1(S_DOGS_DIE4, SPR_DOGS, 11, 4, @A_Fall, S_DOGS_DIE5, 0, 0);
  Set_States(S_DOGS_DIE5, SPR_DOGS, 12, 4, Nil, S_DOGS_DIE6, 0, 0);
  Set_States(S_DOGS_DIE6, SPR_DOGS, 13, -1, Nil, S_NULL, 0, 0);
  Set_States(S_DOGS_RAISE1, SPR_DOGS, 13, 5, Nil, S_DOGS_RAISE2, 0, 0);
  Set_States(S_DOGS_RAISE2, SPR_DOGS, 12, 5, Nil, S_DOGS_RAISE3, 0, 0);
  Set_States(S_DOGS_RAISE3, SPR_DOGS, 11, 5, Nil, S_DOGS_RAISE4, 0, 0);
  Set_States(S_DOGS_RAISE4, SPR_DOGS, 10, 5, Nil, S_DOGS_RAISE5, 0, 0);
  Set_States(S_DOGS_RAISE5, SPR_DOGS, 9, 5, Nil, S_DOGS_RAISE6, 0, 0);
  Set_States(S_DOGS_RAISE6, SPR_DOGS, 8, 5, Nil, S_DOGS_RUN1, 0, 0);
  Set_States(S_OLDBFG1, SPR_BFGG, 0, 10, @A_BFGsound, S_OLDBFG2, 0, 0);
  Set_States(S_OLDBFG2, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG3, 0, 0);
  Set_States(S_OLDBFG3, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG4, 0, 0);
  Set_States(S_OLDBFG4, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG5, 0, 0);
  Set_States(S_OLDBFG5, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG6, 0, 0);
  Set_States(S_OLDBFG6, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG7, 0, 0);
  Set_States(S_OLDBFG7, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG8, 0, 0);
  Set_States(S_OLDBFG8, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG9, 0, 0);
  Set_States(S_OLDBFG9, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG10, 0, 0);
  Set_States(S_OLDBFG10, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG11, 0, 0);
  Set_States(S_OLDBFG11, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG12, 0, 0);
  Set_States(S_OLDBFG12, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG13, 0, 0);
  Set_States(S_OLDBFG13, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG14, 0, 0);
  Set_States(S_OLDBFG14, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG15, 0, 0);
  Set_States(S_OLDBFG15, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG16, 0, 0);
  Set_States(S_OLDBFG16, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG17, 0, 0);
  Set_States(S_OLDBFG17, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG18, 0, 0);
  Set_States(S_OLDBFG18, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG19, 0, 0);
  Set_States(S_OLDBFG19, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG20, 0, 0);
  Set_States(S_OLDBFG20, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG21, 0, 0);
  Set_States(S_OLDBFG21, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG22, 0, 0);
  Set_States(S_OLDBFG22, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG23, 0, 0);
  Set_States(S_OLDBFG23, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG24, 0, 0);
  Set_States(S_OLDBFG24, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG25, 0, 0);
  Set_States(S_OLDBFG25, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG26, 0, 0);
  Set_States(S_OLDBFG26, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG27, 0, 0);
  Set_States(S_OLDBFG27, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG28, 0, 0);
  Set_States(S_OLDBFG28, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG29, 0, 0);
  Set_States(S_OLDBFG29, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG30, 0, 0);
  Set_States(S_OLDBFG30, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG31, 0, 0);
  Set_States(S_OLDBFG31, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG32, 0, 0);
  Set_States(S_OLDBFG32, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG33, 0, 0);
  Set_States(S_OLDBFG33, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG34, 0, 0);
  Set_States(S_OLDBFG34, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG35, 0, 0);
  Set_States(S_OLDBFG35, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG36, 0, 0);
  Set_States(S_OLDBFG36, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG37, 0, 0);
  Set_States(S_OLDBFG37, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG38, 0, 0);
  Set_States(S_OLDBFG38, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG39, 0, 0);
  Set_States(S_OLDBFG39, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG40, 0, 0);
  Set_States(S_OLDBFG40, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG41, 0, 0);
  Set_States(S_OLDBFG41, SPR_BFGG, 1, 1, @A_FireOldBFG, S_OLDBFG42, 0, 0);
  Set_States(S_OLDBFG42, SPR_BFGG, 1, 0, @A_Light0, S_OLDBFG43, 0, 0);
  Set_States(S_OLDBFG43, SPR_BFGG, 1, 20, @A_ReFire, S_BFG, 0, 0);
  Set_States(S_PLS1BALL, SPR_PLS1, 32768, 6, Nil, S_PLS1BALL2, 0, 0);
  Set_States(S_PLS1BALL2, SPR_PLS1, 32769, 6, Nil, S_PLS1BALL, 0, 0);
  Set_States(S_PLS1EXP, SPR_PLS1, 32770, 4, Nil, S_PLS1EXP2, 0, 0);
  Set_States(S_PLS1EXP2, SPR_PLS1, 32771, 4, Nil, S_PLS1EXP3, 0, 0);
  Set_States(S_PLS1EXP3, SPR_PLS1, 32772, 4, Nil, S_PLS1EXP4, 0, 0);
  Set_States(S_PLS1EXP4, SPR_PLS1, 32773, 4, Nil, S_PLS1EXP5, 0, 0);
  Set_States(S_PLS1EXP5, SPR_PLS1, 32774, 4, Nil, S_NULL, 0, 0);
  Set_States(S_PLS2BALL, SPR_PLS2, 32768, 4, Nil, S_PLS2BALL2, 0, 0);
  Set_States(S_PLS2BALL2, SPR_PLS2, 32769, 4, Nil, S_PLS2BALL, 0, 0);
  Set_States(S_PLS2BALLX1, SPR_PLS2, 32770, 6, Nil, S_PLS2BALLX2, 0, 0);
  Set_States(S_PLS2BALLX2, SPR_PLS2, 32771, 6, Nil, S_PLS2BALLX3, 0, 0);
  Set_States(S_PLS2BALLX3, SPR_PLS2, 32772, 6, Nil, S_NULL, 0, 0);
  Set_States(S_BON3, SPR_BON3, 0, 6, Nil, S_BON3, 0, 0);
  Set_States(S_BON4, SPR_BON4, 0, 6, Nil, S_BON4, 0, 0);
  Set_StatesP1(S_BSKUL_STND, SPR_SKUL, 0, 10, @A_Look, S_BSKUL_STND, 0, 0);
  Set_StatesP1(S_BSKUL_RUN1, SPR_SKUL, 1, 5, @A_Chase, S_BSKUL_RUN2, 0, 0);
  Set_StatesP1(S_BSKUL_RUN2, SPR_SKUL, 2, 5, @A_Chase, S_BSKUL_RUN3, 0, 0);
  Set_StatesP1(S_BSKUL_RUN3, SPR_SKUL, 3, 5, @A_Chase, S_BSKUL_RUN4, 0, 0);
  Set_StatesP1(S_BSKUL_RUN4, SPR_SKUL, 0, 5, @A_Chase, S_BSKUL_RUN1, 0, 0);
  Set_StatesP1(S_BSKUL_ATK1, SPR_SKUL, 4, 4, @A_FaceTarget, S_BSKUL_ATK2, 0, 0);
  Set_StatesP1(S_BSKUL_ATK2, SPR_SKUL, 5, 5, @A_BetaSkullAttack, S_BSKUL_ATK3, 0, 0);
  Set_States(S_BSKUL_ATK3, SPR_SKUL, 5, 4, Nil, S_BSKUL_RUN1, 0, 0);
  Set_States(S_BSKUL_PAIN1, SPR_SKUL, 6, 4, Nil, S_BSKUL_PAIN2, 0, 0);
  Set_StatesP1(S_BSKUL_PAIN2, SPR_SKUL, 7, 2, @A_Pain, S_BSKUL_RUN1, 0, 0);
  Set_States(S_BSKUL_PAIN3, SPR_SKUL, 8, 4, Nil, S_BSKUL_RUN1, 0, 0);
  Set_States(S_BSKUL_DIE1, SPR_SKUL, 9, 5, Nil, S_BSKUL_DIE2, 0, 0);
  Set_States(S_BSKUL_DIE2, SPR_SKUL, 10, 5, Nil, S_BSKUL_DIE3, 0, 0);
  Set_States(S_BSKUL_DIE3, SPR_SKUL, 11, 5, Nil, S_BSKUL_DIE4, 0, 0);
  Set_States(S_BSKUL_DIE4, SPR_SKUL, 12, 5, Nil, S_BSKUL_DIE5, 0, 0);
  Set_StatesP1(S_BSKUL_DIE5, SPR_SKUL, 13, 5, @A_Scream, S_BSKUL_DIE6, 0, 0);
  Set_States(S_BSKUL_DIE6, SPR_SKUL, 14, 5, Nil, S_BSKUL_DIE7, 0, 0);
  Set_StatesP1(S_BSKUL_DIE7, SPR_SKUL, 15, 5, @A_Fall, S_BSKUL_DIE8, 0, 0);
  Set_StatesP1(S_BSKUL_DIE8, SPR_SKUL, 16, 5, @A_Stop, S_BSKUL_DIE8, 0, 0);
  Set_StatesP1(S_MUSHROOM, SPR_MISL, 32769, 8, @A_Mushroom, S_EXPLODE2, 0, 0);

  Set_MobInfo(
    MT_PLAYER, //	"OUR HERO"
    -1, // doomednum
    S_PLAY, // spawnstate
    100, // spawnhealth
    S_PLAY_RUN1, // seestate
    sfx_None, // seesound
    0, // reactiontime
    sfx_None, // attacksound
    S_PLAY_PAIN, // painstate
    255, // painchance
    sfx_plpain, // painsound
    S_NULL, // meleestate
    S_PLAY_ATK1, // missilestate
    S_PLAY_DIE1, // deathstate
    S_PLAY_XDIE1, // xdeathstate
    sfx_pldeth, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_DROPOFF Or MF_PICKUP Or MF_NOTDMATCH Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_POSSESSED, // "ZOMBIEMAN"
    3004, // doomednum
    S_POSS_STND, // spawnstate
    20, // spawnhealth
    S_POSS_RUN1, // seestate
    sfx_posit1, // seesound
    8, // reactiontime
    sfx_pistol, // attacksound
    S_POSS_PAIN, // painstate
    200, // painchance
    sfx_popain, // painsound
    S_NULL, // meleestate
    S_POSS_ATK1, // missilestate
    S_POSS_DIE1, // deathstate
    S_POSS_XDIE1, // xdeathstate
    sfx_podth1, // deathsound
    8, // speed
    20 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_posact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_POSS_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_SHOTGUY, // "SHOTGUN GUY"
    9, // doomednum
    S_SPOS_STND, // spawnstate
    30, // spawnhealth
    S_SPOS_RUN1, // seestate
    sfx_posit2, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_SPOS_PAIN, // painstate
    170, // painchance
    sfx_popain, // painsound
    S_NULL, // meleestate
    S_SPOS_ATK1, // missilestate
    S_SPOS_DIE1, // deathstate
    S_SPOS_XDIE1, // xdeathstate
    sfx_podth2, // deathsound
    8, // speed
    20 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_posact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_SPOS_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_VILE, // "ARCH-VILE"
    64, // doomednum
    S_VILE_STND, // spawnstate
    700, // spawnhealth
    S_VILE_RUN1, // seestate
    sfx_vilsit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_VILE_PAIN, // painstate
    10, // painchance
    sfx_vipain, // painsound
    S_NULL, // meleestate
    S_VILE_ATK1, // missilestate
    S_VILE_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_vildth, // deathsound
    15, // speed
    20 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    500, // mass
    0, // damage
    sfx_vilact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_FIRE, //
    -1, // doomednum
    S_FIRE1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_UNDEAD, // "REVENANT"
    66, // doomednum
    S_SKEL_STND, // spawnstate
    300, // spawnhealth
    S_SKEL_RUN1, // seestate
    sfx_skesit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_SKEL_PAIN, // painstate
    100, // painchance
    sfx_popain, // painsound
    S_SKEL_FIST1, // meleestate
    S_SKEL_MISS1, // missilestate
    S_SKEL_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_skedth, // deathsound
    10, // speed
    20 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    500, // mass
    0, // damage
    sfx_skeact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_SKEL_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_TRACER, //
    -1, // doomednum
    S_TRACER, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_skeatk, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_TRACEEXP1, // deathstate
    S_NULL, // xdeathstate
    sfx_barexp, // deathsound
    10 * FRACUNIT, // speed
    11 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    10, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_SMOKE, //
    -1, // doomednum
    S_SMOKE1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_FATSO, // "MANCUBUS"
    67, // doomednum
    S_FATT_STND, // spawnstate
    600, // spawnhealth
    S_FATT_RUN1, // seestate
    sfx_mansit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_FATT_PAIN, // painstate
    80, // painchance
    sfx_mnpain, // painsound
    S_NULL, // meleestate
    S_FATT_ATK1, // missilestate
    S_FATT_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_mandth, // deathsound
    8, // speed
    48 * FRACUNIT, // radius
    64 * FRACUNIT, // height
    1000, // mass
    0, // damage
    sfx_posact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_FATT_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_FATSHOT, //
    -1, // doomednum
    S_FATSHOT1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_firsht, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_FATSHOTX1, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    20 * FRACUNIT, // speed
    6 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    8, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_CHAINGUY, // "HEAVY WEAPON DUDE"
    65, // doomednum
    S_CPOS_STND, // spawnstate
    70, // spawnhealth
    S_CPOS_RUN1, // seestate
    sfx_posit2, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_CPOS_PAIN, // painstate
    170, // painchance
    sfx_popain, // painsound
    S_NULL, // meleestate
    S_CPOS_ATK1, // missilestate
    S_CPOS_DIE1, // deathstate
    S_CPOS_XDIE1, // xdeathstate
    sfx_podth2, // deathsound
    8, // speed
    20 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_posact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_CPOS_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_TROOP, // "IMP"
    3001, // doomednum
    S_TROO_STND, // spawnstate
    60, // spawnhealth
    S_TROO_RUN1, // seestate
    sfx_bgsit1, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_TROO_PAIN, // painstate
    200, // painchance
    sfx_popain, // painsound
    S_TROO_ATK1, // meleestate
    S_TROO_ATK1, // missilestate
    S_TROO_DIE1, // deathstate
    S_TROO_XDIE1, // xdeathstate
    sfx_bgdth1, // deathsound
    8, // speed
    20 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_bgact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_TROO_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_SERGEANT, // "DEMON"
    3002, // doomednum
    S_SARG_STND, // spawnstate
    150, // spawnhealth
    S_SARG_RUN1, // seestate
    sfx_sgtsit, // seesound
    8, // reactiontime
    sfx_sgtatk, // attacksound
    S_SARG_PAIN, // painstate
    180, // painchance
    sfx_dmpain, // painsound
    S_SARG_ATK1, // meleestate
    S_NULL, // missilestate
    S_SARG_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_sgtdth, // deathsound
    10, // speed
    30 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    400, // mass
    0, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_SARG_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_SHADOWS, //
    58, // doomednum
    S_SARG_STND, // spawnstate
    150, // spawnhealth
    S_SARG_RUN1, // seestate
    sfx_sgtsit, // seesound
    8, // reactiontime
    sfx_sgtatk, // attacksound
    S_SARG_PAIN, // painstate
    180, // painchance
    sfx_dmpain, // painsound
    S_SARG_ATK1, // meleestate
    S_NULL, // missilestate
    S_SARG_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_sgtdth, // deathsound
    10, // speed
    30 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    400, // mass
    0, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_SHADOW Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_SARG_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_HEAD, // "CACODEMON"
    3005, // doomednum
    S_HEAD_STND, // spawnstate
    400, // spawnhealth
    S_HEAD_RUN1, // seestate
    sfx_cacsit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_HEAD_PAIN, // painstate
    128, // painchance
    sfx_dmpain, // painsound
    S_NULL, // meleestate
    S_HEAD_ATK1, // missilestate
    S_HEAD_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_cacdth, // deathsound
    8, // speed
    31 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    400, // mass
    0, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_FLOAT Or MF_NOGRAVITY Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_HEAD_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_BRUISER, // "BARON OF HELL"
    3003, // doomednum
    S_BOSS_STND, // spawnstate
    1000, // spawnhealth
    S_BOSS_RUN1, // seestate
    sfx_brssit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_BOSS_PAIN, // painstate
    50, // painchance
    sfx_dmpain, // painsound
    S_BOSS_ATK1, // meleestate
    S_BOSS_ATK1, // missilestate
    S_BOSS_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_brsdth, // deathsound
    8, // speed
    24 * FRACUNIT, // radius
    64 * FRACUNIT, // height
    1000, // mass
    0, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_BOSS_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_BRUISERSHOT, //
    -1, // doomednum
    S_BRBALL1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_firsht, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_BRBALLX1, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    15 * FRACUNIT, // speed
    6 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    8, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_KNIGHT, // "HELL KNIGHT"
    69, // doomednum
    S_BOS2_STND, // spawnstate
    500, // spawnhealth
    S_BOS2_RUN1, // seestate
    sfx_kntsit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_BOS2_PAIN, // painstate
    50, // painchance
    sfx_dmpain, // painsound
    S_BOS2_ATK1, // meleestate
    S_BOS2_ATK1, // missilestate
    S_BOS2_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_kntdth, // deathsound
    8, // speed
    24 * FRACUNIT, // radius
    64 * FRACUNIT, // height
    1000, // mass
    0, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_BOS2_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_SKULL, // "LOST SOUL"
    3006, // doomednum
    S_SKULL_STND, // spawnstate
    100, // spawnhealth
    S_SKULL_RUN1, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_sklatk, // attacksound
    S_SKULL_PAIN, // painstate
    256, // painchance
    sfx_dmpain, // painsound
    S_NULL, // meleestate
    S_SKULL_ATK1, // missilestate
    S_SKULL_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    8, // speed
    16 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    50, // mass
    3, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_FLOAT Or MF_NOGRAVITY Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_SPIDER, // "THE SPIDER MASTERMIND"
    7, // doomednum
    S_SPID_STND, // spawnstate
    3000, // spawnhealth
    S_SPID_RUN1, // seestate
    sfx_spisit, // seesound
    8, // reactiontime
    sfx_shotgn, // attacksound
    S_SPID_PAIN, // painstate
    40, // painchance
    sfx_dmpain, // painsound
    S_NULL, // meleestate
    S_SPID_ATK1, // missilestate
    S_SPID_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_spidth, // deathsound
    12, // speed
    128 * FRACUNIT, // radius
    100 * FRACUNIT, // height
    1000, // mass
    0, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_BABY, // "ARACHNOTRON"
    68, // doomednum
    S_BSPI_STND, // spawnstate
    500, // spawnhealth
    S_BSPI_SIGHT, // seestate
    sfx_bspsit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_BSPI_PAIN, // painstate
    128, // painchance
    sfx_dmpain, // painsound
    S_NULL, // meleestate
    S_BSPI_ATK1, // missilestate
    S_BSPI_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_bspdth, // deathsound
    12, // speed
    64 * FRACUNIT, // radius
    64 * FRACUNIT, // height
    600, // mass
    0, // damage
    sfx_bspact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_BSPI_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_CYBORG, // "THE CYBERDEMON"
    16, // doomednum
    S_CYBER_STND, // spawnstate
    4000, // spawnhealth
    S_CYBER_RUN1, // seestate
    sfx_cybsit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_CYBER_PAIN, // painstate
    20, // painchance
    sfx_dmpain, // painsound
    S_NULL, // meleestate
    S_CYBER_ATK1, // missilestate
    S_CYBER_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_cybdth, // deathsound
    16, // speed
    40 * FRACUNIT, // radius
    110 * FRACUNIT, // height
    1000, // mass
    0, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_PAIN, // "PAIN ELEMENTAL"
    71, // doomednum
    S_PAIN_STND, // spawnstate
    400, // spawnhealth
    S_PAIN_RUN1, // seestate
    sfx_pesit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_PAIN_PAIN, // painstate
    128, // painchance
    sfx_pepain, // painsound
    S_NULL, // meleestate
    S_PAIN_ATK1, // missilestate
    S_PAIN_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_pedth, // deathsound
    8, // speed
    31 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    400, // mass
    0, // damage
    sfx_dmact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_FLOAT Or MF_NOGRAVITY Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_PAIN_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_WOLFSS, //
    84, // doomednum
    S_SSWV_STND, // spawnstate
    50, // spawnhealth
    S_SSWV_RUN1, // seestate
    sfx_sssit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_SSWV_PAIN, // painstate
    170, // painchance
    sfx_popain, // painsound
    S_NULL, // meleestate
    S_SSWV_ATK1, // missilestate
    S_SSWV_DIE1, // deathstate
    S_SSWV_XDIE1, // xdeathstate
    sfx_ssdth, // deathsound
    8, // speed
    20 * FRACUNIT, // radius
    56 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_posact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_SSWV_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_KEEN, //
    72, // doomednum
    S_KEENSTND, // spawnstate
    100, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_KEENPAIN, // painstate
    256, // painchance
    sfx_keenpn, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_COMMKEEN, // deathstate
    S_NULL, // xdeathstate
    sfx_keendt, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    72 * FRACUNIT, // height
    10000000, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_BOSSBRAIN, //
    88, // doomednum
    S_BRAIN, // spawnstate
    250, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_BRAIN_PAIN, // painstate
    255, // painchance
    sfx_bospn, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_BRAIN_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_bosdth, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    10000000, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SHOOTABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_BOSSSPIT, //
    89, // doomednum
    S_BRAINEYE, // spawnstate
    1000, // spawnhealth
    S_BRAINEYESEE, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    32 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP Or MF_NOSECTOR, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_BOSSTARGET, //
    87, // doomednum
    S_NULL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    32 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP Or MF_NOSECTOR, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_SPAWNSHOT, //
    -1, // doomednum
    S_SPAWN1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_bospit, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    10 * FRACUNIT, // speed
    6 * FRACUNIT, // radius
    32 * FRACUNIT, // height
    100, // mass
    3, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_NOCLIP, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_SPAWNFIRE, //
    -1, // doomednum
    S_SPAWNFIRE1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_BARREL, //
    2035, // doomednum
    S_BAR1, // spawnstate
    20, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_BEXP, // deathstate
    S_NULL, // xdeathstate
    sfx_barexp, // deathsound
    0, // speed
    10 * FRACUNIT, // radius
    42 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_NOBLOOD, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_TROOPSHOT, //
    -1, // doomednum
    S_TBALL1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_firsht, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_TBALLX1, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    10 * FRACUNIT, // speed
    6 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    3, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_HEADSHOT, //
    -1, // doomednum
    S_RBALL1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_firsht, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_RBALLX1, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    10 * FRACUNIT, // speed
    6 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    5, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_ROCKET, //
    -1, // doomednum
    S_ROCKET, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_rlaunc, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_EXPLODE1, // deathstate
    S_NULL, // xdeathstate
    sfx_barexp, // deathsound
    20 * FRACUNIT, // speed
    11 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    20, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_PLASMA, //
    -1, // doomednum
    S_PLASBALL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_plasma, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_PLASEXP, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    25 * FRACUNIT, // speed
    13 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    5, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_BFG, //
    -1, // doomednum
    S_BFGSHOT, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_BFGLAND, // deathstate
    S_NULL, // xdeathstate
    sfx_rxplod, // deathsound
    25 * FRACUNIT, // speed
    13 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    100, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_ARACHPLAZ, //
    -1, // doomednum
    S_ARACH_PLAZ, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_plasma, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_ARACH_PLEX, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    25 * FRACUNIT, // speed
    13 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    5, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_PUFF, //
    -1, // doomednum
    S_PUFF1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_NOGRAVITY Or MF_FLIPPABLE Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_BLOOD, //
    -1, // doomednum
    S_BLOOD1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_TFOG, //
    -1, // doomednum
    S_TFOG, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_IFOG, //
    -1, // doomednum
    S_IFOG, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_TELEPORTMAN, //
    14, // doomednum
    S_NULL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP Or MF_NOSECTOR, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_EXTRABFG, //
    -1, // doomednum
    S_BFGEXP, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_NOBLOCKMAP Or MF_NOGRAVITY Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC0, //
    2018, // doomednum
    S_ARM1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC1, //
    2019, // doomednum
    S_ARM2, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC2, //
    2014, // doomednum
    S_BON1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_COUNTITEM, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC3, //
    2015, // doomednum
    S_BON2, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_COUNTITEM, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC4, //
    5, // doomednum
    S_BKEY, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_NOTDMATCH, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC5, //
    13, // doomednum
    S_RKEY, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_NOTDMATCH, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC6, //
    6, // doomednum
    S_YKEY, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_NOTDMATCH, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC7, //
    39, // doomednum
    S_YSKULL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_NOTDMATCH, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC8, //
    38, // doomednum
    S_RSKULL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_NOTDMATCH, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC9, //
    40, // doomednum
    S_BSKULL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_NOTDMATCH, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC10, //
    2011, // doomednum
    S_STIM, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC11, //
    2012, // doomednum
    S_MEDI, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC12, //
    2013, // doomednum
    S_SOUL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_SPECIAL Or MF_COUNTITEM Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_INV, //
    2022, // doomednum
    S_PINV, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_SPECIAL Or MF_COUNTITEM Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC13, //
    2023, // doomednum
    S_PSTR, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_COUNTITEM, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_INS, //
    2024, // doomednum
    S_PINS, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_SPECIAL Or MF_COUNTITEM Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC14, //
    2025, // doomednum
    S_SUIT, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC15, //
    2026, // doomednum
    S_PMAP, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_COUNTITEM, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC16, //
    2045, // doomednum
    S_PVIS, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_COUNTITEM, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MEGA, //
    83, // doomednum
    S_MEGA, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    int(MF_SPECIAL Or MF_COUNTITEM Or MF_TRANSLUCENT), // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_CLIP, //
    2007, // doomednum
    S_CLIP, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC17, //
    2048, // doomednum
    S_AMMO, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC18, //
    2010, // doomednum
    S_ROCK, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC19, //
    2046, // doomednum
    S_BROK, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC20, //
    2047, // doomednum
    S_CELL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC21, //
    17, // doomednum
    S_CELP, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC22, //
    2008, // doomednum
    S_SHEL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC23, //
    2049, // doomednum
    S_SBOX, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC24, //
    8, // doomednum
    S_BPAK, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC25, //
    2006, // doomednum
    S_BFUG, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_CHAINGUN, //
    2002, // doomednum
    S_MGUN, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC26, //
    2005, // doomednum
    S_CSAW, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC27, //
    2003, // doomednum
    S_LAUN, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC28, //
    2004, // doomednum
    S_PLAS, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_SHOTGUN, //
    2001, // doomednum
    S_SHOT, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_SUPERSHOTGUN, //
    82, // doomednum
    S_SHOT2, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC29, //
    85, // doomednum
    S_TECHLAMP, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC30, //
    86, // doomednum
    S_TECH2LAMP, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC31, //
    2028, // doomednum
    S_COLU, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC32, //
    30, // doomednum
    S_TALLGRNCOL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC33, //
    31, // doomednum
    S_SHRTGRNCOL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC34, //
    32, // doomednum
    S_TALLREDCOL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC35, //
    33, // doomednum
    S_SHRTREDCOL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC36, //
    37, // doomednum
    S_SKULLCOL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC37, //
    36, // doomednum
    S_HEARTCOL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC38, //
    41, // doomednum
    S_EVILEYE, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC39, //
    42, // doomednum
    S_FLOATSKULL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC40, //
    43, // doomednum
    S_TORCHTREE, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC41, //
    44, // doomednum
    S_BLUETORCH, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC42, //
    45, // doomednum
    S_GREENTORCH, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC43, //
    46, // doomednum
    S_REDTORCH, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC44, //
    55, // doomednum
    S_BTORCHSHRT, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC45, //
    56, // doomednum
    S_GTORCHSHRT, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC46, //
    57, // doomednum
    S_RTORCHSHRT, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC47, //
    47, // doomednum
    S_STALAGTITE, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC48, //
    48, // doomednum
    S_TECHPILLAR, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC49, //
    34, // doomednum
    S_CANDLESTIK, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC50, //
    35, // doomednum
    S_CANDELABRA, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC51, //
    49, // doomednum
    S_BLOODYTWITCH, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    68 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC52, //
    50, // doomednum
    S_MEAT2, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    84 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC53, //
    51, // doomednum
    S_MEAT3, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    84 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC54, //
    52, // doomednum
    S_MEAT4, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    68 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC55, //
    53, // doomednum
    S_MEAT5, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    52 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC56, //
    59, // doomednum
    S_MEAT2, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    84 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC57, //
    60, // doomednum
    S_MEAT4, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    68 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC58, //
    61, // doomednum
    S_MEAT3, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    52 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC59, //
    62, // doomednum
    S_MEAT5, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    52 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC60, //
    63, // doomednum
    S_BLOODYTWITCH, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    68 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC61, //
    22, // doomednum
    S_HEAD_DIE6, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC62, //
    15, // doomednum
    S_PLAY_DIE7, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC63, //
    18, // doomednum
    S_POSS_DIE5, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC64, //
    21, // doomednum
    S_SARG_DIE6, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC65, //
    23, // doomednum
    S_SKULL_DIE6, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC66, //
    20, // doomednum
    S_TROO_DIE5, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC67, //
    19, // doomednum
    S_SPOS_DIE5, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC68, //
    10, // doomednum
    S_PLAY_XDIE9, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC69, //
    12, // doomednum
    S_PLAY_XDIE9, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0 Or MF_FLIPPABLE, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC70, //
    28, // doomednum
    S_HEADSONSTICK, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC71, //
    24, // doomednum
    S_GIBS, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    0, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC72, //
    27, // doomednum
    S_HEADONASTICK, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC73, //
    29, // doomednum
    S_HEADCANDLES, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC74, //
    25, // doomednum
    S_DEADSTICK, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC75, //
    26, // doomednum
    S_LIVESTICK, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC76, //
    54, // doomednum
    S_BIGTREE, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    32 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC77, //
    70, // doomednum
    S_BBAR1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC78, //
    73, // doomednum
    S_HANGNOGUTS, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    88 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC79, //
    74, // doomednum
    S_HANGBNOBRAIN, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    88 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC80, //
    75, // doomednum
    S_HANGTLOOKDN, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    64 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC81, //
    76, // doomednum
    S_HANGTSKULL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    64 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC82, //
    77, // doomednum
    S_HANGTLOOKUP, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    64 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC83, //
    78, // doomednum
    S_HANGTNOBRAIN, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16 * FRACUNIT, // radius
    64 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SOLID Or MF_SPAWNCEILING Or MF_NOGRAVITY, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC84, //
    79, // doomednum
    S_COLONGIBS, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC85, //
    80, // doomednum
    S_SMALLPOOL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_MISC86, //
    81, // doomednum
    S_BRAINSTEM, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP, // flags
    S_NULL // raisestate
    );

  // [crispy] additional BOOM and MBF states, sprites and code pointers
  Set_MobInfo(
    MT_PUSH, //
    5001, // doomednum
    S_TNT1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    8, // radius
    8, // height
    10, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_PULL, //
    5002, // doomednum
    S_TNT1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    8, // radius
    8, // height
    10, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_DOGS, //
    888, // doomednum
    S_DOGS_STND, // spawnstate
    500, // spawnhealth
    S_DOGS_RUN1, // seestate
    sfx_dgsit, // seesound
    8, // reactiontime
    sfx_dgatk, // attacksound
    S_DOGS_PAIN, // painstate
    180, // painchance
    sfx_dgpain, // painsound
    S_DOGS_ATK1, // meleestate
    S_NULL, // missilestate
    S_DOGS_DIE1, // deathstate
    S_NULL, // xdeathstate
    sfx_dgdth, // deathsound
    10, // speed
    12 * FRACUNIT, // radius
    28 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_dgact, // activesound
    MF_SOLID Or MF_SHOOTABLE Or MF_COUNTKILL Or MF_FLIPPABLE, // flags
    S_DOGS_RAISE1 // raisestate
    );

  Set_MobInfo(
    MT_PLASMA1, //
    -1, // doomednum
    S_PLS1BALL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_plasma, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_PLS1EXP, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    25 * FRACUNIT, // speed
    13 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    4, // damage
    sfx_None, // activesound
    // [NS] Beta projectile bouncing.
    MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_BOUNCES,
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_PLASMA2, //
    -1, // doomednum
    S_PLS2BALL, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_plasma, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_PLS2BALLX1, // deathstate
    S_NULL, // xdeathstate
    sfx_firxpl, // deathsound
    25 * FRACUNIT, // speed
    6 * FRACUNIT, // radius
    8 * FRACUNIT, // height
    100, // mass
    4, // damage
    sfx_None, // activesound
    // [NS] Beta projectile bouncing.
    MF_NOBLOCKMAP Or MF_MISSILE Or MF_DROPOFF Or MF_NOGRAVITY Or MF_BOUNCES,
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_SCEPTRE, //
    2016, // doomednum
    S_BON3, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    10 * FRACUNIT, // radius
    16 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_COUNTITEM, // flags
    S_NULL // raisestate
    );

  Set_MobInfo(
    MT_BIBLE, //
    2017, // doomednum
    S_BON4, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    20 * FRACUNIT, // radius
    10 * FRACUNIT, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_SPECIAL Or MF_COUNTITEM, // flags
    S_NULL // raisestate
    );

  // [crispy] support MUSINFO lump (dynamic music changing)
  Set_MobInfo(
    MT_MUSICSOURCE, //
    14164, // doomednum
    S_TNT1, // spawnstate
    1000, // spawnhealth
    S_NULL, // seestate
    sfx_None, // seesound
    8, // reactiontime
    sfx_None, // attacksound
    S_NULL, // painstate
    0, // painchance
    sfx_None, // painsound
    S_NULL, // meleestate
    S_NULL, // missilestate
    S_NULL, // deathstate
    S_NULL, // xdeathstate
    sfx_None, // deathsound
    0, // speed
    16, // radius
    16, // height
    100, // mass
    0, // damage
    sfx_None, // activesound
    MF_NOBLOCKMAP, // flags
    S_NULL // raisestate
    );




End.

