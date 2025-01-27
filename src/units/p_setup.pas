Unit p_setup;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , doomdef, doomdata, info_types
  , d_mode
  , m_fixed
  , r_defs
  ;

Const
  // Maintain single and multi player starting spots.
  MAX_DEATHMATCH_STARTS = 10;

Var
  playerstarts: Array[0..MAXPLAYERS - 1] Of mapthing_t;
  playerstartsingame: Array[0..MAXPLAYERS - 1] Of boolean;

  deathmatchstarts: Array[0..MAX_DEATHMATCH_STARTS - 1] Of mapthing_t;
  deathmatch_p: int;

  numnodes: int;
  nodes: Array Of node_t;

  numsectors: int;
  sectors: Array Of sector_t;

  numsegs: int;
  segs: Array Of seg_t;

  numsides: int;
  sides: Array Of side_t;

  numsubsectors: int;
  subsectors: Array Of subsector_t;

  // for thing chains
  blocklinks: Array Of Pmobj_t;

  // BLOCKMAP
  // Created from axis aligned bounding box
  // of the map, a rectangular array of
  // blocks of size ...
  // Used to speed up collision detection
  // by spatial subdivision in 2D.
  //
  blockmap: ^int32_t; // int for larger maps // [crispy] BLOCKMAP limit
  // offsets in blockmap are from here
  blockmaplump: Array Of int32_t; // [crispy] BLOCKMAP limit

  // Blockmap size.
  bmapwidth: int;
  bmapheight: int; // size in mapblocks

  // origin of block map
  bmaporgx: fixed_t;
  bmaporgy: fixed_t;

  numlines: int;
  lines: Array Of line_t;

Function P_GetNumForMap(episode, map: int; critical: boolean): int;

Procedure P_SetupLevel(episode, map, playermask: int; skill: skill_t);

Procedure P_Init();

Implementation

Uses
  doomstat, tables, info
  , d_loop, d_main
  , i_timer, i_system
  , g_game
  , m_argv, m_bbox
  , p_tick, p_extnodes, p_blockmap, p_local, p_mobj, p_inter, p_switch, p_spec
  , r_data, r_main, r_things
  , s_musinfo, s_sound
  , w_wad
  , z_zone
  ;

Const
  skilltable: Array Of String =
  (
    'Nothing',
    'Baby',
    'Easy',
    'Normal',
    'Hard',
    'Nightmare'
    );

Var
  // pointer to the current map lump info struct
  maplumpinfo: ^lumpinfo_t;

  //
  // MAP related Lookup tables.
  // Store VERTEXES, LINEDEFS, SIDEDEFS, etc.
  //
  numvertexes: int;
  vertexes: Array Of vertex_t;

  totallines: int;

  // REJECT
  // For fast sight rejection.
  // Speeds up enemy AI by skipping detailed
  //  LineOf Sight calculation.
  // Without special effect, this could be
  //  used as a PVS lookup as well.
  //
  rejectmatrix: Array Of byte;

  // [crispy] recalculate seg offsets
  // adapted from prboom-plus/src/p_setup.c:474-482

Function GetOffset(v1: Pvertex_t; v2: Pvertex_t): fixed_t;
Var
  dx, dy: fixed_t;
  r: fixed_t;
Begin
  dx := SarLongint(v1^.x - v2^.x, FRACBITS);
  dy := SarLongint(v1^.y - v2^.y, FRACBITS);

  r := trunc(sqrt(dx * dx + dy * dy)) Shl FRACBITS;
  result := r;
End;

//
// P_LoadBlockMap
//

Function P_LoadBlockMap(lump: int): boolean;
Var
  i, count, lumplen: int;
  wadblockmaplump: Array Of short;
  t: short;
Begin
  result := false;
  // [crispy] (re-)create BLOCKMAP if necessary
  lumplen := W_LumpLength(lump);
  count := lumplen Div 2;
  If (M_CheckParm('-blockmap') <> 0) Or
    (lump >= length(lumpinfo)) Or
    (lumplen < 8) Or
    (count >= $10000) Then exit;

  // [crispy] remove BLOCKMAP limit
  // adapted from boom202s/P_SETUP.C:1025-1076
  wadblockmaplump := Nil;
  setlength(wadblockmaplump, lumplen);
  W_ReadLump(lump, @wadblockmaplump[0]);
  setlength(blockmaplump, count);
  blockmap := pointer(@blockmaplump[0]) + 4;

  blockmaplump[0] := wadblockmaplump[0];
  blockmaplump[1] := wadblockmaplump[1];
  blockmaplump[2] := wadblockmaplump[2] And $FFFF;
  blockmaplump[3] := wadblockmaplump[3] And $FFFF;

  // Swap all short integers to native byte ordering.

  For i := 4 To count - 1 Do Begin
    t := wadblockmaplump[i];
    If (t = -1) Then Begin
      blockmaplump[i] := -1;
    End
    Else Begin
      blockmaplump[i] := t And $FFFF;
    End;
  End;

  //  Z_Free(wadblockmaplump);

  // Read the header

  bmaporgx := blockmaplump[0] Shl FRACBITS;
  bmaporgy := blockmaplump[1] Shl FRACBITS;
  bmapwidth := blockmaplump[2];
  bmapheight := blockmaplump[3];

  // Clear out mobj chains

  count := bmapwidth * bmapheight;
  setlength(blocklinks, count);
  For i := 0 To high(blocklinks) Do
    blocklinks[i] := Nil;

  // [crispy] (re-)create BLOCKMAP if necessary
  writeln(stderr, ')');
  result := true;
End;

Function P_GetNumForMap(episode, map: int; critical: boolean): int;
Var
  lumpName: String;
Begin
  // find map name
  If (gamemode = commercial) Then Begin
    If (map < 10) Then Begin
      lumpname := 'map0' + inttostr(map);
    End
    Else Begin
      lumpname := 'map' + inttostr(map);
    End;
  End
  Else Begin
    lumpName := format('E%dM%d', [episode, map]);
  End;

  // [crispy] special-casing for E1M10 "Sewers" support
//      if (crispy->havee1m10 && episode == 1 && map == 10)
//      {
//  	DEH_snprintf(lumpname, 9, "E1M10");
//      }

  // [crispy] NRFTL / The Master Levels
//    if (crispy->havenerve && episode == 2 && map <= 9)
//    {
//	strcat(lumpname, "N");
//    }
//    if (crispy->havemaster && episode == 3 && map <= 21)
//    {
//	strcat(lumpname, "M");
//    }
  If critical Then Begin
    result := W_GetNumForName(lumpname);
  End
  Else Begin
    result := W_CheckNumForName(lumpname);
  End;
End;

Procedure P_LoadVertexes(lump: int);
Var
  i: int;
  ml: Array Of mapvertex_t;
  li: Array Of vertex_t;
Begin
  // Determine number of lumps:
  // total lump length / vertex record length.
  numvertexes := W_LumpLength(lump) Div sizeof(mapvertex_t);

  // Allocate zone memory for buffer.
  setlength(vertexes, numvertexes);

  // Load data into cache.
  ml := W_CacheLumpNum(lump, PU_STATIC);
  li := vertexes;

  // Copy and convert vertex coordinates,
  // internal representation as fixed.
  For i := 0 To numvertexes - 1 Do Begin

    li[i].x := (ml[i].x) Shl FRACBITS;
    li[i].y := (ml[i].y) Shl FRACBITS;

    // [crispy] initialize vertex coordinates *only* used in rendering
    li[i].r_x := li[i].x;
    li[i].r_y := li[i].y;
    li[i].moved := false;
  End;

  // Free buffer memory.
//    W_ReleaseLumpNum(lump);
End;

Procedure P_LoadSectors(lump: int);
Var
  i: int;
  ms: Array Of mapsector_t;
Begin

  // [crispy] fail on missing sectors
  If (lump >= length(lumpinfo)) Then Begin
    I_Error('P_LoadSectors: No sectors in map!');
  End;

  numsectors := W_LumpLength(lump) Div sizeof(mapsector_t);
  setlength(sectors, numsectors);
  FillChar(sectors[0], numsectors * sizeof(sector_t), 0);


  ms := W_CacheLumpNum(lump, PU_STATIC);

  // [crispy] fail on missing sectors
  If (ms = Nil) Or (numsectors = 0) Then Begin
    I_Error('P_LoadSectors: No sectors In map!');
  End;

  For i := 0 To numsectors - 1 Do Begin
    sectors[i].floorheight := ms[i].floorheight Shl FRACBITS;
    sectors[i].ceilingheight := ms[i].ceilingheight Shl FRACBITS;
    sectors[i].floorpic := R_FlatNumForName(ms[i].floorpic);
    sectors[i].ceilingpic := R_FlatNumForName(ms[i].ceilingpic);
    sectors[i].lightlevel := ms[i].lightlevel;
    // [crispy] A11Y light level used for rendering
    sectors[i].rlightlevel := sectors[i].lightlevel;
    sectors[i].special := ms[i].special;
    sectors[i].tag := ms[i].tag;
    sectors[i].thinglist := Nil;
    // [crispy] WiggleFix: [kb] for R_FixWiggle()
    sectors[i].cachedheight := 0;
    // [AM] Sector interpolation.  Even if we're
    //      not running uncapped, the renderer still
    //      uses this data.
    sectors[i].oldfloorheight := sectors[i].floorheight;
    sectors[i].interpfloorheight := sectors[i].floorheight;
    sectors[i].oldceilingheight := sectors[i].ceilingheight;
    sectors[i].interpceilingheight := sectors[i].ceilingheight;
    // [crispy] inhibit sector interpolation during the 0th gametic
    sectors[i].oldgametic := -1;
  End;

  W_ReleaseLumpNum(lump);
End;

Procedure P_LoadSideDefs(lump: int);
Var
  i: int;
  msd: Array Of mapsidedef_t;
Begin
  numsides := W_LumpLength(lump) Div sizeof(mapsidedef_t);
  setlength(sides, numsides);
  FillChar(sides[0], numsides * sizeof(side_t), 0);

  msd := W_CacheLumpNum(lump, PU_STATIC);
  For i := 0 To numsides - 1 Do Begin
    sides[i].textureoffset := msd[i].textureoffset Shl FRACBITS;
    sides[i].rowoffset := msd[i].rowoffset Shl FRACBITS;
    sides[i].toptexture := R_TextureNumForName(msd[i].toptexture);
    sides[i].bottomtexture := R_TextureNumForName(msd[i].bottomtexture);
    sides[i].midtexture := R_TextureNumForName(msd[i].midtexture);
    sides[i].sector := @sectors[msd[i].sector];
    // [crispy] smooth texture scrolling
    sides[i].basetextureoffset := sides[i].textureoffset;
  End;

  //    W_ReleaseLumpNum(lump);
End;

Procedure P_LoadLineDefs(lump: int);
Var
  i: int;
  mld: ^maplinedef_t;
  v1, v2: ^vertex_t;
  warn, warn2: int; // [crispy] warn about invalid linedefs
Begin
  numlines := W_LumpLength(lump) Div sizeof(maplinedef_t);
  setlength(lines, numlines);
  FillChar(lines[0], numlines * sizeof(line_t), 0);
  mld := W_CacheLumpNum(lump, PU_STATIC);
  warn := 0;
  warn2 := 0; // [crispy] warn about invalid linedefs
  For i := 0 To numlines - 1 Do Begin
    lines[i].flags := mld[i].flags; // [crispy] extended nodes
    lines[i].special := mld[i].special;
    // [crispy] warn about unknown linedef types
    If (lines[i].special > 141) And (lines[i].special <> 271) And (lines[i].special <> 272) Then Begin
      writeln(stderr, format('P_LoadLineDefs: Unknown special %d at line %d.', [lines[i].special, i]));
      warn := warn + 1;
    End;
    lines[i].tag := mld[i].tag;
    // [crispy] warn about special linedefs without tag
    If (lines[i].special <> 0) And (lines[i].tag = 0) Then Begin

      Case (lines[i].special) Of

        1, // Vertical Door
        26, // Blue Door/Locked
        27, // Yellow Door /Locked
        28, // Red Door /Locked
        31, // Manual door open
        32, // Blue locked door open
        33, // Red locked door open
        34, // Yellow locked door open
        117, // Blazing door raise
        118, // Blazing door open
        271, // MBF sky transfers
        272,
          48, // Scroll Wall Left
        85, // [crispy] [JN] (Boom) Scroll Texture Right
        11, // s1 Exit level
        51, // s1 Secret exit
        52, // w1 Exit level
        124: Begin // w1 Secret exit
          End;
      Else Begin
          writeln(stderr, format('P_LoadLineDefs: Special linedef %d without tag.', [i]));
          warn2 := warn2 + 1;
        End;
      End;
    End;
    v1 := @vertexes[mld[i].v1]; // [crispy] extended nodes
    lines[i].v1 := @vertexes[mld[i].v1]; // [crispy] extended nodes
    v2 := @vertexes[mld[i].v2]; // [crispy] extended nodes
    lines[i].v2 := @vertexes[mld[i].v2]; // [crispy] extended nodes
    lines[i].dx := v2^.x - v1^.x;
    lines[i].dy := v2^.y - v1^.y;

    If (lines[i].dx = 0) Then
      lines[i].slopetype := ST_VERTICAL
    Else Begin
      If (lines[i].dy = 0) Then
        lines[i].slopetype := ST_HORIZONTAL
      Else Begin
        If (FixedDiv(lines[i].dy, lines[i].dx) > 0) Then
          lines[i].slopetype := ST_POSITIVE
        Else
          lines[i].slopetype := ST_NEGATIVE;
      End;
    End;

    If (v1^.x < v2^.x) Then Begin
      lines[i].bbox[BOXLEFT] := v1^.x;
      lines[i].bbox[BOXRIGHT] := v2^.x;
    End
    Else Begin
      lines[i].bbox[BOXLEFT] := v2^.x;
      lines[i].bbox[BOXRIGHT] := v1^.x;
    End;

    If (v1^.y < v2^.y) Then Begin
      lines[i].bbox[BOXBOTTOM] := v1^.y;
      lines[i].bbox[BOXTOP] := v2^.y;
    End
    Else Begin
      lines[i].bbox[BOXBOTTOM] := v2^.y;
      lines[i].bbox[BOXTOP] := v1^.y;
    End;

    // [crispy] calculate sound origin of line to be its midpoint
    lines[i].soundorg.x := lines[i].bbox[BOXLEFT] Div 2 + lines[i].bbox[BOXRIGHT] Div 2;
    lines[i].soundorg.y := lines[i].bbox[BOXTOP] Div 2 + lines[i].bbox[BOXBOTTOM] Div 2;

    lines[i].sidenum[0] := mld[i].sidenum[0];
    lines[i].sidenum[1] := mld[i].sidenum[1];

    // [crispy] substitute dummy sidedef for missing right side
    If (lines[i].sidenum[0] = NO_INDEX) Then Begin
      lines[i].sidenum[0] := 0;
      writeln(stderr, format('P_LoadLineDefs: linedef %d without first sidedef!', [i]));
    End;

    If (lines[i].sidenum[0] <> NO_INDEX) Then // [crispy] extended nodes
      lines[i].frontsector := sides[lines[i].sidenum[0]].sector
    Else
      lines[i].frontsector := Nil;

    If (lines[i].sidenum[1] <> NO_INDEX) Then // [crispy] extended nodes
      lines[i].backsector := sides[lines[i].sidenum[1]].sector
    Else
      lines[i].backsector := Nil;
  End;

  // [crispy] warn about unknown linedef types
  If (warn <> 0) Then Begin

    writeln(stderr, format('P_LoadLineDefs: Found %d line with unknown linedef type.', [warn]));
  End;
  // [crispy] warn about special linedefs without tag
  If (warn2 <> 0) Then Begin

    writeln(stderr, format('P_LoadLineDefs: Found %d special linedef without tag.', [warn2]));
  End;
  If (warn <> 0) Or (warn2 <> 0) Then Begin
    writeln(stderr, 'THIS MAP MAY NOT WORK AS EXPECTED!');
  End;

  //    W_ReleaseLumpNum(lump);
End;

Procedure P_LoadSubsectors(lump: int);
Var
  i: int;
  ms: Array Of mapsubsector_t;

Begin
  numsubsectors := W_LumpLength(lump) Div sizeof(mapsubsector_t);

  setlength(subsectors, numsubsectors);
  ms := W_CacheLumpNum(lump, PU_STATIC);

  // [crispy] fail on missing subsectors
  If (Not assigned(ms) Or (numsubsectors = 0)) Then Begin
    I_Error('P_LoadSubsectors: No subsectors in map!');
  End;
  FillChar(subsectors[0], numsubsectors * sizeof(subsector_t), 0);

  For i := 0 To numsubsectors - 1 Do Begin
    subsectors[i].numlines := ms[i].numsegs; // [crispy] extended nodes
    subsectors[i].firstline := ms[i].firstseg; // [crispy] extended nodes
  End;

  //    W_ReleaseLumpNum(lump);
End;

Procedure P_LoadNodes(lump: int);
Var
  i, j, k: int;
  mn: Array Of mapnode_t;
Begin
  numnodes := W_LumpLength(lump) Div sizeof(mapnode_t);
  //    nodes = Z_Malloc (numnodes*sizeof(node_t),PU_LEVEL,0);
  setlength(nodes, numnodes);
  mn := W_CacheLumpNum(lump, PU_STATIC);

  // [crispy] warn about missing nodes
  If (Not assigned(mn) Or (numnodes = 0)) Then Begin
    If (numsubsectors = 1) Then
      writeln(stderr, 'P_LoadNodes: No nodes in map, but only one subsector.')
    Else
      I_Error('P_LoadNodes: No nodes in map!');
  End;

  For i := 0 To numnodes - 1 Do Begin
    nodes[i].x := mn[i].x Shl FRACBITS;
    nodes[i].y := mn[i].y Shl FRACBITS;
    nodes[i].dx := mn[i].dx Shl FRACBITS;
    nodes[i].dy := mn[i].dy Shl FRACBITS;

    For j := 0 To 1 Do Begin

      nodes[i].children[j] := mn[i].children[j]; // [crispy] extended nodes

      // [crispy] add support for extended nodes
      // from prboom-plus/src/p_setup.c:937-957
      If (nodes[i].children[j] = NO_INDEX) Then
        nodes[i].children[j] := -1
      Else If ((nodes[i].children[j] And NF_SUBSECTOR_VANILLA) <> 0) Then Begin

        nodes[i].children[j] := nodes[i].children[j] And Not NF_SUBSECTOR_VANILLA;
        If (nodes[i].children[j] >= numsubsectors) Then Begin
          nodes[i].children[j] := 0;
        End;
        nodes[i].children[j] := int(nodes[i].children[j] Or NF_SUBSECTOR);
      End;
      For k := 0 To 3 Do Begin
        nodes[i].bbox[j][k] := mn[i].bbox[j][k] Shl FRACBITS;
      End;
    End;
  End;

  //    W_ReleaseLumpNum(lump);
End;

//
// GetSectorAtNullAddress
//
Var
  null_sector: sector_t;

Function GetSectorAtNullAddress(): Psector_t;
Const
  null_sector_is_initialized: boolean = false;
Begin

  If (Not null_sector_is_initialized) Then Begin
    FillChar(null_sector, sizeof(null_sector), 0);
    I_GetMemoryValue(0, @null_sector.floorheight, 4);
    I_GetMemoryValue(4, @null_sector.ceilingheight, 4);
    null_sector_is_initialized := true;
  End;

  result := @null_sector;
End;

Procedure P_LoadSegs(lump: int);
Var
  i: int;
  ml: ^mapseg_t; // Als Array of Crasht der Code, beim Laden von Doom1.wad
  linedef: int;
  side: int;
  sidenum: int;
Begin
  numsegs := W_LumpLength(lump) Div sizeof(mapseg_t);
  setlength(segs, numsegs);
  FillChar(segs[0], numsegs * sizeof(seg_t), 0);

  ml := W_CacheLumpNum(lump, PU_STATIC);
  For i := 0 To numsegs - 1 Do Begin
    segs[i].v1 := @vertexes[ml[i].v1]; // [crispy] extended nodes
    segs[i].v2 := @vertexes[ml[i].v2]; // [crispy] extended nodes

    segs[i].angle := unsigned_int(short(ml[i].angle) Shl FRACBITS);
    // segs[i].offset := ml[i].offset shl FRACBITS; // [crispy] recalculated below
    linedef := ml[i].linedef; // [crispy] extended nodes
    segs[i].linedef := @lines[linedef];
    side := ml[i].side;

    // e6y: check for wrong indexes
    If (linedef >= numlines) Then Begin
      I_Error(format('P_LoadSegs: seg %d references a non-existent linedef %d',
        [i, linedef]));
    End;

    If (lines[linedef].sidenum[side] >= numsides) Then Begin
      I_Error(format('P_LoadSegs: linedef %d for seg %d references a non-existent sidedef %d',
        [linedef, i, lines[linedef].sidenum[side]]));
    End;

    segs[i].sidedef := @sides[lines[linedef].sidenum[side]];
    segs[i].frontsector := sides[lines[linedef].sidenum[side]].sector;
    // [crispy] recalculate
    If ml[i].side <> 0 Then Begin
      segs[i].offset := GetOffset(segs[i].v1, lines[linedef].v2);
    End
    Else Begin
      segs[i].offset := GetOffset(segs[i].v1, lines[linedef].v1);
    End;

    If ((lines[linedef].flags And ML_TWOSIDED) <> 0) Then Begin
      sidenum := lines[linedef].sidenum[side Xor 1];

      // If the sidenum is out of range, this may be a "glass hack"
      // impassible window.  Point at side #0 (this may not be
      // the correct Vanilla behavior; however, it seems to work for
      // OTTAWAU.WAD, which is the one place I've seen this trick
      // used).

      If (sidenum < 0) Or (sidenum >= numsides) Then Begin

        // [crispy] linedef has two-sided flag set, but no valid second sidedef;
        // but since it has a midtexture, it is supposed to be rendered just
        // like a regular one-sided linedef
        If (segs[i].sidedef^.midtexture <> 0) Then Begin
          segs[i].backsector := Nil;
          writeln(stderr, format('P_LoadSegs: Linedef %d has two-sided flag set, but no second sidedef', [linedef]));
        End
        Else
          segs[i].backsector := GetSectorAtNullAddress();
      End
      Else Begin
        segs[i].backsector := sides[sidenum].sector;
      End;
    End
    Else Begin
      segs[i].backsector := Nil;
    End;
  End;

  W_ReleaseLumpNum(lump);
End;

//
// P_GroupLines
// Builds sector line lists and subsector sector numbers.
// Finds block bounding boxes for sectors.
//

Procedure P_GroupLines();
Var
  i, j: int;
  li: ^line_t;
  sector: ^sector_t;
  //subsector_t*	ss;
  seg: ^seg_t;
  bbox: Array[0..3] Of fixed_t;
  block: int;
Begin

  // look up sector number for each subsector
  For i := 0 To numsubsectors - 1 Do Begin
    seg := @segs[subsectors[i].firstline];
    subsectors[i].sector := seg^.sidedef^.sector;
  End;

  // count number of lines in each sector
  totallines := 0;
  For i := 0 To numlines - 1 Do Begin

    totallines := totallines + 1;
    lines[i].frontsector^.linecount := lines[i].frontsector^.linecount + 1;

    If assigned(lines[i].backsector) And (lines[i].backsector <> lines[i].frontsector) Then Begin
      lines[i].backsector^.linecount := lines[i].backsector^.linecount + 1;
      totallines := totallines + 1;
    End;
  End;

  // build line tables for each sector
  For i := 0 To numsectors - 1 Do Begin
    // Assign the line buffer for this sector
    setlength(sectors[i].lines, sectors[i].linecount);
    // Reset linecount to zero so in the next stage we can count
    // lines into the list.
    sectors[i].linecount := 0;
  End;

  // Assign lines to sectors

  For i := 0 To numlines - 1 Do Begin
    If (lines[i].frontsector <> Nil) Then Begin
      sector := lines[i].frontsector;
      sector^.lines[sector^.linecount] := lines[i];
      sector^.linecount := sector^.linecount + 1;
    End;
    If (lines[i].backsector <> Nil) And (lines[i].frontsector <> lines[i].backsector) Then Begin
      sector := lines[i].backsector;
      sector^.lines[sector^.linecount] := lines[i];
      sector^.linecount := sector^.linecount + 1;
    End;
  End;

  // Generate bounding boxes for sectors
  For i := 0 To numsectors - 1 Do Begin
    M_ClearBox(bbox);
    For j := 0 To sectors[i].linecount - 1 Do Begin
      li := @sectors[i].lines[j];
      M_AddToBox(bbox, li^.v1^.x, li^.v1^.y);
      M_AddToBox(bbox, li^.v2^.x, li^.v2^.y);
    End;

    // set the degenmobj_t to the middle of the bounding box
    If (crispy.soundfix = 0) Then Begin
      sectors[i].soundorg.x := (bbox[BOXRIGHT] + bbox[BOXLEFT]) Div 2;
      sectors[i].soundorg.y := (bbox[BOXTOP] + bbox[BOXBOTTOM]) Div 2;
    End
    Else Begin
      // [crispy] Andrey Budko: fix sound origin for large levels
      sectors[i].soundorg.x := bbox[BOXRIGHT] Div 2 + bbox[BOXLEFT] Div 2;
      sectors[i].soundorg.y := bbox[BOXTOP] Div 2 + bbox[BOXBOTTOM] Div 2;
    End;

    // adjust bounding box to map blocks
    block := SarLongint(bbox[BOXTOP] - bmaporgy + MAXRADIUS, MAPBLOCKSHIFT);
    If block >= bmapheight Then Begin
      block := bmapheight - 1;
    End;
    sectors[i].blockbox[BOXTOP] := block;

    block := SarLongint(bbox[BOXBOTTOM] - bmaporgy - MAXRADIUS, MAPBLOCKSHIFT);
    If block < 0 Then Begin
      block := 0;
    End;
    sectors[i].blockbox[BOXBOTTOM] := block;

    block := SarLongint(bbox[BOXRIGHT] - bmaporgx + MAXRADIUS, MAPBLOCKSHIFT);
    If block >= bmapwidth Then Begin
      block := bmapwidth - 1;
    End;
    sectors[i].blockbox[BOXRIGHT] := block;

    block := SarLongint(bbox[BOXLEFT] - bmaporgx - MAXRADIUS, MAPBLOCKSHIFT);
    If block < 0 Then Begin
      block := 0;
    End;
    sectors[i].blockbox[BOXLEFT] := block;
  End;
End;

// Pad the REJECT lump with extra data when the lump is too small,
// to simulate a REJECT buffer overflow in Vanilla Doom.

Procedure PadRejectArray(byte: Pbyte; len: unsigned_int);
//    unsigned int i;
//    unsigned int byte_num;
//    byte *dest;
//    unsigned int padvalue;
Begin
  Raise exception.create('PadRejectArray: nicht portiert');
  // Values to pad the REJECT array with:

//    unsigned int rejectpad[4] =
//    {
//        0,                                    // Size
//        0,                                    // Part of z_zone block header
//        50,                                   // PU_LEVEL
//        0x1d4a11                              // DOOM_CONST_ZONEID
//    };
//
//    rejectpad[0] = ((totallines * 4 + 3) & ~3) + 24;
//
//    // Copy values from rejectpad into the destination array.
//
//    dest = array;
//
//    for (i=0; i<len && i<sizeof(rejectpad); ++i)
//    {
//        byte_num = i % 4;
//        *dest = (rejectpad[i / 4] >> (byte_num * 8)) & 0xff;
//        ++dest;
//    }
//
//    // We only have a limited pad size.  Print a warning if the
//    // REJECT lump is too small.
//
//    if (len > sizeof(rejectpad))
//    {
//        fprintf(stderr, "PadRejectArray: REJECT lump too short to pad! (%u > %i)\n",
//                        len, (int) sizeof(rejectpad));
//
//        // Pad remaining space with 0 (or 0xff, if specified on command line).
//
//        if (M_CheckParm("-reject_pad_with_ff"))
//        {
//            padvalue = 0xff;
//        }
//        else
//        {
//            padvalue = 0x00;
//        }
//
//        memset(array + sizeof(rejectpad), padvalue, len - sizeof(rejectpad));
//    }
End;

Procedure P_LoadReject(lumpnum: int);
Var
  minlength, lumplen: int;
Begin

  // Calculate the size that the REJECT lump *should* be.

  minlength := (numsectors * numsectors + 7) Div 8;

  // If the lump meets the minimum length, it can be loaded directly.
  // Otherwise, we need to allocate a buffer of the correct size
  // and pad it with appropriate data.

  lumplen := W_LumpLength(lumpnum);

  If (lumplen >= minlength) Then Begin
    rejectmatrix := W_CacheLumpNum(lumpnum, PU_LEVEL);
  End
  Else Begin
    setlength(rejectmatrix, minlength);
    W_ReadLump(lumpnum, @rejectmatrix[0]);
    PadRejectArray(@rejectmatrix[lumplen], minlength - lumplen);
  End;
End;


// [crispy] remove slime trails
// mostly taken from Lee Killough's implementation in mbfsrc/P_SETUP.C:849-924,
// with the exception that not the actual vertex coordinates are modified,
// but separate coordinates that are *only* used in rendering,
// i.e. r_bsp.c:R_AddLine()

Procedure P_RemoveSlimeTrails();
Var
  i: int;
  dx2, dy2, dxy, s: int64;
  flag: Boolean;
  v: ^vertex_t; // Das ist fieß, der wechselt in der Repeat schleife von V1 nach V2, deswegen muss das ein Pointer bleiben..
Begin
  For i := 0 To numsegs - 1 Do Begin
    // [crispy] ignore exactly vertical or horizontal linedefs
    If (segs[i].linedef^.dx <> 0) And (segs[i].linedef^.dy <> 0) Then Begin
      v := segs[i].v1;
      Repeat
        // [crispy] vertex wasn't already moved
        If (Not v^.moved) Then Begin
          v^.moved := true;
          // [crispy] ignore endpoints of linedefs
          If (v <> segs[i].linedef^.v1) And (v <> segs[i].linedef^.v2) Then Begin

            // [crispy] move the vertex towards the linedef
            // by projecting it using the law of cosines
            dx2 := (SarLongint(segs[i].linedef^.dx, FRACBITS)) * (SarLongint(segs[i].linedef^.dx, FRACBITS));
            dy2 := (SarLongint(segs[i].linedef^.dy, FRACBITS)) * (SarLongint(segs[i].linedef^.dy, FRACBITS));
            dxy := (SarLongint(segs[i].linedef^.dx, FRACBITS)) * (SarLongint(segs[i].linedef^.dy, FRACBITS));
            s := dx2 + dy2;

            // [crispy] MBF actually overrides v^.x and v^.y here
            v^.r_x := fixed_t(((dx2 * v^.x + dy2 * segs[i].linedef^.v1^.x + dxy * (v^.y - segs[i].linedef^.v1^.y)) Div s));
            v^.r_y := fixed_t(((dy2 * v^.y + dx2 * segs[i].linedef^.v1^.y + dxy * (v^.x - segs[i].linedef^.v1^.x)) Div s));

            // [crispy] wait a minute... moved more than 8 map units?
            // maybe that's a linguortal then, back to the original coordinates
            If (abs(v^.r_x - v^.x) > 8 * FRACUNIT) Or (abs(v^.r_y - v^.y) > 8 * FRACUNIT) Then Begin
              v^.r_x := v^.x;
              v^.r_y := v^.y;
              // WTF: eigentlich müsste hier doch  v^.moved := false; noch stehen
            End;
          End;
        End;
        // [crispy] if v^ doesn't point to the second vertex of the seg already, point it there
        flag := false;
        If (v <> segs[i].v2) Then Begin
          v := segs[i].v2;
          flag := assigned(v);
        End;
      Until (Not flag);
    End;
  End;
End;

Function anglediff(a, b: angle_t): angle_t;
Begin
  If (b > a) Then Begin
    result := anglediff(b, a);
    exit;
  End;
  If (a - b < ANG180) Then Begin
    result := a - b;
  End
  Else Begin // [crispy] wrap around
    result := angle_t(b - a);
  End;
End;

Procedure P_SegLengths(contrast_only: boolean);
Var
  i: int;
  rightangle: int;
  dx, dy: int64_t;
Begin
  rightangle := abs(finesine[SarLongint(ANG60 Div 2, ANGLETOFINESHIFT)]);

  For i := 0 To numsegs - 1 Do Begin

    dx := segs[i].v2^.r_x - segs[i].v1^.r_x;
    dy := segs[i].v2^.r_y - segs[i].v1^.r_y;

    If (Not contrast_only) Then Begin

      segs[i].length := trunc(sqrt(dx * dx + dy * dy) / 2);

      // [crispy] re-calculate angle used for rendering
      viewx := segs[i].v1^.r_x;
      viewy := segs[i].v1^.r_y;
      segs[i].r_angle := R_PointToAngleCrispy(segs[i].v2^.r_x, segs[i].v2^.r_y);
      // [crispy] more than just a little adjustment?
      // back to the original angle then
      If (anglediff(segs[i].r_angle, segs[i].angle) > ANG60 Div 2) Then Begin
        segs[i].r_angle := segs[i].angle;
      End;
    End;

    // [crispy] smoother fake contrast
    If (dy = 0) Then
      segs[i].fakecontrast := -LIGHTBRIGHT
    Else Begin
      If (abs(finesine[segs[i].r_angle Shr ANGLETOFINESHIFT]) < rightangle) Then
        segs[i].fakecontrast := -LIGHTBRIGHT Div 2
      Else If (dx = 0) Then
        segs[i].fakecontrast := LIGHTBRIGHT
      Else If (abs(finecosine[segs[i].r_angle Shr ANGLETOFINESHIFT]) < rightangle) Then
        segs[i].fakecontrast := LIGHTBRIGHT Div 2
      Else
        segs[i].fakecontrast := 0;
    End;
  End;
End;

Procedure P_LoadThings(lump: int);
Var
  i: int;
  mt: ^mapthing_t;
  spawnthing: mapthing_t;
  numthings: int;
  spawn: Boolean;
Begin
  FreeAllocations(); // Alle bisher erstellen Map Opjecte werden nicht mehr gebraucht, also weg damit ..
  numthings := W_LumpLength(lump) Div sizeof(mapthing_t);

  mt := W_CacheLumpNum(lump, PU_STATIC);
  For i := 0 To numthings - 1 Do Begin
    spawn := true;
    // Do not spawn cool, new monsters if !commercial
    If (gamemode <> commercial) Then Begin
      Case mt[i]._type Of
        68, // Arachnotron
        64, // Archvile
        88, // Boss Brain
        89, // Boss Shooter
        69, // Hell Knight
        67, // Mancubus
        71, // Pain Elemental
        65, // Former Human Commando
        66, // Revenant
        84: Begin // Wolf SS
            spawn := false;
          End;
      End;
      If (Not spawn) Then break;
    End;
    // Do spawn all other stuff.
    spawnthing.x := mt[i].x;
    spawnthing.y := mt[i].y;
    spawnthing.angle := mt[i].angle;
    spawnthing._type := mt[i]._type;
    spawnthing.options := mt[i].options;

    P_SpawnMapThing(@spawnthing);
  End;

  If (deathmatch = 0) Then Begin
    For i := 0 To MAXPLAYERS - 1 Do Begin
      If (playeringame[i]) And (Not playerstartsingame[i]) Then Begin
        I_Error(format('P_LoadThings: Player %d start missing (vanilla crashes here)', [i + 1]));
      End;
      playerstartsingame[i] := false;
    End;
  End;

  W_ReleaseLumpNum(lump);
End;

Procedure P_SetupLevel(episode, map, playermask: int; skill: skill_t);
Var
  lumpnum, i: Int;
  rfn_str {, lumpname}: String;
  ltime, ttime: int;
  crispy_mapformat: mapformat_t;
  crispy_validblockmap: Boolean;
Begin
  totalkills := 0;
  totalitems := 0;
  totalsecret := 0;
  wminfo.maxfrags := 0;

  // [crispy] count spawned monsters
  extrakills := 0;
  wminfo.partime := 180;
  For i := 0 To MAXPLAYERS - 1 Do Begin
    players[i].killcount := 0;
    players[i].secretcount := 0;
    players[i].itemcount := 0;
  End;

  // [crispy] NRFTL / The Master Levels
//    if (crispy->havenerve || crispy->havemaster)
//    {
//        if (crispy->havemaster && episode == 3)
//        {
//            gamemission = pack_master;
//        }
//        else
//        if (crispy->havenerve && episode == 2)
//        {
//            gamemission = pack_nerve;
//        }
//        else
//        {
//            gamemission = doom2;
//        }
//    }
//    else
  Begin
    If (gamemission = pack_master) Then Begin
      episode := 3;
      gameepisode := 3;
    End
    Else If (gamemission = pack_nerve) Then Begin
      episode := 2;
      gameepisode := 2;
    End;
  End;

  // Initial height of PointOfView
  // will be set by player think.
  players[consoleplayer].viewz := 1;

  // [crispy] stop demo warp mode now
//    if (crispy->demowarp == map)
//    {
//	crispy->demowarp = 0;
//	nodrawers = false;
//	singletics = false;
//    }

    // [crispy] don't load map's default music if loaded from a savegame with MUSINFO data
  If (Not musinfo.from_savegame) Then Begin

    // Make sure all sounds are stopped before Z_FreeTags.
    S_Start();
  End;
  musinfo.from_savegame := false;

  //    Z_FreeTags (PU_LEVEL, PU_PURGELEVEL-1); --> Sagt dem SpeicherManager er soll alles Platt machen was er bisher zu "Levels" geladen hat ...

  // UNUSED W_Profile ();
  P_InitThinkers();

  // if working with a devlopment map, reload it
  W_Reload();

  // [crispy] factor out map lump name and number finding into a separate function
(*
      // find map name
      if ( gamemode == commercial)
      {
   if (map<10)
       DEH_snprintf(lumpname, 9, "map0%i", map);
   else
       DEH_snprintf(lumpname, 9, "map%i", map);
      }
      else
      {
   lumpname[0] = 'E';
   lumpname[1] = '0' + episode;
   lumpname[2] = 'M';
   lumpname[3] = '0' + map;
   lumpname[4] = 0;
      }

      lumpnum = W_GetNumForName (lumpname);
  *)
  lumpnum := P_GetNumForMap(episode, map, true);

  maplumpinfo := @lumpinfo[lumpnum];
  //lumpname := lumpinfo[lumpnum].name;

  leveltime := 0;
  oldleveltime := 0;

  // [crispy] better logging
  Begin

    ltime := savedleveltime Div TICRATE;
    ttime := (totalleveltimes + savedleveltime) Div TICRATE;
    rfn_str :=
      IfThen(respawnparm, ' -respawn', '') +
      IfThen(fastparm, ' -fast', '') +
      IfThen(nomonsters, ' -nomonsters', '');

    write(stderr,
      format('P_SetupLevel: %s (%s) %s%s %d:%0.2d:%0.2d/%d:%0.2d:%0.2d ',
      [maplumpinfo^.name, W_WadNameForLump(maplumpinfo^),
      skilltable[integer(skill) + 1], rfn_str,
        ltime Div 3600, (ltime Mod 3600) Div 60, ltime Mod 60,
        ttime Div 3600, (ttime Mod 3600) Div 60, ttime Mod 60]));
  End;
  // [crispy] check and log map and nodes format
  crispy_mapformat := P_CheckMapFormat(lumpnum);

  // note: most of this ordering is important
  crispy_validblockmap := P_LoadBlockMap(lumpnum + ML_BLOCKMAP); // [crispy] (re-)create BLOCKMAP if necessary
  P_LoadVertexes(lumpnum + ML_VERTEXES);
  P_LoadSectors(lumpnum + ML_SECTORS);
  P_LoadSideDefs(lumpnum + ML_SIDEDEFS);

  If (crispy_mapformat = MFMT_HEXEN) Then Begin
    //    P_LoadLineDefs_Hexen(lumpnum + ML_LINEDEFS)
  End
  Else Begin
    P_LoadLineDefs(lumpnum + ML_LINEDEFS);
  End;
  // [crispy] (re-)create BLOCKMAP if necessary
  If (Not crispy_validblockmap) Then Begin
    P_CreateBlockMap();
  End;
  If (crispy_mapformat In [MFMT_ZDBSPX, MFMT_ZDBSPZ]) Then Begin
    Raise exception.create('P_SetupLevel, fehlender code.');
    //	P_LoadNodes_ZDBSP (lumpnum+ML_NODES, crispy_mapformat & MFMT_ZDBSPZ);
  End
  Else Begin
    If (crispy_mapformat = MFMT_DEEPBSP) Then Begin
      Raise exception.create('P_SetupLevel, fehlender code.');
      //	P_LoadSubsectors_DeePBSP (lumpnum+ML_SSECTORS);
      //	P_LoadNodes_DeePBSP (lumpnum+ML_NODES);
      //	P_LoadSegs_DeePBSP (lumpnum+ML_SEGS);
    End
    Else Begin
      P_LoadSubsectors(lumpnum + ML_SSECTORS);
      P_LoadNodes(lumpnum + ML_NODES);
      P_LoadSegs(lumpnum + ML_SEGS);
    End;
  End;

  P_GroupLines();
  P_LoadReject(lumpnum + ML_REJECT);

  // [crispy] remove slime trails
  P_RemoveSlimeTrails();
  // [crispy] fix long wall wobble
  P_SegLengths(false);
  // [crispy] blinking key or skull in the status bar
//    memset(st_keyorskull, 0, sizeof(st_keyorskull));

  bodyqueslot := 0;
  deathmatch_p := 0;
  If (crispy_mapformat = MFMT_HEXEN) Then Begin
    //	P_LoadThings_Hexen (lumpnum+ML_THINGS);
  End
  Else Begin
    P_LoadThings(lumpnum + ML_THINGS);
  End;

  // if deathmatch, randomly spawn the active players
  If (deathmatch <> 0) Then Begin
    For i := 0 To MAXPLAYERS - 1 Do Begin
      If (playeringame[i]) Then Begin
        players[i].mo := Nil;
        G_DeathMatchSpawnPlayer(i);
      End;
    End;
  End;

  // [crispy] support MUSINFO lump (dynamic music changing)
  If (gamemode <> shareware) Then Begin
    S_ParseMusInfo(lumpinfo[lumpnum].name);
  End;

  // clear special respawning que
  iquehead := 0;
  iquetail := 0;

  // set up world state
  P_SpawnSpecials();

  // build subsector connect matrix
  //	UNUSED P_ConnectSubsectors ();

  // preload graphics
  If (precache) Then R_PrecacheLevel();

  //printf ("free memory: 0x%x\n", Z_FreeMemory());
End;

Procedure P_Init();
Begin
  P_InitSwitchList();
  P_InitPicAnims();
  R_InitSprites(sprnames);
End;


End.

