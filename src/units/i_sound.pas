Unit i_sound;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , sounds
  , d_mode
  ;




Procedure I_InitSound(mission: GameMission_t);
//Procedure I_ShutdownSound();
Function I_GetSfxLumpNum(sfxinfo: Psfxinfo_t): int;
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

Uses
  i_sdlsound
  ;

// Find and initialize a sound_module_t appropriate for the setting
// in snd_sfxdevice.

Procedure InitSfxModule(mission: GameMission_t);
Begin
  I_SDL_InitSound(mission); // TODO: das hier ist alles noch hacky ..
  //    int i;
  //
  //    sound_module = NULL;
  //
  //    for (i=0; sound_modules[i] != NULL; ++i)
  //    {
  //        // Is the sfx device in the list of devices supported by
  //        // this module?
  //
  //        if (SndDeviceInList(snd_sfxdevice,
  //                            sound_modules[i]->sound_devices,
  //                            sound_modules[i]->num_sound_devices))
  //        {
  //            // Initialize the module
  //
  //            if (sound_modules[i]->Init(mission))
  //            {
  //                sound_module = sound_modules[i];
  //                return;
  //            }
  //        }
  //    }
End;

Procedure I_InitSound(mission: GameMission_t);
Begin
  //   boolean nosound, nosfx, nomusic, nomusicpacks;
  //
  //    //!
  //    // @vanilla
  //    //
  //    // Disable all sound output.
  //    //
  //
  //    nosound = M_CheckParm("-nosound") > 0;
  //
  //    //!
  //    // @vanilla
  //    //
  //    // Disable sound effects.
  //    //
  //
  //    nosfx = M_CheckParm("-nosfx") > 0;
  //
  //    //!
  //    // @vanilla
  //    //
  //    // Disable music.
  //    //
  //
  //    nomusic = M_CheckParm("-nomusic") > 0;
  //
  //    //!
  //    //
  //    // Disable substitution music packs.
  //    //
  //
  //    nomusicpacks = M_ParmExists("-nomusicpacks");
  //
  //    // Auto configure the music pack directory.
  //    M_SetMusicPackDir();
  //
  //    // Initialize the sound and music subsystems.
  //
  //    if (!nosound && !screensaver_mode)
  //    {
  //        // This is kind of a hack. If native MIDI is enabled, set up
  //        // the TIMIDITY_CFG environment variable here before SDL_mixer
  //        // is opened.
  //
  //        if (!nomusic
  //         && (snd_musicdevice == SNDDEVICE_GENMIDI
  //          || snd_musicdevice == SNDDEVICE_GUS))
  //        {
  //            I_InitTimidityConfig();
  //        }
  //
  //        if (!nosfx)
  //        {
  InitSfxModule(mission);
  //        }
  //
  //        if (!nomusic)
  //        {
  //            InitMusicModule();
  //            active_music_module = music_module;
  //        }
  //
  //        // We may also have substitute MIDIs we can load.
  //        if (!nomusicpacks && music_module != NULL)
  //        {
  //            music_packs_active = music_pack_module.Init();
  //        }
  //    }
  //    // [crispy] print the SDL audio backend
  //    {
  //	const char *driver_name = SDL_GetCurrentAudioDriver();
  //
  //	fprintf(stderr, "I_InitSound: SDL audio driver is %s\n", driver_name ? driver_name : "none");
  //    }
End;

Function I_GetSfxLumpNum(sfxinfo: Psfxinfo_t): int;
Begin
  //     if (sound_module != NULL)
  //    {
  result := {sound_module->} I_SDL_GetSfxLumpNum(sfxinfo);
  //    }
  //    else
  //    {
  //        return 0;
  //    }
End;

Procedure I_InitMusic();
Begin

End;

End.

