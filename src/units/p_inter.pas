Unit p_inter;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef, info_types
  , d_englsh
  ;


// [crispy] show weapon pickup messages in multiplayer games
Const
  WeaponPickupMessages: Array Of String =
  (
    '', // wp_fist
    '', // wp_pistol
    GOTSHOTGUN,
    GOTCHAINGUN,
    GOTLAUNCHER,
    GOTPLASMA,
    GOTBFG9000,
    GOTCHAINSAW,
    GOTSHOTGUN2
    );

  // a weapon is found with two clip loads,
  // a big item has five clip loads
  maxammo: Array[0..integer(NUMAMMO) - 1] Of int = (200, 50, 300, 50);
  clipammo: Array[0..integer(NUMAMMO) - 1] Of int = (10, 4, 20, 1);

Procedure P_DamageMobj(target: Pmobj_t; inflictor: Pmobj_t; source: Pmobj_t; damage: int);
Procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);

Implementation

Uses
  tables, doomstat, info, sounds, deh_misc
  , am_map
  , d_mode, d_player, d_items
  , i_system
  , g_game
  , m_fixed, m_random
  , p_mobj, p_local, p_pspr
  , r_main
  , s_sound
  ;

Const
  BONUSADD = 6;

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
// P_GiveAmmo
// Num is the number of clip loads,
// not the individual count (0= 1/2 clip).
// Returns false if the ammo can't be picked up at all
//

Function P_GiveAmmo(player: Pplayer_t; ammo: ammotype_t; num: int; dropped: boolean): boolean; // [NS] Dropped ammo/weapons give half as much.
Var
  oldammo: int;
Begin
  result := false;
  If (ammo = am_noammo) Then exit;

  If (ammo >= NUMAMMO) Then Begin
    I_Error(format('P_GiveAmmo: bad type %d', [integer(ammo)]));
  End;

  If (player^.ammo[integer(ammo)] = player^.maxammo[integer(ammo)]) Then exit;

  If (num <> 0) Then
    num := num * clipammo[integer(ammo)]
  Else
    num := clipammo[integer(ammo)] Div 2;

  If (gameskill = sk_baby)
    Or (gameskill = sk_nightmare)
    Or (critical^.moreammo) Then Begin
    // give double ammo in trainer mode,
    // you'll need in nightmare
    num := num Shl 1;
  End;

  // [NS] Halve if needed.
  If (dropped) Then Begin
    num := num Shr 1;
    // Don't round down to 0.
    If (num = 0) Then
      num := 1;
  End;

  oldammo := player^.ammo[integer(ammo)];
  player^.ammo[integer(ammo)] := player^.ammo[integer(ammo)] + num;

  If (player^.ammo[integer(ammo)] > player^.maxammo[integer(ammo)]) Then
    player^.ammo[integer(ammo)] := player^.maxammo[integer(ammo)];

  // If non zero ammo,
  // don't change up weapons,
  // player was lower on purpose.
  If (oldammo <> 0) Then Begin
    result := true;
    exit;
  End;

  // We were down to zero,
  // so select a new weapon.
  // Preferences are not user selectable.
  Case (ammo) Of

    am_clip: Begin
        If (player^.readyweapon = wp_fist) Then Begin

          If (player^.weaponowned[wp_chaingun] <> 0) Then
            player^.pendingweapon := wp_chaingun
          Else
            player^.pendingweapon := wp_pistol;
        End;
      End;

    am_shell: Begin
        If (player^.readyweapon = wp_fist)
          Or (player^.readyweapon = wp_pistol) Then Begin

          If (player^.weaponowned[wp_shotgun] <> 0) Then
            player^.pendingweapon := wp_shotgun;
        End;
      End;

    am_cell: Begin
        If (player^.readyweapon = wp_fist)
          Or (player^.readyweapon = wp_pistol) Then Begin
          If (player^.weaponowned[wp_plasma] <> 0) Then
            player^.pendingweapon := wp_plasma;
        End;
      End;

    am_misl: Begin
        If (player^.readyweapon = wp_fist) Then Begin
          If (player^.weaponowned[wp_missile] <> 0) Then
            player^.pendingweapon := wp_missile;
        End;
      End;
  End;

  result := true;
End;


//
// P_GiveWeapon
// The weapon name may have a MF_DROPPED flag ored in.
//

Function P_GiveWeapon(player: Pplayer_t; weapon: weapontype_t; dropped: boolean): boolean;
Var
  gaveammo: boolean;
  gaveweapon: boolean;
Begin

  If (netgame)
    And (deathmatch <> 2)
    And (Not dropped) Then Begin
    // leave placed weapons forever on net games
    If (player^.weaponowned[weapon] <> 0) Then Begin
      result := false;
      exit;
    End;

    player^.bonuscount := player^.bonuscount + BONUSADD;
    player^.weaponowned[weapon] := 1;

    If (deathmatch <> 0) Then
      P_GiveAmmo(player, weaponinfo[integer(weapon)].ammo, 5, false)
    Else
      P_GiveAmmo(player, weaponinfo[integer(weapon)].ammo, 2, false);
    player^.pendingweapon := weapon;
    // [crispy] show weapon pickup messages in multiplayer games
    player^.message := WeaponPickupMessages[integer(weapon)];

    If (player = @players[displayplayer]) Then
      S_StartSound(Nil, sfx_wpnup);
    result := false;
    exit;
  End;

  If (weaponinfo[integer(weapon)].ammo <> am_noammo) Then Begin

    // give one clip with a dropped weapon,
    // two clips with a found weapon
    // [NS] Just need to pass that it's dropped.
    gaveammo := P_GiveAmmo(player, weaponinfo[integer(weapon)].ammo, 2, dropped);
    (*
    if (dropped) then
        gaveammo := P_GiveAmmo (player, weaponinfo[weapon].ammo, 1)
    else
        gaveammo := P_GiveAmmo (player, weaponinfo[weapon].ammo, 2);
    *)
  End
  Else
    gaveammo := false;

  If (player^.weaponowned[weapon] <> 0) Then
    gaveweapon := false
  Else Begin
    gaveweapon := true;
    player^.weaponowned[weapon] := 1;
    player^.pendingweapon := weapon;
  End;

  result := (gaveweapon Or gaveammo);
End;

//
// P_GiveBody
// Returns false if the body isn't needed at all
//

Function P_GiveBody(player: pplayer_t; num: int): boolean;
Begin
  If (player^.health >= MAXHEALTH) Then Begin
    result := false;
    exit;
  End;

  player^.health := player^.health + num;
  If (player^.health > MAXHEALTH) Then
    player^.health := MAXHEALTH;
  player^.mo^.health := player^.health;

  result := true;
End;

//
// P_GiveArmor
// Returns false if the armor is worse
// than the current armor.
//

Function P_GiveArmor(player: Pplayer_t; armortype: int): boolean;
Var
  hits: int;
Begin
  hits := armortype * 100;
  If (player^.armorpoints >= hits) Then Begin
    result := false; // don't pick up
    exit;
  End;
  player^.armortype := armortype;
  player^.armorpoints := hits;
  result := true;
End;

//
// P_TouchSpecialThing
//

Procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
Var
  player: Pplayer_t;
  i: int;
  delta: fixed_t;
  sound: sfxenum_t;
  dropped: boolean;
Begin
  dropped := ((special^.flags And MF_DROPPED) <> 0);
  delta := special^.z - toucher^.z;
  If (delta > toucher^.height)
    Or (delta < -8 * FRACUNIT) Then Begin
    // out of reach
    exit;
  End;

  sound := sfx_itemup;
  player := toucher^.player;
  // Dead thing touching.
  // Can happen with a sliding player corpse.
  If (toucher^.health <= 0) Then exit;

  // Identify by sprite.
  Case (special^.sprite) Of

    // armor
    SPR_ARM1: Begin
        If (Not P_GiveArmor(player, deh_green_armor_class)) Then exit;
        player^.message := GOTARMOR;
      End;

    SPR_ARM2: Begin
        If (Not P_GiveArmor(player, deh_blue_armor_class)) Then exit;
        player^.message := GOTMEGA;
      End;

    // bonus items
    SPR_BON1: Begin
        player^.health := player^.health + 1; // can go over 100%
        If (player^.health > deh_max_health) Then
          player^.health := deh_max_health;
        player^.mo^.health := player^.health;
        player^.message := GOTHTHBONUS;
      End;

    SPR_BON2: Begin
        player^.armorpoints := player^.armorpoints + 1; // can go over 100%
        If (player^.armorpoints > deh_max_armor) And (gameversion > exe_doom_1_2) Then
          player^.armorpoints := deh_max_armor;
        // deh_green_armor_class only applies to the green armor shirt;
        // for the armor helmets, armortype 1 is always used.
        If (player^.armortype = 0) Then
          player^.armortype := 1;
        player^.message := GOTARMBONUS;
      End;

    //      case SPR_SOUL:
    //	player^.health += deh_soulsphere_health;
    //	if (player^.health > deh_max_soulsphere)
    //	    player^.health = deh_max_soulsphere;
    //	player^.mo^.health = player^.health;
    //	player^.message = DEH_String(GOTSUPER);
    //	if (gameversion > exe_doom_1_2)
    //	    sound = sfx_getpow;
    //	break;
    //
    //      case SPR_MEGA:
    //	if (gamemode != commercial)
    //	    return;
    //	player^.health = deh_megasphere_health;
    //	player^.mo^.health = player^.health;
    //        // We always give armor type 2 for the megasphere; dehacked only
    //        // affects the MegaArmor.
    //	P_GiveArmor (player, 2);
    //	player^.message = DEH_String(GOTMSPHERE);
    //	if (gameversion > exe_doom_1_2)
    //	    sound = sfx_getpow;
    //	break;
    //
    //	// cards
    //	// leave cards for everyone
    //      case SPR_BKEY:
    //	if (!player^.cards[it_bluecard])
    //	    player^.message = DEH_String(GOTBLUECARD);
    //	P_GiveCard (player, it_bluecard);
    //	sound = sfx_keyup; // [NS] Optional key pickup sound.
    //	if (!netgame)
    //	    break;
    //	return;
    //
    //      case SPR_YKEY:
    //	if (!player^.cards[it_yellowcard])
    //	    player^.message = DEH_String(GOTYELWCARD);
    //	P_GiveCard (player, it_yellowcard);
    //	sound = sfx_keyup; // [NS] Optional key pickup sound.
    //	if (!netgame)
    //	    break;
    //	return;
    //
    //      case SPR_RKEY:
    //	if (!player^.cards[it_redcard])
    //	    player^.message = DEH_String(GOTREDCARD);
    //	P_GiveCard (player, it_redcard);
    //	sound = sfx_keyup; // [NS] Optional key pickup sound.
    //	if (!netgame)
    //	    break;
    //	return;
    //
    //      case SPR_BSKU:
    //	if (!player^.cards[it_blueskull])
    //	    player^.message = DEH_String(GOTBLUESKUL);
    //	P_GiveCard (player, it_blueskull);
    //	sound = sfx_keyup; // [NS] Optional key pickup sound.
    //	if (!netgame)
    //	    break;
    //	return;
    //
    //      case SPR_YSKU:
    //	if (!player^.cards[it_yellowskull])
    //	    player^.message = DEH_String(GOTYELWSKUL);
    //	P_GiveCard (player, it_yellowskull);
    //	sound = sfx_keyup; // [NS] Optional key pickup sound.
    //	if (!netgame)
    //	    break;
    //	return;
    //
    //      case SPR_RSKU:
    //	if (!player^.cards[it_redskull])
    //	    player^.message = DEH_String(GOTREDSKULL);
    //	P_GiveCard (player, it_redskull);
    //	sound = sfx_keyup; // [NS] Optional key pickup sound.
    //	if (!netgame)
    //	    break;
    //	return;

     // medikits, heals
    SPR_STIM: Begin
        If (Not P_GiveBody(player, 10)) Then exit;

        player^.message := GOTSTIM;
      End;

    SPR_MEDI: Begin
        If (Not P_GiveBody(player, 25)) Then exit;
        // [crispy] show "Picked up a Medikit that you really need" message as intended
        If (player^.health < 50) Then
          player^.message := GOTMEDINEED
        Else
          player^.message := GOTMEDIKIT;
      End;

    //	// power ups
    //      case SPR_PINV:
    //	if (!P_GivePower (player, pw_invulnerability))
    //	    return;
    //	player^.message = DEH_String(GOTINVUL);
    //	if (gameversion > exe_doom_1_2)
    //	    sound = sfx_getpow;
    //	break;

    //      case SPR_PSTR:
    //	if (!P_GivePower (player, pw_strength))
    //	    return;
    //	player^.message = DEH_String(GOTBERSERK);
    //	if (player^.readyweapon != wp_fist)
    //	    player^.pendingweapon = wp_fist;
    //	if (gameversion > exe_doom_1_2)
    //	    sound = sfx_getpow;
    //	break;

    //      case SPR_PINS:
    //	if (!P_GivePower (player, pw_invisibility))
    //	    return;
    //	player^.message = DEH_String(GOTINVIS);
    //	if (gameversion > exe_doom_1_2)
    //	    sound = sfx_getpow;
    //	break;

    //      case SPR_SUIT:
    //	if (!P_GivePower (player, pw_ironfeet))
    //	    return;
    //	player^.message = DEH_String(GOTSUIT);
    //	if (gameversion > exe_doom_1_2)
    //	    sound = sfx_getpow;
    //	break;

    //      case SPR_PMAP:
    //	if (!P_GivePower (player, pw_allmap))
    //	    return;
    //	player^.message = DEH_String(GOTMAP);
    //	if (gameversion > exe_doom_1_2)
    //	    sound = sfx_getpow;
    //	break;

    //      case SPR_PVIS:
    //	if (!P_GivePower (player, pw_infrared))
    //	    return;
    //	player^.message = DEH_String(GOTVISOR);
    //	if (gameversion > exe_doom_1_2)
    //	    sound = sfx_getpow;
    //	break;

     // ammo
     // [NS] Give half ammo for drops of all types.
    SPR_CLIP: Begin
        (*
        If (special^.flags And MF_DROPPED) <> 0 Then Begin
          If (Not P_GiveAmmo(player, am_clip, 0)) Then exit;
        End
        Else Begin
          If (Not P_GiveAmmo(player, am_clip, 1)) Then exit;
        End;
        //*)
        If (Not P_GiveAmmo(player, am_clip, 1, dropped)) Then exit;
        player^.message := GOTCLIP;
      End;

    SPR_AMMO: Begin
        If (Not P_GiveAmmo(player, am_clip, 5, dropped)) Then exit;

        player^.message := GOTCLIPBOX;
      End;

    //      case SPR_ROCK:
    //	if (!P_GiveAmmo (player, am_misl,1,dropped))
    //	    return;
    //	player^.message = DEH_String(GOTROCKET);
    //	break;

    //      case SPR_BROK:
    //	if (!P_GiveAmmo (player, am_misl,5,dropped))
    //	    return;
    //	player^.message = DEH_String(GOTROCKBOX);
    //	break;

    //      case SPR_CELL:
    //	if (!P_GiveAmmo (player, am_cell,1,dropped))
    //	    return;
    //	player^.message = DEH_String(GOTCELL);
    //	break;

    //      case SPR_CELP:
    //	if (!P_GiveAmmo (player, am_cell,5,dropped))
    //	    return;
    //	player^.message = DEH_String(GOTCELLBOX);
    //	break;

    SPR_SHEL: Begin
        If (Not P_GiveAmmo(player, am_shell, 1, dropped)) Then exit;
        player^.message := GOTSHELLS;
      End;

    SPR_SBOX: Begin
        If (Not P_GiveAmmo(player, am_shell, 5, dropped)) Then exit;
        player^.message := GOTSHELLBOX;
      End;

    //      case SPR_BPAK:
    //	if (!player^.backpack)
    //	{
    //	    for (i=0 ; i<NUMAMMO ; i++)
    //		player^.maxammo[i] *= 2;
    //	    player^.backpack = true;
    //	}
    //	for (i=0 ; i<NUMAMMO ; i++)
    //	    P_GiveAmmo (player, i, 1, false);
    //	player^.message = DEH_String(GOTBACKPACK);
    //	break;

     // weapons
     // [NS] Give half ammo for all dropped weapons.
    SPR_BFUG: Begin
        If (Not P_GiveWeapon(player, wp_bfg, dropped)) Then exit;

        player^.message := GOTBFG9000;
        sound := sfx_wpnup;
      End;

    SPR_MGUN: Begin
        If (Not P_GiveWeapon(player, wp_chaingun,
          (special^.flags And MF_DROPPED) <> 0)) Then exit;

        player^.message := GOTCHAINGUN;
        sound := sfx_wpnup;
      End;

    SPR_CSAW: Begin
        If (Not P_GiveWeapon(player, wp_chainsaw, dropped)) Then exit;
        player^.message := GOTCHAINSAW;
        sound := sfx_wpnup;
      End;

    SPR_LAUN: Begin
        If (Not P_GiveWeapon(player, wp_missile, dropped)) Then exit;
        player^.message := GOTLAUNCHER;
        sound := sfx_wpnup;
      End;

    SPR_PLAS: Begin
        If (Not P_GiveWeapon(player, wp_plasma, dropped)) Then exit;

        player^.message := GOTPLASMA;
        sound := sfx_wpnup;
      End;

    SPR_SHOT: Begin
        If (Not P_GiveWeapon(player, wp_shotgun,
          (special^.flags And MF_DROPPED) <> 0)) Then exit;
        player^.message := GOTSHOTGUN;
        sound := sfx_wpnup;
      End;

    SPR_SGN2: Begin
        If (Not P_GiveWeapon(player, wp_supershotgun,
          (special^.flags And MF_DROPPED) <> 0)) Then exit;
        player^.message := GOTSHOTGUN2;
        sound := sfx_wpnup;
      End;

    // [NS] Beta pickups.
    //      case SPR_BON3:
    //	player^.message = DEH_String(BETA_BONUS3);
    //	break;

    //      case SPR_BON4:
    //	player^.message = DEH_String(BETA_BONUS4);
    //  break;

  Else Begin
      Raise exception.create('port me: ' + inttostr(integer(special^.sprite)));
      I_Error('P_SpecialThing: Unknown gettable thing');
    End;
  End;

  If (special^.flags And MF_COUNTITEM) <> 0 Then
    player^.itemcount := player^.itemcount + 1;
  P_RemoveMobj(special);
  player^.bonuscount := player^.bonuscount + BONUSADD;
  If (player = @players[displayplayer]) Then
    S_StartSoundOptional(Nil, sound, sfx_itemup); // [NS] Fallback to itemup.
End;

End.

