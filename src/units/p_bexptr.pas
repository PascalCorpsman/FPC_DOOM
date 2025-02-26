Unit p_bexptr;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Procedure A_Die(actor: Pmobj_t);
Procedure A_BetaSkullAttack(actor: Pmobj_t);
Procedure A_Detonate(mo: Pmobj_t);

Procedure A_Stop(actor: Pmobj_t);
Procedure A_Mushroom(actor: Pmobj_t);

Procedure A_FireOldBFG(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Procedure A_RandomJump(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);

Implementation

Uses
  sounds
  , m_random
  , p_map, p_inter, p_enemy
  , s_sound
  ;

// killough 11/98: kill an object

Procedure A_Die(actor: Pmobj_t);
Begin
  P_DamageMobj(actor, Nil, Nil, actor^.health);
End;

//
// A_BetaSkullAttack()
// killough 10/98: this emulates the beta version's lost soul attacks
//

Procedure A_BetaSkullAttack(actor: Pmobj_t);
Var
  damage: int;
Begin
  If (actor^.target = Nil) Or (actor^.target^._type = MT_SKULL) Then exit;

  S_StartSound(actor, actor^.info^.attacksound);
  A_FaceTarget(actor);
  damage := (P_Random((* pr_skullfly *)) Mod 8 + 1) * actor^.info^.damage;
  P_DamageMobj(actor^.target, actor, actor, damage);
End;

//
// A_Detonate
// killough 8/9/98: same as A_Explode, except that the damage is variable
//

Procedure A_Detonate(mo: Pmobj_t);
Begin
  P_RadiusAttack(mo, mo^.target, mo^.info^.damage);
End;

Procedure A_Stop(actor: Pmobj_t);
Begin
  actor^.momx := 0;
  actor^.momy := 0;
  actor^.momz := 0;
End;

//
// killough 9/98: a mushroom explosion effect, sorta :)
// Original idea: Linguica
//

Procedure A_Mushroom(actor: Pmobj_t);
Begin
  Raise Exception.Create('Port me.');

  //  int i, j, n = actor->info->damage;
  //
  //  // Mushroom parameters are part of code pointer's state
  //  fixed_t misc1 = actor->state->misc1 ? actor->state->misc1 : FRACUNIT*4;
  //  fixed_t misc2 = actor->state->misc2 ? actor->state->misc2 : FRACUNIT/2;
  //
  //  A_Explode(actor);               // make normal explosion
  //
  //  for (i = -n; i <= n; i += 8)    // launch mushroom cloud
  //    for (j = -n; j <= n; j += 8)
  //      {
  //	mobj_t target = *actor, *mo;
  //	target.x += i << FRACBITS;    // Aim in many directions from source
  //	target.y += j << FRACBITS;
  //	target.z += P_AproxDistance(i,j) * misc1;           // Aim fairly high
  //	mo = P_SpawnMissile(actor, &target, MT_FATSHOT);    // Launch fireball
  //	mo->momx = FixedMul(mo->momx, misc2);
  //	mo->momy = FixedMul(mo->momy, misc2);               // Slow down a bit
  //	mo->momz = FixedMul(mo->momz, misc2);
  //	mo->flags &= ~MF_NOGRAVITY;   // Make debris fall under gravity
  //      }
End;

//
// A_FireOldBFG
//
// This function emulates Doom's Pre-Beta BFG
// By Lee Killough 6/6/98, 7/11/98, 7/19/98, 8/20/98
//
// This code may not be used in other mods without appropriate credit given.
// Code leeches will be telefragged.

Procedure A_FireOldBFG(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  Raise Exception.Create('Port me.');

  //  int type = MT_PLASMA1;
  //  extern void P_CheckMissileSpawn (mobj_t* th);
  //
  //  if (!player) return; // [crispy] let pspr action pointers get called from mobj states
  //
  //  player->ammo[weaponinfo[player->readyweapon].ammo]--;
  //
  //  player->extralight = 2;
  //
  //  do
  //    {
  //      mobj_t *th, *mo = player->mo;
  //      angle_t an = mo->angle;
  //      angle_t an1 = ((P_Random(/* pr_bfg */)&127) - 64) * (ANG90/768) + an;
  //      angle_t an2 = ((P_Random(/* pr_bfg */)&127) - 64) * (ANG90/640) + ANG90;
  ////    extern int autoaim;
  //
  ////    if (autoaim || !beta_emulation)
  //	{
  //	  // killough 8/2/98: make autoaiming prefer enemies
  //	  int mask = 0;//MF_FRIEND;
  //	  fixed_t slope;
  //	  if (critical->freeaim == FREEAIM_DIRECT)
  //	    slope = PLAYER_SLOPE(player);
  //	  else
  //	  do
  //	    {
  //	      slope = P_AimLineAttack(mo, an, 16*64*FRACUNIT);//, mask);
  //	      if (!linetarget)
  //		slope = P_AimLineAttack(mo, an += 1<<26, 16*64*FRACUNIT);//, mask);
  //	      if (!linetarget)
  //		slope = P_AimLineAttack(mo, an -= 2<<26, 16*64*FRACUNIT);//, mask);
  //	      if (!linetarget)
  //		slope = (critical->freeaim == FREEAIM_BOTH) ? PLAYER_SLOPE(player) : 0, an = mo->angle;
  //	    }
  //	  while (mask && (mask=0, !linetarget));     // killough 8/2/98
  //	  an1 += an - mo->angle;
  //	  // [crispy] consider negative slope
  //	  if (slope < 0)
  //	    an2 -= tantoangle[-slope >> DBITS];
  //	  else
  //	  an2 += tantoangle[slope >> DBITS];
  //	}
  //
  //      th = P_SpawnMobj(mo->x, mo->y,
  //		       mo->z + 62*FRACUNIT - player->psprites[ps_weapon].sy,
  //		       type);
  //      // [NS] Play projectile sound.
  //      if (th->info->seesound)
  //      {
  //	S_StartSound (th, th->info->seesound);
  //      }
  //      th->target = mo; // P_SetTarget(&th->target, mo);
  //      th->angle = an1;
  //      // [NS] Use speed from thing info.
  //      th->momx = FixedMul(th->info->speed, finecosine[an1>>ANGLETOFINESHIFT]);
  //      th->momy = FixedMul(th->info->speed, finesine[an1>>ANGLETOFINESHIFT]);
  //      th->momz = FixedMul(th->info->speed, finetangent[an2>>ANGLETOFINESHIFT]);
  //      // [crispy] suppress interpolation of player missiles for the first tic
  //      th->interp = -1;
  //      P_CheckMissileSpawn(th);
  //    }
  //  while ((type != MT_PLASMA2) && (type = MT_PLASMA2)); //killough: obfuscated!

End;

Procedure A_RandomJump(mobj: Pmobj_t; player: Pplayer_t; psp: Ppspdef_t);
Begin
  Raise exception.create('Port me.');
End;

End.

