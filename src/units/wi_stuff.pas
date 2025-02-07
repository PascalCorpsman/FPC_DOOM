Unit wi_stuff;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , v_patch
  ;

Type

  animenum_t = (
    ANIM_ALWAYS,
    ANIM_RANDOM,
    ANIM_LEVEL
    );

  point_t = Record
    x: int;
    y: int;
  End;


Implementation

Type
  //
  // Animation.
  // There is another anim_t used in p_spec.
  //

  anim_t = Record

    _type: animenum_t;

    // period in tics between animations
    period: int;

    // number of animation frames
    nanims: int;

    // location of animation
    loc: point_t;

    // ALWAYS: n/a,
    // RANDOM: period deviation (<256),
    // LEVEL: level
    data1: int;

    // ALWAYS: n/a,
    // RANDOM: random base period,
    // LEVEL: n/a
    data2: int;

    // actual graphics for frames of animations
    p: Array[0..3] Of Ppatch_t;

    // following must be initialized to zero before use!

    // next value of bcnt (used in conjunction with period)
    nexttic: int;

    // last drawn animation frame
    lastdrawn: int;

    // next frame number to animate
    ctr: int;

    // used by RANDOM and LEVEL when animating
    state: int;
  End;

End.

