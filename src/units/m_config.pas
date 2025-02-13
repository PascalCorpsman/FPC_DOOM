Unit m_config;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure M_SetConfigDir(Const dir: String);
Procedure M_MakeDirectory(Const dir: String);
Procedure M_LoadDefaults();
Procedure M_SetConfigFilenames(Const main_config: String; Const extra_config: String);

Function M_GetSaveGameDir(iwadname: String): String;

Implementation

Uses m_argv;

Var
  configdir: String = '';

  // Default filenames for configuration files.

  default_main_config: String;
  default_extra_config: String;

  //
  // SetConfigDir:
  //
  // Sets the location of the configuration directory, where configuration
  // files are stored - default.cfg, chocolate-doom.cfg, savegames, etc.
  //

Procedure M_SetConfigDir(Const dir: String);
Begin
  // Use the directory that was passed, or find the default.

  If (dir <> '') Then Begin
    configdir := dir;
  End
  Else Begin
    configdir := GetAppConfigDir(false);
  End;

  If (configdir <> exedir) Then Begin
    writeln(format('Using %s for configuration and saves', [configdir]));
  End;

  // Make the directory if it doesn't already exist:

  M_MakeDirectory(configdir);
End;

Procedure M_MakeDirectory(Const dir: String);
Begin
  ForceDirectories(dir);
End;

Procedure M_LoadDefaults();
Var
  i: int;
Begin

  //
  //    // This variable is a special snowflake for no good reason.
  //    M_BindStringVariable("autoload_path", &autoload_path);
  //
      // check for a custom default file

      //!
      // @arg <file>
      // @vanilla
      //
      // Load main configuration from the specified file, instead of the
      // default.
      //

  i := M_CheckParmWithArgs('-config', 1);

  If (i <> 0) Then Begin
    //	doom_defaults.filename = myargv[i+1];
    //	printf ("	default file: %s\n",doom_defaults.filename);
  End
  Else Begin
    //        doom_defaults.filename
    //            = M_StringJoin(configdir, default_main_config, NULL);
  End;

  //    printf("saving config in %s\n", doom_defaults.filename);

      //!
      // @arg <file>
      //
      // Load additional configuration from the specified file, instead of
      // the default.
      //

  i := M_CheckParmWithArgs('-extraconfig', 1);

  If (i <> 0) Then Begin
    //        extra_defaults.filename = myargv[i+1];
    //        printf("        extra configuration file: %s\n",
    //               extra_defaults.filename);
  End
  Else Begin
    //        extra_defaults.filename
    //            = M_StringJoin(configdir, default_extra_config, NULL);
  End;

  //    LoadDefaultCollection(&doom_defaults);
  //    LoadDefaultCollection(&extra_defaults);
End;


// Set the default filenames to use for configuration files.

Procedure M_SetConfigFilenames(Const main_config: String;
  Const extra_config: String);
Begin
  default_main_config := main_config;
  default_extra_config := extra_config;
End;

Function M_GetSaveGameDir(iwadname: String): String;
Var
  p: int;
  savegamedir, topdir: String;
Begin

  //!
  // @arg <directory>
  //
  // Specify a path from which to load and save games. If the directory
  // does not exist then it will automatically be created.
  //

  p := M_CheckParmWithArgs('-savedir', 1);
  If (p <> 0) Then Begin
    savegamedir := myargv[p + 1];
    If (Not DirectoryExists(savegamedir)) Then Begin
      ForceDirectories(savegamedir);
    End;

    // add separator at end just in case
    savegamedir := IncludeTrailingPathDelimiter(savegamedir);

    writeln(format('Save directory changed to %s.', [savegamedir]));
  End
    //#ifdef _WIN32
    //    // In -cdrom mode, we write savegames to a specific directory
    //    // in addition to configs.
    //
    //    else if (M_ParmExists("-cdrom"))
    //    {
    //        savegamedir = M_StringDuplicate(configdir);
    //    }
    //#endif
    //    // If not "doing" a configuration directory (Windows), don't "do"
    //    // a savegame directory, either.
    //    else if (!strcmp(configdir, exedir))
    //    {
    //	savegamedir = M_StringDuplicate("");
    //    }
  Else Begin
    // ~/.local/share/chocolate-doom/savegames
    topdir := IncludeTrailingPathDelimiter(GetAppConfigDir(false)) + 'savegames';
    ForceDirectories(topdir);

    // eg. ~/.local/share/chocolate-doom/savegames/doom2.wad/

    savegamedir := IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(topdir) + iwadname);
    ForceDirectories(savegamedir);
  End;
  result := savegamedir;
End;

End.

