Unit z_zone;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Const
  PU_STATIC = 1; // static entire execution time
  PU_SOUND = 2; // static while playing
  PU_MUSIC = 3; // static while playing
  PU_FREE = 4; // a free block
  PU_LEVEL = 5; // static until level exited
  PU_LEVSPEC = 6; // a special thinker in a level

  // Tags >= PU_PURGELEVEL are purgable whenever needed.

  PU_PURGELEVEL = 100;
  PU_CACHE = 101;

  // Total number of different tag types

  PU_NUM_TAGS = 8;

Procedure Z_Init();
Function Z_Malloc(size: int; tag: int; Var ptr: Pointer): pointer;
Procedure Z_Free(Var ptr: Pointer);
Procedure Z_FreeTags(lowtag, hightag: int);
Procedure Z_DumpHeap(lowtag, hightag: int);
//  Procedure	Z_FileDumpHeap (FILE *f);
Procedure Z_CheckHeap();
//  Procedure	Z_ChangeTag2 (void *ptr, int tag, const char *file, int line);
//  Procedure	Z_ChangeUser(void *ptr, void **user);
Function Z_FreeMemory(): int;
Function Z_ZoneSize(): unsigned_int;

Implementation

Procedure Z_Init();
Begin

End;

Function Z_Malloc(size: int; tag: int; Var ptr: Pointer): pointer;
Begin

End;

Procedure Z_Free(Var ptr: Pointer);
Begin

End;

Procedure Z_FreeTags(lowtag, hightag: int);
Begin

End;

Procedure Z_DumpHeap(lowtag, hightag: int);
Begin

End;

Procedure Z_CheckHeap();
Begin

End;

Function Z_FreeMemory(): int;
Begin

End;

Function Z_ZoneSize(): unsigned_int;
Begin

End;

End.

