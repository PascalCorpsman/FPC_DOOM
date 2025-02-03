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

Uses
  tables, doomstat, info
  , am_map
  , d_mode, d_player
  , i_system
  , g_game
  , m_fixed, m_random
  , p_mobj, p_local, p_pspr
  , r_main
  ;

//
// KillMobj
//

Procedure P_KillMobj(source: Pmobj_t; target: Pmobj_t);
Var
  item: mobjtype_t;
  mo: Pmobj_t;
Begin
  target^.flags := target^.flags And int(Not (MF_SHOOTABLE Or MF_FLOAT Or MF_SKULLFLY));

  If (target^._type <> MT_SKULL) Then
    target^.flags := target^.flags And Not MF_NOGRAVITY;

  target^.flags := target^.flags Or (MF_CORPSE Or MF_DROPOFF);
  target^.height := SarLongint(target^.height, 2);

  If assigned(source) And assigned(source^.player) Then Begin

    // count for intermission
    If (target^.flags And MF_COUNTKILL) <> 0 Then
      source^.player^.killcount := source^.player^.killcount + 1;

    If assigned(target^.player) Then
      source^.player^.frags[(target^.player - @players) Div sizeof(players[0])] :=
        source^.player^.frags[(target^.player - @players) Div sizeof(players[0])] + 1;
  End
  Else If (Not netgame) And ((target^.flags And MF_COUNTKILL) <> 0) Then Begin
    // count all monster deaths,
    // even those caused by other monsters
    players[0].killcount := players[0].killcount + 1;
  End;

  If assigned(target^.player) Then Begin

    // count environment kills against you
    If (source = Nil) Then
      target^.player^.frags[(target^.player - @players) Div sizeof(players[0])] :=
        target^.player^.frags[(target^.player - @players) Div sizeof(players[0])] + 1;

    target^.flags := target^.flags And Not MF_SOLID;
    target^.player^.playerstate := PST_DEAD;
    P_DropWeapon(target^.player);
    // [crispy] center view when dying
    target^.player^.centering := true;
    // [JN] & [crispy] Reset the yellow bonus palette when the player dies
    target^.player^.bonuscount := 0;
    // [JN] & [crispy] Remove the effect of the inverted palette when the player dies
    If target^.player^.powers[integer(pw_infrared)] <> 0 Then Begin
      target^.player^.fixedcolormap := 1;
    End
    Else Begin
      target^.player^.fixedcolormap := 0;
    End;

    If (target^.player = @players[consoleplayer])
      And (automapactive)
      And (Not demoplayback) Then Begin // [crispy] killough 11/98: don't switch out in demos, though
      // don't die in auto map,
      // switch view prior to dying
      AM_Stop();
    End;
  End;

  // [crispy] Lost Soul, Pain Elemental and Barrel explosions are translucent
  If (target^._type = MT_SKULL) Or (
    target^._type = MT_PAIN) Or (
    target^._type = MT_BARREL) Then
    target^.flags := int(target^.flags Or MF_TRANSLUCENT);

  If (target^.health < -target^.info^.spawnhealth)
    And (target^.info^.xdeathstate <> S_NULL) Then Begin
    P_SetMobjState(target, target^.info^.xdeathstate);
  End
  Else
    P_SetMobjState(target, target^.info^.deathstate);
  target^.tics := target^.tics - P_Random() And 3;

  // [crispy] randomly flip corpse, blood and death animation sprites
  If (target^.flags And MF_FLIPPABLE) <> 0 Then Begin
    target^.health := (target^.health And int(Not (1))) - (Crispy_Random() And 1);
  End;

  If (target^.tics < 1) Then
    target^.tics := 1;

  // I_StartSound (&actor^.r, actor^.info^.deathsound);

  // In Chex Quest, monsters don't drop items.
  If (gameversion = exe_chex) Then exit;

  // Drop stuff.
  // This determines the kind of object spawned
  // during the death frame of a thing.
  If (target^.info^.droppeditem <> MT_NULL) Then Begin // [crispy] drop generalization
    item := target^.info^.droppeditem;
  End
  Else
    exit;

  mo := P_SpawnMobj(target^.x, target^.y, ONFLOORZ, item);
  mo^.flags := mo^.flags Or MF_DROPPED; // special versions of items
End;

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
Var
  ang: unsigned;
  saved: int;
  player: Pplayer_t;
  thrust: fixed_t;
  temp: int;
Begin
  If ((target^.flags And MF_SHOOTABLE) = 0) Then exit; // shouldn't happen...

  If (target^.health <= 0) Then exit;


  If (target^.flags And MF_SKULLFLY) <> 0 Then Begin
    target^.momx := 0;
    target^.momy := 0;
    target^.momz := 0;
  End;

  player := target^.player;
  If assigned(player) And (gameskill = sk_baby) Then Begin
    damage := damage Shr 1; // take half damage in trainer mode
  End;


  // Some close combat weapons should not
  // inflict thrust and push the victim out of reach,
  // thus kick away unless using the chainsaw.
  If assigned(inflictor)
    And ((target^.flags And MF_NOCLIP) = 0)
    And ((source = Nil)
    Or (source^.player = Nil)
    Or (source^.player^.readyweapon <> wp_chainsaw)) Then Begin
    ang := R_PointToAngle2(inflictor^.x, inflictor^.y,
      target^.x, target^.y);

    thrust := damage * (FRACUNIT Shr 3) * 100 Div target^.info^.mass;

    // make fall forwards sometimes
    If (damage < 40)
      And (damage > target^.health)
      And (target^.z - inflictor^.z > 64 * FRACUNIT)
      And ((P_Random() And 1) <> 0) Then Begin
      ang := angle_t(ang + ANG180);
      thrust := thrust * 4;
    End;

    ang := ang Shr ANGLETOFINESHIFT;
    target^.momx := target^.momx + FixedMul(thrust, finecosine[ang]);
    target^.momy := target^.momy + FixedMul(thrust, finesine[ang]);
  End;

  // player specific
  If assigned(player) Then Begin

    // end of game hell hack
    If (target^.subsector^.sector^.special = 11)
      And (damage >= target^.health) Then Begin
      damage := target^.health - 1;
    End;


    // Below certain threshold,
    // ignore damage in GOD mode, or with INVUL power.
    If (damage < 1000)
      And (((player^.cheats And integer(CF_GODMODE)) <> 0)
      Or (player^.powers[integer(pw_invulnerability)] <> 0))
    Then Begin
      exit;
    End;

    If (player^.armortype <> 0) Then Begin

      If (player^.armortype = 1) Then
        saved := damage Div 3
      Else
        saved := damage Div 2;

      If (player^.armorpoints <= saved) Then Begin
        // armor is used up
        saved := player^.armorpoints;
        player^.armortype := 0;
      End;
      player^.armorpoints := player^.armorpoints - saved;
      damage := damage - saved;
    End;
    player^.health := player^.health - damage; // mirror mobj health here for Dave
    // [crispy] negative player health
    player^.neghealth := player^.health;
    If (player^.neghealth < -99) Then
      player^.neghealth := -99;
    If (player^.health < 0) Then
      player^.health := 0;

    player^.attacker := source;
    player^.damagecount := player^.damagecount + damage; // add damage after armor / invuln

    If (player^.damagecount > 100) Then
      player^.damagecount := 100; // teleport stomp does 10k points...
    If damage < 100 Then Begin
      temp := damage;
    End
    Else Begin
      temp := 100;
    End;

    If (player = @players[consoleplayer]) Then
      I_Tactile(40, 10, 40 + temp * 2);
  End;

  // do the damage
  target^.health := target^.health - damage;
  If (target^.health <= 0) Then Begin
    P_KillMobj(source, target);
    exit;
  End;

  If ((P_Random() < target^.info^.painchance))
    And ((target^.flags And MF_SKULLFLY) = 0) Then Begin

    target^.flags := target^.flags Or MF_JUSTHIT; // fight back!

    P_SetMobjState(target, target^.info^.painstate);
  End;

  target^.reactiontime := 0; // we're awake now...

  If (((target^.threshold = 0) Or (target^._type = MT_VILE))
    And assigned(source) And ((source <> target) Or (gameversion < exe_doom_1_5))
    And (source^._type <> MT_VILE)) Then Begin

    // if not intent on another player,
    // chase after this one
    target^.target := source;
    target^.threshold := BASETHRESHOLD;
    If (target^.state = @states[integer(target^.info^.spawnstate)])
    And (target^.info^.seestate <> S_NULL) Then
      P_SetMobjState(target, target^.info^.seestate);
  End;
End;

//
// P_TouchSpecialThing
//

Procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
Begin
  Raise exception.create('Port me.');

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

