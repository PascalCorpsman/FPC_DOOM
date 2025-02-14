Unit deh_doom;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , deh_thing, deh_ptr;


Const
  (*
   * Aktuell ist nur die .init Methode implementiert, und die gibt es bei den auskommentierten nicht..
   *)
  deh_section_types: Array Of Pdeh_section_t =
  (
    //    &deh_section_ammo,
    //    &deh_section_cheat,
    //    &deh_section_frame,
    //    &deh_section_misc,
    @deh_section_pointer,
    //    &deh_section_sound,
    //    &deh_section_text,
    @deh_section_thing
    //    &deh_section_weapon,
    //    &deh_section_bexstr,
    //    &deh_section_bexpars,
    //    &deh_section_bexptr,
    //    &deh_section_bexincl,
    //
    );

Implementation

End.

