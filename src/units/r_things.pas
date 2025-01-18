Unit r_things;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , r_defs
  ;

Var
  // variables used to look up
  //  and range check thing_t sprites patches
  numsprites: int;

  // [crispy] A11Y number of player sprites to draw
  numrpsprites: int = integer(spritenum_t(NUMPSPRITES)); // [crispy] A11Y number of player sprites to draw

  sprites: Array Of spritedef_t = Nil;
  pspr_interp: boolean = true; // interpolate weapon bobbing

Procedure R_InitSprites(Const namelist: Array Of String);

Implementation

Uses
  doomstat
  , i_video, i_system
  , r_data
  , w_wad
  ;

Var
  // constant arrays
  //  used for psprite clipping and initializing clipping
  negonearray: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math
  screenheightarray: Array[0..MAXWIDTH - 1] Of int; // [crispy] 32-bit integer math

  maxframe: int;
  sprtemp: Array[0..28] Of spriteframe_t;
  spritename: String;

  //
  // R_InstallSpriteLump
  // Local function for R_InitSprites.
  //

Procedure R_InstallSpriteLump(lump: int; frame: unsigned; rot: char; flipped: boolean);
Var
  r: int;
  rotation: unsigned;
Begin
  // [crispy] support 16 sprite rotations
  If ord(rot) >= ord('A') Then Begin
    rotation := ord(rot) - ord('A') + 10;
  End
  Else Begin
    If ord(rot) >= ord('0') Then Begin
      rotation := ord(rot) - ord('0');
    End
    Else Begin
      rotation := 17;
    End;
  End;

  If (frame >= 29) Or (rotation > 16) Then // [crispy] support 16 sprite rotations
    I_Error(format('R_InstallSpriteLump: Bad frame characters in lump %d', [lump]));

  If (frame > maxframe) Then maxframe := frame;

  If (rotation = 0) Then Begin
    // the lump should be used for all rotations
    // [crispy] make non-fatal
    If (sprtemp[frame].rotate = 0) Then Begin
      writeln(stderr, format('R_InitSprites: Sprite %s frame %s has multip rot = 0 lump',
        [spritename, chr(ord('A') + frame)]));
    End;

    // [crispy] make non-fatal
    If (sprtemp[frame].rotate = 1) Then Begin
      writeln(stderr, format('R_InitSprites: Sprite %s frame %s has rotations and a rot=0 lump',
        [spritename, chr(ord('A') + frame)]));
    End;

    //    [crispy]moved...
    // sprtemp[frame].rotate = false;
    For r := 0 To 8 - 1 Do Begin
      // [crispy] only if not yet substituted
      If (sprtemp[frame].lump[r] = -1) Then Begin

        sprtemp[frame].lump[r] := lump - firstspritelump;
        sprtemp[frame].flip[r] := ord(flipped);
        // [crispy] ... here
        sprtemp[frame].rotate := 0;
      End;
    End;
    exit;
  End;

  // the lump is only used for one rotation
  // [crispy] make non-fatal
  If (sprtemp[frame].rotate = 0) Then Begin
    writeln(stderr, format('R_InitSprites: Sprite %s frame %s has rotations and a rot=0 lump',
      [spritename, chr(ord('A') + frame)]));
  End;
  // [crispy] moved ...
  //    sprtemp[frame].rotate = true;

  // make 0 based
  rotation := rotation - 1;
  If (sprtemp[frame].lump[rotation] <> -1) Then Begin

    // [crispy] make non-fatal
    writeln(stderr, format('R_InitSprites: Sprite %s : %s : %s has two lumps mapped to it',
      [spritename, chr(ord('A') + frame), chr(ord('1') + rotation)]));
    exit;
  End;

  sprtemp[frame].lump[rotation] := lump - firstspritelump;
  sprtemp[frame].flip[rotation] := ord(flipped);
  // [crispy] ... here
  sprtemp[frame].rotate := 1;
End;

//
// R_InitSpriteDefs
// Pass a null terminated list of sprite names
//  (4 chars exactly) to be used.
// Builds the sprite rotation matrixes to account
//  for horizontally flipped sprites.
// Will report an error if the lumps are inconsistant.
// Only called at startup.
//
// Sprite lump names are 4 characters for the actor,
//  a letter for the frame, and a number for the rotation.
// A sprite that is flippable will have an additional
//  letter/number appended.
// The rotation character can be 0 to signify no rotations.
//

Procedure R_InitSpriteDefs(Const namelist: Array Of String);
Var
  rotation: char;
  frame, i, l, r: int;
  start: int;
  _end: int;
  patched: int;
Begin
  numsprites := length(namelist);

  If (numsprites = 0) Then exit;
  setlength(sprites, numsprites);
  start := firstspritelump - 1;
  _end := lastspritelump + 1;

  // scan all the lump names for each of the names,
  //  noting the highest frame letter.
  // Just compare 4 characters as ints
  For i := 0 To numsprites - 1 Do Begin

    spritename := namelist[i];
    FillChar(sprtemp[0], sizeof(sprtemp), $FF);

    maxframe := -1;

    // scan the lumps,
    //  filling in the frames for whatever is found
    For l := start + 1 To _end - 1 Do Begin

      If copy(lumpinfo[l].name, 1, 4) = uppercase(copy(spritename, 1, 4)) Then Begin
        frame := ord(lumpinfo[l].name[5]) - ord('A');
        rotation := lumpinfo[l].name[6];

        If (modifiedgame) Then Begin
          patched := W_GetNumForName(lumpinfo[l].name);
        End
        Else Begin
          patched := l;
        End;

        R_InstallSpriteLump(patched, frame, rotation, false);

        If length(lumpinfo[l].name) >= 8 Then Begin
          frame := ord(lumpinfo[l].name[7]) - ord('A');
          rotation := lumpinfo[l].name[8];
          R_InstallSpriteLump(l, frame, rotation, true);
        End;
      End;
    End;

    // check the frames that were found for completeness
    If (maxframe = -1) Then Begin
      sprites[i].numframes := 0;
      continue;
    End;

    maxframe := maxframe + 1;

    For Frame := 0 To maxframe - 1 Do Begin
      Case sprtemp[frame].rotate Of
        -1: Begin
            // no rotations were found for that frame at all
            // [crispy] make non-fatal
            writeln(stderr, format('R_InitSprites: No patches found for %s frame %s\',
              [spritename, chr(frame + ord('A'))]));
          End;
        0: Begin
            // only the first rotation is needed
          End;
        1: Begin
            // must have all 8 frames

            For r := 0 To 8 - 1 Do Begin
              If (sprtemp[frame].lump[r] = -1) Then Begin
                I_Error(format('R_InitSprites: Sprite %s frame %s is missing rotations',
                  [spritename, chr(frame + ord('A'))]));
              End;
            End;
            // [crispy] support 16 sprite rotations
            sprtemp[frame].rotate := 2;
            For r := 8 To 16 - 1 Do Begin
              If (sprtemp[frame].lump[r] = -1) Then Begin
                sprtemp[frame].rotate := 1;
                break;
              End;
            End;
          End;
      End;
    End;

    // allocate space for the frames present and copy sprtemp to it
    sprites[i].numframes := maxframe;
    setlength(sprites[i].spriteframes, maxframe);
    move(sprtemp[0], sprites[i].spriteframes[0], maxframe * sizeof(spriteframe_t));
  End;
End;

//
// R_InitSprites
// Called at program start.
//

Procedure R_InitSprites(Const namelist: Array Of String);
Var
  i: int;
Begin
  For i := 0 To SCREENWIDTH - 1 Do Begin // WTF: das wird aufgerufen befor SCREENWIDTH initialisiert wird -> Eigentlich nutzlos
    negonearray[i] := -1;
  End;

  R_InitSpriteDefs(namelist);
End;

End.

