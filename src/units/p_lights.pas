Unit p_lights;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  ;

Procedure P_SpawnLightFlash(sector: Psector_t);
Procedure P_SpawnStrobeFlash(sector: Psector_t; fastOrSlow: int; inSync: int);
Procedure P_SpawnGlowingLight(sector: Psector_t);
Procedure P_SpawnFireFlicker(sector: Psector_t);

Procedure EV_LightTurnOn(line: Pline_t; bright: int);
Procedure EV_StartLightStrobing(line: Pline_t);
Procedure EV_TurnTagLightsOff(line: Pline_t);

Implementation

Uses
  a11y_weapon_pspr
  , m_random
  , p_spec, p_tick, p_setup
  ;

Var
  AllocatedFlashs: Array Of Plightflash_t = Nil;
  Allocatedglows: Array Of Pglow_t = Nil;
  Allocatedstrobes: Array Of Pstrobe_t = Nil;
  AllocatedFlicks: Array Of Pfireflicker_t = Nil;

  //
  // T_LightFlash
  // Do flashing lights.
  //

Procedure T_LightFlash(mo: Pmobj_t);
Var
  flash: Plightflash_t;
Begin
  flash := Plightflash_t(mo);
  flash^.count := flash^.count - 1;
  If (flash^.count <> 0) Then exit;

  If (flash^.sector^.lightlevel = flash^.maxlight) Then Begin

    flash^.sector^.lightlevel := flash^.minlight;
    flash^.count := (P_Random() And flash^.mintime) + 1;
  End
  Else Begin
    flash^.sector^.lightlevel := flash^.maxlight;
    flash^.count := (P_Random() And flash^.maxtime) + 1;
  End;

  // [crispy] A11Y
  If (a11y_sector_lighting <> 0) Then
    flash^.sector^.rlightlevel := flash^.sector^.lightlevel
  Else
    flash^.sector^.rlightlevel := flash^.maxlight;
End;

//
// P_SpawnLightFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
//

Procedure P_SpawnLightFlash(sector: Psector_t);
Var
  flash: Plightflash_t;
Begin
  // nothing special about it during gameplay
  sector^.special := 0;

  new(flash);
  setlength(AllocatedFlashs, high(AllocatedFlashs) + 2);
  AllocatedFlashs[high(AllocatedFlashs)] := flash;

  P_AddThinker(@flash^.thinker);

  flash^.thinker._function.acp1 := @T_LightFlash;
  flash^.sector := sector;
  flash^.maxlight := sector^.lightlevel;

  flash^.minlight := P_FindMinSurroundingLight(sector, sector^.lightlevel);
  flash^.maxtime := 64;
  flash^.mintime := 7;
  flash^.count := (P_Random() And flash^.maxtime) + 1;
End;

//
// T_StrobeFlash
//

Procedure T_StrobeFlash(mo: Pmobj_t);
Var
  flash: Pstrobe_t;
Begin
  flash := Pstrobe_t(mo);
  flash^.count := flash^.count - 1;
  If (flash^.count <> 0) Then exit;

  If (flash^.sector^.lightlevel = flash^.minlight) Then Begin

    flash^.sector^.lightlevel := flash^.maxlight;
    flash^.count := flash^.brighttime;
  End
  Else Begin
    flash^.sector^.lightlevel := flash^.minlight;
    flash^.count := flash^.darktime;
  End;

  // [crispy] A11Y
  If (a11y_sector_lighting <> 0) Then
    flash^.sector^.rlightlevel := flash^.sector^.lightlevel
  Else
    flash^.sector^.rlightlevel := flash^.maxlight;
End;

//
// P_SpawnStrobeFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
//

Procedure P_SpawnStrobeFlash(sector: Psector_t; fastOrSlow: int; inSync: int);
Var
  flash: Pstrobe_t;
Begin
  new(flash);
  setlength(Allocatedstrobes, high(Allocatedstrobes) + 2);
  Allocatedstrobes[high(Allocatedstrobes)] := flash;

  P_AddThinker(@flash^.thinker);

  flash^.sector := sector;
  flash^.darktime := fastOrSlow;
  flash^.brighttime := STROBEBRIGHT;
  flash^.thinker._function.acp1 := @T_StrobeFlash;
  flash^.maxlight := sector^.lightlevel;
  flash^.minlight := P_FindMinSurroundingLight(sector, sector^.lightlevel);

  If (flash^.minlight = flash^.maxlight) Then
    flash^.minlight := 0;

  // nothing special about it during gameplay
  sector^.special := 0;

  If (inSync = 0) Then
    flash^.count := (P_Random() And 7) + 1
  Else
    flash^.count := 1;
End;

Procedure T_Glow(mo: Pmobj_t);
Var
  g: Pglow_t;
Begin
  g := Pglow_t(mo);
  Case (g^.direction) Of
    -1: Begin
        // DOWN
        g^.sector^.lightlevel := g^.sector^.lightlevel - GLOWSPEED;
        If (g^.sector^.lightlevel <= g^.minlight) Then Begin
          g^.sector^.lightlevel := g^.sector^.lightlevel + GLOWSPEED;
          g^.direction := 1;
        End;
      End;

    1: Begin
        // UP
        g^.sector^.lightlevel := g^.sector^.lightlevel + GLOWSPEED;
        If (g^.sector^.lightlevel >= g^.maxlight) Then Begin
          g^.sector^.lightlevel := g^.sector^.lightlevel - GLOWSPEED;
          g^.direction := -1;
        End;
      End;
  End;

  // [crispy] A11Y
  If (a11y_sector_lighting <> 0) Then
    g^.sector^.rlightlevel := g^.sector^.lightlevel
  Else
    g^.sector^.rlightlevel := g^.maxlight;
End;

Procedure P_SpawnGlowingLight(sector: Psector_t);
Var
  g: Pglow_t;
Begin
  new(g);
  setlength(Allocatedglows, high(Allocatedglows) + 2);
  Allocatedglows[high(Allocatedglows)] := g;

  P_AddThinker(@g^.thinker);

  g^.sector := sector;
  g^.minlight := P_FindMinSurroundingLight(sector, sector^.lightlevel);
  g^.maxlight := sector^.lightlevel;
  g^.thinker._function.acp1 := @T_Glow;
  g^.direction := -1;

  sector^.special := 0;
End;


//
// T_FireFlicker
//

Procedure T_FireFlicker(mo: Pmobj_t);
Var
  flick: Pfireflicker_t;
  amount: int;
Begin
  flick := Pfireflicker_t(mo);

  flick^.count := flick^.count - 1;
  If (flick^.count <> 0) Then exit;

  amount := (P_Random() And 3) * 16;

  If (flick^.sector^.lightlevel - amount < flick^.minlight) Then
    flick^.sector^.lightlevel := flick^.minlight
  Else
    flick^.sector^.lightlevel := flick^.maxlight - amount;

  flick^.count := 4;

  // [crispy] A11Y
  If (a11y_sector_lighting <> 0) Then
    flick^.sector^.rlightlevel := flick^.sector^.lightlevel
  Else
    flick^.sector^.rlightlevel := flick^.maxlight;
End;

//
// P_SpawnFireFlicker
//

Procedure P_SpawnFireFlicker(sector: Psector_t);
Var
  flick: Pfireflicker_t;
Begin

  // Note that we are resetting sector attributes.
  // Nothing special about it during gameplay.
  sector^.special := 0;
  new(flick);
  setlength(AllocatedFlicks, high(AllocatedFlicks) + 2);
  AllocatedFlicks[high(AllocatedFlicks)] := flick;

  P_AddThinker(@flick^.thinker);

  flick^.thinker._function.acp1 := @T_FireFlicker;
  flick^.sector := sector;
  flick^.maxlight := sector^.lightlevel;
  flick^.minlight := P_FindMinSurroundingLight(sector, sector^.lightlevel) + 16;
  flick^.count := 4;
End;

Procedure EV_LightTurnOn(line: Pline_t; bright: int);
Begin
  Raise exception.create('Port me.');
  //   int		i;
  //   int		j;
  //   sector_t*	sector;
  //   sector_t*	temp;
  //   line_t*	templine;
  //
  //   sector = sectors;
  //
  //   for (i=0;i<numsectors;i++, sector++)
  //   {
  //if (sector->tag == line->tag)
  //{
  //    // bright = 0 means to search
  //    // for highest light level
  //    // surrounding sector
  //    if (!bright)
  //    {
  //	for (j = 0;j < sector->linecount; j++)
  //	{
  //	    templine = sector->lines[j];
  //	    temp = getNextSector(templine,sector);
  //
  //	    if (!temp)
  //		continue;
  //
  //	    if (temp->lightlevel > bright)
  //		bright = temp->lightlevel;
  //	}
  //    }
  //    sector-> lightlevel = bright;
  //    // [crispy] A11Y
  //    sector->rlightlevel = sector->lightlevel;
  //}
  //   }
End;

//
// Start strobing lights (usually from a trigger)
//

Procedure EV_StartLightStrobing(line: Pline_t);
Var
  secnum: int;
  sec: Psector_t;
Begin
  secnum := -1;
  secnum := P_FindSectorFromLineTag(line, secnum);
  While (secnum >= 0) Do Begin

    sec := @sectors[secnum];
    If assigned(sec^.specialdata) Then Begin
      secnum := P_FindSectorFromLineTag(line, secnum);
      continue;
    End;

    P_SpawnStrobeFlash(sec, SLOWDARK, 0);
    secnum := P_FindSectorFromLineTag(line, secnum);
  End;
End;

//
// TURN LINE'S TAG LIGHTS OFF
//

Procedure EV_TurnTagLightsOff(line: Pline_t);
Begin
  Raise exception.create('Port me.');
  //    int			i;
  //    int			j;
  //    int			min;
  //    sector_t*		sector;
  //    sector_t*		tsec;
  //    line_t*		templine;
  //
  //    sector = sectors;
  //
  //    for (j = 0;j < numsectors; j++, sector++)
  //    {
  //	if (sector->tag == line->tag)
  //	{
  //	    min = sector->lightlevel;
  //	    for (i = 0;i < sector->linecount; i++)
  //	    {
  //		templine = sector->lines[i];
  //		tsec = getNextSector(templine,sector);
  //		if (!tsec)
  //		    continue;
  //		if (tsec->lightlevel < min)
  //		    min = tsec->lightlevel;
  //	    }
  //	    sector->lightlevel = min;
  //	    // [crispy] A11Y
  //	    sector->rlightlevel = sector->lightlevel;
  //	}
  //    }
End;

Var
  i: integer;

Finalization

  For i := 0 To high(AllocatedFlashs) Do Begin
    Dispose(AllocatedFlashs[i]);
  End;
  setlength(AllocatedFlashs, 0);

  For i := 0 To high(Allocatedglows) Do Begin
    Dispose(Allocatedglows[i]);
  End;
  setlength(Allocatedglows, 0);

  For i := 0 To high(Allocatedstrobes) Do Begin
    Dispose(Allocatedstrobes[i]);
  End;
  setlength(Allocatedstrobes, 0);

  For i := 0 To high(AllocatedFlicks) Do Begin
    Dispose(AllocatedFlicks[i]);
  End;
  setlength(AllocatedFlicks, 0);


End.

