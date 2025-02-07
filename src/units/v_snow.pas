Unit v_snow;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure V_SnowUpdate();

Implementation

Procedure V_SnowUpdate();
Begin
  Raise Exception.Create('Port me.');
  //  size_t i;
  //
  //    if (last_screen_size != (SCREENHEIGHT * SCREENWIDTH))
  //        ResetSnow();
  //
  //    if (Crispy_Random() % 20 == 4)
  //        wind = 1 - Crispy_Random() % 3;
  //
  //    for (i = 0; i < snowflakes_num; i++)
  //    {
  //        snowflakes[i].y += Crispy_Random() % 4;
  //
  //        snowflakes[i].x += 1 - Crispy_Random() % 3;
  //        snowflakes[i].x += wind;
  //
  //        if (snowflakes[i].y >= SCREENHEIGHT)
  //            snowflakes[i].y = 0;
  //        if (snowflakes[i].x >= SCREENWIDTH)
  //            snowflakes[i].x = snowflakes[i].x - SCREENWIDTH;
  //        if (snowflakes[i].x < 0)
  //            snowflakes[i].x = SCREENWIDTH + snowflakes[i].x;
  //    }
End;

End.

