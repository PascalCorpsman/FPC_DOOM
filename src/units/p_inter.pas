Unit p_inter;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef, info_types
  ;

Const
  // a weapon is found with two clip loads,
  // a big item has five clip loads
  maxammo: Array[0..integer(NUMAMMO) - 1] Of int = (200, 50, 300, 50);
  clipammo: Array[0..integer(NUMAMMO) - 1] Of int = (10, 4, 20, 1);

Procedure P_DamageMobj(target: Pmobj_t; inflictor: Pmobj_t; source: Pmobj_t; damage: int);
Procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);

Implementation

//
// P_DamageMobj
// Damages both enemies and players
// "inflictor" is the thing that caused the damage
//  creature or missile, can be NULL (slime, etc)
// "source" is the thing to target after taking damage
//  creature or NULL
// Source and inflictor are the same for melee attacks.
// Source can be NULL for slime, barrel explosions
// and other environmental stuff.
//

Procedure P_DamageMobj(target: Pmobj_t; inflictor: Pmobj_t; source: Pmobj_t; damage: int);
Begin
  //    unsigned	ang;
  //    int		saved;
  //    player_t*	player;
  //    fixed_t	thrust;
  //    int		temp;
  //
  //    if ( !(target->flags & MF_SHOOTABLE) )
  //	return;	// shouldn't happen...
  //
  //    if (target->health <= 0)
  //	return;
  //
  //    if ( target->flags & MF_SKULLFLY )
  //    {
  //	target->momx = target->momy = target->momz = 0;
  //    }
  //
  //    player = target->player;
  //    if (player && gameskill == sk_baby)
  //	damage >>= 1; 	// take half damage in trainer mode
  //
  //
  //    // Some close combat weapons should not
  //    // inflict thrust and push the victim out of reach,
  //    // thus kick away unless using the chainsaw.
  //    if (inflictor
  //	&& !(target->flags & MF_NOCLIP)
  //	&& (!source
  //	    || !source->player
  //	    || source->player->readyweapon != wp_chainsaw))
  //    {
  //	ang = R_PointToAngle2 ( inflictor->x,
  //				inflictor->y,
  //				target->x,
  //				target->y);
  //
  //	thrust = damage*(FRACUNIT>>3)*100/target->info->mass;
  //
  //	// make fall forwards sometimes
  //	if ( damage < 40
  //	     && damage > target->health
  //	     && target->z - inflictor->z > 64*FRACUNIT
  //	     && (P_Random ()&1) )
  //	{
  //	    ang += ANG180;
  //	    thrust *= 4;
  //	}
  //
  //	ang >>= ANGLETOFINESHIFT;
  //	target->momx += FixedMul (thrust, finecosine[ang]);
  //	target->momy += FixedMul (thrust, finesine[ang]);
  //    }
  //
  //    // player specific
  //    if (player)
  //    {
  //	// end of game hell hack
  //	if (target->subsector->sector->special == 11
  //	    && damage >= target->health)
  //	{
  //	    damage = target->health - 1;
  //	}
  //
  //
  //	// Below certain threshold,
  //	// ignore damage in GOD mode, or with INVUL power.
  //	if ( damage < 1000
  //	     && ( (player->cheats&CF_GODMODE)
  //		  || player->powers[pw_invulnerability] ) )
  //	{
  //	    return;
  //	}
  //
  //	if (player->armortype)
  //	{
  //	    if (player->armortype == 1)
  //		saved = damage/3;
  //	    else
  //		saved = damage/2;
  //
  //	    if (player->armorpoints <= saved)
  //	    {
  //		// armor is used up
  //		saved = player->armorpoints;
  //		player->armortype = 0;
  //	    }
  //	    player->armorpoints -= saved;
  //	    damage -= saved;
  //	}
  //	player->health -= damage; 	// mirror mobj health here for Dave
  //	// [crispy] negative player health
  //	player->neghealth = player->health;
  //	if (player->neghealth < -99)
  //	    player->neghealth = -99;
  //	if (player->health < 0)
  //	    player->health = 0;
  //
  //	player->attacker = source;
  //	player->damagecount += damage;	// add damage after armor / invuln
  //
  //	if (player->damagecount > 100)
  //	    player->damagecount = 100;	// teleport stomp does 10k points...
  //
  //	temp = damage < 100 ? damage : 100;
  //
  //	if (player == &players[consoleplayer])
  //	    I_Tactile (40,10,40+temp*2);
  //    }
  //
  //    // do the damage
  //    target->health -= damage;
  //    if (target->health <= 0)
  //    {
  //	P_KillMobj (source, target);
  //	return;
  //    }
  //
  //    if ( (P_Random () < target->info->painchance)
  //	 && !(target->flags&MF_SKULLFLY) )
  //    {
  //	target->flags |= MF_JUSTHIT;	// fight back!
  //
  //	P_SetMobjState (target, target->info->painstate);
  //    }
  //
  //    target->reactiontime = 0;		// we're awake now...
  //
  //    if ( (!target->threshold || target->type == MT_VILE)
  //	 && source && (source != target || gameversion < exe_doom_1_5)
  //	 && source->type != MT_VILE)
  //    {
  //	// if not intent on another player,
  //	// chase after this one
  //	target->target = source;
  //	target->threshold = BASETHRESHOLD;
  //	if (target->state == &states[target->info->spawnstate]
  //	    && target->info->seestate != S_NULL)
  //	    P_SetMobjState (target, target->info->seestate);
  //    }

End;

//
// P_TouchSpecialThing
//

Procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
Begin
  //   player_t*	player;
  //    int		i;
  //    fixed_t	delta;
  //    int		sound;
  //    const boolean dropped = ((special->flags & MF_DROPPED) != 0);
  //
  //    delta = special->z - toucher->z;
  //
  //    if (delta > toucher->height
  //	|| delta < -8*FRACUNIT)
  //    {
  //	// out of reach
  //	return;
  //    }
  //
  //
  //    sound = sfx_itemup;
  //    player = toucher->player;
  //
  //    // Dead thing touching.
  //    // Can happen with a sliding player corpse.
  //    if (toucher->health <= 0)
  //	return;
  //
  //    // Identify by sprite.
  //    switch (special->sprite)
  //    {
  //	// armor
  //      case SPR_ARM1:
  //	if (!P_GiveArmor (player, deh_green_armor_class))
  //	    return;
  //	player->message = DEH_String(GOTARMOR);
  //	break;
  //
  //      case SPR_ARM2:
  //	if (!P_GiveArmor (player, deh_blue_armor_class))
  //	    return;
  //	player->message = DEH_String(GOTMEGA);
  //	break;
  //
  //	// bonus items
  //      case SPR_BON1:
  //	player->health++;		// can go over 100%
  //	if (player->health > deh_max_health)
  //	    player->health = deh_max_health;
  //	player->mo->health = player->health;
  //	player->message = DEH_String(GOTHTHBONUS);
  //	break;
  //
  //      case SPR_BON2:
  //	player->armorpoints++;		// can go over 100%
  //	if (player->armorpoints > deh_max_armor && gameversion > exe_doom_1_2)
  //	    player->armorpoints = deh_max_armor;
  //        // deh_green_armor_class only applies to the green armor shirt;
  //        // for the armor helmets, armortype 1 is always used.
  //	if (!player->armortype)
  //	    player->armortype = 1;
  //	player->message = DEH_String(GOTARMBONUS);
  //	break;
  //
  //      case SPR_SOUL:
  //	player->health += deh_soulsphere_health;
  //	if (player->health > deh_max_soulsphere)
  //	    player->health = deh_max_soulsphere;
  //	player->mo->health = player->health;
  //	player->message = DEH_String(GOTSUPER);
  //	if (gameversion > exe_doom_1_2)
  //	    sound = sfx_getpow;
  //	break;
  //
  //      case SPR_MEGA:
  //	if (gamemode != commercial)
  //	    return;
  //	player->health = deh_megasphere_health;
  //	player->mo->health = player->health;
  //        // We always give armor type 2 for the megasphere; dehacked only
  //        // affects the MegaArmor.
  //	P_GiveArmor (player, 2);
  //	player->message = DEH_String(GOTMSPHERE);
  //	if (gameversion > exe_doom_1_2)
  //	    sound = sfx_getpow;
  //	break;
  //
  //	// cards
  //	// leave cards for everyone
  //      case SPR_BKEY:
  //	if (!player->cards[it_bluecard])
  //	    player->message = DEH_String(GOTBLUECARD);
  //	P_GiveCard (player, it_bluecard);
  //	sound = sfx_keyup; // [NS] Optional key pickup sound.
  //	if (!netgame)
  //	    break;
  //	return;
  //
  //      case SPR_YKEY:
  //	if (!player->cards[it_yellowcard])
  //	    player->message = DEH_String(GOTYELWCARD);
  //	P_GiveCard (player, it_yellowcard);
  //	sound = sfx_keyup; // [NS] Optional key pickup sound.
  //	if (!netgame)
  //	    break;
  //	return;
  //
  //      case SPR_RKEY:
  //	if (!player->cards[it_redcard])
  //	    player->message = DEH_String(GOTREDCARD);
  //	P_GiveCard (player, it_redcard);
  //	sound = sfx_keyup; // [NS] Optional key pickup sound.
  //	if (!netgame)
  //	    break;
  //	return;
  //
  //      case SPR_BSKU:
  //	if (!player->cards[it_blueskull])
  //	    player->message = DEH_String(GOTBLUESKUL);
  //	P_GiveCard (player, it_blueskull);
  //	sound = sfx_keyup; // [NS] Optional key pickup sound.
  //	if (!netgame)
  //	    break;
  //	return;
  //
  //      case SPR_YSKU:
  //	if (!player->cards[it_yellowskull])
  //	    player->message = DEH_String(GOTYELWSKUL);
  //	P_GiveCard (player, it_yellowskull);
  //	sound = sfx_keyup; // [NS] Optional key pickup sound.
  //	if (!netgame)
  //	    break;
  //	return;
  //
  //      case SPR_RSKU:
  //	if (!player->cards[it_redskull])
  //	    player->message = DEH_String(GOTREDSKULL);
  //	P_GiveCard (player, it_redskull);
  //	sound = sfx_keyup; // [NS] Optional key pickup sound.
  //	if (!netgame)
  //	    break;
  //	return;
  //
  //	// medikits, heals
  //      case SPR_STIM:
  //	if (!P_GiveBody (player, 10))
  //	    return;
  //	player->message = DEH_String(GOTSTIM);
  //	break;
  //
  //      case SPR_MEDI:
  //	if (!P_GiveBody (player, 25))
  //	    return;
  //
  //	// [crispy] show "Picked up a Medikit that you really need" message as intended
  //	if (player->health < 50)
  //	    player->message = DEH_String(GOTMEDINEED);
  //	else
  //	    player->message = DEH_String(GOTMEDIKIT);
  //	break;
  //
  //
  //	// power ups
  //      case SPR_PINV:
  //	if (!P_GivePower (player, pw_invulnerability))
  //	    return;
  //	player->message = DEH_String(GOTINVUL);
  //	if (gameversion > exe_doom_1_2)
  //	    sound = sfx_getpow;
  //	break;
  //
  //      case SPR_PSTR:
  //	if (!P_GivePower (player, pw_strength))
  //	    return;
  //	player->message = DEH_String(GOTBERSERK);
  //	if (player->readyweapon != wp_fist)
  //	    player->pendingweapon = wp_fist;
  //	if (gameversion > exe_doom_1_2)
  //	    sound = sfx_getpow;
  //	break;
  //
  //      case SPR_PINS:
  //	if (!P_GivePower (player, pw_invisibility))
  //	    return;
  //	player->message = DEH_String(GOTINVIS);
  //	if (gameversion > exe_doom_1_2)
  //	    sound = sfx_getpow;
  //	break;
  //
  //      case SPR_SUIT:
  //	if (!P_GivePower (player, pw_ironfeet))
  //	    return;
  //	player->message = DEH_String(GOTSUIT);
  //	if (gameversion > exe_doom_1_2)
  //	    sound = sfx_getpow;
  //	break;
  //
  //      case SPR_PMAP:
  //	if (!P_GivePower (player, pw_allmap))
  //	    return;
  //	player->message = DEH_String(GOTMAP);
  //	if (gameversion > exe_doom_1_2)
  //	    sound = sfx_getpow;
  //	break;
  //
  //      case SPR_PVIS:
  //	if (!P_GivePower (player, pw_infrared))
  //	    return;
  //	player->message = DEH_String(GOTVISOR);
  //	if (gameversion > exe_doom_1_2)
  //	    sound = sfx_getpow;
  //	break;
  //
  //	// ammo
  //	// [NS] Give half ammo for drops of all types.
  //      case SPR_CLIP:
  //	/*
  //	if (special->flags & MF_DROPPED)
  //	{
  //	    if (!P_GiveAmmo (player,am_clip,0))
  //		return;
  //	}
  //	else
  //	{
  //	    if (!P_GiveAmmo (player,am_clip,1))
  //		return;
  //	}
  //	*/
  //	    if (!P_GiveAmmo (player,am_clip,1,dropped))
  //		return;
  //	player->message = DEH_String(GOTCLIP);
  //	break;
  //
  //      case SPR_AMMO:
  //	if (!P_GiveAmmo (player, am_clip,5,dropped))
  //	    return;
  //	player->message = DEH_String(GOTCLIPBOX);
  //	break;
  //
  //      case SPR_ROCK:
  //	if (!P_GiveAmmo (player, am_misl,1,dropped))
  //	    return;
  //	player->message = DEH_String(GOTROCKET);
  //	break;
  //
  //      case SPR_BROK:
  //	if (!P_GiveAmmo (player, am_misl,5,dropped))
  //	    return;
  //	player->message = DEH_String(GOTROCKBOX);
  //	break;
  //
  //      case SPR_CELL:
  //	if (!P_GiveAmmo (player, am_cell,1,dropped))
  //	    return;
  //	player->message = DEH_String(GOTCELL);
  //	break;
  //
  //      case SPR_CELP:
  //	if (!P_GiveAmmo (player, am_cell,5,dropped))
  //	    return;
  //	player->message = DEH_String(GOTCELLBOX);
  //	break;
  //
  //      case SPR_SHEL:
  //	if (!P_GiveAmmo (player, am_shell,1,dropped))
  //	    return;
  //	player->message = DEH_String(GOTSHELLS);
  //	break;
  //
  //      case SPR_SBOX:
  //	if (!P_GiveAmmo (player, am_shell,5,dropped))
  //	    return;
  //	player->message = DEH_String(GOTSHELLBOX);
  //	break;
  //
  //      case SPR_BPAK:
  //	if (!player->backpack)
  //	{
  //	    for (i=0 ; i<NUMAMMO ; i++)
  //		player->maxammo[i] *= 2;
  //	    player->backpack = true;
  //	}
  //	for (i=0 ; i<NUMAMMO ; i++)
  //	    P_GiveAmmo (player, i, 1, false);
  //	player->message = DEH_String(GOTBACKPACK);
  //	break;
  //
  //	// weapons
  //	// [NS] Give half ammo for all dropped weapons.
  //      case SPR_BFUG:
  //	if (!P_GiveWeapon (player, wp_bfg, dropped) )
  //	    return;
  //	player->message = DEH_String(GOTBFG9000);
  //	sound = sfx_wpnup;
  //	break;
  //
  //      case SPR_MGUN:
  //        if (!P_GiveWeapon(player, wp_chaingun,
  //                          (special->flags & MF_DROPPED) != 0))
  //            return;
  //	player->message = DEH_String(GOTCHAINGUN);
  //	sound = sfx_wpnup;
  //	break;
  //
  //      case SPR_CSAW:
  //	if (!P_GiveWeapon (player, wp_chainsaw, dropped) )
  //	    return;
  //	player->message = DEH_String(GOTCHAINSAW);
  //	sound = sfx_wpnup;
  //	break;
  //
  //      case SPR_LAUN:
  //	if (!P_GiveWeapon (player, wp_missile, dropped) )
  //	    return;
  //	player->message = DEH_String(GOTLAUNCHER);
  //	sound = sfx_wpnup;
  //	break;
  //
  //      case SPR_PLAS:
  //	if (!P_GiveWeapon (player, wp_plasma, dropped) )
  //	    return;
  //	player->message = DEH_String(GOTPLASMA);
  //	sound = sfx_wpnup;
  //	break;
  //
  //      case SPR_SHOT:
  //        if (!P_GiveWeapon(player, wp_shotgun,
  //                          (special->flags & MF_DROPPED) != 0))
  //            return;
  //	player->message = DEH_String(GOTSHOTGUN);
  //	sound = sfx_wpnup;
  //	break;
  //
  //      case SPR_SGN2:
  //        if (!P_GiveWeapon(player, wp_supershotgun,
  //                          (special->flags & MF_DROPPED) != 0))
  //            return;
  //	player->message = DEH_String(GOTSHOTGUN2);
  //	sound = sfx_wpnup;
  //	break;
  //
  //	// [NS] Beta pickups.
  //      case SPR_BON3:
  //	player->message = DEH_String(BETA_BONUS3);
  //	break;
  //
  //      case SPR_BON4:
  //	player->message = DEH_String(BETA_BONUS4);
  //	break;
  //
  //      default:
  //	I_Error ("P_SpecialThing: Unknown gettable thing");
  //    }
  //
  //    if (special->flags & MF_COUNTITEM)
  //	player->itemcount++;
  //    P_RemoveMobj (special);
  //    player->bonuscount += BONUSADD;
  //    if (player == &players[displayplayer])
  //	S_StartSoundOptional (NULL, sound, sfx_itemup); // [NS] Fallback to itemup.

End;

End.

