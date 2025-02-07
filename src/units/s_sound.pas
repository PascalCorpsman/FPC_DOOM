Unit s_sound;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , sounds, info_types
  ;

Procedure S_StartSound(origin_p: Pointer; sfx_id: sfxenum_t);
Procedure S_StartSoundOptional(origin_p: Pointer; sfx_id: sfxenum_t; old_sfx_id: sfxenum_t);
Procedure S_StartMusic(m_id: musicenum_t);

Procedure S_ResumeSound();
Procedure S_PauseSound();

Procedure S_Start();
Procedure S_StartSoundOnce(origin_p: Pointer; sfx_id: sfxenum_t);

Procedure S_UnlinkSound(origin: Pmobj_t);
Procedure S_StopSound(origin: Pmobj_t);

Procedure S_Shutdown();

Implementation

Uses
  doomdef
  , d_loop
  , g_game
  , i_sound
  ;

Var
  snd_SfxVolume: integer = 10000; // Full Sound
  mus_paused: Boolean = false;
  mus_playing: Boolean = false;

Procedure S_StartSound(origin_p: Pointer; sfx_id: sfxenum_t);
Var
  sfx: ^sfxinfo_t;
  origin: Pmobj_t;
  //  int rc;
  //  int sep;
  //  int pitch;
  //  int cnum;
  //  int volume;

Begin
  origin := origin_p;
  //  volume = snd_SfxVolume;
  //
    // [crispy] make non-fatal, consider zero volume
  If (sfx_id = sfx_None) Or (snd_SfxVolume = 0) Or (nodrawers And singletics) Then Begin
    exit;
  End;
  //  // check for bogus sound #
  //  if (sfx_id < 1 || sfx_id > NUMSFX)
  //  {
  //      I_Error("Bad sfx #: %d", sfx_id);
  //  }

  sfx := @S_sfx[integer(sfx_id)];

  //  // Initialize sound parameters
  //  pitch = NORM_PITCH;
  //  if (sfx->link)
  //  {
  //      volume += sfx->volume;
  //      pitch = sfx->pitch;
  //
  //      if (volume < 1)
  //      {
  //          return;
  //      }
  //
  //      if (volume > snd_SfxVolume)
  //      {
  //          volume = snd_SfxVolume;
  //      }
  //  }
  //
  //
  //  // Check to see if it is audible,
  //  //  and if not, modify the params
  //  if (origin && origin != players[displayplayer].mo && origin != players[displayplayer].so) // [crispy] weapon sound source
  //  {
  //      rc = S_AdjustSoundParams(players[displayplayer].mo,
  //                               origin,
  //                               &volume,
  //                               &sep);
  //
  //      if (origin->x == players[displayplayer].mo->x
  //       && origin->y == players[displayplayer].mo->y)
  //      {
  //          sep = NORM_SEP;
  //      }
  //
  //      if (!rc)
  //      {
  //          return;
  //      }
  //  }
  //  else
  //  {
  //      sep = NORM_SEP;
  //  }
  //
  //  // hacks to vary the sfx pitches
  //  if (sfx_id >= sfx_sawup && sfx_id <= sfx_sawhit)
  //  {
  //      pitch += 8 - (M_Random()&15);
  //  }
  //  else if (sfx_id != sfx_itemup && sfx_id != sfx_tink)
  //  {
  //      pitch += 16 - (M_Random()&31);
  //  }
  //  pitch = Clamp(pitch);

  // kill old sound
  If (crispy.soundfull = 0) Or assigned(origin) Or (gamestate <> GS_LEVEL) Then Begin
    S_StopSound(origin);
  End;

  //  // try to find a channel
  //  cnum = S_GetChannel(origin, sfx);
  //
  //  if (cnum < 0)
  //  {
  //      return;
  //  }
  //
  //  // increase the usefulness
  //  if (sfx->usefulness++ < 0)
  //  {
  //      sfx->usefulness = 1;
  //  }

  If (sfx^.lumpnum < 0) Then Begin
    sfx^.lumpnum := I_GetSfxLumpNum(sfx);
  End;

  //  channels[cnum].pitch = pitch;
  //  channels[cnum].handle =
  I_StartSound(sfx, 0, 100, 0, NORM_PITCH);
End;

Procedure S_StartSoundOptional(origin_p: Pointer; sfx_id: sfxenum_t; old_sfx_id: sfxenum_t);
Begin
  // Umleiten nach Bass ?
  If (I_GetSfxLumpNum(@S_sfx[integer(sfx_id)]) <> -1) Then Begin
    S_StartSound(origin_p, sfx_id);
  End
  Else If (old_sfx_id <> sfx_None) Then Begin // Play a fallback?
    S_StartSound(origin_p, old_sfx_id);
  End;
End;

Procedure S_StartMusic(m_id: musicenum_t);
Begin
  //    S_ChangeMusic(m_id, false);
  nop();
End;

Procedure S_ResumeSound();
Begin
  If (mus_playing) And (mus_paused) Then Begin

    //    I_ResumeSong();
    mus_paused := false;
  End;
End;

Procedure S_PauseSound();
Begin
  If (mus_playing) And (Not mus_paused) Then Begin

    //    I_PauseSong();
    mus_paused := true;
  End;
End;


//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//

Procedure S_Start();
Begin
  nop();

End;

Procedure S_StartSoundOnce(origin_p: Pointer; sfx_id: sfxenum_t);
Begin
  nop();

  //    int cnum;
  //    const sfxinfo_t *const sfx = &S_sfx[sfx_id];
  //
  //    for (cnum = 0; cnum < snd_channels; cnum++)
  //    {
  //        if (channels[cnum].sfxinfo == sfx &&
  //            channels[cnum].origin == origin_p)
  //        {
  //            return;
  //        }
  //    }
  //
  //    S_StartSound(origin_p, sfx_id);
End;

// [crispy] removed map objects may finish their sounds
// When map objects are removed from the map by P_RemoveMobj(), instead of
// stopping their sounds, their coordinates are transfered to "sound objects"
// so stereo positioning and distance calculations continue to work even after
// the corresponding map object has already disappeared.
// Thanks to jeff-d and kb1 for discussing this feature and the former for the
// original implementation idea: https://www.doomworld.com/vb/post/1585325

Procedure S_UnlinkSound(origin: Pmobj_t);
Begin
  nop();

  //  int cnum;
  //
  //    if (origin)
  //    {
  //        for (cnum=0 ; cnum<snd_channels ; cnum++)
  //        {
  //            if (channels[cnum].sfxinfo && channels[cnum].origin == origin)
  //            {
  //                degenmobj_t *const sobj = &sobjs[cnum];
  //                sobj->x = origin->x;
  //                sobj->y = origin->y;
  //                sobj->z = origin->z;
  //                channels[cnum].origin = (mobj_t *) sobj;
  //                break;
  //            }
  //        }
  //    }
End;

Procedure S_StopSound(origin: Pmobj_t);
Begin
  nop();

  //      int cnum;
  //
  //    for (cnum=0 ; cnum<snd_channels ; cnum++)
  //    {
  //        if (channels[cnum].sfxinfo && channels[cnum].origin == origin)
  //        {
  //            S_StopChannel(cnum);
  //            break;
  //        }
  //    }
End;

Procedure S_Shutdown();
Begin
  I_ShutdownSound();
  //I_ShutdownMusic();
End;

End.

