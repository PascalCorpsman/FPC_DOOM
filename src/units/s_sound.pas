Unit s_sound;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, sounds;

Procedure S_StartSoundOptional(origin: Pointer; sound_id, old_sound_id: sfxenum_t);
Procedure S_StartMusic(m_id: musicenum_t);

Implementation

Procedure S_StartSoundOptional(origin: Pointer; sound_id, old_sound_id: sfxenum_t);
Begin
  // Umleiten nach Bass ?
End;

Procedure S_StartMusic(m_id: musicenum_t);
Begin
  //    S_ChangeMusic(m_id, false);
End;

End.

