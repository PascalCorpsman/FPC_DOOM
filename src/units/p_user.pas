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
  tables, doomdef
  , d_player, d_ticcmd
  , g_game
  , m_fixed
  , p_local, p_tick, p_mobj, p_spec, p_pspr
  , r_main
  ;

Const
  // 16 pixels of bob
  MAXBOB = $100000;

  // [crispy] variable player view bob
  crispy_bobfactor: Array[0..2] Of fixed_t = (4, 3, 0);

Var
  onground: boolean;

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

  //    // [crispy] fast polling
  //    if (player == &players[consoleplayer])
  //    {
  //        localview.ticangle += localview.ticangleturn << 16;
  //        localview.ticangleturn = 0;
  //    }
  //
  //    if (cmd^.forwardmove && onground)
  //	P_Thrust (player, player^.mo^.angle, cmd^.forwardmove*2048);
  //    else
  //    // [crispy] in-air movement is only possible with jumping enabled
  //    if (cmd^.forwardmove && critical^.jump)
  //        P_Thrust (player, player^.mo^.angle, FRACUNIT >> 8);
  //
  //    if (cmd^.sidemove && onground)
  //	P_Thrust (player, player^.mo^.angle-ANG90, cmd^.sidemove*2048);
  //    else
  //    // [crispy] in-air movement is only possible with jumping enabled
  //    if (cmd^.sidemove && critical^.jump)
  //            P_Thrust(player, player^.mo^.angle, FRACUNIT >> 8);
  //
  //    if ( (cmd^.forwardmove || cmd^.sidemove)
  //	 && player^.mo^.state == &states[S_PLAY] )
  //    {
  //	P_SetMobjState (player^.mo, S_PLAY_RUN1);
  //    }
  //
  //    // [crispy] apply lookdir delta
  //    look = cmd^.lookfly & 15;
  //    if (look > 7)
  //    {
  //        look -= 16;
  //    }
  //    if (look)
  //    {
  //        if (look == TOCENTER)
  //        {
  //            player^.centering = true;
  //        }
  //        else
  //        {
  //            cmd^.lookdir = MLOOKUNIT * 5 * look;
  //        }
  //    }
  //    if (!menuactive && !demoplayback)
  //    {
  //	player^.lookdir = BETWEEN(-LOOKDIRMIN * MLOOKUNIT,
  //	                          LOOKDIRMAX * MLOOKUNIT,
  //	                          player^.lookdir + cmd^.lookdir);
  //    }
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
    //        if (player^.lookdir > 0)
    //        {
    //            player^.lookdir -= 8 * MLOOKUNIT;
    //        }
    //        else if (player^.lookdir < 0)
    //        {
    //            player^.lookdir += 8 * MLOOKUNIT;
    //        }
    //        if (abs(player^.lookdir) < 8 * MLOOKUNIT)
    //        {
    //            player^.lookdir = 0;
    //            player^.centering = false;
    //        }
  End;

  // [crispy] weapon recoil pitch
  If (player^.recoilpitch <> 0) Then Begin
    //        if (player^.recoilpitch > 0)
    //        {
    //            player^.recoilpitch -= 1;
    //        }
    //        else if (player^.recoilpitch < 0)
    //        {
    //            player^.recoilpitch += 1;
    //        }
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
//    if (cmd^.arti)
//    {
//        if ((cmd^.arti & AFLAG_JUMP) && onground &&
//            player^.viewz < player^.mo^.ceilingz-16*FRACUNIT &&
//            !player^.jumpTics)
//        {
//            // [crispy] Hexen sets 9; Strife adds 8
//            player^.mo^.momz = (7 + critical^.jump) * FRACUNIT;
//            player^.jumpTics = 18;
//            // [NS] Jump sound.
//            S_StartSoundOptional(player^.mo, sfx_pljump, -1);
//        }
//    }

    // Check for weapon change.
//
//    // A special event has no other buttons.
//    if (cmd^.buttons & BT_SPECIAL)
//	cmd^.buttons = 0;
//
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
//
//	if ( (crispy^.havessg)
//	    && newweapon == wp_shotgun
//	    && player^.weaponowned[wp_supershotgun]
//	    && player^.readyweapon != wp_supershotgun)
//	{
//	    newweapon = wp_supershotgun;
//	}
//
//
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
//
//    // check for use
//    if (cmd^.buttons & BT_USE)
//    {
//	if (!player^.usedown)
//	{
//	    P_UseLines (player);
//	    player^.usedown = true;
//	    // [crispy] "use" button timer
//	    if (crispy^.btusetimer)
//	    {
//		player^.btuse = leveltime;
//		player^.btuse_tics = 5*TICRATE/2; // [crispy] 2.5 seconds
//	    }
//	}
//    }
//    else
//	player^.usedown = false;

    // cycle psprites
  P_MovePsprites(player);

  //    // Counters, time dependend power ups.
  //
  //    // Strength counts up to diminish fade.
  //    if (player^.powers[pw_strength])
  //	player^.powers[pw_strength]++;
  //
  //    if (player^.powers[pw_invulnerability])
  //	player^.powers[pw_invulnerability]--;
  //
  //    if (player^.powers[pw_invisibility])
  //	if (! --player^.powers[pw_invisibility] )
  //	    player^.mo^.flags &= ~MF_SHADOW;
  //
  //    if (player^.powers[pw_infrared])
  //	player^.powers[pw_infrared]--;
  //
  //    if (player^.powers[pw_ironfeet])
  //	player^.powers[pw_ironfeet]--;
  //
  //    if (player^.damagecount)
  //	player^.damagecount--;
  //
  //    if (player^.bonuscount)
  //	player^.bonuscount--;
  //
  //
  //    // [crispy] A11Y
  //    if (!a11y_invul_colormap)
  //    {
  //	if (player^.powers[pw_invulnerability] || player^.powers[pw_infrared])
  //	    player^.fixedcolormap = 1;
  //	else
  //	    player^.fixedcolormap = 0;
  //    }
  //    else
  //    // Handling colormaps.
  //    if (player^.powers[pw_invulnerability])
  //    {
  //	if (player^.powers[pw_invulnerability] > 4*32
  //	    || (player^.powers[pw_invulnerability]&8) )
  //	    player^.fixedcolormap = INVERSECOLORMAP;
  //	else
  //	    // [crispy] Visor effect when Invulnerability is fading out
  //	    player^.fixedcolormap = player^.powers[pw_infrared] ? 1 : 0;
  //    }
  //    else if (player^.powers[pw_infrared])
  //    {
  //	if (player^.powers[pw_infrared] > 4*32
  //	    || (player^.powers[pw_infrared]&8) )
  //	{
  //	    // almost full bright
  //	    player^.fixedcolormap = 1;
  //	}
  //	else
  //	    player^.fixedcolormap = 0;
  //    }
  //    else
  //	player^.fixedcolormap = 0;
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


  //    // move viewheight
  //    if (player->playerstate == PST_LIVE)
  //    {
  //	player->viewheight += player->deltaviewheight;
  //
  //	if (player->viewheight > DEFINE_VIEWHEIGHT)
  //	{
  //	    player->viewheight = DEFINE_VIEWHEIGHT;
  //	    player->deltaviewheight = 0;
  //	}
  //
  //	if (player->viewheight < DEFINE_VIEWHEIGHT/2)
  //	{
  //	    player->viewheight = DEFINE_VIEWHEIGHT/2;
  //	    if (player->deltaviewheight <= 0)
  //		player->deltaviewheight = 1;
  //	}
  //
  //	if (player->deltaviewheight)
  //	{
  //	    player->deltaviewheight += FRACUNIT/4;
  //	    if (!player->deltaviewheight)
  //		player->deltaviewheight = 1;
  //	}
  //    }
  player^.viewz := player^.mo^.z + player^.viewheight + bob;

  If (player^.viewz > player^.mo^.ceilingz - 4 * FRACUNIT) Then
    player^.viewz := player^.mo^.ceilingz - 4 * FRACUNIT;
End;

End.

