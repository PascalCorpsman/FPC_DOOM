Unit s_sound;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, sounds;

Procedure S_StartSound(origin: Pointer; sound_id: sfxenum_t);
Procedure S_StartSoundOptional(origin: Pointer; sound_id, old_sound_id: sfxenum_t);
Procedure S_StartMusic(m_id: musicenum_t);

Procedure S_ResumeSound();
Procedure S_PauseSound();

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

    //        I_ResumeSong();
    mus_paused := false;
  End;
End;

Procedure S_PauseSound();
Begin
  If (mus_playing) And (Not mus_paused) Then Begin

    //        I_PauseSong();
    mus_paused := true;
  End;
End;

End.

