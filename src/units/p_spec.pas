Unit p_spec;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils,
  info_types, doomdef
  , m_fixed
  ;

Const
  VDOORSPEED = FRACUNIT * 2;
  VDOORWAIT = 150;

  // max # of wall switches in a level
  DEFINE_MAXSWITCHES = 50;

  // 4 players, 4 buttons each at once, max.
  DEFINE_MAXBUTTONS = MAXPLAYERS * 4;
  DEFINE_MAXANIMS = 32;

  // 1 second, in ticks.
  BUTTONTIME = 35;
  GLOWSPEED = 8;
  STROBEBRIGHT = 5;
  FASTDARK = 15;
  SLOWDARK = 35;
  CEILSPEED = FRACUNIT;
  CEILWAIT = 150;
  MAXCEILINGS = 30;


  PLATWAIT = 3;
  PLATSPEED = FRACUNIT;
  MAXPLATS = 30 * 256;

  //
  // P_FLOOR
  //
Type
  floor_e = (
    // lower floor to highest surrounding floor
    lowerFloor,

    // lower floor to lowest surrounding floor
    lowerFloorToLowest,

    // lower floor to highest surrounding floor VERY FAST
    turboLower,

    // raise floor to lowest surrounding CEILING
    raiseFloor,

    // raise floor to next highest surrounding floor
    raiseFloorToNearest,

    // raise floor to shortest height texture around it
    raiseToTexture,

    // lower floor to lowest surrounding floor
    //  and change floorpic
    lowerAndChange,

    raiseFloor24,
    raiseFloor24AndChange,
    raiseFloorCrush,

    // raise to next highest floor, turbo-speed
    raiseFloorTurbo,
    donutRaise,
    raiseFloor512
    );

  //
  // P_DOORS
  //
  vldoor_e = (
    vld_normal,
    vld_close30ThenOpen,
    vld_close,
    vld_open,
    vld_raiseIn5Mins,
    vld_blazeRaise,
    vld_blazeOpen,
    vld_blazeClose
    );

  vldoor_t = Record
    thinker: thinker_t;
    _type: vldoor_e;
    sector: Psector_t;
    topheight: fixed_t;
    speed: fixed_t;

    // 1 = up, 0 = waiting at top, -1 = down
    direction: int;

    // tics to wait at the top
    topwait: int;
    // (keep in case a door going down is reset)
    // when it reaches 0, start going down
    topcountdown: int;
  End;
  Pvldoor_t = ^vldoor_t;

  plattype_e = (
    perpetualRaise,
    downWaitUpStay,
    raiseAndChange,
    raiseToNearestAndChange,
    blazeDWUS
    );

  result_e = (
    ok,
    crushed,
    pastdest
    );

  //
  // P_SWITCH
  //
  // [crispy] add PACKEDATTR for reading SWITCHES lumps from memory
  switchlist_t = Packed Record
    name1: String[9];
    name2: String[9];
    episode: short;
  End;

  bwhere_e = (top, middle, bottom);

  button_t = Record
    line: Pline_t;
    where: bwhere_e;
    btexture: int;
    btimer: int;
    soundorg: Pdegenmobj_t;
  End;

  ceiling_e =
    (
    lowerToFloor,
    raiseToHighest,
    lowerAndCrush,
    crushAndRaise,
    fastCrushAndRaise,
    silentCrushAndRaise
    );

  ceiling_t = Record
    thinker: thinker_t;
    _type: ceiling_e;
    sector: Psector_t;
    bottomheight: fixed_t;
    topheight: fixed_t;
    speed: fixed_t;
    crush: boolean;

    // 1 = up, 0 = waiting, -1 = down
    direction: int;

    // ID
    tag: int;
    olddirection: int;
  End;
  Pceiling_t = ^ceiling_t;

  plat_e =
    (
    up,
    down,
    waiting,
    in_stasis
    );

  plat_t = Record
    thinker: thinker_t;
    sector: Psector_t;
    speed: fixed_t;
    low: fixed_t;
    high: fixed_t;
    wait: int;
    count: int;
    status: plat_e;
    oldstatus: plat_e;
    crush: boolean;
    tag: int;
    _type: plattype_e;
  End;
  Pplat_t = ^plat_t;

  animdef_t = Packed Record
    istexture: signed_char; // if false, it is a flat
    endname: String[9];
    startname: String[9];
    speed: int;
  End;
  Panimdef_t = ^animdef_t;

  lightflash_t = Record
    thinker: thinker_t;
    sector: Psector_t;
    count: int;
    maxlight: int;
    minlight: int;
    maxtime: int;
    mintime: int;
  End;
  Plightflash_t = ^lightflash_t;

  glow_t = Record
    thinker: thinker_t;
    sector: Psector_t;
    minlight: int;
    maxlight: int;
    direction: int;
  End;
  Pglow_t = ^glow_t;

  strobe_t = Record
    thinker: thinker_t;
    sector: Psector_t;
    count: int;
    minlight: int;
    maxlight: int;
    darktime: int;
    brighttime: int;
  End;
  Pstrobe_t = ^strobe_t;

Procedure P_InitPicAnims();
Procedure P_SpawnSpecials();
Procedure R_InterpolateTextureOffsets();
Procedure P_PlayerInSpecialSector(player: Pplayer_t);
Procedure P_UpdateSpecials();

Procedure P_ShootSpecialLine(thing: Pmobj_t; line: pline_t);
Procedure P_CrossSpecialLine(linenum, side: int; thing: Pmobj_t);

Function P_FindLowestCeilingSurrounding(sec: Psector_t): fixed_t;
Function P_FindMinSurroundingLight(sector: Psector_t; max: int): int;

Implementation

Uses
  doomstat, doomdata, sounds
  , d_loop, d_mode, d_englsh
  , i_timer, i_system, i_sound
  , g_game
  , m_menu
  , p_tick, p_setup, p_floor, p_switch, p_doors, p_plats, p_lights, p_ceilng, p_mobj, p_inter
  , r_draw, r_plane, r_data, r_swirl
  , s_sound
  , v_snow
  , w_wad
  , z_zone
  ;

Const

  HUSTR_SECRETFOUND = 'A secret is revealed!'; // WTF: Warum ist das nicht in d_englsh

  //
  //      Animating line specials
  //
  MAXLINEANIMS = 64 * 256;

  // Floor/ceiling animation sequences,
  //  defined by first and last frame,
  //  i.e. the flat (64x64 tile) name to
  //  be used.
  // The full animation sequence is given
  //  using all the flats between the start
  //  and end entry, in the order found in
  //  the WAD file.
  //
  // [crispy] add support for ANIMATED lumps
  animdefs_vanilla: Array Of animdef_t =
  (
    (istexture: 0; endname: 'NUKAGE3'; startname: 'NUKAGE1'; speed: 8),
    (istexture: 0; endname: 'FWATER4'; startname: 'FWATER1'; speed: 8),
    (istexture: 0; endname: 'SWATER4'; startname: 'SWATER1'; speed: 8),
    (istexture: 0; endname: 'LAVA4'; startname: 'LAVA1'; speed: 8),
    (istexture: 0; endname: 'BLOOD3'; startname: 'BLOOD1'; speed: 8),

    // DOOM II flat animations.
    (istexture: 0; endname: 'RROCK08'; startname: 'RROCK05'; speed: 8),
    (istexture: 0; endname: 'SLIME04'; startname: 'SLIME01'; speed: 8),
    (istexture: 0; endname: 'SLIME08'; startname: 'SLIME05'; speed: 8),
    (istexture: 0; endname: 'SLIME12'; startname: 'SLIME09'; speed: 8),

    (istexture: 1; endname: 'BLODGR4'; startname: 'BLODGR1'; speed: 8),
    (istexture: 1; endname: 'SLADRIP3'; startname: 'SLADRIP1'; speed: 8),

    (istexture: 1; endname: 'BLODRIP4'; startname: 'BLODRIP1'; speed: 8),
    (istexture: 1; endname: 'FIREWALL'; startname: 'FIREWALA'; speed: 8),
    (istexture: 1; endname: 'GSTFONT3'; startname: 'GSTFONT1'; speed: 8),
    (istexture: 1; endname: 'FIRELAVA'; startname: 'FIRELAV3'; speed: 8),
    (istexture: 1; endname: 'FIREMAG3'; startname: 'FIREMAG1'; speed: 8),
    (istexture: 1; endname: 'FIREBLU2'; startname: 'FIREBLU1'; speed: 8),
    (istexture: 1; endname: 'ROCKRED3'; startname: 'ROCKRED1'; speed: 8),

    (istexture: 1; endname: 'BFALL4'; startname: 'BFALL1'; speed: 8),
    (istexture: 1; endname: 'SFALL4'; startname: 'SFALL1'; speed: 8),
    (istexture: 1; endname: 'WFALL4'; startname: 'WFALL1'; speed: 8),
    (istexture: 1; endname: 'DBRAIN4'; startname: 'DBRAIN1'; speed: 8),

    (istexture: - 1; endname: ''; startname: ''; speed: 0)
    );

Type
  //
  // Animating textures and planes
  // There is another anim_t used in wi_stuff, unrelated.
  //
  anim_t = Record
    istexture: boolean;
    picnum: int;
    basepic: int;
    numpics: int;
    speed: int;
  End;

Var
  numlinespecials: short;
  linespeciallist: Array[0..MAXLINEANIMS - 1] Of Pline_t;

  levelTimer: boolean;
  levelTimeCount: int;

  anims: Array Of anim_t;
  lastanim: integer;
  maxanims: size_t = 0;

Procedure P_InitPicAnims();
Var
  i: int;
  init_swirl: boolean;
  animdefs: panimdef_t;
  from_lump: boolean;
  startname, endname: String;
  newmax: size_t;
Begin
  init_swirl := false;

  // [crispy] add support for ANIMATED lumps

  from_lump := (W_CheckNumForName('ANIMATED') <> -1);

  If (from_lump) Then Begin
    animdefs := W_CacheLumpName('ANIMATED', PU_STATIC);
  End
  Else Begin
    animdefs := @animdefs_vanilla[0];
  End;

  //	Init animation
  lastanim := 0;
  i := 0;
  While animdefs[i].istexture <> -1 Do Begin

    // [crispy] remove MAXANIMS limit
    If (lastanim >= maxanims) Then Begin
      If maxanims <> 0 Then Begin
        newmax := 2 * maxanims;
      End
      Else Begin
        newmax := define_MAXANIMS;
      End;
      setlength(anims, newmax);
      lastanim := maxanims;
      maxanims := newmax;
    End;

    startname := animdefs[i].startname;
    endname := animdefs[i].endname;

    If (animdefs[i].istexture <> 0) Then Begin

      // different episode ?
      If (R_CheckTextureNumForName(startname) = -1) Then Begin
        i := i + 1;
        continue;
      End;

      anims[lastanim].picnum := R_TextureNumForName(endname);
      anims[lastanim].basepic := R_TextureNumForName(startname);
    End
    Else Begin
      If (W_CheckNumForName(startname) = -1) Then Begin
        i := i + 1;
        continue;
      End;

      anims[lastanim].picnum := R_FlatNumForName(endname);
      anims[lastanim].basepic := R_FlatNumForName(startname);
    End;

    anims[lastanim].istexture := animdefs[i].istexture <> 0;
    anims[lastanim].numpics := anims[lastanim].picnum - anims[lastanim].basepic + 1;
    If from_lump Then Begin
      anims[lastanim].speed := int(animdefs[i].speed);
    End
    Else Begin
      anims[lastanim].speed := animdefs[i].speed;
    End;

    // [crispy] add support for SMMU swirling flats
    If (anims[lastanim].speed > 65535) Or (anims[lastanim].numpics = 1) Then Begin
      init_swirl := true;
    End
    Else If (anims[lastanim].numpics < 2) Then Begin
      // [crispy] make non-fatal, skip invalid animation sequences
      writeln(stderr, format('P_InitPicAnims: bad cycle from %s to %s\n',
        [startname, endname]));
      i := i + 1;
      continue;
    End;

    lastanim := lastanim + 1;
    i := i + 1;
  End;

  If (from_lump) Then Begin
    W_ReleaseLumpName('ANIMATED');
  End;

  If (init_swirl) Then Begin
    R_InitDistortedFlats();
  End;
End;

//
// P_SpawnSpecials
// After the map has been loaded, scan for specials
//  that spawn thinkers
//

Function NumScrollers(): unsigned_int;
Var
  i, scrollers: unsigned_int;
Begin
  scrollers := 0;
  For i := 0 To numlines - 1 Do Begin
    If (48 = lines[i].special) Then Begin
      scrollers := scrollers + 1;
    End;
  End;
  result := scrollers;
End;

Procedure P_SpawnSpecials();
Var
  sector: Psector_t;
  i: int;
  secnum: int;
Begin
  // See if -TIMER was specified.
  If (timelimit > 0) And (deathmatch <> 0) Then Begin
    levelTimer := true;
    levelTimeCount := timelimit * 60 * TICRATE;
  End
  Else Begin
    levelTimer := false;
  End;
  // Init special SECTORs.
  For i := 0 To numsectors - 1 Do Begin
    sector := @sectors[i];

    If (sector^.special = 0) Then Continue;

    Case (sector^.special) Of
      1: Begin
          // FLICKERING LIGHTS
          P_SpawnLightFlash(sector);
        End;
      2: Begin
          // STROBE FAST
          P_SpawnStrobeFlash(sector, FASTDARK, 0);
        End;

      3: Begin
          // STROBE SLOW
          P_SpawnStrobeFlash(sector, SLOWDARK, 0);
        End;

      4: Begin
          // STROBE FAST/DEATH SLIME
          P_SpawnStrobeFlash(sector, FASTDARK, 0);
          sector^.special := 4;
        End;

      8: Begin
          // GLOWING LIGHT
          P_SpawnGlowingLight(sector);
        End;
      9: Begin
          // SECRET SECTOR
          totalsecret := totalsecret + 1;
        End;

      10: Begin
          // DOOR CLOSE IN 30 SECONDS
          P_SpawnDoorCloseIn30(sector);
        End;

      12: Begin
          // SYNC STROBE SLOW
          P_SpawnStrobeFlash(sector, SLOWDARK, 1);
        End;

      13: Begin
          // SYNC STROBE FAST
          P_SpawnStrobeFlash(sector, FASTDARK, 1);
        End;

      14: Begin
          // DOOR RAISE IN 5 MINUTES
          P_SpawnDoorRaiseIn5Mins(sector, i);
        End;

      17: Begin
          // first introduced in official v1.4 beta
          If (gameversion > exe_doom_1_2) Then Begin
            P_SpawnFireFlicker(sector);
          End;
        End;
    End;
  End;

  //	Init line EFFECTs
  numlinespecials := 0;

  For i := 0 To numlines - 1 Do Begin

    Case (lines[i].special) Of
      48, 85: Begin // [crispy] [JN] (Boom) Scroll Texture Right
          If (numlinespecials >= MAXLINEANIMS) Then Begin

            I_Error(format('Too many scrolling wall linedefs (%d)! ' +
              '(Vanilla limit is 64)', [NumScrollers()]));
          End;
          // EFFECT FIRSTCOL SCROLL+
          linespeciallist[numlinespecials] := @lines[i];
          numlinespecials := numlinespecials + 1;
        End;

      // [crispy] add support for MBF sky tranfers
      271, 272: Begin
          For secnum := 0 To numsectors - 1 Do Begin
            If (sectors[secnum].tag = lines[i].tag) Then Begin
              sectors[secnum].sky := int(i Or PL_SKYFLAT);
            End;
          End;
        End;
    End;
  End;

  //	Init other misc stuff
  For i := 0 To MAXCEILINGS - 1 Do
    activeceilings[i] := Nil;

  For i := 0 To MAXPLATS - 1 Do
    activeplats[i] := Nil;

  For i := 0 To maxbuttons - 1 Do
    FillChar(buttonlist[i], sizeof(button_t), 0);

  // UNUSED: no horizonal sliders.
  //	P_InitSlidingDoorFrames();
End;

Procedure R_InterpolateTextureOffsets();
Begin
  If (crispy.uncapped <> 0) And (leveltime > oldleveltime) Then Begin
    Raise exception.create('Port me.');
    //		int i;
    //
    //		for (i = 0; i < numlinespecials; i++)
    //		{
    //			const line_t *const line = linespeciallist[i];
    //			side_t *const side = &sides[line->sidenum[0]];
    //
    //			if (line->special == 48)
    //			{
    //				side->textureoffset = side->basetextureoffset + fractionaltic;
    //			}
    //			else
    //			if (line->special == 85)
    //			{
    //				side->textureoffset = side->basetextureoffset - fractionaltic;
    //			}
    //		}
  End;
End;

//
// P_PlayerInSpecialSector
// Called every tic frame
//  that the player origin is in a special sector
//

Procedure P_PlayerInSpecialSector(player: Pplayer_t);
Const
  error: Psector_t = Nil;
Var
  sector: Psector_t;
  //    extern int showMessages;
  sfx_id: sfxenum_t;
  str_count: String;
Begin
  sector := player^.mo^.subsector^.sector;

  // Falling, not all the way down yet?
  If (player^.mo^.z <> sector^.floorheight) Then exit;

  // Has hitten ground.
  Case (sector^.special) Of
    5: Begin
        // HELLSLIME DAMAGE
        // [crispy] no nukage damage with NOCLIP cheat
        If (player^.powers[int(pw_ironfeet)] = 0) And ((player^.mo^.flags And MF_NOCLIP) = 0) Then
          If ((leveltime And $1F) = 0) Then
            P_DamageMobj(player^.mo, Nil, Nil, 10);
      End;
    7: Begin
        // NUKAGE DAMAGE
        // [crispy] no nukage damage with NOCLIP cheat
        If (player^.powers[int(pw_ironfeet)] = 0) And ((player^.mo^.flags And MF_NOCLIP) = 0) Then
          If ((leveltime And $1F) = 0) Then
            P_DamageMobj(player^.mo, Nil, Nil, 5);
      End;

    16,
      // SUPER HELLSLIME DAMAGE
    4: Begin
        Raise exception.create('Port me.');

        //	// STROBE HURT
        //	// [crispy] no nukage damage with NOCLIP cheat
        //	if ((!player^.powers[pw_ironfeet]
        //	    || (P_Random()<5) ) && !(player^.mo^.flags & MF_NOCLIP))
        //	{
        //	    if (!(leveltime&0x1f))
        //		P_DamageMobj (player^.mo, Nil, Nil, 20);
        //	}
      End;
    9: Begin
        // SECRET SECTOR
        player^.secretcount := player^.secretcount + 1;
        // [crispy] show centered "Secret Revealed!" message
        If (showMessages <> 0) And (crispy.secretmessage <> 0) And (player = @players[consoleplayer]) Then Begin

          // [crispy] play DSSECRET if available
          If I_GetSfxLumpNum(@S_sfx[int(sfx_secret)]) <> -1 Then Begin
            sfx_id := sfx_secret;
          End
          Else Begin
            If I_GetSfxLumpNum(@S_sfx[int(sfx_itmbk)]) <> -1 Then Begin
              sfx_id := sfx_itmbk;
            End
            Else Begin
              sfx_id := sfx_None;
            End;
          End;
          If (crispy.secretmessage = SECRETMESSAGE_COUNT) Then Begin
            str_count := format('Secret %d of %d revealed!', [player^.secretcount, totalsecret]);
            player^.centermessage := str_count;
          End
          Else Begin
            player^.centermessage := HUSTR_SECRETFOUND;
          End;
          If (sfx_id <> sfx_None) Then
            S_StartSound(Nil, sfx_id);
        End;
        // [crispy] remember revealed secrets
        sector^.oldspecial := sector^.special;
        sector^.special := 0;
      End;
    11: Begin
        Raise exception.create('Port me.');
        //	// EXIT SUPER DAMAGE! (for E1M8 finale)
        //	player^.cheats &= ~CF_GODMODE;
        //
        //	if (!(leveltime&0x1f))
        //	    P_DamageMobj (player^.mo, Nil, Nil, 20);
        //
        //	if (player^.health <= 10)
        //	    G_ExitLevel();
      End;
  Else Begin
      // [crispy] ignore unknown special sectors
      If (error <> sector) Then Begin
        error := sector;
        writeln(stderr, format('P_PlayerInSpecialSector: ' +
          'unknown special %d',
          [sector^.special]));
      End;
    End;
  End;
End;

Procedure P_UpdateSpecials();
Var
  anim: ^anim_t;
  anim_i: integer;
  pic: int;
  i: int;
  line: Pline_t;
Begin
  // LEVEL TIMER
  If (levelTimer) Then Begin
    levelTimeCount := levelTimeCount - 1;
    If (levelTimeCount = 0) Then
      G_ExitLevel();
  End;

  // ANIMATE FLATS AND TEXTURES GLOBALLY
  For anim_i := 0 To lastanim - 1 Do Begin
    anim := @anims[anim_i];
    For i := anim^.basepic To anim^.basepic + anim^.numpics - 1 Do Begin
      pic := anim^.basepic + ((leveltime Div anim^.speed + i) Mod anim^.numpics);
      If (anim^.istexture) Then
        texturetranslation[i] := pic
      Else Begin
        // [crispy] add support for SMMU swirling flats
        If (anim^.speed > 65535) Or (anim^.numpics = 1) Then Begin
          flattranslation[i] := -1;
        End
        Else
          flattranslation[i] := pic;
      End;
    End;
  End;

  // ANIMATE LINE SPECIALS
  For i := 0 To numlinespecials - 1 Do Begin
    line := @linespeciallist[i];
    Case (line^.special) Of
      48: Begin
          // EFFECT FIRSTCOL SCROLL +
          // [crispy] smooth texture scrolling
          sides[line^.sidenum[0]].basetextureoffset := sides[line^.sidenum[0]].basetextureoffset + FRACUNIT;
          sides[line^.sidenum[0]].textureoffset := sides[line^.sidenum[0]].basetextureoffset;
        End;
      85: Begin
          // [JN] (Boom) Scroll Texture Right
          // [crispy] smooth texture scrolling
          sides[line^.sidenum[0]].basetextureoffset := sides[line^.sidenum[0]].basetextureoffset - FRACUNIT;
          sides[line^.sidenum[0]].textureoffset := sides[line^.sidenum[0]].basetextureoffset;
        End;
    End;
  End;

  //	DO BUTTONS
  For i := 0 To maxbuttons - 1 Do Begin
    If (buttonlist[i].btimer <> 0) Then Begin
      buttonlist[i].btimer := buttonlist[i].btimer - 1;
      If (buttonlist[i].btimer = 0) Then Begin

        Case (buttonlist[i].where) Of
          top: Begin
              sides[buttonlist[i].line^.sidenum[0]].toptexture := buttonlist[i].btexture;
            End;
          middle: Begin
              sides[buttonlist[i].line^.sidenum[0]].midtexture := buttonlist[i].btexture;
            End;
          bottom: Begin
              sides[buttonlist[i].line^.sidenum[0]].bottomtexture := buttonlist[i].btexture;
            End;
        End;
        // [crispy] & [JN] Logically proper sound behavior.
        // Do not play second "sfx_swtchn" on two-sided linedefs that attached to special sectors,
        // and always play second sound on single-sided linedefs.
        If (crispy.soundfix <> 0) Then Begin
          If (buttonlist[i].line^.backsector = Nil) Or (buttonlist[i].line^.backsector^.specialdata = Nil) Then Begin
            S_StartSoundOnce(buttonlist[i].soundorg, sfx_swtchn);
          End;
        End
        Else Begin
          S_StartSoundOnce(&buttonlist[i].soundorg, sfx_swtchn);
        End;
        FillChar(buttonlist[i], sizeof(button_t), 0);
      End;
    End;
  End;

  // [crispy] Snow
  If (crispy.snowflakes <> 0) Then Begin
    V_SnowUpdate();
  End;

  // [crispy] draw fuzz effect independent of rendering frame rate
  R_SetFuzzPosTic();
End;

//
// P_ShootSpecialLine - IMPACT SPECIALS
// Called when a thing shoots a special line.
//

Procedure P_ShootSpecialLine(thing: Pmobj_t; line: pline_t);
Var
  ok: int;
Begin
  // Impacts that other things can activate.
  If (thing^.player = Nil) Then Begin
    ok := 0;
    Case (line^.special) Of
      46: Begin
          // OPEN DOOR IMPACT
          ok := 1;
        End;
    End;
    If (ok = 0) Then
      exit;
  End;

  Case (line^.special) Of
    24: Begin
        // RAISE FLOOR
        EV_DoFloor(line, raiseFloor);
        P_ChangeSwitchTexture(line, 0);
      End;
    46: Begin
        // OPEN DOOR
        EV_DoDoor(line, vld_open);
        P_ChangeSwitchTexture(line, 1);
      End;
    47: Begin
        // RAISE FLOOR NEAR AND CHANGE
        EV_DoPlat(line, raiseToNearestAndChange, 0);
        P_ChangeSwitchTexture(line, 0);
      End;
  End;
End;

// [crispy] more MBF code pointers

Procedure P_CrossSpecialLinePtr(line: pline_t; side: int; thing: Pmobj_t);
Var
  ok: int;
Begin

  //  line = &lines[linenum];

  If (gameversion <= exe_doom_1_2) Then Begin
    If (line^.special > 98) And (line^.special <> 104) Then Begin
      exit;
    End;
  End
  Else Begin
    //	Triggers that other things can activate
    If (thing^.player = Nil) Then Begin

      // Things that should NOT trigger specials...
      Case (thing^._type) Of
        MT_ROCKET,
          MT_PLASMA,
          MT_BFG,
          MT_TROOPSHOT,
          MT_HEADSHOT,
          MT_BRUISERSHOT: Begin
            exit;
          End;
      End;
    End;
  End;

  If (thing^.player = Nil) Then Begin
    ok := 0;
    Case (line^.special) Of
      39, // TELEPORT TRIGGER
      97, // TELEPORT RETRIGGER
      125, // TELEPORT MONSTERONLY TRIGGER
      126, // TELEPORT MONSTERONLY RETRIGGER
      4, // RAISE DOOR
      10, // PLAT DOWN-WAIT-UP-STAY TRIGGER
      88: Begin // PLAT DOWN-WAIT-UP-STAY RETRIGGER
          ok := 1;
        End;
    End;
    If (ok = 0) Then exit;
  End;

  // Note: could use some const's here.
  Case (line^.special) Of
    // TRIGGERS.
    // All from here to RETRIGGERS.
    2: Begin
        // Open Door
        EV_DoDoor(line, vld_open);
        line^.special := 0;
      End;

    3: Begin
        // Close Door
        EV_DoDoor(line, vld_close);
        line^.special := 0;
      End;

    4: Begin
        // Raise Door
        EV_DoDoor(line, vld_normal);
        line^.special := 0;
      End;

    //      case 5:
    //	// Raise Floor
    //	EV_DoFloor(line,raiseFloor);
    //	line^.special = 0;
    //	break;

    //      case 6:
    //	// Fast Ceiling Crush & Raise
    //	EV_DoCeiling(line,fastCrushAndRaise);
    //	line^.special = 0;
    //	break;

    //      case 8:
    //	// Build Stairs
    //	EV_BuildStairs(line,build8);
    //	line^.special = 0;
    //	break;

    //      case 10:
    //	// PlatDownWaitUp
    //	EV_DoPlat(line,downWaitUpStay,0);
    //	line^.special = 0;
    //	break;

    //      case 12:
    //	// Light Turn On - brightest near
    //	EV_LightTurnOn(line,0);
    //	line^.special = 0;
    //	break;

    //      case 13:
    //	// Light Turn On 255
    //	EV_LightTurnOn(line,255);
    //	line^.special = 0;
    //	break;

    //      case 16:
    //	// Close Door 30
    //	EV_DoDoor(line,vld_close30ThenOpen);
    //	line^.special = 0;
    //	break;

    //      case 17:
    //	// Start Light Strobing
    //	EV_StartLightStrobing(line);
    //	line^.special = 0;
    //	break;

    //      case 19:
    //	// Lower Floor
    //	EV_DoFloor(line,lowerFloor);
    //	line^.special = 0;
    //	break;

    //      case 22:
    //	// Raise floor to nearest height and change texture
    //	EV_DoPlat(line,raiseToNearestAndChange,0);
    //	line^.special = 0;
    //	break;

    //      case 25:
    //	// Ceiling Crush and Raise
    //	EV_DoCeiling(line,crushAndRaise);
    //	line^.special = 0;
    //	break;

    //      case 30:
    //	// Raise floor to shortest texture height
    //	//  on either side of lines.
    //	EV_DoFloor(line,raiseToTexture);
    //	line^.special = 0;
    //	break;

    //      case 35:
    //	// Lights Very Dark
    //	EV_LightTurnOn(line,35);
    //	line^.special = 0;
    //	break;

    //      case 36:
    //	// Lower Floor (TURBO)
    //	EV_DoFloor(line,turboLower);
    //	line^.special = 0;
    //	break;

    //      case 37:
    //	// LowerAndChange
    //	EV_DoFloor(line,lowerAndChange);
    //	line^.special = 0;
    //	break;

    //      case 38:
    //	// Lower Floor To Lowest
    //	EV_DoFloor( line, lowerFloorToLowest );
    //	line^.special = 0;
    //	break;

    //      case 39:
    //	// TELEPORT!
    //	EV_Teleport( line, side, thing );
    //	line^.special = 0;
    //	break;

    //      case 40:
    //	// RaiseCeilingLowerFloor
    //	EV_DoCeiling( line, raiseToHighest );
    //	EV_DoFloor( line, lowerFloorToLowest );
    //	line^.special = 0;
    //	break;

    //      case 44:
    //	// Ceiling Crush
    //	EV_DoCeiling( line, lowerAndCrush );
    //	line^.special = 0;
    //	break;

    52: Begin
        // EXIT!
        G_ExitLevel();
      End;

    //      case 53:
    //	// Perpetual Platform Raise
    //	EV_DoPlat(line,perpetualRaise,0);
    //	line^.special = 0;
    //	break;
    //
    //      case 54:
    //	// Platform Stop
    //	EV_StopPlat(line);
    //	line^.special = 0;
    //	break;
    //
    //      case 56:
    //	// Raise Floor Crush
    //	EV_DoFloor(line,raiseFloorCrush);
    //	line^.special = 0;
    //	break;
    //
    //      case 57:
    //	// Ceiling Crush Stop
    //	EV_CeilingCrushStop(line);
    //	line^.special = 0;
    //	break;
    //
    //      case 58:
    //	// Raise Floor 24
    //	EV_DoFloor(line,raiseFloor24);
    //	line^.special = 0;
    //	break;
    //
    //      case 59:
    //	// Raise Floor 24 And Change
    //	EV_DoFloor(line,raiseFloor24AndChange);
    //	line^.special = 0;
    //	break;
    //
    //      case 104:
    //	// Turn lights off in sector(tag)
    //	EV_TurnTagLightsOff(line);
    //	line^.special = 0;
    //	break;
    //
    //      case 108:
    //	// Blazing Door Raise (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeRaise);
    //	line^.special = 0;
    //	break;
    //
    //      case 109:
    //	// Blazing Door Open (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeOpen);
    //	line^.special = 0;
    //	break;
    //
    //      case 100:
    //	// Build Stairs Turbo 16
    //	EV_BuildStairs(line,turbo16);
    //	line^.special = 0;
    //	break;
    //
    //      case 110:
    //	// Blazing Door Close (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeClose);
    //	line^.special = 0;
    //	break;
    //
    //      case 119:
    //	// Raise floor to nearest surr. floor
    //	EV_DoFloor(line,raiseFloorToNearest);
    //	line^.special = 0;
    //	break;
    //
    //      case 121:
    //	// Blazing PlatDownWaitUpStay
    //	EV_DoPlat(line,blazeDWUS,0);
    //	line^.special = 0;
    //	break;

    124: Begin
        // Secret EXIT
        G_SecretExitLevel();
      End;

    //      case 125:
    //	// TELEPORT MonsterONLY
    //	if (!thing^.player)
    //	{
    //	    EV_Teleport( line, side, thing );
    //	    line^.special = 0;
    //	}
    //	break;
    //
    //      case 130:
    //	// Raise Floor Turbo
    //	EV_DoFloor(line,raiseFloorTurbo);
    //	line^.special = 0;
    //	break;
    //
    //      case 141:
    //	// Silent Ceiling Crush & Raise
    //	EV_DoCeiling(line,silentCrushAndRaise);
    //	line^.special = 0;
    //	break;
    //
    //	// RETRIGGERS.  All from here till end.
    //      case 72:
    //	// Ceiling Crush
    //	EV_DoCeiling( line, lowerAndCrush );
    //	break;
    //
    //      case 73:
    //	// Ceiling Crush and Raise
    //	EV_DoCeiling(line,crushAndRaise);
    //	break;
    //
    //      case 74:
    //	// Ceiling Crush Stop
    //	EV_CeilingCrushStop(line);
    //	break;
    //
    //      case 75:
    //	// Close Door
    //	EV_DoDoor(line,vld_close);
    //	break;
    //
    //      case 76:
    //	// Close Door 30
    //	EV_DoDoor(line,vld_close30ThenOpen);
    //	break;
    //
    //      case 77:
    //	// Fast Ceiling Crush & Raise
    //	EV_DoCeiling(line,fastCrushAndRaise);
    //	break;
    //
    //      case 79:
    //	// Lights Very Dark
    //	EV_LightTurnOn(line,35);
    //	break;
    //
    //      case 80:
    //	// Light Turn On - brightest near
    //	EV_LightTurnOn(line,0);
    //	break;
    //
    //      case 81:
    //	// Light Turn On 255
    //	EV_LightTurnOn(line,255);
    //	break;
    //
    //      case 82:
    //	// Lower Floor To Lowest
    //	EV_DoFloor( line, lowerFloorToLowest );
    //	break;
    //
    //      case 83:
    //	// Lower Floor
    //	EV_DoFloor(line,lowerFloor);
    //	break;
    //
    //      case 84:
    //	// LowerAndChange
    //	EV_DoFloor(line,lowerAndChange);
    //	break;
    //
    //      case 86:
    //	// Open Door
    //	EV_DoDoor(line,vld_open);
    //	break;
    //
    //      case 87:
    //	// Perpetual Platform Raise
    //	EV_DoPlat(line,perpetualRaise,0);
    //	break;
    //
    //      case 88:
    //	// PlatDownWaitUp
    //	EV_DoPlat(line,downWaitUpStay,0);
    //	break;
    //
    //      case 89:
    //	// Platform Stop
    //	EV_StopPlat(line);
    //	break;
    //
    //      case 90:
    //	// Raise Door
    //	EV_DoDoor(line,vld_normal);
    //	break;
    //
    //      case 91:
    //	// Raise Floor
    //	EV_DoFloor(line,raiseFloor);
    //	break;
    //
    //      case 92:
    //	// Raise Floor 24
    //	EV_DoFloor(line,raiseFloor24);
    //	break;
    //
    //      case 93:
    //	// Raise Floor 24 And Change
    //	EV_DoFloor(line,raiseFloor24AndChange);
    //	break;
    //
    //      case 94:
    //	// Raise Floor Crush
    //	EV_DoFloor(line,raiseFloorCrush);
    //	break;
    //
    //      case 95:
    //	// Raise floor to nearest height
    //	// and change texture.
    //	EV_DoPlat(line,raiseToNearestAndChange,0);
    //	break;
    //
    //      case 96:
    //	// Raise floor to shortest texture height
    //	// on either side of lines.
    //	EV_DoFloor(line,raiseToTexture);
    //	break;
    //
    //      case 97:
    //	// TELEPORT!
    //	EV_Teleport( line, side, thing );
    //	break;
    //
    //      case 98:
    //	// Lower Floor (TURBO)
    //	EV_DoFloor(line,turboLower);
    //	break;
    //
    //      case 105:
    //	// Blazing Door Raise (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeRaise);
    //	break;
    //
    //      case 106:
    //	// Blazing Door Open (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeOpen);
    //	break;
    //
    //      case 107:
    //	// Blazing Door Close (faster than TURBO!)
    //	EV_DoDoor (line,vld_blazeClose);
    //	break;
    //
    //      case 120:
    //	// Blazing PlatDownWaitUpStay.
    //	EV_DoPlat(line,blazeDWUS,0);
    //	break;
    //
    //      case 126:
    //	// TELEPORT MonsterONLY.
    //	if (!thing^.player)
    //	    EV_Teleport( line, side, thing );
    //	break;
    //
    //      case 128:
    //	// Raise To Nearest Floor
    //	EV_DoFloor(line,raiseFloorToNearest);
    //	break;
    //
    //      case 129:
    //	// Raise Floor Turbo
    //	EV_DoFloor(line,raiseFloorTurbo);
    //	break;
  Else Begin // TODO: remove, when finishing porting
      // Nicht jeder Index ist oben definiert, alle Nummern die mal kamen aber nicht relevant sind einfach hier eintragen ;)
      If Not line^.special In [48] Then Begin
        Raise exception.create('P_CrossSpecialLinePtr: missing port for: ' + inttostr(line^.special));
      End;
    End; // TODO: remove, when finishing porting -- Ende
  End;
End;

//
// P_CrossSpecialLine - TRIGGER
// Called every time a thing origin is about
//  to cross a line with a non 0 special.
//

Procedure P_CrossSpecialLine(linenum, side: int; thing: Pmobj_t);
Begin
  P_CrossSpecialLinePtr(@lines[linenum], side, thing);
End;

//
// getNextSector()
// Return sector_t * of sector next to current.
// NULL if not two-sided line
//

Function getNextSector(line: Pline_t; sec: Psector_t): Psector_t;
Begin
  If ((line^.flags And ML_TWOSIDED) = 0) Then Begin
    result := Nil;
    exit;
  End;
  If (line^.frontsector = sec) Then Begin
    result := line^.backsector;
  End
  Else Begin
    result := line^.frontsector;
  End;
End;

//
// FIND LOWEST CEILING IN THE SURROUNDING SECTORS
//

Function P_FindLowestCeilingSurrounding(sec: Psector_t): fixed_t;
Var
  i: int;
  check: pline_t;
  other: psector_t;
  height: fixed_t;

Begin
  height := INT_MAX;

  For i := 0 To sec^.linecount - 1 Do Begin
    check := @sec^.lines[i];
    other := getNextSector(check, sec);

    If (other = Nil) Then continue;
    If (other^.ceilingheight < height) Then
      height := other^.ceilingheight;
  End;
  result := height;
End;

//
// Find minimum light from an adjacent sector
//

Function P_FindMinSurroundingLight(sector: Psector_t; max: int): int;
Var
  i: int;
  min: int;
  line: Pline_t;
  check: Psector_t;
Begin
  min := max;
  For i := 0 To sector^.linecount - 1 Do Begin
    line := @sector^.lines[i];
    check := getNextSector(line, sector);

    If (check = Nil) Then
      continue;

    If (check^.lightlevel < min) Then
      min := check^.lightlevel;
  End;
  result := min;
End;

End.

