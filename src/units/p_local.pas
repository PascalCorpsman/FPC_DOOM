Unit p_local;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , info_types
  , m_fixed
  ;
Const
  // [crispy] blinking key or skull in the status bar
  KEYBLINKMASK = $8;
  KEYBLINKTICS = (7 * KEYBLINKMASK);

  TOCENTER = -8;
  AFLAG_JUMP = $80;
  FLOATSPEED = (FRACUNIT * 4);

  MAXHEALTH = 100;
  DEFINE_VIEWHEIGHT = (41 * FRACUNIT);

  // mapblocks are used to check movement
  // against lines and things
  MAPBLOCKUNITS = 128;
  MAPBLOCKSIZE = (MAPBLOCKUNITS * FRACUNIT);
  MAPBLOCKSHIFT = (FRACBITS + 7);
  MAPBMASK = (MAPBLOCKSIZE - 1);
  MAPBTOFRAC = (MAPBLOCKSHIFT - FRACBITS);


  // player radius for movement checking
  PLAYERRADIUS = 16 * FRACUNIT;

  // MAXRADIUS is for precalculated sector block boxes
  // the spider demon is larger,
  // but we do not have any moving sectors nearby
  MAXRADIUS = 32 * FRACUNIT;

  GRAVITY = FRACUNIT;
  MAXMOVE = (30 * FRACUNIT);

  USERANGE = (64 * FRACUNIT);
  MELEERANGE = (64 * FRACUNIT);
  MISSILERANGE = (32 * 64 * FRACUNIT);

  // follow a player exlusively for 3 seconds
  BASETHRESHOLD = 100;

  // fraggle: I have increased the size of this buffer.  In the original Doom,
  // overrunning past this limit caused other bits of memory to be overwritten,
  // affecting demo playback.  However, in doing so, the limit was still
  // exceeded.  So we have to support more than 8 specials.
  //
  // We keep the original limit, to detect what variables in memory were
  // overwritten (see SpechitOverrun())
  MAXSPECIALCROSS = 20;
  MAXSPECIALCROSS_ORIGINAL = 8;

  //
  // P_TICK
  //

  // both the head and tail of the thinker list
  //extern	thinker_t	thinkercap;


  //void P_InitThinkers (void);
  //void P_AddThinker (thinker_t* thinker);
  //void P_RemoveThinker (thinker_t* thinker);


  //
  // P_PSPR
  //
  //void P_SetupPsprites (player_t* curplayer);
  //void P_MovePsprites (player_t* curplayer);
  //void P_DropWeapon (player_t* player);


  //
  // P_USER
  //
Const
  MLOOKUNIT = 8;

  //
  // P_MOBJ
  //
  ONFLOORZ = INT_MIN;
  ONCEILINGZ = INT_MAX;

  // Time interval for item respawning.
  ITEMQUESIZE = 128;

Type
  //
  // P_MAPUTL
  //
  divline_t = Record
    x: fixed_t;
    y: fixed_t;
    dx: fixed_t;
    dy: fixed_t;
  End;
  Pdivline_t = ^divline_t;

  dt = Record
    Case boolean Of
      true: (thing: pmobj_t);
      false: (line: pline_t);
  End;

  intercept_t = Record
    frac: fixed_t; // along trace line
    isaline: boolean;
    d: dt;
  End;

  Pintercept_t = ^intercept_t;

  traverser_t = Function(_in: Pintercept_t): Boolean;

  //// Extended MAXINTERCEPTS, to allow for intercepts overrun emulation.
  //
Const
  MAXINTERCEPTS_ORIGINAL = 128;
  //#define MAXINTERCEPTS          (MAXINTERCEPTS_ORIGINAL + 61)
  //
  ////extern intercept_t	intercepts[MAXINTERCEPTS]; // [crispy] remove INTERCEPTS limit
  //extern intercept_t*	intercept_p;
  //
  //typedef boolean (*traverser_t) (intercept_t *in);
  //
  //fixed_t P_AproxDistance (fixed_t dx, fixed_t dy);
  //int 	P_PointOnLineSide (fixed_t x, fixed_t y, line_t* line);
  //int 	P_PointOnDivlineSide (fixed_t x, fixed_t y, divline_t* line);
  //void 	P_MakeDivline (line_t* li, divline_t* dl);
  //fixed_t P_InterceptVector (divline_t* v2, divline_t* v1);
  //int 	P_BoxOnLineSide (fixed_t* tmbox, line_t* ld);
  //
  //extern fixed_t		opentop;
  //extern fixed_t 		openbottom;
  //extern fixed_t		openrange;
  //extern fixed_t		lowfloor;
  //
  //void 	P_LineOpening (line_t* linedef);
  //
  //boolean P_BlockLinesIterator (int x, int y, boolean(*func)(line_t*) );
  //boolean P_BlockThingsIterator (int x, int y, boolean(*func)(mobj_t*) );

Const
  PT_ADDLINES = 1;
  PT_ADDTHINGS = 2;
  PT_EARLYOUT = 4;

  //extern divline_t	trace;
  //
  //boolean
  //P_PathTraverse
  //( fixed_t	x1,
  //  fixed_t	y1,
  //  fixed_t	x2,
  //  fixed_t	y2,
  //  int		flags,
  //  boolean	(*trav) (intercept_t *));
  //
  //void P_UnsetThingPosition (mobj_t* thing);
  //void P_SetThingPosition (mobj_t* thing);
  //
  //
  ////
  //// P_MAP
  ////
  //
  //// If "floatok" true, move would be ok
  //// if within "tmfloorz - tmceilingz".
  //extern boolean		floatok;
  //extern fixed_t		tmfloorz;
  //extern fixed_t		tmceilingz;
  //
  //
  //extern	line_t*		ceilingline;
  //
  //// fraggle: I have increased the size of this buffer.  In the original Doom,
  //// overrunning past this limit caused other bits of memory to be overwritten,
  //// affecting demo playback.  However, in doing so, the limit was still
  //// exceeded.  So we have to support more than 8 specials.
  ////
  //// We keep the original limit, to detect what variables in memory were
  //// overwritten (see SpechitOverrun())
  //
  //#define MAXSPECIALCROSS 		20
  //#define MAXSPECIALCROSS_ORIGINAL	8
  //
  //extern	line_t**	spechit; // [crispy] remove SPECHIT limit
  //extern	int	numspechit;
  //
  //boolean P_CheckPosition (mobj_t *thing, fixed_t x, fixed_t y);
  //boolean P_TryMove (mobj_t* thing, fixed_t x, fixed_t y);
  //boolean P_TeleportMove (mobj_t* thing, fixed_t x, fixed_t y);
  //void	P_SlideMove (mobj_t* mo);
  //boolean P_CheckSight (mobj_t* t1, mobj_t* t2);
  //void 	P_UseLines (player_t* player);
  //
  //boolean P_ChangeSector (sector_t* sector, boolean crunch);
  //
  //extern mobj_t*	linetarget;	// who got hit (or NULL)
  //
  //
  //extern fixed_t attackrange;
  //
  //// slopes to top and bottom of target
  //extern fixed_t	topslope;
  //extern fixed_t	bottomslope;

  //fixed_t
  //P_AimLineAttack
  //( mobj_t*	t1,
  //  angle_t	angle,
  //  fixed_t	distance );

  //void
  //P_RadiusAttack
  //( mobj_t*	spot,
  //  mobj_t*	source,
  //  int		damage );

  ////
  //// P_SETUP
  ////
  //extern byte*		rejectmatrix;	// for fast sight rejection
  //extern int32_t*	blockmaplump;	// offsets in blockmap are from here // [crispy] BLOCKMAP limit
  //extern int32_t*	blockmap; // [crispy] BLOCKMAP limit
  //extern int		bmapwidth;
  //extern int		bmapheight;	// in mapblocks
  //extern fixed_t		bmaporgx;
  //extern fixed_t		bmaporgy;	// origin of block map
  //extern mobj_t**		blocklinks;	// for thing chains
  //
  //// [crispy] factor out map lump name and number finding into a separate function
  //extern int P_GetNumForMap (int episode, int map, boolean critical);

  //extern int st_keyorskull[3];
  //
  ////
  //// P_INTER
  ////
  //extern int		maxammo[NUMAMMO];
  //extern int		clipammo[NUMAMMO];
  //
  //void
  //P_TouchSpecialThing
  //( mobj_t*	special,
  //  mobj_t*	toucher );
  //
  //void
  //P_DamageMobj
  //( mobj_t*	target,
  //  mobj_t*	inflictor,
  //  mobj_t*	source,
  //  int		damage );

Function PLAYER_SLOPE(a: pplayer_t): fixed_t;

Implementation

Function PLAYER_SLOPE(a: pplayer_t): fixed_t;
Begin
  result := SarLongint(a^.lookdir Div MLOOKUNIT, FRACBITS) Div 173;
End;

End.

