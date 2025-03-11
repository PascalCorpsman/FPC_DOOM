Unit f_finale;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_event, d_mode, d_englsh
  ;

Type
  textscreen_t = Record
    mission: GameMission_t;
    episode, level: int;
    background: String;
    text: String;
  End;

Const // FPC_DOOM braucht das nicht so "öffentlich" aber der WAD-Viewer
  textscreens: Array Of textscreen_t =
  (
    (mission: doom; episode: 1; level: 8; Background: 'FLOOR4_8'; text: E1TEXT),
    (mission: doom; episode: 2; level: 8; Background: 'SFLR6_1'; text: E2TEXT),
    (mission: doom; episode: 3; level: 8; Background: 'MFLR8_4'; text: E3TEXT),
    (mission: doom; episode: 4; level: 8; Background: 'MFLR8_3'; text: E4TEXT),
    (mission: doom; episode: 5; level: 8; Background: 'FLOOR7_2'; text: E5TEXT), // [crispy] Sigil
    (mission: doom; episode: 6; level: 8; Background: 'FLOOR7_2'; text: E6TEXT), // [crispy] Sigil II

    (mission: doom2; episode: 1; level: 6; Background: 'SLIME16'; text: C1TEXT),
    (mission: doom2; episode: 1; level: 11; Background: 'RROCK14'; text: C2TEXT),
    (mission: doom2; episode: 1; level: 20; Background: 'RROCK07'; text: C3TEXT),
    (mission: doom2; episode: 1; level: 30; Background: 'RROCK17'; text: C4TEXT),
    (mission: doom2; episode: 1; level: 15; Background: 'RROCK13'; text: C5TEXT),
    (mission: doom2; episode: 1; level: 31; Background: 'RROCK19'; text: C6TEXT),

    (mission: pack_tnt; episode: 1; level: 6; Background: 'SLIME16'; text: T1TEXT),
    (mission: pack_tnt; episode: 1; level: 11; Background: 'RROCK14'; text: T2TEXT),
    (mission: pack_tnt; episode: 1; level: 20; Background: 'RROCK07'; text: T3TEXT),
    (mission: pack_tnt; episode: 1; level: 30; Background: 'RROCK17'; text: T4TEXT),
    (mission: pack_tnt; episode: 1; level: 15; Background: 'RROCK13'; text: T5TEXT),
    (mission: pack_tnt; episode: 1; level: 31; Background: 'RROCK19'; text: T6TEXT),

    (mission: pack_plut; episode: 1; level: 6; Background: 'SLIME16'; text: P1TEXT),
    (mission: pack_plut; episode: 1; level: 11; Background: 'RROCK14'; text: P2TEXT),
    (mission: pack_plut; episode: 1; level: 20; Background: 'RROCK07'; text: P3TEXT),
    (mission: pack_plut; episode: 1; level: 30; Background: 'RROCK17'; text: P4TEXT),
    (mission: pack_plut; episode: 1; level: 15; Background: 'RROCK13'; text: P5TEXT),
    (mission: pack_plut; episode: 1; level: 31; Background: 'RROCK19'; text: P6TEXT),

    (mission: pack_nerve; episode: 1; level: 8; Background: 'SLIME16'; text: N1TEXT),
    (mission: pack_master; episode: 1; level: 20; Background: 'SLIME16'; text: M1TEXT),
    (mission: pack_master; episode: 1; level: 21; Background: 'SLIME16'; text: M2TEXT)
    );

Procedure F_StartFinale();
Procedure F_Ticker();
Function F_Responder(Const ev: Pevent_t): boolean;
Procedure F_Drawer();

Implementation

Uses
  doomstat, doomdef, sounds, info_types, info, doomtype
  , am_map
  , d_main
  , g_game
  , hu_stuff
  , i_video
  , m_controls, m_random, m_fixed
  , p_mobj, p_bexptr, p_pspr, p_enemy
  , r_defs, r_things, r_data
  , s_sound
  , w_wad
  , v_video, v_patch
  , z_zone
  ;

Const
  TEXTSPEED = 3;
  TEXTWAIT = 250;

Type

  castinfo_t = Record
    name: String;
    _type: mobjtype_t;
  End;

  finalestage_t = (F_STAGE_TEXT, F_STAGE_ARTSCREEN, F_STAGE_CAST);

Const
  castorder: Array Of castinfo_t = (
    (name: CC_ZOMBIE; _type: MT_POSSESSED),
    (name: CC_SHOTGUN; _type: MT_SHOTGUY),
    (name: CC_HEAVY; _type: MT_CHAINGUY),
    (name: CC_IMP; _type: MT_TROOP),
    (name: CC_DEMON; _type: MT_SERGEANT),
    (name: CC_LOST; _type: MT_SKULL),
    (name: CC_CACO; _type: MT_HEAD),
    (name: CC_HELL; _type: MT_KNIGHT),
    (name: CC_BARON; _type: MT_BRUISER),
    (name: CC_ARACH; _type: MT_BABY),
    (name: CC_PAIN; _type: MT_PAIN),
    (name: CC_REVEN; _type: MT_UNDEAD),
    (name: CC_MANCU; _type: MT_FATSO),
    (name: CC_ARCH; _type: MT_VILE),
    (name: CC_SPIDER; _type: MT_SPIDER),
    (name: CC_CYBER; _type: MT_CYBORG),
    (name: CC_HERO; _type: MT_PLAYER)
    );

Var
  finalestage: finalestage_t;

  finalecount: unsigned_int;
  finaletext: String;
  finaleflat: String;
  finaletext_rw: String;

  castnum: int;
  casttics: int;
  caststate: ^state_t;
  castdeath: Boolean;
  castframes: int;
  castonmelee: int;
  castattacking: Boolean;
  castangle: signed_char; // [crispy] turnable cast
  castskip: signed_char; // [crispy] skippable cast
  castflip: Boolean; // [crispy] flippable death sequence
  dxi, dy, dyi: fixed_t;

  //
  // F_StartFinale
  //

Procedure F_StartFinale();
Var
  i: size_t;
  screen: ^textscreen_t;
Begin
  gameaction := ga_nothing;
  gamestate := GS_FINALE;
  viewactive := false;
  automapactive := false;

  If (logical_gamemission = doom) Then Begin
    S_ChangeMusic(mus_victor, true);
  End
  Else Begin
    S_ChangeMusic(mus_read_m, true);
  End;

  // Find the right screen and set the text and background

  For i := 0 To length(textscreens) - 1 Do Begin

    screen := @textscreens[i];

    // Hack for Chex Quest

    If (gameversion = exe_chex) And (screen^.mission = doom) Then Begin
      screen^.level := 5;
    End;

    If (logical_gamemission = screen^.mission)
      And ((logical_gamemission <> doom) Or (gameepisode = screen^.episode))
      And (gamemap = screen^.level) Then Begin
      finaletext := screen^.text;
      finaleflat := screen^.background;
    End;
  End;

  // Do dehacked substitutions of strings

  finaletext_rw := finaletext;

  finalestage := F_STAGE_TEXT;
  finalecount := 0;
End;

Procedure F_StartCast();
Begin
  wipegamestate := GS_NEG_1; // force a screen wipe
  castnum := 0;
  caststate := @states[int(mobjinfo[int(castorder[castnum]._type)].seestate)];
  casttics := caststate^.tics;
  castdeath := false;
  finalestage := F_STAGE_CAST;
  castframes := 0;
  castonmelee := 0;
  castattacking := false;
  S_ChangeMusic(mus_evil, true);
End;

// [crispy] randomize seestate and deathstate sounds in the cast

Function F_RandomizeSound(sound: sfxenum_t): sfxenum_t;
Begin
  If (crispy.soundfix = 0) Then Begin
    result := sound;
    exit;
  End;

  Case (sound) Of
    // [crispy] actor->info->seesound, from p_enemy.c:A_Look()
    sfx_posit1,
      sfx_posit2,
      sfx_posit3:
      result := sfxenum_t(int(sfx_posit1) + Crispy_Random() Mod 3);

    sfx_bgsit1,
      sfx_bgsit2:
      result := sfxenum_t(int(sfx_bgsit1) + Crispy_Random() Mod 2);

    // [crispy] actor->info->deathsound, from p_enemy.c:A_Scream()
    sfx_podth1,
      sfx_podth2,
      sfx_podth3:
      result := sfxenum_t(int(sfx_podth1) + Crispy_Random() Mod 3);

    sfx_bgdth1,
      sfx_bgdth2:
      result := sfxenum_t(int(sfx_bgdth1) + Crispy_Random() Mod 2);
  Else
    result := sound;
  End;
End;

Type
  actionsound_t = Record
    action: actionf_p1;
    sound: sfxenum_t;
    early: Boolean;
  End;

Const
  actionsounds: Array Of actionsound_t =
  (
    (action: @A_PosAttack; sound: sfx_pistol; early: false),
    (action: @A_SPosAttack; sound: sfx_shotgn; early: false),
    (action: @A_CPosAttack; sound: sfx_shotgn; early: false),
    (action: @A_CPosRefire; sound: sfx_shotgn; early: false),
    (action: @A_VileTarget; sound: sfx_vilatk; early: true),
    (action: @A_SkelWhoosh; sound: sfx_skeswg; early: false),
    (action: @A_SkelFist; sound: sfx_skepch; early: false),
    (action: @A_SkelMissile; sound: sfx_skeatk; early: true),
    (action: @A_FatAttack1; sound: sfx_firsht; early: false),
    (action: @A_FatAttack2; sound: sfx_firsht; early: false),
    (action: @A_FatAttack3; sound: sfx_firsht; early: false),
    (action: @A_HeadAttack; sound: sfx_firsht; early: true),
    (action: @A_BruisAttack; sound: sfx_firsht; early: true),
    (action: @A_TroopAttack; sound: sfx_claw; early: false),
    (action: @A_SargAttack; sound: sfx_sgtatk; early: true),
    (action: @A_SkullAttack; sound: sfx_sklatk; early: false),
    (action: @A_PainAttack; sound: sfx_sklatk; early: true),
    (action: @A_BspiAttack; sound: sfx_plasma; early: false),
    (action: @A_CyberAttack; sound: sfx_rlaunc; early: false)
    );

  // [crispy] play attack sound based on state action function (instead of state number)

Function F_SoundForState(st: int): int;
Var
  i: int;
  ass: ^actionsound_t;
  castaction, nextaction: actionf_p1;
Begin
  castaction := caststate^.action.acp1;
  nextaction := states[int(caststate^.nextstate)].action.acp1;

  // [crispy] fix Doomguy in casting sequence
  If (caststate^.action.acv = Nil) Then Begin

    If (st = int(S_PLAY_ATK2)) Then
      result := int(sfx_dshtgn)
    Else
      result := int(sfx_None);
    exit;
  End
  Else Begin
    For i := 0 To high(actionsounds) Do Begin
      ass := @actionsounds[i];
      If ((Not ass^.early) And (castaction = ass^.action) Or
        (ass^.early) And (nextaction = ass^.action)) Then Begin
        result := int(ass^.sound);
        exit;
      End;
    End;
  End;
  result := int(sfx_None);
End;

Procedure F_CastTicker();
Label
  stopattack;
Var
  st: int;
  sfx: sfxenum_t;
Begin
  casttics := casttics - 1;
  If (casttics > 0) Then exit; // not time to change state yet

  If (caststate^.tics = -1) Or (caststate^.nextstate = S_NULL) Or (castskip <> 0) Then Begin // [crispy] skippable cast

    If (castskip <> 0) Then Begin
      castnum := castnum + castskip;
      castskip := 0;
    End
    Else
      // switch from deathstate to next monster
      castnum := castnum + 1;
    castdeath := false;
    If castnum > high(castorder) Then castnum := 0;

    If (mobjinfo[int(castorder[castnum]._type)].seesound <> sfx_None) Then
      S_StartSound(Nil, F_RandomizeSound(mobjinfo[int(castorder[castnum]._type)].seesound));
    caststate := @states[int(mobjinfo[int(castorder[castnum]._type)].seestate)];
    castframes := 0;
    castangle := 0; // [crispy] turnable cast
    castflip := false; // [crispy] flippable death sequence
  End
  Else Begin
    // just advance to next state in animation
    // [crispy] fix Doomguy in casting sequence
    (*
    if (!castdeath && caststate == &states[S_PLAY_ATK1])
        goto stopattack;	// Oh, gross hack!
    *)
    // [crispy] Allow A_RandomJump() in deaths in cast sequence
    If (caststate^.action.acp3 = @A_RandomJump) And (Crispy_Random() < caststate^.misc2) Then Begin
      st := caststate^.misc1;
    End
    Else Begin
      // [crispy] fix Doomguy in casting sequence
      If (Not castdeath) And (caststate = @states[int(S_PLAY_ATK1)]) Then
        st := int(S_PLAY_ATK2)
      Else If (Not castdeath) And (caststate = @states[int(S_PLAY_ATK2)]) Then
        Goto stopattack // Oh, gross hack!
      Else
        st := int(caststate^.nextstate);
    End;
    caststate := @states[st];
    castframes := castframes + 1;

    sfx := sfxenum_t(F_SoundForState(st));
    (*
        //	// sound hacks....
        //	switch (st)
        //	{
        //	  case S_PLAY_ATK2:	sfx = sfx_dshtgn; break; // [crispy] fix Doomguy in casting sequence
        //	  case S_POSS_ATK2:	sfx = sfx_pistol; break;
        //	  case S_SPOS_ATK2:	sfx = sfx_shotgn; break;
        //	  case S_VILE_ATK2:	sfx = sfx_vilatk; break;
        //	  case S_SKEL_FIST2:	sfx = sfx_skeswg; break;
        //	  case S_SKEL_FIST4:	sfx = sfx_skepch; break;
        //	  case S_SKEL_MISS2:	sfx = sfx_skeatk; break;
        //	  case S_FATT_ATK8:
        //	  case S_FATT_ATK5:
        //	  case S_FATT_ATK2:	sfx = sfx_firsht; break;
        //	  case S_CPOS_ATK2:
        //	  case S_CPOS_ATK3:
        //	  case S_CPOS_ATK4:	sfx = sfx_shotgn; break;
        //	  case S_TROO_ATK3:	sfx = sfx_claw; break;
        //	  case S_SARG_ATK2:	sfx = sfx_sgtatk; break;
        //	  case S_BOSS_ATK2:
        //	  case S_BOS2_ATK2:
        //	  case S_HEAD_ATK2:	sfx = sfx_firsht; break;
        //	  case S_SKULL_ATK2:	sfx = sfx_sklatk; break;
        //	  case S_SPID_ATK2:
        //	  case S_SPID_ATK3:	sfx = sfx_shotgn; break;
        //	  case S_BSPI_ATK2:	sfx = sfx_plasma; break;
        //	  case S_CYBER_ATK2:
        //	  case S_CYBER_ATK4:
        //	  case S_CYBER_ATK6:	sfx = sfx_rlaunc; break;
        //	  case S_PAIN_ATK3:	sfx = sfx_sklatk; break;
        //	  default: sfx = 0; break;
        //	}
        //
        //*)
    If (sfx <> sfx_None) Then
      S_StartSound(Nil, sfx);
  End;

  If (Not castdeath) And (castframes = 12) Then Begin

    // go into attack frame
    castattacking := true;
    If (castonmelee <> 0) Then
      caststate := @states[int(mobjinfo[int(castorder[castnum]._type)].meleestate)]
    Else
      caststate := @states[int(mobjinfo[int(castorder[castnum]._type)].missilestate)];
    castonmelee := castonmelee Xor 1;
    If (caststate = @states[int(S_NULL)]) Then Begin

      If (castonmelee <> 0) Then
        caststate :=
          @states[int(mobjinfo[int(castorder[castnum]._type)].meleestate)]
      Else
        caststate :=
          @states[int(mobjinfo[int(castorder[castnum]._type)].missilestate)];
    End;
  End;

  If (castattacking) Then Begin
    If (castframes = 24)
      Or (caststate = @states[int(mobjinfo[int(castorder[castnum]._type)].seestate)]) Then Begin
      stopattack:
      castattacking := false;
      castframes := 0;
      caststate := @states[int(mobjinfo[int(castorder[castnum]._type)].seestate)];
    End;
  End;
  casttics := caststate^.tics;
  If (casttics = -1) Then Begin
    // [crispy] Allow A_RandomJump() in deaths in cast sequence
    If (caststate^.action.acp3 = @A_RandomJump) Then Begin
      If (Crispy_Random() < caststate^.misc2) Then Begin
        caststate := @states[caststate^.misc1];
      End
      Else Begin
        caststate := @states[int(caststate^.nextstate)];
      End;
      casttics := caststate^.tics;
    End;
    If (casttics = -1) Then Begin
      casttics := 15;
    End;
  End;
End;

Procedure F_Ticker();
Var
  i, j: int;
Begin
  // check for skipping
  If ((gamemode = commercial)
    And (finalecount > 50)) Then Begin

    // go on to the next level
    j := -1;
    For i := 0 To MAXPLAYERS - 1 Do
      If (players[i].cmd.buttons <> 0) Then Begin
        j := i;
        break;
      End;

    If (j <> -1) Then Begin
      If (gamemission = pack_nerve) And (gamemap = 8) Then
        F_StartCast()
      Else If (gamemission = pack_master) And ((gamemap = 20) Or (gamemap = 21)) Then
        F_StartCast()
      Else If (gamemap = 30) Then
        F_StartCast()
      Else
        gameaction := ga_worlddone;
    End;
  End;

  // advance animation
  finalecount := finalecount + 1;

  If (finalestage = F_STAGE_CAST) Then Begin
    F_CastTicker();
    exit;
  End;

  If (gamemode = commercial) Then exit;

  If (finalestage = F_STAGE_TEXT)
    And (finalecount > length(finaletext) * TEXTSPEED + TEXTWAIT) Then Begin

    finalecount := 0;
    finalestage := F_STAGE_ARTSCREEN;
    wipegamestate := GS_NEG_1; // force a wipe
    If (gameepisode = 3) Then
      S_StartMusic(mus_bunny);
  End;
End;

Function F_CastResponder(Const ev: Pevent_t): boolean;
Var
  xdeath: boolean;
Begin
  xdeath := false;

  If (ev^._type <> ev_keydown) Then Begin
    result := false;
    exit;
  End;

  // [crispy] make monsters turnable in cast ...
  If (ev^.data1 = key_left) Then Begin
    castangle := (castangle + 1) Mod 8;
    result := false;
    exit;
  End
  Else If (ev^.data1 = key_right) Then Begin
    castangle := (castangle + 7) Mod 8;
    result := false;
    exit;
  End
  Else If (ev^.data1 = key_strafeleft) Or (ev^.data1 = key_alt_strafeleft) Then Begin
    If castnum <> 0 Then Begin
      castskip := -1;
    End
    Else Begin
      castskip := length(castorder) - 1; // Den Helden Auslassen, warum auch immer ?
    End;
    result := false;
    exit;
  End
  Else If (ev^.data1 = key_straferight) Or (ev^.data1 = key_alt_straferight) Then Begin

    castskip := 1;
    result := false;
    exit;
  End;
  // [crispy] ... and finally turn them into gibbs
  If (ev^.data1 = key_speed) Then
    xdeath := true;

  If (castdeath) Then Begin
    result := true; // already in dying frames
    exit;
  End;

  // go into death frame
  castdeath := true;
  If (xdeath) And (mobjinfo[integer(castorder[castnum]._type)].xdeathstate <> S_NULL) Then
    caststate := @states[integer(mobjinfo[integer(castorder[castnum]._type)].xdeathstate)]
  Else
    caststate := @states[integer(mobjinfo[integer(castorder[castnum]._type)].deathstate)];
  casttics := caststate^.tics;
  // [crispy] Allow A_RandomJump() in deaths in cast sequence
  If (casttics = -1) And (caststate^.action.acp3 = @A_RandomJump) Then Begin
    If (Crispy_Random() < caststate^.misc2) Then Begin
      caststate := @states[int(caststate^.misc1)];
    End
    Else Begin
      caststate := @states[int(caststate^.nextstate)];
    End;
    casttics := caststate^.tics;
  End;
  castframes := 0;
  castattacking := false;
  If (xdeath) And (mobjinfo[int(castorder[castnum]._type)].xdeathstate <> S_NULL) Then
    S_StartSound(Nil, sfx_slop)
  Else If (mobjinfo[int(castorder[castnum]._type)].deathsound <> sfx_None) Then
    S_StartSound(Nil, F_RandomizeSound(mobjinfo[int(castorder[castnum]._type)].deathsound));

  // [crispy] flippable death sequence
  castflip := (crispy.flipcorpses <> 0) And
    castdeath And
    ((mobjinfo[integer(castorder[castnum]._type)].flags And MF_FLIPPABLE) <> 0) And
  ((Crispy_Random() And 1) <> 0);

  result := true;
End;

Function F_Responder(Const ev: Pevent_t): boolean;
Begin
  If (finalestage = F_STAGE_CAST) Then Begin
    result := F_CastResponder(ev);
  End
  Else Begin
    result := false;
  End;
End;

Procedure F_CastPrint(text: String);
Var
  i, c, cx, w, width: int;
Begin
  // find width
  width := 0;

  For i := 1 To length(text) Do Begin

    c := ord(text[i]);
    If (c = 0) Then
      break;
    c := ord(UpperCase(chr(c))[1]) - ord(HU_FONTSTART);
    If (c < 0) Or (c >= HU_FONTSIZE) Then Begin
      width := width + 4;
      continue;
    End;
    w := hu_font[c]^.width;
    width := width + w;
  End;

  // draw it
  cx := ORIGWIDTH Div 2 - width Div 2;
  For i := 1 To length(text) Do Begin
    c := ord(text[i]);
    If (c = 0) Then
      break;
    c := ord(UpperCase(chr(c))[1]) - ord(HU_FONTSTART);
    If (c < 0) Or (c >= HU_FONTSIZE) Then Begin
      width := width + 4;
      continue;
    End;
    w := hu_font[c]^.width;
    V_DrawPatch(cx, 180, hu_font[c]);
    cx := cx + w;
  End;
End;

Procedure F_CastDrawer();
Var
  sprdef: ^spritedef_t;
  sprframe: ^spriteframe_t;
  lump: int;
  flip: boolean;
  patch: ^patch_t;
Begin

  // erase the entire screen to a background
  V_DrawPatchFullScreen(W_CacheLumpName('BOSSBACK', PU_CACHE), false);

  F_CastPrint(castorder[castnum].name);

  // draw the current frame in the middle of the screen
  sprdef := @sprites[int(caststate^.sprite)];
  // [crispy] the TNT1 sprite is not supposed to be rendered anyway
  If (sprdef^.numframes = 0) And (caststate^.sprite = SPR_TNT1) Then exit;

  sprframe := @sprdef^.spriteframes[caststate^.frame And FF_FRAMEMASK];
  lump := sprframe^.lump[castangle]; // [crispy] turnable cast
  flip := odd(sprframe^.flip[castangle]) Xor castflip; // [crispy] turnable cast, flippable death sequence

  patch := W_CacheLumpNum(lump + firstspritelump, PU_CACHE);
  If (flip) Then
    //    V_DrawPatchFlipped((ORIGWIDTH - patch^.width) Div 2, 170, patch)
    V_DrawPatchFlipped(ORIGWIDTH Div 2 - patch^.width, 170, patch)
  Else
    V_DrawPatch(ORIGWIDTH Div 2 - patch^.width, 170, patch);
End;

Procedure F_TextWrite();
Var
  src: ^Byte;
  dest: pixel_tArray;

  w, i: int;
  count: integer;
  //   char *ch; // [crispy] un-const
  c, cx, cy: int;

Begin
  // erase the entire screen to a tiled background
  src := W_CacheLumpName(finaleflat, PU_CACHE);
  dest := I_VideoBuffer;

  // [crispy] use unified flat filling function
  V_FillFlat(0, SCREENHEIGHT, 0, SCREENWIDTH, src, dest);

  V_MarkRect(0, 0, SCREENWIDTH, SCREENHEIGHT);

  // draw some of the text onto the screen
  cx := 10;
  cy := 10;

  count := int(finalecount - 10) Div TEXTSPEED;
  If (count < 0) Then
    count := 0;
  i := 0;
  While i < count - 1 Do Begin
    If i + 1 > length(finaletext_rw) Then break;
    C := ord(finaletext_rw[i + 1]);
    If (c = ord('\')) And (i + 2 <= length(finaletext_rw)) And
      (finaletext_rw[i + 2] = 'n') Then Begin
      cx := 10;
      cy := cy + 11;
      i := i + 2;
      continue;
    End;

    c := ord(UpperCase(chr(c))[1]) - ord(HU_FONTSTART);
    If (c < 0) Or (c >= HU_FONTSIZE) Then Begin
      cx := cx + 4;
      inc(i);
      continue;
    End;

    w := hu_font[c]^.width;
    If (cx + w > ORIGWIDTH) Then Begin

      // [crispy] add line breaks for lines exceeding screenwidth
      If {(F_AddLineBreak(ch))}  false Then Begin
        inc(i);
        continue;
      End
      Else
        break;
    End;
    // [cispy] prevent text from being drawn off-screen vertically
    If (cy + hu_font[c]^.height > ORIGHEIGHT) Then Begin
      break;
    End;
    V_DrawPatch(cx, cy, hu_font[c]);
    cx := cx + w;
    inc(i);
  End;
End;

Procedure F_DrawPatchCol(x: int; patch: Ppatch_t; col: int);
Begin
  Raise Exception.Create('Port me.');
  //    column_t*	column;
  //    byte*	source;
  //    pixel_t*	dest;
  //    pixel_t*	desttop;
  //    int		count;
  //
  //    column = (column_t *)((byte *)patch + LONG(patch->columnofs[col]));
  //    desttop = I_VideoBuffer + x;
  //
  //    // step through the posts in a column
  //    while (column->topdelta != 0xff )
  //    {
  //	int srccol = 0;
  //	source = (byte *)column + 3;
  //	dest = desttop + ((column->topdelta * dy) >> FRACBITS)*SCREENWIDTH;
  //	count = (column->length * dy) >> FRACBITS;
  //
  //	while (count--)
  //	{
  //#ifndef CRISPY_TRUECOLOR
  //	    *dest = source[srccol >> FRACBITS];
  //#else
  //	    *dest = pal_color[source[srccol >> FRACBITS]];
  //#endif
  //	    srccol += dyi;
  //	    dest += SCREENWIDTH;
  //	}
  //	column = (column_t *)(  (byte *)column + column->length + 4 );
  //    }
End;

Procedure F_BunnyScroll();
Const
  laststage: int = 0;
Var
  scrolled: signed_int;
  x, x2: int;
  p1: Ppatch_t;
  p2: Ppatch_t;
  name: String;
  stage: int;
  p2offset, p1offset, pillar_width: int;
Begin
  dxi := (ORIGWIDTH Shl FRACBITS) Div NONWIDEWIDTH;
  dy := (SCREENHEIGHT Shl FRACBITS) Div ORIGHEIGHT;
  dyi := (ORIGHEIGHT Shl FRACBITS) Div SCREENHEIGHT;

  p1 := W_CacheLumpName('PFUB2', PU_LEVEL);
  p2 := W_CacheLumpName('PFUB1', PU_LEVEL);

  // [crispy] fill pillarboxes in widescreen mode
  pillar_width := (SCREENWIDTH - (SHORT(p1^.width) Shl FRACBITS) Div dxi) Div 2;

  If (pillar_width > 0) Then Begin
    V_DrawFilledBox(0, 0, pillar_width, SCREENHEIGHT, 0);
    V_DrawFilledBox(SCREENWIDTH - pillar_width, 0, pillar_width, SCREENHEIGHT, 0);
  End
  Else Begin
    pillar_width := 0;
  End;

  // Calculate the portion of PFUB2 that would be offscreen at original res.
  p1offset := (ORIGWIDTH - SHORT(p1^.width)) Div 2;

  If ((p2^.width) = ORIGWIDTH) Then Begin
    // Unity or original PFUBs.
    // PFUB1 only contains the pixels that scroll off.
    p2offset := ORIGWIDTH - p1offset;
  End
  Else Begin
    // Widescreen mod PFUBs.
    // Right side of PFUB2 and left side of PFUB1 are identical.
    p2offset := ORIGWIDTH + p1offset;
  End;

  V_MarkRect(0, 0, SCREENWIDTH, SCREENHEIGHT);

  scrolled := (ORIGWIDTH - (finalecount - 230) Div 2);
  If (scrolled > ORIGWIDTH) Then
    scrolled := ORIGWIDTH;
  If (scrolled < 0) Then
    scrolled := 0;

  For x := pillar_width To SCREENWIDTH - pillar_width - 1 Do Begin
    x2 := ((x * dxi) Shr FRACBITS) - WIDESCREENDELTA + scrolled;
    If (x2 < p2offset) Then
      F_DrawPatchCol(x, p1, x2 - p1offset)
    Else
      F_DrawPatchCol(x, p2, x2 - p2offset);
  End;

  If (finalecount < 1130) Then exit;

  If (finalecount < 1180) Then Begin

    V_DrawPatch((ORIGWIDTH - 13 * 8) Div 2,
      (ORIGHEIGHT - 8 * 8) Div 2,
      W_CacheLumpName('END0', PU_CACHE));
    laststage := 0;
    exit;
  End;

  stage := (finalecount - 1180) Div 5;
  If (stage > 6) Then
    stage := 6;
  If (stage > laststage) Then Begin
    S_StartSound(Nil, sfx_pistol);
    laststage := stage;
  End;

  name := format('END%d', [stage]);
  V_DrawPatch((ORIGWIDTH - 13 * 8) Div 2,
    (ORIGHEIGHT - 8 * 8) Div 2,
    W_CacheLumpName(name, PU_CACHE));
End;

Procedure F_ArtScreenDrawer();
Var
  lumpname: String;
Begin
  If (gameepisode = 3) Then Begin
    F_BunnyScroll();
  End
  Else Begin
    Case (gameepisode) Of
      1: Begin
          If (gameversion >= exe_ultimate) Then Begin
            lumpname := 'CREDIT';
          End
          Else Begin
            lumpname := 'HELP2';
          End;
        End;
      2: Begin
          lumpname := 'VICTORY2';
        End;
      4: Begin
          lumpname := 'ENDPIC';
        End;
      // [crispy] Sigil
      5: Begin
          lumpname := 'SIGILEND';
          If (W_CheckNumForName(lumpname) = -1) Then exit;
        End;
      // [crispy] Sigil II
      6: Begin
          lumpname := 'SGL2END';
          If (W_CheckNumForName(lumpname) = -1) Then Begin
            lumpname := 'SIGILEND';
            If (W_CheckNumForName(lumpname) = -1) Then exit;
          End;
        End;
    Else Begin
        exit;
      End;
    End;
  End;

  V_DrawPatchFullScreen(W_CacheLumpName(lumpname, PU_CACHE), false);
End;

Procedure F_Drawer();
Begin
  Case (finalestage) Of
    F_STAGE_CAST: F_CastDrawer();
    F_STAGE_TEXT: F_TextWrite();
    F_STAGE_ARTSCREEN: F_ArtScreenDrawer();
  End;
End;

End.

