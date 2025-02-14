Unit deh_thing;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  ;

Type

  //  typedef struct deh_context_s deh_context_t;
  //typedef struct deh_section_s deh_section_t;
  deh_section_init_t = Procedure();
  //typedef void *(*deh_section_start_t)(deh_context_t *context, char *line);
  //typedef void (*deh_section_end_t)(deh_context_t *context, void *tag);
  //typedef void (*deh_line_parser_t)(deh_context_t *context, char *line, void *tag);
  //typedef void (*deh_sha1_hash_t)(sha1_context_t *context);

  deh_section_t = Record
    name: String;

    // Called on startup to initialize code

    init: deh_section_init_t;

    // This is called when a new section is started.  The pointer
    // returned is used as a tag for the following calls.

//    deh_section_start_t start;

    // This is called for each line in the section

//    deh_line_parser_t line_parser;

    // This is called at the end of the section for any cleanup

//    deh_section_end_t end;

    // Called when generating an SHA1 sum of the dehacked state

//    deh_sha1_hash_t sha1_hash;
  End;
  Pdeh_section_t = ^deh_section_t;

Var
  deh_section_thing: deh_section_t;

Implementation

Uses
  info, info_types
  , m_fixed
  ;

// [crispy] initialize Thing extra properties (keeping vanilla props in info.c)

Procedure DEH_InitThingProperties();
Var
  i: integer;
Begin
  For i := 0 To int(NUMMOBJTYPES) - 1 Do Begin
    // [crispy] mobj id for item dropped on death
    Case mobjtype_t(i) Of
      MT_WOLFSS,
        MT_POSSESSED: Begin
          mobjinfo[i].droppeditem := MT_CLIP;
        End;

      MT_SHOTGUY: Begin
          mobjinfo[i].droppeditem := MT_SHOTGUN;
        End;

      MT_CHAINGUY: Begin
          mobjinfo[i].droppeditem := MT_CHAINGUN;
        End;
    Else
      mobjinfo[i].droppeditem := MT_NULL;
    End;

    // [crispy] distance to switch from missile to melee attack (generaliz. for Revenant)
    If (i = int(MT_UNDEAD)) Then
      mobjinfo[i].meleethreshold := 196
    Else
      mobjinfo[i].meleethreshold := 0;

    // [crispy] maximum distance range to start shooting (generaliz. for Arch Vile)
    If (i = int(MT_VILE)) Then
      mobjinfo[i].maxattackrange := 14 * 64
    Else
      mobjinfo[i].maxattackrange := 0; // unlimited

    // [crispy] minimum likelihood of a missile attack (generaliz. for Cyberdemon)
    If (i = int(MT_CYBORG)) Then
      mobjinfo[i].minmissilechance := 160
    Else
      mobjinfo[i].minmissilechance := 200;

    // [crispy] multiplier for missile firing chance (generaliz. from vanilla)
    If (i = int(MT_CYBORG))
      Or (i = int(MT_SPIDER))
      Or (i = int(MT_UNDEAD))
      Or (i = int(MT_SKULL)) Then
      mobjinfo[i].missilechancemult := FRACUNIT Div 2
    Else
      mobjinfo[i].missilechancemult := FRACUNIT;
  End;
End;

Initialization

  deh_section_thing.name := 'Thing';
  deh_section_thing.init := @DEH_InitThingProperties; // [crispy] initialize Thing extra properties
  //  deh_section_thing.start := @DEH_ThingStart;
  //  deh_section_thing.line_parser := @DEH_ThingParseLine;
  //  deh_section_thing._end := Nil;
  //  deh_section_thing.sha1_hash := @DEH_ThingSHA1Sum,

End.

