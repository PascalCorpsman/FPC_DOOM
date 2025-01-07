Unit v_video;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils, v_patch;

Type
  ppatch_t = ^patch_t;

Procedure V_Init();
Procedure V_DrawPatchDirect(x, y: int; Const patch: ppatch_t);

Implementation

Uses m_fixed;

Procedure V_Init;
Begin
  //  // [crispy] initialize resolution-agnostic patch drawing
  //    if (NONWIDEWIDTH && SCREENHEIGHT)
  //    {
  //        dx = (NONWIDEWIDTH << FRACBITS) / ORIGWIDTH;
  //        dxi = (ORIGWIDTH << FRACBITS) / NONWIDEWIDTH;
  //        dy = (SCREENHEIGHT << FRACBITS) / ORIGHEIGHT;
  //        dyi = (ORIGHEIGHT << FRACBITS) / SCREENHEIGHT;
  //    }
  //    // no-op!
  //    // There used to be separate screens that could be drawn to; these are
  //    // now handled in the upper layers.
End;

Procedure V_DrawPatchDirect(x, y: int; Const patch: ppatch_t);
Begin
    Wie Kriegen wir da nun die Pixeldaten raus ?
End;

End.

