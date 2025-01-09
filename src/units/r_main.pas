Unit r_main;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure R_Init();
Var
  NUMCOLORMAPS: int;

Implementation

Uses r_data;

Var
  // just for profiling purposes
  framecount: int;

Procedure R_Init();
Begin
  R_InitData();
  write('.');
  //  R_InitPointToAngle();
  write('.');
  //  R_InitTables();
    // viewwidth / viewheight / detailLevel are set by the defaults
  write('.');

  //  R_SetViewSize(screenblocks, detailLevel);
  //  R_InitPlanes();
  write('.');
  //  R_InitLightTables();
  write('.');
  write('.');
  //  R_InitTranslationTables();
  write('.');

  framecount := 0;
End;


End.

