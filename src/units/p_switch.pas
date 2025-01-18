Unit p_switch;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure P_InitSwitchList();

Implementation
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

End.

