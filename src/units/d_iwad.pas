Unit d_iwad;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_mode
  ;

Const
  IWAD_MASK_DOOM =
    ((1 Shl integer(doom))
    Or (1 Shl integer(doom2))
    Or (1 Shl integer(pack_tnt))
    Or (1 Shl integer(pack_plut))
    Or (1 Shl integer(pack_chex))
    Or (1 Shl integer(pack_hacx)));

  IWAD_MASK_HERETIC = (1 Shl integer(heretic));
  IWAD_MASK_HEXEN = (1 Shl integer(hexen));
  IWAD_MASK_STRIFE = (1 Shl integer(strife));

Type
  iwad_t = Record
    name: String;
    mission: GameMission_t;
    mode: GameMode_t;
    description: String;
  End;

Const
  iwads: Array Of iwad_t =
  (
    (name: 'doom2.wad'; mission: doom2; Mode: commercial; description: 'Doom II'),
    (name: 'plutonia.wad'; mission: pack_plut; mode: commercial; description: 'Final Doom: Plutonia Experiment'),
    (name: 'tnt.wad'; mission: pack_tnt; mode: commercial; description: 'Final Doom: TNT: Evilution'),
    (name: 'doom.wad'; mission: doom; mode: retail; description: 'Doom'),
    (name: 'doom1.wad'; mission: doom; mode: shareware; description: 'Doom Shareware'),
    (name: 'doom2f.wad'; mission: doom2; mode: commercial; description: 'Doom II: L''Enfer sur Terre'),
    (name: 'chex.wad'; mission: pack_chex; mode: retail; description: 'Chex Quest'),
    (name: 'hacx.wad'; mission: pack_hacx; mode: commercial; description: 'Hacx'),
    (name: 'freedoom2.wad'; mission: doom2; mode: commercial; description: 'Freedoom: Phase 2'),
    (name: 'freedoom1.wad'; mission: doom; mode: retail; description: 'Freedoom: Phase 1'),
    (name: 'freedm.wad'; mission: doom2; mode: commercial; description: 'FreeDM'),
    (name: 'rekkrsa.wad'; mission: doom; mode: retail; description: 'REKKR'), // [crispy] REKKR
    (name: 'rekkrsl.wad'; mission: doom; mode: retail; description: 'REKKR: Sunken Land'), // [crispy] REKKR: Sunken Land (Steam retail)
    (name: 'heretic.wad'; mission: heretic; mode: retail; description: 'Heretic'),
    (name: 'heretic1.wad'; mission: heretic; mode: shareware; description: 'Heretic Shareware'),
    (name: 'hexen.wad'; mission: hexen; mode: commercial; description: 'Hexen'),
    // (name: 'strife0.wad'; mission: strife; mode: commercial; description: 'Strife'), // haleyjd: STRIFE-FIXME
    (name: 'strife1.wad'; mission: strife; mode: commercial; description: 'Strife')
    );

Function D_FindIWAD(mask: int; Var mission: GameMission_t): String;
Function D_SaveGameIWADName(gamemission: GameMission_t; gamevariant: GameVariant_t): String;

Implementation

Uses m_argv, m_misc;

Const
  MAX_IWAD_DIRS = 128;

Var
  iwad_dirs_built: Boolean = false;
  iwad_dirs: Array[0..MAX_IWAD_DIRS - 1] Of String;
  num_iwad_dirs: int = 0;

Procedure AddIWADDir(dir: String);
Begin
  If (num_iwad_dirs < MAX_IWAD_DIRS) Then Begin
    iwad_dirs[num_iwad_dirs] := dir;
    num_iwad_dirs := num_iwad_dirs + 1;
  End;
End;

Procedure BuildIWADDirList();
Begin
  //    char *env;

  If (iwad_dirs_built) Then exit;

  // Look in the current directory.  Doom always does this.
  AddIWADDir('.');

  // Next check the directory where the executable is located. This might
  // be different from the current directory.
  AddIWADDir(ExtractFileDir(ParamStr(0)));

  // Add DOOMWADDIR if it is in the environment
  //    env = M_getenv('DOOMWADDIR');
  //    if (env != NULL)
  //    {
  //        AddIWADDir(env);
  //    }

  // Add dirs from DOOMWADPATH:
  //    env = M_getenv('DOOMWADPATH');
  //    if (env != NULL)
  //    {
  //        AddIWADPath(env, '');
  //    }


{$IFDEF Windows}

  // Search the registry and find where IWADs have been installed.

  //CheckUninstallStrings();
  //CheckInstallRootPaths();
  //CheckSteamEdition();
  //CheckDOSDefaults();

  // Check for GUS patches installed with the BFG edition!

  //CheckSteamGUSPatches();

{$ELSE}
  //    AddXdgDirs();
{$IFDEF DARWIN}
  //    AddSteamDirs();
{$ENDIF}
{$ENDIF}

  // Don't run this function again.

  iwad_dirs_built := true;
End;


// Check if the specified directory contains the specified IWAD
// file, returning the full path to the IWAD if found, or NULL
// if not found.

Function CheckDirectoryHasIWAD(dir, iwadname: String): String;
Var
  probe, Filename: String;
Begin
  result := '';
  //    // As a special case, the "directory" may refer directly to an
  //    // IWAD file if the path comes from DOOMWADDIR or DOOMWADPATH.
  //
  //    probe = M_FileCaseExists(dir);
  //    if (DirIsFile(dir, iwadname) && probe != NULL)
  //    {
  //        return probe;
  //    }

  If Not DirectoryExists(dir) Then exit;
  // Construct the full path to the IWAD if it is located in
  // this directory, and check if it exists.
  If dir = '.' Then Begin
    Filename := iwadname;
  End
  Else Begin
    Filename := IncludeTrailingPathDelimiter(dir) + iwadname;
  End;
  probe := M_FileCaseExists(Filename);
  If probe <> '' Then Begin
    result := probe;
  End;
End;

// Search a directory to try to find an IWAD
// Returns the location of the IWAD if found, otherwise NULL.

Function SearchDirectoryForIWAD(Const dir: String; mask: int; Var mission: GameMission_t): String;
Var
  i: integer;
  filename: String;
Begin
  result := '';

  For i := 0 To high(iwads) Do Begin

    If (((1 Shl integer(iwads[i].mission)) And mask) = 0) Then Continue;

    filename := CheckDirectoryHasIWAD(dir, iwads[i].name);

    If (filename <> '') Then Begin
      mission := iwads[i].mission;

      result := filename;

      exit;
    End;
  End;
End;

//
// FindIWAD
// Checks availability of IWAD files by name,
// to determine whether registered/commercial features
// should be executed (notably loading PWADs).
//

Function D_FindIWAD(mask: int; Var mission: GameMission_t): String;
Var
  iwadparm: int;
  //    const char *iwadfile;
  i: int;
Begin
  result := '';

  // Check for the -iwad parameter

  //!
  // Specify an IWAD file to use.
  //
  // @arg <file>
  //

  iwadparm := M_CheckParmWithArgs('-iwad', 1);

  If (iwadparm <> 0) Then Begin
    // Search through IWAD dirs for an IWAD with the given name.
//
//        iwadfile = myargv[iwadparm + 1];
//
//        result = D_FindWADByName(iwadfile);
//
//        if (result == NULL)
//        {
//            I_Error('IWAD file '%s' not found!', iwadfile);
//        }
//
//        *mission = IdentifyIWADByName(result, mask);
  End
  Else Begin
    // Search through the list and look for an IWAD

    BuildIWADDirList();

    For i := 0 To num_iwad_dirs - 1 Do Begin
      result := SearchDirectoryForIWAD(iwad_dirs[i], mask, mission);
      If result <> '' Then break;
    End;
  End;
End;

//
// Get the IWAD name used for savegames.
//

Function D_SaveGameIWADName(gamemission: GameMission_t;
  gamevariant: GameVariant_t): String;
Var
  i: int;
Begin
  // Default fallback:
  result := 'unknown.wad';
  // Determine the IWAD name to use for savegames.
  // This determines the directory the savegame files get put into.
  //
  // Note that we match on gamemission rather than on IWAD name.
  // This ensures that doom1.wad and doom.wad saves are stored
  // in the same place.

  If (gamevariant = freedoom) Then Begin
    If (gamemission = doom) Then Begin
      result := 'freedoom1.wad';
    End
    Else If (gamemission = doom2) Then Begin
      result := 'freedoom2.wad';
    End
  End
  Else If (gamevariant = freedm) And (gamemission = doom2) Then Begin
    result := 'freedm.wad';
  End;

  For i := 0 To high(iwads) Do Begin
    If (gamemission = iwads[i].mission) Then Begin
      result := iwads[i].name;
      break;
    End;
  End;
End;

End.

