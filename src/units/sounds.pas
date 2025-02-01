Unit sounds;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Type
  //
  // SoundFX struct.
  //
  Psfxinfo_t = ^sfxinfo_t;

  sfxinfo_t = Record

    // tag name, used for hexen.
    tagname: String;

    // lump name.  If we are running with use_sfx_prefix=true, a
    // 'DS' (or 'DP' for PC speaker sounds) is prepended to this.

    name: String;

    // Sfx priority
    priority: int;

    // referenced sound if a link
    link: Psfxinfo_t;

    // pitch if a link (Doom), whether to pitch-shift (Hexen)
    pitch: int;

    // volume if a link
    volume: int;

    // this is checked every second to see if sound
    // can be thrown out (if 0, then decrement, if -1,
    // then throw out, if > 0, then it is in use)
    usefulness: int;

    // lump number of sfx
    lumpnum: int;

    // Maximum number of channels that the sound can be played on
    // (Heretic)
    numchannels: int;

    // data used by the low level code
//    void *driver_data;
  End;

  //
  // Identifiers for all music in game.
  //

  musicenum_t =
    (
    mus_None,
    mus_e1m1,
    mus_e1m2,
    mus_e1m3,
    mus_e1m4,
    mus_e1m5,
    mus_e1m6,
    mus_e1m7,
    mus_e1m8,
    mus_e1m9,
    mus_e2m1,
    mus_e2m2,
    mus_e2m3,
    mus_e2m4,
    mus_e2m5,
    mus_e2m6,
    mus_e2m7,
    mus_e2m8,
    mus_e2m9,
    mus_e3m1,
    mus_e3m2,
    mus_e3m3,
    mus_e3m4,
    mus_e3m5,
    mus_e3m6,
    mus_e3m7,
    mus_e3m8,
    mus_e3m9,
    // [crispy] support dedicated music tracks for the 4th episode
    mus_e4m1,
    mus_e4m2,
    mus_e4m3,
    mus_e4m4,
    mus_e4m5,
    mus_e4m6,
    mus_e4m7,
    mus_e4m8,
    mus_e4m9,
    // [crispy] Sigil
    mus_e5m1,
    mus_e5m2,
    mus_e5m3,
    mus_e5m4,
    mus_e5m5,
    mus_e5m6,
    mus_e5m7,
    mus_e5m8,
    mus_e5m9,
    // [crispy] Sigil II
    mus_e6m1,
    mus_e6m2,
    mus_e6m3,
    mus_e6m4,
    mus_e6m5,
    mus_e6m6,
    mus_e6m7,
    mus_e6m8,
    mus_e6m9,
    mus_sigint,
    mus_sg2int,
    mus_inter,
    mus_intro,
    mus_bunny,
    mus_victor,
    mus_introa,
    mus_runnin,
    mus_stalks,
    mus_countd,
    mus_betwee,
    mus_doom,
    mus_the_da,
    mus_shawn,
    mus_ddtblu,
    mus_in_cit,
    mus_dead,
    mus_stlks2,
    mus_theda2,
    mus_doom2,
    mus_ddtbl2,
    mus_runni2,
    mus_dead2,
    mus_stlks3,
    mus_romero,
    mus_shawn2,
    mus_messag,
    mus_count2,
    mus_ddtbl3,
    mus_ampie,
    mus_theda3,
    mus_adrian,
    mus_messg2,
    mus_romer2,
    mus_tense,
    mus_shawn3,
    mus_openin,
    mus_evil,
    mus_ultima,
    mus_read_m,
    mus_dm2ttl,
    mus_dm2int,
    // [crispy] NRFTL
    mus_nrftl1,
    mus_nrftl2,
    mus_nrftl3,
    mus_nrftl4,
    mus_nrftl5,
    mus_nrftl6,
    mus_nrftl7,
    mus_nrftl8,
    mus_nrftl9,
    NUMMUSIC,
    mus_musinfo
    );

  //
  // Identifiers for all sfx in game.
  //

  sfxenum_t =
    (
    sfx_None,
    sfx_pistol,
    sfx_shotgn,
    sfx_sgcock,
    sfx_dshtgn,
    sfx_dbopn,
    sfx_dbcls,
    sfx_dbload,
    sfx_plasma,
    sfx_bfg,
    sfx_sawup,
    sfx_sawidl,
    sfx_sawful,
    sfx_sawhit,
    sfx_rlaunc,
    sfx_rxplod,
    sfx_firsht,
    sfx_firxpl,
    sfx_pstart,
    sfx_pstop,
    sfx_doropn,
    sfx_dorcls,
    sfx_stnmov,
    sfx_swtchn,
    sfx_swtchx,
    sfx_plpain,
    sfx_dmpain,
    sfx_popain,
    sfx_vipain,
    sfx_mnpain,
    sfx_pepain,
    sfx_slop,
    sfx_itemup,
    sfx_wpnup,
    sfx_oof,
    sfx_telept,
    sfx_posit1,
    sfx_posit2,
    sfx_posit3,
    sfx_bgsit1,
    sfx_bgsit2,
    sfx_sgtsit,
    sfx_cacsit,
    sfx_brssit,
    sfx_cybsit,
    sfx_spisit,
    sfx_bspsit,
    sfx_kntsit,
    sfx_vilsit,
    sfx_mansit,
    sfx_pesit,
    sfx_sklatk,
    sfx_sgtatk,
    sfx_skepch,
    sfx_vilatk,
    sfx_claw,
    sfx_skeswg,
    sfx_pldeth,
    sfx_pdiehi,
    sfx_podth1,
    sfx_podth2,
    sfx_podth3,
    sfx_bgdth1,
    sfx_bgdth2,
    sfx_sgtdth,
    sfx_cacdth,
    sfx_skldth,
    sfx_brsdth,
    sfx_cybdth,
    sfx_spidth,
    sfx_bspdth,
    sfx_vildth,
    sfx_kntdth,
    sfx_pedth,
    sfx_skedth,
    sfx_posact,
    sfx_bgact,
    sfx_dmact,
    sfx_bspact,
    sfx_bspwlk,
    sfx_vilact,
    sfx_noway,
    sfx_barexp,
    sfx_punch,
    sfx_hoof,
    sfx_metal,
    sfx_chgun,
    sfx_tink,
    sfx_bdopn,
    sfx_bdcls,
    sfx_itmbk,
    sfx_flame,
    sfx_flamst,
    sfx_getpow,
    sfx_bospit,
    sfx_boscub,
    sfx_bossit,
    sfx_bospn,
    sfx_bosdth,
    sfx_manatk,
    sfx_mandth,
    sfx_sssit,
    sfx_ssdth,
    sfx_keenpn,
    sfx_keendt,
    sfx_skeact,
    sfx_skesit,
    sfx_skeatk,
    sfx_radio,
    // [crispy] additional BOOM and MBF states, sprites and code pointers
    sfx_dgsit,
    sfx_dgatk,
    sfx_dgact,
    sfx_dgdth,
    sfx_dgpain,
    // [crispy] play DSSECRET if available
    sfx_secret,
    // [NS] New optional sounds.
    sfx_pljump,
    sfx_plland,
    sfx_locked,
    sfx_keyup,
    // [NS] Optional menu/intermission sounds.
    sfx_mnuopn,
    sfx_mnucls,
    sfx_mnuact,
    sfx_mnubak,
    sfx_mnumov,
    sfx_mnusli,
    sfx_mnuerr,
    sfx_inttic,
    sfx_inttot,
    sfx_intnex,
    sfx_intnet,
    sfx_intdms,
    NUMSFX
    );

Var
  s_sfx: Array Of sfxinfo_t = Nil; // Wird über initialization erzeugt

Implementation

Procedure Sound(name: String; Priority: int);
Begin
  setlength(s_sfx, high(s_sfx) + 2);
  s_sfx[high(s_sfx)].tagname := '';
  s_sfx[high(s_sfx)].name := name;
  s_sfx[high(s_sfx)].priority := Priority;
  s_sfx[high(s_sfx)].link := Nil;
  s_sfx[high(s_sfx)].pitch := -1;
  s_sfx[high(s_sfx)].volume := -1;
  s_sfx[high(s_sfx)].usefulness := 0;
  s_sfx[high(s_sfx)].lumpnum := 0;
  s_sfx[high(s_sfx)].numchannels := -1;
//  s_sfx[high(s_sfx)].driver_data := Nil;
End;

Procedure Sound_Link(name: String; priority: int; link_id: sfxenum_t; pitch, volume: int);
Begin
  setlength(s_sfx, high(s_sfx) + 2);
  s_sfx[high(s_sfx)].tagname := '';
  s_sfx[high(s_sfx)].name := name;
  s_sfx[high(s_sfx)].priority := Priority;
  s_sfx[high(s_sfx)].link := @s_sfx[integer(link_id)];
  s_sfx[high(s_sfx)].pitch := pitch;
  s_sfx[high(s_sfx)].volume := volume;
  s_sfx[high(s_sfx)].usefulness := 0;
  s_sfx[high(s_sfx)].lumpnum := 0;
  s_sfx[high(s_sfx)].numchannels := -1;
//  s_sfx[high(s_sfx)].driver_data := Nil;
End;

Initialization

  // S_sfx[0] needs to be a dummy for odd reasons.
  SOUND('none', 0);
  SOUND('pistol', 64);
  SOUND('shotgn', 64);
  SOUND('sgcock', 64);
  SOUND('dshtgn', 64);
  SOUND('dbopn', 64);
  SOUND('dbcls', 64);
  SOUND('dbload', 64);
  SOUND('plasma', 64);
  SOUND('bfg', 64);
  SOUND('sawup', 64);
  SOUND('sawidl', 118);
  SOUND('sawful', 64);
  SOUND('sawhit', 64);
  SOUND('rlaunc', 64);
  SOUND('rxplod', 70);
  SOUND('firsht', 70);
  SOUND('firxpl', 70);
  SOUND('pstart', 100);
  SOUND('pstop', 100);
  SOUND('doropn', 100);
  SOUND('dorcls', 100);
  SOUND('stnmov', 119);
  SOUND('swtchn', 78);
  SOUND('swtchx', 78);
  SOUND('plpain', 96);
  SOUND('dmpain', 96);
  SOUND('popain', 96);
  SOUND('vipain', 96);
  SOUND('mnpain', 96);
  SOUND('pepain', 96);
  SOUND('slop', 78);
  SOUND('itemup', 78);
  SOUND('wpnup', 78);
  SOUND('oof', 96);
  SOUND('telept', 32);
  SOUND('posit1', 98);
  SOUND('posit2', 98);
  SOUND('posit3', 98);
  SOUND('bgsit1', 98);
  SOUND('bgsit2', 98);
  SOUND('sgtsit', 98);
  SOUND('cacsit', 98);
  SOUND('brssit', 94);
  SOUND('cybsit', 92);
  SOUND('spisit', 90);
  SOUND('bspsit', 90);
  SOUND('kntsit', 90);
  SOUND('vilsit', 90);
  SOUND('mansit', 90);
  SOUND('pesit', 90);
  SOUND('sklatk', 70);
  SOUND('sgtatk', 70);
  SOUND('skepch', 70);
  SOUND('vilatk', 70);
  SOUND('claw', 70);
  SOUND('skeswg', 70);
  SOUND('pldeth', 32);
  SOUND('pdiehi', 32);
  SOUND('podth1', 70);
  SOUND('podth2', 70);
  SOUND('podth3', 70);
  SOUND('bgdth1', 70);
  SOUND('bgdth2', 70);
  SOUND('sgtdth', 70);
  SOUND('cacdth', 70);
  SOUND('skldth', 70);
  SOUND('brsdth', 32);
  SOUND('cybdth', 32);
  SOUND('spidth', 32);
  SOUND('bspdth', 32);
  SOUND('vildth', 32);
  SOUND('kntdth', 32);
  SOUND('pedth', 32);
  SOUND('skedth', 32);
  SOUND('posact', 120);
  SOUND('bgact', 120);
  SOUND('dmact', 120);
  SOUND('bspact', 100);
  SOUND('bspwlk', 100);
  SOUND('vilact', 100);
  SOUND('noway', 78);
  SOUND('barexp', 60);
  SOUND('punch', 64);
  SOUND('hoof', 70);
  SOUND('metal', 70);
  SOUND_LINK('chgun', 64, sfx_pistol, 150, 0);
  SOUND('tink', 60);
  SOUND('bdopn', 100);
  SOUND('bdcls', 100);
  SOUND('itmbk', 100);
  SOUND('flame', 32);
  SOUND('flamst', 32);
  SOUND('getpow', 60);
  SOUND('bospit', 70);
  SOUND('boscub', 70);
  SOUND('bossit', 70);
  SOUND('bospn', 70);
  SOUND('bosdth', 70);
  SOUND('manatk', 70);
  SOUND('mandth', 70);
  SOUND('sssit', 70);
  SOUND('ssdth', 70);
  SOUND('keenpn', 70);
  SOUND('keendt', 70);
  SOUND('skeact', 70);
  SOUND('skesit', 70);
  SOUND('skeatk', 70);
  SOUND('radio', 60);
  // [crispy] additional BOOM and MBF states, sprites and code pointers
  SOUND('dgsit', 98);
  SOUND('dgatk', 70);
  SOUND('dgact', 120);
  SOUND('dgdth', 70);
  SOUND('dgpain', 96);
  // [crispy] play DSSECRET if available
  SOUND('secret', 60);
  // [NS] New optional sounds.
  SOUND('pljump', 78);
  SOUND('plland', 78);
  SOUND('locked', 78);
  SOUND('keyup', 78);
  // [NS] Optional menu/intermission sounds.
  SOUND('mnuopn', 60);
  SOUND('mnucls', 60);
  SOUND('mnuact', 60);
  SOUND('mnubak', 60);
  SOUND('mnumov', 60);
  SOUND('mnusli', 60);
  SOUND('mnuerr', 60);
  SOUND('inttic', 60);
  SOUND('inttot', 60);
  SOUND('intnex', 60);
  SOUND('intnet', 60);
  SOUND('intdms', 60);

End.

