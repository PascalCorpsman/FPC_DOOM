Unit v_video;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Procedure V_Init();

Implementation

Uses m_fixed;

Procedure V_Init();
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

End.

