Unit p_switch;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Procedure P_InitSwitchList();
Procedure P_ChangeSwitchTexture(line: Pline_t; useAgain: int);

Function P_UseSpecialLine(thing: Pmobj_t; line: Pline_t; side: int): boolean;

Implementation

Uses
  doomdata
  , p_doors
  ;

//
// P_InitSwitchList
// Only called at game initialization.
//

Procedure P_InitSwitchList();
//int i, slindex, episode;
Begin

  // [crispy] add support for SWITCHES lumps
//    switchlist_t *alphSwitchList;
//    boolean from_lump;
//
//    if ((from_lump = (W_CheckNumForName("SWITCHES") != -1)))
//    {
//	alphSwitchList = W_CacheLumpName("SWITCHES", PU_STATIC);
//    }
//    else
//    {
//	alphSwitchList = alphSwitchList_vanilla;
//    }
//
//    // Note that this is called "episode" here but it's actually something
//    // quite different. As we progress from Shareware->Registered->Doom II
//    // we support more switch textures.
//    switch (gamemode)
//    {
//        case registered:
//        case retail:
//            episode = 2;
//            break;
//        case commercial:
//            episode = 3;
//            break;
//        default:
//            episode = 1;
//            break;
//    }
//
//    slindex = 0;
//
//    for (i = 0; alphSwitchList[i].episode; i++)
//    {
//	const short alphSwitchList_episode = from_lump ?
//	    SHORT(alphSwitchList[i].episode) :
//	    alphSwitchList[i].episode;
//
//	// [crispy] remove MAXSWITCHES limit
//	if (slindex + 1 >= maxswitches)
//	{
//	    size_t newmax = maxswitches ? 2 * maxswitches : MAXSWITCHES;
//	    switchlist = I_Realloc(switchlist, newmax * sizeof(*switchlist));
//	    maxswitches = newmax;
//	}
//
//	// [crispy] ignore switches referencing unknown texture names,
//	// warn if either one is missing, but only add if both are valid
//	if (alphSwitchList_episode <= episode)
//	{
//	    int texture1, texture2;
//	    const char *name1 = DEH_String(alphSwitchList[i].name1);
//	    const char *name2 = DEH_String(alphSwitchList[i].name2);
//
//	    texture1 = R_CheckTextureNumForName(name1);
//	    texture2 = R_CheckTextureNumForName(name2);
//
//	    if (texture1 == -1 || texture2 == -1)
//	    {
//		fprintf(stderr, "P_InitSwitchList: could not add %s(%d)/%s(%d)\n",
//		        name1, texture1, name2, texture2);
//	    }
//	    else
//	    {
//		switchlist[slindex++] = texture1;
//		switchlist[slindex++] = texture2;
//	    }
//	}
//    }
//
//    numswitches = slindex / 2;
//    switchlist[slindex] = -1;
//
//    // [crispy] add support for SWITCHES lumps
//    if (from_lump)
//    {
//	W_ReleaseLumpName("SWITCHES");
//    }
//
//    // [crispy] pre-allocate some memory for the buttonlist[] array
//    buttonlist = I_Realloc(NULL, sizeof(*buttonlist) * (maxbuttons = MAXBUTTONS));
//    memset(buttonlist, 0, sizeof(*buttonlist) * maxbuttons);
End;

//
// Function that changes wall texture.
// Tell it if switch is ok to use again (1=yes, it's a button).
//

Procedure P_ChangeSwitchTexture(line: Pline_t; useAgain: int);
Begin
  //    int     texTop;
  //    int     texMid;
  //    int     texBot;
  //    int     i;
  //    int     sound;
  //    boolean playsound = false;
  //
  //    if (!useAgain)
  //	line->special = 0;
  //
  //    texTop = sides[line->sidenum[0]].toptexture;
  //    texMid = sides[line->sidenum[0]].midtexture;
  //    texBot = sides[line->sidenum[0]].bottomtexture;
  //
  //    sound = sfx_swtchn;
  //
  //    // EXIT SWITCH?
  //    if (line->special == 11)
  //	sound = sfx_swtchx;
  //
  //    for (i = 0;i < numswitches*2;i++)
  //    {
  //	if (switchlist[i] == texTop)
  //	{
  ////	    S_StartSound(buttonlist->soundorg,sound);
  //	    playsound = true;
  //	    sides[line->sidenum[0]].toptexture = switchlist[i^1];
  //
  //	    if (useAgain)
  //		P_StartButton(line,top,switchlist[i],BUTTONTIME);
  //
  ////	    return;
  //	}
  //	// [crispy] register up to three buttons at once for lines with more than one switch texture
  ////	else
  //	{
  //	    if (switchlist[i] == texMid)
  //	    {
  ////		S_StartSound(buttonlist->soundorg,sound);
  //		playsound = true;
  //		sides[line->sidenum[0]].midtexture = switchlist[i^1];
  //
  //		if (useAgain)
  //		    P_StartButton(line, middle,switchlist[i],BUTTONTIME);
  //
  ////		return;
  //	    }
  //	    // [crispy] register up to three buttons at once for lines with more than one switch texture
  ////	    else
  //	    {
  //		if (switchlist[i] == texBot)
  //		{
  ////		    S_StartSound(buttonlist->soundorg,sound);
  //		    playsound = true;
  //		    sides[line->sidenum[0]].bottomtexture = switchlist[i^1];
  //
  //		    if (useAgain)
  //			P_StartButton(line, bottom,switchlist[i],BUTTONTIME);
  //
  ////		    return;
  //		}
  //	    }
  //	}
  //    }
  //
  //    // [crispy] corrected sound source
  //    if (playsound)
  //    {
  //	S_StartSound(crispy->soundfix ? &line->soundorg : buttonlist->soundorg,sound);
  //    }
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
    If (line^.flags And ML_SECRET) <> 0 Then Begin
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

    //	//UNUSED - Door Slide Open&Close
    //	// case 124:
    //	// EV_SlidingDoor (line, thing);
    //	// break;
    //
    //	// SWITCHES
    //      case 7:
    //	// Build Stairs
    //	if (EV_BuildStairs(line,build8))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 9:
    //	// Change Donut
    //	if (EV_DoDonut(line))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 11:
    //	// Exit level
    //	P_ChangeSwitchTexture(line,0);
    //	G_ExitLevel ();
    //	break;
    //
    //      case 14:
    //	// Raise Floor 32 and change texture
    //	if (EV_DoPlat(line,raiseAndChange,32))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 15:
    //	// Raise Floor 24 and change texture
    //	if (EV_DoPlat(line,raiseAndChange,24))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 18:
    //	// Raise Floor to next highest floor
    //	if (EV_DoFloor(line, raiseFloorToNearest))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 20:
    //	// Raise Plat next highest floor and change texture
    //	if (EV_DoPlat(line,raiseToNearestAndChange,0))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 21:
    //	// PlatDownWaitUpStay
    //	if (EV_DoPlat(line,downWaitUpStay,0))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 23:
    //	// Lower Floor to Lowest
    //	if (EV_DoFloor(line,lowerFloorToLowest))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 29:
    //	// Raise Door
    //	if (EV_DoDoor(line,vld_normal))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 41:
    //	// Lower Ceiling to Floor
    //	if (EV_DoCeiling(line,lowerToFloor))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 71:
    //	// Turbo Lower Floor
    //	if (EV_DoFloor(line,turboLower))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 49:
    //	// Ceiling Crush And Raise
    //	if (EV_DoCeiling(line,crushAndRaise))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 50:
    //	// Close Door
    //	if (EV_DoDoor(line,vld_close))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 51:
    //	// Secret EXIT
    //	P_ChangeSwitchTexture(line,0);
    //	G_SecretExitLevel ();
    //	break;
    //
    //      case 55:
    //	// Raise Floor Crush
    //	if (EV_DoFloor(line,raiseFloorCrush))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 101:
    //	// Raise Floor
    //	if (EV_DoFloor(line,raiseFloor))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 102:
    //	// Lower Floor to Surrounding floor height
    //	if (EV_DoFloor(line,lowerFloor))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 103:
    //	// Open Door
    //	if (EV_DoDoor(line,vld_open))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 111:
    //	// Blazing Door Raise (faster than TURBO!)
    //	if (EV_DoDoor (line,vld_blazeRaise))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 112:
    //	// Blazing Door Open (faster than TURBO!)
    //	if (EV_DoDoor (line,vld_blazeOpen))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 113:
    //	// Blazing Door Close (faster than TURBO!)
    //	if (EV_DoDoor (line,vld_blazeClose))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 122:
    //	// Blazing PlatDownWaitUpStay
    //	if (EV_DoPlat(line,blazeDWUS,0))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 127:
    //	// Build Stairs Turbo 16
    //	if (EV_BuildStairs(line,turbo16))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 131:
    //	// Raise Floor Turbo
    //	if (EV_DoFloor(line,raiseFloorTurbo))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 133:
    //	// BlzOpenDoor BLUE
    //      case 135:
    //	// BlzOpenDoor RED
    //      case 137:
    //	// BlzOpenDoor YELLOW
    //	if (EV_DoLockedDoor (line,vld_blazeOpen,thing))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //      case 140:
    //	// Raise Floor 512
    //	if (EV_DoFloor(line,raiseFloor512))
    //	    P_ChangeSwitchTexture(line,0);
    //	break;
    //
    //	// BUTTONS
    //      case 42:
    //	// Close Door
    //	if (EV_DoDoor(line,vld_close))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 43:
    //	// Lower Ceiling to Floor
    //	if (EV_DoCeiling(line,lowerToFloor))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 45:
    //	// Lower Floor to Surrounding floor height
    //	if (EV_DoFloor(line,lowerFloor))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 60:
    //	// Lower Floor to Lowest
    //	if (EV_DoFloor(line,lowerFloorToLowest))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 61:
    //	// Open Door
    //	if (EV_DoDoor(line,vld_open))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 62:
    //	// PlatDownWaitUpStay
    //	if (EV_DoPlat(line,downWaitUpStay,1))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 63:
    //	// Raise Door
    //	if (EV_DoDoor(line,vld_normal))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 64:
    //	// Raise Floor to ceiling
    //	if (EV_DoFloor(line,raiseFloor))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 66:
    //	// Raise Floor 24 and change texture
    //	if (EV_DoPlat(line,raiseAndChange,24))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 67:
    //	// Raise Floor 32 and change texture
    //	if (EV_DoPlat(line,raiseAndChange,32))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 65:
    //	// Raise Floor Crush
    //	if (EV_DoFloor(line,raiseFloorCrush))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 68:
    //	// Raise Plat to next highest floor and change texture
    //	if (EV_DoPlat(line,raiseToNearestAndChange,0))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 69:
    //	// Raise Floor to next highest floor
    //	if (EV_DoFloor(line, raiseFloorToNearest))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 70:
    //	// Turbo Lower Floor
    //	if (EV_DoFloor(line,turboLower))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 114:
    //	// Blazing Door Raise (faster than TURBO!)
    //	if (EV_DoDoor (line,vld_blazeRaise))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 115:
    //	// Blazing Door Open (faster than TURBO!)
    //	if (EV_DoDoor (line,vld_blazeOpen))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 116:
    //	// Blazing Door Close (faster than TURBO!)
    //	if (EV_DoDoor (line,vld_blazeClose))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 123:
    //	// Blazing PlatDownWaitUpStay
    //	if (EV_DoPlat(line,blazeDWUS,0))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 132:
    //	// Raise Floor Turbo
    //	if (EV_DoFloor(line,raiseFloorTurbo))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 99:
    //	// BlzOpenDoor BLUE
    //      case 134:
    //	// BlzOpenDoor RED
    //      case 136:
    //	// BlzOpenDoor YELLOW
    //	if (EV_DoLockedDoor (line,vld_blazeOpen,thing))
    //	    P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 138:
    //	// Light Turn On
    //	EV_LightTurnOn(line,255);
    //	P_ChangeSwitchTexture(line,1);
    //	break;
    //
    //      case 139:
    //	// Light Turn Off
    //	EV_LightTurnOn(line,35);
    //	P_ChangeSwitchTexture(line,1);
    //	break;
  Else Begin
      Raise exception.create('P_UseSpecialLine: ' + inttostr(line^.special) + ' not ported yet.');
    End;
  End;

  result := true;

End;

End.

