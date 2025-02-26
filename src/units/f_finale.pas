Unit f_finale;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_event
  ;

Procedure F_StartFinale();
Procedure F_Ticker();
Function F_Responder(Const ev: Pevent_t): boolean;
Procedure F_Drawer();

Implementation

Uses
  doomstat, doomdef, sounds, info_types, info
  , am_map
  , d_mode, d_englsh
  , g_game
  , m_controls, m_random
  , p_mobj, p_bexptr
  , s_sound
  ;

Const
  TEXTSPEED = 3;
  TEXTWAIT = 250;

Type
  textscreen_t = Record
    mission: GameMission_t;
    episode, level: int;
    background: String;
    text: String;
  End;

  castinfo_t = Record
    name: String;
    _type: mobjtype_t;
  End;


  finalestage_t = (F_STAGE_TEXT, F_STAGE_ARTSCREEN, F_STAGE_CAST);

Const
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

Procedure F_Ticker();
Begin
  Raise exception.create('Port me.');
  //   size_t		i;
  //
  //   // check for skipping
  //   if ( (gamemode == commercial)
  //     && ( finalecount > 50) )
  //   {
  //     // go on to the next level
  //     for (i=0 ; i<MAXPLAYERS ; i++)
  //if (players[i].cmd.buttons)
  //  break;
  //
  //     if (i < MAXPLAYERS)
  //     {
  //if (gamemission == pack_nerve && gamemap == 8)
  //  F_StartCast ();
  //else
  //if (gamemission == pack_master && (gamemap == 20 || gamemap == 21))
  //  F_StartCast ();
  //else
  //if (gamemap == 30)
  //  F_StartCast ();
  //else
  //  gameaction = ga_worlddone;
  //     }
  //   }
  //
  //   // advance animation
  //   finalecount++;
  //
  //   if (finalestage == F_STAGE_CAST)
  //   {
  //F_CastTicker ();
  //return;
  //   }
  //
  //   if ( gamemode == commercial)
  //return;
  //
  //   if (finalestage == F_STAGE_TEXT
  //    && finalecount>strlen (finaletext)*TEXTSPEED + TEXTWAIT)
  //   {
  //finalecount = 0;
  //finalestage = F_STAGE_ARTSCREEN;
  //wipegamestate = -1;		// force a wipe
  //if (gameepisode == 3)
  //    S_StartMusic (mus_bunny);
  //   }
End;

// [crispy] randomize seestate and deathstate sounds in the cast

Function F_RandomizeSound(sound: sfxenum_t): sfxenum_t;
Begin
  Raise exception.create('Port me.');
  //if (!crispy->soundfix)
  //	return sound;
  //
  //switch (sound)
  //{
  //	// [crispy] actor->info->seesound, from p_enemy.c:A_Look()
  //	case sfx_posit1:
  //	case sfx_posit2:
  //	case sfx_posit3:
  //		return sfx_posit1 + Crispy_Random()%3;
  //		break;
  //
  //	case sfx_bgsit1:
  //	case sfx_bgsit2:
  //		return sfx_bgsit1 + Crispy_Random()%2;
  //		break;
  //
  //	// [crispy] actor->info->deathsound, from p_enemy.c:A_Scream()
  //	case sfx_podth1:
  //	case sfx_podth2:
  //	case sfx_podth3:
  //		return sfx_podth1 + Crispy_Random()%3;
  //		break;
  //
  //	case sfx_bgdth1:
  //	case sfx_bgdth2:
  //		return sfx_bgdth1 + Crispy_Random()%2;
  //		break;
  //
  //	default:
  //		return sound;
  //		break;
 //	}
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

Procedure F_CastDrawer();
Begin
  Raise exception.create('Port me.');
  //   spritedef_t*	sprdef;
  //   spriteframe_t*	sprframe;
  //   int			lump;
  //   boolean		flip;
  //   patch_t*		patch;
  //
  //   // erase the entire screen to a background
  //   V_DrawPatchFullScreen (W_CacheLumpName (DEH_String("BOSSBACK"), PU_CACHE), false);
  //
  //   F_CastPrint (DEH_String(castorder[castnum].name));
  //
  //   // draw the current frame in the middle of the screen
  //   sprdef = &sprites[caststate->sprite];
  //   // [crispy] the TNT1 sprite is not supposed to be rendered anyway
  //   if (!sprdef->numframes && caststate->sprite == SPR_TNT1)
  //   {
  //return;
  //   }
  //   sprframe = &sprdef->spriteframes[ caststate->frame & FF_FRAMEMASK];
  //   lump = sprframe->lump[castangle]; // [crispy] turnable cast
  //   flip = (boolean)sprframe->flip[castangle] ^ castflip; // [crispy] turnable cast, flippable death sequence
  //
  //   patch = W_CacheLumpNum (lump+firstspritelump, PU_CACHE);
  //   if (flip)
  //V_DrawPatchFlipped(ORIGWIDTH/2, 170, patch);
  //   else
  //V_DrawPatch(ORIGWIDTH/2, 170, patch);
End;


Procedure F_TextWrite();
Begin
  Raise exception.create('Port me.');
  //   byte*	src;
  //   pixel_t*	dest;
  //
  //   int		w;
  //   signed int	count;
  //   char *ch; // [crispy] un-const
  //   int		c;
  //   int		cx;
  //   int		cy;
  //
  //   // erase the entire screen to a tiled background
  //   src = W_CacheLumpName ( finaleflat , PU_CACHE);
  //   dest = I_VideoBuffer;
  //
  //   // [crispy] use unified flat filling function
  //   V_FillFlat(0, SCREENHEIGHT, 0, SCREENWIDTH, src, dest);
  //
  //   V_MarkRect (0, 0, SCREENWIDTH, SCREENHEIGHT);
  //
  //   // draw some of the text onto the screen
  //   cx = 10;
  //   cy = 10;
  //   ch = finaletext_rw;
  //
  //   count = ((signed int) finalecount - 10) / TEXTSPEED;
  //   if (count < 0)
  //count = 0;
  //   for ( ; count ; count-- )
  //   {
  //c = *ch++;
  //if (!c)
  //    break;
  //if (c == '\n')
  //{
  //    cx = 10;
  //    cy += 11;
  //    continue;
  //}
  //
  //c = toupper(c) - HU_FONTSTART;
  //if (c < 0 || c >= HU_FONTSIZE)
  //{
  //    cx += 4;
  //    continue;
  //}
  //
  //w = SHORT (hu_font[c]->width);
  //if (cx+w > ORIGWIDTH)
  //{
  //    // [crispy] add line breaks for lines exceeding screenwidth
  //    if (F_AddLineBreak(ch))
  //    {
  //	continue;
  //    }
  //    else
  //    break;
  //}
  //// [cispy] prevent text from being drawn off-screen vertically
  //if (cy + SHORT(hu_font[c]->height) > ORIGHEIGHT)
  //{
  //    break;
  //}
  //V_DrawPatch(cx, cy, hu_font[c]);
  //cx+=w;
  //   }

End;

Procedure F_ArtScreenDrawer();
Begin
  Raise exception.create('Port me.');
  //const char *lumpname;
  //
  //if (gameepisode == 3)
  //{
  //    F_BunnyScroll();
  //}
  //else
  //{
  //    switch (gameepisode)
  //    {
  //        case 1:
  //            if (gameversion >= exe_ultimate)
  //            {
  //                lumpname = "CREDIT";
  //            }
  //            else
  //            {
  //                lumpname = "HELP2";
  //            }
  //            break;
  //        case 2:
  //            lumpname = "VICTORY2";
  //            break;
  //        case 4:
  //            lumpname = "ENDPIC";
  //            break;
  //        // [crispy] Sigil
  //        case 5:
  //            lumpname = "SIGILEND";
  //            if (W_CheckNumForName(DEH_String(lumpname)) == -1)
  //            {
  //                return;
  //            }
  //            break;
  //        // [crispy] Sigil II
  //        case 6:
  //            lumpname = "SGL2END";
  //            if (W_CheckNumForName(DEH_String(lumpname)) == -1)
  //            {
  //                lumpname = "SIGILEND";
  //
  //                if (W_CheckNumForName(DEH_String(lumpname)) == -1)
  //                {
  //                    return;
  //                }
  //            }
  //            break;
  //        default:
  //            return;
  //    }
  //
  //    lumpname = DEH_String(lumpname);
  //
  //    V_DrawPatchFullScreen (W_CacheLumpName(lumpname, PU_CACHE), false);
  //}
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

