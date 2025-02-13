Unit st_stuff;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef, doomtype
  , d_event
  , i_video, i_timer
  , m_cheat
  ;

Const
  // Das wirkt sich auf viewheight aus, und das dann wohl auf die Sprites ..
  ST_HEIGHT = 32;
  ST_WIDTH = ORIGWIDTH;
  ST_Y = (ORIGHEIGHT - ST_HEIGHT);

  CRISPY_HUD = 12;

  //cheatseq_t cheat_mus = CHEAT("idmus", 2);
  cheat_god: cheatseq_t = (sequence: 'iddqd'; parameter_chars: 0);
  cheat_ammo: cheatseq_t = (sequence: 'idkfa'; parameter_chars: 0);
  cheat_ammonokey: cheatseq_t = (sequence: 'idfa'; parameter_chars: 0);
  cheat_noclip: cheatseq_t = (sequence: 'idspispopd'; parameter_chars: 0);
  cheat_commercial_noclip: cheatseq_t = (sequence: 'idclip'; parameter_chars: 0);
  cheat_weapon: cheatseq_t = (sequence: 'tntweap'; parameter_chars: 1);

  cheat_clev: cheatseq_t = (sequence: 'idclev'; parameter_chars: 2);

  // [crispy] pseudo cheats to eat up the first digit typed after a cheat expecting two parameters
  cheat_clev1: cheatseq_t = (sequence: 'idclev'; parameter_chars: 1);

Var
  st_keyorskull: Array[card_t] Of int; // Es werden aber nur it_bluecard .. it_redcard genutzt

  // graphics are drawn to a backing screen and blitted to the real screen
  st_backing_screen: Array Of pixel_t = Nil;

Procedure ST_Init();
Procedure ST_Start();
Procedure ST_Ticker();

Procedure ST_Drawer(fullscreen, refresh: boolean);

Function cht_CheckCheatSP(Var cht: cheatseq_t; key: char): int;

Function ST_Responder(Const ev: Pevent_t): boolean;

Procedure ST_refreshBackground(force: boolean);
Procedure ST_DrawDemoTimer(time: int);

Implementation

Uses
  math, info_types, doomstat, doomdata, tables, sounds, info
  , am_map
  , d_items, d_player, d_englsh, deh_misc, d_mode, d_loop
  , g_game
  , m_menu, m_fixed, m_random, m_controls
  , p_mobj, p_local, p_inter, p_setup
  , r_main
  , st_lib, s_sound
  , v_patch, v_video, v_trans
  , w_wad
  , z_zone
  ;

Const
  // Location and size of statistics,
  //  justified according to widget type.
  // Problem is, within which space? STbar? Screen?
  // Note: this could be read in by a lump.
  //       Problem is, is the stuff rendered
  //       into a buffer,
  //       or into the frame buffer?

  // AMMO number pos.
  ST_AMMOWIDTH = 3;
  ST_AMMOX = (44 {- ST_WIDESCREENDELTA});
  ST_AMMOY = 171;

  // HEALTH number pos.
  ST_HEALTHWIDTH = 3;
  ST_HEALTHX = (90 {- ST_WIDESCREENDELTA});
  ST_HEALTHY = 171;

  // Weapon pos.
  ST_ARMSX = (111 {- ST_WIDESCREENDELTA});
  ST_ARMSY = 172;
  ST_ARMSBGX = (104 {- ST_WIDESCREENDELTA});
  ST_ARMSBGY = 168;
  ST_ARMSXSPACE = 12;
  ST_ARMSYSPACE = 10;

  // Frags pos.
  ST_FRAGSX = (138 {- ST_WIDESCREENDELTA});
  ST_FRAGSY = 171;
  ST_FRAGSWIDTH = 2;

  // ARMOR number pos.
  ST_ARMORWIDTH = 3;
  ST_ARMORX = (221 {+ ST_WIDESCREENDELTA});
  ST_ARMORY = 171;

  // Number of status faces.
  ST_NUMPAINFACES = 5;
  ST_NUMSTRAIGHTFACES = 3;
  ST_NUMTURNFACES = 2;
  ST_NUMSPECIALFACES = 3;

  ST_FACESTRIDE = (ST_NUMSTRAIGHTFACES + ST_NUMTURNFACES + ST_NUMSPECIALFACES);

  ST_TURNOFFSET = (ST_NUMSTRAIGHTFACES);
  ST_OUCHOFFSET = (ST_TURNOFFSET + ST_NUMTURNFACES);
  ST_EVILGRINOFFSET = (ST_OUCHOFFSET + 1);
  ST_RAMPAGEOFFSET = (ST_EVILGRINOFFSET + 1);
  ST_GODFACE = (ST_NUMPAINFACES * ST_FACESTRIDE);
  ST_DEADFACE = (ST_GODFACE + 1);

  ST_NUMEXTRAFACES = 2;

  ST_NUMFACES = (ST_FACESTRIDE * ST_NUMPAINFACES + ST_NUMEXTRAFACES);

  ST_FACESX = 143 + 10; // WTF: Hack für w_faces (Achtung 3 mal)
  ST_FACESY = 168;

  // Location of status bar
  ST_X = 0;
  ST_X2 = 104;

  ST_FX = 143;
  ST_FY = 169;

  ST_MUCHPAIN = 20;

  // Ammunition counter.
  ST_AMMO0WIDTH = 3;
  ST_AMMO0HEIGHT = 6;
  ST_AMMO0X = (288 {+ ST_WIDESCREENDELTA});
  ST_AMMO0Y = 173;
  ST_AMMO1WIDTH = ST_AMMO0WIDTH;
  ST_AMMO1X = (288 {+ ST_WIDESCREENDELTA});
  ST_AMMO1Y = 179;
  ST_AMMO2WIDTH = ST_AMMO0WIDTH;
  ST_AMMO2X = (288 {+ ST_WIDESCREENDELTA});
  ST_AMMO2Y = 191;
  ST_AMMO3WIDTH = ST_AMMO0WIDTH;
  ST_AMMO3X = (288 {+ ST_WIDESCREENDELTA});
  ST_AMMO3Y = 185;

  // Indicate maximum ammunition.
// Only needed because backpack exists.
  ST_MAXAMMO0WIDTH = 3;
  ST_MAXAMMO0HEIGHT = 5;
  ST_MAXAMMO0X = (314 {+ ST_WIDESCREENDELTA});
  ST_MAXAMMO0Y = 173;
  ST_MAXAMMO1WIDTH = ST_MAXAMMO0WIDTH;
  ST_MAXAMMO1X = (314 {+ ST_WIDESCREENDELTA});
  ST_MAXAMMO1Y = 179;
  ST_MAXAMMO2WIDTH = ST_MAXAMMO0WIDTH;
  ST_MAXAMMO2X = (314 {+ ST_WIDESCREENDELTA});
  ST_MAXAMMO2Y = 191;
  ST_MAXAMMO3WIDTH = ST_MAXAMMO0WIDTH;
  ST_MAXAMMO3X = (314 {+ ST_WIDESCREENDELTA});
  ST_MAXAMMO3Y = 185;
  ST_EVILGRINCOUNT = (2 * TICRATE);
  ST_TURNCOUNT = (1 * TICRATE);
  ST_RAMPAGEDELAY = (2 * TICRATE);
  ST_STRAIGHTFACECOUNT = (TICRATE Div 2);

  // Key icon positions.
  ST_KEY0WIDTH = 8;
  ST_KEY0HEIGHT = 5;
  ST_KEY0X = (239 {+ ST_WIDESCREENDELTA});
  ST_KEY0Y = 171;
  ST_KEY1WIDTH = ST_KEY0WIDTH;
  ST_KEY1X = (239 {+ ST_WIDESCREENDELTA});
  ST_KEY1Y = 181;
  ST_KEY2WIDTH = ST_KEY0WIDTH;
  ST_KEY2X = (239 {+ ST_WIDESCREENDELTA});
  ST_KEY2Y = 191;

Type
  load_callback_t = Procedure(lumpname: String; variable: PPPatch_t);

  hudcolor_t =
    (
    hudcolor_ammo,
    hudcolor_health,
    hudcolor_frags,
    hudcolor_armor
    );

Var

  // main player in game
  plyr: ^player_t;

  // ST_Start() has just been called
  st_firsttime: Boolean;

  // lump number for PLAYPAL
  lu_palette: int;

  //  // used for making messages go away
  st_msgcounter: int = 0;

  // whether left-side main status bar is active
  st_statusbaron: boolean;

  // [crispy] distinguish classic status bar with background and player face from Crispy HUD
  st_crispyhud: boolean;
  st_classicstatusbar: boolean;
  st_statusbarface: boolean;

  // whether status bar chat is active
  st_chat: boolean;

  // value of st_chat before message popped up
  st_oldchat: boolean;

  // !deathmatch
  st_notdeathmatch: Boolean;

  // !deathmatch && st_statusbaron
  st_armson: boolean;

  // !deathmatch
  st_fragson: boolean;

  // main bar left
  sbar: ppatch_t;

  // main bar right, for doom 1.0
  sbarr: ppatch_t;

  // 0-9, tall numbers
  tallnum: Array[0..9] Of ppatch_t;

  // tall % sign
  tallpercent: ppatch_t;

  // 0-9, short, yellow (,different!) numbers
  shortnum: Array[0..9] Of ppatch_t;

  // 3 key-cards, 3 skulls
  keys: Array[0..integer(NUMCARDS) + 3 - 1] Of ppatch_t; // [crispy] support combined card and skull keys

  // face status patches
  faces: Array[0..integer(ST_NUMFACES) - 1] Of ppatch_t;

  // face background
  faceback: Array[0..MAXPLAYERS - 1] Of ppatch_t; // [crispy] killough 3/7/98: make array

  // main bar right
  armsbg: ppatch_t;

  // weapon ownership patches
  arms: Array[0..5, 0..1] Of ppatch_t;

  // ready-weapon widget
  w_ready: st_number_t;

  // in deathmatch only, summary of frags stats
  w_frags: st_number_t;

  // health widget
  w_health: st_percent_t;

  // arms background
  w_armsbg: st_binicon_t;

  // weapon ownership widgets
  w_arms: Array[0..5] Of st_multicon_t;
  // [crispy] show SSG availability in the Shotgun slot of the arms widget
  st_shotguns: int;

  // face status widget
  w_faces: st_multicon_t;

  // keycard widgets
  w_keyboxes: Array[0..2] Of st_multicon_t;

  // armor widget
  w_armor: st_percent_t;

  // ammo widgets
  w_ammo: Array[0..3] Of st_number_t;

  // max ammo widgets
  w_maxammo: Array[0..3] Of st_number_t;

  // number of frags so far in deathmatch
  st_fragscount: int;

  // used to use appopriately pained face
  st_oldhealth: int = -1;

  // used for evil grin
  oldweaponsowned: Array[0..integer(NUMWEAPONS) - 1] Of boolean;

  // count until face changes
  st_facecount: int = 0;

  // current face index, used by w_faces
  faceindex: int;

  // holds key-type for each key box on bar
  keyboxes: Array[0..2] Of int;

  //  // [crispy] blinking key or skull in the status bar
  //  int		st_keyorskull[3];

  // a random number per tick
  st_randomnumber: int;

  st_widescreendelta: int;
  st_stopped: boolean = true;

  // current face index, used by w_faces
  st_faceindex: int = 0;
  st_palette: int = 0;

Procedure ST_Stop();
Begin
  If (st_stopped) Then exit;

  //#ifndef CRISPY_TRUECOLOR
  //    I_SetPalette (W_CacheLumpNum (lu_palette, PU_CACHE));
  //#else
  //    I_SetPalette (0);
  //#endif

  st_stopped := true;
End;

Procedure ST_initData();
Var
  i: int;
Begin

  st_firsttime := true;
  plyr := @players[displayplayer];

  st_statusbaron := true;
  st_oldchat := false;
  st_chat := false;

  faceindex := 0; // [crispy] fix status bar face hysteresis across level changes
  st_faceindex := 0;
  st_palette := -1;

  st_oldhealth := -1;

  For i := 0 To integer(NUMWEAPONS) - 1 Do Begin
    oldweaponsowned[i] := odd(plyr^.weaponowned[weapontype_t(i)]);
  End;

  For i := 0 To 2 Do Begin
    keyboxes[i] := -1;
  End;

  STlib_init();
End;

// [crispy] in non-widescreen mode WIDESCREENDELTA is 0 anyway

Function ST_WIDESCREENDELTA_(): int;
Begin
  //  If (false {screenblocks >= CRISPY_HUD + 3 && (!automapactive || crispy->automapoverlay) }) Then Begin
  //    result := WIDESCREENDELTA;
  //  End
  //  Else Begin
  result := 0;
  //  End;
End;

Procedure ST_createWidgets();
Var
  i: int;
  before: weapontype_t;

Begin
  // [crispy] re-calculate WIDESCREENDELTA
  I_GetScreenDimensions();
  st_widescreendelta := ST_WIDESCREENDELTA_;

  // If you regulary finish a
  before := plyr^.readyweapon;
  If (plyr^.readyweapon = wp_fist) Or (plyr^.readyweapon = wp_chainsaw) Then plyr^.readyweapon := wp_pistol; // Corpsman, FIX Crash when player has fist or chainsaw during init..
  // ready weapon ammo
  STlib_initNum(w_ready,
    ST_AMMOX,
    ST_AMMOY,
    tallnum,
    @plyr^.ammo[integer(weaponinfo[integer(plyr^.readyweapon)].ammo)],
    @st_statusbaron,
    ST_AMMOWIDTH);
  plyr^.readyweapon := before;

  // the last weapon type
  w_ready.data := int(plyr^.readyweapon);

  // health percentage
  STlib_initPercent(w_health,
    ST_HEALTHX,
    ST_HEALTHY,
    tallnum,
    @plyr^.health,
    @st_statusbaron,
    tallpercent);

  // arms background
  STlib_initBinIcon(w_armsbg,
    ST_ARMSBGX,
    ST_ARMSBGY,
    armsbg,
    @st_notdeathmatch,
    @st_classicstatusbar);

  // weapons owned
  For i := 0 To 5 Do Begin
    STlib_initMultIcon(w_arms[i],
      ST_ARMSX + (i Mod 3) * ST_ARMSXSPACE,
      ST_ARMSY + (i Div 3) * ST_ARMSYSPACE,
      arms[i],
      @plyr^.weaponowned[weapontype_t(i + 1)],
      @st_armson);
  End;
  // [crispy] show SSG availability in the Shotgun slot of the arms widget
  w_arms[1].inum := @st_shotguns;

  // frags sum
  STlib_initNum(w_frags,
    ST_FRAGSX,
    ST_FRAGSY,
    tallnum,
    @st_fragscount,
    @st_fragson,
    ST_FRAGSWIDTH);

  // faces
  STlib_initMultIcon(w_faces,
    ST_FACESX,
    ST_FACESY,
    faces,
    @st_faceindex,
    @st_statusbarface);

  // armor percentage - should be colored later
  STlib_initPercent(w_armor,
    ST_ARMORX,
    ST_ARMORY,
    tallnum,
    @plyr^.armorpoints,
    @st_statusbaron, tallpercent);

  // keyboxes 0-2
  STlib_initMultIcon(w_keyboxes[0],
    ST_KEY0X,
    ST_KEY0Y,
    keys,
    @keyboxes[0],
    @st_statusbaron);

  STlib_initMultIcon(w_keyboxes[1],
    ST_KEY1X,
    ST_KEY1Y,
    keys,
    @keyboxes[1],
    @st_statusbaron);

  STlib_initMultIcon(w_keyboxes[2],
    ST_KEY2X,
    ST_KEY2Y,
    keys,
    @keyboxes[2],
    @st_statusbaron);

  // ammo count (all four kinds)
  STlib_initNum(w_ammo[0],
    ST_AMMO0X,
    ST_AMMO0Y,
    shortnum,
    @plyr^.ammo[0],
    @st_statusbaron,
    ST_AMMO0WIDTH);

  STlib_initNum(w_ammo[1],
    ST_AMMO1X,
    ST_AMMO1Y,
    shortnum,
    @plyr^.ammo[1],
    @st_statusbaron,
    ST_AMMO1WIDTH);

  STlib_initNum(w_ammo[2],
    ST_AMMO2X,
    ST_AMMO2Y,
    shortnum,
    @plyr^.ammo[2],
    @st_statusbaron,
    ST_AMMO2WIDTH);

  STlib_initNum(w_ammo[3],
    ST_AMMO3X,
    ST_AMMO3Y,
    shortnum,
    @plyr^.ammo[3],
    @st_statusbaron,
    ST_AMMO3WIDTH);

  // max ammo count (all four kinds)
  STlib_initNum(w_maxammo[0],
    ST_MAXAMMO0X,
    ST_MAXAMMO0Y,
    shortnum,
    @plyr^.maxammo[0],
    @st_statusbaron,
    ST_MAXAMMO0WIDTH);

  STlib_initNum(w_maxammo[1],
    ST_MAXAMMO1X,
    ST_MAXAMMO1Y,
    shortnum,
    @plyr^.maxammo[1],
    @st_statusbaron,
    ST_MAXAMMO1WIDTH);

  STlib_initNum(w_maxammo[2],
    ST_MAXAMMO2X,
    ST_MAXAMMO2Y,
    shortnum,
    @plyr^.maxammo[2],
    @st_statusbaron,
    ST_MAXAMMO2WIDTH);

  STlib_initNum(w_maxammo[3],
    ST_MAXAMMO3X,
    ST_MAXAMMO3Y,
    shortnum,
    @plyr^.maxammo[3],
    @st_statusbaron,
    ST_MAXAMMO3WIDTH);
End;

Procedure ST_Start;
Begin
  If (Not st_stopped) Then ST_Stop();

  ST_initData();
  ST_createWidgets();
  st_stopped := false;
End;


Function ST_calcPainOffset(): int;
Const
  lastcalc: int = 0;
  oldhealth: int = -1;
Var
  health: int;

Begin
  If plyr^.health > 100 Then Begin
    health := 100;
  End
  Else Begin
    health := plyr^.health;
  End;

  If (health <> oldhealth) Then Begin
    lastcalc := ST_FACESTRIDE * (((100 - health) * ST_NUMPAINFACES) Div 101);
    oldhealth := health;
  End;
  result := lastcalc;
End;

//
// This is a not-very-pretty routine which handles
//  the face states and their timing.
// the precedence of expressions is:
//  dead > evil grin > turned head > straight ahead
//
// [crispy] fix status bar face hysteresis

Procedure ST_updateFaceWidget();
Const
  lastattackdown: int = -1;
  priority: int = 0;
Var
  i: int;
  badguyangle: angle_t;
  diffang: angle_t;
  doevilgrin: boolean;
  // [crispy] fix status bar face hysteresis
  painoffset: int;
  invul: boolean;
Begin

  // [crispy] no evil grin or rampage face in god mode
  invul := ((plyr^.cheats And int(CF_GODMODE)) <> 0) Or (plyr^.powers[int(pw_invulnerability)] <> 0);

  painoffset := ST_calcPainOffset();

  If (priority < 10) Then Begin
    // dead
    If (plyr^.health = 0) Then Begin
      priority := 9;
      painoffset := 0;
      faceindex := ST_DEADFACE;
      st_facecount := 1;
    End;
  End;

  If (priority < 9) Then Begin

    If (plyr^.bonuscount <> 0) Then Begin

      // picking up bonus
      doevilgrin := false;

      For i := 0 To int(NUMWEAPONS) - 1 Do Begin
        If (oldweaponsowned[i] <> odd(plyr^.weaponowned[weapontype_t(i)])) Then Begin
          doevilgrin := true;
          oldweaponsowned[i] := odd(plyr^.weaponowned[weapontype_t(i)]);
        End;
      End;
      // [crispy] no evil grin in god mode
      If (doevilgrin) And (Not invul) Then Begin

        // evil grin if just picked up weapon
        priority := 8;
        st_facecount := ST_EVILGRINCOUNT;
        faceindex := ST_EVILGRINOFFSET;
      End;
    End;
  End;

  If (priority < 8) Then Begin

    If (plyr^.damagecount <> 0)
      And assigned(plyr^.attacker)
      And (plyr^.attacker <> plyr^.mo) Then Begin
      // being attacked
      priority := 7;

      // [crispy] show "Ouch Face" as intended
      If (st_oldhealth - plyr^.health > ST_MUCHPAIN) Then Begin
        // [crispy] raise "Ouch Face" priority
        priority := 8;
        st_facecount := ST_TURNCOUNT;
        faceindex := ST_OUCHOFFSET;
      End
      Else Begin
        badguyangle := R_PointToAngle2(plyr^.mo^.x,
          plyr^.mo^.y,
          plyr^.attacker^.x,
          plyr^.attacker^.y);

        If (badguyangle > plyr^.mo^.angle) Then Begin

          // whether right or left
          diffang := angle_t(badguyangle - plyr^.mo^.angle);
          i := ord(diffang > ANG180);
        End
        Else Begin
          // whether left or right
          diffang := angle_t(plyr^.mo^.angle - badguyangle);
          i := ord(diffang <= ANG180);
        End; // confusing, aint it?

        st_facecount := ST_TURNCOUNT;

        If (diffang < ANG45) Then Begin
          // head-on
          faceindex := ST_RAMPAGEOFFSET;
        End
        Else If (i <> 0) Then Begin
          // turn face right
          faceindex := ST_TURNOFFSET;
        End
        Else Begin
          // turn face left
          faceindex := ST_TURNOFFSET + 1;
        End;
      End;
    End;
  End;

  If (priority < 7) Then Begin
    // getting hurt because of your own damn stupidity
    If (plyr^.damagecount <> 0) Then Begin
      // [crispy] show "Ouch Face" as intended
      If (st_oldhealth - plyr^.health > ST_MUCHPAIN) Then Begin
        priority := 7;
        st_facecount := ST_TURNCOUNT;
        faceindex := ST_OUCHOFFSET;
      End
      Else Begin
        priority := 6;
        st_facecount := ST_TURNCOUNT;
        faceindex := ST_RAMPAGEOFFSET;
      End;
    End;
  End;

  If (priority < 6) Then Begin

    // rapid firing
    If (plyr^.attackdown) Then Begin
      If (lastattackdown = -1) Then
        lastattackdown := ST_RAMPAGEDELAY
      Else Begin
        // [crispy] no rampage face in god mode
        lastattackdown := lastattackdown - 1;
        If (lastattackdown = 0) And (Not invul) Then Begin
          priority := 5;
          faceindex := ST_RAMPAGEOFFSET;
          st_facecount := 1;
          lastattackdown := 1;
        End;
      End;
    End
    Else
      lastattackdown := -1;
  End;

  If (priority < 5) Then Begin

    // invulnerability
    If (invul) Then Begin

      priority := 4;
      painoffset := 0;
      faceindex := ST_GODFACE;
      st_facecount := 1;
    End;
  End;

  // look left or look right if the facecount has timed out
  If (st_facecount = 0) Then Begin

    faceindex := st_randomnumber Mod 3;
    st_facecount := ST_STRAIGHTFACECOUNT;
    priority := 0;
  End;

  st_facecount := st_facecount - 1;

  // [crispy] fix status bar face hysteresis
  st_faceindex := painoffset + faceindex;
End;

Procedure ST_updateWidgets();
Const
  largeammo: int = 1994; // means "n/a"
Var
  i: int;
Begin

  // must redirect the pointer if the ready weapon has changed.
  //  if (w_ready.data <> plyr^.readyweapon) then begin
  //
  If (weaponinfo[int(plyr^.readyweapon)].ammo = am_noammo) Then
    w_ready.num := @largeammo
  Else
    w_ready.num := @plyr^.ammo[int(weaponinfo[int(plyr^.readyweapon)].ammo)];
  //{
  // static int tic=0;
  // static int dir=-1;
  // if (!(tic&15))
  //   plyr->ammo[weaponinfo[plyr->readyweapon].ammo]+=dir;
  // if (plyr->ammo[weaponinfo[plyr->readyweapon].ammo] == -100)
  //   dir = 1;
  // tic++;
  // }
  w_ready.data := int(plyr^.readyweapon);

  // if (*w_ready.on)
  //  STlib_updateNum(&w_ready, true);
  // refresh weapon change
  //  }

  // update keycard multiple widgets
  For i := 0 To 2 Do Begin

    If plyr^.cards[card_t(i)] Then Begin
      keyboxes[i] := i;
    End
    Else Begin
      keyboxes[i] := -1;
    End;

    If (plyr^.cards[card_t(i + 3)]) Then Begin
      If (keyboxes[i] = -1) Then Begin
        keyboxes[i] := i + 3; // [crispy] support combined card and skull keys
      End
      Else Begin
        keyboxes[i] := i + 6; // [crispy] support combined card and skull keys
      End;
    End;
    // [crispy] blinking key or skull in the status bar
    If (plyr^.tryopen[card_t(i)] <> 0) Then Begin
      //#if defined(CRISPY_KEYBLINK_WITH_SOUND)
      //		if (!(plyr^.tryopen[i] & (2*KEYBLINKMASK-1)))
      //		{
      //			S_StartSound(NULL, sfx_itemup);
      //		}
      //#endif
      //#if defined(CRISPY_KEYBLINK_IN_CLASSIC_HUD)
      //		if (st_classicstatusbar && !(plyr^.tryopen[i] & (KEYBLINKMASK-1)))
      //		{
      //			st_firsttime = true;
      //		}
      //#endif
      plyr^.tryopen[card_t(i)] := plyr^.tryopen[card_t(i)] - 1;
      //#if !defined(CRISPY_KEYBLINK_IN_CLASSIC_HUD)
      //		if (st_crispyhud)then
      //#endif
      Begin
        If (plyr^.tryopen[card_t(i)] And KEYBLINKMASK) <> 0 Then Begin
          keyboxes[i] := i + st_keyorskull[card_t(i)];
        End
        Else Begin
          keyboxes[i] := -1;
        End;
      End;
      If (plyr^.tryopen[card_t(i)] = 0) Then Begin
        w_keyboxes[i].oldinum := -1;
      End;
    End;
  End;

  // refresh everything if this is him coming back to life
  ST_updateFaceWidget();

  // used by the w_armsbg widget
  st_notdeathmatch := deathmatch = 0;

  // used by w_arms[] widgets
  st_armson := st_statusbaron And (deathmatch = 0);

  // used by w_frags widget
  st_fragson := (deathmatch <> 0) And st_statusbaron;
  st_fragscount := 0;

  For i := 0 To MAXPLAYERS - 1 Do Begin
    If (i <> displayplayer) Then
      st_fragscount := st_fragscount + plyr^.frags[i]
    Else
      st_fragscount := st_fragscount - plyr^.frags[i];
  End;

  // get rid of chat window if up because of message
  st_msgcounter := st_msgcounter - 1;
  If (st_msgcounter = 0) Then
    st_chat := st_oldchat;
End;

Procedure ST_doPaletteStuff();
Begin

  //    int		palette;
  //#ifndef CRISPY_TRUECOLOR
  //    byte*	pal;
  //#endif
  //    int		cnt;
  //    int		bzc;
  //
  //    cnt = plyr->damagecount;
  //
  //    if (plyr->powers[pw_strength])
  //    {
  //	// slowly fade the berzerk out
  //  	bzc = 12 - (plyr->powers[pw_strength]>>6);
  //
  //	if (bzc > cnt)
  //	    cnt = bzc;
  //    }
  //
  //    // [crispy] A11Y
  //    if (!a11y_palette_changes)
  //    {
  //	palette = 0;
  //    }
  //    else
  //    if (cnt)
  //    {
  //	palette = (cnt+7)>>3;
  //
  //	if (palette >= NUMREDPALS)
  //	    palette = NUMREDPALS-1;
  //
  //	// [crispy] tune down a bit so the menu remains legible
  //	if (menuactive || paused)
  //	    palette >>= 1;
  //
  //	palette += STARTREDPALS;
  //    }
  //
  //    else if (plyr->bonuscount && plyr->health > 0) // [crispy] never show the yellow bonus palette for a dead player
  //    {
  //	palette = (plyr->bonuscount+7)>>3;
  //
  //	if (palette >= NUMBONUSPALS)
  //	    palette = NUMBONUSPALS-1;
  //
  //	palette += STARTBONUSPALS;
  //    }
  //
  //    else if ( plyr->powers[pw_ironfeet] > 4*32
  //	      || plyr->powers[pw_ironfeet]&8)
  //	palette = RADIATIONPAL;
  //    else
  //	palette = 0;
  //
  //    // In Chex Quest, the player never sees red.  Instead, the
  //    // radiation suit palette is used to tint the screen green,
  //    // as though the player is being covered in goo by an
  //    // attacking flemoid.
  //
  //    if (gameversion == exe_chex
  //     && palette >= STARTREDPALS && palette < STARTREDPALS + NUMREDPALS)
  //    {
  //        palette = RADIATIONPAL;
  //    }
  //
  //    // [crispy] prevent palette changes when in help screen or Crispness menu
  //    if (inhelpscreens)
  //    {
  //	palette = 0;
  //    }
  //
  //    if (palette != st_palette)
  //    {
  //	st_palette = palette;
  //#ifndef CRISPY_TRUECOLOR
  //	pal = (byte *) W_CacheLumpNum (lu_palette, PU_CACHE)+palette*768;
  //	I_SetPalette (pal);
  //#else
  //	I_SetPalette (palette);
  //#endif
  //    }

End;

Procedure ST_Ticker();
Begin
  st_randomnumber := M_Random.M_Random();
  ST_updateWidgets();
  st_oldhealth := plyr^.health;

  // Do red-/gold-shifts from damage/items
  ST_doPaletteStuff();
End;

Procedure ST_refreshBackground(force: boolean);
Begin
  If (st_classicstatusbar) Or (force) Then Begin

    V_UseBuffer(st_backing_screen);

    // [crispy] this is our own local copy of R_FillBackScreen() to
    // fill the entire background of st_backing_screen with the bezel pattern,
    // so it appears to the left and right of the status bar in widescreen mode
    If ((SCREENWIDTH Shr crispy.hires) <> ST_WIDTH) Then Begin
      Raise exception.create('Not planed to support widescreen mode ?');
      //		byte *src;
      //		pixel_t *dest;
      //		const char *name = (gamemode == commercial) ? DEH_String("GRNROCK") : DEH_String("FLOOR7_2");
      //
      //		src = W_CacheLumpName(name, PU_CACHE);
      //		dest = st_backing_screen;
      //
      //		// [crispy] use unified flat filling function
      //		V_FillFlat(SCREENHEIGHT-(ST_HEIGHT<<crispy->hires), SCREENHEIGHT, 0, SCREENWIDTH, src, dest);
      //
      //		// [crispy] preserve bezel bottom edge
      //		if (scaledviewwidth == SCREENWIDTH)
      //		{
      //			int x;
      //			patch_t *const patch = W_CacheLumpName(DEH_String("brdr_b"), PU_CACHE);
      //
      //			for (x = 0; x < WIDESCREENDELTA; x += 8)
      //			{
      //				V_DrawPatch(x - WIDESCREENDELTA, 0, patch);
      //				V_DrawPatch(ORIGWIDTH + WIDESCREENDELTA - x - 8, 0, patch);
      //			}
      //		}
    End;

    // [crispy] center unity rerelease wide status bar
    If (sbar^.width > ORIGWIDTH) And (sbar^.leftoffset = 0) Then Begin
      V_DrawPatch(ST_X + (ORIGWIDTH - sbar^.width) Div 2, 0, sbar);
    End
    Else Begin
      V_DrawPatch(ST_X, 0, sbar);
    End;

    // draw right side of bar if needed (Doom 1.0)
    If assigned(sbarr) Then
      V_DrawPatch(ST_ARMSBGX, 0, sbarr);

    // [crispy] back up arms widget background
    If (deathmatch = 0) Then
      V_DrawPatch(ST_ARMSBGX, 0, armsbg);

    // [crispy] killough 3/7/98: make face background change with displayplayer
    If (netgame) Then
      V_DrawPatch(ST_FX, 0, faceback[displayplayer]);

    V_RestoreBuffer();

    // [crispy] copy entire SCREENWIDTH, to preserve the pattern
    // to the left and right of the status bar in widescreen mode
    If (Not force) Then Begin
      V_CopyRect(ST_X, 0, st_backing_screen, SCREENWIDTH Shr crispy.hires, ST_HEIGHT, ST_X, ST_Y);
    End
    Else If (WIDESCREENDELTA > 0) And (Not st_firsttime) Then Begin
      V_CopyRect(0, 0, st_backing_screen, WIDESCREENDELTA, ST_HEIGHT, 0, ST_Y);
      V_CopyRect(ORIGWIDTH + WIDESCREENDELTA, 0, st_backing_screen, WIDESCREENDELTA, ST_HEIGHT, ORIGWIDTH + WIDESCREENDELTA, ST_Y);
    End;
  End;
End;

Procedure ST_DrawDemoTimer(time: int);
Begin
  Raise Exception.Create('Port me.');
End;

// [crispy] return ammo/health/armor widget color

Function ST_WidgetColor(i: int): TBytes;
Var
  armor, frags, health, fullammo, ammo: int;
Begin
  result := Nil;
  If ((crispy.coloredhud And COLOREDHUD_BAR) = 0) Then Begin
    exit;
  End;
  Case (hudcolor_t(i)) Of
    hudcolor_ammo: Begin
        If (weaponinfo[int(plyr^.readyweapon)].ammo = am_noammo) Then Begin
          exit;
        End
        Else Begin
          ammo := plyr^.ammo[int(weaponinfo[int(plyr^.readyweapon)].ammo)];
          fullammo := maxammo[int(weaponinfo[int(plyr^.readyweapon)].ammo)];
          If (ammo < fullammo Div 4) Then
            result := cr[CR_RED]
          Else If (ammo < fullammo Div 2) Then
            result := cr[CR_GOLD]
          Else If (ammo <= fullammo) Then
            result := cr[CR_GREEN]
          Else
            result := cr[CR_BLUE];
        End;
      End;
    hudcolor_health: Begin
        health := plyr^.health;
        // [crispy] Invulnerability powerup and God Mode cheat turn Health values gray
        If (plyr^.cheats And int(CF_GODMODE) <> 0) Or
          (plyr^.powers[int(pw_invulnerability)] <> 0) Then
          result := cr[CR_GRAY]
        Else If (health < 25) Then
          result := cr[CR_RED]
        Else If (health < 50) Then
          result := cr[CR_GOLD]
        Else If (health <= 100) Then
          result := cr[CR_GREEN]
        Else
          result := cr[CR_BLUE];
      End;
    hudcolor_frags: Begin
        frags := st_fragscount;
        If (frags < 0) Then
          result := cr[CR_RED]
        Else If (frags = 0) Then
          result := cr[CR_GOLD]
        Else
          result := cr[CR_GREEN];
      End;
    hudcolor_armor: Begin
        // [crispy] Invulnerability powerup and God Mode cheat turn Armor values gray
        If (plyr^.cheats And int(CF_GODMODE) <> 0) Or
          (plyr^.powers[int(pw_invulnerability)] <> 0) Then
          result := cr[CR_GRAY]
            // [crispy] color by armor type
        Else If (plyr^.armortype >= 2) Then
          result := cr[CR_BLUE]
        Else If (plyr^.armortype = 1) Then
          result := cr[CR_GREEN]
        Else If (plyr^.armortype = 0) Then
          result := cr[CR_RED];
        (*
        // [crispy] alternatively, color by armor points
        armor := plyr^.armorpoints;
        If (armor < 25) Then
          result := cr[CR_RED]
        Else If (armor < 50) Then
          result := cr[CR_GOLD]
        Else If (armor <= 100) Then
          result := cr[CR_GREEN]
        Else
          result := cr[CR_BLUE];
        // *)
      End;
  End;
End;

// [crispy] draw the gibbed death state frames in the Health widget
// in sync with the actual player sprite

Function ST_PlayerIsGibbed(): Boolean;
Var
  state: statenum_t;
Begin
  state := statenum_t((plyr^.mo^.state - @states[0]) Div sizeof(states[0]));
  result := (plyr^.health <= 0) And
    (((state >= (S_PLAY_XDIE1)) And (state <= (S_PLAY_XDIE9))) Or
    (state = (S_GIBS)));
End;

Procedure ST_DrawGibbedPlayerSprites();
Begin
  Raise exception.create('Port me.');
  //        state_t const *state = plyr->mo->state;
  //	spritedef_t *sprdef;
  //	spriteframe_t *sprframe;
  //	patch_t *patch;
  //
  //	sprdef = &sprites[state->sprite];
  //
  //	// [crispy] the TNT1 sprite is not supposed to be rendered anyway
  //	if (!sprdef->numframes && plyr->mo->sprite == SPR_TNT1)
  //	{
  //		return;
  //	}
  //
  //	sprframe = &sprdef->spriteframes[state->frame & FF_FRAMEMASK];
  //	patch = W_CacheLumpNum(sprframe->lump[0] + firstspritelump, PU_CACHE);
  //
  //	if (plyr->mo->flags & MF_TRANSLATION)
  //	{
  //		dp_translation = translationtables - 256 +
  //		                 ((plyr->mo->flags & MF_TRANSLATION) >> (MF_TRANSSHIFT - 8));
  //	}
  //
  //	V_DrawPatch(ST_HEALTHX - 17, 186, patch);
  //	dp_translation = NULL;
End;

Procedure ST_drawWidgets(refresh: boolean);
Const
  lump: int = -1;
Var
  i: int;
  gibbed: boolean;
  patch: Ppatch_t;
Begin
  gibbed := false;

  // used by w_arms[] widgets
  st_armson := st_statusbaron And (deathmatch = 0);

  // used by w_frags widget
  st_fragson := (deathmatch <> 0) And st_statusbaron;

  dp_translation := ST_WidgetColor(int(hudcolor_ammo));
  STlib_updateNum(@w_ready, refresh);
  dp_translation := Nil;

  // [crispy] draw "special widgets" in the Crispy HUD
  If (st_crispyhud) Then Begin
    // [crispy] draw berserk pack instead of no ammo if appropriate
    If (plyr^.readyweapon = wp_fist) And (plyr^.powers[int(pw_strength)] <> 0) Then Begin
      If (lump = -1) Then Begin
        lump := W_CheckNumForName('PSTRA0');
        If (lump = -1) Then Begin
          lump := W_CheckNumForName('MEDIA0');
        End;
      End;
      patch := W_CacheLumpNum(lump, PU_CACHE);
      // [crispy] (23,179) is the center of the Ammo widget
      V_DrawPatch(ST_AMMOX - 2 * 21 - SHORT(patch^.width) Div 2 + SHORT(patch^.leftoffset),
        179 - SHORT(patch^.height) Div 2 + SHORT(patch^.topoffset),
        patch);
    End;

    // [crispy] draw the gibbed death state frames in the Health widget
    // in sync with the actual player sprite
    gibbed := ST_PlayerIsGibbed();
    If (gibbed) Then Begin
      ST_DrawGibbedPlayerSprites();
    End;
  End;

  For i := 0 To 3 Do Begin
    STlib_updateNum(@w_ammo[i], refresh);
    STlib_updateNum(@w_maxammo[i], refresh);
  End;

  If (Not gibbed) Then Begin
    dp_translation := ST_WidgetColor(int(hudcolor_health));
    // [crispy] negative player health
    If crispy.neghealth <> 0 Then Begin
      w_health.n.num := @plyr^.neghealth;
    End
    Else Begin
      w_health.n.num := @plyr^.health;
    End;
    STlib_updatePercent(@w_health, refresh);
  End;
  dp_translation := ST_WidgetColor(int(hudcolor_armor));
  STlib_updatePercent(@w_armor, refresh);
  dp_translation := Nil;

  STlib_updateBinIcon(@w_armsbg, refresh);

  // [crispy] show SSG availability in the Shotgun slot of the arms widget
  st_shotguns := ord(plyr^.weaponowned[wp_shotgun] Or plyr^.weaponowned[wp_supershotgun]);

  For i := 0 To 5 Do
    STlib_updateMultIcon(@w_arms[i], refresh);

  // [crispy] draw the actual face widget background
  If (st_crispyhud) And (screenblocks Mod 3 = 0) Then Begin
    If (netgame) Then
      V_DrawPatch(ST_FX, ST_Y + 1, faceback[displayplayer])
    Else
      V_CopyRect(ST_FX + WIDESCREENDELTA, 1, st_backing_screen, faceback[0]^.width, ST_HEIGHT - 1, ST_FX + WIDESCREENDELTA, ST_Y + 1);
  End;
  // WTF: Hack für w_faces (Achtung 3 mal)
  WIDESCREENDELTA := 1;
  STlib_updateMultIcon(@w_faces, refresh);
  WIDESCREENDELTA := 0;

  For i := 0 To 2 Do
    STlib_updateMultIcon(@w_keyboxes[i], refresh);

  dp_translation := ST_WidgetColor(int(hudcolor_frags));
  STlib_updateNum(@w_frags, refresh);

  dp_translation := Nil;
End;

Procedure ST_doRefresh();
Begin
  st_firsttime := false;

  // draw status bar background to off-screen buff
  ST_refreshBackground(false);

  // and refresh all widgets
  ST_drawWidgets(true);
End;

Procedure ST_diffDraw();
Begin
  // update all widgets
  ST_drawWidgets(false);
End;

Procedure ST_Drawer(fullscreen, refresh: boolean);
Begin
  st_statusbaron := (Not fullscreen) Or ((automapactive) And (true {!crispy->automapoverlay}));
  // [crispy] immediately redraw status bar after help screens have been shown
  st_firsttime := st_firsttime Or refresh Or inhelpscreens;

  // [crispy] distinguish classic status bar with background and player face from Crispy HUD
  st_crispyhud := (screenblocks >= CRISPY_HUD) And ((Not automapactive) Or (crispy.automapoverlay <> 0));
  st_classicstatusbar := st_statusbaron And Not st_crispyhud;
  st_statusbarface := st_classicstatusbar Or (st_crispyhud And (screenblocks Mod 3 = 0));

  //    // [crispy] re-calculate widget coordinates on demand
  //    if (st_widescreendelta != ST_WIDESCREENDELTA)
  //    {
  //        void ST_createWidgets (void);
  //        ST_createWidgets();
  //    }

  If (crispy.cleanscreenshot = 2) Then exit;

  // [crispy] translucent HUD
  If (st_crispyhud And (screenblocks Mod 3 = 2)) Then
    dp_translucent := true;

  (*
   * Das Diff draw funktioniert zwar prinzipiel, glitcht aber doch ab und zu
   * -> wir haben die Rechenpower das auch einfach jedes mal neu zu rendern ..
   *)
  //If (st_firsttime) Then Begin
    // If just after ST_Start(), refresh all
  ST_doRefresh();
  //End
  //Else Begin
    // Otherwise, update as little as possible
    //ST_diffDraw();
  //End;

  dp_translucent := false;
End;

Function cht_CheckCheatSP(Var cht: cheatseq_t; key: char): int;
Begin
  If (cht_CheckCheat(cht, key) = 0) Then Begin
    result := 0;
    exit;
  End
  Else Begin
    If (Not crispy.singleplayer) Then Begin
      plyr^.message := 'Cheater!';
      result := 0;
      exit;
    End;
  End;
  result := 1;
End;

// [crispy] give or take backpack

Procedure GiveBackpack(give: boolean);
Var
  i: int;
Begin
  If (give) And (Not plyr^.backpack) Then Begin
    For i := 0 To integer(NUMAMMO) - 1 Do Begin
      plyr^.maxammo[i] := plyr^.maxammo[i] * 2;
    End;
    plyr^.backpack := true;
  End
  Else If (Not give) And (plyr^.backpack) Then Begin
    For i := 0 To integer(NUMAMMO) - 1 Do Begin
      plyr^.maxammo[i] := plyr^.maxammo[i] Div 2;
    End;
    plyr^.backpack := false;
  End;
End;

// [crispy] only give available weapons

Function WeaponAvailable(w: int): boolean;
Begin
  result := false;

  If (w < 0) Or (w >= integer(NUMWEAPONS)) Then exit;

  If (w = integer(wp_supershotgun)) And (Not crispy.havessg) Then exit;

  If ((w = integer(wp_bfg)) Or (w = integer(wp_plasma))) And (gamemode = shareware) Then exit;

  result := true;
End;

// Respond to keyboard input events,
//  intercept cheats.

Function ST_Responder(Const ev: Pevent_t): boolean;
Var
  i: int;
  mt: mapthing_t;
  an: angle_t;
  buf: String;
  w: int;
  epsd: int;
  map: int;
Begin
  result := false;
  // Filter automap on/off.
  If (ev^._type = ev_keyup)
    And ((ev^.data1 And $FFFF0000) = AM_MSGHEADER) Then Begin

    Case ev^.data1 Of

      AM_MSGENTERED: Begin
          st_firsttime := true;
        End;

      AM_MSGEXITED: Begin
          //	writeln(stderr, 'AM exited');
        End;
    End;
  End
    // if a user keypress...
  Else If (ev^._type = ev_keydown) Then Begin
    If ev^.data1 = key_view_zoomIn Then Begin // Corpsman, zoom BLocks in the same way like automap does
      screenblocks := math.min(12, screenblocks + 1);
      R_SetViewSize(screenblocks, detailLevel);
    End;
    If ev^.data1 = key_view_zoomOut Then Begin // Corpsman, zoom BLocks in the same way like automap does
      screenblocks := math.max(10, screenblocks - 1);
      R_SetViewSize(screenblocks, detailLevel);
    End;
    If (Not netgame) And (gameskill <> sk_nightmare) Then Begin
      // 'dqd' cheat for toggleable god mode
      If (cht_CheckCheatSP(cheat_god, chr(ev^.data2)) <> 0) Then Begin
        // [crispy] dead players are first respawned at the current position
        If (plyr^.playerstate = PST_DEAD) Then Begin
          FillChar(mt, sizeof(mt), 0);
          mt.x := SarLongint(plyr^.mo^.x, FRACBITS);
          mt.y := SarLongint(plyr^.mo^.y, FRACBITS);
          mt.angle := angle_t((plyr^.mo^.angle + ANG45 Div 2) * uint64_t(45) Div ANG45);
          mt._type := consoleplayer + 1;
          P_SpawnPlayer(mt);

          // [crispy] spawn a teleport fog
          an := plyr^.mo^.angle Shr ANGLETOFINESHIFT;
          P_SpawnMobj(plyr^.mo^.x + 20 * finecosine[an], plyr^.mo^.y + 20 * finesine[an], plyr^.mo^.z, MT_TFOG);
          S_StartSound(plyr, sfx_slop);

          // Fix reviving as "zombie" if god mode was already enabled
          If assigned(plyr^.mo) Then
            plyr^.mo^.health := deh_god_mode_health;
          plyr^.health := deh_god_mode_health;
        End;

        plyr^.cheats := plyr^.cheats Xor integer(CF_GODMODE);
        If (plyr^.cheats And integer(CF_GODMODE)) <> 0 Then Begin
          If assigned(plyr^.mo) Then
            plyr^.mo^.health := deh_god_mode_health;

          plyr^.health := deh_god_mode_health;
          plyr^.message := STSTR_DQDON;
        End
        Else
          plyr^.message := STSTR_DQDOFF;

        // [crispy] eat key press when respawning
        If (mt._type <> 0) Then Begin
          result := true;
          exit;
        End;
      End
        // 'fa' cheat for killer fucking arsenal
      Else If (cht_CheckCheatSP(cheat_ammonokey, chr(ev^.data2)) <> 0) Then Begin
        plyr^.armorpoints := deh_idfa_armor;
        plyr^.armortype := deh_idfa_armor_class;

        // [crispy] give backpack
        GiveBackpack(true);

        For i := 0 To integer(NUMWEAPONS) - 1 Do
          If (WeaponAvailable(i)) Then // [crispy] only give available weapons
            plyr^.weaponowned[weapontype_t(i)] := 1;

        For i := 0 To integer(NUMAMMO) - 1 Do
          plyr^.ammo[i] := plyr^.maxammo[i];

        // [crispy] trigger evil grin now
        plyr^.bonuscount := plyr^.bonuscount + 2;

        plyr^.message := STSTR_FAADDED;
      End
        // 'kfa' cheat for key full ammo
      Else If (cht_CheckCheatSP(cheat_ammo, chr(ev^.data2)) <> 0) Then Begin

        plyr^.armorpoints := deh_idkfa_armor;
        plyr^.armortype := deh_idkfa_armor_class;

        // [crispy] give backpack
        GiveBackpack(true);

        For i := 0 To integer(NUMWEAPONS) - 1 Do
          If (WeaponAvailable(i)) Then // [crispy] only give available weapons
            plyr^.weaponowned[weapontype_t(i)] := 1;

        For i := 0 To integer(NUMAMMO) - 1 Do
          plyr^.ammo[i] := plyr^.maxammo[i];

        For i := 0 To integer(NUMCARDS) - 1 Do
          plyr^.cards[card_t(i)] := true;

        // [crispy] trigger evil grin now
        plyr^.bonuscount := plyr^.bonuscount + 2;

        plyr^.message := STSTR_KFAADDED;
      End
        //      // 'mus' cheat for changing music
        //      else if (cht_CheckCheat(&cheat_mus, ev->data2))
        //      {
        //
        //	char	buf[3];
        //	int		musnum;
        //
        //	plyr->message = DEH_String(STSTR_MUS);
        //	cht_GetParam(&cheat_mus, buf);
        //
        //        // Note: The original v1.9 had a bug that tried to play back
        //        // the Doom II music regardless of gamemode.  This was fixed
        //        // in the Ultimate Doom executable so that it would work for
        //        // the Doom 1 music as well.
        //
        //	// [crispy] restart current music if IDMUS00 is entered
        //	if (buf[0] == '0' && buf[1] == '0')
        //	{
        //	  S_ChangeMusic(0, 2);
        //	  // [crispy] eat key press, i.e. don't change weapon upon music change
        //	  return true;
        //	}
        //	else
        //	// [JN] Fixed: using a proper IDMUS selection for shareware
        //	// and registered game versions.
        //	if (gamemode == commercial /* || gameversion < exe_ultimate */ )
        //	{
        //	  musnum = mus_runnin + (buf[0]-'0')*10 + buf[1]-'0' - 1;
        //
        //	  /*
        //	  if (((buf[0]-'0')*10 + buf[1]-'0') > 35
        //       && gameversion >= exe_doom_1_8)
        //	  */
        //	  // [crispy] prevent crash with IDMUS00
        //	  if (musnum < mus_runnin || musnum >= NUMMUSIC)
        //	    plyr->message = DEH_String(STSTR_NOMUS);
        //	  else
        //	  {
        //	    S_ChangeMusic(musnum, 1);
        //	    // [crispy] eat key press, i.e. don't change weapon upon music change
        //	    return true;
        //	  }
        //	}
        //	else
        //	{
        //	  musnum = mus_e1m1 + (buf[0]-'1')*9 + (buf[1]-'1');
        //
        //	  /*
        //	  if (((buf[0]-'1')*9 + buf[1]-'1') > 31)
        //	  */
        //	  // [crispy] prevent crash with IDMUS0x or IDMUSx0
        //	  if (musnum < mus_e1m1 || musnum >= mus_runnin ||
        //	      // [crispy] support dedicated music tracks for the 4th episode
        //	      S_music[musnum].lumpnum == -1)
        //	    plyr->message = DEH_String(STSTR_NOMUS);
        //	  else
        //	  {
        //	    S_ChangeMusic(musnum, 1);
        //	    // [crispy] eat key press, i.e. don't change weapon upon music change
        //	    return true;
        //	  }
        //	}
        //      }
        //      // [crispy] eat up the first digit typed after a cheat expecting two parameters
        //      else if (cht_CheckCheat(&cheat_mus1, ev->data2))
        //      {
        //	char buf[2];
        //
        //	cht_GetParam(&cheat_mus1, buf);
        //
        //	return isdigit(buf[0]);
        //      }
        //      // [crispy] allow both idspispopd and idclip cheats in all gamemissions
      Else If (cht_CheckCheatSP(cheat_noclip, chr(ev^.data2)) <> 0)
        Or (cht_CheckCheatSP(cheat_commercial_noclip, chr(ev^.data2)) <> 0)
        Then Begin
        plyr^.cheats := plyr^.cheats Xor integer(CF_NOCLIP);
        If (plyr^.cheats And integer(CF_NOCLIP)) <> 0 Then
          plyr^.message := STSTR_NCON
        Else
          plyr^.message := STSTR_NCOFF;
      End;
      //      // 'behold?' power-up cheats
    //      for (i=0;i<6;i++)
    //      {
    //	if (i < 4 ? cht_CheckCheatSP(&cheat_powerup[i], ev->data2) : cht_CheckCheat(&cheat_powerup[i], ev->data2))
    //	{
    //	  if (!plyr->powers[i])
    //	    P_GivePower( plyr, i);
    //	  else if (i!=pw_strength && i!=pw_allmap) // [crispy] disable full Automap
    //	    plyr->powers[i] = 1;
    //	  else
    //	    plyr->powers[i] = 0;
    //
    //	  plyr->message = DEH_String(STSTR_BEHOLDX);
    //	}
    //      }
    //      // [crispy] idbehold0
    //      if (cht_CheckCheatSP(&cheat_powerup[7], ev->data2))
    //      {
    //	memset(plyr->powers, 0, sizeof(plyr->powers));
    //	plyr->mo->flags &= ~MF_SHADOW; // [crispy] cancel invisibility
    //	plyr->message = DEH_String(STSTR_BEHOLDX);
    //      }
    //
    //      // 'behold' power-up menu
    //      if (cht_CheckCheat(&cheat_powerup[6], ev->data2))
    //      {
    //	plyr->message = DEH_String(STSTR_BEHOLD);
    //      }
    //      // 'choppers' invulnerability & chainsaw
    //      else if (cht_CheckCheatSP(&cheat_choppers, ev->data2))
    //      {
    //	plyr->weaponowned[wp_chainsaw] = true;
    //	plyr->powers[pw_invulnerability] = true;
    //	plyr->message = DEH_String(STSTR_CHOPPERS);
    //      }
    //      // 'mypos' for player position
    //      else if (cht_CheckCheat(&cheat_mypos, ev->data2))
    //      {
    ///*
    //        static char buf[ST_MSGWIDTH];
    //        M_snprintf(buf, sizeof(buf), "ang=0x%x;x,y=(0x%x,0x%x)",
    //                   players[consoleplayer].mo->angle,
    //                   players[consoleplayer].mo->x,
    //                   players[consoleplayer].mo->y);
    //        plyr->message = buf;
    //*/
    //        // [crispy] extra high precision IDMYPOS variant, updates for 10 seconds
    //        plyr->powers[pw_mapcoords] = 10*TICRATE;
    //      }
    //
    //// [crispy] now follow "critical" Crispy Doom specific cheats
    //
    //      // [crispy] implement Boom's "tntem" cheat
    //      else if (cht_CheckCheatSP(&cheat_massacre, ev->data2) ||
    //               cht_CheckCheatSP(&cheat_massacre2, ev->data2) ||
    //               cht_CheckCheatSP(&cheat_massacre3, ev->data2))
    //      {
    //	int killcount = ST_cheat_massacre();
    //	const char *const monster = (gameversion == exe_chex) ? "Flemoid" : "Monster";
    //	const char *const killed = (gameversion == exe_chex) ? "returned" : "killed";
    //
    //	M_snprintf(msg, sizeof(msg), "%s%d %s%s%s %s",
    //	           crstr[CR_GOLD],
    //	           killcount, crstr[CR_NONE], monster, (killcount == 1) ? "" : "s", killed);
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement Crispy Doom's "spechits" cheat
    //      else if (cht_CheckCheatSP(&cheat_spechits, ev->data2))
    //      {
    //	int triggeredlines = ST_cheat_spechits();
    //
    //	M_snprintf(msg, sizeof(msg), "%s%d %sSpecial Line%s Triggered",
    //	           crstr[CR_GOLD],
    //	           triggeredlines, crstr[CR_NONE], (triggeredlines == 1) ? "" : "s");
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement PrBoom+'s "notarget" cheat
    //      else if (cht_CheckCheatSP(&cheat_notarget, ev->data2) ||
    //               cht_CheckCheatSP(&cheat_notarget2, ev->data2))
    //      {
    //	plyr->cheats ^= CF_NOTARGET;
    //
    //	if (plyr->cheats & CF_NOTARGET)
    //	{
    //		int i;
    //		thinker_t *th;
    //
    //		// [crispy] let mobjs forget their target and tracer
    //		for (th = thinkercap.next; th != &thinkercap; th = th->next)
    //		{
    //			if (th->function.acp1 == (actionf_p1)P_MobjThinker)
    //			{
    //				mobj_t *const mo = (mobj_t *)th;
    //
    //				if (mo->target && mo->target->player)
    //				{
    //					mo->target = NULL;
    //				}
    //
    //				if (mo->tracer && mo->tracer->player)
    //				{
    //					mo->tracer = NULL;
    //				}
    //			}
    //		}
    //		// [crispy] let sectors forget their soundtarget
    //		for (i = 0; i < numsectors; i++)
    //		{
    //			sector_t *const sector = &sectors[i];
    //
    //			sector->soundtarget = NULL;
    //		}
    //	}
    //
    //	M_snprintf(msg, sizeof(msg), "Notarget Mode %s%s",
    //	           crstr[CR_GREEN],
    //	           (plyr->cheats & CF_NOTARGET) ? "ON" : "OFF");
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement "nomomentum" cheat, ne debug aid -- pretty useless, though
    //      else if (cht_CheckCheatSP(&cheat_nomomentum, ev->data2))
    //      {
    //	plyr->cheats ^= CF_NOMOMENTUM;
    //
    //	M_snprintf(msg, sizeof(msg), "Nomomentum Mode %s%s",
    //	           crstr[CR_GREEN],
    //	           (plyr->cheats & CF_NOMOMENTUM) ? "ON" : "OFF");
    //	plyr->message = msg;
    //      }
    //      // [crispy] implement Crispy Doom's "goobers" cheat, ne easter egg
    //      else if (cht_CheckCheatSP(&cheat_goobers, ev->data2))
    //      {
    //	extern void EV_DoGoobers (void);
    //
    //	EV_DoGoobers();
    //
    //	R_SetGoobers(true);
    //
    //	M_snprintf(msg, sizeof(msg), "Get Psyched!");
    //	plyr->message = msg;
    //End else
      //      // [crispy] implement Boom's "tntweap?" weapon cheats
      If (cht_CheckCheatSP(cheat_weapon, chr(ev^.data2)) <> 0) Then Begin
        cht_GetParam(cheat_weapon, buf);
        w := ord(buf[1]) - ord('1');

        // [crispy] TNTWEAP0 takes away all weapons and ammo except for the pistol and 50 bullets
        If (w = -1) Then Begin
          GiveBackpack(false);
          plyr^.powers[int(pw_strength)] := 0;
          For i := 0 To int(NUMWEAPONS) - 1 Do Begin
            oldweaponsowned[i] := false;
            plyr^.weaponowned[weapontype_t(i)] := 0;
          End;
          oldweaponsowned[int(wp_fist)] := true;
          plyr^.weaponowned[wp_fist] := 1;
          oldweaponsowned[int(wp_pistol)] := true;
          plyr^.weaponowned[wp_pistol] := 1;

          For i := 0 To int(NUMAMMO) - 1 Do Begin
            plyr^.ammo[i] := 0;
          End;
          plyr^.ammo[int(am_clip)] := deh_initial_bullets;

          If (plyr^.readyweapon > wp_pistol) Then Begin
            plyr^.pendingweapon := wp_pistol;
          End;

          plyr^.message := 'All weapons removed!'; // WTF: warum ist das nicht in d_englsh ?;

          result := true;
          exit;
        End;

        // [crispy] only give available weapons
        If (Not WeaponAvailable(w)) Then Begin
          result := false;
          exit;
        End;

        // make '1' apply beserker strength toggle
        If (w = int(wp_fist)) Then Begin
          If (plyr^.powers[int(pw_strength)] = 0) Then Begin
            P_GivePower(plyr, int(pw_strength));
            S_StartSound(Nil, sfx_getpow);
            plyr^.message := GOTBERSERK;
          End
          Else Begin
            plyr^.powers[int(pw_strength)] := 0;
            plyr^.message := STSTR_BEHOLDX;
          End;
        End
        Else Begin
          Raise exception.create('Port me.');
          //	    if (!plyr->weaponowned[w])
          //	    {
          //		extern boolean P_GiveWeapon (player_t* player, weapontype_t weapon, boolean dropped);
          //		extern const char *const WeaponPickupMessages[NUMWEAPONS];
          //
          //		P_GiveWeapon(plyr, w, false);
          //		S_StartSound(NULL, sfx_wpnup);
          //
          //		if (w > 1)
          //		{
          //		    plyr->message = DEH_String(WeaponPickupMessages[w]);
          //		}
          //
          //		// [crispy] trigger evil grin now
          //		plyr->bonuscount += 2;
          //	    }
          //	    else
          //	    {
          //		// [crispy] no reason for evil grin
          //		oldweaponsowned[w] = plyr->weaponowned[w] = false;
          //
          //		// [crispy] removed current weapon, select another one
          //		if (w == plyr->readyweapon)
          //		{
          //		    extern boolean P_CheckAmmo (player_t* player);
          //
          //		    P_CheckAmmo(plyr);
          //		}
          //	    }
        End;
        If (plyr^.message = '') Then Begin
          // Raise exception.create('Port me.');
          //	    M_snprintf(msg, sizeof(msg), "Weapon %s%d%s %s",
          //	               crstr[CR_GOLD], w + 1, crstr[CR_NONE],
          //	               plyr->weaponowned[w] ? "added" : "removed");
          //	    plyr->message = msg;
          //	}
        End;
      End;


      //// [crispy] now follow "harmless" Crispy Doom specific cheats
      //
      //    // [crispy] implement Crispy Doom's "showfps" cheat, ne debug aid
      //    if (cht_CheckCheat(&cheat_showfps, ev->data2) ||
      //             cht_CheckCheat(&cheat_showfps2, ev->data2))
        //    {
        //	plyr->powers[pw_showfps] ^= 1;
        //    }
        //    // [crispy] implement Boom's "tnthom" cheat
        //    else if (cht_CheckCheat(&cheat_hom, ev->data2))
        //    {
        //	crispy->flashinghom = !crispy->flashinghom;
        //
        //	M_snprintf(msg, sizeof(msg), "HOM Detection %s%s",
        //	           crstr[CR_GREEN],
        //	           (crispy->flashinghom) ? "ON" : "OFF");
        //	plyr->message = msg;
        //    }
        //    // [crispy] Show engine version, build date and SDL version
        //    else if (cht_CheckCheat(&cheat_version, ev->data2))
        //    {
        //#ifndef BUILD_DATE
        //#define BUILD_DATE __DATE__
        //#endif
        //      M_snprintf(msg, sizeof(msg), "%s (%s) x%ld SDL%s",
        //                 PACKAGE_STRING,
        //                 BUILD_DATE,
        //                 (long) sizeof(void *) * CHAR_BIT,
        //                 crispy->sdlversion);
        //#undef BUILD_DATE
        //      plyr->message = msg;
        //      fprintf(stderr, "%s\n", msg);
        //    }
        //    // [crispy] Show skill level
        //    else if (cht_CheckCheat(&cheat_skill, ev->data2))
        //    {
        //      extern const char *skilltable[];
        //
        //      M_snprintf(msg, sizeof(msg), "Skill: %s",
        //                 skilltable[BETWEEN(0,5,(int) gameskill+1)]);
        //      plyr->message = msg;
        //    }
        //    // [crispy] snow
        //    else if (cht_CheckCheat(&cheat_snow, ev->data2))
        //    {
        //      crispy->snowflakes = !crispy->snowflakes;
        //    }
    End;


    // 'clev' change-level cheat
    If (Not netgame) And (cht_CheckCheat(cheat_clev, chr(ev^.data2)) <> 0) And (Not menuactive) Then Begin // [crispy] prevent only half the screen being updated
      cht_GetParam(cheat_clev, buf);

      If (gamemode = commercial) Then Begin

        If (gamemission = pack_master) Then
          epsd := 3
        Else If (gamemission = pack_nerve) Then
          epsd := 2
        Else
          epsd := 0;
        map := strtointdef(buf, -1);
      End
      Else Begin
        epsd := StrToIntDef(buf[1], -1);
        map := StrToIntDef(buf[2], -1);

        // Chex.exe always warps to episode 1.
        If (gameversion = exe_chex) Then Begin
          If (epsd > 1) Then epsd := 1;
          If (map > 5) Then map := 5;
        End;
      End;

      // [crispy] only fix episode/map if it doesn't exist
      If (P_GetNumForMap(epsd, map, false) < 0) Then Begin
        // Catch invalid maps.
        If (gamemode <> commercial) Then Begin
          // [crispy] allow IDCLEV0x to work in Doom 1
          If (epsd = 0) Then Begin
            epsd := gameepisode;
          End;
          If (epsd < 1) Then Begin
            result := false;
            exit;
          End;
          If (epsd > 4) Then Begin
            // [crispy] Sigil
            If Not (crispy.haved1e5 And (epsd = 5)) And
              Not (crispy.haved1e6 And (epsd = 6)) Then Begin
              result := false;
              exit;
            End;
          End;
          If (epsd = 4) And (gameversion < exe_ultimate) Then Begin
            result := false;
            exit;
          End;
          // [crispy] IDCLEV00 restarts current map
          If ((map = 0) And (buf[1] = '0')) Then Begin
            map := gamemap;
          End;
          // [crispy] support E1M10 "Sewers"
          If ((map = 0) Or (map > 9)) And crispy.havee1m10 And (epsd = 1) Then Begin
            map := 10;
          End;
          If (map < 1) Then Begin
            result := false;
            exit;
          End;
          If (map > 9) Then Begin
            // [crispy] support E1M10 "Sewers"
            If (Not (crispy.havee1m10 And (epsd = 1) And (map = 10))) Then Begin
              result := false;
              exit;
            End;
          End;
        End
        Else Begin
          // [crispy] IDCLEV00 restarts current map
          If ((map = 0) And (buf[1] = '0')) Then Begin
            map := gamemap;
          End;
          If (map < 1) Then Begin
            result := false;
            exit;
          End;
          If (map > 40) Then Begin
            result := false;
            exit;
          End;
          If (map > 9) And (gamemission = pack_nerve) Then Begin
            result := false;
            exit;
          End;
          If (map > 21) And (gamemission = pack_master) Then Begin
            result := false;
            exit;
          End;
        End;
      End;

      // [crispy] prevent idclev to nonexistent levels exiting the game
      If (P_GetNumForMap(epsd, map, false) >= 0) Then Begin

        // So be it.
        plyr^.message := STSTR_CLEV;
        // [crisp] allow IDCLEV during demo playback and warp to the requested map
        If (demoplayback) Then Begin

          crispy.demowarp := map;
          nodrawers := true;
          singletics := true;

          If (map <= gamemap) Then Begin
            G_DoPlayDemo();
          End;

          result := true;
          exit;
        End
        Else
          G_DeferedInitNew(gameskill, epsd, map);
        // [crispy] eat key press, i.e. don't change weapon upon level change
        result := true;
        exit;
      End;
    End
      // [crispy] eat up the first digit typed after a cheat expecting two parameters
    Else If (Not netgame) And (cht_CheckCheat(cheat_clev1, chr(ev^.data2)) <> 0) And (Not menuactive) Then Begin
      cht_GetParam(cheat_clev1, buf);
      result := isdigit(buf[1]);
    End;
  End;
End;

// Iterates through all graphics to be loaded or unloaded, along with
// the variable they use, invoking the specified callback function.

Procedure ST_loadUnloadGraphics(callback: load_callback_t);
Var
  i, j: int;
  facenum: int;
  namebuf: String;
Begin
  // Load the numbers, tall and short
  For i := 0 To 9 Do Begin

    namebuf := format('STTNUM%d', [i]);
    callback(namebuf, @tallnum[i]);

    namebuf := format('STYSNUM%d', [i]);
    callback(namebuf, @shortnum[i]);
  End;

  // Load percent key.
  //Note: why not load STMINUS here, too?

  callback('STTPRCNT', @tallpercent);

  // key cards
  For i := 0 To integer(NUMCARDS) - 1 Do Begin
    namebuf := format('STKEYS%d', [i]);
    callback(namebuf, @keys[i]);
  End;

  // arms background
  callback('STARMS', @armsbg);

  // arms ownership widgets
  For i := 0 To 5 Do Begin
    namebuf := format('STGNUM%d', [i + 2]);

    // gray #
    callback(namebuf, @arms[i][0]);

    // yellow #
    arms[i][1] := shortnum[i + 2];
  End;

  // face backgrounds for different color players
  // [crispy] killough 3/7/98: add better support for spy mode by loading
  // all player face backgrounds and using displayplayer to choose them:

  For i := 0 To MAXPLAYERS - 1 Do Begin
    namebuf := format('STFB%d', [i]);
    callback(namebuf, @faceback[i]);
  End;

  // status bar background bits
  If (W_CheckNumForName('STBAR') >= 0) Then Begin
    callback('STBAR', @sbar);
    sbarr := Nil;
  End
  Else Begin
    callback('STMBARL', @sbar);
    callback('STMBARR', @sbarr);
  End;

  // face states
  facenum := 0;
  For i := 0 To ST_NUMPAINFACES - 1 Do Begin
    For j := 0 To ST_NUMSTRAIGHTFACES - 1 Do Begin
      namebuf := format('STFST%d%d', [i, j]);
      callback(namebuf, @faces[facenum]);
      facenum := facenum + 1;
    End;
    namebuf := format('STFTR%d0', [i]); // turn right
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
    namebuf := format('STFTL%d0', [i]); // turn left
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
    namebuf := format('STFOUCH%d', [i]); // ouch!
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
    namebuf := format('STFEVL%d', [i]); // evil grin ;)
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
    namebuf := format('STFKILL%d', [i]); // pissed off
    callback(namebuf, @faces[facenum]);
    facenum := facenum + 1;
  End;

  callback('STFGOD0', @faces[facenum]);
  facenum := facenum + 1;
  callback('STFDEAD0', @faces[facenum]);
  facenum := facenum + 1;
End;

Procedure ST_loadCallback(lumpname: String; variable: PPPatch_t);
Begin
  variable^ := W_CacheLumpName(lumpname, PU_STATIC);
End;

Procedure ST_loadGraphics();
Begin
  ST_loadUnloadGraphics(@ST_loadCallback);
End;

Procedure ST_loadData();
Var
  i: int;
  lumpname: String;
  lumpnum: int;
Begin
  lu_palette := W_GetNumForName('PLAYPAL');
  ST_loadGraphics();

  // [crispy] support combined card and skull keys (if provided by PWAD)
  // i.e. only for display in the status bar
  For i := integer(NUMCARDS) To integer(NUMCARDS) + 3 - 1 Do Begin
    lumpname := format('STKEYS%d', [i]);
    lumpnum := W_CheckNumForName(lumpname);
    If (lumpnum <> -1) Then Begin
      keys[i] := W_CacheLumpNum(lumpnum, PU_STATIC);
    End
    Else Begin
      keys[i] := keys[i - 3];
    End;
  End;
End;

Procedure ST_Init();
Begin
  // [crispy] colorize the confusing 'behold' power-up menu
  //    if (!DEH_HasStringReplacement(STSTR_BEHOLD) &&
  //        !M_ParmExists("-nodeh"))
  //    {
  //	char str_behold[80];
  //	M_snprintf(str_behold, sizeof(str_behold),
  //	           "in%sV%suln, %sS%str, %sI%snviso, %sR%sad, %sA%sllmap, or %sL%site-amp",
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE],
  //	           crstr[CR_GOLD], crstr[CR_NONE]);
  //	DEH_AddStringReplacement(STSTR_BEHOLD, str_behold);
  //    }

  ST_loadData();
  setlength(st_backing_screen, MAXWIDTH * (ST_HEIGHT Shl 1) * sizeof(pixel_t)); // WTF: müsste hier nicht Crispy.hires +1 stehen ?
End;


End.

