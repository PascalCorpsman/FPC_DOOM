Unit s_musinfo;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Type
  musinfo_t = Record
    mapthing: Pmobj_t;
    lastmapthing: Pmobj_t;
    tics: int;
    //    int current_item;
    //    int items[MAX_MUS_ENTRIES];
    from_savegame: boolean;
  End;
Var

  musinfo: musinfo_t;

Procedure S_ParseMusInfo(mapid: String);

Procedure T_MusInfo();

Implementation

Procedure S_ParseMusInfo(mapid: String);
Begin

End;

Procedure T_MusInfo();
Begin

End;

End.

