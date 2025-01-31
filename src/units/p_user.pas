Unit p_user;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Procedure P_PlayerThink(player: Pplayer_t);

Procedure P_CalcHeight(player: Pplayer_t);

Implementation

Uses
  a11y_weapon_pspr, tables, doomdef, info, sounds
  , d_player, d_ticcmd, d_event
  , i_timer
  , g_game
  , m_fixed, m_menu
  , p_local, p_tick, p_mobj, p_spec, p_pspr, p_map
  , r_main, r_data
  , s_sound
  ;

Const
  // 16 pixels of bob
  MAXBOB = $100000;
  // Index of the special effects (INVUL inverse) map.
  INVERSECOLORMAP = 32;

  // [crispy] variable player view bob
  crispy_bobfactor: Array[0..2] Of fixed_t = (4, 3, 0);

Var
  onground: boolean;

  //
  // P_Thrust
  // Moves the given origin along a given angle.
  //

Procedure P_Thrust(player: Pplayer_t; angle: angle_t; move: fixed_t);
Begin
  angle := angle Shr ANGLETOFINESHIFT;
  player^.mo^.momx := player^.mo^.momx + FixedMul(move, finecosine[angle]);
  player^.mo^.momy := player^.mo^.momy + FixedMul(move, finesine[angle]);
End;

//
// P_DeathThink
// Fall on your face when dying.
// Decrease POV height to floor height.
//

Procedure P_DeathThink(player: Pplayer_t);
Begin
  //      angle_t		angle;
  //      angle_t		delta;

  P_MovePsprites(player);

  //      // fall to the ground
  //      if (player->viewheight > 6*FRACUNIT)
  //  	player->viewheight -= FRACUNIT;
  //
  //      if (player->viewheight < 6*FRACUNIT)
  //  	player->viewheight = 6*FRACUNIT;
  //
  //      player->deltaviewheight = 0;
  //      onground = (player->mo->z <= player->mo->floorz);
  //      P_CalcHeight (player);
  //
  //      if (player->attacker && player->attacker != player->mo)
  //      {
  //  	angle = R_PointToAngle2 (player->mo->x,
  //  				 player->mo->y,
  //  				 player->attacker->x,
  //  				 player->attacker->y);
  //
  //  	delta = angle - player->mo->angle;
  //
  //  	if (delta < ANG5 || delta > (unsigned)-ANG5)
  //  	{
  //  	    // Looking at killer,
  //  	    //  so fade damage flash down.
  //  	    player->mo->angle = angle;
  //
  //  	    if (player->damagecount)
  //  		player->damagecount--;
  //  	}
  //  	else if (delta < ANG180)
  //  	    player->mo->angle += ANG5;
  //  	else
  //  	    player->mo->angle -= ANG5;
  //      }
  //      else if (player->damagecount)
  //  	player->damagecount--;
  //
  //
  //      if (player->cmd.buttons & BT_USE)
  //  	player->playerstate = PST_REBORN;
End;

//
// P_MovePlayer
//

Procedure P_MovePlayer(player: Pplayer_t);
Var
  cmd: Pticcmd_t;
  look: int;
Begin
  cmd := @player^.cmd;

  player^.mo^.angle := angle_t(player^.mo^.angle + (cmd^.angleturn Shl FRACBITS));

  // Do not let the player control movement
  //  if not onground.
  onground := (player^.mo^.z <= player^.mo^.floorz);
  // [crispy] give full control in no-clipping mode
  onground := onground Or ((player^.mo^.flags And MF_NOCLIP) <> 0);

  // [crispy] fast polling
  //    if (player == &players[consoleplayer])
  //    {
  //        localview.ticangle += localview.ticangleturn << 16;
  //        localview.ticangleturn = 0;
  //    }

  If (cmd^.forwardmove <> 0) And (onground) Then
    P_Thrust(player, player^.mo^.angle, cmd^.forwardmove * 2048)
      // [crispy] in-air movement is only possible with jumping enabled
  Else If (cmd^.forwardmove <> 0) And (critical^.jump <> 0) Then
    P_Thrust(player, player^.mo^.angle, FRACUNIT Shr 8);

  If (cmd^.sidemove <> 0) And (onground) Then
    P_Thrust(player, angle_t(player^.mo^.angle - ANG90), cmd^.sidemove * 2048)
      // [crispy] in-air movement is only possible with jumping enabled
  Else If (cmd^.sidemove <> 0) And (critical^.jump <> 0) Then
    P_Thrust(player, angle_t(player^.mo^.angle - ANG90), FRACUNIT Shr 8);

  If (((cmd^.forwardmove <> 0) Or (cmd^.sidemove <> 0))
    And (player^.mo^.state = @states[integer(S_PLAY)])) Then Begin
    P_SetMobjState(player^.mo, S_PLAY_RUN1);
  End;

  // [crispy] apply lookdir delta
  look := cmd^.lookfly And 15;
  If (look > 7) Then Begin

    look := look - 16;
  End;
  If (look <> 0) Then Begin

    If (look = TOCENTER) Then Begin
      player^.centering := true;
    End
    Else Begin
      cmd^.lookdir := MLOOKUNIT * 5 * look;
    End;
  End;
  If (Not menuactive) And (Not demoplayback) Then Begin
    player^.lookdir := Clamp(player^.lookdir + cmd^.lookdir,
      -LOOKDIRMIN * MLOOKUNIT, LOOKDIRMAX * MLOOKUNIT);
  End;
End;

Procedure P_PlayerThink(player: Pplayer_t);
Var
  cmd: Pticcmd_t;
  newweapon: weapontype_t;
Begin
  // [AM] Assume we can interpolate at the beginning
  //      of the tic.
  player^.mo^.interp := 1;

  // [AM] Store starting position for player interpolation.
  player^.mo^.oldx := player^.mo^.x;
  player^.mo^.oldy := player^.mo^.y;
  player^.mo^.oldz := player^.mo^.z;
  player^.mo^.oldangle := player^.mo^.angle;
  player^.oldviewz := player^.viewz;
  player^.oldlookdir := player^.lookdir;
  player^.oldrecoilpitch := player^.recoilpitch;

  // [crispy] fast polling
  If (player = @players[consoleplayer]) Then Begin
    localview.oldticangle := localview.ticangle;
  End;

  // [crispy] update weapon sound source coordinates
  If (player^.so <> player^.mo) Then Begin
    //	memcpy(player->so, player->mo, sizeof(degenmobj_t));
    move(player^.mo^, player^.so^, sizeof(degenmobj_t));
  End;

  // fixme: do this in the cheat code
  If (player^.cheats And integer(CF_NOCLIP)) <> 0 Then Begin
    player^.mo^.flags := player^.mo^.flags Or MF_NOCLIP;
  End
  Else
    player^.mo^.flags := player^.mo^.flags And (Not MF_NOCLIP);

  // chain saw run forward
  cmd := @player^.cmd;
  If (player^.mo^.flags And MF_JUSTATTACKED) <> 0 Then Begin

    cmd^.angleturn := 0;
    //	cmd^.forwardmove = 0xc800/512; // WTF: Das muss verstanden und dann korrect umgesetzt werden ..
    cmd^.sidemove := 0;
    player^.mo^.flags := player^.mo^.flags And (Not MF_JUSTATTACKED);
  End;

  // [crispy] center view
  // e.g. after teleporting, dying, jumping and on demand
  If (player^.centering) Then Begin
    If (player^.lookdir > 0) Then Begin
      player^.lookdir := player^.lookdir - 8 * MLOOKUNIT;
    End
    Else If (player^.lookdir < 0) Then Begin
      player^.lookdir := player^.lookdir + 8 * MLOOKUNIT;
    End;
    If (abs(player^.lookdir) < 8 * MLOOKUNIT) Then Begin
      player^.lookdir := 0;
      player^.centering := false;
    End;
  End;

  // [crispy] weapon recoil pitch
  If (player^.recoilpitch <> 0) Then Begin
    If (player^.recoilpitch > 0) Then Begin

      player^.recoilpitch := player^.recoilpitch - 1;
    End
    Else If (player^.recoilpitch < 0) Then Begin
      player^.recoilpitch := player^.recoilpitch + 1;
    End;
  End;

  If (player^.playerstate = PST_DEAD) Then Begin
    P_DeathThink(player);
    exit;
  End;

  // [crispy] negative player health
  player^.neghealth := player^.health;

  // [crispy] delay next possible jump
  If (player^.jumpTics <> 0) Then Begin
    player^.jumpTics := player^.jumpTics - 1;
  End;

  // Move around.
  // Reactiontime is used to prevent movement
  //  for a bit after a teleport.
  If (player^.mo^.reactiontime <> 0) Then Begin
    player^.mo^.reactiontime := player^.mo^.reactiontime - 1;
  End
  Else Begin
    P_MovePlayer(player);
  End;

  P_CalcHeight(player);

  If (player^.mo^.subsector^.sector^.special <> 0) Then Begin
    P_PlayerInSpecialSector(player);
  End;

  // [crispy] jumping: apply vertical momentum
  If (cmd^.arti <> 0) Then Begin

    If ((cmd^.arti And AFLAG_JUMP) <> 0) And (onground) And
      (player^.viewz < player^.mo^.ceilingz - 16 * FRACUNIT) And (
      player^.jumpTics = 0) Then Begin
      // [crispy] Hexen sets 9; Strife adds 8
      player^.mo^.momz := (7 + critical^.jump) * FRACUNIT;
      player^.jumpTics := 18;
      // [NS] Jump sound.
      S_StartSoundOptional(player^.mo, sfx_pljump, sfx_None);
    End;
  End;

  // Check for weapon change.

  //    // A special event has no other buttons.
  //    if (cmd^.buttons & BT_SPECIAL)
  //	cmd^.buttons = 0;

  //    if (cmd^.buttons & BT_CHANGE)
  //    {
  //	// The actual changing of the weapon is done
  //	//  when the weapon psprite can do it
  //	//  (read: not in the middle of an attack).
  //	newweapon = (cmd^.buttons&BT_WEAPONMASK)>>BT_WEAPONSHIFT;
  //
  //	if (newweapon == wp_fist
  //	    && player^.weaponowned[wp_chainsaw]
  //	    && !(player^.readyweapon == wp_chainsaw
  //		 && player^.powers[pw_strength]))
  //	{
  //	    newweapon = wp_chainsaw;
  //	}

  //	if ( (crispy^.havessg)
  //	    && newweapon == wp_shotgun
  //	    && player^.weaponowned[wp_supershotgun]
  //	    && player^.readyweapon != wp_supershotgun)
  //	{
  //	    newweapon = wp_supershotgun;
  //	}

  //	if (player^.weaponowned[newweapon]
  //	    && newweapon != player^.readyweapon)
  //	{
  //	    // Do not go to plasma or BFG in shareware,
  //	    //  even if cheated.
  //	    if ((newweapon != wp_plasma
  //		 && newweapon != wp_bfg)
  //		|| (gamemode != shareware) )
  //	    {
  //		player^.pendingweapon = newweapon;
  //	    }
  //	}
  //    }

  // check for use
  If (cmd^.buttons And BT_USE) <> 0 Then Begin
    If (Not player^.usedown) Then Begin
      P_UseLines(player);
      player^.usedown := true;
      // [crispy] "use" button timer
      If (crispy.btusetimer <> 0) Then Begin
        player^.btuse := leveltime;
        player^.btuse_tics := 5 * TICRATE Div 2; // [crispy] 2.5 seconds
      End;
    End;
  End
  Else
    player^.usedown := false;

  // cycle psprites
  P_MovePsprites(player);

  // Counters, time dependend power ups.

  // Strength counts up to diminish fade.
  If (player^.powers[integer(pw_strength)] <> 0) Then
    player^.powers[integer(pw_strength)] := player^.powers[integer(pw_strength)] + 1;

  If (player^.powers[integer(pw_invulnerability)] <> 0) Then
    player^.powers[integer(pw_invulnerability)] := player^.powers[integer(pw_invulnerability)] - 1;

  If (player^.powers[integer(pw_invisibility)] <> 0) Then Begin
    player^.powers[integer(pw_invisibility)] := player^.powers[integer(pw_invisibility)] - 1;
    If (player^.powers[integer(pw_invisibility)] = 0) Then
      player^.mo^.flags := player^.mo^.flags And Not MF_SHADOW;
  End;

  If (player^.powers[integer(pw_infrared)] <> 0) Then
    player^.powers[integer(pw_infrared)] := player^.powers[integer(pw_infrared)] - 1;

  If (player^.powers[integer(pw_ironfeet)] <> 0) Then
    player^.powers[integer(pw_ironfeet)] := player^.powers[integer(pw_ironfeet)] - 1;

  If (player^.damagecount <> 0) Then
    player^.damagecount := player^.damagecount - 1;

  If (player^.bonuscount <> 0) Then
    player^.bonuscount := player^.bonuscount - 1;

  // [crispy] A11Y
  If (a11y_invul_colormap = 0) Then Begin

    If (player^.powers[integer(pw_invulnerability)] <> 0) Or (player^.powers[integer(pw_infrared)] <> 0) Then
      player^.fixedcolormap := 1
    Else
      player^.fixedcolormap := 0;
  End
    // Handling colormaps.
  Else If (player^.powers[integer(pw_invulnerability)] <> 0) Then Begin

    If (player^.powers[integer(pw_invulnerability)] > 4 * 32)
    Or ((player^.powers[integer(pw_invulnerability)] And 8) <> 0) Then
      player^.fixedcolormap := INVERSECOLORMAP
        // [crispy] Visor effect when Invulnerability is fading out
    Else Begin
      If player^.powers[integer(pw_infrared)] <> 0 Then Begin
        player^.fixedcolormap := 1;
      End
      Else Begin
        player^.fixedcolormap := 0;
      End;
    End;
  End
  Else If (player^.powers[integer(pw_infrared)] <> 0) Then Begin
    If (player^.powers[integer(pw_infrared)] > 4 * 32)
    Or ((player^.powers[integer(pw_infrared)] And 8) <> 0) Then Begin
      // almost full bright
      player^.fixedcolormap := 1;
    End
    Else
      player^.fixedcolormap := 0;
  End
  Else
    player^.fixedcolormap := 0;
End;

Procedure P_CalcHeight(player: Pplayer_t);
Var
  angle: int;
  bob: fixed_t;
Begin
  // Regular movement bobbing
  // (needs to be calculated for gun swing
  // even if not on ground)
  // OPTIMIZE: tablify angle
  // Note: a LUT allows for effects
  //  like a ramp with low health.
  player^.bob :=
    FixedMul(player^.mo^.momx, player^.mo^.momx)
    + FixedMul(player^.mo^.momy, player^.mo^.momy);

  player^.bob := player^.bob Shr 2;

  If (player^.bob > MAXBOB) Then player^.bob := MAXBOB;

  // [crispy] variable player view bob
  player^.bob2 := crispy_bobfactor[crispy.bobfactor] * player^.bob Div 4;

  If ((player^.cheats And integer(CF_NOMOMENTUM)) <> 0) Or (Not onground) Then Begin

    player^.viewz := player^.mo^.z + DEFINE_VIEWHEIGHT;

    If (player^.viewz > player^.mo^.ceilingz - 4 * FRACUNIT) Then
      player^.viewz := player^.mo^.ceilingz - 4 * FRACUNIT;

    // [crispy] fix player viewheight in NOMOMENTUM mode
    //player^.viewz := player^.mo^.z + player^.viewheight;
    exit;
  End;

  angle := (FINEANGLES Div 20 * leveltime) And FINEMASK;
  bob := FixedMul(player^.bob2 Div 2, finesine[angle]); // [crispy] variable player view bob


  // move viewheight
  If (player^.playerstate = PST_LIVE) Then Begin

    player^.viewheight := player^.viewheight + player^.deltaviewheight;

    If (player^.viewheight > DEFINE_VIEWHEIGHT) Then Begin
      player^.viewheight := DEFINE_VIEWHEIGHT;
      player^.deltaviewheight := 0;
    End;

    If (player^.viewheight < DEFINE_VIEWHEIGHT Div 2) Then Begin
      player^.viewheight := DEFINE_VIEWHEIGHT Div 2;
      If (player^.deltaviewheight <= 0) Then
        player^.deltaviewheight := 1;
    End;

    If (player^.deltaviewheight <> 0) Then Begin
      player^.deltaviewheight := player^.deltaviewheight + FRACUNIT Div 4;
      If (player^.deltaviewheight = 0) Then
        player^.deltaviewheight := 1;
    End;
  End;
  player^.viewz := player^.mo^.z + player^.viewheight + bob;

  If (player^.viewz > player^.mo^.ceilingz - 4 * FRACUNIT) Then
    player^.viewz := player^.mo^.ceilingz - 4 * FRACUNIT;
End;

End.

