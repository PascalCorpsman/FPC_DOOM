Unit i_sound;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, d_mode;


Procedure I_InitSound(mission: GameMission_t);
//Procedure I_ShutdownSound();
//Function I_GetSfxLumpNum(Var sfxinfo: sfxinfo_t): int;
//Procedure I_UpdateSound();
//Procedure I_UpdateSoundParams(channel: int; vol: int; sep: int);
//Function I_StartSound(Var sfxinfo: sfxinfo_t; channel: int; vol: int; sep: int; pitch: int): int;
//Procedure I_StopSound(channel: int);
//Function I_SoundIsPlaying(channel: int): boolean;
//Procedure I_PrecacheSounds(Var sounds: sfxinfo_t; num_sounds: int);


Procedure I_InitMusic();
//Procedure I_ShutdownMusic();
//Procedure I_SetMusicVolume(int volume);
//Procedure I_PauseSong();
//Procedure I_ResumeSong();
//Function I_RegisterSong(data: Pointer, len: int): Pointer;
//Procedure I_UnRegisterSong(handle: pointer);
//Procedure I_PlaySong(handle: Pointer; looping: boolean);
//Procedure I_StopSong();
//Function I_MusicIsPlaying(): boolean;

//Function IsMid(Const mem: Array Of byte; len: int): boolean;
//Function IsMus(Const mem: Array Of byte; len: int): boolean;

Implementation

Procedure I_InitSound(mission: GameMission_t);
Begin

End;

Procedure I_InitMusic();
Begin

End;

End.

