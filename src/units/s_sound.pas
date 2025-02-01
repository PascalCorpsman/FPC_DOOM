Unit s_sound;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , sounds, info_types
  ;

Procedure S_StartSound(origin: Pointer; sound_id: sfxenum_t);
Procedure S_StartSoundOptional(origin: Pointer; sound_id, old_sound_id: sfxenum_t);
Procedure S_StartMusic(m_id: musicenum_t);

Procedure S_ResumeSound();
Procedure S_PauseSound();

Procedure S_Start();
Procedure S_StartSoundOnce(origin_p: Pointer; sfx_id: sfxenum_t);

Procedure S_UnlinkSound(origin: Pmobj_t);
Procedure S_StopSound(origin: Pmobj_t);

Implementation

Var
  mus_paused: Boolean = false;
  mus_playing: Boolean = false;

Procedure S_StartSound(origin: Pointer; sound_id: sfxenum_t);
Begin

End;

Procedure S_StartSoundOptional(origin: Pointer; sound_id, old_sound_id: sfxenum_t);
Begin
  // Umleiten nach Bass ?
End;

Procedure S_StartMusic(m_id: musicenum_t);
Begin
  //    S_ChangeMusic(m_id, false);
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

End;

Procedure S_StartSoundOnce(origin_p: Pointer; sfx_id: sfxenum_t);
Begin
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

End.

