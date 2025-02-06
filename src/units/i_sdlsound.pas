Unit i_sdlsound;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , sounds
  , d_mode
  ;

Function I_SDL_GetSfxLumpNum(sfx: Psfxinfo_t): int;
Function I_SDL_InitSound(mission: GameMission_t): boolean;

Implementation

Uses
  bass
  , w_wad
  ;

Var
  use_sfx_prefix: Boolean;

Procedure GetSfxLumpName(sfx: Psfxinfo_t; Var buf: String);
Begin
  // Linked sfx lumps? Get the lump number for the sound linked to.
  If (sfx^.link <> Nil) Then Begin
    sfx := sfx^.link;
  End;

  // Doom adds a DS* prefix to sound lumps; Heretic and Hexen don't
  // do this.
  If (use_sfx_prefix) Then Begin
    buf := 'ds' + sfx^.name;
    //    M_snprintf(buf, buf_len, "ds%s", DEH_String(sfx - > name));
  End
  Else Begin
    //    M_StringCopy(buf, DEH_String(sfx - > name), buf_len);
    buf := sfx^.name;
  End;
End;

Function I_SDL_GetSfxLumpNum(sfx: Psfxinfo_t): int;
Var
  namebuf: String;
Begin
  GetSfxLumpName(sfx, namebuf);
  result := W_CheckNumForName(namebuf);
End;

Function I_SDL_InitSound(mission: GameMission_t): boolean;
Begin
  use_sfx_prefix := (mission = doom) Or (mission = strife);
  //   // No sounds yet
  //    for (i=0; i<NUM_CHANNELS; ++i)
  //    {
  //        channels_playing[i] = NULL;
  //    }

  If (BASS_GetVersion() Shr 16) <> Bassversion Then Begin
    writeln(stderr, 'Unable to set up sound.');
    result := false;
  End;
  If (Not Bass_init(-1, 44100, 0, {$IFDEF Windows}0{$ELSE}Nil{$ENDIF}, Nil)) Then Begin
    writeln(stderr, format('Error initialising SDL_mixer: %d', [BASS_ErrorGetCode()]));
    result := false;
  End;

  Bass ist initialisiert, es fehlt nun der "Manager" zum Abspielen

  //    ExpandSoundData = ExpandSoundData_SDL;
  //
  //    Mix_QuerySpec(&mixer_freq, &mixer_format, &mixer_channels);
  //
  //#ifdef HAVE_LIBSAMPLERATE
  //    if (use_libsamplerate != 0)
  //    {
  //        if (SRC_ConversionMode() < 0)
  //        {
  //            I_Error("I_SDL_InitSound: Invalid value for use_libsamplerate: %i",
  //                    use_libsamplerate);
  //        }
  //
  //        ExpandSoundData = ExpandSoundData_SRC;
  //    }
  //#else
  //    if (use_libsamplerate != 0)
  //    {
  //        fprintf(stderr, "I_SDL_InitSound: use_libsamplerate=%i, but "
  //                        "libsamplerate support not compiled in.\n",
  //                        use_libsamplerate);
  //    }
  //#endif
  //
  //    Mix_AllocateChannels(NUM_CHANNELS);
  //
  //    SDL_PauseAudio(0);
  //
  //    sound_initialized = true;

  result := true;
End;

End.

