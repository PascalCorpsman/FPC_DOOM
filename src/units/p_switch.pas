Unit p_switch; // Finished porting

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , p_spec
  ;

Var
  buttonlist: Array Of button_t; // [crispy] remove MAXBUTTONS limit
  maxbuttons: int; // [crispy] remove MAXBUTTONS limit

Procedure P_InitSwitchList();

Procedure P_ChangeSwitchTexture(line: Pline_t; useAgain: int);

Function P_UseSpecialLine(thing: Pmobj_t; line: Pline_t; side: int): boolean;

Implementation

Uses
  doomdata, doomstat, sounds
  , d_mode
  , i_system
  , g_game
  , p_doors, p_setup, p_floor, p_plats, p_ceilng, p_lights
  , r_data
  , s_sound
  , w_wad
  , z_zone
  ;

Const

  //
  // CHANGE THE TEXTURE OF A WALL SWITCH TO ITS OPPOSITE
  //
  // [crispy] add support for SWITCHES lumps
  alphSwitchList_vanilla: Array Of switchlist_t =
  (
    // Doom shareware episode 1 switches
    (name1: 'SW1BRCOM'; name2: 'SW2BRCOM'; episode: 1),
    (name1: 'SW1BRN1'; name2: 'SW2BRN1'; episode: 1),
    (name1: 'SW1BRN2'; name2: 'SW2BRN2'; episode: 1),
    (name1: 'SW1BRNGN'; name2: 'SW2BRNGN'; episode: 1),
    (name1: 'SW1BROWN'; name2: 'SW2BROWN'; episode: 1),
    (name1: 'SW1COMM'; name2: 'SW2COMM'; episode: 1),
    (name1: 'SW1COMP'; name2: 'SW2COMP'; episode: 1),
    (name1: 'SW1DIRT'; name2: 'SW2DIRT'; episode: 1),
    (name1: 'SW1EXIT'; name2: 'SW2EXIT'; episode: 1),
    (name1: 'SW1GRAY'; name2: 'SW2GRAY'; episode: 1),
    (name1: 'SW1GRAY1'; name2: 'SW2GRAY1'; episode: 1),
    (name1: 'SW1METAL'; name2: 'SW2METAL'; episode: 1),
    (name1: 'SW1PIPE'; name2: 'SW2PIPE'; episode: 1),
    (name1: 'SW1SLAD'; name2: 'SW2SLAD'; episode: 1),
    (name1: 'SW1STARG'; name2: 'SW2STARG'; episode: 1),
    (name1: 'SW1STON1'; name2: 'SW2STON1'; episode: 1),
    (name1: 'SW1STON2'; name2: 'SW2STON2'; episode: 1),
    (name1: 'SW1STONE'; name2: 'SW2STONE'; episode: 1),
    (name1: 'SW1STRTN'; name2: 'SW2STRTN'; episode: 1),

    // Doom registered episodes 2&3 switches
    (name1: 'SW1BLUE'; name2: 'SW2BLUE'; episode: 2),
    (name1: 'SW1CMT'; name2: 'SW2CMT'; episode: 2),
    (name1: 'SW1GARG'; name2: 'SW2GARG'; episode: 2),
    (name1: 'SW1GSTON'; name2: 'SW2GSTON'; episode: 2),
    (name1: 'SW1HOT'; name2: 'SW2HOT'; episode: 2),
    (name1: 'SW1LION'; name2: 'SW2LION'; episode: 2),
    (name1: 'SW1SATYR'; name2: 'SW2SATYR'; episode: 2),
    (name1: 'SW1SKIN'; name2: 'SW2SKIN'; episode: 2),
    (name1: 'SW1VINE'; name2: 'SW2VINE'; episode: 2),
    (name1: 'SW1WOOD'; name2: 'SW2WOOD'; episode: 2),

    // Doom II switches
    (name1: 'SW1PANEL'; name2: 'SW2PANEL'; episode: 3),
    (name1: 'SW1ROCK'; name2: 'SW2ROCK'; episode: 3),
    (name1: 'SW1MET2'; name2: 'SW2MET2'; episode: 3),
    (name1: 'SW1WDMET'; name2: 'SW2WDMET'; episode: 3),
    (name1: 'SW1BRIK'; name2: 'SW2BRIK'; episode: 3),
    (name1: 'SW1MOD1'; name2: 'SW2MOD1'; episode: 3),
    (name1: 'SW1ZIM'; name2: 'SW2ZIM'; episode: 3),
    (name1: 'SW1STON6'; name2: 'SW2STON6'; episode: 3),
    (name1: 'SW1TEK'; name2: 'SW2TEK'; episode: 3),
    (name1: 'SW1MARB'; name2: 'SW2MARB'; episode: 3),
    (name1: 'SW1SKULL'; name2: 'SW2SKULL'; episode: 3),

    // [crispy] SWITCHES lumps are supposed to end like this
    (name1: ''; name2: ''; episode: 0)
    );

Var
  // [crispy] remove MAXSWITCHES limit
  switchlist: Array Of int;
  numswitches: int;
  maxswitches: size_t = 0;

  //
  // P_InitSwitchList
  // Only called at game initialization.
  //

Procedure P_InitSwitchList();
Var
  i, slindex, episode: int;
  alphSwitchList: ^switchlist_t;
  from_lump: Boolean;
  alphSwitchList_episode: Short;
  newmax: size_t;
  texture1, texture2: int;
  name1, name2: String;
Begin
  // [crispy] add support for SWITCHES lumps
  from_lump := W_CheckNumForName('SWITCHES') <> -1;
  If (from_lump) Then Begin
    alphSwitchList := W_CacheLumpName('SWITCHES', PU_STATIC);
  End
  Else Begin
    alphSwitchList := @alphSwitchList_vanilla[0];
  End;

  // Note that this is called "episode" here but it's actually something
  // quite different. As we progress from Shareware->Registered->Doom II
  // we support more switch textures.
  Case (gamemode) Of
    registered,
      retail:
      episode := 2;
    commercial:
      episode := 3;
  Else
    episode := 1;
  End;

  slindex := 0;
  i := 0;
  While alphSwitchList[i].episode <> 0 Do Begin
    If from_lump Then Begin
      alphSwitchList_episode := alphSwitchList[i].episode;
    End
    Else Begin
      alphSwitchList_episode := alphSwitchList[i].episode;
    End;

    // [crispy] remove MAXSWITCHES limit
    If (slindex + 1 >= maxswitches) Then Begin
      If maxswitches <> 0 Then Begin
        newmax := 2 * maxswitches;
      End
      Else Begin
        newmax := DEFINE_MAXSWITCHES;
      End;
      setlength(switchlist, newmax);
      maxswitches := newmax;
    End;

    // [crispy] ignore switches referencing unknown texture names,
    // warn if either one is missing, but only add if both are valid
    If (alphSwitchList_episode <= episode) Then Begin

      name1 := alphSwitchList[i].name1;
      name2 := alphSwitchList[i].name2;

      texture1 := R_CheckTextureNumForName(name1);
      texture2 := R_CheckTextureNumForName(name2);

      If (texture1 = -1) Or (texture2 = -1) Then Begin
        writeln(stderr, format('P_InitSwitchList: could not add %s(%d)/%s(%d)',
          [name1, texture1, name2, texture2]));
      End
      Else Begin
        switchlist[slindex] := texture1;
        slindex := slindex + 1;
        switchlist[slindex] := texture2;
        slindex := slindex + 1;
      End;
    End;
    inc(i);
  End;

  numswitches := slindex Div 2;
  switchlist[slindex] := -1;

  // [crispy] add support for SWITCHES lumps
  If (from_lump) Then Begin
    W_ReleaseLumpName('SWITCHES');
  End;

  // [crispy] pre-allocate some memory for the buttonlist[] array
  maxbuttons := DEFINE_MAXBUTTONS;
  // buttonlist = I_Realloc(NULL, sizeof(*buttonlist) * (maxbuttons = MAXBUTTONS));
  // memset(buttonlist, 0, sizeof(*buttonlist) * maxbuttons);
  setlength(buttonlist, maxbuttons);
  FillChar(buttonlist[0], maxbuttons * sizeof(buttonlist[0]), 0);
End;

//
// Start a button counting down till it turns off.
//

Procedure P_StartButton(line: Pline_t; w: bwhere_e; texture: int; time: int);
Var
  i: int;
Begin
  // See if button is already pressed

  For i := 0 To maxbuttons - 1 Do Begin
    If (buttonlist[i].btimer <> 0)
      And (buttonlist[i].line = line) Then Begin
      // [crispy] register up to three buttons at once for lines with more than one switch texture
      If (buttonlist[i].where = w) Then Begin
        exit;
      End;
    End;
  End;

  For i := 0 To maxbuttons - 1 Do Begin
    If (buttonlist[i].btimer = 0) Then Begin
      buttonlist[i].line := line;
      buttonlist[i].where := w;
      buttonlist[i].btexture := texture;
      buttonlist[i].btimer := time;
      If crispy.soundfix <> 0 Then Begin
        buttonlist[i].soundorg := @line^.soundorg; // [crispy] corrected sound source
      End
      Else Begin
        buttonlist[i].soundorg := @line^.frontsector^.soundorg; // [crispy] corrected sound source
      End;
      exit;
    End;
  End;

  // [crispy] remove MAXBUTTONS limit
  Begin
    maxbuttons := 2 * maxbuttons;
    setlength(buttonlist, maxbuttons);
    For i := maxbuttons Div 2 To maxbuttons - 1 Do
      FillChar(buttonlist[i], sizeof(buttonlist[i]), 0);

    P_StartButton(line, w, texture, time);
    exit;
  End;

  I_Error('P_StartButton: no button slots left!');
End;

//
// Function that changes wall texture.
// Tell it if switch is ok to use again (1=yes, it's a button).
//

Procedure P_ChangeSwitchTexture(line: Pline_t; useAgain: int);
Var
  texTop, texMid, texBot: int;
  i: int;
  sound: sfxenum_t;
  playsound: Boolean;
Begin
  playsound := false;

  If (useAgain = 0) Then
    line^.special := 0;

  texTop := sides[line^.sidenum[0]].toptexture;
  texMid := sides[line^.sidenum[0]].midtexture;
  texBot := sides[line^.sidenum[0]].bottomtexture;

  sound := sfx_swtchn;

  // EXIT SWITCH?
  If (line^.special = 11) Then
    sound := sfx_swtchx;

  For i := 0 To numswitches * 2 - 1 Do Begin

    If (switchlist[i] = texTop) Then Begin

      // S_StartSound(buttonlist^.soundorg,sound);
      playsound := true;
      sides[line^.sidenum[0]].toptexture := switchlist[i Xor 1];

      If (useAgain <> 0) Then
        P_StartButton(line, top, switchlist[i], BUTTONTIME);

      // return;
    End
      // [crispy] register up to three buttons at once for lines with more than one switch texture
      ; // else
    Begin
      If (switchlist[i] = texMid) Then Begin
        // S_StartSound(buttonlist^.soundorg,sound);
        playsound := true;
        sides[line^.sidenum[0]].midtexture := switchlist[i Xor 1];

        If (useAgain <> 0) Then
          P_StartButton(line, middle, switchlist[i], BUTTONTIME);

        // return;
      End
        // [crispy] register up to three buttons at once for lines with more than one switch texture
        ; // else
      Begin
        If (switchlist[i] = texBot) Then Begin

          // S_StartSound(buttonlist^.soundorg,sound);
          playsound := true;
          sides[line^.sidenum[0]].bottomtexture := switchlist[i Xor 1];

          If (useAgain <> 0) Then
            P_StartButton(line, bottom, switchlist[i], BUTTONTIME);

          // return;
        End;
      End;
    End;
  End;

  // [crispy] corrected sound source
  If (playsound)
    Then Begin
    If crispy.soundfix <> 0 Then Begin
      S_StartSound(@line^.soundorg, sound);
    End
    Else Begin
      S_StartSound(buttonlist[0].soundorg, sound); // WTF: warum wird hier immer der erste Button genommen ?
    End;
  End;
End;

//
// P_UseSpecialLine
// Called when a thing uses a special line.
// Only the front sides of lines are usable.
//

Function P_UseSpecialLine(thing: Pmobj_t; line: Pline_t; side: int): boolean;
Begin
  // Err...
  // Use the back sides of VERY SPECIAL lines...
  If (side <> 0) Then Begin
    Case line^.special Of
      124: Begin
          // Sliding door open&close
          // UNUSED?
        End;
    Else Begin
        result := false;
        exit;
      End;
    End;
  End;

  // Switches that other things can activate.
  If (thing^.player = Nil) Then Begin
    // never open secret doors
    If (line = Nil) Or ((line^.flags And ML_SECRET) <> 0) Then Begin
      result := false;
      exit;
    End;

    Case (line^.special) Of
      1, // MANUAL DOOR RAISE
      32, // MANUAL BLUE
      33, // MANUAL RED
      34: Begin // MANUAL YELLOW
        End;
    Else Begin
        result := false;
        exit;
      End;
    End;
  End;

  // do something
  Case line^.special Of

    // MANUALS
    1, // Vertical Door
    26, // Blue Door/Locked
    27, // Yellow Door /Locked
    28, // Red Door /Locked

    31, // Manual door open
    32, // Blue locked door open
    33, // Red locked door open
    34, // Yellow locked door open

    117, // Blazing door raise
    118: Begin // Blazing door open
        EV_VerticalDoor(line, thing);
      End;

    //UNUSED - Door Slide Open&Close
    // case 124:
    // EV_SlidingDoor (line, thing);
    // break;

    // SWITCHES
    7: Begin
        // Build Stairs
        If (EV_BuildStairs(line, build8) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    9: Begin
        // Change Donut
        If (EV_DoDonut(line) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    11: Begin
        // Exit level
        P_ChangeSwitchTexture(line, 0);
        G_ExitLevel();
      End;

    14: Begin
        // Raise Floor 32 and change texture
        If (EV_DoPlat(line, raiseAndChange, 32) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    15: Begin
        // Raise Floor 24 and change texture
        If (EV_DoPlat(line, raiseAndChange, 24) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    18: Begin
        // Raise Floor to next highest floor
        If (EV_DoFloor(line, raiseFloorToNearest) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    20: Begin
        // Raise Plat next highest floor and change texture
        If (EV_DoPlat(line, raiseToNearestAndChange, 0) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    21: Begin
        // PlatDownWaitUpStay
        If (EV_DoPlat(line, downWaitUpStay, 0) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    23: Begin
        // Lower Floor to Lowest
        If (EV_DoFloor(line, lowerFloorToLowest) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    29: Begin
        // Raise Door
        If (EV_DoDoor(line, vld_normal) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    41: Begin
        // Lower Ceiling to Floor
        If (EV_DoCeiling(line, lowerToFloor) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    71: Begin
        // Turbo Lower Floor
        If (EV_DoFloor(line, turboLower) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    49: Begin
        // Ceiling Crush And Raise
        If (EV_DoCeiling(line, crushAndRaise) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    50: Begin
        // Close Door
        If (EV_DoDoor(line, vld_close) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    51: Begin
        // Secret EXIT
        P_ChangeSwitchTexture(line, 0);
        G_SecretExitLevel();
      End;

    55: Begin
        // Raise Floor Crush
        If (EV_DoFloor(line, raiseFloorCrush) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    101: Begin
        // Raise Floor
        If (EV_DoFloor(line, raiseFloor) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    102: Begin
        // Lower Floor to Surrounding floor height
        If (EV_DoFloor(line, lowerFloor) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;
    103: Begin
        // Open Door
        If (EV_DoDoor(line, vld_open) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    111: Begin
        // Blazing Door Raise (faster than TURBO!)
        If (EV_DoDoor(line, vld_blazeRaise) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    112: Begin
        // Blazing Door Open (faster than TURBO!)
        If (EV_DoDoor(line, vld_blazeOpen) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    113: Begin
        // Blazing Door Close (faster than TURBO!)
        If (EV_DoDoor(line, vld_blazeClose) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    122: Begin
        // Blazing PlatDownWaitUpStay
        If (EV_DoPlat(line, blazeDWUS, 0) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    127: Begin
        // Build Stairs Turbo 16
        If (EV_BuildStairs(line, turbo16) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    131: Begin
        // Raise Floor Turbo
        If (EV_DoFloor(line, raiseFloorTurbo) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    133,
      // BlzOpenDoor BLUE
    135,
      // BlzOpenDoor RED
    137: Begin
        // BlzOpenDoor YELLOW
        If (EV_DoLockedDoor(line, vld_blazeOpen, thing) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    140: Begin
        // Raise Floor 512
        If (EV_DoFloor(line, raiseFloor512) <> 0) Then
          P_ChangeSwitchTexture(line, 0);
      End;

    // BUTTONS
    42: Begin
        // Close Door
        If (EV_DoDoor(line, vld_close) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    43: Begin
        // Lower Ceiling to Floor
        If (EV_DoCeiling(line, lowerToFloor) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    45: Begin
        // Lower Floor to Surrounding floor height
        If (EV_DoFloor(line, lowerFloor) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    60: Begin
        // Lower Floor to Lowest
        If (EV_DoFloor(line, lowerFloorToLowest) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    61: Begin
        // Open Door
        If (EV_DoDoor(line, vld_open) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    62: Begin
        // PlatDownWaitUpStay
        If (EV_DoPlat(line, downWaitUpStay, 1) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    63: Begin
        // Raise Door
        If (EV_DoDoor(line, vld_normal) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    64: Begin
        // Raise Floor to ceiling
        If (EV_DoFloor(line, raiseFloor) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    66: Begin
        // Raise Floor 24 and change texture
        If (EV_DoPlat(line, raiseAndChange, 24) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    67: Begin
        // Raise Floor 32 and change texture
        If (EV_DoPlat(line, raiseAndChange, 32) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    65: Begin
        // Raise Floor Crush
        If (EV_DoFloor(line, raiseFloorCrush) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    68: Begin
        // Raise Plat to next highest floor and change texture
        If (EV_DoPlat(line, raiseToNearestAndChange, 0) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    69: Begin
        // Raise Floor to next highest floor
        If (EV_DoFloor(line, raiseFloorToNearest) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    70: Begin
        // Turbo Lower Floor
        If (EV_DoFloor(line, turboLower) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    114: Begin
        // Blazing Door Raise (faster than TURBO!)
        If (EV_DoDoor(line, vld_blazeRaise) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    115: Begin
        // Blazing Door Open (faster than TURBO!)
        If (EV_DoDoor(line, vld_blazeOpen) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    116: Begin
        // Blazing Door Close (faster than TURBO!)
        If (EV_DoDoor(line, vld_blazeClose) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    123: Begin
        // Blazing PlatDownWaitUpStay
        If (EV_DoPlat(line, blazeDWUS, 0) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    132: Begin
        // Raise Floor Turbo
        If (EV_DoFloor(line, raiseFloorTurbo) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    99,
      // BlzOpenDoor BLUE
    134,
      // BlzOpenDoor RED
    136: Begin
        // BlzOpenDoor YELLOW
        If (EV_DoLockedDoor(line, vld_blazeOpen, thing) <> 0) Then
          P_ChangeSwitchTexture(line, 1);
      End;

    138: Begin
        // Light Turn On
        EV_LightTurnOn(line, 255);
        P_ChangeSwitchTexture(line, 1);
      End;

    139: Begin
        // Light Turn Off
        EV_LightTurnOn(line, 35);
        P_ChangeSwitchTexture(line, 1);
      End;
  End;
  result := true;
End;

End.

