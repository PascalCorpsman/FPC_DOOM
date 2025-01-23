Unit r_sky;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Const
  // The sky map is 256*128*4 maps.
  ANGLETOSKYSHIFT = 22;

  // [crispy] stretch sky
  SKYSTRETCH_HEIGHT = 228;

  // SKY, store the number for name.
  SKYFLATNAME = 'F_SKY1';

Var
  //
  // sky mapping
  //
  skyflatnum: int;
  skytexture: int = -1; // [crispy] initialize
  skytexturemid: int;

Procedure R_InitSkyMap();

Implementation

Uses
  r_data
  , m_fixed
  , i_video
  ;

Procedure R_InitSkyMap();
Var
  skyheight: int;
Begin

  // [crispy] stretch short skies
  If (skytexture = -1) Then Begin
    exit;
  End;

  crispy.stretchsky := (crispy.freelook <> 0) Or (crispy.mouselook <> 0) Or (crispy.pitch <> 0);
  skyheight := textureheight[skytexture] Shr FRACBITS;

  If (crispy.stretchsky) And (skyheight < 200) Then Begin
    skytexturemid := -28 * FRACUNIT;
  End
  Else If (skyheight >= 200) Then Begin
    skytexturemid := 200 * FRACUNIT;
  End
  Else Begin
    skytexturemid := ORIGHEIGHT Div 2 * FRACUNIT;
  End;
End;

End.

