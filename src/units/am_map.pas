Unit am_map;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils;

Procedure AM_Ticker();

Implementation

//
// Updates on Game Tick
//

Procedure AM_Ticker();
Begin

  //    if (!automapactive)
  //	return;
  //
  //    amclock++;
  //
  //    // [crispy] sync up for interpolation
  //    m_x = prev_m_x = next_m_x;
  //    m_y = prev_m_y = next_m_y;
  //
  //    m_paninc_target.x = m_paninc.x + m_paninc2.x;
  //    m_paninc_target.y = m_paninc.y + m_paninc2.y;
  //
  //    // [crispy] reset after moving with the mouse
  //    m_paninc2.x = m_paninc2.y = 0;
  //
  //    if (followplayer)
  //	AM_doFollowPlayer();
  //
  //    // Change the zoom if necessary
  //    if (ftom_zoommul != FRACUNIT)
  //	AM_changeWindowScale();
  //
  //    if (m_paninc_target.x || m_paninc_target.y)
  //        AM_changeWindowLocTick();
  //
  //    // Update light level
  //    // AM_updateLightLev();
End;



End.

