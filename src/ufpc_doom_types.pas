Unit ufpc_doom_types;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Const
  INT_MIN = -2147483648; // = low(int); ?
  INT_MAX = 2147483647; // = high(int); ?

  BOBFACTOR_FULL = 0;
  BOBFACTOR_75 = 1;
  BOBFACTOR_OFF = 2;
  NUM_BOBFACTORS = 3;

  BRIGHTMAPS_OFF = 0;
  BRIGHTMAPS_TEXTURES = 1;
  BRIGHTMAPS_SPRITES = 2;
  BRIGHTMAPS_BOTH = 3;
  NUM_BRIGHTMAPS = 4;

  TRANSLUCENCY_OFF = 0;
  TRANSLUCENCY_MISSILE = 1;
  TRANSLUCENCY_ITEM = 2;
  TRANSLUCENCY_BOTH = 3;
  NUM_TRANSLUCENCY = 4;

  CROSSHAIR_OFF = 0;
  CROSSHAIR_STATIC = 1;
  CROSSHAIR_PROJECTED = 2;
  NUM_CROSSHAIRS = 3;
  CROSSHAIR_INTERCEPT = $10;

  DEMOTIMER_OFF = 0;
  DEMOTIMER_RECORD = 1;
  DEMOTIMER_PLAYBACK = 2;
  DEMOTIMER_BOTH = 3;
  NUM_DEMOTIMERS = 4;

  NUM_CROSSHAIRTYPES = 3;

  FREEAIM_AUTO = 0;
  FREEAIM_DIRECT = 1;
  FREEAIM_BOTH = 2;
  NUM_FREEAIMS = 3;

  CENTERWEAPON_OFF = 0;
  CENTERWEAPON_CENTER = 1;
  CENTERWEAPON_BOB = 2;
  NUM_CENTERWEAPON = 3;

  COLOREDHUD_OFF = 0;
  COLOREDHUD_BAR = 1;
  COLOREDHUD_TEXT = 2;
  COLOREDHUD_BOTH = 3;
  NUM_COLOREDHUD = 4;

  COLOREDBLOOD_OFF = 0;
  COLOREDBLOOD_BLOOD = 1;
  COLOREDBLOOD_ALL = 2;
  NUM_COLOREDBLOOD = 3;

  SECRETMESSAGE_OFF = 0;
  SECRETMESSAGE_ON = 1;
  SECRETMESSAGE_COUNT = 2;
  NUM_SECRETMESSAGE = 3;

  JUMP_OFF = 0;
  JUMP_LOW = 1;
  JUMP_HIGH = 2;
  NUM_JUMPS = 3;

Type
  TProcedure = Procedure();

  signed_char = Int8;
  unsigned_char = UInt8;

  uint8_t = UInt8;
  uint16_t = UInt16;
  uint64_t = UInt64;
  size_t = UInt64;
  short = Int16;
  unsigned_short = uInt16;

  int = int32;
  int32_t = Int32;
  uint32_t = UInt32;
  unsigned = UInt32; // Geraten, den dass steht nirgends, könnte auch PTR_int sein ??
  P_int = ^int;
  unsigned_int = uint32;
  P_unsigned_int = ^unsigned_int;
  int64_t = Int64;
  Pint64_t = ^int64_t;
  float = single;

  fixed_t = int;
  Pfixed_t = ^fixed_t;

  TCrispy = Record
    // [crispy] "crispness" config variables
    automapoverlay: int; // 0, ?
    automaprotate: int;
    //    	int automapstats;
    bobfactor: int; // BOBFACTOR_FULL, BOBFACTOR_75, BOBFACTOR_OFF,
    brightmaps: int; // BRIGHTMAPS_OFF, BRIGHTMAPS_TEXTURES, BRIGHTMAPS_SPRITES, BRIGHTMAPS_BOTH
    btusetimer: int; // ?
    centerweapon: int; // CENTERWEAPON_OFF, CENTERWEAPON_CENTER, CENTERWEAPON_BOB
    coloredblood: int; // COLOREDBLOOD_OFF .. COLOREDBLOOD_ALL
    coloredhud: int; // COLOREDHUD_OFF .. COLOREDHUD_BOTH
    crosshair: int; // CROSSHAIR_OFF .. CROSSHAIR_PROJECTED
    crosshairhealth: int;
    crosshairtarget: int;
    crosshairtype: int;
    //    	int defaultskill;
    demotimer: int; // DEMOTIMER_OFF, DEMOTIMER_RECORD, DEMOTIMER_PLAYBACK, DEMOTIMER_BOTH
    //    	int demotimerdir;
    demobar: int;
    extautomap: int; // 0,1
    flipcorpses: int;
    //    	int fpslimit;
    freeaim: int;
    freelook: int; // 0,1 ?
    //    	int freelook_hh;
    //    	int gamma;
    hires: Int; // 0, 1, 2 Alles über 2 macht eigentlich keinen Sinn mehr, Bei werten > 2 muss MAXWIDTH und MAXHEIGHT aus i_video.pas angepasst werden, sonst knallts beim start !
    jump: int; // JUMP_OFF, JUMP_LOW, JUMP_HIGH -> ist aber nur im Singleplayer erlaubt !
    //    	int leveltime;
    mouselook: int; // ?
    neghealth: int;
    overunder: int; // ?
    pitch: int; // ?
    //    	int playercoords;
    secretmessage: int; // SECRETMESSAGE_OFF, SECRETMESSAGE_ON, SECRETMESSAGE_COUNT
    //    	int smoothlight;
    smoothmap: int;
    //    	int smoothscaling;
    soundfix: int;
    soundfull: int;
    //    	int soundmono;
    //    	int statsformat;
    translucency: int;
    //    #ifdef CRISPY_TRUECOLOR
    //    	int truecolor;
    //    #endif
    uncapped: int; // 0, ?
    //    	int vsync;
    //    	int widescreen;

    //    	// [crispy] in-game switches and variables
    screenshotmsg: int;
    snowflakes: int;
    cleanscreenshot: int;
    demowarp: int;
    //    	int fps;

    fistisquit: Boolean; // By Corpsman, if true, the fist can be fired without making noises (= waking up other enemies) ;)
    flashinghom: Boolean;
    fliplevels: boolean;
    flipweapons: Boolean;
    haved1e5: boolean;
    haved1e6: boolean;
    havee1m10: boolean;
    havemap33: boolean;
    havessg: boolean; // Hat der Spieler zugriff auf die Doppeläufige Schrotflinte ? (true = ja)
    singleplayer: boolean;
    stretchsky: Boolean; // wird in R_InitSkyMap initialisiert

    //    	// [crispy] custom difficulty parameters
    //    	boolean autohealth;
    //    	boolean fast;
    //    	boolean keysloc;
    moreammo: boolean;
    //    	boolean pistolstart;

    havenerve: String;
    havemaster: String;
    havesigil: String;
    havesigil2: String;

    //    	const char *sdlversion;
    //    	const char *platform;

    //    	void (*post_rendering_hook) (void);
  End;

Var
  Crispy: TCrispy;
  Critical: ^TCrispy;

Procedure Nop(); // Just for debugging to have a breakpoint position ;)

Function IfThen(aValue: Boolean; aTrueString: String; aFalseString: String): String;
Procedure CheckCrispySingleplayer(singleplayer: Boolean);

Function Clamp(Value, Lower, Upper: fixed_t): fixed_t; // overload;

Function isdigit(value: Char): Boolean;

Implementation

Var
  critical_s: TCrispy; // wird im Initialization gesetzt

Function Clamp(Value, Lower, Upper: fixed_t): fixed_t; // overload;
Begin
  If value < lower Then Begin
    result := lower;
  End
  Else Begin
    If Value > Upper Then Begin
      result := upper;
    End
    Else Begin
      result := value;
    End;
  End;
End;

Function isdigit(value: Char): Boolean;
Begin
  result := (value >= '0') And (value <= '9');
End;

Procedure Nop();
Begin

End;

Function IfThen(aValue: Boolean; aTrueString: String; aFalseString: String
  ): String;
Begin
  If aValue Then Begin
    result := aTrueString;
  End
  Else Begin
    Result := aFalseString;
  End;
End;

Procedure CheckCrispySingleplayer(singleplayer: Boolean);
Begin
  crispy.singleplayer := singleplayer;
  If (crispy.singleplayer) Then Begin
    critical := @Crispy;
  End
  Else Begin
    critical := @critical_s;
  End;
End;

Initialization

  Crispy.automapoverlay := 0;
  Crispy.automaprotate := 0;
  Crispy.bobfactor := BOBFACTOR_FULL;
  Crispy.brightmaps := BRIGHTMAPS_OFF;
  Crispy.btusetimer := 0;
  Crispy.centerweapon := CENTERWEAPON_OFF;
  Crispy.coloredblood := COLOREDBLOOD_OFF;
  Crispy.coloredhud := COLOREDHUD_OFF;
  Crispy.crosshair := CROSSHAIR_OFF;
  Crispy.crosshairhealth := 0;
  Crispy.crosshairtarget := 0;
  Crispy.crosshairtype := 0;
  Crispy.demotimer := DEMOTIMER_OFF;
  Crispy.demobar := 0;
  Crispy.extautomap := 0; // Wenn <> 0, dann werden Schlüssel Türen auf der Kartenvorschau in ihrer Farbe gezeichnet
  Crispy.flipcorpses := 0;
  Crispy.freeaim := 0;
  Crispy.freelook := 0;

  Crispy.hires := 1;
  Crispy.jump := JUMP_OFF;
  Crispy.extautomap := 1;
  //  Crispy.gamma := 9; // default level is "OFF" for intermediate gamma levels
  Crispy.mouselook := 0;
  Crispy.neghealth := 0;
  Crispy.overunder := 0;
  Crispy.pitch := 0;
  Crispy.secretmessage := SECRETMESSAGE_OFF;
  Crispy.smoothmap := 0;
  //  Crispy.smoothscaling := 1;
  //    #ifdef CRISPY_TRUECOLOR
  //    Crispy.smoothlight := 1;
  //    Crispy.truecolor := 1;
  //    #Endif
  Crispy.soundfix := 1;
  Crispy.soundfull := 0;
  Crispy.translucency := 0;
  Crispy.uncapped := 0;
  //  Crispy.vsync := 1;
  //  Crispy.widescreen := 1; // match screen by default
  Crispy.cleanscreenshot := 0;
  Crispy.demowarp := 0;
  Crispy.screenshotmsg := 0;
  Crispy.snowflakes := 0;
  Crispy.fistisquit := false; // by Corpsman
  Crispy.flashinghom := false;
  Crispy.fliplevels := false;
  Crispy.flipweapons := false;
  Crispy.haved1e5 := false; // Wird während dem laden des .wad files initialisiert
  Crispy.haved1e6 := false; // Wird während dem laden des .wad files initialisiert
  Crispy.havee1m10 := false; // Wird während dem laden des .wad files initialisiert
  Crispy.havemap33 := false; // Wird während dem laden des .wad files initialisiert
  Crispy.havessg := false; // Wird während dem laden des .wad files initialisiert
  Crispy.singleplayer := false;
  Crispy.stretchsky := false;
  Crispy.moreammo := false;
  Crispy.havenerve := ''; // Wird in CheckLoadNerve initialisiert
  Crispy.havemaster := ''; // Wird in LoadMasterlevelsWads initialisiert
  Crispy.havesigil := ''; // Wird in LoadSigilWad initialisiert
  Crispy.havesigil2 := ''; // Wird in LoadSigil2Wad initialisiert

  FillChar(critical_s, sizeof(critical_s), 0);

End.

