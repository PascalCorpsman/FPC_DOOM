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

Procedure P_MovePsprites(player: Pplayer_t);

Implementation

Uses
  doomdef, sounds, a11y_weapon_pspr, info, tables, doomstat
  , d_items, d_event, deh_misc, d_mode
  , m_fixed, m_random
  , p_mobj, p_tick, p_enemy, p_local, p_map
  , r_things
  , s_sound
  ;

Const
  LOWERSPEED = FRACUNIT * 6;
  RAISESPEED = FRACUNIT * 6;

  WEAPONBOTTOM = 128 * FRACUNIT;
  WEAPONTOP = 32 * FRACUNIT;

  // [crispy] weapon recoil pitch values
  recoil_values: Array Of int = (
    0, // wp_fist
    4, // wp_pistol
    8, // wp_shotgun
    4, // wp_chaingun
    16, // wp_missile
    4, // wp_plasma
    20, // wp_bfg
    -2, // wp_chainsaw
    16 // wp_supershotgun
    );

Var
  bulletslope: fixed_t;

  //
  // P_SetPsprite
  //

Procedure P_SetPsprite(player: Pplayer_t; position: psprnum_t; stnum: statenum_t);
Var
  psp: ^pspdef_t;
  state: ^state_t;
Begin
  psp := @player^.psprites[position];
  //      do
  Repeat

    If (stnum = S_NULL) Then Begin
      // object removed itself
      psp^.state := Nil;
      break;
    End;

    state := @states[integer(stnum)];
    psp^.state := state;
    psp^.tics := state^.tics; // could be 0

    If (state^.misc1 <> 0) Then Begin
      // coordinate set
      psp^.sx := state^.misc1 Shl FRACBITS;
      psp^.sy := state^.misc2 Shl FRACBITS;
      // [crispy] variable weapon sprite bob
      psp^.sx2 := psp^.sx;
      psp^.sy2 := psp^.sy;
    End;

    // Call action routine.
    // Modified handling.
    If assigned(state^.action.acp3) Then Begin
      state^.action.acp3(player^.mo, player, psp); // [crispy] let mobj action pointers get called from pspr states
      If (psp^.state = Nil) Then
        break;
    End;

    stnum := psp^.state^.nextstate;

    //      } while (!psp->tics);
  Until psp^.tics <> 0;
  // an initial state of 0 could cycle through
End;

//
// P_CheckAmmo
// Returns true if there is enough ammo to shoot.
// If not, selects the next weapon to use.
//

Function P_CheckAmmo(player: Pplayer_t): boolean;
Var
  ammo: ammotype_t;
  count: int;
Begin

  ammo := weaponinfo[integer(player^.readyweapon)].ammo;

  // Minimal amount for one shot varies.
  If (player^.readyweapon = wp_bfg) Then
    count := deh_bfg_cells_per_shot
  Else If (player^.readyweapon = wp_supershotgun) Then
    count := 2 // Double barrel.
  Else
    count := 1; // Regular.

  // [crispy] force weapon switch if weapon not owned
  // only relevant when removing current weapon with TNTWEAPx cheat
  If (Not player^.weaponowned[player^.readyweapon]) Then Begin
    ammo := am_clip; // [crispy] at least not am_noammo, see below
    count := INT_MAX;
  End;

  // Some do not need ammunition anyway.
  // Return if current ammunition sufficient.
  If (ammo = am_noammo) Or (player^.ammo[integer(ammo)] >= count) Then Begin
    result := true;
    exit;
  End;

  // Out of ammo, pick a weapon to change to.
  // Preferences are set here.
  Repeat
    If (player^.weaponowned[wp_plasma]
      ) And (player^.ammo[integer(am_cell)] <> 0)
    And ((gamemode <> shareware)) Then Begin
      player^.pendingweapon := wp_plasma;
    End
    Else If (player^.weaponowned[wp_supershotgun])
      And (player^.ammo[integer(am_shell)] > 2)
    And (crispy.havessg) Then Begin
      player^.pendingweapon := wp_supershotgun;
    End
    Else If (player^.weaponowned[wp_chaingun])
      And (player^.ammo[integer(am_clip)] <> 0) Then Begin
      player^.pendingweapon := wp_chaingun;
    End
    Else If (player^.weaponowned[wp_shotgun])
      And (player^.ammo[integer(am_shell)] <> 0) Then Begin
      player^.pendingweapon := wp_shotgun;
    End
      // [crispy] allow to remove the pistol via TNTWEAP2
    Else If (player^.ammo[integer(am_clip)] <> 0) And (player^.weaponowned[wp_pistol]) Then Begin
      player^.pendingweapon := wp_pistol;
    End
    Else If (player^.weaponowned[wp_chainsaw]) Then Begin
      player^.pendingweapon := wp_chainsaw;
    End
    Else If (player^.weaponowned[wp_missile])
      And (player^.ammo[integer(am_misl)] <> 0) Then Begin
      player^.pendingweapon := wp_missile;
    End
    Else If (player^.weaponowned[wp_bfg])
      And (player^.ammo[integer(am_cell)] > 40)
    And (gamemode <> shareware) Then Begin
      player^.pendingweapon := wp_bfg;
    End
    Else Begin
      // If everything fails.
      player^.pendingweapon := wp_fist;
    End;
    //    } while (player^.pendingweapon == wp_nochange);
  Until (player^.pendingweapon <> wp_nochange);

  // Now set appropriate weapon overlay.
  P_SetPsprite(player,
    ps_weapon,
    weaponinfo[integer(player^.readyweapon)].downstate);

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

Procedure P_FireWeapon(player: Pplayer_t);
Var
  newstate: statenum_t;
Begin
  If (Not P_CheckAmmo(player)) Then exit;

  P_SetMobjState(player^.mo, S_PLAY_ATK1);
  newstate := weaponinfo[integer(player^.readyweapon)].atkstate;
  P_SetPsprite(player, ps_weapon, newstate);
  If (Not crispy.fistisquit) Or
    ((player^.readyweapon <> wp_fist) And (crispy.fistisquit))
  Then Begin
    P_NoiseAlert(player^.mo, player^.mo);
  End;
End;

//
// A_WeaponReady
// The player can fire the weapon
// or change to another weapon at this time.
// Follows after getting weapon up,
// or after previous attack/fire sequence.
//

Procedure A_WeaponReady(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Var
  newstate: statenum_t;
  angle: int;
Begin
  If (player = Nil) Then exit; // [crispy] let pspr action pointers get called from mobj states
  // get out of attack state
  If (player^.mo^.state = @states[integer(S_PLAY_ATK1)])
  Or (player^.mo^.state = @states[integer(S_PLAY_ATK2)]) Then Begin
    P_SetMobjState(player^.mo, S_PLAY);
  End;

  If (player^.readyweapon = wp_chainsaw)
    And (psp^.state = @states[integer(S_SAW)]) Then Begin
    S_StartSound(player^.so, sfx_sawidl); // [crispy] weapon sound source
  End;

  // check for change
  //  if player is dead, put the weapon away
  If (player^.pendingweapon <> wp_nochange) Or (player^.health = 0) Then Begin
    // change weapon
    //  (pending weapon should allready be validated)
    newstate := weaponinfo[integer(player^.readyweapon)].downstate;
    P_SetPsprite(player, ps_weapon, newstate);
    exit;
  End;

  // check for fire
  //  the missile launcher and bfg do not auto fire
  If (player^.cmd.buttons And BT_ATTACK) <> 0 Then Begin
    If (Not player^.attackdown) Or
      ((player^.readyweapon <> wp_missile) And (player^.readyweapon <> wp_bfg)) Then Begin
      player^.attackdown := true;
      P_FireWeapon(player);
      exit;
    End;
  End
  Else Begin
    player^.attackdown := false;
  End;

  // bob the weapon based on movement speed
  angle := (128 * leveltime) And FINEMASK;
  psp^.sx := FRACUNIT + FixedMul(player^.bob, finecosine[angle]);
  angle := angle And (FINEANGLES Div 2 - 1);
  psp^.sy := WEAPONTOP + FixedMul(player^.bob, finesine[angle]);
End;

Procedure A_Lower(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  Raise Exception.Create('Port me.');
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
Var
  newstate: statenum_t;
Begin
  If (player = Nil) Then exit; // [crispy] let pspr action pointers get called from mobj states
  psp^.sy := psp^.sy - RAISESPEED;
  If (psp^.sy > WEAPONTOP) Then exit;


  psp^.sy := WEAPONTOP;

  // The weapon has been raised all the way,
  //  so change to the ready state.
  newstate := weaponinfo[integer(player^.readyweapon)].readystate;

  P_SetPsprite(player, ps_weapon, newstate);
End;

Procedure A_Punch(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  Raise Exception.Create('Port me.');
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

//
// A_ReFire
// The player can re-fire the weapon
// without lowering it entirely.
//

Procedure A_ReFire(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If (player = Nil) Then exit; // [crispy] let pspr action pointers get called from mobj states
  // check for fire
  //  (if a weaponchange is pending, let it go through instead)
  If ((player^.cmd.buttons And BT_ATTACK) <> 0)
    And (player^.pendingweapon = wp_nochange)
    And (player^.health <> 0) Then Begin
    player^.refire := player^.refire + 1;
    P_FireWeapon(player);
  End
  Else Begin
    player^.refire := 0;
    P_CheckAmmo(player);
  End;
End;

// Doom does not check the bounds of the ammo array.  As a result,
// it is possible to use an ammo type > 4 that overflows into the
// maxammo array and affects that instead.  Through dehacked, for
// example, it is possible to make a weapon that decreases the max
// number of ammo for another weapon.  Emulate this.

Procedure DecreaseAmmo(player: Pplayer_t; ammonum, amount: int);
Begin
  If (ammonum < integer(NUMAMMO)) Then Begin
    player^.ammo[ammonum] := player^.ammo[ammonum] - amount;
    // [crispy] never allow less than zero ammo
    If (player^.ammo[ammonum] < 0) Then Begin
      player^.ammo[ammonum] := 0;
    End;
  End
  Else Begin
    player^.maxammo[ammonum - integer(NUMAMMO)] := player^.maxammo[ammonum - integer(NUMAMMO)] - amount;
  End;
End;

//
// P_BulletSlope
// Sets a slope so a near miss is at aproximately
// the height of the intended target
//

Procedure P_BulletSlope(mo: Pmobj_t);
Var
  an: angle_t;
Begin

  If (critical^.freeaim = FREEAIM_DIRECT) Then Begin
    bulletslope := PLAYER_SLOPE(mo^.player);
  End
  Else Begin
    // see which target is to be aimed at
    an := mo^.angle;
    bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);

    If (linetarget = Nil) Then Begin
      an := angle_t(an + 1 Shl 26);
      bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);
      If (linetarget = Nil) Then Begin
        an := angle_t(an - 2 Shl 26);
        bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);
        If (linetarget = Nil) And (critical^.freeaim = FREEAIM_BOTH) Then Begin
          bulletslope := PLAYER_SLOPE(mo^.player);
        End;
      End;
    End;
  End;
End;

//
// P_GunShot
//

Procedure P_GunShot(mo: Pmobj_t; accurate: boolean);
Var
  angle: angle_t;
  damage: int;
Begin
  damage := 5 * (P_Random() Mod 3 + 1);
  angle := mo^.angle;

  If (Not accurate) Then
    angle := angle + P_SubRandom() Shl 18;

  P_LineAttack(mo, angle, MISSILERANGE, bulletslope, damage);
End;

// [crispy] add weapon recoil pitch

Procedure A_Recoil(player: Pplayer_t);
Begin
  If assigned(player) And (crispy.pitch <> 0) Then Begin
    player^.recoilpitch := recoil_values[integer(player^.readyweapon)];
  End;
End;

Procedure A_FirePistol(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  If (player = Nil) Then exit; // [crispy] let pspr action pointers get called from mobj states
  S_StartSound(player^.so, sfx_pistol); // [crispy] weapon sound source

  P_SetMobjState(player^.mo, S_PLAY_ATK2);
  DecreaseAmmo(player, integer(weaponinfo[integer(player^.readyweapon)].ammo), 1);

  P_SetPsprite(player,
    ps_flash,
    weaponinfo[integer(player^.readyweapon)].flashstate);

  P_BulletSlope(player^.mo);
  P_GunShot(player^.mo, player^.refire = 0);

  A_Recoil(player);
End;

Procedure A_FireShotgun(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  Raise Exception.Create('Port me.');
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
  Raise Exception.Create('Port me.');
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
  Raise Exception.Create('Port me.');
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
  Raise Exception.Create('Port me.');
  //    if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    P_SetMobjState (player->mo, S_PLAY_ATK2);
  //    P_SetPsprite (player,ps_flash,weaponinfo[player->readyweapon].flashstate);
End;

Procedure A_FireMissile(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  Raise Exception.Create('Port me.');
  //  if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //  DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo, 1);
  //  P_SpawnPlayerMissile (player->mo, MT_ROCKET);
End;

Procedure A_Saw(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  Raise Exception.Create('Port me.');
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
  Raise Exception.Create('Port me.');
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
  Raise Exception.Create('Port me.');
  //      if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //    DecreaseAmmo(player, weaponinfo[player->readyweapon].ammo,
  //                 deh_bfg_cells_per_shot);
  //    P_SpawnPlayerMissile (player->mo, MT_BFG);
End;

Procedure A_BFGSpray(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  Raise Exception.Create('Port me.');
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
  For i := 0 To integer(NUMPSPRITES) - 1 Do Begin
    player^.psprites[psprnum_t(i)].state := Nil;
  End;

  // spawn the gun
  player^.pendingweapon := player^.readyweapon;
  P_BringUpWeapon(player);

  // [crispy] A11Y
  If a11y_weapon_pspr_ <> 0 Then Begin
    numrpsprites := integer(NUMPSPRITES);
  End
  Else Begin
    numrpsprites := integer(NUMPSPRITES) - 1;
  End;
End;

//
// P_MovePsprites
// Called every tic by player thinking routine.
//

Procedure P_MovePsprites(player: Pplayer_t);
Var
  i: int;
  psp: ^pspdef_t;
Begin
  For i := 0 To integer(NUMPSPRITES) - 1 Do Begin
    psp := @player^.psprites[psprnum_t(i)];
    //    psp := @sprites[i];

    // a null state means not active
    If (psp^.state <> Nil) Then Begin

      // drop tic count and possibly change state

      // a -1 tic count never changes
      If (psp^.tics <> -1) Then Begin
        psp^.tics := psp^.tics - 1;
        If (psp^.tics = 0) Then
          P_SetPsprite(player, psprnum_t(i), psp^.state^.nextstate);
      End;
    End;
  End;

  player^.psprites[ps_flash].sx := player^.psprites[ps_weapon].sx;
  player^.psprites[ps_flash].sy := player^.psprites[ps_weapon].sy;

  // [crispy] apply bobbing (or centering) to the player's weapon sprite
  psp := @player^.psprites[psprnum_t(0)];
  psp^.sx2 := psp^.sx;
  psp^.sy2 := psp^.sy;
  If (psp^.state <> Nil) And ((crispy.bobfactor <> 0) Or (crispy.centerweapon <> 0) Or (crispy.uncapped <> 0)) Then Begin
    Raise exception.create('Need port.');
    // [crispy] don't center vertically during lowering and raising states
   //	if (psp^.state^.misc1 ||
   //	    psp^.state^.action.acp3 == (actionf_p3)A_Lower ||
   //	    psp^.state^.action.acp3 == (actionf_p3)A_Raise)
   //	{
   //	}
   //	else
   //	// [crispy] not attacking means idle
   //	if (!player^.attackdown ||
   //	    crispy^.centerweapon == CENTERWEAPON_BOB)
   //	{
   //		angle_t angle = (128 * leveltime) & FINEMASK;
   //		psp^.sx2 = FRACUNIT + FixedMul(player^.bob2, finecosine[angle]);
   //		angle &= FINEANGLES / 2 - 1;
   //		psp^.sy2 = WEAPONTOP + FixedMul(player^.bob2, finesine[angle]);
   //	}
   //	else
   //	// [crispy] center the weapon sprite horizontally and push up vertically
   //	if (crispy^.centerweapon == CENTERWEAPON_CENTER)
   //	{
   //		psp^.sx2 = FRACUNIT;
   //		psp^.sy2 = WEAPONTOP;
   //	}
  End;

  player^.psprites[ps_flash].sx2 := psp^.sx2;
  player^.psprites[ps_flash].sy2 := psp^.sy2;
End;

End.

