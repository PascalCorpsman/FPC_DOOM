Unit g_game;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef
  , d_event
  ;

Var
  timelimit: int;

  nodrawers: boolean = false; // for comparative timing purposes
  gamestate: gamestate_t;
  demorecording: Boolean;
  paused: boolean;
  sendpause: Boolean;

Function G_Responder(Const ev: Pevent_t): boolean;

Function speedkeydown(): boolean;

Implementation

//
// G_Responder
// Get info needed to make ticcmd_ts for the players.
//

Function G_Responder(Const ev: Pevent_t): boolean;
Begin
  //   // [crispy] demo pause (from prboom-plus)
  //    if (gameaction == ga_nothing &&
  //        (demoplayback || gamestate == GS_DEMOSCREEN))
  //    {
  //        if (ev->type == ev_keydown && ev->data1 == key_pause)
  //        {
  //            if (paused ^= 2)
  //                S_PauseSound();
  //            else
  //                S_ResumeSound();
  //            return true;
  //        }
  //    }
  //
  //    // [crispy] demo fast-forward
  //    if (ev->type == ev_keydown && ev->data1 == key_demospeed &&
  //        (demoplayback || gamestate == GS_DEMOSCREEN))
  //    {
  //        singletics = !singletics;
  //        return true;
  //    }
  //
  //    // allow spy mode changes even during the demo
  //    if (gamestate == GS_LEVEL && ev->type == ev_keydown
  //     && ev->data1 == key_spy && (singledemo || !deathmatch) )
  //    {
  //	// spy mode
  //	do
  //	{
  //	    displayplayer++;
  //	    if (displayplayer == MAXPLAYERS)
  //		displayplayer = 0;
  //	} while (!playeringame[displayplayer] && displayplayer != consoleplayer);
  //	// [crispy] killough 3/7/98: switch status bar views too
  //	ST_Start();
  //	HU_Start();
  //	S_UpdateSounds(players[displayplayer].mo);
  //	// [crispy] re-init automap variables for correct player arrow angle
  //	if (automapactive)
  //	AM_initVariables();
  //	return true;
  //    }
  //
  //    // any other key pops up menu if in demos
  //    if (gameaction == ga_nothing && !singledemo &&
  //	(demoplayback || gamestate == GS_DEMOSCREEN)
  //	)
  //    {
  //	if (ev->type == ev_keydown ||
  //	    (ev->type == ev_mouse && ev->data1) ||
  //	    (ev->type == ev_joystick && ev->data1) )
  //	{
  //	    // [crispy] play a sound if the menu is activated with a different key than ESC
  //	    if (!menuactive && crispy->soundfix)
  //		S_StartSoundOptional(NULL, sfx_mnuopn, sfx_swtchn); // [NS] Optional menu sounds.
  //	    M_StartControlPanel ();
  //	    joywait = I_GetTime() + 5;
  //	    return true;
  //	}
  //	return false;
  //    }
  //
  //    if (gamestate == GS_LEVEL)
  //    {
  //#if 0
  //	if (devparm && ev->type == ev_keydown && ev->data1 == ';')
  //	{
  //	    G_DeathMatchSpawnPlayer (0);
  //	    return true;
  //	}
  //#endif
  //	if (HU_Responder (ev))
  //	    return true;	// chat ate the event
  //	if (ST_Responder (ev))
  //	    return true;	// status window ate it
  //	if (AM_Responder (ev))
  //	    return true;	// automap ate it
  //    }
  //
  //    if (gamestate == GS_FINALE)
  //    {
  //	if (F_Responder (ev))
  //	    return true;	// finale ate the event
  //    }
  //
  //    if (testcontrols && ev->type == ev_mouse)
  //    {
  //        // If we are invoked by setup to test the controls, save the
  //        // mouse speed so that we can display it on-screen.
  //        // Perform a low pass filter on this so that the thermometer
  //        // appears to move smoothly.
  //
  //        testcontrols_mousespeed = abs(ev->data2);
  //    }
  //
  //    // If the next/previous weapon keys are pressed, set the next_weapon
  //    // variable to change weapons when the next ticcmd is generated.
  //
  //    if (ev->type == ev_keydown && ev->data1 == key_prevweapon)
  //    {
  //        next_weapon = -1;
  //    }
  //    else if (ev->type == ev_keydown && ev->data1 == key_nextweapon)
  //    {
  //        next_weapon = 1;
  //    }
  //
  //    switch (ev->type)
  //    {
  //      case ev_keydown:
  //	if (ev->data1 == key_pause)
  //	{
  //	    sendpause = true;
  //	}
  //        else if (ev->data1 <NUMKEYS)
  //        {
  //	    gamekeydown[ev->data1] = true;
  //        }
  //
  //	return true;    // eat key down events
  //
  //      case ev_keyup:
  //	if (ev->data1 <NUMKEYS)
  //	    gamekeydown[ev->data1] = false;
  //	return false;   // always let key up events filter down
  //
  //      case ev_mouse:
  //        SetMouseButtons(ev->data1);
  //        mousex += ev->data2;
  //        mousey += ev->data3;
  //	return true;    // eat events
  //
  //      case ev_joystick:
  //        SetJoyButtons(ev->data1);
  //	joyxmove = ev->data2;
  //	joyymove = ev->data3;
  //        joystrafemove = ev->data4;
  //        joylook = ev->data5;
  //	return true;    // eat events
  //
  //      default:
  //	break;
  //    }

  result := false;
End;

// [crispy] holding down the "Run" key may trigger special behavior,
// e.g. quick exit, clean screenshots, resurrection from savegames

Function speedkeydown(): boolean;
Begin
  // TODO: Fehlt noch
//   return (key_speed < NUMKEYS && gamekeydown[key_speed]) ||
//           (joybspeed < MAX_JOY_BUTTONS && joybuttons[joybspeed]) ||
//           (mousebspeed < MAX_MOUSE_BUTTONS && mousebuttons[mousebspeed]);
  result := false;
End;

End.

