Unit p_pspr;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;
Const
  //
  // Frame flags:
  // handles maximum brightness (torches, muzzle flare, light sources)
  //
  FF_FULLBRIGHT = $8000; // flag in thing->frame
  FF_FRAMEMASK = $7FFF;

  //  psprnum_t -> info_types.pas

Procedure A_Light0(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_Light1(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_Light2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_WeaponReady(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_Lower(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_Raise(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_Punch(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_ReFire(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_FirePistol(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_FireShotgun(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_FireShotgun2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_CheckReload(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_FireCGun(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_GunFlash(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_FireMissile(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_Saw(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_FirePlasma(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_BFGsound(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_FireBFG(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_BFGSpray(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);

Procedure P_SetupPsprites(player: Pplayer_t);

Implementation

Uses
  doomdef, sounds
  , a11y_weapon_pspr
  , d_items
  , m_fixed
  , r_things
  , s_sound
  ;

Const
  LOWERSPEED = FRACUNIT * 6;
  RAISESPEED = FRACUNIT * 6;

  WEAPONBOTTOM = 128 * FRACUNIT;
  WEAPONTOP = 32 * FRACUNIT;


  //
  // P_SetPsprite
  //

Procedure P_SetPsprite(player: Pplayer_t; position: psprnum_t; stnum: statenum_t);
Var
  psp: ^pspdef_t;
  //      state_t*	state;
Begin
  psp := @player^.psprites[position];

  hier gehts weiter ..

  //      do
  //      {
  //  	if (!stnum)
  //  	{
  //  	    // object removed itself
  //  	    psp->state = NULL;
  //  	    break;
  //  	}
  //
  //  	state = &states[stnum];
  //  	psp->state = state;
  //  	psp->tics = state->tics;	// could be 0
  //
  //  	if (state->misc1)
  //  	{
  //  	    // coordinate set
  //  	    psp->sx = state->misc1 << FRACBITS;
  //  	    psp->sy = state->misc2 << FRACBITS;
  //  	    // [crispy] variable weapon sprite bob
  //  	    psp->sx2 = psp->sx;
  //  	    psp->sy2 = psp->sy;
  //  	}
  //
  //  	// Call action routine.
  //  	// Modified handling.
  //  	if (state->action.acp3)
  //  	{
  //  	    state->action.acp3(player->mo, player, psp); // [crispy] let mobj action pointers get called from pspr states
  //  	    if (!psp->state)
  //  		break;
  //  	}
  //
  //  	stnum = psp->state->nextstate;
  //
  //      } while (!psp->tics);
        // an initial state of 0 could cycle through
End;

//
// P_CheckAmmo
// Returns true if there is enough ammo to shoot.
// If not, selects the next weapon to use.
//

Function P_CheckAmmo(player: Pplayer_t): boolean;
Begin
  //    ammotype_t		ammo;
  //    int			count;
  //
  //    ammo = weaponinfo[player->readyweapon].ammo;
  //
  //    // Minimal amount for one shot varies.
  //    if (player->readyweapon == wp_bfg)
  //	count = deh_bfg_cells_per_shot;
  //    else if (player->readyweapon == wp_supershotgun)
  //	count = 2;	// Double barrel.
  //    else
  //	count = 1;	// Regular.
  //
  //    // [crispy] force weapon switch if weapon not owned
  //    // only relevant when removing current weapon with TNTWEAPx cheat
  //    if (!player->weaponowned[player->readyweapon])
  //    {
  //	ammo = am_clip; // [crispy] at least not am_noammo, see below
  //	count = INT_MAX;
  //    }
  //
  //    // Some do not need ammunition anyway.
  //    // Return if current ammunition sufficient.
  //    if (ammo == am_noammo || player->ammo[ammo] >= count)
  //	return true;
  //
  //    // Out of ammo, pick a weapon to change to.
  //    // Preferences are set here.
  //    do
  //    {
  //	if (player->weaponowned[wp_plasma]
  //	    && player->ammo[am_cell]
  //	    && (gamemode != shareware) )
  //	{
  //	    player->pendingweapon = wp_plasma;
  //	}
  //	else if (player->weaponowned[wp_supershotgun]
  //		 && player->ammo[am_shell]>2
  //		 && (crispy->havessg) )
  //	{
  //	    player->pendingweapon = wp_supershotgun;
  //	}
  //	else if (player->weaponowned[wp_chaingun]
  //		 && player->ammo[am_clip])
  //	{
  //	    player->pendingweapon = wp_chaingun;
  //	}
  //	else if (player->weaponowned[wp_shotgun]
  //		 && player->ammo[am_shell])
  //	{
  //	    player->pendingweapon = wp_shotgun;
  //	}
  //	// [crispy] allow to remove the pistol via TNTWEAP2
  //	else if (player->ammo[am_clip] && player->weaponowned[wp_pistol])
  //	{
  //	    player->pendingweapon = wp_pistol;
  //	}
  //	else if (player->weaponowned[wp_chainsaw])
  //	{
  //	    player->pendingweapon = wp_chainsaw;
  //	}
  //	else if (player->weaponowned[wp_missile]
  //		 && player->ammo[am_misl])
  //	{
  //	    player->pendingweapon = wp_missile;
  //	}
  //	else if (player->weaponowned[wp_bfg]
  //		 && player->ammo[am_cell]>40
  //		 && (gamemode != shareware) )
  //	{
  //	    player->pendingweapon = wp_bfg;
  //	}
  //	else
  //	{
  //	    // If everything fails.
  //	    player->pendingweapon = wp_fist;
  //	}
  //
  //    } while (player->pendingweapon == wp_nochange);
  //
  //    // Now set appropriate weapon overlay.
  //    P_SetPsprite (player,
  //		  ps_weapon,
  //		  weaponinfo[player->readyweapon].downstate);
  //
  result := false;
End;

Procedure A_Light0(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  player^.extralight := 0;
End;

Procedure A_Light1(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  player^.extralight := 1;
End;

Procedure A_Light2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  player^.extralight := 2;
End;

//
// A_WeaponReady
// The player can fire the weapon
// or change to another weapon at this time.
// Follows after getting weapon up,
// or after previous attack/fire sequence.
//

Procedure A_WeaponReady(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //   statenum_t	newstate;
  //    int		angle;
  //
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    // get out of attack state
  //    if (player->mo->state == &states[S_PLAY_ATK1]
  //	|| player->mo->state == &states[S_PLAY_ATK2] )
  //    {
  //	P_SetMobjState (player->mo, S_PLAY);
  //    }
  //
  //    if (player->readyweapon == wp_chainsaw
  //	&& psp->state == &states[S_SAW])
  //    {
  //	S_StartSound (player->so, sfx_sawidl); // [crispy] weapon sound source
  //    }
  //
  //    // check for change
  //    //  if player is dead, put the weapon away
  //    if (player->pendingweapon != wp_nochange || !player->health)
  //    {
  //	// change weapon
  //	//  (pending weapon should allready be validated)
  //	newstate = weaponinfo[player->readyweapon].downstate;
  //	P_SetPsprite (player, ps_weapon, newstate);
  //	return;
  //    }
  //
  //    // check for fire
  //    //  the missile launcher and bfg do not auto fire
  //    if (player->cmd.buttons & BT_ATTACK)
  //    {
  //	if ( !player->attackdown
  //	     || (player->readyweapon != wp_missile
  //		 && player->readyweapon != wp_bfg) )
  //	{
  //	    player->attackdown = true;
  //	    P_FireWeapon (player);
  //	    return;
  //	}
  //    }
  //    else
  //	player->attackdown = false;
  //
  //    // bob the weapon based on movement speed
  //    angle = (128*leveltime)&FINEMASK;
  //    psp->sx = FRACUNIT + FixedMul (player->bob, finecosine[angle]);
  //    angle &= FINEANGLES/2-1;
  //    psp->sy = WEAPONTOP + FixedMul (player->bob, finesine[angle]);
End;

Procedure A_Lower(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    psp->sy += LOWERSPEED;
  //
  //    // Is already down.
  //    if (psp->sy < WEAPONBOTTOM )
  //	return;
  //
  //    // Player is dead.
  //    if (player->playerstate == PST_DEAD)
  //    {
  //	psp->sy = WEAPONBOTTOM;
  //
  //	// don't bring weapon back up
  //	return;
  //    }
  //
  //    // The old weapon has been lowered off the screen,
  //    // so change the weapon and start raising it
  //    if (!player->health)
  //    {
  //	// Player is dead, so keep the weapon off screen.
  //	P_SetPsprite (player,  ps_weapon, S_NULL);
  //	return;
  //    }
  //
  //    player->readyweapon = player->pendingweapon;
  //
  //    P_BringUpWeapon (player);
End;

Procedure A_Raise(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //       statenum_t	newstate;
  //
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    psp->sy -= RAISESPEED;
  //
  //    if (psp->sy > WEAPONTOP )
  //	return;
  //
  //    psp->sy = WEAPONTOP;
  //
  //    // The weapon has been raised all the way,
  //    //  so change to the ready state.
  //    newstate = weaponinfo[player->readyweapon].readystate;
  //
  //    P_SetPsprite (player, ps_weapon, newstate);
End;

Procedure A_Punch(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //     angle_t	angle;
  //    int		damage;
  //    int		slope;
  //
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    damage = (P_Random ()%10+1)<<1;
  //
  //    if (player->powers[pw_strength])
  //	damage *= 10;
  //
  //    angle = player->mo->angle;
  //    angle += P_SubRandom() << 18;
  //    slope = P_AimLineAttack (player->mo, angle, MELEERANGE);
  //    P_LineAttack (player->mo, angle, MELEERANGE, slope, damage);
  //
  //    // turn to face target
  //    if (linetarget)
  //    {
  //	S_StartSound (player->so, sfx_punch); // [crispy] weapon sound source
  //	player->mo->angle = R_PointToAngle2 (player->mo->x,
  //					     player->mo->y,
  //					     linetarget->x,
  //					     linetarget->y);
  //    }
End;

Procedure A_ReFire(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    // check for fire
  //    //  (if a weaponchange is pending, let it go through instead)
  //    if ( (player->cmd.buttons & BT_ATTACK)
  //	 && player->pendingweapon == wp_nochange
  //	 && player->health)
  //    {
  //	player->refire++;
  //	P_FireWeapon (player);
  //    }
  //    else
  //    {
  //	player->refire = 0;
  //	P_CheckAmmo (player);
  //    }
End;

Procedure A_FirePistol(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    S_StartSound (player->so, sfx_pistol); // [crispy] weapon sound source
  //
  //    P_SetMobjState (player->mo, S_PLAY_ATK2);
  //    DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo, 1);
  //
  //    P_SetPsprite (player,
  //		  ps_flash,
  //		  weaponinfo[player->readyweapon].flashstate);
  //
  //    P_BulletSlope (player->mo);
  //    P_GunShot (player->mo, !player->refire);
  //
  //    A_Recoil (player);
End;

Procedure A_FireShotgun(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //   int		i;
  //
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    S_StartSound (player->so, sfx_shotgn); // [crispy] weapon sound source
  //    P_SetMobjState (player->mo, S_PLAY_ATK2);
  //
  //    DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo, 1);
  //
  //    P_SetPsprite (player,
  //		  ps_flash,
  //		  weaponinfo[player->readyweapon].flashstate);
  //
  //    P_BulletSlope (player->mo);
  //
  //    for (i=0 ; i<7 ; i++)
  //	P_GunShot (player->mo, false);
  //
  //    A_Recoil (player);
End;

Procedure A_FireShotgun2(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //   int		i;
  //    angle_t	angle;
  //    int		damage;
  //
  //
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    S_StartSound (player->so, sfx_dshtgn); // [crispy] weapon sound source
  //    P_SetMobjState (player->mo, S_PLAY_ATK2);
  //
  //    DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo, 2);
  //
  //    P_SetPsprite (player,
  //		  ps_flash,
  //		  weaponinfo[player->readyweapon].flashstate);
  //
  //    P_BulletSlope (player->mo);
  //
  //    for (i=0 ; i<20 ; i++)
  //    {
  //	damage = 5*(P_Random ()%3+1);
  //	angle = player->mo->angle;
  //	angle += P_SubRandom() << ANGLETOFINESHIFT;
  //	P_LineAttack (player->mo,
  //		      angle,
  //		      MISSILERANGE,
  //		      bulletslope + (P_SubRandom() << 5), damage);
  //    }
  //
  //    A_Recoil (player);
End;

Procedure A_CheckReload(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  P_CheckAmmo(player);
  //#if 0
  //    if (player->ammo[am_shell]<2)
  //	P_SetPsprite (player, ps_weapon, S_DSNR1);
  //#endif
End;

Procedure A_FireCGun(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    S_StartSound (player->so, sfx_pistol); // [crispy] weapon sound source
  //
  //    if (!player->ammo[weaponinfo[player->readyweapon].ammo])
  //	return;
  //
  //    P_SetMobjState (player->mo, S_PLAY_ATK2);
  //    DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo, 1);
  //
  //    P_SetPsprite (player,
  //		  ps_flash,
  //		  weaponinfo[player->readyweapon].flashstate
  //		  + psp->state
  //		  - &states[S_CHAIN1] );
  //
  //    P_BulletSlope (player->mo);
  //
  //    P_GunShot (player->mo, !player->refire);
  //
  //    A_Recoil (player);
End;

Procedure A_GunFlash(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    P_SetMobjState (player->mo, S_PLAY_ATK2);
  //    P_SetPsprite (player,ps_flash,weaponinfo[player->readyweapon].flashstate);
End;

Procedure A_FireMissile(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //  if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //  DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo, 1);
  //  P_SpawnPlayerMissile (player->mo, MT_ROCKET);
End;

Procedure A_Saw(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //    angle_t	angle;
  //    int		damage;
  //    int		slope;
  //
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    damage = 2*(P_Random ()%10+1);
  //    angle = player->mo->angle;
  //    angle += P_SubRandom() << 18;
  //
  //    // use meleerange + 1 se the puff doesn't skip the flash
  //    slope = P_AimLineAttack (player->mo, angle, MELEERANGE+1);
  //    P_LineAttack (player->mo, angle, MELEERANGE+1, slope, damage);
  //
  //    A_Recoil (player);
  //
  //    if (!linetarget)
  //    {
  //	S_StartSound (player->so, sfx_sawful); // [crispy] weapon sound source
  //	return;
  //    }
  //    S_StartSound (player->so, sfx_sawhit); // [crispy] weapon sound source
  //
  //    // turn to face target
  //    angle = R_PointToAngle2 (player->mo->x, player->mo->y,
  //			     linetarget->x, linetarget->y);
  //    if (angle - player->mo->angle > ANG180)
  //    {
  //	if ((signed int) (angle - player->mo->angle) < -ANG90/20)
  //	    player->mo->angle = angle + ANG90/21;
  //	else
  //	    player->mo->angle -= ANG90/20;
  //    }
  //    else
  //    {
  //	if (angle - player->mo->angle > ANG90/20)
  //	    player->mo->angle = angle - ANG90/21;
  //	else
  //	    player->mo->angle += ANG90/20;
  //    }
  //    player->mo->flags |= MF_JUSTATTACKED;
End;

Procedure A_FirePlasma(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //  if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo, 1);
  //
  //    P_SetPsprite (player,
  //		  ps_flash,
  //		  weaponinfo[player->readyweapon].flashstate+(P_Random ()&1) );
  //
  //    P_SpawnPlayerMissile (player->mo, MT_PLASMA);
End;

Procedure A_BFGsound(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If Not assigned(player) Then exit; // [crispy] let pspr action pointers get called from mobj states
  S_StartSound(player^.mo, sfx_bfg); // [crispy] intentionally not weapon sound source
End;

Procedure A_FireBFG(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //      if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo,
  //                 deh_bfg_cells_per_shot);
  //    P_SpawnPlayerMissile (player->mo, MT_BFG);
End;

Procedure A_BFGSpray(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  //    int			i;
  //    int			j;
  //    int			damage;
  //    angle_t		an;
  //
  //    // offset angles from its attack angle
  //    for (i=0 ; i<40 ; i++)
  //    {
  //	an = mo->angle - ANG90/2 + ANG90/40*i;
  //
  //	// mo->target is the originator (player)
  //	//  of the missile
  //	P_AimLineAttack (mo->target, an, 16*64*FRACUNIT);
  //
  //	if (!linetarget)
  //	    continue;
  //
  //	P_SpawnMobj (linetarget->x,
  //		     linetarget->y,
  //		     linetarget->z + (linetarget->height>>2),
  //		     MT_EXTRABFG);
  //
  //	damage = 0;
  //	for (j=0;j<15;j++)
  //	    damage += (P_Random()&7) + 1;
  //
  //	P_DamageMobj (linetarget, mo->target,mo->target, damage);
  //    }
End;

//
// P_BringUpWeapon
// Starts bringing the pending weapon up
// from the bottom of the screen.
// Uses player
//

Procedure P_BringUpWeapon(player: Pplayer_t);
Var
  newstate: statenum_t;
Begin
  If (player^.pendingweapon = wp_nochange) Then Begin
    player^.pendingweapon := player^.readyweapon;
  End;

  If (player^.pendingweapon = wp_chainsaw) Then Begin
    S_StartSound(player^.mo, sfx_sawup); // [crispy] intentionally not weapon sound source
  End;

  (*
      // [crispy] play "power up" sound when selecting berserk fist...
      if (player->pendingweapon == wp_fist && player->powers[pw_strength])
      {
   // [crispy] ...only if not playing already
   if (player == &players[consoleplayer])
   {
       S_StartSoundOnce (NULL, sfx_getpow);
   }
      }
  *)

  newstate := weaponinfo[integer(player^.pendingweapon)].upstate;

  player^.pendingweapon := wp_nochange;
  player^.psprites[ps_weapon].sy := WEAPONBOTTOM;

  P_SetPsprite(player, ps_weapon, newstate);
End;

//
// P_SetupPsprites
// Called at start of level for each player.
//

Procedure P_SetupPsprites(player: Pplayer_t);
Var
  i: int;
Begin
  // remove all psprites
  For i := 0 To integer(NUMSPRITES) - 1 Do Begin
    player^.psprites[psprnum_t(i)].state := Nil;
  End;

  // spawn the gun
  player^.pendingweapon := player^.readyweapon;
  P_BringUpWeapon(player);

  // [crispy] A11Y
  If a11y_weapon_pspr_ <> 0 Then Begin
    numrpsprites := integer(NUMSPRITES);
  End
  Else Begin
    numrpsprites := integer(NUMSPRITES) - 1;
  End;
End;

End.

