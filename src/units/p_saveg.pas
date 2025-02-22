Unit p_saveg;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Var
  savegame_error: boolean;

Function P_SaveGameFile(slot: int): String;
Function P_TempSaveGameFile(): String;
Procedure P_WriteSaveGameHeader(Const Stream: TStream; description: String);

Procedure P_ArchivePlayers(Const Stream: TStream);

Implementation

Uses
  dstrings, doomdef, info_types
  , d_main
  , g_game
  , m_menu
  , p_tick
  ;

Procedure saveg_write_pad();
Begin
  // Nichts, wer braucht das ..
End;

// Get the filename of the save game file to use for the specified slot.

Function P_SaveGameFile(slot: int): String;
Var
  filename, basename: String;
Begin
  basename := SAVEGAMENAME + format('%d.dsg', [10 * savepage + slot]);
  filename := savegamedir + basename;
  result := filename;
End;

Function P_TempSaveGameFile(): String;
Const
  filename: String = '';
Begin
  If (filename = '') Then Begin
    filename := savegamedir + 'temp.dsg';
  End;
  result := filename;
End;

Procedure P_WriteSaveGameHeader(Const Stream: TStream; description: String);
Var
  name: String;
  i: Integer;
Begin
  stream.WriteAnsiString(description);
  name := format('version %d', [G_VanillaVersionCode()]);
  stream.WriteAnsiString(name);
  stream.Write(gameskill, sizeof(gameskill));
  stream.Write(gameepisode, sizeof(gameepisode));
  stream.Write(gamemap, sizeof(gamemap));
  For i := 0 To MAXPLAYERS - 1 Do
    stream.Write(playeringame[i], sizeof(playeringame[i]));
  stream.Write(leveltime, sizeof(leveltime));
End;

Procedure saveg_write_player_t(Const Stream: TStream; Const str: player_t);
Var
  i: int;
Begin
  // mobj_t* mo;
//  saveg_writep(str.mo);

  // playerstate_t playerstate;
  stream.Write(str.playerstate, sizeof(str.playerstate));

  // ticcmd_t cmd;
  stream.Write(str.cmd, sizeof(str.cmd));

  // fixed_t viewz;
  stream.Write(str.viewz, sizeof(str.viewz));

  // fixed_t viewheight;
  stream.Write(str.viewheight, sizeof(str.viewheight));

  // fixed_t deltaviewheight;
  stream.Write(str.deltaviewheight, sizeof(str.deltaviewheight));

  // fixed_t bob;
  stream.Write(str.bob, sizeof(str.bob));

  // int health;
  stream.Write(str.health, sizeof(str.health));

  // int armorpoints;
  stream.Write(str.armorpoints, sizeof(str.armorpoints));

  // int armortype;
  stream.Write(str.armortype, sizeof(str.armortype));

  // int powers[NUMPOWERS];
  For i := 0 To int(NUMPOWERS) - 1 Do Begin
    stream.Write(str.powers[i], sizeof(str.powers[i]));
  End;

  // boolean cards[NUMCARDS];
  For i := 0 To int(NUMCARDS) - 1 Do Begin
    stream.Write(str.cards[card_t(i)], sizeof(str.cards[card_t(i)]));
  End;

  // boolean backpack;
  stream.Write(str.backpack, sizeof(str.backpack));

  // int frags[MAXPLAYERS];
  For i := 0 To MAXPLAYERS - 1 Do Begin
    stream.Write(str.frags[i], sizeof(str.frags[i]));
  End;

  // weapontype_t readyweapon;
  stream.Write(str.readyweapon, sizeof(str.readyweapon));

  // weapontype_t pendingweapon;
  stream.Write(str.pendingweapon, sizeof(str.pendingweapon));

  // boolean weaponowned[NUMWEAPONS];
  For i := 0 t int(NUMWEAPONS) - 1 Do
    stream.Write(str.weaponowned[i], sizeof(str.weaponowned[i]));

  // int ammo[NUMAMMO];
  For i := 0 To int(NUMAMMO) - 1 Do
    stream.Write(str.ammo[i], sizeof(str.ammo[i]));

  // int maxammo[NUMAMMO];
  For i := 0 To int(NUMAMMO) - 1 Do
    stream.Write(str.maxammo[i], sizeof(str.maxammo[i]));

  // int attackdown;
  stream.Write(str.attackdown, sizeof(str.attackdown));
  // int usedown;
  stream.Write(str.usedown, sizeof(str.usedown));
  // int cheats;
  stream.Write(str.cheats, sizeof(str.cheats));

  // int refire;
  stream.Write(str.refire, sizeof(str.refire));

  // int killcount;
  stream.Write(str.killcount, sizeof(str.killcount));

  // int itemcount;
  stream.Write(str.itemcount, sizeof(str.itemcount));

  // int secretcount;
  stream.Write(str.secretcount, sizeof(str.secretcount));

  // char* message;
  stream.WriteAnsiString(str.message);

  // int damagecount;
  stream.Write(str.damagecount, sizeof(str.damagecount));

  // int bonuscount;
  stream.Write(str.bonuscount, sizeof(str.bonuscount));

  // mobj_t* attacker;
//  stream.Write(str.attacker, sizeof(str.attacker)); --> Das geht so nicht ..

  // int extralight;
  stream.Write(str.extralight, sizeof(str.extralight));

  // int fixedcolormap;
  stream.Write(str.fixedcolormap, sizeof(str.fixedcolormap));

  // int colormap;
  stream.Write(str.colormap, sizeof(str.colormap));


  // pspdef_t psprites[NUMPSPRITES];
  For i := 0 To NUMSPRITES - 1 Do Begin
    // stream.Write(str.psprites[i], sizeof(str.psprites[i])); --> Das geht so nicht..
  End;

  // boolean didsecret;
  stream.Write(str.didsecret, sizeof(str.didsecret));
End;

Procedure P_ArchivePlayers(Const Stream: TStream);
Var
  i: int;
Begin
  For i := 0 To MAXPLAYERS - 1 Do Begin

    If (Not playeringame[i]) Then
      continue;

    saveg_write_pad();

    saveg_write_player_t(stream, players[i]);


  End;
End;

End.

