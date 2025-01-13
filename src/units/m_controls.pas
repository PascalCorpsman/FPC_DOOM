Unit m_controls;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Var
  //extern int key_right;
  //extern int key_left;
  //extern int key_reverse;
  //
  //extern int key_up;
  //extern int key_alt_up;
  //extern int key_down;
  //extern int key_alt_down;
  //extern int key_strafeleft;
  //extern int key_alt_strafeleft;
  //extern int key_straferight;
  //extern int key_alt_straferight;
  //extern int key_fire;
  //extern int key_use;
  //extern int key_strafe;
  //extern int key_speed;
  //extern int key_demospeed;  // [crispy]
  //
  //extern int key_jump;
  //extern int key_toggleautorun;
  //extern int key_togglenovert;
  //
  //extern int key_flyup;
  //extern int key_flydown;
  //extern int key_flycenter;
  //extern int key_lookup;
  //extern int key_lookdown;
  //extern int key_lookcenter;
  //extern int key_invleft;
  //extern int key_invright;
  //extern int key_useartifact;
  //
  //// villsa [STRIFE] strife keys
  //extern int key_usehealth;
  //extern int key_invquery;
  //extern int key_mission;
  //extern int key_invpop;
  //extern int key_invkey;
  //extern int key_invhome;
  //extern int key_invend;
  //extern int key_invuse;
  //extern int key_invdrop;
  //
  //extern int key_message_refresh;
  //extern int key_pause;
  //
  //extern int key_multi_msg;
  //extern int key_multi_msgplayer[8];
  //
  //extern int key_weapon1;
  //extern int key_weapon2;
  //extern int key_weapon3;
  //extern int key_weapon4;
  //extern int key_weapon5;
  //extern int key_weapon6;
  //extern int key_weapon7;
  //extern int key_weapon8;
  //
  //extern int key_arti_quartz;
  //extern int key_arti_urn;
  //extern int key_arti_bomb;
  //extern int key_arti_tome;
  //extern int key_arti_ring;
  //extern int key_arti_chaosdevice;
  //extern int key_arti_shadowsphere;
  //extern int key_arti_wings;
  //extern int key_arti_torch;
  //extern int key_arti_morph;
  //
  //extern int key_arti_all;
  //extern int key_arti_health;
  //extern int key_arti_poisonbag;
  //extern int key_arti_blastradius;
  //extern int key_arti_teleport;
  //extern int key_arti_teleportother;
  //extern int key_arti_egg;
  //extern int key_arti_invulnerability;
  //
  //extern int key_demo_quit;
  //extern int key_spy;
  //extern int key_prevweapon;
  //extern int key_nextweapon;
  //
  //extern int key_map_north;
  //extern int key_map_south;
  //extern int key_map_east;
  //extern int key_map_west;
  //extern int key_map_zoomin;
  //extern int key_map_zoomout;
  //extern int key_map_toggle;
  //extern int key_map_maxzoom;
  //extern int key_map_follow;
  //extern int key_map_grid;
  //extern int key_map_mark;
  //extern int key_map_clearmark;
  //extern int key_map_overlay;
  //extern int key_map_rotate;

  // menu keys:
  key_menu_activate: int;
  key_menu_up: int;
  key_menu_down: int;
  key_menu_left: int;
  key_menu_right: int;
  key_menu_back: int;
  key_menu_forward: int;
  key_menu_confirm: int;
  key_menu_abort: int;

  //extern int key_menu_help;
  //extern int key_menu_save;
  //extern int key_menu_load;
  //extern int key_menu_volume;
  //extern int key_menu_detail;
  //extern int key_menu_qsave;
  //extern int key_menu_endgame;
  //extern int key_menu_messages;
  //extern int key_menu_qload;
  //extern int key_menu_quit;
  //extern int key_menu_gamma;

  //extern int key_menu_incscreen;
  //extern int key_menu_decscreen;
  //extern int key_menu_screenshot;
  //extern int key_menu_cleanscreenshot; // [crispy]
  key_menu_del: int; // [crispy]
  //extern int key_menu_nextlevel; // [crispy]
  //extern int key_menu_reloadlevel; // [crispy]
  //
  //extern int mousebfire;
  //extern int mousebstrafe;
  //extern int mousebforward;
  //extern int mousebspeed;
  //
  //extern int mousebjump;
  //
  //extern int mousebstrafeleft;
  //extern int mousebstraferight;
  //extern int mousebturnleft;
  //extern int mousebturnright;
  //extern int mousebbackward;
  //extern int mousebuse;
  //extern int mousebmouselook;
  //extern int mousebreverse;
  //
  //extern int mousebprevweapon;
  //extern int mousebnextweapon;
  //extern int mousebinvleft;
  //extern int mousebinvright;
  //extern int mousebuseartifact;
  //extern int mousebinvuse; // [crispy]
  //
  //extern int mousebmapzoomin; // [crispy]
  //extern int mousebmapzoomout; // [crispy]
  //extern int mousebmapmaxzoom; // [crispy]
  //extern int mousebmapfollow; // [crispy]
  //
  //extern int joybfire;
  //extern int joybstrafe;
  //extern int joybuse;
  //extern int joybspeed;
  //
  //extern int joybjump;
  //
  //extern int joybstrafeleft;
  //extern int joybstraferight;
  //
  //extern int joybprevweapon;
  //extern int joybnextweapon;
  //
  //extern int joybmenu;
  //extern int joybautomap;
  //
  //extern int joybuseartifact;
  //extern int joybinvleft;
  //extern int joybinvright;
  //
  //extern int joybflyup;
  //extern int joybflydown;
  //extern int joybflycenter;
  //
  //extern int dclick_use;

Procedure M_BindBaseControls();
//Procedure  M_BindHereticControls();
//Procedure  M_BindHexenControls();
//Procedure  M_BindStrifeControls();
Procedure M_BindWeaponControls();
Procedure M_BindMapControls();
Procedure M_BindMenuControls();
//Procedure  M_BindChatControls(num_players:unsigned_int);

//void M_ApplyPlatformDefaults(void);


Implementation

Uses
  LCLType,
  doomkey
  ;

Procedure M_BindBaseControls();
Begin

End;

Procedure M_BindWeaponControls();
Begin

End;

Procedure M_BindMapControls();
Begin

End;

Procedure M_BindMenuControls();
Begin
  // ACHTUNG, Alle werte hier sind "Geraten"
  // TODO: Das muss natürlich alles "Dynamisch" gemacht werden und aus der Config geladen werden
  key_menu_activate := VK_ESCAPE;
  key_menu_up := VK_UP;
  key_menu_down := vk_down;
  key_menu_left := VK_LEFT;
  key_menu_right := VK_RIGHT;
  key_menu_back := VK_BACK;
  key_menu_forward := VK_RETURN;
  key_menu_confirm := VK_Y; // Y oder Z je nach Land..
  key_menu_abort := VK_N;

  //    M_BindIntVariable("key_menu_help",      &key_menu_help);
  //    M_BindIntVariable("key_menu_save",      &key_menu_save);
  //    M_BindIntVariable("key_menu_load",      &key_menu_load);
  //    M_BindIntVariable("key_menu_volume",    &key_menu_volume);
  //    M_BindIntVariable("key_menu_detail",    &key_menu_detail);
  //    M_BindIntVariable("key_menu_qsave",     &key_menu_qsave);
  //    M_BindIntVariable("key_menu_endgame",   &key_menu_endgame);
  //    M_BindIntVariable("key_menu_messages",  &key_menu_messages);
  //    M_BindIntVariable("key_menu_qload",     &key_menu_qload);
  //    M_BindIntVariable("key_menu_quit",      &key_menu_quit);
  //    M_BindIntVariable("key_menu_gamma",     &key_menu_gamma);
  //
  //    M_BindIntVariable("key_menu_incscreen", &key_menu_incscreen);
  //    M_BindIntVariable("key_menu_decscreen", &key_menu_decscreen);
  //    M_BindIntVariable("key_menu_screenshot",&key_menu_screenshot);
  //    M_BindIntVariable("key_menu_cleanscreenshot",&key_menu_cleanscreenshot); // [crispy]
  //    M_BindIntVariable("key_menu_del",       &key_menu_del); // [crispy]
  //    M_BindIntVariable("key_demo_quit",      &key_demo_quit);
  //    M_BindIntVariable("key_spy",            &key_spy);
  //    M_BindIntVariable("key_menu_nextlevel", &key_menu_nextlevel); // [crispy]
  //    M_BindIntVariable("key_menu_reloadlevel", &key_menu_reloadlevel); // [crispy]

End;

End.

