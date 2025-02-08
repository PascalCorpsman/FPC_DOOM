Unit wi_stuff;

{$MODE ObjFPC}{$H+}

Interface

Uses
  ufpc_doom_types, Classes, SysUtils
  , d_player
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

  // Called by main loop, animate the intermission.
Procedure WI_Ticker();

// Called by main loop,
// draws the intermission directly into the screen buffer.
Procedure WI_Drawer();

// Setup for an intermission screen.
Procedure WI_Start(wbstartstruct: Pwbstartstruct_t);

// Shut down the intermission screen
Procedure WI_End();

Implementation

Uses
  doomstat, doomdef, sounds, info_types
  , d_mode, d_event
  , i_timer, i_video
  , g_game
  , hu_stuff
  , p_spec, p_setup, p_tick
  , s_sound, st_stuff
  , v_video
  , w_wad
  , z_zone
  ;

Const
  WI_TITLEY = 2;

  // SINGPLE-PLAYER STUFF
  SP_STATSX = 50;
  SP_STATSY = 50;
  SP_TIMEX = 16;
  SP_TIMEY = (ORIGHEIGHT - 32);

Type

  load_callback_t = Procedure(Lumname: String; Variable: PPPatch_t);

  //
  // Animation.
  // There is another anim_t used in p_spec.
  //

  wianim_t = Record

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
  Pwianim_t = ^wianim_t;
  WiAnim_tArray = Array Of wianim_t;

  stateenum_t =
    (
    NoState = -1,
    StatCount,
    ShowNextLoc
    );

  //
  // GENERAL DATA
  //
Const
  //
  // Locally used stuff.
  //

  // States for single-player
  SP_KILLS = 0;
  SP_ITEMS = 2;
  SP_SECRET = 4;
  SP_FRAGS = 6;
  SP_TIME = 8;
  //SP_PAR = ST_TIME;

  SP_PAUSE = 1;

  // in seconds
  SHOWNEXTLOCDELAY = 4;
  SHOWLASTLOCDELAY = SHOWNEXTLOCDELAY;

  // Different between registered DOOM (1994) and
  //  Ultimate DOOM - Final edition (retail, 1995?).
  // This is supposedly ignored for commercial
  //  release (aka DOOM II), which had 34 maps
  //  in one episode. So there.
  NUMEPISODES = 4;
  DEFINE_NUMMAPS = 9;

Var
  // used to accelerate or skip a stage
  acceleratestage: int;

  // wbs->pnum
  me: int;

  // specifies current state
  state: stateenum_t;

  // contains information passed into intermission
  wbs: Pwbstartstruct_t;

  plrs: Pwbplayerstruct_t; // wbs->plyr[]

  // used for general timing
  cnt: int;

  // used for timing of background animation
  bcnt: int;

  // signals to refresh everything for one frame
  firstrefresh: int;

  cnt_kills: Array[0..MAXPLAYERS - 1] Of int;
  cnt_items: Array[0..MAXPLAYERS - 1] Of int;
  cnt_secret: Array[0..MAXPLAYERS - 1] Of int;
  cnt_time: int;
  cnt_par: int;
  cnt_pause: int;
  snl_pointeron: boolean = false;

  // # of commercial levels
  NUMCMAPS: int = 32;

  //
  //	GRAPHICS
  //

  // You Are Here graphic
  yah: Array[0..2] Of Ppatch_t = (Nil, Nil, Nil);

  // splat
  splat: Array[0..1] Of ppatch_t = (Nil, Nil);

  //  // %, : graphics
  percent: Ppatch_t;
  colon: Ppatch_t;

  // 0-9 graphic
  num: Array[0..9] Of Ppatch_t;

  //  // minus sign
  wiminus: Ppatch_t;

  // "Finished!" graphics
  finished: Ppatch_t;

  // "Entering" graphic
  entering: Ppatch_t;

  // "secret"
  _sp_secret: Ppatch_t;

  //   // "Kills", "Scrt", "Items", "Frags"
  kills: Ppatch_t;
  secret: Ppatch_t;
  items: Ppatch_t;
  frags: Ppatch_t;

  //  // Time sucks.
  timepatch: Ppatch_t;
  par: Ppatch_t;
  sucks: Ppatch_t;

  // "killers", "victims"
  killers: Ppatch_t;
  victims: Ppatch_t;

  // "Total", your face, your dead face
  total: Ppatch_t;
  star: Ppatch_t;
  bstar: Ppatch_t;

  // "red P[1..MAXPLAYERS]"
  p: Array[0..MAXPLAYERS - 1] Of Ppatch_t;

  // "gray P[1..MAXPLAYERS]"
  bp: Array[0..MAXPLAYERS - 1] Of Ppatch_t;

  // Name graphics of each level (centered)
  lnames: Array Of Ppatch_t;

  // [crispy] prevent crashes with maps without map title graphics lump
  num_lnames: unsigned_int;

  sp_state: int;

  NUMANIMS: Array[0..NUMEPISODES - 1] Of int; // Wird im Initialization gesetzt

  epsd0animinfo: WiAnim_tArray = Nil; // Wird im Initialization gesetzt
  epsd1animinfo: WiAnim_tArray = Nil; // Wird im Initialization gesetzt
  epsd2animinfo: WiAnim_tArray = Nil; // Wird im Initialization gesetzt

  anims: Array[0..NUMEPISODES - 1] Of WiAnim_tArray; // Wird im Initialization gesetzt

  // Buffer storing the backdrop
  background: Ppatch_t;

Procedure WI_checkForAccelerate();
Var
  i: int;
  player: Pplayer_t;
Begin
  // check for button presses to skip delays
  For i := 0 To MAXPLAYERS - 1 Do Begin
    player := @players[i];
    If (playeringame[i]) Then Begin
      If (player^.cmd.buttons And BT_ATTACK) <> 0 Then Begin
        If (player^.attackdown = false) Then
          acceleratestage := 1;
        player^.attackdown := true;
      End
      Else
        player^.attackdown := false;
      If (player^.cmd.buttons And BT_USE) <> 0 Then Begin
        If (player^.usedown = false) Then
          acceleratestage := 1;
        player^.usedown := true;
      End
      Else
        player^.usedown := false;
    End;
  End;
End;

Procedure WI_updateAnimatedBack();
Var
  i: int;
  a: PWianim_t;
Begin
  If (gamemode = commercial) Then exit;
  If (wbs^.epsd > 2) Then exit;

  Raise Exception.Create('Port me.');

  //    for (i=0;i<NUMANIMS[wbs->epsd];i++)
  //    {
  //	a = &anims[wbs->epsd][i];
  //
  //	if (bcnt == a->nexttic)
  //	{
  //	    switch (a->type)
  //	    {
  //	      case ANIM_ALWAYS:
  //		if (++a->ctr >= a->nanims) a->ctr = 0;
  //		a->nexttic = bcnt + a->period;
  //		break;
  //
  //	      case ANIM_RANDOM:
  //		a->ctr++;
  //		if (a->ctr == a->nanims)
  //		{
  //		    a->ctr = -1;
  //		    a->nexttic = bcnt+a->data2+(M_Random()%a->data1);
  //		}
  //		else a->nexttic = bcnt + a->period;
  //		break;
  //
  //	      case ANIM_LEVEL:
  //		// gawd-awful hack for level anims
  //		if (!(state == StatCount && i == 7)
  //		    && wbs->next == a->data1)
  //		{
  //		    a->ctr++;
  //		    if (a->ctr == a->nanims) a->ctr--;
  //		    a->nexttic = bcnt + a->period;
  //		}
  //		break;
  //	    }
  //	}
  //
  //    }

End;

Procedure WI_initNoState();
Begin
  state := NoState;
  acceleratestage := 0;
  cnt := 10;
End;

Procedure WI_initAnimatedBack(firstcall: boolean);
Var
  i: int;
  a: PWianim_t;
Begin
  If (gamemode = commercial) Then exit;

  If (wbs^.epsd > 2) Then exit;
  Raise exception.create('Port me.');

  //    for (i=0;i<NUMANIMS[wbs->epsd];i++)
  //    {
  //	a = &anims[wbs->epsd][i];
  //
  //	// init variables
  //	// [crispy] Do not reset animation timers upon switching to "Entering" state
  //	// via WI_initShowNextLoc. Fixes notable blinking of Tower of Babel drawing
  //	// and the rest of animations from being restarted.
  //	if (firstcall)
  //	a->ctr = -1;
  //
  //	// specify the next time to draw it
  //	if (a->type == ANIM_ALWAYS)
  //	    a->nexttic = bcnt + 1 + (M_Random()%a->period);
  //	else if (a->type == ANIM_RANDOM)
  //	    a->nexttic = bcnt + 1 + a->data2+(M_Random()%a->data1);
  //	else if (a->type == ANIM_LEVEL)
  //	    a->nexttic = bcnt + 1;
  //    }
End;

Procedure WI_initShowNextLoc();
Begin
  // [crispy] display tally screen after ExM8
  If ((gamemode <> commercial) And (gamemap = 8)) Or ((gameversion = exe_chex) And (gamemap = 5)) Then Begin
    G_WorldDone();
    exit;
  End;

  state := ShowNextLoc;
  acceleratestage := 0;
  cnt := SHOWNEXTLOCDELAY * TICRATE;

  WI_initAnimatedBack(false);
End;

Procedure WI_updateDeathmatchStats();
Begin
  Raise exception.create('Port me.');
  //    int		i;
  //    int		j;
  //
  //    boolean	stillticking;
  //
  //    WI_updateAnimatedBack();
  //
  //    if (acceleratestage && dm_state != 4)
  //    {
  //	acceleratestage = 0;
  //
  //	for (i=0 ; i<MAXPLAYERS ; i++)
  //	{
  //	    if (playeringame[i])
  //	    {
  //		for (j=0 ; j<MAXPLAYERS ; j++)
  //		    if (playeringame[j])
  //			dm_frags[i][j] = plrs[i].frags[j];
  //
  //		dm_totals[i] = WI_fragSum(i);
  //	    }
  //	}
  //
  //
  //	S_StartSoundOptional(0, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
  //	dm_state = 4;
  //    }
  //
  //
  //    if (dm_state == 2)
  //    {
  //	if (!(bcnt&3))
  //	    S_StartSoundOptional(0, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.
  //
  //	stillticking = false;
  //
  //	for (i=0 ; i<MAXPLAYERS ; i++)
  //	{
  //	    if (playeringame[i])
  //	    {
  //		for (j=0 ; j<MAXPLAYERS ; j++)
  //		{
  //		    if (playeringame[j]
  //			&& dm_frags[i][j] != plrs[i].frags[j])
  //		    {
  //			if (plrs[i].frags[j] < 0)
  //			    dm_frags[i][j]--;
  //			else
  //			    dm_frags[i][j]++;
  //
  //			if (dm_frags[i][j] > 99)
  //			    dm_frags[i][j] = 99;
  //
  //			if (dm_frags[i][j] < -99)
  //			    dm_frags[i][j] = -99;
  //
  //			stillticking = true;
  //		    }
  //		}
  //		dm_totals[i] = WI_fragSum(i);
  //
  //		if (dm_totals[i] > 99)
  //		    dm_totals[i] = 99;
  //
  //		if (dm_totals[i] < -99)
  //		    dm_totals[i] = -99;
  //	    }
  //
  //	}
  //	if (!stillticking)
  //	{
  //	    S_StartSoundOptional(0, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
  //	    dm_state++;
  //	}
  //
  //    }
  //    else if (dm_state == 4)
  //    {
  //	if (acceleratestage)
  //	{
  //	    S_StartSoundOptional(0, sfx_intdms, sfx_slop); // [NS] Optional inter sounds.
  //
  //	    if ( gamemode == commercial)
  //		WI_initNoState();
  //	    else
  //		WI_initShowNextLoc();
  //	}
  //    }
  //    else if (dm_state & 1)
  //    {
  //	if (!--cnt_pause)
  //	{
  //	    dm_state++;
  //	    cnt_pause = TICRATE;
  //	}
  //    }
End;

Procedure WI_updateNetgameStats();
Begin
  Raise exception.create('Port me.');
  //    int		i;
  //    int		fsum;
  //
  //    boolean	stillticking;
  //
  //    WI_updateAnimatedBack();
  //
  //    if (acceleratestage && ng_state != 10)
  //    {
  //	acceleratestage = 0;
  //
  //	for (i=0 ; i<MAXPLAYERS ; i++)
  //	{
  //	    if (!playeringame[i])
  //		continue;
  //
  //	    cnt_kills[i] = (plrs[i].skills * 100) / wbs->maxkills;
  //	    cnt_items[i] = (plrs[i].sitems * 100) / wbs->maxitems;
  //	    cnt_secret[i] = (plrs[i].ssecret * 100) / wbs->maxsecret;
  //
  //	    if (dofrags)
  //		cnt_frags[i] = WI_fragSum(i);
  //	}
  //	S_StartSoundOptional(0, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
  //	ng_state = 10;
  //    }
  //
  //    if (ng_state == 2)
  //    {
  //	if (!(bcnt&3))
  //	    S_StartSoundOptional(0, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.
  //
  //	stillticking = false;
  //
  //	for (i=0 ; i<MAXPLAYERS ; i++)
  //	{
  //	    if (!playeringame[i])
  //		continue;
  //
  //	    cnt_kills[i] += 2;
  //
  //	    if (cnt_kills[i] >= (plrs[i].skills * 100) / wbs->maxkills)
  //		cnt_kills[i] = (plrs[i].skills * 100) / wbs->maxkills;
  //	    else
  //		stillticking = true;
  //	}
  //
  //	if (!stillticking)
  //	{
  //	    S_StartSoundOptional(0, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
  //	    ng_state++;
  //	}
  //    }
  //    else if (ng_state == 4)
  //    {
  //	if (!(bcnt&3))
  //	    S_StartSoundOptional(0, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.
  //
  //	stillticking = false;
  //
  //	for (i=0 ; i<MAXPLAYERS ; i++)
  //	{
  //	    if (!playeringame[i])
  //		continue;
  //
  //	    cnt_items[i] += 2;
  //	    if (cnt_items[i] >= (plrs[i].sitems * 100) / wbs->maxitems)
  //		cnt_items[i] = (plrs[i].sitems * 100) / wbs->maxitems;
  //	    else
  //		stillticking = true;
  //	}
  //	if (!stillticking)
  //	{
  //	    S_StartSoundOptional(0, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
  //	    ng_state++;
  //	}
  //    }
  //    else if (ng_state == 6)
  //    {
  //	if (!(bcnt&3))
  //	    S_StartSoundOptional(0, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.
  //
  //	stillticking = false;
  //
  //	for (i=0 ; i<MAXPLAYERS ; i++)
  //	{
  //	    if (!playeringame[i])
  //		continue;
  //
  //	    cnt_secret[i] += 2;
  //
  //	    if (cnt_secret[i] >= (plrs[i].ssecret * 100) / wbs->maxsecret)
  //		cnt_secret[i] = (plrs[i].ssecret * 100) / wbs->maxsecret;
  //	    else
  //		stillticking = true;
  //	}
  //
  //	if (!stillticking)
  //	{
  //	    S_StartSoundOptional(0, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
  //	    ng_state += 1 + 2*!dofrags;
  //	}
  //    }
  //    else if (ng_state == 8)
  //    {
  //	if (!(bcnt&3))
  //	    S_StartSoundOptional(0, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.
  //
  //	stillticking = false;
  //
  //	for (i=0 ; i<MAXPLAYERS ; i++)
  //	{
  //	    if (!playeringame[i])
  //		continue;
  //
  //	    cnt_frags[i] += 1;
  //
  //	    if (cnt_frags[i] >= (fsum = WI_fragSum(i)))
  //		cnt_frags[i] = fsum;
  //	    else
  //		stillticking = true;
  //	}
  //
  //	if (!stillticking)
  //	{
  //	    S_StartSoundOptional(0, sfx_intnet, sfx_pldeth); // [NS] Optional inter sounds.
  //	    ng_state++;
  //	}
  //    }
  //    else if (ng_state == 10)
  //    {
  //	if (acceleratestage)
  //	{
  //	    S_StartSoundOptional(0, sfx_intnex, sfx_sgcock); // [NS] Optional inter sounds.
  //	    if ( gamemode == commercial )
  //		WI_initNoState();
  //	    else
  //		WI_initShowNextLoc();
  //	}
  //    }
  //    else if (ng_state & 1)
  //    {
  //	if (!--cnt_pause)
  //	{
  //	    ng_state++;
  //	    cnt_pause = TICRATE;
  //	}
  //    }
End;

Procedure WI_updateStats();
Begin
  WI_updateAnimatedBack();

  If (acceleratestage <> 0) And (sp_state <> 10) Then Begin
    acceleratestage := 0;
    cnt_kills[0] := (plrs[me].skills * 100) Div wbs^.maxkills;
    cnt_items[0] := (plrs[me].sitems * 100) Div wbs^.maxitems;
    cnt_secret[0] := (plrs[me].ssecret * 100) Div wbs^.maxsecret;
    cnt_time := plrs[me].stime Div TICRATE;
    cnt_par := wbs^.partime Div TICRATE;
    S_StartSoundOptional(Nil, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
    sp_state := 10;
  End;

  If (sp_state = 2) Then Begin

    cnt_kills[0] := cnt_kills[0] + 2;

    If ((bcnt And 3) = 0) Then
      S_StartSoundOptional(Nil, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.

    If (cnt_kills[0] >= (plrs[me].skills * 100) Div wbs^.maxkills) Then Begin
      cnt_kills[0] := (plrs[me].skills * 100) Div wbs^.maxkills;
      S_StartSoundOptional(Nil, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
      sp_state := sp_state + 1;
    End;
  End
  Else If (sp_state = 4) Then Begin

    cnt_items[0] := cnt_items[0] + 2;

    If ((bcnt And 3) = 0) Then
      S_StartSoundOptional(Nil, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.

    If (cnt_items[0] >= (plrs[me].sitems * 100) Div wbs^.maxitems) Then Begin
      cnt_items[0] := (plrs[me].sitems * 100) Div wbs^.maxitems;
      S_StartSoundOptional(Nil, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
      sp_state := sp_state + 1;
    End;
  End
  Else If (sp_state = 6) Then Begin
    cnt_secret[0] := cnt_secret[0] + 2;

    If ((bcnt And 3) = 0) Then
      S_StartSoundOptional(Nil, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.

    If (cnt_secret[0] >= (plrs[me].ssecret * 100) Div wbs^.maxsecret) Then Begin

      cnt_secret[0] := (plrs[me].ssecret * 100) Div wbs^.maxsecret;
      S_StartSoundOptional(Nil, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
      sp_state := sp_state + 1;
    End;
  End

  Else If (sp_state = 8) Then Begin
    If ((bcnt And 3) = 0) Then
      S_StartSoundOptional(Nil, sfx_inttic, sfx_pistol); // [NS] Optional inter sounds.

    cnt_time := cnt_time + 3;

    If (cnt_time >= plrs[me].stime Div TICRATE) Then
      cnt_time := plrs[me].stime Div TICRATE;

    cnt_par := cnt_par + 3;

    If (cnt_par >= wbs^.partime Div TICRATE) Then Begin
      cnt_par := wbs^.partime Div TICRATE;
      If (cnt_time >= plrs[me].stime Div TICRATE) Then Begin
        S_StartSoundOptional(Nil, sfx_inttot, sfx_barexp); // [NS] Optional inter sounds.
        sp_state := sp_state + 1;
      End;
    End;
  End
  Else If (sp_state = 10) Then Begin
    If (acceleratestage <> 0) Then Begin
      S_StartSoundOptional(Nil, sfx_intnex, sfx_sgcock); // [NS] Optional inter sounds.
      If (gamemode = commercial) Then
        WI_initNoState()
      Else
        WI_initShowNextLoc();
    End;
  End
  Else If (sp_state And 1) <> 0 Then Begin
    cnt_pause := cnt_pause - 1;
    If (cnt_pause <> 0) Then Begin
      sp_state := sp_state + 1;
      cnt_pause := TICRATE;
    End;
  End;
End;

Procedure WI_updateShowNextLoc();
Begin
  WI_updateAnimatedBack();
  cnt := cnt - 1;
  If (cnt = 0) Or (acceleratestage <> 0) Then
    WI_initNoState()
  Else
    snl_pointeron := (cnt And 31) < 20;
End;

Procedure WI_updateNoState();
Begin
  WI_updateAnimatedBack();
  cnt := cnt - 1;
  If (cnt = 0) Then Begin
    // Don't call WI_End yet.  G_WorldDone doesnt immediately
    // change gamestate, so WI_Drawer is still going to get
    // run until that happens.  If we do that after WI_End
    // (which unloads all the graphics), we're in trouble.
    //WI_End();
    G_WorldDone();
  End;
End;

Procedure WI_Ticker();
Begin
  // counter for general background animation
  bcnt := bcnt + 1;

  If (bcnt = 1) Then Begin
    // intermission music
    If (gamemode = commercial) Then
      S_ChangeMusic(mus_dm2int, true)
        // [crispy] Sigil
    Else If (crispy.haved1e5) And (wbs^.epsd = 4) And ((W_CheckNumForName('D_SIGINT') <> -1)) Then
      S_ChangeMusic(mus_sigint, true)
        // [crispy] Sigil II
    Else If (crispy.haved1e6) And (wbs^.epsd = 5) And ((W_CheckNumForName('D_SG2INT') <> -1)) Then
      S_ChangeMusic(mus_sg2int, true)
    Else
      S_ChangeMusic(mus_inter, true);
  End;

  WI_checkForAccelerate();
  Case (state) Of
    StatCount:
      If (deathmatch <> 0) Then
        WI_updateDeathmatchStats()
      Else If (netgame) Then
        WI_updateNetgameStats()
      Else
        WI_updateStats();
    ShowNextLoc: WI_updateShowNextLoc();
    NoState: WI_updateNoState();
  End;
End;

// slam background

Procedure WI_slamBackground();
Begin
  V_DrawPatchFullScreen(background, false);
End;

Procedure WI_drawAnimatedBack();
Var
  i: int;
  a: pwianim_t;

Begin
  If (gamemode = commercial) Then exit;

  If (wbs^.epsd > 2) Then exit;

  For i := 0 To NUMANIMS[wbs^.epsd] - 1 Do Begin
    a := @anims[wbs^.epsd][i];
    If (a^.ctr >= 0) Then
      V_DrawPatch(a^.loc.x, a^.loc.y, a^.p[a^.ctr]);
  End;

  // [crispy] show Fortress of Mystery if it has been completed
  If (wbs^.epsd = 1) And (wbs^.didsecret) Then Begin
    a := @anims[wbs^.epsd][7];
    V_DrawPatch(a^.loc.x, a^.loc.y, a^.p[a^.nanims - 1]);
  End;
End;


// Draws "<Levelname> Finished!"

Procedure WI_drawLF();
Var
  y: int;
Begin
  y := WI_TITLEY;
  // [crispy] prevent crashes with maps without map title graphics lump
  If (wbs^.last >= num_lnames) Or (lnames[wbs^.last] = Nil) Then Begin

    V_DrawPatch((ORIGWIDTH - SHORT(finished^.width)) Div 2, y, finished);
    exit;
  End;

  hier gehts weiter

  //    if (gamemode != commercial || wbs^.last < NUMCMAPS)
  //    {
  //        // draw <LevelName>
  //        V_DrawPatch((ORIGWIDTH - SHORT(lnames[wbs^.last]^.width))/2,
  //                    y, lnames[wbs^.last]);
  //
  //        // draw "Finished!"
  //        y += (5*SHORT(lnames[wbs^.last]^.height))/4;
  //
  //        V_DrawPatch((ORIGWIDTH - SHORT(finished^.width)) / 2, y, finished);
  //    }
  //    else if (wbs^.last == NUMCMAPS)
  //    {
  //        // MAP33 - draw "Finished!" only
  //        V_DrawPatch((ORIGWIDTH - SHORT(finished^.width)) / 2, y, finished);
  //    }
  //    else if (wbs^.last > NUMCMAPS)
  //    {
  //        // > MAP33.  Doom bombs out here with a Bad V_DrawPatch error.
  //        // I'm pretty sure that doom2.exe is just reading into random
  //        // bits of memory at this point, but let's try to be accurate
  //        // anyway.  This deliberately triggers a V_DrawPatch error.
  //
  //        patch_t tmp = { ORIGWIDTH, ORIGHEIGHT, 1, 1,
  //                        { 0, 0, 0, 0, 0, 0, 0, 0 } };
  //
  //        V_DrawPatch(0, y, &tmp);
  //    }
End;


//
// Draws a number.
// If digits > 0, then use that many digits minimum,
//  otherwise only use as many as necessary.
// Returns new x position.
//

Function WI_drawNum(x: int; y: int; n: int; digits: int): int;
Var
  fontwidth: int;
  neg: boolean;
  temp: int;
Begin
  fontwidth := num[0]^.width;
  If (digits < 0) Then Begin
    If (n = 0) Then Begin
      // make variable-length zeros 1 digit long
      digits := 1;
    End
    Else Begin
      // figure out # of digits in #
      digits := 0;
      temp := n;
      While (temp <> 0) Do Begin
        temp := temp Div 10;
        digits := digits + 1;
      End;
    End;
  End;

  neg := n < 0;
  If (neg) Then
    n := -n;

  // if non-number, do not draw it
  If (n = 1994) Then Begin
    result := 0;
    exit;
  End;

  // draw the new number
  While (digits <> 0) Do Begin
    x := x - fontwidth;
    V_DrawPatch(x, y, num[n Mod 10]);
    n := n Div 10;
    digits := digits - 1;
  End;

  // draw a minus sign if necessary
  If (neg And (wiminus <> Nil)) Then Begin
    x := x - 8;
    V_DrawPatch(x, y, wiminus);
  End;
  result := x;
End;

Procedure WI_drawPercent(x: int;
  y: int;
  p: int);
Begin
  If (p < 0) Then exit;
  V_DrawPatch(x, y, percent);
  WI_drawNum(x, y, p, -1);
End;

//
// Display level completion time and par,
//  or "sucks" message if overflow.
//

Procedure WI_drawTime(x, y, t: int; suck: boolean);
Var
  _div: int;
  n: int;
Begin
  If (t < 0) Then exit;

  If (t <= 61 * 59) Or (Not suck) Then Begin

    _div := 1;

    Repeat
      n := (t Div _div) Mod 60;
      x := WI_drawNum(x, y, n, 2) - colon^.width;
      _div := _div * 60;

      // draw
      If (_div = 60) Or (t Div _div <> 0) Then
        V_DrawPatch(x, y, colon);

      //	} while (t / div && div < 3600);
    Until Not ((t Div _div <> 0) And (_div < 3600));

    // [crispy] print at most in hhhh:mm:ss format
    n := (t Div _div);
    If (n <> 0) Then Begin
      x := WI_drawNum(x, y, n, -1);
    End;
  End
  Else Begin
    // "sucks"
    V_DrawPatch(x - sucks^.width, y, sucks);
  End;
End;


// [crispy] conditionally draw par times on intermission screen

Function WI_drawParTime(): boolean;
Begin
  result := true;

  // [crispy] PWADs have no par times (including The Master Levels)
  If (Not W_IsIWADLump(maplumpinfo^)) Then Begin
    result := false;
  End;

  If (gamemode = commercial) Then Begin
    // [crispy] IWAD: Final Doom has no par times
    If (gamemission = pack_tnt) Or (gamemission = pack_plut) Then Begin
      result := false;
    End;

    // [crispy] PWAD: NRFTL has par times
    If (gamemission = pack_nerve) Then Begin
      result := true;
    End;

    // [crispy] IWAD/PWAD: BEX patch provided par times
//    If (bex_cpars[wbs^.last]) Then Begin
//      result := true;
//    End;
  End
  Else Begin
    // [crispy] IWAD: Episode 4 has no par times
    // (but we have for singleplayer games)
    If (wbs^.epsd = 3) And (Not crispy.singleplayer) Then Begin
      result := false;
    End;

    // [crispy] IWAD/PWAD: BEX patch provided par times for Episode 4
    // (disguised as par times for Doom II MAP02 to MAP10)
  //		if (wbs->epsd == 3 && bex_cpars[wbs->last + 1])
  //		{
  //			result = true;
  //		}

    // [crispy] IWAD/PWAD: BEX patch provided par times for Episodes 1-4
  //		if (wbs->epsd <= 3 && bex_pars[wbs->epsd + 1][wbs->last + 1])
  //		{
  //			result = true;
  //		}

    // [crispy] PWAD: par times for Sigil
    If (wbs^.epsd = 4) Or (wbs^.epsd = 5) Then Begin
      result := true;
    End;
  End;
End;

Procedure WI_drawStats();
Var
  // line height
  lh: int;
  ttime: int;
  wide: boolean;
Begin

  lh := (3 * SHORT(num[0]^.height)) Div 2;

  WI_slamBackground();

  // draw animated background
  WI_drawAnimatedBack();

  WI_drawLF();

  V_DrawPatch(SP_STATSX, SP_STATSY, kills);
  WI_drawPercent(ORIGWIDTH - SP_STATSX, SP_STATSY, cnt_kills[0]);

  V_DrawPatch(SP_STATSX, SP_STATSY + lh, items);
  WI_drawPercent(ORIGWIDTH - SP_STATSX, SP_STATSY + lh, cnt_items[0]);

  V_DrawPatch(SP_STATSX, SP_STATSY + 2 * lh, _sp_secret);
  WI_drawPercent(ORIGWIDTH - SP_STATSX, SP_STATSY + 2 * lh, cnt_secret[0]);

  V_DrawPatch(SP_TIMEX, SP_TIMEY, timepatch);
  WI_drawTime(ORIGWIDTH Div 2 - SP_TIMEX, SP_TIMEY, cnt_time, true);

  // [crispy] conditionally draw par times on intermission screen
  If (WI_drawParTime()) Then Begin
    V_DrawPatch(ORIGWIDTH Div 2 + SP_TIMEX, SP_TIMEY, par);
    WI_drawTime(ORIGWIDTH - SP_TIMEX, SP_TIMEY, cnt_par, true);
  End;

  // [crispy] draw total time after level time and par time
  If (sp_state > 8) Then Begin
    ttime := wbs^.totaltimes Div TICRATE;
    wide := (ttime > 61 * 59) Or (SP_TIMEX + SHORT(total^.width) >= ORIGWIDTH Div 4);

    V_DrawPatch(SP_TIMEX, SP_TIMEY + 16, total);
    // [crispy] choose x-position depending on width of time string
    If wide Then Begin
      WI_drawTime(ORIGWIDTH - SP_TIMEX, SP_TIMEY + 16, ttime, false);
    End
    Else Begin
      WI_drawTime((ORIGWIDTH Div 2) - SP_TIMEX, SP_TIMEY + 16, ttime, false);
    End;
  End;

  // [crispy] exit early from the tally screen after ExM8
  If (sp_state = 10) And (((gamemode <> commercial) And (gamemap = 8)) Or ((gameversion = exe_chex) And (gamemap = 5))) Then Begin
    acceleratestage := 1;
  End;

  // [crispy] demo timer widget
  If ((demoplayback) And ((crispy.demotimer And DEMOTIMER_PLAYBACK) <> 0)) Or (
    (demorecording) And ((crispy.demotimer And DEMOTIMER_RECORD) <> 0))
    Then Begin
    ST_DrawDemoTimer(leveltime);
  End;

  // [crispy] demo progress bar
  If (demoplayback) And (crispy.demobar <> 0) Then Begin
    HU_DemoProgressBar();
  End;
End;

Procedure WI_drawNetgameStats();
Begin
  Raise exception.create('Port me.');
  //    int		i;
  //    int		x;
  //    int		y;
  //    int		pwidth = SHORT(percent->width);
  //
  //    WI_slamBackground();
  //
  //    // draw animated background
  //    WI_drawAnimatedBack();
  //
  //    WI_drawLF();
  //
  //    // draw stat titles (top line)
  //    V_DrawPatch(NG_STATSX+NG_SPACINGX-SHORT(kills->width),
  //		NG_STATSY, kills);
  //
  //    V_DrawPatch(NG_STATSX+2*NG_SPACINGX-SHORT(items->width),
  //		NG_STATSY, items);
  //
  //    V_DrawPatch(NG_STATSX+3*NG_SPACINGX-SHORT(secret->width),
  //		NG_STATSY, secret);
  //
  //    if (dofrags)
  //	V_DrawPatch(NG_STATSX+4*NG_SPACINGX-SHORT(frags->width),
  //		    NG_STATSY, frags);
  //
  //    // draw stats
  //    y = NG_STATSY + SHORT(kills->height);
  //
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //    {
  //	if (!playeringame[i])
  //	    continue;
  //
  //	x = NG_STATSX;
  //	V_DrawPatch(x-SHORT(p[i]->width), y, p[i]);
  //
  //	if (i == me)
  //	    V_DrawPatch(x-SHORT(p[i]->width), y, star);
  //
  //	x += NG_SPACINGX;
  //	WI_drawPercent(x-pwidth, y+10, cnt_kills[i]);	x += NG_SPACINGX;
  //	WI_drawPercent(x-pwidth, y+10, cnt_items[i]);	x += NG_SPACINGX;
  //	WI_drawPercent(x-pwidth, y+10, cnt_secret[i]);	x += NG_SPACINGX;
  //
  //	if (dofrags)
  //	    WI_drawNum(x, y+10, cnt_frags[i], -1);
  //
  //	y += WI_SPACINGY;
  //    }

End;

Procedure WI_drawDeathmatchStats();
Begin
  Raise exception.create('Port me.');
  //    int		i;
  //    int		j;
  //    int		x;
  //    int		y;
  //    int		w;
  //
  //    WI_slamBackground();
  //
  //    // draw animated background
  //    WI_drawAnimatedBack();
  //    WI_drawLF();
  //
  //    // draw stat titles (top line)
  //    V_DrawPatch(DM_TOTALSX-SHORT(total->width)/2,
  //		DM_MATRIXY-WI_SPACINGY+10,
  //		total);
  //
  //    V_DrawPatch(DM_KILLERSX, DM_KILLERSY, killers);
  //    V_DrawPatch(DM_VICTIMSX, DM_VICTIMSY, victims);
  //
  //    // draw P?
  //    x = DM_MATRIXX + DM_SPACINGX;
  //    y = DM_MATRIXY;
  //
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //    {
  //	if (playeringame[i])
  //	{
  //	    V_DrawPatch(x-SHORT(p[i]->width)/2,
  //			DM_MATRIXY - WI_SPACINGY,
  //			p[i]);
  //
  //	    V_DrawPatch(DM_MATRIXX-SHORT(p[i]->width)/2,
  //			y,
  //			p[i]);
  //
  //	    if (i == me)
  //	    {
  //		V_DrawPatch(x-SHORT(p[i]->width)/2,
  //			    DM_MATRIXY - WI_SPACINGY,
  //			    bstar);
  //
  //		V_DrawPatch(DM_MATRIXX-SHORT(p[i]->width)/2,
  //			    y,
  //			    star);
  //	    }
  //	}
  //	else
  //	{
  //	    // V_DrawPatch(x-SHORT(bp[i]->width)/2,
  //	    //   DM_MATRIXY - WI_SPACINGY, bp[i]);
  //	    // V_DrawPatch(DM_MATRIXX-SHORT(bp[i]->width)/2,
  //	    //   y, bp[i]);
  //	}
  //	x += DM_SPACINGX;
  //	y += WI_SPACINGY;
  //    }
  //
  //    // draw stats
  //    y = DM_MATRIXY+10;
  //    w = SHORT(num[0]->width);
  //
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //    {
  //	x = DM_MATRIXX + DM_SPACINGX;
  //
  //	if (playeringame[i])
  //	{
  //	    for (j=0 ; j<MAXPLAYERS ; j++)
  //	    {
  //		if (playeringame[j])
  //		    WI_drawNum(x+w, y, dm_frags[i][j], 2);
  //
  //		x += DM_SPACINGX;
  //	    }
  //	    WI_drawNum(DM_TOTALSX+w, y, dm_totals[i], 2);
  //	}
  //	y += WI_SPACINGY;
  //    }
End;


Procedure WI_drawShowNextLoc();
Begin
        hier gehts weiter
  //    int		i;
  //    int		last;
  //    extern boolean secretexit; // [crispy] Master Level support
  //
  //    WI_slamBackground();
  //
  //    // draw animated background
  //    WI_drawAnimatedBack();
  //
  //    if ( gamemode != commercial)
  //    {
  //  	if (wbs->epsd > 2)
  //	{
  //	    WI_drawEL();
  //	    return;
  //	}
  //
  //	last = (wbs->last == 8 || wbs->last == 9) ? wbs->next - 1 : wbs->last; // [crispy] support E1M10 "Sewers"
  //
  //	// draw a splat on taken cities.
  //	for (i=0 ; i<=last ; i++)
  //	    WI_drawOnLnode(i, splat);
  //
  //	// splat the secret level?
  //	if (wbs->didsecret)
  //	    WI_drawOnLnode(8, splat);
  //
  //	// [crispy] the splat for E1M10 "Sewers" is drawn only once,
  //	// i.e. now, when returning from the level
  //	// (and this is not going to change)
  //	if (crispy->havee1m10 && wbs->epsd == 0 && wbs->last == 9)
  //	{
  //	    wbs->epsd = 1;
  //	    WI_drawOnLnode(0, splat);
  //	    wbs->epsd = 0;
  //	}
  //
  //	// draw flashing ptr
  //	if (snl_pointeron)
  //	    WI_drawOnLnode(wbs->next, yah);
  //    }
  //
  //    if ((gamemission == pack_nerve && wbs->last == 7) ||
  //        (gamemission == pack_master && wbs->last == 19 && !secretexit) ||
  //        (gamemission == pack_master && wbs->last == 20))
  //        return;
  //
  //    // draws which level you are entering..
  //    if ( (gamemode != commercial)
  //	 || wbs->next != 30)
  //	WI_drawEL();

End;

Procedure WI_drawNoState();
Begin
  snl_pointeron := true;
  WI_drawShowNextLoc();
End;

Procedure WI_Drawer();
Begin
  Case (state) Of
    StatCount:
      If (deathmatch <> 0) Then
        WI_drawDeathmatchStats()
      Else If (netgame) Then
        WI_drawNetgameStats()
      Else
        WI_drawStats();
    ShowNextLoc: WI_drawShowNextLoc();
    NoState: WI_drawNoState();
  End;
End;

Procedure WI_initVariables(wbstartstruct: Pwbstartstruct_t);
Begin

  wbs := wbstartstruct;

  //#ifdef RANGECHECKING
  //    if (gamemode != commercial)
  //    {
  //      if (gameversion >= exe_ultimate)
  //	RNGCHECK(wbs->epsd, 0, 3);
  //      else
  //	RNGCHECK(wbs->epsd, 0, 2);
  //    }
  //    else
  //    {
  //	RNGCHECK(wbs->last, 0, 8);
  //	RNGCHECK(wbs->next, 0, 8);
  //    }
  //    RNGCHECK(wbs->pnum, 0, MAXPLAYERS);
  //    RNGCHECK(wbs->pnum, 0, MAXPLAYERS);
  //#endif

  acceleratestage := 0;
  cnt := 0;
  bcnt := 0;
  firstrefresh := 1;
  me := wbs^.pnum;
  plrs := wbs^.plyr;

  If (wbs^.maxkills = 0) Then
    wbs^.maxkills := 1;
  //
  If (wbs^.maxitems = 0) Then
    wbs^.maxitems := 1;

  If (wbs^.maxsecret = 0) Then
    wbs^.maxsecret := 1;

  If (gameversion < exe_ultimate) Then
    If (wbs^.epsd > 2) Then
      wbs^.epsd := wbs^.epsd - 3;
End;

// Common load/unload function.  Iterates over all the graphics
// lumps to be loaded/unloaded into memory.

Procedure WI_loadUnloadData(callback: load_callback_t);
Var
  i, j: int;
  name: String;
  a: PWianim_t;
Begin
  If (gamemode = commercial) Then Begin
    For i := 0 To NUMCMAPS - 1 Do Begin
      name := Format('CWILV%0.2d', [i]);
      // [crispy] NRFTL / The Master Levels
      If (crispy.havenerve <> '') And (wbs^.epsd = 1) And (i < 9) Then Begin // [crispy] gamemission == pack_nerve
        name[1] := 'N';
      End;
      If (crispy.havemaster <> '') And (wbs^.epsd = 2) And (i < 21) Then Begin // [crispy] gamemission == pack_master
        name[1] := 'M';
      End;
      callback(name, @lnames[i]);
    End;
  End
  Else Begin
    For i := 0 To DEFINE_NUMMAPS - 1 Do Begin
      name := format('WILV%d%d', [wbs^.epsd, i]);
      callback(name, @lnames[i]);
    End;
    //	// [crispy] special-casing for E1M10 "Sewers" support
    If (crispy.havee1m10) Then Begin
      i := DEFINE_NUMMAPS;
      name := 'SEWERS';
      callback(name, @lnames[i]);
    End;

    // you are here
    callback('WIURH0', @yah[0]);

    // you are here (alt.)
    callback('WIURH1', @yah[1]);

    // splat
    callback('WISPLAT', @splat[0]);

    If (wbs^.epsd < 3) Then Begin

      //	    for (j=0;j<NUMANIMS[wbs->epsd];j++)
      For j := 0 To NUMANIMS[wbs^.epsd] - 1 Do Begin
        a := @anims[wbs^.epsd][j];
        For i := 0 To a^.nanims - 1 Do Begin

          // MONDO HACK!
          If (wbs^.epsd <> 1) Or (j <> 8) Then Begin
            // animations
            name := format('WIA%d%.2d%.2d', [wbs^.epsd, j, i]);
            callback(name, @a^.p[i]);
          End
          Else Begin
            // HACK ALERT!
            a^.p[i] := anims[1][4].p[i];
          End;
        End;
      End;
    End;
  End;

  // More hacks on minus sign.
  If (W_CheckNumForName('WIMINUS') > 0) Then
    callback('WIMINUS', @wiminus)
  Else
    wiminus := Nil;

  For i := 0 To 9 Do Begin
    // numbers 0-9
    name := format('WINUM%d', [i]);
    callback(name, @num[i]);
  End;

  // percent sign
  callback('WIPCNT', @percent);

  // "finished"
  callback('WIF', @finished);

  // "entering"
  callback('WIENTER', @entering);

  // "kills"
  callback('WIOSTK', @kills);

  // "scrt"
  callback('WIOSTS', @secret);

  // "secret"
  callback('WISCRT2', @_sp_secret);

  // french wad uses WIOBJ (?)
  If (W_CheckNumForName('WIOBJ') >= 0) Then Begin

    // "items"
    If netgame And (deathmatch = 0) Then
      callback('WIOBJ', @items)
    Else
      callback('WIOSTI', @items);
  End
  Else Begin
    callback('WIOSTI', @items);
  End;

  // "frgs"
  callback('WIFRGS', @frags);

  // ":"
  callback('WICOLON', @colon);

  // "time"
  callback('WITIME', @timepatch);

  // "sucks"
  callback('WISUCKS', @sucks);

  // "par"
  callback('WIPAR', @par);

  // "killers" (vertical)
  callback('WIKILRS', @killers);

  // "victims" (horiz)
  callback('WIVCTMS', @victims);

  // "total"
  callback('WIMSTT', @total);


  For i := 0 To MAXPLAYERS - 1 Do Begin
    // "1,2,3,4"
    name := format('STPB%d', [i]);
    callback(name, @p[i]);

    // "1,2,3,4"
    name := format('WIBP%d', [i + 1]);
    callback(name, @bp[i]);
  End;

  // Background image

  If (gamemode = commercial) Then Begin
    If (crispy.havenerve <> '') And (wbs^.epsd = 1) And (W_CheckNumForName('NERVEINT') <> -1) Then Begin // [crispy] gamemission == pack_nerve
      name := 'NERVEINT';
    End
    Else If (crispy.havemaster <> '') And (wbs^.epsd = 2) And (W_CheckNumForName('MASTRINT') <> -1) Then Begin // [crispy] gamemission == pack_master
      name := 'MASTRINT';
    End
    Else Begin
      name := 'INTERPIC';
    End;
  End
  Else If (gameversion >= exe_ultimate) And (wbs^.epsd = 3) Then Begin
    name := 'INTERPIC';
  End
  Else If (crispy.haved1e5) And (wbs^.epsd = 4) And (W_CheckNumForName('SIGILINT') <> -1) Then Begin // [crispy] Sigil
    name := 'SIGILINT';
  End
  Else If (crispy.haved1e6) And (wbs^.epsd = 5) And (W_CheckNumForName('SIGILIN2') <> -1) Then Begin // [crispy] Sigil
    name := 'SIGILIN2';
  End
  Else Begin
    name := format('WIMAP%d', [wbs^.epsd]);
  End;

  // [crispy] if still in doubt, use INTERPIC
  If (W_CheckNumForName(name) = -1) Then Begin
    name := 'INTERPIC';
  End;

  // Draw backdrop and save to a temporary buffer
  callback(name, @background);
End;

Procedure WI_loadCallback(name: String; variable: PPPAtch_t);
Begin
  // [crispy] prevent crashes with maps without map title graphics lump
  If (W_CheckNumForName(name) <> -1) Then
    variable^ := PPAtch_t(W_CacheLumpName(name, PU_STATIC))
  Else
    variable^ := Nil;
End;

Procedure WI_loadData();
Var
  nummaps: int;
Begin
  If (gamemode = commercial) Then Begin
    If crispy.havemap33 Then Begin
      NUMCMAPS := 33;
    End
    Else Begin
      NUMCMAPS := 32;
    End;
    setlength(lnames, NUMCMAPS);
    num_lnames := NUMCMAPS;
  End
  Else Begin
    // [crispy] support E1M10 "Sewers"
    If crispy.havee1m10 Then Begin
      nummaps := DEFINE_NUMMAPS + 1;
    End
    Else Begin
      nummaps := NUMMAPS;
    End;
    setlength(lnames, nummaps);
    num_lnames := nummaps;
  End;

  WI_loadUnloadData(@WI_loadCallback);

  // These two graphics are special cased because we're sharing
  // them with the status bar code

  // your face
  star := W_CacheLumpName('STFST01', PU_STATIC);

  // dead face
  bstar := W_CacheLumpName('STFDEAD0', PU_STATIC);
End;

Procedure WI_initDeathmatchStats();
Begin
  exception.create('Port me.');
  //    int		i;
  //    int		j;
  //
  //    state = StatCount;
  //    acceleratestage = 0;
  //    dm_state = 1;
  //
  //    cnt_pause = TICRATE;
  //
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //    {
  //	if (playeringame[i])
  //	{
  //	    for (j=0 ; j<MAXPLAYERS ; j++)
  //		if (playeringame[j])
  //		    dm_frags[i][j] = 0;
  //
  //	    dm_totals[i] = 0;
  //	}
  //    }
  //
  //    WI_initAnimatedBack(true);
End;

Procedure WI_initNetgameStats();
Begin
  exception.create('Port me.');
  //    int i;
  //
  //    state = StatCount;
  //    acceleratestage = 0;
  //    ng_state = 1;
  //
  //    cnt_pause = TICRATE;
  //
  //    for (i=0 ; i<MAXPLAYERS ; i++)
  //    {
  //	if (!playeringame[i])
  //	    continue;
  //
  //	cnt_kills[i] = cnt_items[i] = cnt_secret[i] = cnt_frags[i] = 0;
  //
  //	dofrags += WI_fragSum(i);
  //    }
  //
  //    dofrags = !!dofrags;
  //
  //    WI_initAnimatedBack(true);
End;

Procedure WI_initStats();
Begin
  state := StatCount;
  acceleratestage := 0;
  sp_state := 1;
  cnt_kills[0] := -1;
  cnt_items[0] := -1;
  cnt_secret[0] := -1;
  cnt_time := -1;
  cnt_par := -1;
  cnt_pause := TICRATE;
  WI_initAnimatedBack(true);
End;

Procedure WI_Start(wbstartstruct: Pwbstartstruct_t);
Begin
  WI_initVariables(wbstartstruct);
  WI_loadData();
  If (deathmatch <> 0) Then
    WI_initDeathmatchStats()
  Else If (netgame) Then
    WI_initNetgameStats()
  Else
    WI_initStats();
End;

Procedure WI_End();
Begin
  // WI_unloadData(); --> Brauchen wir nicht, da wir keine Lumps freigeben!
End;

Procedure Anim(Var Arr: WiAnim_tArray; _type: animenum_t; period: int; nanims: int; x: int; y: int; nexttic: int);
Begin
  setlength(arr, high(arr) + 2);
  arr[high(arr)]._type := _type;
  arr[high(arr)].period := period;
  arr[high(arr)].nanims := nanims;
  arr[high(arr)].loc.x := x;
  arr[high(arr)].loc.y := y;
  arr[high(arr)].data1 := nexttic;
  arr[high(arr)].data2 := 0;
  arr[high(arr)].p[0] := Nil;
  arr[high(arr)].p[1] := Nil;
  arr[high(arr)].p[2] := Nil;
  arr[high(arr)].nexttic := 0;
  arr[high(arr)].lastdrawn := 0;
  arr[high(arr)].ctr := 0;
  arr[high(arr)].state := 0;
End;

Initialization

  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 224, 104, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 184, 160, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 112, 136, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 72, 112, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 88, 96, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 64, 48, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 192, 40, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 136, 16, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 80, 16, 0);
  ANIM(epsd0animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 64, 24, 0);

  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 1, 128, 136, 1);
  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 1, 128, 136, 2);
  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 1, 128, 136, 3);
  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 1, 128, 136, 4);
  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 1, 128, 136, 5);
  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 1, 128, 136, 6);
  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 1, 128, 136, 7);
  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 3, 192, 144, 8);
  ANIM(epsd1animinfo, ANIM_LEVEL, TICRATE Div 3, 1, 128, 136, 8);

  ANIM(epsd2animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 104, 168, 0);
  ANIM(epsd2animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 40, 136, 0);
  ANIM(epsd2animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 160, 96, 0);
  ANIM(epsd2animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 104, 80, 0);
  ANIM(epsd2animinfo, ANIM_ALWAYS, TICRATE Div 3, 3, 120, 32, 0);
  ANIM(epsd2animinfo, ANIM_ALWAYS, TICRATE Div 4, 3, 40, 0, 0);

  NUMANIMS[0] := length(epsd0animinfo);
  NUMANIMS[1] := length(epsd1animinfo);
  NUMANIMS[2] := length(epsd2animinfo);

  anims[0] := epsd0animinfo;
  anims[1] := epsd1animinfo;
  anims[2] := epsd2animinfo;

End.

