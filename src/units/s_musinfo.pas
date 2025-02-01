Unit s_musinfo;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Type
  musinfo_t = Record
    //    mobj_t * mapthing;
    //    mobj_t * lastmapthing;
    //    int tics;
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

