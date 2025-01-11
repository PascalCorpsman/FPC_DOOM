Unit s_sound;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, sounds;

Procedure S_StartSoundOptional(origin: Pointer; sound_id, old_sound_id: sfxenum_t);

Implementation

Procedure S_StartSoundOptional(origin: Pointer; sound_id, old_sound_id: sfxenum_t);
Begin
  // Umleiten nach Bass ?
End;

End.

