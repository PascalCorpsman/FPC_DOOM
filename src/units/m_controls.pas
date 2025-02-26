Unit m_controls;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Var
  key_right: int;
  key_left: int;
  //extern int key_reverse;

  key_up: int;
  //extern int key_alt_up;
  key_down: int;
  //extern int key_alt_down;
  key_strafeleft: int;
  key_alt_strafeleft: int;
  key_straferight: int;
  key_alt_straferight: int;
  key_fire: int;
  key_alt_fire: int;
  key_use: int;
  key_strafe: int;
  key_speed: int;
  key_alt_speed: int;
  //extern int key_demospeed;  // [crispy]
  key_view_zoomin: int; // Corpsman
  key_view_zoomout: int; // Corpsman

  key_jump: int;
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
  key_pause: int;
  //
  //extern int key_multi_msg;
  //extern int key_multi_msgplayer[8];

  key_weapon1: int;
  key_weapon2: int;
  key_weapon3: int;
  key_weapon4: int;
  key_weapon5: int;
  key_weapon6: int;
  key_weapon7: int;
  key_weapon8: int;

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
  key_demo_quit: int;
  key_spy: int;
  //extern int key_prevweapon;
  //extern int key_nextweapon;
  //
  //extern int key_map_north;
  //extern int key_map_south;
  key_map_east: int;
  key_map_west: int;
  key_map_zoomin: int;
  key_map_zoomout: int;
  key_map_toggle: int;
  //extern int key_map_maxzoom;
  //extern int key_map_follow;
  //extern int key_map_grid;
  key_map_mark: int;
  key_map_clearmark: int;
  key_map_overlay: int;
  key_map_rotate: int;

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

  // Map control keys:

// key_map_north     := KEY_UPARROW;
// key_map_south     := KEY_DOWNARROW;
  key_map_east := KEY_RIGHTARROW;
  key_map_west := KEY_LEFTARROW;
  key_map_zoomin := VK_ADD;
  key_map_zoomout := VK_SUBTRACT;
  key_map_toggle := KEY_TAB;
  // key_map_maxzoom   := '0';
  // key_map_follow    := 'f';
  // key_map_grid      := 'g';
  key_map_mark := VK_M;
  key_map_clearmark := VK_C;
  key_map_overlay := VK_O; // [crispy]
  key_map_rotate := VK_R; // [crispy]

  key_view_zoomin := VK_ADD;
  key_view_zoomout := VK_SUBTRACT;

  key_pause := VK_PAUSE;

  key_weapon1 := VK_1;
  key_weapon2 := VK_2;
  key_weapon3 := VK_3;
  key_weapon4 := VK_4;
  key_weapon5 := VK_5;
  key_weapon6 := VK_6;
  key_weapon7 := VK_7;
  key_weapon8 := VK_8;

  key_speed := KEY_RSHIFT;
  key_alt_speed := KEY_LSHIFT;
  key_right := KEY_RIGHTARROW;
  key_left := KEY_LEFTARROW;
  key_up := KEY_UPARROW;
  key_down := KEY_DOWNARROW;
  key_jump := VK_W; // Bei hexen ist der "a", aber der ist ja schon mit dem Strafen vorbelegt -> w macht irgendwie sinn ;)
  key_fire := VK_RCONTROL;
  key_alt_fire := VK_LCONTROL; // Fun Fact, Crispy doom hat im Code nur R-Control reagiert aber auch auf L-Control..
  key_strafeleft := VK_A;
  key_alt_strafeleft := 0; // Deakvtiviert
  key_straferight := VK_D;
  key_alt_straferight := 0; // Deakvtiviert
  key_use := VK_SPACE;
  key_strafe := KEY_RALT; // TODO: Eigentlich sollte man den zum Strafen nehmen nicht A und D ...

  // TODO: Das muss natürlich alles "Dynamisch" gemacht werden und aus der Config geladen werden
  key_menu_activate := KEY_ESCAPE;
  key_menu_up := KEY_UPARROW;
  key_menu_down := KEY_DOWNARROW;
  key_menu_left := KEY_LEFTARROW;
  key_menu_right := KEY_RIGHTARROW;
  key_menu_back := VK_BACK;
  key_menu_forward := KEY_ENTER;
  key_menu_confirm := VK_Y; // Y oder Z je nach Land..
  key_menu_abort := VK_N;

  key_spy := VK_F12;

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
  key_demo_quit := VK_Q;
  //    M_BindIntVariable("key_spy",            &key_spy);
  //    M_BindIntVariable("key_menu_nextlevel", &key_menu_nextlevel); // [crispy]
  //    M_BindIntVariable("key_menu_reloadlevel", &key_menu_reloadlevel); // [crispy]

End;

End.

